-- Buscar pessoas, ver perfil, seguir e deixar de seguir
module Handlers.Perfil (pessoas, perfil, seguirUsuario, deixarDeSeguirUsuario) where

import Control.Monad.IO.Class (liftIO)
import Data.Char (toLower)
import Servant
import Banco (Conexoes)
import Dados.Filmes (avaliacoesDe, destaquesDe, queroAssistirDe)
import Dados.Social
import Erro (falhar)
import Sessao (exigirUsuario)
import Tipos
import Util (aparar)

-- GET /api/usuarios?q=texto
pessoas :: Conexoes -> Maybe String -> Maybe String -> Handler [UsuarioPublico]
pessoas conexoes cookie texto = do
    _ <- exigirUsuario conexoes cookie
    case fmap aparar texto of
        Just t | not (null t) -> liftIO (buscarUsuarios conexoes t)
        _                     -> pure []

-- GET /api/usuarios/:username
perfil :: Conexoes -> Maybe String -> String -> Handler Perfil
perfil conexoes cookie username = do
    eu   <- exigirUsuario conexoes cookie
    dono <- acharUsuario conexoes username
    let uid = publicoId dono
    (seguidores, seguindo, euSigo) <- liftIO (contagensDoPerfil conexoes (usuarioId eu) uid)
    destaques  <- liftIO (destaquesDe conexoes uid)
    quero      <- liftIO (queroAssistirDe conexoes uid)
    avaliacoes <- liftIO (avaliacoesDe conexoes uid)
    pure Perfil
        { perfilUsuario       = dono
        , perfilSeguidores    = seguidores
        , perfilSeguindo      = seguindo
        , perfilEuSigo        = euSigo
        , perfilEhVoce        = usuarioId eu == uid
        , perfilDestaques     = destaques
        , perfilQueroAssistir = quero
        , perfilAvaliacoes    = avaliacoes
        }

-- PUT /api/usuarios/:username/seguir
seguirUsuario :: Conexoes -> Maybe String -> String -> Handler NoContent
seguirUsuario conexoes cookie username = do
    eu   <- exigirUsuario conexoes cookie
    alvo <- acharUsuario conexoes username
    if publicoId alvo == usuarioId eu
        then falhar err400 "Você não pode seguir a si mesmo."
        else do
            liftIO (seguir conexoes (usuarioId eu) (publicoId alvo))
            pure NoContent

-- DELETE /api/usuarios/:username/seguir
deixarDeSeguirUsuario :: Conexoes -> Maybe String -> String -> Handler NoContent
deixarDeSeguirUsuario conexoes cookie username = do
    eu   <- exigirUsuario conexoes cookie
    alvo <- acharUsuario conexoes username
    liftIO (deixarDeSeguir conexoes (usuarioId eu) (publicoId alvo))
    pure NoContent

acharUsuario :: Conexoes -> String -> Handler UsuarioPublico
acharUsuario conexoes username = do
    talvez <- liftIO (usuarioPorUsername conexoes (map toLower username))
    maybe (falhar err404 "Usuário não encontrado.") pure talvez
