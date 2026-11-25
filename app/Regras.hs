module Regras
    ( validarCadastro
    , normalizarLogin
    , validarAvaliacao
    , proximaPosicao
    , compatibilidade
    , emComum
    , validarFoto
    , estatisticas
    , conquistas
    ) where

import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC
import Data.Char (isAsciiLower, isDigit, toLower)
import Data.List (maximumBy, nub)
import Data.Ord (comparing)
import Tipos
import Data.Maybe (listToMaybe)
import Util (aparar)

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

normalizarLogin :: String -> String
normalizarLogin = map toLower . aparar

caractereDeUsername :: Char -> Bool
caractereDeUsername ch = isAsciiLower ch || isDigit ch || ch `elem` "_."

emailValido :: String -> Bool
emailValido email =
    case break (== '@') email of
        (antes, '@' : depois) -> not (null antes) && '.' `elem` depois && '@' `notElem` depois
        _                     -> False

validarAvaliacao :: NovaAvaliacao -> Either String NovaAvaliacao
validarAvaliacao a
    | novaNota a < 1 || novaNota a > 5 = Left "A nota deve ser de 1 a 5 estrelas."
    | maybe 0 length comentario > 500  = Left "O comentário deve ter no máximo 500 caracteres."
    | otherwise                        = Right a { novaComentario = comentario }
  where
    comentario = case fmap aparar (novaComentario a) of
        Just "" -> Nothing
        outro   -> outro

proximaPosicao :: [Int] -> Maybe Int
proximaPosicao usadas = listToMaybe [ p | p <- [1 .. 3], p `notElem` usadas ]

compatibilidade :: [(Int, Int)] -> [(Int, Int)] -> Maybe Int
compatibilidade minhas dele
    | null diferencas = Nothing
    | otherwise       = Just (round (100 * (1 - media / 4)))
  where
    diferencas = [ fromIntegral (abs (a - b)) | (f1, a) <- minhas, (f2, b) <- dele, f1 == f2 ]
    media      = sum diferencas / fromIntegral (length diferencas) :: Double

emComum :: [Filme] -> [Filme] -> [Filme]
emComum minhas dele = filter (\f -> filmeTmdbId f `elem` map filmeTmdbId minhas) dele

validarFoto :: BS.ByteString -> Either String String
validarFoto bytes
    | BS.null bytes                     = Left "Nenhuma foto foi enviada."
    | BS.length bytes > 2 * 1024 * 1024 = Left "A foto deve ter no máximo 2 MB."
    | comecaCom [0xFF, 0xD8, 0xFF]      = Right "image/jpeg"
    | comecaCom [0x89, 0x50, 0x4E, 0x47] = Right "image/png"
    | webp                              = Right "image/webp"
    | otherwise                         = Left "Use uma imagem JPG, PNG ou WebP."
  where
    comecaCom assinatura = BS.pack assinatura `BS.isPrefixOf` bytes
    webp = BS.take 4 bytes == BC.pack "RIFF" && BS.take 4 (BS.drop 8 bytes) == BC.pack "WEBP"

estatisticas :: [FilmeAvaliado] -> Estatisticas
estatisticas avaliados = Estatisticas
    { estatisticasTotal        = length avaliados
    , estatisticasMedia        = media
    , estatisticasDistribuicao = [ length (filter (== n) notas) | n <- [1 .. 5] ]
    , estatisticasDecada       = decadaFavorita
    , estatisticasComentarios  = length [ c | Just c <- map avaliadoComentario avaliados ]
    }
  where
    notas = map avaliadoNota avaliados
    media
        | null notas = Nothing
        | otherwise  = Just (fromIntegral (round (10 * mediaExata) :: Int) / 10)
    mediaExata = fromIntegral (sum notas) / fromIntegral (length notas) :: Double
    decadas = [ (ano `div` 10) * 10 | Just ano <- map (filmeAno . avaliadoFilme) avaliados ]
    decadaFavorita
        | null decadas = Nothing
        | otherwise    = Just (fst (maximumBy (comparing snd)
                            [ (d, length (filter (== d) decadas)) | d <- nub decadas ]))

conquistas :: Estatisticas -> Int -> Int -> [String]
conquistas e seguidores destaques =
    [ nome | (nome, ganhou) <- selos, ganhou ]
  where
    total       = estatisticasTotal e
    mediaNota   = maybe 0 id (estatisticasMedia e)
    selos =
        [ ("Cinéfilo",         total >= 5)
        , ("Crítico",          estatisticasComentarios e >= 3)
        , ("Fácil de agradar", total >= 3 && mediaNota >= 4.5)
        , ("Exigente",         total >= 3 && mediaNota <= 3)
        , ("Fã de clássicos",  maybe False (< 2000) (estatisticasDecada e))
        , ("Popular",          seguidores >= 5)
        , ("Vitrine completa", destaques == 3)
        ]
