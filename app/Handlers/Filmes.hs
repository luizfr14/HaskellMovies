-- Catálogo (TMDB), página do filme, avaliações, "quero assistir" e destaques
module Handlers.Filmes
    ( catalogo
    , detalhe
    , avaliar
    , desavaliar
    , quererAssistir
    , naoQuererAssistir
    , destacar
    , desdestacar
    ) where

import Control.Monad.IO.Class (liftIO)
import Servant
import Banco (Conexoes)
import Dados.Filmes
import Erro (falhar)
import Regras (validarAvaliacao)
import Sessao (exigirUsuario)
import Tipos
import Tmdb
import Util (aparar)

-- GET /api/filmes?q=texto   (sem texto: filmes populares)
catalogo :: Conexoes -> TokenTmdb -> Maybe String -> Maybe String -> Handler [FilmeNaBusca]
catalogo conexoes token cookie texto = do
    usuario <- exigirUsuario conexoes cookie
    talvezFilmes <- liftIO (case fmap aparar texto of
        Just t | not (null t) -> buscarFilmes token t
        _                     -> filmesPopulares token)
    filmes <- maybe semTmdb pure talvezFilmes
    let basicos = map tmdbFilme filmes
    opinioes <- liftIO (opinioesDosSeguidos conexoes (usuarioId usuario) (map filmeTmdbId basicos))
    pure [ FilmeNaBusca f (filter (\o -> opiniaoTmdbId o == filmeTmdbId f) opinioes)
         | f <- basicos ]

-- GET /api/filmes/:id
detalhe :: Conexoes -> TokenTmdb -> Maybe String -> Int -> Handler DetalheFilme
detalhe conexoes token cookie idFilme = do
    usuario <- exigirUsuario conexoes cookie
    talvezFilme <- liftIO (detalheDoFilme token idFilme)
    filme <- maybe naoEncontrado pure talvezFilme
    let uid = usuarioId usuario
    avaliacao        <- liftIO (minhaAvaliacao conexoes uid idFilme)
    (quero, destaque) <- liftIO (minhasListas conexoes uid idFilme)
    amigos           <- liftIO (opinioesDosSeguidos conexoes uid [idFilme])
    pure DetalheFilme
        { detalheFilme         = tmdbFilme filme
        , detalheSinopse       = tmdbSinopse filme
        , detalheMinhaNota     = fmap fst avaliacao
        , detalheMeuComentario = avaliacao >>= snd
        , detalheQueroAssistir = quero
        , detalheDestaque      = destaque
        , detalheAmigos        = amigos
        }

-- PUT /api/filmes/:id/avaliacao
avaliar :: Conexoes -> TokenTmdb -> Maybe String -> Int -> NovaAvaliacao -> Handler NoContent
avaliar conexoes token cookie idFilme nova =
    case validarAvaliacao nova of
        Left mensagem -> falhar err400 mensagem
        Right valida  -> comFilme conexoes token cookie idFilme (\uid ->
            liftIO (salvarAvaliacao conexoes uid idFilme valida))

-- DELETE /api/filmes/:id/avaliacao
desavaliar :: Conexoes -> Maybe String -> Int -> Handler NoContent
desavaliar conexoes cookie idFilme = do
    usuario <- exigirUsuario conexoes cookie
    liftIO (apagarAvaliacao conexoes (usuarioId usuario) idFilme)
    pure NoContent

-- PUT /api/filmes/:id/quero-assistir
quererAssistir :: Conexoes -> TokenTmdb -> Maybe String -> Int -> Handler NoContent
quererAssistir conexoes token cookie idFilme =
    comFilme conexoes token cookie idFilme (\uid -> liftIO (adicionarQuero conexoes uid idFilme))

-- DELETE /api/filmes/:id/quero-assistir
naoQuererAssistir :: Conexoes -> Maybe String -> Int -> Handler NoContent
naoQuererAssistir conexoes cookie idFilme = do
    usuario <- exigirUsuario conexoes cookie
    liftIO (removerQuero conexoes (usuarioId usuario) idFilme)
    pure NoContent

-- PUT /api/filmes/:id/destaque
destacar :: Conexoes -> TokenTmdb -> Maybe String -> Int -> Handler NoContent
destacar conexoes token cookie idFilme =
    comFilme conexoes token cookie idFilme (\uid -> do
        resultado <- liftIO (adicionarDestaque conexoes uid idFilme)
        either (falhar err400) pure resultado)

-- DELETE /api/filmes/:id/destaque
desdestacar :: Conexoes -> Maybe String -> Int -> Handler NoContent
desdestacar conexoes cookie idFilme = do
    usuario <- exigirUsuario conexoes cookie
    liftIO (removerDestaque conexoes (usuarioId usuario) idFilme)
    pure NoContent

-- Garante que o usuário está logado e que o filme está salvo no nosso banco
-- (buscando no TMDB na primeira vez), depois executa a ação.
comFilme :: Conexoes -> TokenTmdb -> Maybe String -> Int -> (Int -> Handler ()) -> Handler NoContent
comFilme conexoes token cookie idFilme acao = do
    usuario <- exigirUsuario conexoes cookie
    salvo   <- liftIO (filmeSalvo conexoes idFilme)
    if salvo
        then pure ()
        else do
            talvezFilme <- liftIO (detalheDoFilme token idFilme)
            filme <- maybe naoEncontrado pure talvezFilme
            liftIO (salvarFilme conexoes (tmdbFilme filme))
    acao (usuarioId usuario)
    pure NoContent

semTmdb :: Handler a
semTmdb = falhar err502 "Não foi possível falar com o TMDB. Tente de novo."

naoEncontrado :: Handler a
naoEncontrado = falhar err404 "Filme não encontrado."
