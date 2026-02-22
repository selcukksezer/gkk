// =====================================================
// components/ui/Modal.tsx - Genel modal dialog
// GDScript BaseDialog.gd, ConfirmDialog.gd, ErrorDialog.gd'den dönüştürüldü
// =====================================================
'use client'

import { useEffect, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'

// Temel Modal
interface ModalProps {
  isOpen: boolean
  onClose: () => void
  title?: string
  children: React.ReactNode
  size?: 'sm' | 'md' | 'lg'
  showCloseButton?: boolean
}

export function Modal({ isOpen, onClose, title, children, size = 'md', showCloseButton = true }: ModalProps) {
  const sizeMap = { sm: 'max-w-xs', md: 'max-w-sm', lg: 'max-w-md' }

  // ESC ile kapat
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) onClose()
    }
    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [isOpen, onClose])

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4">
          {/* Arka plan overlay */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 bg-black/70 backdrop-blur-sm"
            onClick={onClose}
          />

          {/* Modal içeriği */}
          <motion.div
            initial={{ opacity: 0, y: 50, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 50, scale: 0.95 }}
            transition={{ type: 'spring', damping: 25, stiffness: 400 }}
            className={`relative w-full ${sizeMap[size]} gk-panel z-10`}
          >
            {/* Başlık */}
            {(title || showCloseButton) && (
              <div className="flex items-center justify-between mb-4">
                {title && (
                  <h2 className="font-game text-gk-gold font-semibold text-lg">{title}</h2>
                )}
                {showCloseButton && (
                  <button
                    onClick={onClose}
                    className="w-8 h-8 flex items-center justify-center rounded-lg bg-gk-surface text-gk-silver hover:text-white transition-colors ml-auto"
                  >
                    ✕
                  </button>
                )}
              </div>
            )}

            {children}
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  )
}

// Onay Modalı
interface ConfirmModalProps {
  isOpen: boolean
  onClose: () => void
  onConfirm: () => void
  title?: string
  message: string
  confirmText?: string
  cancelText?: string
  danger?: boolean
  isLoading?: boolean
}

export function ConfirmModal({
  isOpen,
  onClose,
  onConfirm,
  title = 'Onay',
  message,
  confirmText = 'Evet',
  cancelText = 'İptal',
  danger = false,
  isLoading = false,
}: ConfirmModalProps) {
  const handleConfirm = useCallback(() => {
    onConfirm()
  }, [onConfirm])

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={title} size="sm">
      <p className="text-gk-silver text-sm mb-6">{message}</p>
      <div className="flex gap-3">
        <button onClick={onClose} disabled={isLoading} className="gk-btn-secondary flex-1">
          {cancelText}
        </button>
        <button
          onClick={handleConfirm}
          disabled={isLoading}
          className={`${danger ? 'gk-btn-danger' : 'gk-btn-gold'} flex-1 flex items-center justify-center gap-2`}
        >
          {isLoading ? (
            <span className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin" />
          ) : null}
          {confirmText}
        </button>
      </div>
    </Modal>
  )
}

// Hata Modalı
interface ErrorModalProps {
  isOpen: boolean
  onClose: () => void
  title?: string
  message: string
}

export function ErrorModal({ isOpen, onClose, title = 'Hata', message }: ErrorModalProps) {
  return (
    <Modal isOpen={isOpen} onClose={onClose} title={title} size="sm">
      <div className="flex items-start gap-3 mb-4">
        <span className="text-2xl flex-shrink-0">⚠️</span>
        <p className="text-gk-silver text-sm">{message}</p>
      </div>
      <button onClick={onClose} className="gk-btn-secondary w-full">
        Tamam
      </button>
    </Modal>
  )
}

// Bilgi Modalı
interface InfoModalProps {
  isOpen: boolean
  onClose: () => void
  title?: string
  message: string
}

export function InfoModal({ isOpen, onClose, title = 'Bilgi', message }: InfoModalProps) {
  return (
    <Modal isOpen={isOpen} onClose={onClose} title={title} size="sm">
      <div className="flex items-start gap-3 mb-4">
        <span className="text-2xl flex-shrink-0">ℹ️</span>
        <p className="text-gk-silver text-sm">{message}</p>
      </div>
      <button onClick={onClose} className="gk-btn-gold w-full">
        Tamam
      </button>
    </Modal>
  )
}
