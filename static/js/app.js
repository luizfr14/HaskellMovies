// ===== Estado e utilidades =====

let eu = null;                        // usuário logado
const conteudo = document.getElementById("conteudo");
const modal = document.getElementById("modal");
const modalCaixa = document.getElementById("modal-caixa");

// Escapa texto vindo do usuário antes de colocar no HTML
function esc(texto) {
    const div = document.createElement("div");
    div.textContent = texto ?? "";
    return div.innerHTML;
}

function urlPoster(caminho, tamanho = "w342") {
    return caminho ? `https://image.tmdb.org/t/p/${tamanho}${caminho}` : null;
}

function poster(filme, classe = "poster") {
    const url = urlPoster(filme.poster);
    return url
        ? `<img class="${classe}" src="${url}" alt="${esc(filme.titulo)}" loading="lazy">`
        : `<div class="${classe} poster-vazio">${esc(filme.titulo)}</div>`;
}

function avatar(nome, classe = "avatar") {
    return `<span class="${classe}">${esc((nome || "?")[0])}</span>`;
}

function estrelas(nota) {
    return "★".repeat(nota);
}

// Selo com a opinião de um amigo: "@ana ★★★★" ou "@ana quer ver"
function selo(opiniao) {
    const o = opiniao.querAssistir
        ? "quer ver"
        : `<b>${estrelas(opiniao.nota)}</b>`;
    return `<span class="selo">@${esc(opiniao.username)} ${o}</span>`;
}

function aviso(texto) {
    return `<p class="aviso">${esc(texto)}</p>`;
}

// ===== Entrada (login / cadastro) =====

const formLogin = document.getElementById("form-login");
const formCadastro = document.getElementById("form-cadastro");
const mensagemErro = document.getElementById("mensagem-erro");
const trocaTexto = document.getElementById("troca-texto");
const trocaBotao = document.getElementById("troca-botao");

trocaBotao.addEventListener("click", () => {
    const indoParaCadastro = formCadastro.hidden;
    formCadastro.hidden = !indoParaCadastro;
    formLogin.hidden = indoParaCadastro;
    trocaTexto.textContent = indoParaCadastro ? "Tem uma conta?" : "Não tem uma conta?";
    trocaBotao.textContent = indoParaCadastro ? "Conecte-se" : "Cadastre-se";
    mensagemErro.textContent = "";
});

async function enviar(formulario, caminho) {
    const dados = Object.fromEntries(new FormData(formulario));
    const botao = formulario.querySelector("button");
    botao.disabled = true;
    mensagemErro.textContent = "";
    try {
        const resposta = await api("POST", caminho, dados);
        if (resposta.ok) {
            formulario.reset();
            entrarNoApp(resposta.dados);
        } else {
            mensagemErro.textContent = resposta.dados?.mensagem ?? "Algo deu errado. Tente de novo.";
        }
    } catch {
        mensagemErro.textContent = "Não foi possível falar com o servidor.";
    } finally {
        botao.disabled = false;
    }
}

formLogin.addEventListener("submit", (e) => { e.preventDefault(); enviar(formLogin, "/api/login"); });
formCadastro.addEventListener("submit", (e) => { e.preventDefault(); enviar(formCadastro, "/api/cadastro"); });

document.getElementById("botao-sair").addEventListener("click", async () => {
    await api("POST", "/api/logout");
    eu = null;
    fecharFilme();
    document.getElementById("tela-app").hidden = true;
    document.getElementById("tela-entrada").hidden = false;
});

function entrarNoApp(usuario) {
    eu = usuario;
    document.getElementById("tela-entrada").hidden = true;
    document.getElementById("tela-app").hidden = false;
    document.getElementById("menu-avatar").textContent = usuario.nome[0];
    document.getElementById("menu-perfil").href = `#/u/${usuario.username}`;
    rotear();
}

// ===== Rotas (sem recarregar a página) =====
//   #/            catálogo
//   #/pessoas     buscar pessoas
//   #/u/fulano    perfil

function rotear() {
    if (!eu) return;
    const partes = location.hash.replace(/^#\/?/, "").split("/");
    let rota = "catalogo";
    if (partes[0] === "pessoas") {
        rota = "pessoas";
        telaPessoas();
    } else if (partes[0] === "u" && partes[1]) {
        rota = partes[1] === eu.username ? "perfil" : "";
        telaPerfil(decodeURIComponent(partes[1]));
    } else {
        telaCatalogo();
    }
    document.querySelectorAll(".menu-item").forEach((item) =>
        item.classList.toggle("ativo", item.dataset.rota === rota));
    window.scrollTo(0, 0);
}

window.addEventListener("hashchange", rotear);

// Espera o usuário parar de digitar antes de buscar
function aoDigitar(campo, acao) {
    let espera;
    campo.addEventListener("input", () => {
        clearTimeout(espera);
        espera = setTimeout(() => acao(campo.value.trim()), 350);
    });
}

// ===== Catálogo =====

function telaCatalogo() {
    conteudo.innerHTML = `
        <div class="busca">
            <input id="busca-filmes" type="search" placeholder="Pesquisar filmes" autocomplete="off">
        </div>
        <h2 class="titulo-secao" id="titulo-catalogo">Populares agora</h2>
        <div id="resultado-filmes"></div>`;
    const campo = document.getElementById("busca-filmes");
    aoDigitar(campo, carregarFilmes);
    carregarFilmes("");
}

async function carregarFilmes(texto) {
    const destino = document.getElementById("resultado-filmes");
    document.getElementById("titulo-catalogo").textContent =
        texto ? `Resultados para "${texto}"` : "Populares agora";
    const resposta = await api("GET", "/api/filmes?q=" + encodeURIComponent(texto));
    if (!resposta.ok) {
        destino.innerHTML = aviso(resposta.dados?.mensagem ?? "Não foi possível carregar os filmes.");
        return;
    }
    if (resposta.dados.length === 0) {
        destino.innerHTML = aviso("Nenhum filme encontrado.");
        return;
    }
    destino.innerHTML = `<div class="grade-filmes">${resposta.dados.map(cartaoFilme).join("")}</div>`;
}

function cartaoFilme({ filme, amigos }) {
    return `
        <button class="cartao-filme" data-filme="${filme.tmdbId}">
            ${poster(filme)}
            <span class="cartao-titulo">${esc(filme.titulo)}</span>
            <span class="discreto">${filme.ano ?? ""}</span>
            ${amigos.length ? `<span class="amigos-linha">${amigos.map(selo).join("")}</span>` : ""}
        </button>`;
}

// Qualquer clique em algo com data-filme abre a página do filme
document.addEventListener("click", (e) => {
    const alvo = e.target.closest("[data-filme]");
    if (alvo) abrirFilme(Number(alvo.dataset.filme));
});

// ===== Pessoas =====

function telaPessoas() {
    conteudo.innerHTML = `
        <div class="busca">
            <input id="busca-pessoas" type="search" placeholder="Pesquisar pessoas" autocomplete="off">
        </div>
        <div id="resultado-pessoas" class="lista-pessoas">${aviso("Procure amigos pelo nome ou username.")}</div>`;
    const campo = document.getElementById("busca-pessoas");
    aoDigitar(campo, carregarPessoas);
    campo.focus();
}

async function carregarPessoas(texto) {
    const destino = document.getElementById("resultado-pessoas");
    if (!texto) {
        destino.innerHTML = aviso("Procure amigos pelo nome ou username.");
        return;
    }
    const resposta = await api("GET", "/api/usuarios?q=" + encodeURIComponent(texto));
    const lista = resposta.ok ? resposta.dados : [];
    destino.innerHTML = lista.length
        ? lista.map((p) => `
            <a class="pessoa" href="#/u/${encodeURIComponent(p.username)}">
                ${avatar(p.nome)}
                <span class="pessoa-texto">
                    <strong>${esc(p.username)}</strong>
                    <span>${esc(p.nome)}</span>
                </span>
            </a>`).join("")
        : aviso("Ninguém encontrado.");
}

// ===== Perfil =====

let abaPerfil = "avaliacoes";

async function telaPerfil(username) {
    const resposta = await api("GET", "/api/usuarios/" + encodeURIComponent(username));
    if (!resposta.ok) {
        conteudo.innerHTML = aviso(resposta.dados?.mensagem ?? "Perfil não encontrado.");
        return;
    }
    const p = resposta.dados;
    const u = p.usuario;

    const botao = p.ehVoce
        ? ""
        : p.euSigo
            ? `<button class="botao-cinza" id="botao-seguir" data-seguindo="1">Seguindo</button>`
            : `<button class="botao" id="botao-seguir">Seguir</button>`;

    const vagas = [0, 1, 2].map((i) => p.destaques[i]);
    const destaques = vagas.map((f) => f
        ? `<button class="destaque" data-filme="${f.tmdbId}">
               <span class="destaque-anel">${urlPoster(f.poster, "w185")
                   ? `<img src="${urlPoster(f.poster, "w185")}" alt="">`
                   : `<span class="destaque-vazio">🎬</span>`}</span>
               <span>${esc(f.titulo)}</span>
           </button>`
        : `<div class="destaque"><span class="destaque-vazio">+</span><span class="discreto">Destaque</span></div>`
    ).join("");

    conteudo.innerHTML = `
        <header class="perfil-topo">
            ${avatar(u.nome)}
            <div class="perfil-info">
                <div class="perfil-linha">
                    <h1 class="perfil-username">${esc(u.username)}</h1>
                    ${botao}
                </div>
                <div class="perfil-numeros">
                    <span><b>${p.avaliacoes.length}</b> ${p.avaliacoes.length === 1 ? "avaliação" : "avaliações"}</span>
                    <span><b>${p.seguidores}</b> ${p.seguidores === 1 ? "seguidor" : "seguidores"}</span>
                    <span><b>${p.seguindo}</b> seguindo</span>
                </div>
                <span class="perfil-nome">${esc(u.nome)}</span>
            </div>
        </header>
        <section class="destaques">${destaques}</section>
        <nav class="abas">
            <button class="aba" data-aba="avaliacoes">Avaliados</button>
            <button class="aba" data-aba="quero">Quero assistir</button>
        </nav>
        <section id="grade-perfil"></section>`;

    const mostrarAba = (aba) => {
        abaPerfil = aba;
        conteudo.querySelectorAll(".aba").forEach((b) => b.classList.toggle("ativa", b.dataset.aba === aba));
        const itens = aba === "avaliacoes"
            ? p.avaliacoes.map((a) => ({ filme: a.filme, marca: `<span class="nota-estrelas">${estrelas(a.nota)}</span>` }))
            : p.queroAssistir.map((f) => ({ filme: f, marca: `<span class="discreto">${f.ano ?? ""}</span>` }));
        document.getElementById("grade-perfil").innerHTML = itens.length
            ? `<div class="grade-perfil">${itens.map(({ filme, marca }) => `
                <button class="cartao-filme" data-filme="${filme.tmdbId}">
                    ${poster(filme)}
                    <span class="cartao-titulo">${esc(filme.titulo)}</span>
                    ${marca}
                </button>`).join("")}</div>`
            : aviso(aba === "avaliacoes" ? "Nenhum filme avaliado ainda." : "Nenhum filme na lista.");
    };
    conteudo.querySelectorAll(".aba").forEach((b) => b.addEventListener("click", () => mostrarAba(b.dataset.aba)));
    mostrarAba(abaPerfil);

    const seguir = document.getElementById("botao-seguir");
    if (seguir) {
        seguir.addEventListener("click", async () => {
            seguir.disabled = true;
            const metodo = seguir.dataset.seguindo ? "DELETE" : "PUT";
            await api(metodo, `/api/usuarios/${encodeURIComponent(u.username)}/seguir`);
            telaPerfil(username);
        });
    }
}

// ===== Página do filme =====

let filmeAberto = null;

async function abrirFilme(id) {
    filmeAberto = id;
    modal.hidden = false;
    document.body.style.overflow = "hidden";
    modalCaixa.innerHTML = aviso("Carregando...");
    const resposta = await api("GET", "/api/filmes/" + id);
    if (filmeAberto !== id) return;  // o usuário já abriu outro
    if (!resposta.ok) {
        modalCaixa.innerHTML = aviso(resposta.dados?.mensagem ?? "Não foi possível abrir o filme.");
        return;
    }
    desenharFilme(resposta.dados);
}

function fecharFilme() {
    modal.hidden = true;
    filmeAberto = null;
    document.body.style.overflow = "";
    // No perfil, recarrega para mostrar a avaliação ou o destaque novo
    if (location.hash.startsWith("#/u/")) rotear();
}

document.getElementById("modal-fechar").addEventListener("click", fecharFilme);
modal.addEventListener("click", (e) => { if (e.target === modal) fecharFilme(); });
document.addEventListener("keydown", (e) => { if (e.key === "Escape" && !modal.hidden) fecharFilme(); });

function desenharFilme(d) {
    const f = d.filme;
    const url = urlPoster(f.poster, "w780");
    let nota = d.minhaNota ?? 0;

    const amigos = d.amigos.map((o) => `
        <div class="comentario">
            ${avatar(o.username)}
            <p><strong><a href="#/u/${encodeURIComponent(o.username)}">${esc(o.username)}</a></strong>${o.querAssistir
                ? `<span class="discreto">quer assistir</span>`
                : `<span style="color:var(--estrela)">${estrelas(o.nota)}</span> ${esc(o.comentario ?? "")}`}</p>
        </div>`).join("");

    modalCaixa.innerHTML = `
        ${url ? `<img class="modal-poster" src="${url}" alt="${esc(f.titulo)}">` : `<div class="modal-poster poster-vazio">${esc(f.titulo)}</div>`}
        <article class="post">
            <header class="post-topo">
                <h2>${esc(f.titulo)}</h2>
                <span class="discreto">${f.ano ?? ""}</span>
            </header>
            <div class="post-corpo">
                <p class="post-sinopse">${esc(d.sinopse || "Sem sinopse disponível.")}</p>
                ${amigos || `<p class="discreto">Ninguém que você segue avaliou este filme ainda.</p>`}
            </div>
            <footer class="post-acoes">
                <div class="icones">
                    <button class="icone quero ${d.queroAssistir ? "ligado" : ""}" id="acao-quero" title="Quero assistir">
                        <svg viewBox="0 0 24 24"><path d="M6 3h12v18l-6-5-6 5z"/></svg>
                        ${d.queroAssistir ? "Na sua lista" : "Quero assistir"}
                    </button>
                    <button class="icone destaque-icone ${d.destaque ? "ligado" : ""}" id="acao-destaque" title="Destaque no perfil">
                        <svg viewBox="0 0 24 24"><path d="M12 21s-8-5.2-8-11a4.5 4.5 0 0 1 8-2.8A4.5 4.5 0 0 1 20 10c0 5.8-8 11-8 11z"/></svg>
                        ${d.destaque ? "Em destaque" : "Destacar"}
                    </button>
                </div>
                <form class="form-avaliacao" id="form-avaliacao">
                    <div class="estrelas" id="estrelas">
                        ${[1, 2, 3, 4, 5].map((n) => `<button type="button" class="estrela" data-nota="${n}" aria-label="${n} estrelas">★</button>`).join("")}
                    </div>
                    <textarea name="comentario" placeholder="Escreva o que achou (opcional)..." maxlength="500">${esc(d.meuComentario ?? "")}</textarea>
                    <div class="form-avaliacao-botoes">
                        ${d.minhaNota ? `<button type="button" class="link" id="acao-apagar" style="color:var(--erro)">Apagar avaliação</button>` : "<span></span>"}
                        <button type="submit" class="botao">${d.minhaNota ? "Atualizar" : "Avaliar"}</button>
                    </div>
                    <p class="erro" id="erro-filme"></p>
                </form>
            </footer>
        </article>`;

    // Estrelas clicáveis
    const pintar = () => modalCaixa.querySelectorAll(".estrela").forEach((s) =>
        s.classList.toggle("acesa", Number(s.dataset.nota) <= nota));
    modalCaixa.querySelectorAll(".estrela").forEach((s) =>
        s.addEventListener("click", () => { nota = Number(s.dataset.nota); pintar(); }));
    pintar();

    const erro = document.getElementById("erro-filme");
    const caminho = `/api/filmes/${f.tmdbId}`;

    // Executa uma ação e recarrega o filme
    const agir = async (metodo, sufixo, corpo) => {
        const resposta = await api(metodo, caminho + sufixo, corpo);
        if (resposta.ok) abrirFilme(f.tmdbId);
        else erro.textContent = resposta.dados?.mensagem ?? "Algo deu errado.";
    };

    document.getElementById("acao-quero").addEventListener("click", () =>
        agir(d.queroAssistir ? "DELETE" : "PUT", "/quero-assistir"));
    document.getElementById("acao-destaque").addEventListener("click", () =>
        agir(d.destaque ? "DELETE" : "PUT", "/destaque"));
    document.getElementById("acao-apagar")?.addEventListener("click", () =>
        agir("DELETE", "/avaliacao"));
    document.getElementById("form-avaliacao").addEventListener("submit", (e) => {
        e.preventDefault();
        if (!nota) { erro.textContent = "Escolha de 1 a 5 estrelas."; return; }
        const comentario = e.target.comentario.value;
        agir("PUT", "/avaliacao", { nota, comentario });
    });
}

// ===== Início =====

(async () => {
    const resposta = await api("GET", "/api/eu");
    if (resposta.ok) entrarNoApp(resposta.dados);
    else document.getElementById("tela-entrada").hidden = false;
})();
