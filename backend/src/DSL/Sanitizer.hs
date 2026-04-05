{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DerivingStrategies #-}
module DSL.Sanitizer
  ( Untrusted(..)
  , sanitize
  ) where

import Data.Aeson (ToJSON, FromJSON)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.CaseInsensitive as CI
import GHC.Generics (Generic)

newtype Untrusted = Untrusted { getUntrusted :: Text }
  deriving (Show, Eq, Generic)
  deriving newtype (ToJSON, FromJSON)

blocklist :: [(CI.CI Text, Text)]
blocklist = map (\phrase -> (CI.mk phrase, "[REDACTED]"))
  [ "ignore previous instructions"
  , "ignore all previous"
  , "disregard your instructions"
  , "override your programming"
  , "you are now"
  , "act as if"
  , "pretend you are"
  , "forget your rules"
  , "new instructions:"
  , "system prompt:"
  ]

sanitize :: Untrusted -> Untrusted
sanitize (Untrusted txt) = Untrusted (foldl replacePhrase txt blocklist)
  where
    replacePhrase :: Text -> (CI.CI Text, Text) -> Text
    replacePhrase input (phrase, replacement) =
      replaceCI (CI.original phrase) replacement input

    replaceCI :: Text -> Text -> Text -> Text
    replaceCI needle rep haystack
      | T.null needle = haystack
      | otherwise = go haystack
      where
        needleLen = T.length needle
        needleLower = T.toLower needle
        go h
          | T.null h = T.empty
          | T.toLower (T.take needleLen h) == needleLower =
              rep <> go (T.drop needleLen h)
          | otherwise =
              T.singleton (T.head h) <> go (T.tail h)
