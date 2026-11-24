module Estudos where

verificaLength :: String -> Bool
verificaLength str = mod (length str) 2 == 0

reverseString :: [String] -> [String]
reverseString letras = map (\letra -> reverse letra) letras

paresPares :: [(Int, Int)]
paresPares = [(x,y) | x <- [1 .. 3], y <- [1 .. 3], mod (x+y) 2 == 0]

penultDaLista lista = head (tail(reverse lista))