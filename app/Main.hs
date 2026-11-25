module Main (main) where

import Network.Wai.Handler.Warp (run)
import Servant (serve)
import System.IO (BufferMode (LineBuffering), hSetBuffering, stdout)
import Api (api)
import Banco (criarConexoes)
import Config
import Handlers (servidor)

main :: IO ()
main = do
    -- Mostra cada linha de log na hora (sem isso o texto fica preso no buffer)
    hSetBuffering stdout LineBuffering
    config   <- carregarConfig
    conexoes <- criarConexoes (urlBanco config)
    putStrLn ("HaskellMovies rodando em http://localhost:" ++ show (porta config))
    run (porta config) (serve api (servidor conexoes (tokenTmdb config) (armazenamento config)))
