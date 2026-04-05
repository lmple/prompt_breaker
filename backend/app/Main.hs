{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import Network.Wai.Handler.Warp (run)
import Network.Wai (Middleware)
import Network.Wai.Middleware.Cors
  ( cors, simpleCorsResourcePolicy, corsRequestHeaders
  , corsOrigins, corsMethods, CorsResourcePolicy(..)
  )
import Servant (serve)

import API.Handlers (server)
import API.Routes (api)
import DB.Queries (connectDB)

main :: IO ()
main = do
  putStrLn "Connecting to database..."
  conn <- connectDB
  putStrLn "Starting server on port 8080..."
  run 8080 $ corsMiddleware $ serve api (server conn)

corsMiddleware :: Middleware
corsMiddleware = cors $ const $ Just policy
  where
    policy = simpleCorsResourcePolicy
      { corsOrigins = Just (["http://localhost:5173"], True)
      , corsMethods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
      , corsRequestHeaders = ["Content-Type", "Authorization"]
      }
