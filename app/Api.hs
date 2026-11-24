{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module Api (API, api, ComCookie, Cookie) where

import Servant
import Tipos

-- Resposta que também grava um cookie no navegador
type ComCookie a = Headers '[Header "Set-Cookie" String] a

-- Lê o cabeçalho Cookie da requisição (o handler recebe um Maybe String)
type Cookie = Header "Cookie" String

-- Rotas de um filme: /api/filmes/:id/...
type NoFilme rota = "api" :> "filmes" :> Cookie :> Capture "id" Int :> rota

-- Rotas de um usuário: /api/usuarios/:username/...
type NoUsuario rota = "api" :> "usuarios" :> Cookie :> Capture "username" String :> rota

-- Todas as rotas do sistema, descritas no nível de tipos.
--   :>   encadeia partes da rota (caminho, cookie, corpo)
--   :<|> separa uma rota da outra
type API =
    -- Conta
         "api" :> "cadastro" :> ReqBody '[JSON] Cadastro :> Post '[JSON] (ComCookie UsuarioPublico)
    :<|> "api" :> "login"    :> ReqBody '[JSON] Login    :> Post '[JSON] (ComCookie UsuarioPublico)
    :<|> "api" :> "logout"   :> Cookie :> Post '[JSON] (ComCookie NoContent)
    :<|> "api" :> "eu"       :> Cookie :> Get  '[JSON] UsuarioPublico

    -- Filmes
    :<|> "api" :> "filmes" :> Cookie :> QueryParam "q" String :> Get '[JSON] [FilmeNaBusca]
    :<|> NoFilme (Get '[JSON] DetalheFilme)
    :<|> NoFilme ("avaliacao" :> ReqBody '[JSON] NovaAvaliacao :> PutNoContent)
    :<|> NoFilme ("avaliacao" :> DeleteNoContent)
    :<|> NoFilme ("quero-assistir" :> PutNoContent)
    :<|> NoFilme ("quero-assistir" :> DeleteNoContent)
    :<|> NoFilme ("destaque" :> PutNoContent)
    :<|> NoFilme ("destaque" :> DeleteNoContent)

    -- Pessoas
    :<|> "api" :> "usuarios" :> Cookie :> QueryParam "q" String :> Get '[JSON] [UsuarioPublico]
    :<|> NoUsuario (Get '[JSON] Perfil)
    :<|> NoUsuario ("seguir" :> PutNoContent)
    :<|> NoUsuario ("seguir" :> DeleteNoContent)

    -- Qualquer outro caminho: arquivos do front (pasta static)
    :<|> Raw

api :: Proxy API
api = Proxy
