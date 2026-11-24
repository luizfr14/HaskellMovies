{-# LANGUAGE OverloadedStrings #-}

-- Consultas SQL da parte social: buscar pessoas, perfil e seguir
module Dados.Social
    ( buscarUsuarios
    , usuarioPorUsername
    , contagensDoPerfil
    , seguir
    , deixarDeSeguir
    ) where

import Control.Monad (void)
import Data.Maybe (listToMaybe)
import Database.PostgreSQL.Simple
import Banco (Conexoes, comConexao)
import Tipos

-- Procura pelo nome ou username (sem diferenciar maiúsculas)
buscarUsuarios :: Conexoes -> String -> IO [UsuarioPublico]
buscarUsuarios conexoes texto =
    comConexao conexoes (\conn -> query conn
        "select id, nome, username from usuarios \
        \where username ilike ? or nome ilike ? \
        \order by username limit 20"
        (padrao, padrao))
  where
    padrao = "%" ++ texto ++ "%"

usuarioPorUsername :: Conexoes -> String -> IO (Maybe UsuarioPublico)
usuarioPorUsername conexoes username = do
    linhas <- comConexao conexoes (\conn -> query conn
        "select id, nome, username from usuarios where username = ?" (Only username))
    pure (listToMaybe linhas)

-- (seguidores, seguindo, eu sigo essa pessoa?)
contagensDoPerfil :: Conexoes -> Int -> Int -> IO (Int, Int, Bool)
contagensDoPerfil conexoes eu dono = do
    linhas <- comConexao conexoes (\conn -> query conn
        "select (select count(*)::int from seguidores where seguido_id  = ?), \
        \       (select count(*)::int from seguidores where seguidor_id = ?), \
        \       exists (select 1 from seguidores where seguidor_id = ? and seguido_id = ?)"
        (dono, dono, eu, dono))
    pure (maybe (0, 0, False) id (listToMaybe linhas))

seguir :: Conexoes -> Int -> Int -> IO ()
seguir conexoes eu outro =
    comConexao conexoes (\conn -> void (execute conn
        "insert into seguidores (seguidor_id, seguido_id) values (?, ?) on conflict do nothing"
        (eu, outro)))

deixarDeSeguir :: Conexoes -> Int -> Int -> IO ()
deixarDeSeguir conexoes eu outro =
    comConexao conexoes (\conn -> void (execute conn
        "delete from seguidores where seguidor_id = ? and seguido_id = ?" (eu, outro)))
