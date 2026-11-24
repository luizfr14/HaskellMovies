{-# LANGUAGE OverloadedStrings #-}

-- Consultas SQL de filmes: cache do TMDB, avaliações, "quero assistir" e destaques
module Dados.Filmes
    ( filmeSalvo
    , salvarFilme
    , opinioesDosSeguidos
    , minhaAvaliacao
    , minhasListas
    , salvarAvaliacao
    , apagarAvaliacao
    , adicionarQuero
    , removerQuero
    , adicionarDestaque
    , removerDestaque
    , destaquesDe
    , queroAssistirDe
    , avaliacoesDe
    ) where

import Control.Monad (void)
import Data.Maybe (listToMaybe)
import Database.PostgreSQL.Simple
import Banco (Conexoes, comConexao)
import Regras (proximaPosicao)
import Tipos

-- ===== Cache dos filmes =====

filmeSalvo :: Conexoes -> Int -> IO Bool
filmeSalvo conexoes idFilme = do
    linhas <- comConexao conexoes (\conn ->
        query conn "select 1 from filmes where tmdb_id = ?" (Only idFilme)) :: IO [Only Int]
    pure (not (null linhas))

salvarFilme :: Conexoes -> Filme -> IO ()
salvarFilme conexoes f =
    comConexao conexoes (\conn -> void (execute conn
        "insert into filmes (tmdb_id, titulo, poster, ano) values (?, ?, ?, ?) \
        \on conflict (tmdb_id) do update \
        \set titulo = excluded.titulo, poster = excluded.poster, ano = excluded.ano"
        (filmeTmdbId f, filmeTitulo f, filmePoster f, filmeAno f)))

-- ===== Opiniões de quem eu sigo =====

-- Avaliações e "quero assistir" das pessoas que o usuário segue, para estes filmes
opinioesDosSeguidos :: Conexoes -> Int -> [Int] -> IO [Opiniao]
opinioesDosSeguidos _ _ [] = pure []
opinioesDosSeguidos conexoes uid filmes =
    comConexao conexoes (\conn -> query conn
        "select a.tmdb_id, u.username, a.nota::int, a.comentario, false \
        \from avaliacoes a \
        \join seguidores s on s.seguido_id = a.usuario_id \
        \join usuarios u on u.id = a.usuario_id \
        \where s.seguidor_id = ? and a.tmdb_id in ? \
        \union all \
        \select q.tmdb_id, u.username, null, null, true \
        \from quero_assistir q \
        \join seguidores s on s.seguido_id = q.usuario_id \
        \join usuarios u on u.id = q.usuario_id \
        \where s.seguidor_id = ? and q.tmdb_id in ?"
        (uid, In filmes, uid, In filmes))

-- ===== O que eu fiz com um filme =====

minhaAvaliacao :: Conexoes -> Int -> Int -> IO (Maybe (Int, Maybe String))
minhaAvaliacao conexoes uid idFilme = do
    linhas <- comConexao conexoes (\conn -> query conn
        "select nota::int, comentario from avaliacoes where usuario_id = ? and tmdb_id = ?"
        (uid, idFilme))
    pure (listToMaybe linhas)

-- (está no "quero assistir"?, está nos destaques?)
minhasListas :: Conexoes -> Int -> Int -> IO (Bool, Bool)
minhasListas conexoes uid idFilme = do
    linhas <- comConexao conexoes (\conn -> query conn
        "select exists (select 1 from quero_assistir where usuario_id = ? and tmdb_id = ?), \
        \       exists (select 1 from destaques      where usuario_id = ? and tmdb_id = ?)"
        (uid, idFilme, uid, idFilme))
    pure (maybe (False, False) id (listToMaybe linhas))

-- ===== Avaliações =====

-- Avaliar = já assistiu, então o filme sai do "quero assistir"
salvarAvaliacao :: Conexoes -> Int -> Int -> NovaAvaliacao -> IO ()
salvarAvaliacao conexoes uid idFilme nova =
    comConexao conexoes (\conn -> withTransaction conn (do
        void (execute conn
            "insert into avaliacoes (usuario_id, tmdb_id, nota, comentario) values (?, ?, ?, ?) \
            \on conflict (usuario_id, tmdb_id) do update \
            \set nota = excluded.nota, comentario = excluded.comentario, criado_em = now()"
            (uid, idFilme, novaNota nova, novaComentario nova))
        void (execute conn
            "delete from quero_assistir where usuario_id = ? and tmdb_id = ?" (uid, idFilme))))

apagarAvaliacao :: Conexoes -> Int -> Int -> IO ()
apagarAvaliacao conexoes uid idFilme =
    comConexao conexoes (\conn -> void (execute conn
        "delete from avaliacoes where usuario_id = ? and tmdb_id = ?" (uid, idFilme)))

-- ===== Quero assistir =====

adicionarQuero :: Conexoes -> Int -> Int -> IO ()
adicionarQuero conexoes uid idFilme =
    comConexao conexoes (\conn -> void (execute conn
        "insert into quero_assistir (usuario_id, tmdb_id) values (?, ?) on conflict do nothing"
        (uid, idFilme)))

removerQuero :: Conexoes -> Int -> Int -> IO ()
removerQuero conexoes uid idFilme =
    comConexao conexoes (\conn -> void (execute conn
        "delete from quero_assistir where usuario_id = ? and tmdb_id = ?" (uid, idFilme)))

-- ===== Destaques (até 3) =====

-- Coloca o filme na primeira posição livre (1, 2 ou 3)
adicionarDestaque :: Conexoes -> Int -> Int -> IO (Either String ())
adicionarDestaque conexoes uid idFilme = do
    atuais <- comConexao conexoes (\conn -> query conn
        "select posicao::int, tmdb_id from destaques where usuario_id = ?" (Only uid))
    if idFilme `elem` map snd atuais
        then pure (Right ())
        else case proximaPosicao (map fst atuais) of
            Nothing      -> pure (Left "Você já tem 3 destaques. Remova um antes de adicionar outro.")
            Just posicao -> do
                comConexao conexoes (\conn -> void (execute conn
                    "insert into destaques (usuario_id, posicao, tmdb_id) values (?, ?, ?)"
                    (uid, posicao, idFilme)))
                pure (Right ())

removerDestaque :: Conexoes -> Int -> Int -> IO ()
removerDestaque conexoes uid idFilme =
    comConexao conexoes (\conn -> void (execute conn
        "delete from destaques where usuario_id = ? and tmdb_id = ?" (uid, idFilme)))

-- ===== Listas do perfil =====

destaquesDe :: Conexoes -> Int -> IO [Filme]
destaquesDe conexoes uid =
    comConexao conexoes (\conn -> query conn
        "select f.tmdb_id, f.titulo, f.poster, f.ano \
        \from destaques d join filmes f on f.tmdb_id = d.tmdb_id \
        \where d.usuario_id = ? order by d.posicao"
        (Only uid))

queroAssistirDe :: Conexoes -> Int -> IO [Filme]
queroAssistirDe conexoes uid =
    comConexao conexoes (\conn -> query conn
        "select f.tmdb_id, f.titulo, f.poster, f.ano \
        \from quero_assistir q join filmes f on f.tmdb_id = q.tmdb_id \
        \where q.usuario_id = ? order by q.criado_em desc"
        (Only uid))

avaliacoesDe :: Conexoes -> Int -> IO [FilmeAvaliado]
avaliacoesDe conexoes uid =
    comConexao conexoes (\conn -> query conn
        "select f.tmdb_id, f.titulo, f.poster, f.ano, a.nota::int, a.comentario \
        \from avaliacoes a join filmes f on f.tmdb_id = a.tmdb_id \
        \where a.usuario_id = ? order by a.criado_em desc"
        (Only uid))
