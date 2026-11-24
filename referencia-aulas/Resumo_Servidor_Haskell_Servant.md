Quero criar um servidor web em **Haskell** usando **Cabal**, **Servant**, **Warp** e **Aeson**, estruturado da seguinte forma:

1. **Dependências (`.cabal`)**:
   - `base`, `servant`, `servant-server`, `warp`, `aeson` (e `wai` caso necessário).

2. **Extensões de linguagem necessárias**:
   - `DataKinds`, `DeriveGeneric`, `TypeOperators`, `TypeApplications` (opcional, para `serve @API`).

3. **Modelagem de dados com Aeson**:
   - Criar tipos de dados derivando `Generic` e instanciando `ToJSON` e `FromJSON` (ex.: `data Greeting = Greeting { message :: String, status :: Int }`).

4. **Definição da API a nível de tipos (Servant)**:
   - Usar rotas tipadas sem arquivos externos de configuração, combinando endpoints com `:<|>`, parâmetros/corpo com `:>` e content-type `JSON` (ex.: `"hello" :> Get '[JSON] Greeting` e rotas `POST` com `ReqBody '[JSON] ...`).

5. **Handlers, Server e Execução**:
   - Implementar handlers na mônada `Handler` usando `pure` para retornar os dados.
   - Conectar os handlers ao tipo da API via `Server API` usando `:<|>`.
   - Criar a `Application` com `serve (Proxy :: Proxy API) server` (ou `serve @API server`) e rodar o servidor na porta `8080` com `Network.Wai.Handler.Warp.run`.

Com base nessa arquitetura, me ajude a [DESCREVA AQUI SUA PRÓXIMA TAREFA: ex. criar novos endpoints, conectar ao banco de dados, adicionar CORS ou tratar erros HTTP].