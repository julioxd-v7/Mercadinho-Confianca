# Como ligar o site do Confiança Mercadinho ao Supabase

## Antes de tudo: o que o canvas é e o que não é

O canvas (home + Painel ADM) é o **design navegável**. Os botões funcionam, mas os dados ficam só na tela: se você cadastrar um produto no ADM do canvas, a home não muda e tudo some ao recarregar.

Para funcionar de verdade são três peças:

1. **Banco de dados** (Supabase): guarda produtos, promoções, banners, pedidos e o login do ADM.
2. **O site de verdade** (código): a home e o ADM programados a partir deste design, lendo e gravando no banco.
3. **Hospedagem** (Vercel ou Netlify, ambos com plano grátis): coloca o site no ar com um endereço.

Este guia cobre a peça 1. A peça 2 eu posso construir para você a partir do design.

---

## 1. Use um projeto NOVO, separado dos outros

No Supabase, cada **projeto** é isolado: banco, logins, fotos e chaves próprias. Criar um projeto "Confiança Mercadinho" **não mexe em nada** dos projetos que você já tem.

Na sua conta eu vi a organização **Fy Solucoes Org** com 3 projetos:

| Projeto | Situação |
|---|---|
| FY Painel TV | ativo |
| FY Cobranca Boletos | ativo |
| Fy Whatsapp Cobranças | pausado |

**Atenção ao limite do plano grátis:** se essa organização estiver no plano **Free**, o Supabase só deixa **2 projetos ativos** ao mesmo tempo, e você já tem 2. Nesse caso, escolha uma saída:

- **A)** Assinar o plano Pro da organização (projetos extras são cobrados à parte).
- **B)** Pausar um projeto que não esteja em uso para abrir a vaga.
- **C)** Usar o **Firebase** só para o mercado (plano Spark é grátis e fica totalmente separado). Funciona, mas o SQL deste guia não serve lá. Se escolher Firebase, me avise que eu adapto.

Não use o projeto pausado "Fy Whatsapp Cobranças" para o mercado: misturaria os dados dos dois sistemas.

## 2. Criar o projeto

1. Entre em https://supabase.com/dashboard e clique em **New project**.
2. Organização: a sua. Nome: `confianca-mercadinho`.
3. **Database Password**: gere uma senha forte e guarde num gerenciador de senhas. Não mande essa senha para ninguém (nem para mim).
4. **Region**: `South America (São Paulo)`, que é a mais rápida para Paulista.
5. Clique em **Create new project** e espere uns 2 minutos.

## 3. Criar as tabelas

1. No menu da esquerda, abra **SQL Editor** → **New query**.
2. Abra o arquivo `schema.sql` desta pasta, copie tudo e cole no editor.
3. Clique em **Run**. Deve aparecer "Success. No rows returned".
4. Confira em **Table Editor**: devem existir `admins`, `store_settings`, `categories`, `products`, `promotions`, `banners`, `orders`. Em **Storage** deve existir o bucket `fotos`.

O que esse SQL já garante:

- O site público **só lê**: produtos visíveis, promoções ativas dentro da data, banners no período.
- **Só administradores logados** criam, editam ou apagam qualquer coisa.
- As regras do ADM viram regras do banco: promoção precisa ter preço menor que o anterior, e a data final precisa ser depois da inicial.

## 4. Criar o seu login do Painel ADM

1. Vá em **Authentication** → **Users** → **Add user** → **Create new user**.
2. Coloque o e-mail de quem vai administrar e uma senha. Marque **Auto Confirm User**.
3. Copie o **UID** desse usuário (aparece na lista).
4. Volte no **SQL Editor** e rode, trocando pelo UID copiado:

```sql
insert into public.admins (user_id) values ('COLE-O-UID-AQUI');
```

Para dar acesso a outra pessoa, repita os passos 1 a 4 com o e-mail dela.

Recomendado: em **Authentication** → **Sign In / Providers**, desligue **Allow new users to sign up**. Assim ninguém cria conta sozinho; só você adiciona usuários.

## 5. Pegar as chaves para o site

Em **Project Settings** → **API Keys** (ou no botão **Connect** do topo):

- **Project URL**: algo como `https://xxxx.supabase.co`
- **Publishable key** (ou `anon` key): pode ir no código do site. Ela é pública e quem protege os dados são as regras do passo 3.
- **Secret key / `service_role`**: **nunca** coloque no site nem mande para ninguém. Ela passa por cima de todas as regras.

Essas duas primeiras (URL + publishable key) são o que o site precisa. Quando eu construir o site, elas vão num arquivo `.env`, assim:

```
VITE_SUPABASE_URL=https://xxxx.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxx
```

## 6. Como o site vai usar o banco (resumo)

| No site | No banco |
|---|---|
| Ofertas do Dia / Encarte | lê `promotions` ativas + `products` |
| Catálogo e busca | lê `products` visíveis + `categories` |
| Banner da home | lê `banners` no período, por `sort` |
| Rodapé, WhatsApp, frete | lê `store_settings` |
| Login do ADM | Supabase Auth (e-mail e senha do passo 4) |
| Foto do produto no ADM | envia para o bucket `fotos` e grava o link em `products.image_url` |
| Pedidos no ADM | a loja registra em `orders` e muda o status |

O carrinho continua mandando o pedido pelo WhatsApp, como na copy. O site não cobra nada.

## 7. Próximo passo

Com o projeto criado (passos 2 a 4), me diga e eu:

1. transformo a home e o Painel ADM do canvas num site de verdade, com o mesmo visual e as animações;
2. ligo tudo ao Supabase com a URL e a publishable key;
3. deixo pronto para publicar na Vercel ou na Netlify.
