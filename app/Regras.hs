-- Regras do sistema em funções puras (sem banco, sem web).
-- Dá para testar tudo direto no ghci.
module Regras (validarCadastro, normalizarLogin) where

import Data.Char (isAsciiLower, isDigit, toLower)
import Tipos
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
