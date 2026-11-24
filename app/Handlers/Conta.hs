-- Cadastro, login, logout e "quem sou eu"
module Handlers.Conta (cadastrar, entrar, sair, eu) where

import Control.Monad.IO.Class (liftIO)
import Servant
import Api (ComCookie)
import Banco (Conexoes)
import Dados.Usuarios
import Erro (falhar)
import Regras (normalizarLogin, validarCadastro)
import Sessao
import Tipos

-- POST /api/cadastro
cadastrar :: Conexoes -> Cadastro -> Handler (ComCookie UsuarioPublico)
cadastrar conexoes dados =
    case validarCadastro dados of
        Left mensagem -> falhar err400 mensagem
        Right valido  -> do
            talvezHash <- liftIO (hashSenha (cadastroSenha valido))
            case talvezHash of
                Nothing   -> falhar err500 "Não foi possível proteger a senha."
                Just hash -> do
                    resultado <- liftIO (inserirUsuario conexoes valido hash)
                    case resultado of
                        Left mensagem -> falhar err409 mensagem
                        Right usuario -> iniciarSessao conexoes usuario

-- POST /api/login
entrar :: Conexoes -> Login -> Handler (ComCookie UsuarioPublico)
entrar conexoes dados = do
    talvezUsuario <- liftIO (buscarPorLogin conexoes (normalizarLogin (loginUsuario dados)))
    case talvezUsuario of
        Just usuario | senhaConfere (loginSenha dados) usuario -> iniciarSessao conexoes usuario
        _ -> falhar err401 "Usuário ou senha incorretos."

-- POST /api/logout
sair :: Conexoes -> Maybe String -> Handler (ComCookie NoContent)
sair conexoes cookie = do
    liftIO (mapM_ (apagarSessao conexoes) (cookie >>= tokenDoCookie))
    pure (addHeader cookieExpirado NoContent)

-- GET /api/eu
eu :: Conexoes -> Maybe String -> Handler UsuarioPublico
eu conexoes cookie = fmap publico (exigirUsuario conexoes cookie)

-- Cria a sessão no banco e manda o cookie para o navegador
iniciarSessao :: Conexoes -> Usuario -> Handler (ComCookie UsuarioPublico)
iniciarSessao conexoes usuario = do
    token <- liftIO gerarToken
    liftIO (criarSessao conexoes token (usuarioId usuario))
    pure (addHeader (cookieDeSessao token) (publico usuario))
