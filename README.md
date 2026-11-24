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

### 1. Instalar o Haskell

Instale o [GHCup](https://www.haskell.org/ghcup/), que traz o GHC e o Cabal.

### 2. Instalar a biblioteca do PostgreSQL (só no Windows)

O `postgresql-simple` precisa da `libpq`. Instale pelo MSYS2 que vem com o GHCup:

```
C:\ghcup\msys64\usr\bin\bash.exe -lc "pacman -S --noconfirm mingw-w64-x86_64-postgresql"
```

Ao rodar, a pasta `C:\ghcup\msys64\mingw64\bin` precisa estar no PATH. No VS Code isso já está configurado em `.vscode/settings.json`, só para o terminal deste projeto. Feche e abra o VS Code depois de clonar o repositório.

### 3. Configurar o `.env`

Copie o `.env.example` para `.env` e preencha:

| Variável | Onde conseguir |
|---|---|
| `DATABASE_URL` | Supabase → projeto → **Connect** → **Session pooler**. Troque `[YOUR-PASSWORD]` pela senha do banco. |
| `TMDB_TOKEN` | themoviedb.org → Configurações → API → **API Read Access Token**, o token longo que começa com `eyJ`. |
| `PORT` | Opcional; o padrão é 8080. |

O `.env` está no `.gitignore` e nunca vai para o GitHub.

### 4. Criar as tabelas

Rode o conteúdo de [db/schema.sql](db/schema.sql) no **SQL Editor** do Supabase. Só é preciso na primeira vez.

### 5. Rodar

```
cabal update
cabal run
```

Abra http://localhost:8080

## Rotas da API

| Método | Rota | O que faz |
|---|---|---|
| POST | `/api/cadastro` | Cria a conta e já entra |
| POST | `/api/login` | Entra com username ou e-mail |
| POST | `/api/logout` | Sai |
| GET | `/api/eu` | Usuário logado |
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
