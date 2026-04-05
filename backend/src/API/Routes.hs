{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
module API.Routes
  ( API
  , api
  ) where

import Data.UUID (UUID)
import Servant

import API.Types

type API =
       "targets" :> Get '[JSON] [LLMTarget]
  :<|> "targets" :> ReqBody '[JSON] LLMTargetRequest :> PostCreated '[JSON] LLMTarget
  :<|> "targets" :> Capture "id" UUID :> ReqBody '[JSON] LLMTargetRequest :> Put '[JSON] LLMTarget
  :<|> "targets" :> Capture "id" UUID :> DeleteNoContent
  :<|> "attacks" :> Get '[JSON] [AttackTemplate]
  :<|> "attacks" :> ReqBody '[JSON] AttackRequest :> PostCreated '[JSON] AttackTemplate
  :<|> "attacks" :> Capture "id" UUID :> ReqBody '[JSON] AttackRequest :> Put '[JSON] AttackTemplate
  :<|> "attacks" :> Capture "id" UUID :> DeleteNoContent
  :<|> "runs"    :> Get '[JSON] [RunResult]
  :<|> "runs"    :> ReqBody '[JSON] RunRequest :> PostCreated '[JSON] RunResult
  :<|> "runs"    :> Capture "id" UUID :> Get '[JSON] RunResult
  :<|> "stats"   :> Get '[JSON] Stats

api :: Servant.Proxy API
api = Servant.Proxy
