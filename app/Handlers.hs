{-# LANGUAGE TypeOperators #-}

module Handlers (servidor) where

import Servant
import Api (API)
import Banco (Conexoes)
import Handlers.Conta

-- Liga cada rota da API ao seu handler, na mesma ordem do tipo API
servidor :: Conexoes -> Server API
servidor conexoes =
         cadastrar conexoes
    :<|> entrar conexoes
    :<|> sair conexoes
    :<|> eu conexoes
    :<|> serveDirectoryFileServer "static"  -- "/" abre o static/index.html
