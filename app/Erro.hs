{-# LANGUAGE OverloadedStrings #-}

module Erro (falhar) where

import Data.Aeson (encode)
import Servant
import Tipos (Erro (..))

-- Interrompe o handler com um erro HTTP e uma mensagem em JSON.
-- Ex.: falhar err401 "Faça login para continuar."
falhar :: ServerError -> String -> Handler a
falhar erro mensagem =
    throwError erro
        { errBody    = encode (Erro mensagem)
        , errHeaders = [("Content-Type", "application/json; charset=utf-8")]
        }
