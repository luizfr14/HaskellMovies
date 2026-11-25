{-# LANGUAGE TypeOperators #-}

module Handlers (servidor) where

import Servant
import Api (API)
import Armazenamento (Armazenamento)
import Banco (Conexoes)
import Handlers.Conta
import Handlers.Filmes
import Handlers.Perfil
import Tmdb (TokenTmdb)

-- Liga cada rota da API ao seu handler, na mesma ordem do tipo API
servidor :: Conexoes -> TokenTmdb -> Maybe Armazenamento -> Server API
servidor conexoes token armazenamento =
    -- Conta
         cadastrar conexoes
    :<|> entrar conexoes
    :<|> sair conexoes
    :<|> eu conexoes
    :<|> trocarFoto conexoes armazenamento

    -- Filmes
    :<|> catalogo conexoes token
    :<|> detalhe conexoes token
    :<|> avaliar conexoes token
    :<|> desavaliar conexoes
    :<|> quererAssistir conexoes token
    :<|> naoQuererAssistir conexoes
    :<|> destacar conexoes token
    :<|> desdestacar conexoes

    -- Pessoas
    :<|> pessoas conexoes
    :<|> perfil conexoes
    :<|> seguirUsuario conexoes
    :<|> deixarDeSeguirUsuario conexoes

    :<|> serveDirectoryFileServer "static"  -- "/" abre o static/index.html
