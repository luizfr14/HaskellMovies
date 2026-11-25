-- Cadastro, login, logout e "quem sou eu"
module Handlers.Conta (cadastrar, entrar, sair, eu, trocarFoto) where

import Control.Monad.IO.Class (liftIO)
import qualified Data.ByteString as BS
import Servant
import Api (ComCookie)
import Armazenamento (Armazenamento, enviarFoto)
import Banco (Conexoes)
import Dados.Usuarios
import Erro (falhar)
import Regras (normalizarLogin, validarCadastro, validarFoto)
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

-- PUT /api/eu/foto   (o corpo da requisição é a própria imagem)
trocarFoto :: Conexoes -> Maybe Armazenamento -> Maybe String -> BS.ByteString -> Handler UsuarioPublico
trocarFoto conexoes talvezArmazenamento cookie bytes = do
    usuario <- exigirUsuario conexoes cookie
    tipo    <- either (falhar err400) pure (validarFoto bytes)
    armazenamento <- maybe (falhar err503 "A troca de foto não está configurada neste servidor.")
                           pure talvezArmazenamento
    resultado <- liftIO (enviarFoto armazenamento (usuarioId usuario) tipo bytes)
    case resultado of
        Nothing  -> falhar err502 "Não foi possível salvar a foto. Tente de novo."
        Just url -> do
            -- O ?v=... muda a cada troca, assim o navegador não mostra a foto antiga
            versao <- liftIO (fmap (take 10) gerarToken)
            let endereco = url ++ "?v=" ++ versao
            liftIO (salvarFoto conexoes (usuarioId usuario) endereco)
            pure (publico usuario { usuarioFoto = Just endereco })

-- Cria a sessão no banco e manda o cookie para o navegador
iniciarSessao :: Conexoes -> Usuario -> Handler (ComCookie UsuarioPublico)
iniciarSessao conexoes usuario = do
    token <- liftIO gerarToken
    liftIO (criarSessao conexoes token (usuarioId usuario))
    pure (addHeader (cookieDeSessao token) (publico usuario))
