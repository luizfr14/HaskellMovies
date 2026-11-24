module Util (aparar, separar) where

import Data.Char (isSpace)

-- Remove espaços (e quebras de linha) do começo e do fim
-- aparar "  ola  " == "ola"
aparar :: String -> String
aparar = tirarDoInicio . tirarDoFim
  where
    tirarDoInicio = dropWhile isSpace
    tirarDoFim    = reverse . dropWhile isSpace . reverse

-- Quebra o texto em pedaços a cada separador
-- separar ';' "a=1; b=2" == ["a=1", " b=2"]
separar :: Char -> String -> [String]
separar sep texto =
    case break (== sep) texto of
        (pedaco, [])        -> [pedaco]
        (pedaco, _ : resto) -> pedaco : separar sep resto
