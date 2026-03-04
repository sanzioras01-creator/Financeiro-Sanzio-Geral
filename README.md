# 🚀 Firefly III + Supabase — Deploy no Railway

## O QUE É ISSO
Firefly III rodando via Railway, usando seu Supabase PostgreSQL como banco de dados.
Todos os seus dados (transacoes, receitas) serão migrados automaticamente.

---

## PASSO 1 — Pegar a senha do banco Supabase

1. Acesse https://supabase.com → seu projeto
2. Menu lateral → **Settings** → **Database**
3. Copie ou resete a **Database password**
4. Abra o arquivo `.env` e substitua `SENHA_DO_BANCO_SUPABASE` pela senha real

---

## PASSO 2 — Gerar APP_KEY

Acesse: https://www.browserling.com/tools/random-string
- Length: 32
- Type: alphanumeric
- Copie o resultado e cole no `.env` em `APP_KEY=`

---

## PASSO 3 — Deploy no Railway

1. Acesse https://railway.app e faça login com GitHub
2. Clique em **"New Project"** → **"Deploy from GitHub repo"**
3. Selecione o repositório onde você subiu esses arquivos
   (ou clique em **"Empty project"** → **"Add Service"** → **"GitHub Repo"**)

4. Na aba **"Variables"** do serviço, adicione TODAS as variáveis do `.env`:
   ```
   APP_ENV=local
   APP_KEY=sua_chave_32_chars
   APP_URL=https://SEU_PROJETO.up.railway.app
   DB_CONNECTION=pgsql
   DB_HOST=db.wqajkohquvoukljpkqet.supabase.co
   DB_PORT=5432
   DB_DATABASE=postgres
   DB_USERNAME=postgres
   DB_PASSWORD=sua_senha_aqui
   TZ=America/Sao_Paulo
   DEFAULT_LANGUAGE=pt_BR
   DEFAULT_LOCALE=pt_BR
   DEFAULT_CURRENCY=BRL
   CACHE_DRIVER=file
   SESSION_DRIVER=file
   TRUSTED_PROXIES=**
   ```

5. Clique em **"Deploy"**
6. Aguarde ~3 minutos para o build completar
7. Copie a URL gerada pelo Railway (ex: `firefly-xxx.up.railway.app`)
8. Atualize `APP_URL` nas variáveis com essa URL

---

## PASSO 4 — Primeiro acesso

1. Acesse a URL do Railway no navegador
2. Crie seu usuário administrador (email + senha)
3. Defina a moeda padrão como **BRL (Brazilian Real)**
4. Complete o setup inicial

---

## PASSO 5 — Migrar seus dados

1. Acesse o **SQL Editor** no Supabase Dashboard
2. Cole todo o conteúdo do arquivo `migrar_dados.sql`
3. Clique em **"Run"**
4. Aguarde a mensagem: `✅ MIGRAÇÃO CONCLUÍDA!`
5. Volte ao Firefly III e veja seus dados! 🎉

---

## RESULTADO ESPERADO no Firefly III

- ✅ 113 transações importadas (despesas de Fev + Mar/2026)
- ✅ 16 receitas importadas
- ✅ Todas as categorias criadas automaticamente:
  - Alimentação, Mercado, Combustível, Transferência
  - Conta de Luz, Conta de Água, Assinaturas
  - Compras Online, Transporte, Saúde, Seguro, etc.
- ✅ Conta corrente "C6 Bank" criada
- ✅ Dashboard com gráficos e relatórios

---

## ACESSO LOCAL (opcional, para testar antes)

```bash
# Instale Docker Desktop e rode:
docker-compose up -d

# Acesse: http://localhost:8080
```

---

## ESTRUTURA DOS ARQUIVOS

```
firefly/
├── docker-compose.yml    # Para rodar local
├── Dockerfile            # Para Railway
├── railway.toml          # Config Railway
├── .env                  # Variáveis (coloque a senha aqui!)
├── migrar_dados.sql      # Migração dos dados do Supabase
└── README.md             # Este arquivo
```

---

## SUPABASE — SUAS CREDENCIAIS

- **Projeto:** wqajkohquvoukljpkqet
- **Host:** db.wqajkohquvoukljpkqet.supabase.co
- **Porta:** 5432
- **Database:** postgres
- **Usuário:** postgres
- **Senha:** (você tem no Supabase Dashboard)
