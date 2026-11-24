// Função única para conversar com o backend Haskell.
// Devolve { ok, status, dados } — dados é o JSON da resposta (ou null).
async function api(metodo, caminho, corpo) {
    const opcoes = { method: metodo, headers: {} };
    if (corpo !== undefined) {
        opcoes.headers["Content-Type"] = "application/json";
        opcoes.body = JSON.stringify(corpo);
    }
    const resposta = await fetch(caminho, opcoes);
    const texto = await resposta.text();
    return {
        ok: resposta.ok,
        status: resposta.status,
        dados: texto ? JSON.parse(texto) : null,
    };
}
