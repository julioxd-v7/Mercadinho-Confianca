# Como ligar o site do Confiança Mercadinho ao Firebase

O Firebase fica **totalmente separado** do seu Supabase: outra conta de serviço, outro banco, outros logins. Nada do que você já tem é afetado.

O que cada parte do Firebase faz aqui:

| Firebase | Serve para |
|---|---|
| **Authentication** | login do Painel ADM (e-mail e senha) |
| **Firestore** | banco: produtos, promoções, banners, categorias, pedidos, configurações |
| **Storage** | fotos dos produtos e dos banners |
| **Hosting** (opcional) | colocar o site no ar |

Arquivos desta pasta:

- `firestore.rules`: segurança do banco. O site só lê o que deve aparecer, e só admin edita.
- `storage.rules`: segurança das fotos. Todos veem, só admin envia (até 5 MB, JPG, PNG ou WebP).
- `firestore.indexes.json`: índices para as buscas do site ficarem rápidas.

---

## 1. Criar o projeto

1. Entre em https://console.firebase.google.com com a conta Google que vai cuidar do site.
2. **Criar projeto** → nome `confianca-mercadinho`.
3. Google Analytics: pode **desativar** (não precisa).
4. Espere criar e clique em **Continuar**.

## 2. Ligar o login (Authentication)

1. Menu **Criação** → **Authentication** → **Vamos começar**.
2. Em **Método de login**, ative **E-mail/senha** (só a primeira chave; deixe "link de e-mail" desligado) → **Salvar**.
3. Aba **Usuários** → **Adicionar usuário** → e-mail e senha de quem vai administrar.
4. Copie o **UID do usuário** que aparece na lista. Vai usar no passo 5.

## 3. Criar o banco (Firestore)

1. Menu **Criação** → **Firestore Database** → **Criar banco de dados**.
2. Local: **`southamerica-east1` (São Paulo)**. Atenção: isso não dá para mudar depois.
3. Escolha **Iniciar no modo de produção** → **Criar**.
4. Abra a aba **Regras**, apague o que estiver lá, cole o conteúdo de `firestore.rules` e clique em **Publicar**.

## 4. Fotos (Storage): atenção ao plano

Para criar o Storage, o Firebase hoje pede o plano **Blaze** (paga pelo uso, com cartão cadastrado). O Blaze mantém uma cota grátis, e um mercadinho com algumas centenas de fotos costuma ficar dentro dela. Mesmo assim, confira os valores atuais na página de preços do Firebase antes de ativar.

Se for usar:

1. Clique em **Fazer upgrade** → **Blaze** e cadastre o cartão.
2. **Recomendado:** em **Alertas de orçamento**, crie um alerta de R$ 10. Você recebe um e-mail se algo começar a gerar custo.
3. Menu **Storage** → **Vamos começar** → mesma região do banco.
4. Aba **Regras** → cole o conteúdo de `storage.rules` → **Publicar**.

Se preferir não colocar cartão agora: dá para começar sem Storage. O site e o ADM funcionam, e os produtos aparecem com o bloco colorido da categoria (como no design) até você ativar as fotos.

## 5. Dizer ao banco quem é admin

1. **Firestore Database** → aba **Dados** → **Iniciar coleção**.
2. ID da coleção: `admins`.
3. ID do documento: **cole o UID** do passo 2.4.
4. Adicione um campo qualquer, por exemplo `nome` (string) com o nome da pessoa → **Salvar**.

Para dar acesso a outra pessoa: crie o usuário dela em Authentication e um documento com o UID dela em `admins`. Para tirar o acesso: apague o documento.

## 6. Registrar o site e pegar a configuração

1. Na **Visão geral do projeto** (engrenagem) → **Configurações do projeto** → em **Seus apps**, clique no ícone **Web `</>`**.
2. Apelido: `site`. Pode deixar o Hosting desmarcado por enquanto → **Registrar app**.
3. Aparece um bloco `firebaseConfig` assim:

```js
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "confianca-mercadinho.firebaseapp.com",
  projectId: "confianca-mercadinho",
  storageBucket: "confianca-mercadinho.firebasestorage.app",
  messagingSenderId: "...",
  appId: "1:...:web:..."
};
```

Esse bloco **pode** ir no código do site. Ele identifica o projeto, não é senha, e quem protege os dados são as regras dos passos 3 e 4. Pode me mandar esse bloco quando eu for montar o site.

**Nunca** mande para ninguém: a senha da sua conta Google, nem arquivos de **conta de serviço** (JSON com `private_key`), que ficam em Configurações → Contas de serviço.

## 7. Como os dados ficam organizados

```
settings/store        → name, whatsapp, address, hoursWeek, hoursSunday, deliveryFee, freeDeliveryFrom, deliveryAreas
categories/{id}       → name, tagline, sort
products/{id}         → name, categoryId, price, unit (un|kg|pct|cx|L), stock (ou vazio), visible, imageUrl
promotions/{id}       → productId, oldPrice, promoPrice, type, startsAt, endsAt, tag, perCustomerLimit, featured, status (ativa|rascunho|encerrada)
banners/{id}          → tag, title, subtitle, buttonText, link, sort, imageDesktopUrl, imageMobileUrl, showFrom, showUntil
orders/{id}           → customerName, customerPhone, items[], total, mode, address, payment, notes, status, createdAt
admins/{uid}          → quem pode usar o Painel ADM
```

Você **não precisa** criar essas coleções na mão. Quando o site estiver pronto, ele cria as 9 categorias e as configurações da loja no primeiro acesso do admin.

As regras do ADM também valem dentro do banco: o Firestore recusa promoção com preço maior ou igual ao anterior, e recusa data final antes da inicial.

## 8. Próximo passo

Com os passos 1 a 3, 5 e 6 feitos (o 4 é opcional), me mande o bloco `firebaseConfig`. Aí eu:

1. transformo a home e o Painel ADM do canvas num site de verdade, com o mesmo visual e as animações;
2. ligo ao Firebase: login, produtos, promoções, banners, pedidos e fotos;
3. publico as regras e os índices desta pasta e deixo o site pronto para ir ao ar (Firebase Hosting, Vercel ou Netlify).
