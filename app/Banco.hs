module Banco (Conexoes, criarConexoes, comConexao) where

import qualified Data.ByteString.Char8 as BC
import Data.Pool (Pool, defaultPoolConfig, newPool, withResource)
import Database.PostgreSQL.Simple (Connection, close, connectPostgreSQL)

-- Um "pool" guarda algumas conexões abertas com o banco e as reaproveita,
-- em vez de abrir uma conexão nova a cada requisição.
type Conexoes = Pool Connection

-- Até 5 conexões; uma conexão parada por 60 segundos é fechada.
criarConexoes :: String -> IO Conexoes
criarConexoes url =
    newPool (defaultPoolConfig (connectPostgreSQL (BC.pack url)) close 60 5)

-- Pega uma conexão do pool, usa e devolve
comConexao :: Conexoes -> (Connection -> IO a) -> IO a
comConexao = withResource
