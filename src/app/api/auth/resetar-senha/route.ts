import { NextResponse } from 'next/server'
import { resetarSenhaProfissional, verificarAutenticacao } from '@/lib/auth'

export async function POST(request: Request) {
  try {
    // Exige autenticação - apenas admin logado pode resetar senhas
    const { autorizado, erro } = await verificarAutenticacao(request)
    if (!autorizado) {
      return NextResponse.json(
        { success: false, error: erro || 'Não autorizado' },
        { status: 401 }
      )
    }

    const body = await request.json()
    const { email } = body

    if (!email) {
      return NextResponse.json(
        { success: false, error: 'Email é obrigatório' },
        { status: 400 }
      )
    }

    const resultado = await resetarSenhaProfissional(email)

    if (!resultado.success) {
      return NextResponse.json(
        { success: false, error: resultado.error },
        { status: 400 }
      )
    }

    // Senha retornada apenas para o admin autenticado que fez o reset
    return NextResponse.json({
      success: true,
      novaSenha: resultado.novaSenha,
      mensagem: 'Senha resetada com sucesso! Anote a nova senha temporária.'
    })
  } catch (error) {
    console.error('Erro ao resetar senha:', error)
    return NextResponse.json(
      { success: false, error: 'Erro interno do servidor' },
      { status: 500 }
    )
  }
}
