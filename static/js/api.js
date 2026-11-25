// Funções para conversar com o backend Haskell.
// As duas devolvem { ok, status, dados } — dados é o JSON da resposta (ou null).

async function lerResposta(resposta) {
    const texto = await resposta.text();
    return {
        ok: resposta.ok,
        status: resposta.status,
        dados: texto ? JSON.parse(texto) : null,
    };
}

// Pedido comum, com o corpo em JSON
async function api(metodo, caminho, corpo) {
    const opcoes = { method: metodo, headers: {} };
    if (corpo !== undefined) {
        opcoes.headers["Content-Type"] = "application/json";
        opcoes.body = JSON.stringify(corpo);
    }
    return lerResposta(await fetch(caminho, opcoes));
}

// Envia um arquivo (ex.: a foto de perfil) como corpo da requisição
async function enviarArquivo(metodo, caminho, arquivo) {
    const resposta = await fetch(caminho, {
        method: metodo,
        headers: { "Content-Type": "application/octet-stream" },
        body: arquivo,
    });
    return lerResposta(resposta);
}
