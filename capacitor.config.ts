import { CapacitorConfig } from '@capacitor/cli'

const config: CapacitorConfig = {
  appId: 'com.golge.krallik',
  appName: 'Gölge Krallık',
  webDir: 'out',          // Next.js static export çıktı dizini
  server: {
    // Geliştirme sırasında canlı reload için
    // url: 'http://192.168.x.x:3000', // ← yerel IP adresi ile değiştir
    cleartext: false,
  },
  plugins: {
    // Gelecekte eklenecek plugin yapılandırmaları:
    // SplashScreen, StatusBar, Haptics vb.
  },
  ios: {
    contentInset: 'automatic',
    preferredContentMode: 'mobile',
    backgroundColor: '#0a0a0f',
  },
  android: {
    backgroundColor: '#0a0a0f',
    allowMixedContent: false,
    captureInput: true,
  },
}

export default config
