{-# LANGUAGE OverloadedStrings #-}
module DSL.OWASP
  ( OWASPCategory(..)
  , owaspDescription
  , allCategories
  ) where

import Data.Aeson (ToJSON(..), FromJSON(..), withText)
import Data.Text (Text)
import GHC.Generics (Generic)

data OWASPCategory
  = LLM01_PromptInjection
  | LLM02_InsecureOutputHandling
  | LLM06_SensitiveInfoDisclosure
  | LLM07_InsecurePluginDesign
  deriving (Show, Eq, Ord, Enum, Bounded, Generic)

instance ToJSON OWASPCategory where
  toJSON = toJSON . owaspToText

instance FromJSON OWASPCategory where
  parseJSON = withText "OWASPCategory" $ \t ->
    case owaspFromText t of
      Just c  -> pure c
      Nothing -> fail $ "Unknown OWASPCategory: " <> show t

owaspToText :: OWASPCategory -> Text
owaspToText LLM01_PromptInjection        = "LLM01_PromptInjection"
owaspToText LLM02_InsecureOutputHandling  = "LLM02_InsecureOutputHandling"
owaspToText LLM06_SensitiveInfoDisclosure = "LLM06_SensitiveInfoDisclosure"
owaspToText LLM07_InsecurePluginDesign    = "LLM07_InsecurePluginDesign"

owaspFromText :: Text -> Maybe OWASPCategory
owaspFromText "LLM01_PromptInjection"        = Just LLM01_PromptInjection
owaspFromText "LLM02_InsecureOutputHandling"  = Just LLM02_InsecureOutputHandling
owaspFromText "LLM06_SensitiveInfoDisclosure" = Just LLM06_SensitiveInfoDisclosure
owaspFromText "LLM07_InsecurePluginDesign"    = Just LLM07_InsecurePluginDesign
owaspFromText _                               = Nothing

owaspDescription :: OWASPCategory -> Text
owaspDescription LLM01_PromptInjection        = "Prompt Injection"
owaspDescription LLM02_InsecureOutputHandling  = "Insecure Output Handling"
owaspDescription LLM06_SensitiveInfoDisclosure = "Sensitive Info Disclosure"
owaspDescription LLM07_InsecurePluginDesign    = "Insecure Plugin Design"

allCategories :: [OWASPCategory]
allCategories = [minBound .. maxBound]
