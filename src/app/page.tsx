// =====================================================
// app/page.tsx - Kök sayfa
// Kimlik doğrulama durumuna göre yönlendirme
// =====================================================
import { redirect } from 'next/navigation'

export default function RootPage() {
  // İstemci tarafında oturum kontrolü yapacak
  // Server'da direkt login sayfasına yönlendir
  redirect('/login')
}
