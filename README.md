# HaskellMovies

Rede social de filmes feita para a disciplina de Haskell da Fatec.

- **Catálogo:** filmes populares e busca por nome, com dados e pôsteres do [TMDB](https://www.themoviedb.org).
- **Opinião dos amigos:** na busca e na página do filme aparecem a nota e o "quero assistir" de quem você segue.
- **Página do filme:** pôster, título, ano e sinopse; nota de 1 a 5 estrelas com comentário opcional.
- **Listas:** "quero assistir" e até 3 filmes em destaque no perfil. Avaliar um filme tira ele do "quero assistir".
- **Pessoas:** buscar por nome ou username, seguir e deixar de seguir.
- **Perfil:** seguidores, seguindo, os 3 destaques e as abas "Avaliados" e "Quero assistir".
- **Conta:** cadastro, login e logout, com senha protegida por bcrypt e sessão em cookie.

## Tecnologias

- **Backend (100% Haskell):** Servant, Warp e Aeson; `postgresql-simple` para o banco; `http-conduit` para chamar o TMDB.
- **Banco:** PostgreSQL no Supabase. O schema está em [db/schema.sql](db/schema.sql).
- **Frontend:** HTML, CSS e JavaScript simples com `fetch`, sem recarregar a página. Visual escuro no estilo do Instagram, com a fonte Sora.

## Como rodar

### O que instalar

| Programa | Para quê |
|---|---|
| [Git](https://git-scm.com/downloads) | Baixar o projeto |
| [VS Code](https://code.visualstudio.com) | Editor recomendado; o terminal dele já vem configurado para o projeto |
| [GHCup](https://www.haskell.org/ghcup/) | Instala o GHC (compilador Haskell) e o Cabal (gerenciador de pacotes) |
| `libpq` | Biblioteca do PostgreSQL usada pelo `postgresql-simple` (passo 3) |

Versões testadas: **GHC 9.10.3** e **Cabal 3.16.1**.

### 1. Baixar o projeto

```
git clone https://github.com/luizfr14/HaskellMovies.git
cd HaskellMovies
```

### 2. Instalar o Haskell (GHCup)

**Windows:** siga as instruções do [site do GHCup](https://www.haskell.org/ghcup/). Ele roda um comando no PowerShell que instala tudo em `C:\ghcup`. **Mantenha essa pasta**, porque o `.vscode/settings.json` do projeto depende dela. Depois instale as versões testadas:

```
C:\ghcup\bin\ghcup.exe install ghc 9.10.3 --set
C:\ghcup\bin\ghcup.exe install cabal 3.16.1.0 --set
```

**Linux / macOS:** use o comando do site do GHCup e depois `ghcup install ghc 9.10.3 --set` e `ghcup install cabal 3.16.1.0 --set`.

### 3. Instalar a `libpq` (biblioteca do PostgreSQL)

**Windows:** pelo MSYS2 que vem junto com o GHCup:

```
C:\ghcup\msys64\usr\bin\bash.exe -lc "pacman -Sy --noconfirm mingw-w64-x86_64-postgresql"
```

**Linux (Ubuntu/Debian):** `sudo apt install libpq-dev`

**macOS:** `brew install libpq && brew link --force libpq`

### 4. Abrir o terminal certo

**No VS Code:** abra a pasta do projeto, **feche o VS Code por completo e abra de novo**, e use o terminal integrado (`` Ctrl+` ``). O `.vscode/settings.json` coloca o GHC, o Cabal e a `libpq` no PATH só desse terminal, sem mexer no resto do Windows.

**Em outro terminal (PowerShell)**, rode isto antes, a cada terminal novo:

```
$env:PATH = "C:\ghcup\bin;C:\ghcup\msys64\mingw64\bin;$env:PATH"
$env:CABAL_DIR = "C:\cabal"
```

Para conferir: `ghc --version` e `cabal --version` devem mostrar as versões.

### 5. Configurar o `.env`

Copie o arquivo de exemplo:

```
copy .env.example .env
```

Abra o `.env` e preencha, sem aspas e sem espaços em volta do `=`:

| Variável | Onde conseguir |
|---|---|
| `DATABASE_URL` | Supabase → projeto **haskellmovies** → botão **Connect** → **Session pooler**. Copie a URI e troque `[YOUR-PASSWORD]` pela senha do banco, sem os colchetes. Membros do grupo: peçam a senha no grupo. |
| `TMDB_TOKEN` | Crie uma conta em themoviedb.org → Configurações → API → solicite uma chave (tipo **Education**) → copie o **API Read Access Token**, o token longo que começa com `eyJ`. |
| `PORT` | Opcional; o padrão é 8080. |
| `SUPABASE_URL` | Opcional (troca de foto de perfil). Supabase → **Project Settings → API** → **Project URL**. |
| `SUPABASE_SERVICE_KEY` | Opcional (troca de foto de perfil). Supabase → **Project Settings → API Keys** → chave **secret** (`service_role`). **É secreta: só no `.env`, nunca no GitHub nem no front.** |

Sem as duas variáveis do Supabase o sistema funciona normalmente; só não deixa trocar a foto de perfil.

**Bucket da foto de perfil (uma vez só):** no Supabase, vá em **Storage → New bucket**, use o nome `avatares` e marque **Public bucket**. O banco do grupo já tem essa configuração.

O `.env` está no `.gitignore` e nunca vai para o GitHub. **Nunca compartilhe a senha ou o token em lugares públicos.**

### 6. Criar as tabelas (só para um banco novo)

O banco do grupo **já tem as tabelas**; pule este passo. Se for usar um projeto novo do Supabase, rode o conteúdo de [db/schema.sql](db/schema.sql) no **SQL Editor** dele uma vez.

### 7. Rodar

```
cabal update
cabal run
```

A **primeira vez demora** (de 10 a 20 minutos), porque o Cabal baixa e compila as bibliotecas. Nas próximas vezes leva segundos. Quando aparecer `HaskellMovies rodando em http://localhost:8080`, abra esse endereço no navegador.

Para parar o servidor: `Ctrl+C` no terminal.

### Problemas comuns

| Mensagem | Solução |
|---|---|
| `cabal` não é reconhecido | Feche e abra o VS Code de novo, ou rode os comandos de PATH do passo 4. |
| O programa fecha sem mensagem, ou com código `-1073741515` | A `libpq` não foi encontrada: confira os passos 3 e 4. |
| `A variavel DATABASE_URL nao foi definida` (ou `TMDB_TOKEN`) | O `.env` não existe ou está vazio: veja o passo 5. |
| Erro de conexão com o banco | Confira a senha na `DATABASE_URL` e se escolheu **Session pooler**; a conexão direta exige IPv6. |
| Porta 8080 ocupada / `Permission denied` ao compilar | Já existe um servidor rodando: feche o outro terminal ou use `Ctrl+C` nele. |
| Tela em branco no navegador | Recarregue com `Ctrl+Shift+R` para ignorar o cache. |

## Rotas da API

| Método | Rota | O que faz |
|---|---|---|
| POST | `/api/cadastro` | Cria a conta e já entra |
| POST | `/api/login` | Entra com username ou e-mail |
| POST | `/api/logout` | Sai |
| GET | `/api/eu` | Usuário logado |
| PUT | `/api/eu/foto` | Troca a foto de perfil (corpo = imagem JPG, PNG ou WebP de até 2 MB; guarda no Supabase Storage) |
| GET | `/api/filmes?q=texto` | Busca no TMDB; sem `q`, mostra os populares |
| GET | `/api/filmes/:id` | Página do filme |
| PUT / DELETE | `/api/filmes/:id/avaliacao` | Avalia ou apaga a avaliação (`{ "nota": 5, "comentario": "..." }`) |
| PUT / DELETE | `/api/filmes/:id/quero-assistir` | Adiciona ou remove do "quero assistir" |
| PUT / DELETE | `/api/filmes/:id/destaque` | Adiciona ou remove dos destaques (máximo 3) |
| GET | `/api/usuarios?q=texto` | Busca pessoas |
| GET | `/api/usuarios/:username` | Perfil |
| PUT / DELETE | `/api/usuarios/:username/seguir` | Segue ou deixa de seguir |

Todas as rotas, menos cadastro e login, exigem estar logado. Sem login, elas respondem 401. Os erros vêm em JSON: `{ "mensagem": "..." }`.

## Estrutura

```
app/
  Main.hs              lê a configuração e sobe o servidor
  Config.hs            lê o .env e as variáveis de ambiente
  Api.hs               tipo API: todas as rotas descritas no nível de tipos
  Handlers.hs          liga cada rota ao seu handler
  Handlers/Conta.hs    cadastro, login, logout, "quem sou eu"
  Handlers/Filmes.hs   catálogo, página do filme, avaliações, listas
  Handlers/Perfil.hs   buscar pessoas, perfil, seguir
  Dados/Usuarios.hs    SQL de usuários e sessões
  Dados/Filmes.hs      SQL de filmes, avaliações, "quero assistir" e destaques
  Dados/Social.hs      SQL de busca de pessoas, perfil e seguidores
  Tmdb.hs              chamadas à API do TMDB e leitura do JSON
  Armazenamento.hs     envia a foto de perfil para o Supabase Storage
  Regras.hs            regras em funções puras (validações, posição do destaque)
  Sessao.hs            hash de senha, token e cookie da sessão
  Tipos.hs             tipos de dados (convertidos para JSON pelo Aeson)
  Banco.hs             pool de conexões com o PostgreSQL
  Erro.hs              respostas de erro em JSON
  Util.hs              funções pequenas de texto
db/schema.sql          tabelas do banco
static/                index.html, css/ e js/ do front
referencia-aulas/      material das aulas usado como referência de estilo
```

## Créditos

Dados e imagens de filmes fornecidos pelo [TMDB](https://www.themoviedb.org).
Este produto usa a API do TMDB, mas não é endossado nem certificado pelo TMDB.
