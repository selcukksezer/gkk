// =====================================================
// app/(auth)/login/page.tsx - Giriş / Kayıt sayfası
// GDScript LoginScreen.gd + RegisterDialog.gd'den dönüştürüldü
// =====================================================
'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { motion, AnimatePresence } from 'framer-motion'
import { useSessionStore } from '@/store/sessionStore'
import type { AuthCredentials } from '@/store/sessionStore'

type AuthMode = 'login' | 'register'

export default function LoginPage() {
  const router = useRouter()
  const { login, register, isLoading, isAuthenticated, authError, clearError } = useSessionStore()

  const [mode, setMode] = useState<AuthMode>('login')
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: '',
    confirmPassword: '',
    rememberMe: false,
  })
  const [localError, setLocalError] = useState<string | null>(null)

  // Zaten giriş yapılmışsa ana sayfaya yönlendir
  useEffect(() => {
    if (isAuthenticated) {
      router.replace('/home')
    }
  }, [isAuthenticated, router])

  // Hata temizle
  useEffect(() => {
    clearError()
    setLocalError(null)
  }, [mode, clearError])

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type, checked } = e.target
    setFormData((prev) => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value,
    }))
    setLocalError(null)
  }

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()

    const username = formData.username.trim()
    const password = formData.password

    if (!username) { setLocalError('Kullanıcı adı gerekli'); return }
    if (!password) { setLocalError('Şifre gerekli'); return }
    if (password.length < 8) { setLocalError('Şifre en az 8 karakter olmalı'); return }

    const result = await login(username, password)
    if (result.success) {
      router.replace('/home')
    } else {
      setLocalError(result.error ?? 'Giriş başarısız')
    }
  }

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault()

    const username = formData.username.trim()
    const email = formData.email.trim()
    const password = formData.password
    const confirmPassword = formData.confirmPassword

    if (!username) { setLocalError('Kullanıcı adı gerekli'); return }
    if (username.length < 3) { setLocalError('Kullanıcı adı en az 3 karakter olmalı'); return }
    if (!email || !email.includes('@')) { setLocalError('Geçerli bir e-posta girin'); return }
    if (!password) { setLocalError('Şifre gerekli'); return }
    if (password.length < 8) { setLocalError('Şifre en az 8 karakter olmalı'); return }
    if (password !== confirmPassword) { setLocalError('Şifreler eşleşmiyor'); return }

    const credentials: AuthCredentials = { email, username, password }
    const result = await register(credentials)
    if (result.success) {
      router.replace('/home')
    } else {
      setLocalError(result.error ?? 'Kayıt başarısız')
    }
  }

  const displayError = localError ?? authError

  return (
    <div className="min-h-screen bg-gk-gradient flex flex-col items-center justify-center p-4 relative overflow-hidden">

      {/* Arka plan efekti */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -left-40 w-80 h-80 bg-gk-purple/20 rounded-full blur-3xl" />
        <div className="absolute -bottom-40 -right-40 w-80 h-80 bg-gk-crimson/20 rounded-full blur-3xl" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-gk-gold/5 rounded-full blur-3xl" />
      </div>

      <div className="w-full max-w-sm relative z-10">

        {/* Logo & Başlık */}
        <motion.div
          initial={{ opacity: 0, y: -30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-center mb-8"
        >
          <div className="text-6xl mb-3">⚔️</div>
          <h1 className="font-game text-3xl font-black text-gk-gold mb-1 tracking-widest">
            GÖLGE KRALLIK
          </h1>
          <p className="text-gk-silver text-sm tracking-wider">
            Kadim Mühür&apos;ün Çöküşü
          </p>
        </motion.div>

        {/* Form paneli */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="gk-panel"
        >
          {/* Sekme seçici */}
          <div className="flex mb-6 bg-gk-surface rounded-lg p-1">
            {(['login', 'register'] as const).map((tab) => (
              <button
                key={tab}
                onClick={() => setMode(tab)}
                className={`flex-1 py-2 rounded-md text-sm font-semibold transition-all duration-200 ${
                  mode === tab
                    ? 'bg-gk-gold text-gk-darker'
                    : 'text-gk-silver hover:text-white'
                }`}
              >
                {tab === 'login' ? 'Giriş Yap' : 'Kayıt Ol'}
              </button>
            ))}
          </div>

          {/* Form */}
          <AnimatePresence mode="wait">
            {mode === 'login' ? (
              <motion.form
                key="login"
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
                transition={{ duration: 0.2 }}
                onSubmit={handleLogin}
                className="space-y-4"
              >
                <div>
                  <label className="block text-gk-silver text-xs mb-1.5 font-medium tracking-wide">
                    KULLANICI ADI VEYA E-POSTA
                  </label>
                  <input
                    type="text"
                    name="username"
                    value={formData.username}
                    onChange={handleChange}
                    placeholder="kullaniciadi veya email@ornek.com"
                    className="gk-input"
                    autoComplete="username"
                    disabled={isLoading}
                  />
                </div>

                <div>
                  <label className="block text-gk-silver text-xs mb-1.5 font-medium tracking-wide">
                    ŞİFRE
                  </label>
                  <input
                    type="password"
                    name="password"
                    value={formData.password}
                    onChange={handleChange}
                    placeholder="••••••••"
                    className="gk-input"
                    autoComplete="current-password"
                    disabled={isLoading}
                  />
                </div>

                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="rememberMe"
                    name="rememberMe"
                    checked={formData.rememberMe}
                    onChange={handleChange}
                    className="w-4 h-4 accent-gk-gold"
                  />
                  <label htmlFor="rememberMe" className="text-gk-silver text-sm cursor-pointer">
                    Beni hatırla
                  </label>
                </div>

                {/* Hata mesajı */}
                <AnimatePresence>
                  {displayError && (
                    <motion.div
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: 'auto' }}
                      exit={{ opacity: 0, height: 0 }}
                      className="text-red-400 text-sm bg-red-900/20 border border-red-800 rounded-lg px-3 py-2"
                    >
                      ⚠️ {displayError}
                    </motion.div>
                  )}
                </AnimatePresence>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="gk-btn-gold w-full py-3 text-base"
                >
                  {isLoading ? (
                    <span className="flex items-center justify-center gap-2">
                      <span className="w-4 h-4 border-2 border-gk-darker border-t-transparent rounded-full animate-spin" />
                      Giriş yapılıyor...
                    </span>
                  ) : (
                    '⚔️ Giriş Yap'
                  )}
                </button>
              </motion.form>
            ) : (
              <motion.form
                key="register"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                transition={{ duration: 0.2 }}
                onSubmit={handleRegister}
                className="space-y-4"
              >
                <div>
                  <label className="block text-gk-silver text-xs mb-1.5 font-medium tracking-wide">
                    KULLANICI ADI
                  </label>
                  <input
                    type="text"
                    name="username"
                    value={formData.username}
                    onChange={handleChange}
                    placeholder="kahraman_adi"
                    className="gk-input"
                    autoComplete="username"
                    disabled={isLoading}
                    minLength={3}
                    maxLength={20}
                  />
                </div>

                <div>
                  <label className="block text-gk-silver text-xs mb-1.5 font-medium tracking-wide">
                    E-POSTA
                  </label>
                  <input
                    type="email"
                    name="email"
                    value={formData.email}
                    onChange={handleChange}
                    placeholder="ornek@email.com"
                    className="gk-input"
                    autoComplete="email"
                    disabled={isLoading}
                  />
                </div>

                <div>
                  <label className="block text-gk-silver text-xs mb-1.5 font-medium tracking-wide">
                    ŞİFRE
                  </label>
                  <input
                    type="password"
                    name="password"
                    value={formData.password}
                    onChange={handleChange}
                    placeholder="En az 8 karakter"
                    className="gk-input"
                    autoComplete="new-password"
                    disabled={isLoading}
                    minLength={8}
                  />
                </div>

                <div>
                  <label className="block text-gk-silver text-xs mb-1.5 font-medium tracking-wide">
                    ŞİFRE TEKRAR
                  </label>
                  <input
                    type="password"
                    name="confirmPassword"
                    value={formData.confirmPassword}
                    onChange={handleChange}
                    placeholder="Şifreyi tekrar girin"
                    className="gk-input"
                    autoComplete="new-password"
                    disabled={isLoading}
                  />
                </div>

                {/* Hata mesajı */}
                <AnimatePresence>
                  {displayError && (
                    <motion.div
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: 'auto' }}
                      exit={{ opacity: 0, height: 0 }}
                      className="text-red-400 text-sm bg-red-900/20 border border-red-800 rounded-lg px-3 py-2"
                    >
                      ⚠️ {displayError}
                    </motion.div>
                  )}
                </AnimatePresence>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="gk-btn-gold w-full py-3 text-base"
                >
                  {isLoading ? (
                    <span className="flex items-center justify-center gap-2">
                      <span className="w-4 h-4 border-2 border-gk-darker border-t-transparent rounded-full animate-spin" />
                      Kayıt yapılıyor...
                    </span>
                  ) : (
                    '🛡️ Hesap Oluştur'
                  )}
                </button>

                <p className="text-gk-silver text-xs text-center">
                  Hesap oluşturarak oyun kurallarını kabul etmiş olursunuz.
                </p>
              </motion.form>
            )}
          </AnimatePresence>
        </motion.div>

        {/* Alt metin */}
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6 }}
          className="text-center text-gk-silver/50 text-xs mt-4"
        >
          v0.1.0 Pre-Alpha • Gölge Krallık
        </motion.p>
      </div>
    </div>
  )
}
