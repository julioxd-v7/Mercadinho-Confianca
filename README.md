# Mercadinho Confiança

Site de ofertas e pedidos do **Mercadinho Confiança**, em Maranguape II, Paulista (PE).
O cliente monta a lista de compras no site e envia o pedido pronto pelo WhatsApp da loja.

Site estático, em HTML, CSS e [Alpine.js](https://alpinejs.dev) carregado por CDN. Não tem build nem dependências para instalar.

## Estrutura

```
.
├── index.html      # Site principal (home, ofertas, catálogo, carrinho)
├── admin.html      # Painel ADM (protótipo visual)
├── img/            # Fotos da loja, logo e cartazes de oferta
└── .gitignore
```

## O que o site faz

- **Ofertas do Dia** em cartazes ("É OFERTA" / "OFERTA %"), com contagem regressiva até a meia-noite.
- **Mais vendidos**, **Encarte da Semana** (com filtro por categoria), **Combos** e **Todos os produtos** (com busca e filtros), todos em carrossel. Dá para passar com o dedo, arrastando com o mouse ou pelas setas.
- **Promoções fixas da semana**: terça e quarta do hortifruti, quinta da carne, sexta da cerveja e sábado da padaria. O card do dia atual ganha o selo "Hoje".
- **Carrinho / lista de compras**:
  - quantidade digitável: pão francês em unidades, produtos de peso em gramas, o resto em unidades;
  - atalhos de quantidade (5/10/20 pães, 250 g/500 g/1 kg);
  - entrega ou retirada, forma de pagamento, troco e observações;
  - a lista fica salva no navegador do cliente;
  - o pedido completo vai para o WhatsApp da loja com um clique.
- **Acessibilidade**: botão no topo com tamanho do texto, alto contraste, destaque de links, fonte mais legível, espaçamento entre linhas e pausa das animações. Tem também o link "Pular para o conteúdo".
- **Modo escuro**: botão redondo no topo. A escolha fica salva para o visitante.
- Funciona no celular, no tablet e no computador.

## Rodar no computador

Basta abrir o `index.html` no navegador. Para simular um servidor de verdade, rode na pasta do projeto:

```bash
npx serve .
# ou
python3 -m http.server 8000
```

## Publicar na Vercel

1. Suba esta pasta para um repositório no GitHub.
2. Na Vercel, clique em **Add New → Project** e importe o repositório.
3. Em **Framework Preset**, escolha **Other**. Deixe Build Command e Output Directory em branco.
4. Clique em **Deploy**.

Depois disso, cada `git push` na branch `main` atualiza o site automaticamente.

## Onde editar

Tudo fica no `index.html`.

| O quê | Onde |
|---|---|
| Número do WhatsApp | `var WA = '5581988949059';` no topo do `<script>` |
| Produtos, preços e promoções | objeto `var P = { ... }`. Use `old` para o preço antigo, `tag` para o selo, `soldout: true` para produto esgotado e `max` para limite por cliente |
| Quais produtos aparecem em cada seção | listas `deals` (Ofertas do Dia), `top` (Mais vendidos), `combos` e a lista do encarte em `encIds` |
| Mensagens da faixa azul do topo | lista `bars` |
| Banners do topo | lista `slides` |
| Pão francês por unidade | `each: 0.05` (peso médio de 1 pão em kg) e `eachName: 'pães'` |

## Antes de lançar oficialmente

- [ ] Trocar os textos em **MAIÚSCULO NEGRITO** pelos dados reais: marcas, horários, bairros atendidos, valor do frete, CNPJ, Instagram e datas do encarte.
- [ ] Conferir preços e produtos reais.
- [ ] Remover `<meta name="robots" content="noindex">` do `index.html`, para o Google mostrar o site.
- [ ] Remover o selo `<div class="proto">Protótipo · preços de exemplo</div>`.
- [ ] Trocar as caixas coloridas dos produtos por fotos reais, se houver.
- [ ] Colocar depoimentos reais de clientes.

## Sobre o Painel ADM

O `admin.html` é só um **protótipo visual**. Ele mostra como seria o painel para cadastrar produtos, promoções e banners, mas ainda **não salva nada**: o que for cadastrado ali não muda o site e some ao recarregar a página. Para o painel funcionar de verdade, é preciso ligar um banco de dados, como Supabase ou Firebase.
