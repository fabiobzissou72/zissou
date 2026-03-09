-- =====================================================
-- SCHEMA COMPLETO - APP BARBEARIA
-- Cria todas as tabelas/funcões/views usadas pelo dashboard e API
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================================================
-- TABELA: clientes
-- =====================================================
CREATE TABLE IF NOT EXISTS public.clientes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  telefone VARCHAR(20) UNIQUE NOT NULL,
  nome_completo VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  senha TEXT,
  data_nascimento DATE,
  profissao VARCHAR(100),
  estado_civil VARCHAR(50),
  tem_filhos VARCHAR(10),
  nomes_filhos TEXT[],
  idades_filhos TEXT[],
  estilo_cabelo VARCHAR(100),
  preferencias_corte TEXT,
  tipo_bebida VARCHAR(100),
  alergias TEXT,
  frequencia_retorno VARCHAR(50),
  profissional_preferido VARCHAR(255),
  observacoes TEXT,
  is_vip BOOLEAN DEFAULT FALSE,
  data_cadastro TIMESTAMPTZ DEFAULT NOW(),
  como_soube VARCHAR(100),
  gosta_conversar VARCHAR(50),
  menory_long TEXT,
  tratamento VARCHAR(100),
  ultimo_servico VARCHAR(255),
  plano_id UUID,
  ultimo_acesso TIMESTAMPTZ,
  estilo_preferido TEXT,
  bebida_preferida TEXT
);

-- =====================================================
-- TABELA: profissionais
-- =====================================================
CREATE TABLE IF NOT EXISTS public.profissionais (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome VARCHAR(255) NOT NULL,
  telefone VARCHAR(20),
  email VARCHAR(255),
  especialidades TEXT[] DEFAULT ARRAY[]::TEXT[],
  especialidade VARCHAR(100),
  ativo BOOLEAN DEFAULT TRUE,
  data_cadastro TIMESTAMPTZ DEFAULT NOW(),
  cor_calendario VARCHAR(7) DEFAULT '#3B82F6',
  id_agenda TEXT,
  foto_url TEXT
);

-- =====================================================
-- TABELA: servicos
-- =====================================================
CREATE TABLE IF NOT EXISTS public.servicos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome VARCHAR(255) NOT NULL,
  descricao TEXT,
  preco NUMERIC(10,2) NOT NULL,
  duracao_minutos INTEGER NOT NULL DEFAULT 30,
  categoria VARCHAR(100),
  executor VARCHAR(100),
  ativo BOOLEAN DEFAULT TRUE,
  data_cadastro TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABELA: produtos
-- =====================================================
CREATE TABLE IF NOT EXISTS public.produtos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome VARCHAR(255) NOT NULL,
  funcao TEXT,
  descricao TEXT,
  preco NUMERIC(10,2) NOT NULL,
  beneficios TEXT,
  contra_indicacoes TEXT,
  categoria VARCHAR(100),
  ativo BOOLEAN DEFAULT TRUE,
  estoque INTEGER DEFAULT 0,
  data_cadastro TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABELA: planos
-- =====================================================
CREATE TABLE IF NOT EXISTS public.planos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome VARCHAR(255) NOT NULL,
  itens_inclusos TEXT NOT NULL,
  valor_total NUMERIC(10,2) NOT NULL,
  valor_original NUMERIC(10,2) NOT NULL,
  economia NUMERIC(10,2) NOT NULL,
  validade_dias INTEGER DEFAULT 30,
  ativo BOOLEAN DEFAULT TRUE,
  data_cadastro TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABELA: agendamentos
-- =====================================================
CREATE TABLE IF NOT EXISTS public.agendamentos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id UUID REFERENCES public.clientes(id) ON DELETE SET NULL,
  profissional_id UUID REFERENCES public.profissionais(id) ON DELETE SET NULL,
  servico_id UUID REFERENCES public.servicos(id) ON DELETE SET NULL,
  data_agendamento VARCHAR(20) NOT NULL,
  hora_inicio VARCHAR(5) NOT NULL,
  hora_fim VARCHAR(5),
  status VARCHAR(50) DEFAULT 'agendado',
  observacoes TEXT,
  valor NUMERIC(10,2),
  google_calendar_event_id VARCHAR(255),
  data_criacao TIMESTAMPTZ DEFAULT NOW(),
  nome_cliente VARCHAR(255),
  telefone VARCHAR(20),
  telefone_cliente VARCHAR(20),
  compareceu BOOLEAN,
  checkin_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  "Barbeiro" VARCHAR(255)
);

-- =====================================================
-- TABELA: agendamento_servicos
-- =====================================================
CREATE TABLE IF NOT EXISTS public.agendamento_servicos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agendamento_id UUID NOT NULL REFERENCES public.agendamentos(id) ON DELETE CASCADE,
  servico_id UUID NOT NULL REFERENCES public.servicos(id) ON DELETE CASCADE,
  preco NUMERIC(10,2),
  duracao_minutos INTEGER
);

-- =====================================================
-- TABELA: vendas
-- =====================================================
CREATE TABLE IF NOT EXISTS public.vendas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id UUID REFERENCES public.clientes(id) ON DELETE SET NULL,
  profissional_id UUID REFERENCES public.profissionais(id) ON DELETE SET NULL,
  produto_id UUID NOT NULL REFERENCES public.produtos(id) ON DELETE RESTRICT,
  quantidade INTEGER NOT NULL DEFAULT 1,
  valor_unitario NUMERIC(10,2),
  preco_unitario NUMERIC(10,2),
  valor_total NUMERIC(10,2) NOT NULL,
  forma_pagamento VARCHAR(50) DEFAULT 'dinheiro',
  observacoes TEXT,
  data_venda TIMESTAMPTZ DEFAULT NOW(),
  data_cadastro TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABELA: cliente_planos
-- =====================================================
CREATE TABLE IF NOT EXISTS public.cliente_planos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id UUID NOT NULL REFERENCES public.clientes(id) ON DELETE CASCADE,
  plano_id UUID NOT NULL REFERENCES public.planos(id) ON DELETE CASCADE,
  data_contratacao TIMESTAMPTZ DEFAULT NOW(),
  data_expiracao TIMESTAMPTZ,
  valor_pago NUMERIC(10,2),
  status VARCHAR(50) DEFAULT 'ativo',
  observacoes TEXT
);

-- =====================================================
-- TABELA: compras
-- =====================================================
CREATE TABLE IF NOT EXISTS public.compras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id UUID REFERENCES public.clientes(id) ON DELETE SET NULL,
  produto_id UUID REFERENCES public.produtos(id) ON DELETE SET NULL,
  plano_id UUID REFERENCES public.planos(id) ON DELETE SET NULL,
  agendamento_id UUID REFERENCES public.agendamentos(id) ON DELETE SET NULL,
  quantidade INTEGER DEFAULT 1,
  valor_unitario NUMERIC(10,2),
  valor_total NUMERIC(10,2),
  data_compra TIMESTAMPTZ DEFAULT NOW(),
  status VARCHAR(50) DEFAULT 'pendente'
);

-- =====================================================
-- TABELA: configuracoes
-- =====================================================
CREATE TABLE IF NOT EXISTS public.configuracoes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_barbearia VARCHAR(255) NOT NULL DEFAULT 'zissou',
  endereco TEXT,
  telefone VARCHAR(50),
  email VARCHAR(255),
  horario_abertura VARCHAR(5) NOT NULL DEFAULT '09:00',
  horario_fechamento VARCHAR(5) NOT NULL DEFAULT '19:00',
  dias_funcionamento TEXT[] DEFAULT ARRAY['Segunda','Terça','Quarta','Quinta','Sexta','Sábado'],
  horarios_por_dia JSONB DEFAULT '{
    "Segunda": {"abertura": "09:00", "fechamento": "19:00", "ativo": true},
    "Terça": {"abertura": "09:00", "fechamento": "19:00", "ativo": true},
    "Quarta": {"abertura": "09:00", "fechamento": "19:00", "ativo": true},
    "Quinta": {"abertura": "09:00", "fechamento": "19:00", "ativo": true},
    "Sexta": {"abertura": "09:00", "fechamento": "19:00", "ativo": true},
    "Sábado": {"abertura": "09:00", "fechamento": "18:00", "ativo": true},
    "Domingo": {"abertura": "09:00", "fechamento": "18:00", "ativo": false}
  }'::jsonb,
  tempo_padrao_servico INTEGER NOT NULL DEFAULT 30,
  valor_minimo_agendamento NUMERIC(10,2) NOT NULL DEFAULT 0,
  notificacoes_whatsapp BOOLEAN NOT NULL DEFAULT TRUE,
  notificacoes_email BOOLEAN NOT NULL DEFAULT FALSE,
  aceita_agendamento_online BOOLEAN NOT NULL DEFAULT TRUE,
  comissao_barbeiro_percentual INTEGER NOT NULL DEFAULT 50,
  webhook_url TEXT,
  webhook_senha_url TEXT,
  api_token TEXT,
  prazo_cancelamento_horas INTEGER DEFAULT 2,
  notif_confirmacao BOOLEAN DEFAULT TRUE,
  notif_lembrete_24h BOOLEAN DEFAULT TRUE,
  notif_lembrete_2h BOOLEAN DEFAULT TRUE,
  notif_followup_3d BOOLEAN DEFAULT FALSE,
  notif_followup_21d BOOLEAN DEFAULT FALSE,
  notif_cancelamento BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABELA: profissionais_login
-- =====================================================
CREATE TABLE IF NOT EXISTS public.profissionais_login (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profissional_id UUID NOT NULL UNIQUE REFERENCES public.profissionais(id) ON DELETE CASCADE,
  email VARCHAR(255) UNIQUE NOT NULL,
  senha TEXT NOT NULL,
  ativo BOOLEAN DEFAULT TRUE,
  ultimo_login TIMESTAMPTZ,
  data_criacao TIMESTAMPTZ DEFAULT NOW(),
  data_atualizacao TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABELA: webhooks_barbeiros
-- =====================================================
CREATE TABLE IF NOT EXISTS public.webhooks_barbeiros (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profissional_id UUID NOT NULL REFERENCES public.profissionais(id) ON DELETE CASCADE,
  webhook_url TEXT NOT NULL,
  eventos TEXT[] DEFAULT ARRAY['novo_agendamento','cancelamento','confirmacao']::TEXT[],
  ativo BOOLEAN DEFAULT TRUE,
  data_cadastro TIMESTAMPTZ DEFAULT NOW(),
  data_atualizacao TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABELA: rodizio_barbeiros
-- =====================================================
CREATE TABLE IF NOT EXISTS public.rodizio_barbeiros (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profissional_id UUID NOT NULL REFERENCES public.profissionais(id) ON DELETE CASCADE,
  ordem INTEGER NOT NULL DEFAULT 0,
  ultima_vez TIMESTAMPTZ,
  total_atendimentos_hoje INTEGER DEFAULT 0,
  data_referencia DATE DEFAULT CURRENT_DATE,
  ativo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(profissional_id, data_referencia)
);

-- =====================================================
-- TABELA: agendamentos_cancelamentos
-- =====================================================
CREATE TABLE IF NOT EXISTS public.agendamentos_cancelamentos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agendamento_id UUID NOT NULL REFERENCES public.agendamentos(id) ON DELETE CASCADE,
  cancelado_por VARCHAR(100) NOT NULL,
  motivo TEXT,
  cancelado_em TIMESTAMPTZ DEFAULT NOW(),
  horas_antecedencia NUMERIC(10,2),
  permitido BOOLEAN DEFAULT TRUE,
  cliente_nome TEXT,
  cliente_telefone TEXT,
  barbeiro_nome TEXT,
  data_agendamento VARCHAR(20),
  hora_inicio VARCHAR(5),
  valor NUMERIC(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABELA: notificacoes_enviadas
-- =====================================================
CREATE TABLE IF NOT EXISTS public.notificacoes_enviadas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agendamento_id UUID NOT NULL REFERENCES public.agendamentos(id) ON DELETE CASCADE,
  tipo VARCHAR(50) NOT NULL,
  enviado_em TIMESTAMPTZ DEFAULT NOW(),
  status VARCHAR(50) DEFAULT 'enviado',
  tentativas INTEGER DEFAULT 1,
  payload JSONB,
  resposta JSONB,
  erro TEXT,
  webhook_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(agendamento_id, tipo)
);

-- =====================================================
-- TABELA: historico_atendimentos
-- =====================================================
CREATE TABLE IF NOT EXISTS public.historico_atendimentos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agendamento_id UUID NOT NULL UNIQUE REFERENCES public.agendamentos(id) ON DELETE CASCADE,
  profissional_id UUID NOT NULL REFERENCES public.profissionais(id) ON DELETE CASCADE,
  cliente_id UUID REFERENCES public.clientes(id) ON DELETE SET NULL,
  data_atendimento DATE NOT NULL,
  hora_inicio TIME NOT NULL,
  hora_fim TIME,
  servicos_realizados JSONB,
  valor_total NUMERIC(10,2) NOT NULL DEFAULT 0,
  duracao_minutos INTEGER,
  compareceu BOOLEAN DEFAULT TRUE,
  observacoes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABELA: movimentos_financeiros
-- =====================================================
CREATE TABLE IF NOT EXISTS public.movimentos_financeiros (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data_movimento DATE NOT NULL,
  hora_movimento TIME NOT NULL DEFAULT CURRENT_TIME,
  data_criacao TIMESTAMPTZ DEFAULT NOW(),
  tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('servico','produto','entrada','saida')),
  categoria VARCHAR(100),
  descricao TEXT,
  agendamento_id UUID REFERENCES public.agendamentos(id) ON DELETE CASCADE,
  venda_id UUID REFERENCES public.vendas(id) ON DELETE CASCADE,
  profissional_id UUID REFERENCES public.profissionais(id) ON DELETE SET NULL,
  profissional_nome VARCHAR(255),
  cliente_id UUID REFERENCES public.clientes(id) ON DELETE SET NULL,
  cliente_nome VARCHAR(255),
  servico_id UUID REFERENCES public.servicos(id) ON DELETE SET NULL,
  servico_nome VARCHAR(255),
  produto_id UUID REFERENCES public.produtos(id) ON DELETE SET NULL,
  produto_nome VARCHAR(255),
  quantidade INTEGER DEFAULT 1,
  valor_unitario NUMERIC(10,2) NOT NULL,
  valor_total NUMERIC(10,2) NOT NULL,
  valor NUMERIC(10,2),
  metodo_pagamento VARCHAR(50),
  status VARCHAR(20) DEFAULT 'confirmado',
  compareceu BOOLEAN DEFAULT TRUE,
  observacoes TEXT
);

-- =====================================================
-- COMPATIBILIDADE DE COLUNAS/CONSTRAINTS
-- =====================================================
ALTER TABLE public.clientes ADD COLUMN IF NOT EXISTS plano_id UUID;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'fk_clientes_planos'
  ) THEN
    ALTER TABLE public.clientes
      ADD CONSTRAINT fk_clientes_planos
      FOREIGN KEY (plano_id) REFERENCES public.planos(id) ON DELETE SET NULL;
  END IF;
END $$;

ALTER TABLE public.vendas ADD COLUMN IF NOT EXISTS valor_unitario NUMERIC(10,2);
ALTER TABLE public.vendas ADD COLUMN IF NOT EXISTS preco_unitario NUMERIC(10,2);

-- =====================================================
-- INDICES
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_clientes_telefone ON public.clientes(telefone);
CREATE INDEX IF NOT EXISTS idx_clientes_email ON public.clientes(email);
CREATE INDEX IF NOT EXISTS idx_clientes_plano_id ON public.clientes(plano_id);

CREATE INDEX IF NOT EXISTS idx_profissionais_nome ON public.profissionais(nome);
CREATE INDEX IF NOT EXISTS idx_profissionais_ativo ON public.profissionais(ativo);

CREATE INDEX IF NOT EXISTS idx_servicos_ativo ON public.servicos(ativo);
CREATE INDEX IF NOT EXISTS idx_produtos_ativo ON public.produtos(ativo);
CREATE INDEX IF NOT EXISTS idx_planos_ativo ON public.planos(ativo);

CREATE INDEX IF NOT EXISTS idx_agendamentos_data ON public.agendamentos(data_agendamento);
CREATE INDEX IF NOT EXISTS idx_agendamentos_cliente ON public.agendamentos(cliente_id);
CREATE INDEX IF NOT EXISTS idx_agendamentos_profissional ON public.agendamentos(profissional_id);
CREATE INDEX IF NOT EXISTS idx_agendamentos_status ON public.agendamentos(status);
CREATE INDEX IF NOT EXISTS idx_agendamentos_telefone ON public.agendamentos(telefone);

CREATE UNIQUE INDEX IF NOT EXISTS idx_agendamento_servicos_unique ON public.agendamento_servicos(agendamento_id, servico_id);
CREATE INDEX IF NOT EXISTS idx_ag_servicos_agendamento ON public.agendamento_servicos(agendamento_id);
CREATE INDEX IF NOT EXISTS idx_ag_servicos_servico ON public.agendamento_servicos(servico_id);

CREATE INDEX IF NOT EXISTS idx_vendas_data ON public.vendas(data_venda);
CREATE INDEX IF NOT EXISTS idx_vendas_produto ON public.vendas(produto_id);
CREATE INDEX IF NOT EXISTS idx_vendas_profissional ON public.vendas(profissional_id);
CREATE INDEX IF NOT EXISTS idx_vendas_cliente ON public.vendas(cliente_id);

CREATE INDEX IF NOT EXISTS idx_cliente_planos_cliente ON public.cliente_planos(cliente_id);
CREATE INDEX IF NOT EXISTS idx_cliente_planos_status ON public.cliente_planos(status);
CREATE INDEX IF NOT EXISTS idx_cliente_planos_expiracao ON public.cliente_planos(data_expiracao);

CREATE INDEX IF NOT EXISTS idx_compras_cliente ON public.compras(cliente_id);
CREATE INDEX IF NOT EXISTS idx_compras_agendamento ON public.compras(agendamento_id);

CREATE INDEX IF NOT EXISTS idx_profissionais_login_email ON public.profissionais_login(email);
CREATE INDEX IF NOT EXISTS idx_profissionais_login_profissional ON public.profissionais_login(profissional_id);

CREATE INDEX IF NOT EXISTS idx_webhooks_barbeiros_profissional ON public.webhooks_barbeiros(profissional_id);
CREATE INDEX IF NOT EXISTS idx_webhooks_barbeiros_ativo ON public.webhooks_barbeiros(ativo);

CREATE INDEX IF NOT EXISTS idx_rodizio_data ON public.rodizio_barbeiros(data_referencia);
CREATE INDEX IF NOT EXISTS idx_rodizio_profissional ON public.rodizio_barbeiros(profissional_id);
CREATE INDEX IF NOT EXISTS idx_rodizio_ativo ON public.rodizio_barbeiros(ativo);

CREATE INDEX IF NOT EXISTS idx_cancel_agendamento ON public.agendamentos_cancelamentos(agendamento_id);
CREATE INDEX IF NOT EXISTS idx_cancel_data ON public.agendamentos_cancelamentos(cancelado_em);

CREATE INDEX IF NOT EXISTS idx_notif_agendamento ON public.notificacoes_enviadas(agendamento_id);
CREATE INDEX IF NOT EXISTS idx_notif_tipo ON public.notificacoes_enviadas(tipo);
CREATE INDEX IF NOT EXISTS idx_notif_status ON public.notificacoes_enviadas(status);
CREATE INDEX IF NOT EXISTS idx_notif_enviado_em ON public.notificacoes_enviadas(enviado_em);

CREATE INDEX IF NOT EXISTS idx_hist_profissional ON public.historico_atendimentos(profissional_id);
CREATE INDEX IF NOT EXISTS idx_hist_cliente ON public.historico_atendimentos(cliente_id);
CREATE INDEX IF NOT EXISTS idx_hist_data ON public.historico_atendimentos(data_atendimento);

CREATE INDEX IF NOT EXISTS idx_movimentos_data ON public.movimentos_financeiros(data_movimento);
CREATE INDEX IF NOT EXISTS idx_movimentos_tipo ON public.movimentos_financeiros(tipo);
CREATE INDEX IF NOT EXISTS idx_movimentos_profissional ON public.movimentos_financeiros(profissional_id);
CREATE INDEX IF NOT EXISTS idx_movimentos_cliente ON public.movimentos_financeiros(cliente_id);

-- =====================================================
-- FUNCOES AUXILIARES / TRIGGERS
-- =====================================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_agendamentos_updated_at ON public.agendamentos;
CREATE TRIGGER update_agendamentos_updated_at
  BEFORE UPDATE ON public.agendamentos
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_configuracoes_updated_at ON public.configuracoes;
CREATE TRIGGER update_configuracoes_updated_at
  BEFORE UPDATE ON public.configuracoes
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE OR REPLACE FUNCTION public.update_profissionais_login_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.data_atualizacao = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_profissionais_login_updated_at ON public.profissionais_login;
CREATE TRIGGER update_profissionais_login_updated_at
  BEFORE UPDATE ON public.profissionais_login
  FOR EACH ROW
  EXECUTE FUNCTION public.update_profissionais_login_updated_at();

CREATE OR REPLACE FUNCTION public.sync_agendamentos_campos()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.telefone IS NULL THEN
    NEW.telefone := NEW.telefone_cliente;
  END IF;

  IF NEW.telefone_cliente IS NULL THEN
    NEW.telefone_cliente := NEW.telefone;
  END IF;

  IF NEW.status IS NULL THEN
    NEW.status := 'agendado';
  END IF;

  IF NEW.hora_fim IS NULL AND NEW.hora_inicio IS NOT NULL THEN
    NEW.hora_fim := TO_CHAR((NEW.hora_inicio::TIME + INTERVAL '30 minutes')::TIME, 'HH24:MI');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_sync_agendamentos ON public.agendamentos;
CREATE TRIGGER trigger_sync_agendamentos
  BEFORE INSERT OR UPDATE ON public.agendamentos
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_agendamentos_campos();

CREATE OR REPLACE FUNCTION public.limpar_rodizio_dia_anterior()
RETURNS VOID AS $$
BEGIN
  UPDATE public.rodizio_barbeiros
  SET ativo = FALSE
  WHERE data_referencia < CURRENT_DATE;

  INSERT INTO public.rodizio_barbeiros (profissional_id, data_referencia, total_atendimentos_hoje, ordem)
  SELECT
    p.id,
    CURRENT_DATE,
    0,
    ROW_NUMBER() OVER (ORDER BY p.nome)
  FROM public.profissionais p
  WHERE p.ativo = TRUE
  ON CONFLICT (profissional_id, data_referencia) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.atualizar_rodizio_barbeiro()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.profissional_id IS NULL OR NEW.data_agendamento IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.rodizio_barbeiros (profissional_id, data_referencia, total_atendimentos_hoje, ultima_vez)
  VALUES (NEW.profissional_id, TO_DATE(NEW.data_agendamento, 'DD/MM/YYYY'), 1, NOW())
  ON CONFLICT (profissional_id, data_referencia)
  DO UPDATE SET
    total_atendimentos_hoje = public.rodizio_barbeiros.total_atendimentos_hoje + 1,
    ultima_vez = NOW(),
    updated_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_atualizar_rodizio ON public.agendamentos;
CREATE TRIGGER trigger_atualizar_rodizio
  AFTER INSERT ON public.agendamentos
  FOR EACH ROW
  WHEN (NEW.status = 'agendado' OR NEW.status = 'confirmado')
  EXECUTE FUNCTION public.atualizar_rodizio_barbeiro();

CREATE OR REPLACE FUNCTION public.registrar_historico_atendimento()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'concluido' AND COALESCE(OLD.status, '') <> 'concluido' AND NEW.profissional_id IS NOT NULL THEN
    INSERT INTO public.historico_atendimentos (
      agendamento_id,
      profissional_id,
      cliente_id,
      data_atendimento,
      hora_inicio,
      hora_fim,
      valor_total,
      compareceu,
      observacoes
    ) VALUES (
      NEW.id,
      NEW.profissional_id,
      NEW.cliente_id,
      TO_DATE(NEW.data_agendamento, 'DD/MM/YYYY'),
      NEW.hora_inicio::TIME,
      COALESCE(NEW.hora_fim, NEW.hora_inicio)::TIME,
      COALESCE(NEW.valor, 0),
      COALESCE(NEW.compareceu, TRUE),
      NEW.observacoes
    )
    ON CONFLICT (agendamento_id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_registrar_historico ON public.agendamentos;
CREATE TRIGGER trigger_registrar_historico
  AFTER UPDATE ON public.agendamentos
  FOR EACH ROW
  EXECUTE FUNCTION public.registrar_historico_atendimento();

CREATE OR REPLACE FUNCTION public.registrar_movimento_agendamento()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.status IN ('concluido', 'em_andamento'))
     AND NEW.compareceu = TRUE
     AND (OLD.status IS NULL OR OLD.status NOT IN ('concluido', 'em_andamento') OR OLD.compareceu IS NOT TRUE)
  THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.movimentos_financeiros WHERE agendamento_id = NEW.id
    ) THEN
      INSERT INTO public.movimentos_financeiros (
        data_movimento,
        hora_movimento,
        tipo,
        agendamento_id,
        profissional_id,
        profissional_nome,
        cliente_id,
        cliente_nome,
        servico_id,
        servico_nome,
        quantidade,
        valor_unitario,
        valor_total,
        status,
        compareceu
      )
      SELECT
        TO_DATE(NEW.data_agendamento, 'DD/MM/YYYY'),
        NEW.hora_inicio::TIME,
        'servico',
        NEW.id,
        NEW.profissional_id,
        COALESCE(NEW."Barbeiro", p.nome),
        NEW.cliente_id,
        NEW.nome_cliente,
        ags.servico_id,
        s.nome,
        1,
        COALESCE(ags.preco, s.preco),
        COALESCE(ags.preco, s.preco),
        'confirmado',
        TRUE
      FROM public.agendamento_servicos ags
      JOIN public.servicos s ON s.id = ags.servico_id
      LEFT JOIN public.profissionais p ON p.id = NEW.profissional_id
      WHERE ags.agendamento_id = NEW.id;
    END IF;
  END IF;

  IF NEW.status = 'cancelado' AND OLD.status IS NOT NULL THEN
    DELETE FROM public.movimentos_financeiros WHERE agendamento_id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_movimento_agendamento ON public.agendamentos;
CREATE TRIGGER trigger_movimento_agendamento
  AFTER INSERT OR UPDATE ON public.agendamentos
  FOR EACH ROW
  EXECUTE FUNCTION public.registrar_movimento_agendamento();

CREATE OR REPLACE FUNCTION public.registrar_movimento_venda()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.movimentos_financeiros (
    data_movimento,
    hora_movimento,
    tipo,
    venda_id,
    profissional_id,
    profissional_nome,
    cliente_id,
    cliente_nome,
    produto_id,
    produto_nome,
    quantidade,
    valor_unitario,
    valor_total,
    status
  )
  SELECT
    NEW.data_venda::DATE,
    CURRENT_TIME,
    'produto',
    NEW.id,
    NEW.profissional_id,
    p.nome,
    NEW.cliente_id,
    c.nome_completo,
    NEW.produto_id,
    prod.nome,
    NEW.quantidade,
    COALESCE(NEW.valor_unitario, NEW.preco_unitario, prod.preco),
    NEW.valor_total,
    'confirmado'
  FROM public.produtos prod
  LEFT JOIN public.profissionais p ON p.id = NEW.profissional_id
  LEFT JOIN public.clientes c ON c.id = NEW.cliente_id
  WHERE prod.id = NEW.produto_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_movimento_venda ON public.vendas;
CREATE TRIGGER trigger_movimento_venda
  AFTER INSERT ON public.vendas
  FOR EACH ROW
  EXECUTE FUNCTION public.registrar_movimento_venda();

-- =====================================================
-- VIEWS
-- =====================================================
CREATE OR REPLACE VIEW public.v_rodizio_atual AS
SELECT
  r.id,
  r.profissional_id,
  p.nome AS profissional_nome,
  p.telefone AS profissional_telefone,
  r.total_atendimentos_hoje,
  r.ultima_vez,
  r.ordem,
  r.data_referencia,
  p.ativo AS profissional_ativo
FROM public.rodizio_barbeiros r
JOIN public.profissionais p ON r.profissional_id = p.id
WHERE r.data_referencia = CURRENT_DATE
  AND r.ativo = TRUE
  AND p.ativo = TRUE
ORDER BY r.total_atendimentos_hoje ASC, r.ultima_vez ASC NULLS FIRST, r.ordem ASC;

CREATE OR REPLACE VIEW public.v_movimentos_hoje AS
SELECT
  m.*,
  TO_CHAR(m.data_movimento, 'DD/MM/YYYY') AS data_formatada
FROM public.movimentos_financeiros m
WHERE m.data_movimento = CURRENT_DATE
ORDER BY m.hora_movimento DESC;

-- =====================================================
-- DADOS INICIAIS
-- =====================================================
INSERT INTO public.configuracoes (
  nome_barbearia,
  horario_abertura,
  horario_fechamento,
  dias_funcionamento,
  tempo_padrao_servico,
  valor_minimo_agendamento,
  notificacoes_whatsapp,
  notificacoes_email,
  aceita_agendamento_online,
  comissao_barbeiro_percentual
)
SELECT
  'zissou',
  '09:00',
  '19:00',
  ARRAY['Segunda','Terça','Quarta','Quinta','Sexta','Sábado'],
  30,
  0,
  TRUE,
  FALSE,
  TRUE,
  50
WHERE NOT EXISTS (SELECT 1 FROM public.configuracoes LIMIT 1);

SELECT public.limpar_rodizio_dia_anterior();

-- =====================================================
-- RLS + GRANTS
-- =====================================================
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'clientes',
    'profissionais',
    'servicos',
    'produtos',
    'planos',
    'agendamentos',
    'agendamento_servicos',
    'vendas',
    'cliente_planos',
    'compras',
    'configuracoes',
    'profissionais_login',
    'webhooks_barbeiros',
    'rodizio_barbeiros',
    'agendamentos_cancelamentos',
    'notificacoes_enviadas',
    'historico_atendimentos',
    'movimentos_financeiros'
  ]
  LOOP
    EXECUTE format('ALTER TABLE public.%I DISABLE ROW LEVEL SECURITY', t);
  END LOOP;
END $$;

GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- =====================================================
-- FIM
-- =====================================================
