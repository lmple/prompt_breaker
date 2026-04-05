{-# LANGUAGE OverloadedStrings #-}
module API.Handlers
  ( server
  ) where

import Control.Monad.IO.Class (liftIO)
import qualified Data.Aeson as Aeson
import qualified Data.ByteString.Lazy as LBS
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import Data.UUID (UUID)
import Database.PostgreSQL.Simple (Connection)
import Servant

import API.Routes (API)
import API.Types
import DB.Queries
import qualified DB.Schema
import DSL.Prompt (PromptStrategy(..), buildMessages)
import DSL.Sanitizer (Untrusted(..))
import qualified Runner.Evaluator
import Runner.Evaluator (evaluate)
import Runner.LLM (LLMTargetConfig(..), complete)

server :: Connection -> Server API
server conn =
       getTargetsH conn
  :<|> postTargetH conn
  :<|> getAttacksH conn
  :<|> postAttackH conn
  :<|> getRunsH conn
  :<|> postRunH conn
  :<|> getRunByIdH conn
  :<|> getStatsH conn

-- Target handlers

getTargetsH :: Connection -> Handler [LLMTarget]
getTargetsH conn = do
  rows <- liftIO $ getTargets conn
  pure $ map targetFromRow rows

postTargetH :: Connection -> LLMTargetRequest -> Handler LLMTarget
postTargetH conn r = do
  rows <- liftIO $ insertTarget conn (ltrName r) (ltrBaseUrl r) (ltrModel r) (ltrApiKey r)
  case rows of
    (row:_) -> pure $ targetFromRow row
    []      -> throwError err409 { errBody = "Target name already exists" }

-- Attack handlers

getAttacksH :: Connection -> Handler [AttackTemplate]
getAttacksH conn = do
  rows <- liftIO $ getAttacks conn
  pure $ map attackFromRow rows

postAttackH :: Connection -> AttackRequest -> Handler AttackTemplate
postAttackH conn r = do
  rows <- liftIO $ insertAttack conn
    (arCategory r) (arTechnique r) (arPayload r) (arDescription r) (arOwaspRef r)
  case rows of
    (row:_) -> pure $ attackFromRow row
    []      -> throwError err400 { errBody = "Invalid attack data" }

-- Run handlers

getRunsH :: Connection -> Handler [RunResult]
getRunsH conn = do
  rows <- liftIO $ getRuns conn
  mapM (runResultFromRow conn) rows

postRunH :: Connection -> RunRequest -> Handler RunResult
postRunH conn r = do
  attacks <- liftIO $ getAttackById conn (rrqAttackId r)
  targets <- liftIO $ getTargetById conn (rrqTargetId r)
  attack <- case attacks of
    (a:_) -> pure a
    []    -> throwError err404 { errBody = "Attack not found" }
  target <- case targets of
    (t:_) -> pure t
    []    -> throwError err404 { errBody = "Target not found" }

  let strategy = case T.toLower (rrqStrategy r) of
        "sanitized" -> Sanitized
        _           -> Naive

  let messages = buildMessages strategy (rrqSystemPrompt r) (Untrusted $ DB.Schema.atPayload attack)
      llmConfig = LLMTargetConfig
        { llmBaseUrl = DB.Schema.ltBaseUrl target
        , llmModel   = DB.Schema.ltModel target
        , llmApiKey  = DB.Schema.ltApiKey target
        }

  llmResult <- liftIO $ complete llmConfig messages

  let (rawResponse, mSuccess, mConfidence) = case llmResult of
        Left _err -> (Nothing, Nothing, Nothing)
        Right resp ->
          let evalResult = evaluate (rrqEvaluatorMethod r) resp
          in ( Just resp
             , Just (Runner.Evaluator.success evalResult)
             , Just (Runner.Evaluator.confidence evalResult)
             )

  let strategyText :: Text
      strategyText = case strategy of
        Naive     -> "naive"
        Sanitized -> "sanitized"
      evalMethodText = TE.decodeUtf8 $ LBS.toStrict $ Aeson.encode (rrqEvaluatorMethod r)

  runRows <- liftIO $ insertRun conn
    (rrqAttackId r) (rrqTargetId r)
    strategyText (rrqSystemPrompt r)
    rawResponse mSuccess mConfidence
    evalMethodText

  case runRows of
    (row:_) -> runResultFromRow conn row
    []      -> throwError err500 { errBody = "Failed to insert run" }

getRunByIdH :: Connection -> UUID -> Handler RunResult
getRunByIdH conn rid = do
  rows <- liftIO $ getRun conn rid
  case rows of
    (r:_) -> runResultFromRow conn r
    []    -> throwError err404 { errBody = "Run not found" }

-- Stats handler

getStatsH :: Connection -> Handler Stats
getStatsH conn = do
  rows <- liftIO $ getStats conn
  pure $ Stats $ map (\(cat, naive, san, total) ->
    (cat, CategoryStats naive san total)) rows

-- Helpers

targetFromRow :: DB.Schema.LLMTargetRow -> LLMTarget
targetFromRow r = LLMTarget
  { ltId        = DB.Schema.ltId r
  , ltName      = DB.Schema.ltName r
  , ltBaseUrl   = DB.Schema.ltBaseUrl r
  , ltModel     = DB.Schema.ltModel r
  , ltApiKey    = DB.Schema.ltApiKey r
  , ltCreatedAt = DB.Schema.ltCreatedAt r
  }

attackFromRow :: DB.Schema.AttackTemplateRow -> AttackTemplate
attackFromRow r = AttackTemplate
  { atId          = DB.Schema.atId r
  , atCategory    = DB.Schema.atCategory r
  , atTechnique   = DB.Schema.atTechnique r
  , atPayload     = DB.Schema.atPayload r
  , atDescription = DB.Schema.atDescription r
  , atOwaspRef    = DB.Schema.atOwaspRef r
  , atCreatedAt   = DB.Schema.atCreatedAt r
  }

runResultFromRow :: Connection -> DB.Schema.RunRow -> Handler RunResult
runResultFromRow conn r = do
  attacks <- liftIO $ getAttackById conn (DB.Schema.rrAttackId r)
  targets <- liftIO $ getTargetById conn (DB.Schema.rrTargetId r)
  attack <- case attacks of
    (a:_) -> pure $ attackFromRow a
    []    -> throwError err500 { errBody = "Attack not found for run" }
  target <- case targets of
    (t:_) -> pure $ targetFromRow t
    []    -> throwError err500 { errBody = "Target not found for run" }
  pure RunResult
    { rrRunId       = DB.Schema.rrId r
    , rrAttack      = attack
    , rrTarget      = target
    , rrStrategy    = DB.Schema.rrPromptStrategy r
    , rrRawResponse = DB.Schema.rrRawResponse r
    , rrSuccess     = DB.Schema.rrSuccess r
    , rrConfidence  = DB.Schema.rrConfidence r
    , rrRanAt       = DB.Schema.rrRanAt r
    }
