module Config (Config (..), carregarConfig) where

import Data.Maybe (fromMaybe)
import System.Directory (doesFileExist)
import System.Environment (lookupEnv, setEnv)
import Text.Read (readMaybe)
import Util (aparar)

-- Configurações do sistema, lidas das variáveis de ambiente
data Config = Config
    { urlBanco  :: String  -- DATABASE_URL
    , tokenTmdb :: String  -- TMDB_TOKEN
    , porta     :: Int     -- PORT (padrão 8080)
    }

carregarConfig :: IO Config
carregarConfig = do
    carregarDotEnv
    banco     <- obrigatoria "DATABASE_URL"
    tmdb      <- obrigatoria "TMDB_TOKEN"
    portaTxt  <- lookupEnv "PORT"
    pure Config
        { urlBanco  = banco
        , tokenTmdb = tmdb
        , porta     = fromMaybe 8080 (portaTxt >>= readMaybe)
        }

-- Busca uma variável; se não existir, para o programa com uma mensagem clara
obrigatoria :: String -> IO String
obrigatoria nome = do
    valor <- lookupEnv nome
    case valor of
        Just v | not (null v) -> pure v
        _ -> ioError (userError ("A variavel " ++ nome ++ " nao foi definida. Veja o arquivo .env.example"))

-- Lê o arquivo .env (se existir) e define cada CHAVE=valor como variável de ambiente.
-- Variáveis que já existem (por exemplo, as da hospedagem) não são sobrescritas.
carregarDotEnv :: IO ()
carregarDotEnv = do
    existe <- doesFileExist ".env"
    if existe
        then do
            conteudo <- readFile ".env"
            mapM_ definir (lerPares conteudo)
        else pure ()
  where
    definir (chave, valor) = do
        atual <- lookupEnv chave
        case atual of
            Just _  -> pure ()
            Nothing -> setEnv chave valor

-- Transforma as linhas "CHAVE=valor" em pares, ignorando linhas vazias e comentários (#)
lerPares :: String -> [(String, String)]
lerPares conteudo =
    [ (aparar chave, aparar (drop 1 resto))
    | linha <- lines conteudo
    , let limpa = aparar linha
    , not (null limpa)
    , take 1 limpa /= "#"
    , let (chave, resto) = break (== '=') limpa
    , not (null resto)
    ]
