// =====================================================
// components/ui/LoadingSpinner.tsx - Yükleme göstergesi
// =====================================================
'use client'

import { motion } from 'framer-motion'

interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg'
  message?: string
  fullScreen?: boolean
}

export default function LoadingSpinner({
  size = 'md',
  message,
  fullScreen = false,
}: LoadingSpinnerProps) {
  const sizeMap = { sm: 'w-6 h-6', md: 'w-10 h-10', lg: 'w-16 h-16' }

  const spinner = (
    <div className="flex flex-col items-center justify-center gap-3">
      <div className={`${sizeMap[size]} relative`}>
        <motion.div
          className="absolute inset-0 border-2 border-gk-gold/30 rounded-full"
        />
        <motion.div
          className="absolute inset-0 border-2 border-transparent border-t-gk-gold rounded-full"
          animate={{ rotate: 360 }}
          transition={{ duration: 1, repeat: Infinity, ease: 'linear' }}
        />
      </div>
      {message && (
        <p className="text-gk-silver text-sm animate-pulse">{message}</p>
      )}
    </div>
  )

  if (fullScreen) {
    return (
      <div className="fixed inset-0 bg-gk-darker/90 flex items-center justify-center z-50">
        {spinner}
      </div>
    )
  }

  return spinner
}
