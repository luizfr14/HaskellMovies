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
import qualified Data.ByteString.Char8 as BC
import qualified Data.ByteString.Lazy as LBS
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import Network.HTTP.Simple
import Text.Read (readMaybe)
import Tipos (Filme (..))

type TokenTmdb = String

-- Um filme como o TMDB devolve: os dados básicos + a sinopse
data FilmeTmdb = FilmeTmdb
    { tmdbFilme   :: Filme
    , tmdbSinopse :: String
    }

-- Lê só os campos que usamos do JSON do TMDB
instance FromJSON FilmeTmdb where
    parseJSON = withObject "Filme" (\o -> do
        idFilme    <- o .:  "id"
        titulo     <- o .:  "title"
        poster     <- o .:? "poster_path"
        lancamento <- o .:? "release_date"
        sinopse    <- o .:? "overview"
        pure (FilmeTmdb (Filme idFilme titulo poster (lancamento >>= anoDe))
                        (maybe "" id sinopse)))

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
detalheDoFilme token idFilme = consultar token ("/movie/" ++ show idFilme) []

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
