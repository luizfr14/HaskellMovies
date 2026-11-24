-- Estrutura do banco do HaskellMovies (PostgreSQL)
-- Os dados dos filmes vêm do TMDB; aqui guardamos só o que é do nosso sistema.

-- Usuários da plataforma
create table if not exists usuarios (
    id          serial primary key,
    nome        text not null,
    username    text not null unique,
    email       text not null unique,
    senha_hash  text not null,              -- senha com hash bcrypt, nunca em texto
    criado_em   timestamptz not null default now()
);

-- Sessões de login: o token fica num cookie do navegador
create table if not exists sessoes (
    token       text primary key,
    usuario_id  integer not null references usuarios (id) on delete cascade,
    criado_em   timestamptz not null default now()
);

-- Cópia local do básico de cada filme usado no sistema
-- (para montar perfis e listas sem consultar o TMDB toda hora)
create table if not exists filmes (
    tmdb_id     integer primary key,
    titulo      text not null,
    poster      text,                       -- caminho da imagem no TMDB, ex: /abc123.jpg
    ano         integer
);

-- Avaliação de um filme já assistido (uma por usuário e filme)
create table if not exists avaliacoes (
    usuario_id  integer not null references usuarios (id) on delete cascade,
    tmdb_id     integer not null references filmes (tmdb_id),
    nota        smallint not null check (nota between 1 and 5),
    comentario  text,
    criado_em   timestamptz not null default now(),
    primary key (usuario_id, tmdb_id)
);

-- Filmes que o usuário tem interesse em assistir
create table if not exists quero_assistir (
    usuario_id  integer not null references usuarios (id) on delete cascade,
    tmdb_id     integer not null references filmes (tmdb_id),
    criado_em   timestamptz not null default now(),
    primary key (usuario_id, tmdb_id)
);

-- Os 3 filmes em destaque do perfil (posições 1, 2 e 3)
create table if not exists destaques (
    usuario_id  integer not null references usuarios (id) on delete cascade,
    posicao     smallint not null check (posicao between 1 and 3),
    tmdb_id     integer not null references filmes (tmdb_id),
    primary key (usuario_id, posicao),
    unique (usuario_id, tmdb_id)            -- o mesmo filme não aparece duas vezes
);

-- Quem segue quem
create table if not exists seguidores (
    seguidor_id integer not null references usuarios (id) on delete cascade,
    seguido_id  integer not null references usuarios (id) on delete cascade,
    criado_em   timestamptz not null default now(),
    primary key (seguidor_id, seguido_id),
    check (seguidor_id <> seguido_id)       -- ninguém segue a si mesmo
);

-- Índices para as buscas mais comuns
create index if not exists idx_seguidores_seguido on seguidores (seguido_id);
create index if not exists idx_avaliacoes_filme   on avaliacoes (tmdb_id);
create index if not exists idx_quero_filme        on quero_assistir (tmdb_id);
create index if not exists idx_sessoes_usuario    on sessoes (usuario_id);
create index if not exists idx_destaques_filme    on destaques (tmdb_id);

-- Segurança no Supabase: o Supabase também expõe as tabelas por uma API pública.
-- Ligar o RLS sem nenhuma regra bloqueia esse acesso; só o nosso servidor Haskell,
-- que conecta direto no banco como dono das tabelas, consegue ler e gravar.
alter table usuarios       enable row level security;
alter table sessoes        enable row level security;
alter table filmes         enable row level security;
alter table avaliacoes     enable row level security;
alter table quero_assistir enable row level security;
alter table destaques      enable row level security;
alter table seguidores     enable row level security;
