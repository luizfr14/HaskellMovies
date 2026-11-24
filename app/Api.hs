{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module Api (API, api, ComCookie, Cookie) where

import Servant
import Tipos

-- Resposta que também grava um cookie no navegador
type ComCookie a = Headers '[Header "Set-Cookie" String] a

-- Lê o cabeçalho Cookie da requisição (o handler recebe um Maybe String)
type Cookie = Header "Cookie" String

-- Todas as rotas do sistema, descritas no nível de tipos.
--   :>   encadeia partes da rota (caminho, cookie, corpo)
--   :<|> separa uma rota da outra
type API =
         "api" :> "cadastro" :> ReqBody '[JSON] Cadastro :> Post '[JSON] (ComCookie UsuarioPublico)
    :<|> "api" :> "login"    :> ReqBody '[JSON] Login    :> Post '[JSON] (ComCookie UsuarioPublico)
    :<|> "api" :> "logout"   :> Cookie :> Post '[JSON] (ComCookie NoContent)
    :<|> "api" :> "eu"       :> Cookie :> Get  '[JSON] UsuarioPublico
    :<|> Raw  -- qualquer outro caminho: arquivos do front (pasta static)

api :: Proxy API
api = Proxy
