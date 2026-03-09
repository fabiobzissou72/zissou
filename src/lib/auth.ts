import { supabase } from './supabase'
import bcrypt from 'bcryptjs'
import { randomBytes } from 'crypto'

export interface Profissional {
  id: string
  nome: string
  telefone: string
  especialidades: string[]
  ativo: boolean
  id_agenda?: string
}

export interface LoginData {
  profissional: Profissional
  email: string
}

// ============================================
// FUNÃ‡Ã•ES DE HASH DE SENHA (BCRYPT)
// ============================================

const SALT_ROUNDS = 12

/**
 * Gera hash de uma senha usando bcrypt
 */
export async function hashSenha(senha: string): Promise<string> {
  return bcrypt.hash(senha, SALT_ROUNDS)
}

/**
 * Verifica se uma senha corresponde ao hash
 */
export async function verificarSenha(senha: string, hash: string): Promise<boolean> {
  // Se o hash não começa com $2, é senha antiga em texto plano
  if (!hash.startsWith('$2')) {
    return senha === hash
  }
  return bcrypt.compare(senha, hash)
}

/**
 * Comparação de strings segura contra timing attacks
 * Sempre leva o mesmo tempo independente de onde as strings diferem
 */
export function compararTokensSeguro(a: string, b: string): boolean {
  if (a.length !== b.length) {
    // Para evitar timing attack, ainda fazemos a comparação completa
    let result = 0
    const maxLen = Math.max(a.length, b.length)
    for (let i = 0; i < maxLen; i++) {
      result |= (a.charCodeAt(i % a.length) || 0) ^ (b.charCodeAt(i % b.length) || 0)
    }
    return false // Tamanhos diferentes = sempre falso
  }

  let result = 0
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i)
  }
  return result === 0
}

export async function loginProfissional(email: string, senha: string): Promise<LoginData | null> {
  try {
    // Buscar dados de login no Supabase
    const { data: loginData, error: loginError } = await supabase
      .from('profissionais_login')
      .select(`
        *,
        profissionais (
          id,
          nome,
          telefone,
          especialidades,
          ativo,
          id_agenda
        )
      `)
      .eq('email', email)
      .eq('ativo', true)
      .single()

    if (loginError || !loginData || !loginData.profissionais) {
      return null
    }

    // Verificar senha usando bcrypt (também aceita senhas antigas em texto plano)
    const senhaValida = await verificarSenha(senha, loginData.senha)

    if (senhaValida) {
      // Se a senha estava em texto plano, atualizar para hash
      if (!loginData.senha.startsWith('$2')) {
        const senhaHash = await hashSenha(senha)
        await supabase
          .from('profissionais_login')
          .update({ senha: senhaHash })
          .eq('id', loginData.id)
      }

      // Atualizar último login
      await supabase
        .from('profissionais_login')
        .update({ ultimo_login: new Date().toISOString() })
        .eq('id', loginData.id)

      return {
        profissional: loginData.profissionais as Profissional,
        email: loginData.email
      }
    }

    return null
  } catch (error) {
    console.error('Erro no login:', error)
    return null
  }
}

export async function registrarProfissional(
  dadosProfissional: {
    nome: string
    telefone: string
    especialidades: string[]
  },
  dadosLogin: {
    email: string
    senha: string
  }
): Promise<{ success: boolean; error?: string }> {
  try {
    // Verificar se email já existe
    const { data: emailExiste } = await supabase
      .from('profissionais_login')
      .select('email')
      .eq('email', dadosLogin.email)
      .single()

    if (emailExiste) {
      return { success: false, error: 'Este email já está cadastrado' }
    }

    // Criar profissional
    const { data: novoProfissional, error: profissionalError } = await supabase
      .from('profissionais')
      .insert({
        nome: dadosProfissional.nome,
        telefone: dadosProfissional.telefone,
        especialidades: dadosProfissional.especialidades,
        ativo: true
      })
      .select()
      .single()

    if (profissionalError || !novoProfissional) {
      return { success: false, error: 'Erro ao criar profissional' }
    }

    // Criar login com senha hasheada
    const senhaHash = await hashSenha(dadosLogin.senha)
    const { error: loginError } = await supabase
      .from('profissionais_login')
      .insert({
        profissional_id: novoProfissional.id,
        email: dadosLogin.email,
        senha: senhaHash,
        ativo: true
      })

    if (loginError) {
      // Deletar profissional se falhou ao criar login
      await supabase
        .from('profissionais')
        .delete()
        .eq('id', novoProfissional.id)

      return { success: false, error: 'Erro ao criar login' }
    }

    return { success: true }
  } catch (error) {
    console.error('Erro no registro:', error)
    return { success: false, error: 'Erro interno do servidor' }
  }
}

/**
 * Reseta a senha de um profissional e retorna a nova senha temporária
 */
export async function resetarSenhaProfissional(email: string): Promise<{ success: boolean; novaSenha?: string; error?: string }> {
  try {
    // Verificar se o email existe
    const { data: loginData, error: loginError } = await supabase
      .from('profissionais_login')
      .select('id, profissional_id')
      .eq('email', email)
      .eq('ativo', true)
      .single()

    if (loginError || !loginData) {
      return { success: false, error: 'Email não encontrado no sistema' }
    }

    // Gerar senha temporária
    const novaSenha = require('crypto').randomBytes(4).toString('hex') + require('crypto').randomBytes(3).toString('hex').toUpperCase()

    // Hash da nova senha
    const senhaHash = await hashSenha(novaSenha)

    // Atualizar senha no banco
    const { error: updateError } = await supabase
      .from('profissionais_login')
      .update({ senha: senhaHash })
      .eq('id', loginData.id)

    if (updateError) {
      return { success: false, error: 'Erro ao atualizar senha' }
    }

    return { success: true, novaSenha }
  } catch (error) {
    console.error('Erro ao resetar senha:', error)
    return { success: false, error: 'Erro interno do servidor' }
  }
}

/**
 * Altera a senha de um profissional (usado pelo próprio usuário)
 */
export async function alterarSenhaProfissional(
  profissionalId: string,
  senhaAtual: string,
  novaSenha: string
): Promise<{ success: boolean; error?: string }> {
  try {
    // Buscar dados de login
    const { data: loginData, error: loginError } = await supabase
      .from('profissionais_login')
      .select('id, senha')
      .eq('profissional_id', profissionalId)
      .eq('ativo', true)
      .single()

    if (loginError || !loginData) {
      return { success: false, error: 'Profissional não encontrado' }
    }

    // Verificar senha atual
    const senhaValida = await verificarSenha(senhaAtual, loginData.senha)
    if (!senhaValida) {
      return { success: false, error: 'Senha atual incorreta' }
    }

    // Hash da nova senha
    const senhaHash = await hashSenha(novaSenha)

    // Atualizar senha
    const { error: updateError } = await supabase
      .from('profissionais_login')
      .update({ senha: senhaHash })
      .eq('id', loginData.id)

    if (updateError) {
      return { success: false, error: 'Erro ao atualizar senha' }
    }

    return { success: true }
  } catch (error) {
    console.error('Erro ao alterar senha:', error)
    return { success: false, error: 'Erro interno do servidor' }
  }
}

export async function getProfissionais(): Promise<Profissional[]> {
  try {
    const { data, error } = await supabase
      .from('profissionais')
      .select('*')
      .eq('ativo', true)
      .order('nome')

    if (error) {
      console.error('Erro ao buscar profissionais:', error)
      return []
    }

    return data || []
  } catch (error) {
    console.error('Erro ao buscar profissionais:', error)
    return []
  }
}

// ============================================
// AUTENTICAÃ‡ÃƒO POR TOKEN API
// ============================================

/**
 * Gera um token API aleatório seguro
 */
export function gerarTokenAPI(): string {
  const { randomBytes } = require('crypto')
  // base64url não suportado em todos os ambientes — usar hex
  return 'appbarbearia_' + randomBytes(32).toString('hex')
}

/**
 * Verifica se o token API fornecido é válido
 */
export async function verificarTokenAPI(token: string): Promise<{ valido: boolean; erro?: string }> {
  if (!token) {
    return {
      valido: false,
      erro: 'Token de autorização não fornecido. Use o header: Authorization: Bearer SEU_TOKEN'
    }
  }

  try {
    // Buscar token nas configurações
    const { data: config, error } = await supabase
      .from('configuracoes')
      .select('api_token')
      .single()

    if (error || !config) {
      return { valido: false, erro: 'Erro ao verificar token' }
    }

    if (!config.api_token) {
      return {
        valido: false,
        erro: 'Sistema sem token configurado. Configure um token em Configurações.'
      }
    }

    // Comparação segura contra timing attacks
    if (!compararTokensSeguro(token, config.api_token)) {
      return { valido: false, erro: 'Token inválido ou expirado' }
    }

    return { valido: true }
  } catch (err) {
    console.error('Erro ao verificar token:', err)
    return { valido: false, erro: 'Erro interno ao verificar token' }
  }
}

/**
 * Extrai o token do header Authorization de uma request
 */
export function extrairTokenDaRequest(request: Request): string | null {
  const authHeader = request.headers.get('Authorization')

  if (!authHeader) {
    return null
  }

  // Formato esperado: "Bearer TOKEN"
  const token = authHeader.replace('Bearer ', '').trim()

  return token || null
}

/**
 * Verifica se a requisição é interna (vem do próprio Next.js)
 * ATENÃ‡ÃƒO: Headers HTTP podem ser forjados, então esta verificação
 * é apenas uma camada adicional, não substitui autenticação real.
 * Para operações sensíveis, sempre exija token.
 */
function extrairHostSemPorta(urlOuHost: string): string {
  try {
    const asUrl = new URL(urlOuHost)
    return asUrl.hostname.toLowerCase()
  } catch {
    return urlOuHost.split(':')[0].toLowerCase()
  }
}

/**
 * Verifica se a requisicao e interna (vem do proprio app).
 * Prioriza o header X-Internal-Secret sobre referer/origin (que podem ser forjados).
 */
export function isRequisicaoInterna(request: Request): boolean {
  // Verificação primária: secret interno via env var (não pode ser forjado externamente)
  const internalSecret = process.env.INTERNAL_API_SECRET
  const headerSecret = request.headers.get('x-internal-secret')
  if (internalSecret && headerSecret && headerSecret === internalSecret) {
    return true
  }

  // Fallback: verificação por referer/origin (apenas para requisições do browser do dashboard)
  const referer = request.headers.get('referer')
  const host = request.headers.get('host')
  const origin = request.headers.get('origin')

  if (!host) {
    return false
  }

  const hostLimpo = extrairHostSemPorta(host)
  const refererHost = referer ? extrairHostSemPorta(referer) : null
  const originHost = origin ? extrairHostSemPorta(origin) : null

  if (refererHost && refererHost === hostLimpo) {
    return true
  }

  if (originHost && originHost === hostLimpo) {
    return true
  }

  return false
}
export async function verificarAutenticacao(request: Request): Promise<{ autorizado: boolean; erro?: string }> {
  // 1. Verificar se é requisição interna (do próprio sistema)
  if (isRequisicaoInterna(request)) {
    return { autorizado: true }
  }

  // 2. Se não é interna, exigir token
  const token = extrairTokenDaRequest(request)

  if (!token) {
    return {
      autorizado: false,
      erro: 'Token de autorização não fornecido. Use: Authorization: Bearer SEU_TOKEN'
    }
  }

  // 3. Validar token
  const { valido, erro } = await verificarTokenAPI(token)

  return {
    autorizado: valido,
    erro: erro
  }
}

