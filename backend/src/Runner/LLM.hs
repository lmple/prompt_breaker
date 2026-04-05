{-# LANGUAGE OverloadedStrings #-}
module Runner.LLM
  ( LLMTargetConfig(..)
  , complete
  ) where

import Control.Exception (try, SomeException)
import Data.Aeson (ToJSON(..), FromJSON(..), object, (.=), withObject, (.:))
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import GHC.Generics (Generic)
import Network.HTTP.Req
import Text.URI (mkURI)

import DSL.Prompt (ChatMessage(..))

data LLMTargetConfig = LLMTargetConfig
  { llmBaseUrl :: Text
  , llmModel   :: Text
  , llmApiKey  :: Maybe Text
  } deriving (Show, Eq, Generic)

data ChatCompletionRequest = ChatCompletionRequest
  { ccrModel       :: Text
  , ccrMessages    :: [ChatMessage]
  , ccrTemperature :: Double
  } deriving (Show, Eq, Generic)

instance ToJSON ChatCompletionRequest where
  toJSON r = object
    [ "model"       .= ccrModel r
    , "messages"    .= ccrMessages r
    , "temperature" .= ccrTemperature r
    ]

newtype ChatCompletionResponse = ChatCompletionResponse
  { ccrChoices :: [Choice]
  } deriving (Show, Eq, Generic)

data Choice = Choice
  { choiceMessage :: ChoiceMessage
  } deriving (Show, Eq, Generic)

data ChoiceMessage = ChoiceMessage
  { cmContent :: Text
  } deriving (Show, Eq, Generic)

instance FromJSON ChatCompletionResponse where
  parseJSON = withObject "ChatCompletionResponse" $ \v ->
    ChatCompletionResponse <$> v .: "choices"

instance FromJSON Choice where
  parseJSON = withObject "Choice" $ \v ->
    Choice <$> v .: "message"

instance FromJSON ChoiceMessage where
  parseJSON = withObject "ChoiceMessage" $ \v ->
    ChoiceMessage <$> v .: "content"

complete :: LLMTargetConfig -> [ChatMessage] -> IO (Either Text Text)
complete config messages = do
  let reqBody = ChatCompletionRequest
        { ccrModel       = llmModel config
        , ccrMessages    = messages
        , ccrTemperature = 0.0
        }
      urlText = llmBaseUrl config <> "/v1/chat/completions"
  case mkURI urlText of
    Nothing -> pure $ Left $ "Invalid URL: " <> urlText
    Just uri -> case useHttpsURI uri of
      Just (url, opts) -> doRequest url opts reqBody (llmApiKey config)
      Nothing -> case useHttpURI uri of
        Just (url, opts) -> doRequest url opts reqBody (llmApiKey config)
        Nothing -> pure $ Left $ "Cannot parse URL: " <> urlText

doRequest :: Url scheme -> Option scheme -> ChatCompletionRequest -> Maybe Text -> IO (Either Text Text)
doRequest url opts reqBody mApiKey = do
  let authOpts = case mApiKey of
        Just key -> opts <> header "Authorization" (TE.encodeUtf8 $ "Bearer " <> key)
        Nothing  -> opts
  result <- try $ runReq defaultHttpConfig $
    req POST url (ReqBodyJson reqBody) jsonResponse authOpts
  case result of
    Left (e :: SomeException) ->
      pure $ Left $ T.pack $ show e
    Right resp -> do
      let body = responseBody resp :: ChatCompletionResponse
      case ccrChoices body of
        (choice:_) -> pure $ Right $ cmContent $ choiceMessage choice
        []         -> pure $ Left "No choices in LLM response"
