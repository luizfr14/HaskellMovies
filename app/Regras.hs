-- Regras do sistema em funções puras (sem banco, sem web).
-- Dá para testar tudo direto no ghci.
module Regras (validarCadastro, normalizarLogin, validarAvaliacao, proximaPosicao) where

import Data.Char (isAsciiLower, isDigit, toLower)
import Tipos
import Data.Maybe (listToMaybe)
import Util (aparar)

-- Confere o cadastro e devolve os dados já limpos (sem espaços, username e e-mail minúsculos)
-- ou a mensagem do primeiro problema encontrado.
validarCadastro :: Cadastro -> Either String Cadastro
validarCadastro c
    | length nome < 2                     = Left "Informe seu nome."
    | length user < 3 || length user > 20 = Left "O username deve ter de 3 a 20 caracteres."
    | not (all caractereDeUsername user)  = Left "O username só pode ter letras minúsculas, números, _ e ponto."
    | not (emailValido email)             = Left "E-mail inválido."
    | length senha < 6                    = Left "A senha deve ter pelo menos 6 caracteres."
    | length senha > 72                   = Left "A senha deve ter no máximo 72 caracteres."
    | otherwise = Right c { cadastroNome = nome, cadastroUsername = user, cadastroEmail = email }
  where
    nome  = aparar (cadastroNome c)
    user  = normalizarLogin (cadastroUsername c)
    email = normalizarLogin (cadastroEmail c)
    senha = cadastroSenha c

-- Username e e-mail são comparados sem espaços e em minúsculas
normalizarLogin :: String -> String
normalizarLogin = map toLower . aparar

caractereDeUsername :: Char -> Bool
caractereDeUsername ch = isAsciiLower ch || isDigit ch || ch `elem` "_."

-- Precisa ter algo antes do @, e um ponto depois dele
emailValido :: String -> Bool
emailValido email =
    case break (== '@') email of
        (antes, '@' : depois) -> not (null antes) && '.' `elem` depois && '@' `notElem` depois
        _                     -> False

-- Nota de 1 a 5; comentário opcional (vazio vira Nothing) com até 500 caracteres
validarAvaliacao :: NovaAvaliacao -> Either String NovaAvaliacao
validarAvaliacao a
    | novaNota a < 1 || novaNota a > 5 = Left "A nota deve ser de 1 a 5 estrelas."
    | maybe 0 length comentario > 500  = Left "O comentário deve ter no máximo 500 caracteres."
    | otherwise                        = Right a { novaComentario = comentario }
  where
    comentario = case fmap aparar (novaComentario a) of
        Just "" -> Nothing
        outro   -> outro

-- Primeira posição de destaque livre (1 a 3), ou Nothing se já tem 3
-- proximaPosicao [1, 3] == Just 2      proximaPosicao [1, 2, 3] == Nothing
proximaPosicao :: [Int] -> Maybe Int
proximaPosicao usadas = listToMaybe [ p | p <- [1 .. 3], p `notElem` usadas ]
