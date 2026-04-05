module DB.Schema
  ( LLMTargetRow(..)
  , AttackTemplateRow(..)
  , RunRow(..)
  ) where

import Data.Text (Text)
import Data.Time (UTCTime)
import Data.UUID (UUID)
import Database.PostgreSQL.Simple (FromRow, ToRow)
import GHC.Generics (Generic)

data LLMTargetRow = LLMTargetRow
  { ltId        :: UUID
  , ltName      :: Text
  , ltBaseUrl   :: Text
  , ltModel     :: Text
  , ltApiKey    :: Maybe Text
  , ltCreatedAt :: UTCTime
  } deriving (Show, Eq, Generic)

instance FromRow LLMTargetRow
instance ToRow LLMTargetRow

data AttackTemplateRow = AttackTemplateRow
  { atId          :: UUID
  , atCategory    :: Text
  , atTechnique   :: Maybe Text
  , atPayload     :: Text
  , atDescription :: Text
  , atOwaspRef    :: Text
  , atCreatedAt   :: UTCTime
  } deriving (Show, Eq, Generic)

instance FromRow AttackTemplateRow
instance ToRow AttackTemplateRow

data RunRow = RunRow
  { rrId              :: UUID
  , rrAttackId        :: UUID
  , rrTargetId        :: UUID
  , rrPromptStrategy  :: Text
  , rrSystemPrompt    :: Text
  , rrRawResponse     :: Maybe Text
  , rrSuccess         :: Maybe Bool
  , rrConfidence      :: Maybe Double
  , rrEvaluatorMethod :: Text
  , rrRanAt           :: UTCTime
  } deriving (Show, Eq, Generic)

instance FromRow RunRow
instance ToRow RunRow
