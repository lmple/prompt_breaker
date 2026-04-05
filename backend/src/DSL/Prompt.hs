{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
module DSL.Prompt
  ( PromptStrategy(..)
  , ChatMessage(..)
  , buildMessages
  ) where

import Data.Aeson (ToJSON(..), FromJSON(..), withText)
import Data.Text (Text)
import GHC.Generics (Generic)

import DSL.Sanitizer (Untrusted(..), sanitize)

data PromptStrategy = Naive | Sanitized
  deriving (Show, Eq, Generic)

instance ToJSON PromptStrategy where
  toJSON Naive     = toJSON ("Naive" :: Text)
  toJSON Sanitized = toJSON ("Sanitized" :: Text)

instance FromJSON PromptStrategy where
  parseJSON = withText "PromptStrategy" $ \case
    "Naive"     -> pure Naive
    "Sanitized" -> pure Sanitized
    "naive"     -> pure Naive
    "sanitized" -> pure Sanitized
    other       -> fail $ "Unknown PromptStrategy: " <> show other

data ChatMessage = ChatMessage
  { role    :: Text
  , content :: Text
  } deriving (Show, Eq, Generic)

instance ToJSON ChatMessage
instance FromJSON ChatMessage

buildMessages :: PromptStrategy -> Text -> Untrusted -> [ChatMessage]
buildMessages strategy systemPrompt payload =
  [ ChatMessage "system" systemPrompt
  , ChatMessage "user" userContent
  ]
  where
    userContent = case strategy of
      Naive     -> getUntrusted payload
      Sanitized -> getUntrusted (sanitize payload)
