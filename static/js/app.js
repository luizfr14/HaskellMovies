const telaEntrada = document.getElementById("tela-entrada");
const telaInicio = document.getElementById("tela-inicio");
const usuarioLogado = document.getElementById("usuario-logado");
const saudacao = document.getElementById("saudacao");
const mensagemErro = document.getElementById("mensagem-erro");
const formLogin = document.getElementById("form-login");
const formCadastro = document.getElementById("form-cadastro");

// Mostra a tela certa: entrada (visitante) ou início (logado)
function mostrar(usuario) {
    const logado = usuario !== null;
    telaEntrada.hidden = logado;
    telaInicio.hidden = !logado;
    usuarioLogado.hidden = !logado;
    if (logado) {
        saudacao.textContent = "Olá, " + usuario.nome;
    }
}

// Pergunta ao servidor quem está logado (o cookie vai sozinho)
async function verificarSessao() {
    const resposta = await api("GET", "/api/eu");
    mostrar(resposta.ok ? resposta.dados : null);
}

// Troca entre as abas "Entrar" e "Criar conta"
document.querySelectorAll(".aba").forEach((aba) => {
    aba.addEventListener("click", () => {
        document.querySelectorAll(".aba").forEach((a) => a.classList.toggle("ativa", a === aba));
        formLogin.hidden = aba.dataset.aba !== "form-login";
        formCadastro.hidden = aba.dataset.aba !== "form-cadastro";
        mensagemErro.textContent = "";
    });
});

// Envia um formulário para a API e trata a resposta
async function enviar(formulario, caminho) {
    const dados = Object.fromEntries(new FormData(formulario));
    const botao = formulario.querySelector("button");
    botao.disabled = true;
    mensagemErro.textContent = "";
    try {
        const resposta = await api("POST", caminho, dados);
        if (resposta.ok) {
            formulario.reset();
            mostrar(resposta.dados);
        } else {
            mensagemErro.textContent = resposta.dados?.mensagem ?? "Algo deu errado. Tente de novo.";
        }
    } catch {
        mensagemErro.textContent = "Não foi possível falar com o servidor.";
    } finally {
        botao.disabled = false;
    }
}

formLogin.addEventListener("submit", (evento) => {
    evento.preventDefault();
    enviar(formLogin, "/api/login");
});

formCadastro.addEventListener("submit", (evento) => {
    evento.preventDefault();
    enviar(formCadastro, "/api/cadastro");
});

document.getElementById("botao-sair").addEventListener("click", async () => {
    await api("POST", "/api/logout");
    mostrar(null);
});

verificarSessao();
