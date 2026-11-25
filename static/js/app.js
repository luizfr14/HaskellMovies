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

// Foto do usuário; sem foto, mostra a inicial do nome sobre o gradiente
function avatar(usuario, classe = "avatar") {
    return usuario.foto
        ? `<img class="${classe}" src="${esc(usuario.foto)}" alt="" loading="lazy">`
        : `<span class="${classe}">${esc((usuario.nome || "?")[0])}</span>`;
}

// Recorta o centro da imagem num quadrado de 400x400 e converte para JPEG (arquivo leve)
async function quadrado(arquivo) {
    const imagem = await createImageBitmap(arquivo);
    const lado = Math.min(imagem.width, imagem.height);
    const tela = document.createElement("canvas");
    tela.width = tela.height = 400;
    tela.getContext("2d").drawImage(
        imagem, (imagem.width - lado) / 2, (imagem.height - lado) / 2, lado, lado, 0, 0, 400, 400);
    return new Promise((pronto) => tela.toBlob(pronto, "image/jpeg", 0.9));
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
    document.getElementById("menu-perfil").href = `#/u/${usuario.username}`;
    atualizarMenu();
    rotear();
}

// Mostra a foto (ou a inicial) do usuário logado no menu
function atualizarMenu() {
    document.getElementById("menu-avatar").innerHTML = avatar(eu, "avatar avatar-mini");
}

// ===== Rotas (sem recarregar a página) =====
//   #/            catálogo
//   #/pessoas     buscar pessoas
//   #/u/fulano    perfil

// animar = false recarrega a tela sem repetir a animação de entrada
function rotear(animar = true) {
    if (!eu) return;
    const partes = location.hash.replace(/^#\/?/, "").split("/");
    let rota = "catalogo";
    if (partes[0] === "pessoas") {
        rota = "pessoas";
        telaPessoas();
    } else if (partes[0] === "u" && partes[1]) {
        rota = partes[1] === eu.username ? "perfil" : "";
        telaPerfil(decodeURIComponent(partes[1]), animar);
    } else {
        telaCatalogo();
    }
    document.querySelectorAll(".menu-item").forEach((item) =>
        item.classList.toggle("ativo", item.dataset.rota === rota));
    window.scrollTo(0, 0);
}

window.addEventListener("hashchange", () => rotear());

// Reinicia a animação de entrada de um elemento (a classe "entrando" está no CSS)
function reiniciarAnimacao(elemento) {
    elemento.classList.remove("entrando");
    void elemento.offsetWidth;  // faz o navegador "esquecer" a animação anterior
    elemento.classList.add("entrando");
}

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
    reiniciarAnimacao(conteudo);
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
    reiniciarAnimacao(conteudo);
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
                ${avatar(p)}
                <span class="pessoa-texto">
                    <strong>${esc(p.username)}</strong>
                    <span>${esc(p.nome)}</span>
                </span>
            </a>`).join("")
        : aviso("Ninguém encontrado.");
}

// ===== Perfil =====

let abaPerfil = "destaques";
let filtroNota = 0;         // 0 = mostra todas as notas
let ordem = "recentes";     // como a aba Avaliados está ordenada

// Cada ordem é uma função de comparação. "recentes" mantém a ordem que veio do servidor.
const ordenadores = {
    recentes: () => 0,
    melhor: (a, b) => b.nota - a.nota,
    pior: (a, b) => a.nota - b.nota,
    titulo: (a, b) => a.filme.titulo.localeCompare(b.filme.titulo, "pt-BR"),
};

async function telaPerfil(username, animar = true) {
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

    // Cada destaque ganha a nota e o comentário que o dono do perfil escreveu
    const destaques = p.destaques.map((filme) => ({
        filme,
        avaliacao: p.avaliacoes.find((a) => a.filme.tmdbId === filme.tmdbId),
    }));

    // No meu perfil, clicar na foto abre a escolha de um arquivo
    const foto = p.ehVoce
        ? `<label class="avatar-trocar" title="Trocar foto">
               ${avatar(u)}
               <span class="avatar-camera">Trocar foto</span>
               <input type="file" id="arquivo-foto" accept="image/jpeg,image/png,image/webp" hidden>
           </label>`
        : avatar(u);

    conteudo.innerHTML = `
        <header class="perfil-topo">
            ${foto}
            <div class="perfil-info">
                <div class="perfil-linha">
                    <h1 class="perfil-username">${esc(u.username)}</h1>
                    ${botao}
                    <button class="botao-cinza" id="botao-link">Copiar link</button>
                </div>
                <div class="perfil-numeros">
                    <span><b>${p.avaliacoes.length}</b> ${p.avaliacoes.length === 1 ? "avaliação" : "avaliações"}</span>
                    <span><b>${p.seguidores}</b> ${p.seguidores === 1 ? "seguidor" : "seguidores"}</span>
                    <span><b>${p.seguindo}</b> seguindo</span>
                </div>
                <span class="perfil-nome">${esc(u.nome)}</span>
                ${p.ehVoce ? `<span class="erro-foto" id="erro-foto" role="alert"></span>` : ""}
                ${p.compatibilidade !== null && !p.ehVoce
                    ? `<span class="compat">${p.compatibilidade}% compatível com você</span>`
                    : ""}
                ${p.conquistas.length
                    ? `<div class="conquistas">${p.conquistas.map((c) => `<span class="selo">${esc(c)}</span>`).join("")}</div>`
                    : ""}
            </div>
        </header>
        <nav class="abas">
            <button class="aba" data-aba="destaques">Destaques</button>
            <button class="aba" data-aba="avaliacoes">Avaliados <span class="contador">${p.avaliacoes.length}</span></button>
            <button class="aba" data-aba="quero">Quero assistir <span class="contador">${p.queroAssistir.length}</span></button>
            <button class="aba" data-aba="estatisticas">Estatísticas</button>
        </nav>
        <section id="grade-perfil"></section>
        ${p.emComum.length ? `
        <section class="em-comum">
            <div class="em-comum-topo">
                <h2 class="titulo-secao">Vocês dois querem ver</h2>
                <button class="botao" id="botao-sortear">Sortear um para hoje</button>
            </div>
            <div class="em-comum-lista">
                ${p.emComum.map((f) => `
                    <button class="cartao-filme" data-filme="${f.tmdbId}">
                        ${poster(f)}
                        <span class="cartao-titulo">${esc(f.titulo)}</span>
                    </button>`).join("")}
            </div>
        </section>` : ""}`;

    if (animar) reiniciarAnimacao(conteudo);

    const mostrarAba = (aba) => {
        abaPerfil = aba;
        conteudo.querySelectorAll(".aba").forEach((b) => b.classList.toggle("ativa", b.dataset.aba === aba));
        const grade = document.getElementById("grade-perfil");

        // Destaques: até 3 filmes lado a lado, com pôster grande, nota e comentário
        if (aba === "destaques") {
            grade.innerHTML = destaques.length
                ? `<div class="grade-destaques">${destaques.map(({ filme, avaliacao }) => `
                    <button class="destaque-card" data-filme="${filme.tmdbId}">
                        ${poster(filme, "poster destaque-poster")}
                        <span class="cartao-titulo">${esc(filme.titulo)}</span>
                        ${avaliacao
                            ? `<span class="nota-estrelas">${estrelas(avaliacao.nota)}</span>
                               ${avaliacao.comentario ? `<span class="destaque-texto">${esc(avaliacao.comentario)}</span>` : ""}`
                            : `<span class="discreto">Ainda sem avaliação</span>`}
                    </button>`).join("")}</div>`
                : aviso(p.ehVoce
                    ? "Nenhum destaque ainda. Abra um filme e toque em Destacar."
                    : "Nenhum destaque ainda.");
            return;
        }

        if (aba === "avaliacoes") { desenharAvaliados(grade); return; }
        if (aba === "estatisticas") { desenharEstatisticas(grade); return; }

        // Quero assistir
        grade.innerHTML = p.queroAssistir.length
            ? `<div class="grade-perfil">${p.queroAssistir.map((f) => `
                <button class="cartao-filme" data-filme="${f.tmdbId}">
                    ${poster(f)}
                    <span class="cartao-titulo">${esc(f.titulo)}</span>
                    <span class="discreto">${f.ano ?? ""}</span>
                </button>`).join("")}</div>`
            : aviso(p.ehVoce
                ? "Sua lista está vazia. Abra um filme e toque em Quero assistir."
                : "Nenhum filme na lista.");
    };

    // Avaliados: filtro por nota e ordenação. Cada cartão mostra um trecho do comentário.
    const desenharAvaliados = (grade) => {
        const lista = p.avaliacoes
            .filter((a) => filtroNota === 0 || a.nota === filtroNota)
            .sort(ordenadores[ordem]);
        grade.innerHTML = `
            <div class="barra-filtros">
                <div class="filtros">
                    ${[0, 5, 4, 3, 2, 1].map((n) => `
                        <button class="filtro ${n === filtroNota ? "ativo" : ""}" data-nota="${n}">
                            ${n === 0 ? "Todas" : n + "★"}
                        </button>`).join("")}
                </div>
                <select id="ordem-avaliados" aria-label="Ordenar avaliações">
                    <option value="recentes">Mais recentes</option>
                    <option value="melhor">Melhor nota</option>
                    <option value="pior">Pior nota</option>
                    <option value="titulo">Título (A–Z)</option>
                </select>
            </div>
            ${lista.length ? `<div class="grade-perfil">${lista.map((a) => `
                <button class="cartao-filme" data-filme="${a.filme.tmdbId}">
                    ${poster(a.filme)}
                    <span class="cartao-titulo">${esc(a.filme.titulo)}</span>
                    <span class="nota-estrelas">${estrelas(a.nota)}</span>
                    ${a.comentario ? `<span class="cartao-comentario">${esc(a.comentario)}</span>` : ""}
                </button>`).join("")}</div>`
                : aviso(p.avaliacoes.length ? "Nenhum filme com essa nota." : "Nenhum filme avaliado ainda.")}`;
        grade.querySelector("#ordem-avaliados").value = ordem;
        grade.querySelectorAll(".filtro").forEach((b) => b.addEventListener("click", () => {
            filtroNota = Number(b.dataset.nota);
            desenharAvaliados(grade);
        }));
        grade.querySelector("#ordem-avaliados").addEventListener("change", (e) => {
            ordem = e.target.value;
            desenharAvaliados(grade);
        });
    };

    // Estatísticas: números e um gráfico de barras com quantos filmes receberam cada nota
    const desenharEstatisticas = (grade) => {
        const e = p.estatisticas;
        if (e.total === 0) {
            grade.innerHTML = aviso(p.ehVoce
                ? "Avalie alguns filmes para ver suas estatísticas."
                : "Ainda não há estatísticas.");
            return;
        }
        const maior = Math.max(...e.distribuicao, 1);
        const numero = (valor, legenda) =>
            `<div class="estat-card"><b>${valor}</b><span class="discreto">${legenda}</span></div>`;
        grade.innerHTML = `
            <div class="estat-numeros">
                ${numero(e.media.toFixed(1).replace(".", ","), "nota média")}
                ${numero(e.total, "filmes avaliados")}
                ${numero(e.comentarios, "comentários escritos")}
                ${e.decada ? numero(e.decada + "s", "década favorita") : ""}
            </div>
            <div class="estat-barras">
                <h3 class="titulo-secao">Como avalia</h3>
                ${[5, 4, 3, 2, 1].map((n) => `
                    <div class="barra-linha">
                        <span class="barra-rotulo">${n}★</span>
                        <div class="barra"><div class="barra-preenchida" style="width:${(e.distribuicao[n - 1] / maior) * 100}%"></div></div>
                        <span class="barra-valor">${e.distribuicao[n - 1]}</span>
                    </div>`).join("")}
            </div>`;
    };
    conteudo.querySelectorAll(".aba").forEach((b) => b.addEventListener("click", () => mostrarAba(b.dataset.aba)));
    mostrarAba(abaPerfil);

    // Copiar link do perfil
    document.getElementById("botao-link")?.addEventListener("click", async (e) => {
        const botaoLink = e.target;
        try {
            await navigator.clipboard.writeText(location.href);
            botaoLink.textContent = "Link copiado!";
        } catch {
            botaoLink.textContent = "Copie da barra de endereço";
        }
        setTimeout(() => { botaoLink.textContent = "Copiar link"; }, 2000);
    });

    // Troca de foto: reduz a imagem aqui e o servidor Haskell guarda no Supabase Storage
    document.getElementById("arquivo-foto")?.addEventListener("change", async (e) => {
        const arquivo = e.target.files[0];
        e.target.value = "";  // permite escolher o mesmo arquivo de novo
        if (!arquivo) return;
        const erro = document.getElementById("erro-foto");
        const legenda = conteudo.querySelector(".avatar-camera");
        erro.textContent = "";
        legenda.textContent = "Enviando...";
        try {
            const resposta = await enviarArquivo("PUT", "/api/eu/foto", await quadrado(arquivo));
            if (resposta.ok) {
                eu = resposta.dados;
                atualizarMenu();
                telaPerfil(username, false);
                return;
            }
            erro.textContent = resposta.dados?.mensagem ?? "Não foi possível trocar a foto.";
        } catch {
            erro.textContent = "Não foi possível ler essa imagem.";
        }
        legenda.textContent = "Trocar foto";
    });

    // Sorteio: acende um filme de cada vez, desacelerando, e abre o escolhido
    document.getElementById("botao-sortear")?.addEventListener("click", (e) => {
        const cartoes = [...conteudo.querySelectorAll(".em-comum-lista .cartao-filme")];
        const escolhido = Math.floor(Math.random() * cartoes.length);
        const passos = cartoes.length * 3 + escolhido;
        e.target.disabled = true;
        let i = 0;
        const girar = () => {
            cartoes.forEach((c, n) => c.classList.toggle("sorteando", n === i % cartoes.length));
            if (i === passos) {
                setTimeout(() => abrirFilme(Number(cartoes[escolhido].dataset.filme)), 600);
                e.target.disabled = false;
                return;
            }
            i++;
            setTimeout(girar, 60 + i * 12);
        };
        girar();
    });

    const seguir = document.getElementById("botao-seguir");
    if (seguir) {
        seguir.addEventListener("click", async () => {
            seguir.disabled = true;
            const metodo = seguir.dataset.seguindo ? "DELETE" : "PUT";
            await api(metodo, `/api/usuarios/${encodeURIComponent(u.username)}/seguir`);
            telaPerfil(username, false);
        });
    }
}

// ===== Página do filme =====

let filmeAberto = null;

let timerFechar;  // controla o fim da animação de saída da janela

async function abrirFilme(id) {
    clearTimeout(timerFechar);          // se estava fechando, cancela
    modal.classList.remove("saindo");
    filmeAberto = id;
    // Só mostra "Carregando..." na primeira abertura; ao atualizar, mantém o conteúdo até chegar o novo
    if (modal.hidden) modalCaixa.innerHTML = aviso("Carregando...");
    modal.hidden = false;
    document.body.style.overflow = "hidden";
    const resposta = await api("GET", "/api/filmes/" + id);
    if (filmeAberto !== id) return;  // o usuário já abriu outro
    if (!resposta.ok) {
        modalCaixa.innerHTML = aviso(resposta.dados?.mensagem ?? "Não foi possível abrir o filme.");
        return;
    }
    desenharFilme(resposta.dados);
}

function fecharFilme() {
    if (modal.hidden || modal.classList.contains("saindo")) return;
    filmeAberto = null;
    document.body.style.overflow = "";
    // Toca a animação de saída e só então esconde a janela
    modal.classList.add("saindo");
    timerFechar = setTimeout(() => {
        modal.hidden = true;
        modal.classList.remove("saindo");
    }, 180);
    // No perfil, recarrega (sem animar) para mostrar a avaliação ou o destaque novo
    if (location.hash.startsWith("#/u/")) rotear(false);
}

document.getElementById("modal-fechar").addEventListener("click", fecharFilme);
modal.addEventListener("click", (e) => { if (e.target === modal) fecharFilme(); });
document.addEventListener("keydown", (e) => { if (e.key === "Escape" && !modal.hidden) fecharFilme(); });

function desenharFilme(d) {
    const f = d.filme;
    const url = urlPoster(f.poster, "w780");
    let nota = d.minhaNota ?? 0;

    // Onde assistir no Brasil: só os grupos que têm algum serviço
    const grupos = [
        ["Streaming", d.onde.streaming],
        ["Alugar", d.onde.alugar],
        ["Comprar", d.onde.comprar],
        ["Grátis", d.onde.gratis],
    ].filter(([, servicos]) => servicos.length > 0);

    const onde = grupos.length
        ? grupos.map(([nome, servicos]) => `
            <div class="onde-grupo">
                <span class="onde-rotulo">${nome}</span>
                <div class="onde-lista">${servicos.map((s) => `
                    <span class="onde-item">
                        ${s.logo ? `<img src="https://image.tmdb.org/t/p/w92${s.logo}" alt="" loading="lazy">` : ""}
                        <span>${esc(s.nome)}</span>
                    </span>`).join("")}
                </div>
            </div>`).join("")
        : `<p class="discreto">Não encontramos este filme em nenhum serviço no Brasil.</p>`;

    const amigos = d.amigos.map((o) => `
        <div class="comentario">
            ${avatar({ nome: o.username })}
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
                <section class="onde">
                    <h3 class="onde-titulo">Onde assistir</h3>
                    ${onde}
                </section>
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
                    ${d.trailer ? `
                    <button class="icone" id="acao-trailer" title="Ver trailer">
                        <svg viewBox="0 0 24 24"><path d="M7 4v16l13-8z"/></svg>
                        Trailer
                    </button>` : ""}
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
    // Trailer: troca o pôster pelo vídeo do YouTube
    document.getElementById("acao-trailer")?.addEventListener("click", () => {
        modalCaixa.querySelector(".modal-poster").outerHTML = `
            <iframe class="modal-poster modal-video" allow="autoplay; encrypted-media; fullscreen" allowfullscreen
                src="https://www.youtube-nocookie.com/embed/${encodeURIComponent(d.trailer)}?autoplay=1"></iframe>`;
    });
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
