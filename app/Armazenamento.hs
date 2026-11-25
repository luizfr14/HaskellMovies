{-# LANGUAGE OverloadedStrings #-}

-- Guarda as fotos de perfil no Supabase Storage (bucket público "avatares")
module Armazenamento (Armazenamento (..), enviarFoto) where

import Control.Exception (try)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC
import qualified Data.ByteString.Lazy as LBS
import Network.HTTP.Simple

data Armazenamento = Armazenamento
    { urlSupabase   :: String  -- SUPABASE_URL, ex: https://abcd.supabase.co
    , chaveSupabase :: String  -- SUPABASE_SERVICE_KEY: secreta, fica só no servidor
    }

-- Grava a foto em avatares/<id do usuário>, no lugar da anterior.
-- Devolve o endereço público da foto, ou Nothing se o upload falhar.
enviarFoto :: Armazenamento -> Int -> String -> BS.ByteString -> IO (Maybe String)
enviarFoto armazenamento uid tipo bytes = do
    resposta <- try (httpLBS requisicao) :: IO (Either HttpException (Response LBS.ByteString))
    pure (case resposta of
        Right r | getResponseStatusCode r == 200 -> Just enderecoPublico
        _                                        -> Nothing)
  where
    base            = urlSupabase armazenamento ++ "/storage/v1/object/"
    enderecoPublico = base ++ "public/avatares/" ++ show uid
    requisicao =
          setRequestMethod "POST"
        $ setRequestHeader "Authorization" [BC.pack ("Bearer " ++ chaveSupabase armazenamento)]
        $ setRequestHeader "Content-Type" [BC.pack tipo]
        $ setRequestHeader "x-upsert" ["true"]  -- se já existe uma foto, substitui
        $ setRequestBodyLBS (LBS.fromStrict bytes)
        $ parseRequest_ (base ++ "avatares/" ++ show uid)
