{-# LANGUAGE DeriveGeneric #-}

module Tipos where

import Data.Aeson
import Data.Char (isLower, toLower)
import Database.PostgreSQL.Simple.FromRow (FromRow)
import GHC.Generics (Generic)

-- No JSON, os campos aparecem sem o prefixo do tipo:
--   cadastroNome -> "nome",  publicoId -> "id"
opcoesJson :: Options
opcoesJson = defaultOptions { fieldLabelModifier = semPrefixo }

semPrefixo :: String -> String
semPrefixo campo =
    case dropWhile isLower campo of
        (c : resto) -> toLower c : resto
        []          -> campo

-- ===== Usuários =====

-- Usuário como está no banco (tem o hash da senha, nunca vai para o navegador)
data Usuario = Usuario
    { usuarioId        :: Int
    , usuarioNome      :: String
    , usuarioUsername  :: String
    , usuarioEmail     :: String
    , usuarioSenhaHash :: String
    } deriving (Show, Generic)

instance FromRow Usuario

-- O que o navegador pode ver de um usuário
data UsuarioPublico = UsuarioPublico
    { publicoId       :: Int
    , publicoNome     :: String
    , publicoUsername :: String
    } deriving (Show, Eq, Generic)

instance ToJSON UsuarioPublico where
    toJSON = genericToJSON opcoesJson

publico :: Usuario -> UsuarioPublico
publico u = UsuarioPublico (usuarioId u) (usuarioNome u) (usuarioUsername u)

-- Dados enviados pelo formulário de cadastro
data Cadastro = Cadastro
    { cadastroNome     :: String
    , cadastroUsername :: String
    , cadastroEmail    :: String
    , cadastroSenha    :: String
    } deriving (Show, Generic)

instance FromJSON Cadastro where
    parseJSON = genericParseJSON opcoesJson

-- Dados enviados pelo formulário de login (usuario = username ou e-mail)
data Login = Login
    { loginUsuario :: String
    , loginSenha   :: String
    } deriving (Show, Generic)

instance FromJSON Login where
    parseJSON = genericParseJSON opcoesJson

-- ===== Erros =====

-- Corpo das respostas de erro: { "mensagem": "..." }
newtype Erro = Erro { erroMensagem :: String } deriving (Show, Generic)

instance ToJSON Erro where
    toJSON = genericToJSON opcoesJson
