# 🚀 Como fazer Deploy na Vercel

## 📋 Passo a Passo

### 1️⃣ Acessar Vercel
- Acesse: https://vercel.com
- Faça login com sua conta GitHub

### 2️⃣ Importar Projeto
1. Clique em **"Add New..."** → **"Project"**
2. Selecione o repositório: **`vincebarbearia`**
3. Clique em **"Import"**

### 3️⃣ Configurar Variáveis de Ambiente ⚠️ IMPORTANTE

Na tela de configuração do projeto, clique em **"Environment Variables"** e adicione:

#### Variável 1: NEXT_PUBLIC_SUPABASE_URL
```
NEXT_PUBLIC_SUPABASE_URL
```
**Valor:**
```
https://nypuvicehlmllhbudghf.supabase.co
```

#### Variável 2: NEXT_PUBLIC_SUPABASE_ANON_KEY
```
NEXT_PUBLIC_SUPABASE_ANON_KEY
```
**Valor:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55cHV2aWNlaGxtbGxoYnVkZ2hmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc4MzIxOTgsImV4cCI6MjA3MzQwODE5OH0.USnNrsn-NtwQA04Qd8GkV_d0AyhLVhYgqvzGk7XlTek
```

#### Variável 3: SUPABASE_SERVICE_ROLE_KEY
```
SUPABASE_SERVICE_ROLE_KEY
```
**Valor:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55cHV2aWNlaGxtbGxoYnVkZ2hmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzgzMjE5OCwiZXhwIjoyMDczNDA4MTk4fQ.o0Q-2TIoiwyQ5gWljEwL7ZQwqjzVgavpkYblzFMctjA
```

### 4️⃣ Configurações do Build (já está configurado automaticamente)

✅ **Framework Preset:** Next.js
✅ **Build Command:** `npm run build` (padrão)
✅ **Output Directory:** `.next` (padrão)
✅ **Install Command:** `npm install` (padrão)

### 5️⃣ Deploy

1. Depois de adicionar as 3 variáveis de ambiente, clique em **"Deploy"**
2. Aguarde o build completar (2-5 minutos)
3. ✅ Seu site estará no ar!

---

## 🔗 Depois do Deploy

### URL de Produção
Você receberá uma URL tipo:
```
https://zissou.vercel.app
```

### ⚙️ Configurações Importantes

#### 1. Configurar domínio customizado (opcional)
- Vá em **Settings** → **Domains**
- Adicione seu domínio personalizado

#### 2. Webhook do N8N
Depois do deploy, atualize o webhook no N8N:
```
https://SEU-DOMINIO.vercel.app/api/agendamentos/criar
```

#### 3. CORS no Supabase
Adicione sua URL da Vercel nas configurações do Supabase:
1. Acesse Supabase → Authentication → URL Configuration
2. Adicione: `https://zissou.vercel.app`

---

## 🔄 Atualizações Automáticas

Cada vez que você fizer `git push` para o GitHub, a Vercel vai:
1. ✅ Detectar automaticamente
2. ✅ Fazer build
3. ✅ Deploy automático
4. ✅ Seu site atualiza sozinho!

---

## 🐛 Resolução de Problemas

### Erro: "Missing Environment Variables"
- Verifique se adicionou todas as 3 variáveis
- Certifique-se que não tem espaços extras nos valores

### Erro: "Build Failed"
- Verifique os logs do build na Vercel
- Geralmente é falta de variável de ambiente

### Página em branco após deploy
- Verifique o console do navegador (F12)
- Provavelmente é erro de conexão com Supabase
- Confira se as URLs do Supabase estão corretas

---

## ✨ Pronto!

Agora seu sistema Vince Barbearia está no ar e acessível de qualquer lugar! 🎉

**URLs importantes:**
- 🌐 Frontend: `https://zissou.vercel.app`
- 🔐 Login: `https://zissou.vercel.app/login`
- 📊 Dashboard: `https://zissou.vercel.app/dashboard`
- 🔌 API: `https://zissou.vercel.app/api/*`
