{-# LANGUAGE OverloadedStrings #-}

-- Consultas SQL de usuários e sessões
module Dados.Usuarios
    ( inserirUsuario
    , buscarPorLogin
    , criarSessao
    , buscarUsuarioDaSessao
    , apagarSessao
    ) where

import Control.Exception (throwIO, try)
import Control.Monad (void)
import Data.Maybe (listToMaybe)
import Database.PostgreSQL.Simple
import Banco (Conexoes, comConexao)
import Tipos

-- Cadastra o usuário. Se o username ou e-mail já existir, devolve Left com a mensagem.
inserirUsuario :: Conexoes -> Cadastro -> String -> IO (Either String Usuario)
inserirUsuario conexoes c hash = do
    resultado <- try (comConexao conexoes (\conn ->
        query conn
            "insert into usuarios (nome, username, email, senha_hash) \
            \values (?, ?, ?, ?) \
            \returning id, nome, username, email, senha_hash"
            (cadastroNome c, cadastroUsername c, cadastroEmail c, hash)))
        :: IO (Either SqlError [Usuario])
    case resultado of
        Right (usuario : _) -> pure (Right usuario)
        Right []            -> pure (Left "Não foi possível concluir o cadastro.")
        Left erro
            | sqlState erro == "23505" -> pure (Left "Esse username ou e-mail já está em uso.")
            | otherwise                -> throwIO erro

-- Procura pelo username ou pelo e-mail
buscarPorLogin :: Conexoes -> String -> IO (Maybe Usuario)
buscarPorLogin conexoes login = do
    linhas <- comConexao conexoes (\conn ->
        query conn
            "select id, nome, username, email, senha_hash \
            \from usuarios where username = ? or email = ?"
            (login, login))
    pure (listToMaybe linhas)

criarSessao :: Conexoes -> String -> Int -> IO ()
criarSessao conexoes token uid =
    comConexao conexoes (\conn ->
        void (execute conn "insert into sessoes (token, usuario_id) values (?, ?)" (token, uid)))

-- Sessões valem por 30 dias
buscarUsuarioDaSessao :: Conexoes -> String -> IO (Maybe Usuario)
buscarUsuarioDaSessao conexoes token = do
    linhas <- comConexao conexoes (\conn ->
        query conn
            "select u.id, u.nome, u.username, u.email, u.senha_hash \
            \from sessoes s join usuarios u on u.id = s.usuario_id \
            \where s.token = ? and s.criado_em > now() - interval '30 days'"
            (Only token))
    pure (listToMaybe linhas)

apagarSessao :: Conexoes -> String -> IO ()
apagarSessao conexoes token =
    comConexao conexoes (\conn ->
        void (execute conn "delete from sessoes where token = ?" (Only token)))
