-- ============================================================
-- MIGRAÇÃO DE DADOS → FIREFLY III
-- Executa DEPOIS que o Firefly III rodar pela primeira vez
-- e criar suas tabelas no Supabase.
-- ============================================================
-- Execute no SQL Editor do Supabase após o 1º login no Firefly.
-- ============================================================

-- 1. CRIAR USUÁRIO PADRÃO NO FIREFLY (se não existir)
-- O Firefly III cria o usuário via interface. 
-- Substitua o email/id abaixo pelo do seu usuário criado.
-- Para ver o ID do usuário: SELECT id, email FROM users;

DO $$
DECLARE
  v_user_id BIGINT;
  v_checking_account_id BIGINT;
  v_expense_account_id BIGINT;
  v_revenue_account_id BIGINT;
  v_journal_id BIGINT;
  v_withdrawal_type_id BIGINT;
  v_deposit_type_id BIGINT;
  v_currency_id BIGINT;
  r RECORD;
  v_cat_id BIGINT;
BEGIN

  -- Pega o primeiro usuário criado no Firefly
  SELECT id INTO v_user_id FROM users ORDER BY id LIMIT 1;
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nenhum usuário encontrado. Faça login no Firefly III primeiro e crie sua conta!';
  END IF;

  RAISE NOTICE 'Usando usuário ID: %', v_user_id;

  -- Pega IDs dos tipos de transação
  SELECT id INTO v_withdrawal_type_id FROM transaction_types WHERE type = 'Withdrawal';
  SELECT id INTO v_deposit_type_id FROM transaction_types WHERE type = 'Deposit';

  -- Pega moeda BRL (ou cria se não existir)
  SELECT id INTO v_currency_id FROM transaction_currencies WHERE code = 'BRL';
  IF v_currency_id IS NULL THEN
    INSERT INTO transaction_currencies (created_at, updated_at, code, name, symbol, decimal_places, enabled)
    VALUES (NOW(), NOW(), 'BRL', 'Brazilian Real', 'R$', 2, true)
    RETURNING id INTO v_currency_id;
  END IF;

  -- 2. CRIAR CONTA CORRENTE "C6 Bank"
  INSERT INTO accounts (created_at, updated_at, user_id, account_type_id, name, virtual_balance, iban, active, encrypted)
  SELECT NOW(), NOW(), v_user_id, at.id, 'C6 Bank', 0, NULL, true, false
  FROM account_types at WHERE at.type = 'Asset account'
  LIMIT 1
  RETURNING id INTO v_checking_account_id;

  RAISE NOTICE 'Conta C6 Bank criada: ID %', v_checking_account_id;

  -- 3. CRIAR CONTA "Despesas Gerais" (para saídas)
  INSERT INTO accounts (created_at, updated_at, user_id, account_type_id, name, virtual_balance, active, encrypted)
  SELECT NOW(), NOW(), v_user_id, at.id, 'Despesas Gerais', 0, true, false
  FROM account_types at WHERE at.type = 'Expense account'
  LIMIT 1
  RETURNING id INTO v_expense_account_id;

  -- 4. CRIAR CONTA "Receitas" (para entradas)
  INSERT INTO accounts (created_at, updated_at, user_id, account_type_id, name, virtual_balance, active, encrypted)
  SELECT NOW(), NOW(), v_user_id, at.id, 'Receitas Diversas', 0, true, false
  FROM account_types at WHERE at.type = 'Revenue account'
  LIMIT 1
  RETURNING id INTO v_revenue_account_id;

  -- 5. MIGRAR CATEGORIAS ÚNICAS
  FOR r IN SELECT DISTINCT categoria FROM public.transacoes LOOP
    -- Criar categoria se não existir
    IF NOT EXISTS (SELECT 1 FROM categories WHERE name = r.categoria AND user_id = v_user_id) THEN
      INSERT INTO categories (created_at, updated_at, user_id, name, encrypted)
      VALUES (NOW(), NOW(), v_user_id, r.categoria, false);
      RAISE NOTICE 'Categoria criada: %', r.categoria;
    END IF;
  END LOOP;

  -- 6. MIGRAR TRANSAÇÕES (despesas)
  FOR r IN 
    SELECT * FROM public.transacoes 
    ORDER BY ano, mes, dia
  LOOP
    -- Criar journal (cabeçalho da transação)
    INSERT INTO transaction_journals (
      created_at, updated_at, user_id, transaction_type_id,
      transaction_currency_id, description, date,
      order, tag_count, encrypted
    ) VALUES (
      NOW(), NOW(), v_user_id, v_withdrawal_type_id,
      v_currency_id, r.nome,
      make_date(r.ano, r.mes + 1, r.dia),  -- mes é 0-indexed no nosso banco
      0, 0, false
    ) RETURNING id INTO v_journal_id;

    -- Criar par de transações (double-entry)
    -- Saída da conta corrente
    INSERT INTO transactions (created_at, updated_at, account_id, transaction_journal_id, description, amount, identifier, reconciled)
    VALUES (NOW(), NOW(), v_checking_account_id, v_journal_id, r.nome, -r.valor, 0, false);

    -- Entrada na conta de despesas
    INSERT INTO transactions (created_at, updated_at, account_id, transaction_journal_id, description, amount, identifier, reconciled)
    VALUES (NOW(), NOW(), v_expense_account_id, v_journal_id, r.nome, r.valor, 1, false);

    -- Vincular categoria
    SELECT id INTO v_cat_id FROM categories WHERE name = r.categoria AND user_id = v_user_id LIMIT 1;
    IF v_cat_id IS NOT NULL THEN
      INSERT INTO category_transaction_journal (category_id, transaction_journal_id)
      VALUES (v_cat_id, v_journal_id);
    END IF;

  END LOOP;

  RAISE NOTICE 'Transações migradas: %', (SELECT COUNT(*) FROM public.transacoes);

  -- 7. MIGRAR RECEITAS
  FOR r IN SELECT * FROM public.receitas ORDER BY ano, mes, dia LOOP

    INSERT INTO transaction_journals (
      created_at, updated_at, user_id, transaction_type_id,
      transaction_currency_id, description, date, order, tag_count, encrypted
    ) VALUES (
      NOW(), NOW(), v_user_id, v_deposit_type_id,
      v_currency_id, r.nome,
      make_date(r.ano, r.mes + 1, r.dia),
      0, 0, false
    ) RETURNING id INTO v_journal_id;

    -- Saída da conta receitas
    INSERT INTO transactions (created_at, updated_at, account_id, transaction_journal_id, description, amount, identifier, reconciled)
    VALUES (NOW(), NOW(), v_revenue_account_id, v_journal_id, r.nome, -r.valor, 0, false);

    -- Entrada na conta corrente
    INSERT INTO transactions (created_at, updated_at, account_id, transaction_journal_id, description, amount, identifier, reconciled)
    VALUES (NOW(), NOW(), v_checking_account_id, v_journal_id, r.nome, r.valor, 1, false);

  END LOOP;

  RAISE NOTICE 'Receitas migradas: %', (SELECT COUNT(*) FROM public.receitas);
  RAISE NOTICE '✅ MIGRAÇÃO CONCLUÍDA!';

END $$;
