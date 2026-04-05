{-# LANGUAGE OverloadedStrings #-}
module DB.Queries
  ( connectDB
  , insertTarget
  , getTargets
  , getTargetById
  , insertAttack
  , getAttacks
  , getAttackById
  , insertRun
  , getRun
  , getRuns
  , getStats
  , hasRunsForTarget
  , hasRunsForAttack
  , updateTarget
  , deleteTargetById
  , updateAttack
  , deleteAttackById
  ) where

import Data.Int (Int64)
import Data.Text (Text)
import qualified Data.Text as T
import Data.UUID (UUID)
import Database.PostgreSQL.Simple
import GHC.Generics (Generic)
import System.Environment (lookupEnv)

import DB.Schema

connectDB :: IO Connection
connectDB = do
  host <- lookupEnv "DB_HOST" >>= pure . maybe "localhost" id
  port <- lookupEnv "DB_PORT" >>= pure . maybe "5432" id
  name <- lookupEnv "DB_NAME" >>= pure . maybe "attack_harness" id
  user <- lookupEnv "DB_USER" >>= pure . maybe "harness" id
  pass <- lookupEnv "DB_PASS" >>= pure . maybe "harness" id
  connect defaultConnectInfo
    { connectHost     = host
    , connectPort     = read port
    , connectDatabase = name
    , connectUser     = user
    , connectPassword = pass
    }

-- Targets

insertTarget :: Connection -> Text -> Text -> Text -> Maybe Text -> IO [LLMTargetRow]
insertTarget conn name baseUrl model apiKey =
  query conn
    "INSERT INTO llm_targets (name, base_url, model, api_key) VALUES (?, ?, ?, ?) \
    \ON CONFLICT (name) DO NOTHING \
    \RETURNING id, name, base_url, model, api_key, created_at"
    (name, baseUrl, model, apiKey)

getTargets :: Connection -> IO [LLMTargetRow]
getTargets conn =
  query_ conn "SELECT id, name, base_url, model, api_key, created_at FROM llm_targets ORDER BY created_at"

getTargetById :: Connection -> UUID -> IO [LLMTargetRow]
getTargetById conn tid =
  query conn "SELECT id, name, base_url, model, api_key, created_at FROM llm_targets WHERE id = ?" (Only tid)

-- Attacks

insertAttack :: Connection -> Text -> Maybe Text -> Text -> Text -> Text -> IO [AttackTemplateRow]
insertAttack conn category technique payload description owaspRef =
  query conn
    "INSERT INTO attack_templates (category, technique, payload, description, owasp_ref) VALUES (?, ?, ?, ?, ?) \
    \RETURNING id, category, technique, payload, description, owasp_ref, created_at"
    (category, technique, payload, description, owaspRef)

getAttacks :: Connection -> IO [AttackTemplateRow]
getAttacks conn =
  query_ conn "SELECT id, category, technique, payload, description, owasp_ref, created_at FROM attack_templates ORDER BY created_at"

getAttackById :: Connection -> UUID -> IO [AttackTemplateRow]
getAttackById conn aid =
  query conn "SELECT id, category, technique, payload, description, owasp_ref, created_at FROM attack_templates WHERE id = ?" (Only aid)

-- Runs

insertRun :: Connection -> UUID -> UUID -> Text -> Text -> Maybe Text -> Maybe Bool -> Maybe Double -> Text -> IO [RunRow]
insertRun conn attackId targetId strategy systemPrompt rawResponse success confidence evaluatorMethod =
  query conn
    "INSERT INTO runs (attack_id, target_id, prompt_strategy, system_prompt, raw_response, success, confidence, evaluator_method) \
    \VALUES (?, ?, ?, ?, ?, ?, ?, ?) \
    \RETURNING id, attack_id, target_id, prompt_strategy, system_prompt, raw_response, success, confidence, evaluator_method, ran_at"
    (attackId, targetId, strategy, systemPrompt, rawResponse, success, confidence, evaluatorMethod)

getRun :: Connection -> UUID -> IO [RunRow]
getRun conn rid =
  query conn
    "SELECT id, attack_id, target_id, prompt_strategy, system_prompt, raw_response, success, confidence, evaluator_method, ran_at \
    \FROM runs WHERE id = ?"
    (Only rid)

getRuns :: Connection -> IO [RunRow]
getRuns conn =
  query_ conn
    "SELECT id, attack_id, target_id, prompt_strategy, system_prompt, raw_response, success, confidence, evaluator_method, ran_at \
    \FROM runs ORDER BY ran_at DESC"

-- Run reference checks

hasRunsForTarget :: Connection -> UUID -> IO Bool
hasRunsForTarget conn tid = do
  [Only exists] <- query conn "SELECT EXISTS (SELECT 1 FROM runs WHERE target_id = ?)" (Only tid)
  pure exists

hasRunsForAttack :: Connection -> UUID -> IO Bool
hasRunsForAttack conn aid = do
  [Only exists] <- query conn "SELECT EXISTS (SELECT 1 FROM runs WHERE attack_id = ?)" (Only aid)
  pure exists

-- Update / Delete targets

updateTarget :: Connection -> UUID -> Text -> Text -> Text -> Maybe Text -> IO [LLMTargetRow]
updateTarget conn tid name baseUrl model apiKey =
  case apiKey of
    Nothing -> query conn
      "UPDATE llm_targets SET name=?, base_url=?, model=? WHERE id=? \
      \RETURNING id, name, base_url, model, api_key, created_at"
      (name, baseUrl, model, tid)
    Just key
      | T.null key -> query conn
          "UPDATE llm_targets SET name=?, base_url=?, model=?, api_key=NULL WHERE id=? \
          \RETURNING id, name, base_url, model, api_key, created_at"
          (name, baseUrl, model, tid)
      | otherwise -> query conn
          "UPDATE llm_targets SET name=?, base_url=?, model=?, api_key=? WHERE id=? \
          \RETURNING id, name, base_url, model, api_key, created_at"
          (name, baseUrl, model, key, tid)

deleteTargetById :: Connection -> UUID -> IO Int64
deleteTargetById conn tid =
  execute conn "DELETE FROM llm_targets WHERE id=?" (Only tid)

-- Update / Delete attacks

updateAttack :: Connection -> UUID -> Text -> Maybe Text -> Text -> Text -> Text -> IO [AttackTemplateRow]
updateAttack conn aid category technique payload description owaspRef =
  query conn
    "UPDATE attack_templates SET category=?, technique=?, payload=?, description=?, owasp_ref=? WHERE id=? \
    \RETURNING id, category, technique, payload, description, owasp_ref, created_at"
    (category, technique, payload, description, owaspRef, aid)

deleteAttackById :: Connection -> UUID -> IO Int64
deleteAttackById conn aid =
  execute conn "DELETE FROM attack_templates WHERE id=?" (Only aid)

-- Stats

data StatsRow = StatsRow
  { srOwaspRef         :: Text
  , srStrategy         :: Text
  , srSuccessRate      :: Double
  , srTotalRuns        :: Int
  } deriving (Show, Eq, Generic)

instance FromRow StatsRow

getStatsRaw :: Connection -> IO [StatsRow]
getStatsRaw conn =
  query_ conn
    "SELECT at.owasp_ref, r.prompt_strategy, \
    \COALESCE(AVG(CASE WHEN r.success THEN 1.0 ELSE 0.0 END), 0.0)::float8 AS success_rate, \
    \COUNT(*)::int AS total_runs \
    \FROM runs r \
    \JOIN attack_templates at ON r.attack_id = at.id \
    \WHERE r.success IS NOT NULL \
    \GROUP BY at.owasp_ref, r.prompt_strategy \
    \ORDER BY at.owasp_ref"

-- Re-export helpers for Handlers
getStats :: Connection -> IO [(Text, Double, Double, Int)]
getStats conn = do
  rows <- getStatsRaw conn
  let categories = unique $ map srOwaspRef rows
  pure $ map (buildCategoryStats rows) categories
  where
    unique [] = []
    unique (x:xs) = x : unique (filter (/= x) xs)

    buildCategoryStats rows cat =
      let naiveRate = findRate rows cat "naive"
          sanitizedRate = findRate rows cat "sanitized"
          total = sum $ map srTotalRuns $ filter (\r -> srOwaspRef r == cat) rows
      in (cat, naiveRate, sanitizedRate, total)

    findRate rows cat strategy =
      case filter (\r -> srOwaspRef r == cat && srStrategy r == strategy) rows of
        (r:_) -> srSuccessRate r
        []    -> 0.0
