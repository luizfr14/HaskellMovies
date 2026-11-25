{-# LANGUAGE OverloadedStrings #-}

-- Conversa com a API do TMDB (themoviedb.org)
module Tmdb
    ( TokenTmdb
    , FilmeTmdb (..)
    , filmesPopulares
    , buscarFilmes
    , detalheDoFilme
    ) where

import Control.Exception (try)
import Data.Aeson
import Data.Aeson.Types (Parser)
import qualified Data.ByteString.Char8 as BC
import qualified Data.ByteString.Lazy as LBS
import Data.Maybe (listToMaybe)
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import Network.HTTP.Simple
import Text.Read (readMaybe)
import Tipos (Filme (..), OndeAssistir (..), Provedor (..))

type TokenTmdb = String

-- Um filme como o TMDB devolve: os dados básicos, a sinopse e o trailer
data FilmeTmdb = FilmeTmdb
    { tmdbFilme   :: Filme
    , tmdbSinopse :: String
    , tmdbTrailer :: Maybe String  -- código do vídeo no YouTube (só vem no detalhe)
    , tmdbOnde    :: OndeAssistir  -- onde assistir no Brasil (só vem no detalhe)
    }

-- Lê só os campos que usamos do JSON do TMDB
instance FromJSON FilmeTmdb where
    parseJSON = withObject "Filme" (\o -> do
        idFilme    <- o .:  "id"
        titulo     <- o .:  "title"
        poster     <- o .:? "poster_path"
        lancamento <- o .:? "release_date"
        sinopse    <- o .:? "overview"
        videos     <- o .:? "videos"
        onde       <- o .:? "watch/providers"
        pure (FilmeTmdb (Filme idFilme titulo poster (lancamento >>= anoDe))
                        (maybe "" id sinopse)
                        (videos >>= escolherTrailer)
                        (maybe semProvedores (\(OndeTmdb x) -> x) onde)))

semProvedores :: OndeAssistir
semProvedores = OndeAssistir [] [] [] []

-- Um serviço: { "provider_name": "HBO Max", "logo_path": "/abc.jpg", ... }
newtype ProvedorTmdb = ProvedorTmdb Provedor

instance FromJSON ProvedorTmdb where
    parseJSON = withObject "Provedor" (\o ->
        ProvedorTmdb <$> (Provedor <$> o .: "provider_name" <*> o .:? "logo_path"))

-- { "results": { "BR": { "flatrate": [...], "rent": [...], "buy": [...], "free": [...], "ads": [...] } } }
-- Pegamos só o Brasil. Se o filme não tem dados lá, todas as listas ficam vazias.
newtype OndeTmdb = OndeTmdb OndeAssistir

instance FromJSON OndeTmdb where
    parseJSON = withObject "Provedores" (\o -> do
        paises <- o .:? "results" .!= mempty
        brasil <- paises .:? "BR" .!= mempty
        let lista :: Key -> Parser [Provedor]
            lista tipo = map (\(ProvedorTmdb p) -> p) <$> (brasil .:? tipo .!= [])
        streaming <- lista "flatrate"
        alugar    <- lista "rent"
        comprar   <- lista "buy"
        gratis    <- lista "free"
        comAnuncio <- lista "ads"
        pure (OndeTmdb (OndeAssistir streaming alugar comprar (gratis ++ comAnuncio))))

-- Um vídeo do filme: { "key": "YoHD9XEInc0", "site": "YouTube", "type": "Trailer" }
data Video = Video String String String

instance FromJSON Video where
    parseJSON = withObject "Video" (\o -> Video <$> o .: "key" <*> o .: "site" <*> o .: "type")

-- Os vídeos vêm dentro de { "results": [...] }
newtype Videos = Videos [Video]

instance FromJSON Videos where
    parseJSON = withObject "Videos" (\o -> Videos <$> o .: "results")

-- O primeiro trailer do YouTube da lista
escolherTrailer :: Videos -> Maybe String
escolherTrailer (Videos lista) =
    listToMaybe [ chave | Video chave site tipo <- lista, site == "YouTube", tipo == "Trailer" ]

-- As listas do TMDB vêm dentro de { "results": [...] }
newtype Pagina = Pagina [FilmeTmdb]

instance FromJSON Pagina where
    parseJSON = withObject "Pagina" (\o -> Pagina <$> o .: "results")

-- "2010-07-15" -> Just 2010   |   "" -> Nothing
anoDe :: String -> Maybe Int
anoDe = readMaybe . take 4

filmesPopulares :: TokenTmdb -> IO (Maybe [FilmeTmdb])
filmesPopulares token = fmap (fmap resultados) (consultar token "/movie/popular" [])

buscarFilmes :: TokenTmdb -> String -> IO (Maybe [FilmeTmdb])
buscarFilmes token texto =
    fmap (fmap resultados)
         (consultar token "/search/movie" [("query", texto), ("include_adult", "false")])

detalheDoFilme :: TokenTmdb -> Int -> IO (Maybe FilmeTmdb)
detalheDoFilme token idFilme =
    -- append_to_response traz os vídeos (trailer) e os serviços de streaming na mesma chamada
    consultar token ("/movie/" ++ show idFilme)
        [("append_to_response", "videos,watch/providers"), ("include_video_language", "pt,en")]

resultados :: Pagina -> [FilmeTmdb]
resultados (Pagina filmes) = filmes

-- Faz um GET no TMDB e converte o JSON.
-- Devolve Nothing se a internet falhar, o filme não existir ou o JSON vier diferente.
consultar :: FromJSON a => TokenTmdb -> String -> [(BC.ByteString, String)] -> IO (Maybe a)
consultar token caminho parametros = do
    resposta <- try (httpLBS requisicao) :: IO (Either HttpException (Response LBS.ByteString))
    pure (case resposta of
        Right r | getResponseStatusCode r == 200 -> decode (getResponseBody r)
        _                                        -> Nothing)
  where
    requisicao =
          setRequestHeader "Authorization" [BC.pack ("Bearer " ++ token)]
        $ setRequestQueryString [ (chave, Just (encodeUtf8 (T.pack valor)))
                                | (chave, valor) <- ("language", "pt-BR") : parametros ]
        $ parseRequest_ ("https://api.themoviedb.org/3" ++ caminho)
