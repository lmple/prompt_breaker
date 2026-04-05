module DSL.Attack
  ( JailbreakTechnique(..)
  , AttackCategory(..)
  , Attack(..)
  , directInjection
  , jailbreak
  , promptLeak
  ) where

import Data.Aeson (ToJSON, FromJSON)
import Data.Text (Text)
import Data.UUID (UUID)
import GHC.Generics (Generic)

import DSL.OWASP (OWASPCategory(..))
import DSL.Sanitizer (Untrusted(..))

data JailbreakTechnique
  = Roleplay
  | Hypothetical
  | Encoding
  | Fragmentation
  deriving (Show, Eq, Ord, Enum, Bounded, Generic)

instance ToJSON JailbreakTechnique
instance FromJSON JailbreakTechnique

data AttackCategory
  = DirectInjection
  | IndirectInjection
  | Jailbreak JailbreakTechnique
  | PromptLeaking
  deriving (Show, Eq, Generic)

instance ToJSON AttackCategory
instance FromJSON AttackCategory

data Attack = Attack
  { attackId          :: Maybe UUID
  , attackCategory    :: AttackCategory
  , attackPayload     :: Untrusted
  , attackDescription :: Text
  , attackOwaspRef    :: OWASPCategory
  } deriving (Show, Eq, Generic)

instance ToJSON Attack
instance FromJSON Attack

directInjection :: Text -> Text -> Attack
directInjection payload desc = Attack
  { attackId          = Nothing
  , attackCategory    = DirectInjection
  , attackPayload     = Untrusted payload
  , attackDescription = desc
  , attackOwaspRef    = LLM01_PromptInjection
  }

jailbreak :: JailbreakTechnique -> Text -> Text -> Attack
jailbreak technique payload desc = Attack
  { attackId          = Nothing
  , attackCategory    = Jailbreak technique
  , attackPayload     = Untrusted payload
  , attackDescription = desc
  , attackOwaspRef    = LLM01_PromptInjection
  }

promptLeak :: Text -> Text -> Attack
promptLeak payload desc = Attack
  { attackId          = Nothing
  , attackCategory    = PromptLeaking
  , attackPayload     = Untrusted payload
  , attackDescription = desc
  , attackOwaspRef    = LLM06_SensitiveInfoDisclosure
  }
