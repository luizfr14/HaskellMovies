-- Login: senhas, token da sessão e cookie
module Sessao
    ( hashSenha
    , senhaConfere
    , gerarToken
    , cookieDeSessao
    , cookieExpirado
    , tokenDoCookie
    , exigirUsuario
    ) where

import Control.Monad.IO.Class (liftIO)
import Crypto.BCrypt (hashPasswordUsingPolicy, slowerBcryptHashingPolicy, validatePassword)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import Servant (Handler, err401)
import System.Entropy (getEntropy)
import Text.Printf (printf)
import Banco (Conexoes)
import Dados.Usuarios (buscarUsuarioDaSessao)
import Erro (falhar)
import Tipos
import Util (aparar, separar)

-- ===== Senhas =====

-- Gera o hash bcrypt da senha (é isso que vai para o banco)
hashSenha :: String -> IO (Maybe String)
hashSenha senha =
    fmap (fmap BC.unpack) (hashPasswordUsingPolicy slowerBcryptHashingPolicy (emBytes senha))

senhaConfere :: String -> Usuario -> Bool
senhaConfere senha u = validatePassword (BC.pack (usuarioSenhaHash u)) (emBytes senha)

emBytes :: String -> BS.ByteString
emBytes = encodeUtf8 . T.pack

-- ===== Token e cookie =====

-- 32 bytes aleatórios em hexadecimal (64 caracteres), impossível de adivinhar
gerarToken :: IO String
gerarToken = do
    bytes <- getEntropy 32
    pure (concatMap (\b -> printf "%02x" b) (BS.unpack bytes))

nomeDoCookie :: String
nomeDoCookie = "sessao"

-- HttpOnly: o JavaScript da página não consegue ler o cookie
-- SameSite=Lax: outros sites não conseguem usar a sessão
cookieDeSessao :: String -> String
cookieDeSessao token =
    nomeDoCookie ++ "=" ++ token ++ "; Path=/; HttpOnly; SameSite=Lax; Max-Age=2592000"

cookieExpirado :: String
cookieExpirado = nomeDoCookie ++ "=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0"

-- O navegador manda os cookies assim: "tema=escuro; sessao=abc123"
-- tokenDoCookie "tema=escuro; sessao=abc123" == Just "abc123"
tokenDoCookie :: String -> Maybe String
tokenDoCookie cabecalho = lookup nomeDoCookie pares
  where
    pares = [ (aparar chave, drop 1 valor)
            | parte <- separar ';' cabecalho
            , let (chave, valor) = break (== '=') parte
            ]

-- ===== Rotas protegidas =====

-- Descobre quem está logado pelo cookie; se ninguém, responde 401
exigirUsuario :: Conexoes -> Maybe String -> Handler Usuario
exigirUsuario conexoes cookie =
    case cookie >>= tokenDoCookie of
        Nothing    -> naoLogado
        Just token -> do
            resultado <- liftIO (buscarUsuarioDaSessao conexoes token)
            maybe naoLogado pure resultado
  where
    naoLogado = falhar err401 "Faça login para continuar."
