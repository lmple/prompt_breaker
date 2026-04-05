module API.Types
  ( LLMTargetRequest(..)
  , AttackRequest(..)
  , RunRequest(..)
  , RunResult(..)
  , LLMTarget(..)
  , AttackTemplate(..)
  , Stats(..)
  , CategoryStats(..)
  ) where

import Data.Aeson (ToJSON, FromJSON)
import Data.Text (Text)
import Data.Time (UTCTime)
import Data.UUID (UUID)
import GHC.Generics (Generic)

import Runner.Evaluator (EvaluatorMethod)

data LLMTargetRequest = LLMTargetRequest
  { ltrName    :: Text
  , ltrBaseUrl :: Text
  , ltrModel   :: Text
  , ltrApiKey  :: Maybe Text
  } deriving (Show, Eq, Generic)

instance ToJSON LLMTargetRequest
instance FromJSON LLMTargetRequest

data AttackRequest = AttackRequest
  { arCategory    :: Text
  , arTechnique   :: Maybe Text
  , arPayload     :: Text
  , arDescription :: Text
  , arOwaspRef    :: Text
  } deriving (Show, Eq, Generic)

instance ToJSON AttackRequest
instance FromJSON AttackRequest

data RunRequest = RunRequest
  { rrqAttackId        :: UUID
  , rrqTargetId        :: UUID
  , rrqStrategy        :: Text
  , rrqSystemPrompt    :: Text
  , rrqEvaluatorMethod :: EvaluatorMethod
  } deriving (Show, Eq, Generic)

instance ToJSON RunRequest
instance FromJSON RunRequest

data LLMTarget = LLMTarget
  { ltId        :: UUID
  , ltName      :: Text
  , ltBaseUrl   :: Text
  , ltModel     :: Text
  , ltApiKey    :: Maybe Text
  , ltCreatedAt :: UTCTime
  } deriving (Show, Eq, Generic)

instance ToJSON LLMTarget
instance FromJSON LLMTarget

data AttackTemplate = AttackTemplate
  { atId          :: UUID
  , atCategory    :: Text
  , atTechnique   :: Maybe Text
  , atPayload     :: Text
  , atDescription :: Text
  , atOwaspRef    :: Text
  , atCreatedAt   :: UTCTime
  } deriving (Show, Eq, Generic)

instance ToJSON AttackTemplate
instance FromJSON AttackTemplate

data RunResult = RunResult
  { rrRunId       :: UUID
  , rrAttack      :: AttackTemplate
  , rrTarget      :: LLMTarget
  , rrStrategy    :: Text
  , rrRawResponse :: Maybe Text
  , rrSuccess     :: Maybe Bool
  , rrConfidence  :: Maybe Double
  , rrRanAt       :: UTCTime
  } deriving (Show, Eq, Generic)

instance ToJSON RunResult
instance FromJSON RunResult

data CategoryStats = CategoryStats
  { csNaiveSuccessRate     :: Double
  , csSanitizedSuccessRate :: Double
  , csTotalRuns            :: Int
  } deriving (Show, Eq, Generic)

instance ToJSON CategoryStats
instance FromJSON CategoryStats

data Stats = Stats
  { byCategory :: [(Text, CategoryStats)]
  } deriving (Show, Eq, Generic)

instance ToJSON Stats
instance FromJSON Stats
