{-# LANGUAGE DeriveGeneric #-}

module Tipos where

import Data.Aeson
import Data.Char (isLower, toLower)
import Database.PostgreSQL.Simple.FromRow (FromRow (..), field)
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
    , usuarioFoto      :: Maybe String  -- endereço da foto no Supabase Storage
    } deriving (Show, Generic)

instance FromRow Usuario


-- O que o navegador pode ver de um usuário
data UsuarioPublico = UsuarioPublico
    { publicoId       :: Int
    , publicoNome     :: String
    , publicoUsername :: String
    , publicoFoto     :: Maybe String
    } deriving (Show, Eq, Generic)

instance FromRow UsuarioPublico

instance ToJSON UsuarioPublico where
    toJSON = genericToJSON opcoesJson

publico :: Usuario -> UsuarioPublico
publico u = UsuarioPublico (usuarioId u) (usuarioNome u) (usuarioUsername u) (usuarioFoto u)

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

-- ===== Filmes =====

-- Filme como guardamos no banco e mostramos nas listas
-- (poster é o caminho da imagem no TMDB, ex: "/abc123.jpg")
data Filme = Filme
    { filmeTmdbId :: Int
    , filmeTitulo :: String
    , filmePoster :: Maybe String
    , filmeAno    :: Maybe Int
    } deriving (Show, Generic)

instance FromRow Filme

instance ToJSON Filme where
    toJSON = genericToJSON opcoesJson

-- O que alguém que eu sigo achou de um filme
data Opiniao = Opiniao
    { opiniaoTmdbId       :: Int
    , opiniaoUsername     :: String
    , opiniaoNota         :: Maybe Int     -- Nothing = ainda não avaliou
    , opiniaoComentario   :: Maybe String
    , opiniaoQuerAssistir :: Bool
    } deriving (Show, Generic)

instance FromRow Opiniao

instance ToJSON Opiniao where
    toJSON = genericToJSON opcoesJson

-- Um filme no resultado da busca, com as opiniões de quem eu sigo
data FilmeNaBusca = FilmeNaBusca
    { buscaFilme  :: Filme
    , buscaAmigos :: [Opiniao]
    } deriving (Show, Generic)

instance ToJSON FilmeNaBusca where
    toJSON = genericToJSON opcoesJson

-- Página do filme: dados do TMDB + o que eu e meus amigos fizemos com ele
data DetalheFilme = DetalheFilme
    { detalheFilme         :: Filme
    , detalheSinopse       :: String
    , detalheMinhaNota     :: Maybe Int
    , detalheMeuComentario :: Maybe String
    , detalheQueroAssistir :: Bool
    , detalheDestaque      :: Bool
    , detalheAmigos        :: [Opiniao]
    , detalheTrailer       :: Maybe String  -- código do vídeo no YouTube
    , detalheOnde          :: OndeAssistir
    } deriving (Show, Generic)

instance ToJSON DetalheFilme where
    toJSON = genericToJSON opcoesJson

-- Corpo do PUT /api/filmes/:id/avaliacao
data NovaAvaliacao = NovaAvaliacao
    { novaNota       :: Int
    , novaComentario :: Maybe String
    } deriving (Show, Generic)

instance FromJSON NovaAvaliacao where
    parseJSON = genericParseJSON opcoesJson

-- Filme avaliado, como aparece no perfil
data FilmeAvaliado = FilmeAvaliado
    { avaliadoFilme      :: Filme
    , avaliadoNota       :: Int
    , avaliadoComentario :: Maybe String
    } deriving (Show, Generic)

instance FromRow FilmeAvaliado where
    fromRow = FilmeAvaliado <$> fromRow <*> field <*> field

instance ToJSON FilmeAvaliado where
    toJSON = genericToJSON opcoesJson

-- ===== Perfil =====

data Perfil = Perfil
    { perfilUsuario       :: UsuarioPublico
    , perfilSeguidores    :: Int
    , perfilSeguindo      :: Int
    , perfilEuSigo        :: Bool
    , perfilEhVoce        :: Bool
    , perfilDestaques     :: [Filme]
    , perfilQueroAssistir :: [Filme]
    , perfilAvaliacoes    :: [FilmeAvaliado]
    , perfilCompatibilidade :: Maybe Int  -- 0 a 100; Nothing se não há filmes em comum
    , perfilEmComum       :: [Filme]      -- filmes que os dois querem assistir
    , perfilEstatisticas  :: Estatisticas
    , perfilConquistas    :: [String]     -- selos ganhos (ex.: "Cinéfilo")
    } deriving (Show, Generic)

instance ToJSON Perfil where
    toJSON = genericToJSON opcoesJson

-- Números do perfil, calculados a partir das avaliações
data Estatisticas = Estatisticas
    { estatisticasTotal        :: Int
    , estatisticasMedia        :: Maybe Double  -- Nothing se ainda não avaliou nada
    , estatisticasDistribuicao :: [Int]         -- quantos filmes receberam 1, 2, 3, 4 e 5 estrelas
    , estatisticasDecada       :: Maybe Int     -- década com mais filmes avaliados (ex.: 2010)
    , estatisticasComentarios  :: Int           -- avaliações em que escreveu um comentário
    } deriving (Show, Generic)

instance ToJSON Estatisticas where
    toJSON = genericToJSON opcoesJson

-- Um serviço onde o filme está disponível (logo = caminho da imagem no TMDB)
data Provedor = Provedor
    { provedorNome :: String
    , provedorLogo :: Maybe String
    } deriving (Show, Generic)

instance ToJSON Provedor where
    toJSON = genericToJSON opcoesJson

-- Onde assistir no Brasil (dados do TMDB, fornecidos pela JustWatch)
data OndeAssistir = OndeAssistir
    { ondeStreaming :: [Provedor]  -- incluso na assinatura
    , ondeAlugar    :: [Provedor]
    , ondeComprar   :: [Provedor]
    , ondeGratis    :: [Provedor]  -- grátis, com ou sem anúncios
    } deriving (Show, Generic)

instance ToJSON OndeAssistir where
    toJSON = genericToJSON opcoesJson
