# HaskellMovies

Rede social de filmes: catálogo (via API do TMDB), avaliações, lista "quero assistir",
seguir amigos e perfil com 3 filmes em destaque.

- **Backend:** Haskell com Servant, Warp e Aeson (pasta `app/`)
- **Frontend:** HTML, CSS e JS simples com `fetch` (pasta `static/`)

## Como rodar

Pré-requisito: [GHCup](https://www.haskell.org/ghcup/) (instala GHC e Cabal).

```
cabal update
cabal run
```

Abra http://localhost:8080

## Estrutura

```
app/
  Main.hs      sobe o servidor na porta 8080
  Api.hs       tipo API com todas as rotas
  Handlers.hs  o que cada rota faz
  Tipos.hs     tipos de dados (convertidos para JSON pelo Aeson)
static/        páginas, CSS e JS do front
referencia-aulas/  material das aulas usado como referência de estilo
```
