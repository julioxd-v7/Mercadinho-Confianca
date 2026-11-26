-- =============================================================
-- Confiança Mercadinho — banco de dados (Supabase / Postgres)
-- Rode este arquivo inteiro no SQL Editor de um projeto NOVO.
-- Ele cria as tabelas, as regras de segurança (RLS) e o bucket de fotos.
-- =============================================================

-- ---------- Administradores ----------
-- Quem estiver nesta tabela pode editar tudo pelo Painel ADM.
create table public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admins enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.admins a where a.user_id = auth.uid());
$$;

create policy "admin vê admins" on public.admins
  for select to authenticated using (public.is_admin());

-- ---------- Configurações da loja (1 linha só) ----------
create table public.store_settings (
  id smallint primary key default 1 check (id = 1),
  name text not null default 'Confiança Mercadinho',
  whatsapp text not null default '5581988949059',   -- só números, com 55 + DDD
  address text not null default 'Rua Felipe kk, 69, Maranguape II, Paulista',
  hours_week text not null default '7h–21h',
  hours_sunday text not null default '7h–13h',
  delivery_fee numeric(10,2),
  free_delivery_from numeric(10,2) default 50.00,
  delivery_areas text default 'Maranguape II',
  updated_at timestamptz not null default now()
);
insert into public.store_settings (id) values (1);

-- ---------- Categorias ----------
create table public.categories (
  id smallserial primary key,
  name text not null unique,
  tagline text,
  sort smallint not null default 0
);
insert into public.categories (name, tagline, sort) values
  ('Hortifruti', 'Fresco todo dia', 1),
  ('Açougue', 'Cortes na hora', 2),
  ('Padaria', 'Pão quentinho às 6h e 16h', 3),
  ('Mercearia', 'O básico da despensa', 4),
  ('Bebidas', 'Geladas e prontas', 5),
  ('Frios e Laticínios', 'Fatiados na hora', 6),
  ('Limpeza', 'Casa em ordem', 7),
  ('Higiene e Beleza', 'Cuidado diário', 8),
  ('Pet', 'Para quem também é da família', 9);

-- ---------- Produtos ----------
create table public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category_id smallint not null references public.categories (id),
  price numeric(10,2) not null check (price > 0),
  unit text not null default 'un' check (unit in ('un','kg','pct','cx','L')),
  stock integer check (stock is null or stock >= 0),   -- null = não controla estoque
  visible boolean not null default true,
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index products_category_idx on public.products (category_id);

-- ---------- Promoções ----------
create table public.promotions (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  old_price numeric(10,2) not null check (old_price > 0),
  promo_price numeric(10,2) not null check (promo_price > 0),
  type text not null check (type in ('Oferta do Dia','Encarte da Semana','Combo','Leve X Pague Y')),
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  tag text check (tag in ('Últimas unidades','Limite por cliente','Novidade')),
  per_customer_limit integer check (per_customer_limit is null or per_customer_limit > 0),
  featured boolean not null default false,          -- "Destacar na home"
  status text not null default 'rascunho' check (status in ('ativa','rascunho','encerrada')),
  created_at timestamptz not null default now(),
  constraint promo_menor_que_anterior check (promo_price < old_price),
  constraint data_final_depois_inicial check (ends_at > starts_at)
);
create index promotions_product_idx on public.promotions (product_id);
create index promotions_active_idx on public.promotions (status, ends_at);

-- ---------- Banners da home ----------
create table public.banners (
  id uuid primary key default gen_random_uuid(),
  tag text,
  title text not null,
  subtitle text,
  button_text text,
  link text,
  sort smallint not null default 0,
  image_desktop_url text,   -- 1920×600
  image_mobile_url text,    -- 800×800
  show_from date,
  show_until date
);

-- ---------- Pedidos (registrados pela loja, vindos do WhatsApp) ----------
create table public.orders (
  id bigserial primary key,
  customer_name text not null,
  customer_phone text,
  items jsonb not null default '[]'::jsonb,   -- [{ "name": "...", "qty": 2, "price": 24.90 }]
  total numeric(10,2) not null default 0,
  mode text not null default 'Entrega' check (mode in ('Entrega','Retirada')),
  address text,
  payment text,
  notes text,
  status text not null default 'Novo' check (status in ('Novo','Separando','Saiu para entrega','Pronto para retirada','Entregue','Cancelado')),
  created_at timestamptz not null default now()
);
create index orders_created_idx on public.orders (created_at desc);

-- ---------- Atualiza updated_at sozinho ----------
create or replace function public.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end; $$;
create trigger products_touch before update on public.products
  for each row execute function public.touch_updated_at();
create trigger settings_touch before update on public.store_settings
  for each row execute function public.touch_updated_at();

-- =============================================================
-- Segurança (RLS): o site público só LÊ o que deve aparecer;
-- só administradores logados escrevem.
-- =============================================================
alter table public.store_settings enable row level security;
alter table public.categories     enable row level security;
alter table public.products       enable row level security;
alter table public.promotions     enable row level security;
alter table public.banners        enable row level security;
alter table public.orders         enable row level security;

-- Leitura pública
create policy "público lê configurações" on public.store_settings for select to anon, authenticated using (true);
create policy "público lê categorias"    on public.categories     for select to anon, authenticated using (true);
create policy "público lê produtos visíveis" on public.products   for select to anon, authenticated using (visible or public.is_admin());
create policy "público lê promoções ativas"  on public.promotions for select to anon, authenticated
  using ((status = 'ativa' and now() between starts_at and ends_at) or public.is_admin());
create policy "público lê banners no período" on public.banners   for select to anon, authenticated
  using (((show_from is null or show_from <= current_date) and (show_until is null or show_until >= current_date)) or public.is_admin());

-- Escrita só para admin
create policy "admin edita configurações" on public.store_settings for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin gerencia categorias" on public.categories for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin gerencia produtos"   on public.products   for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin gerencia promoções"  on public.promotions for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin gerencia banners"    on public.banners    for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin gerencia pedidos"    on public.orders     for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- =============================================================
-- Fotos (Storage): bucket público para leitura, upload só admin
-- =============================================================
insert into storage.buckets (id, name, public) values ('fotos', 'fotos', true)
  on conflict (id) do nothing;

create policy "admin envia fotos"   on storage.objects for insert to authenticated with check (bucket_id = 'fotos' and public.is_admin());
create policy "admin troca fotos"   on storage.objects for update to authenticated using (bucket_id = 'fotos' and public.is_admin());
create policy "admin apaga fotos"   on storage.objects for delete to authenticated using (bucket_id = 'fotos' and public.is_admin());
