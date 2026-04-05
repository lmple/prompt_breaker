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
  :<|> "attacks" :> Get '[JSON] [AttackTemplate]
  :<|> "attacks" :> ReqBody '[JSON] AttackRequest :> PostCreated '[JSON] AttackTemplate
  :<|> "runs"    :> Get '[JSON] [RunResult]
  :<|> "runs"    :> ReqBody '[JSON] RunRequest :> PostCreated '[JSON] RunResult
  :<|> "runs"    :> Capture "id" UUID :> Get '[JSON] RunResult
  :<|> "stats"   :> Get '[JSON] Stats

api :: Servant.Proxy API
api = Servant.Proxy
