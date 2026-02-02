# Facility Production System - Fix Notes

## Sorunlar:
1. **DetailModal**: Üretim sırasında kaynaklar görünmüyor, status takılı kalıyor
2. **Production Screen**: Üretim başlatıldığında sorunlar oluyor, süre 00:00 kalıyor
3. **calculate_idle_resources**: Çok karmaşık, end_time limiti gereksiz

## Çözüm:
- Production **BAŞLADIĞINDA** production_started_at kaydedilir
- **HER ZAMAN** kaynaklar birikir (start_time'dan now'a kadar)
- Oyuncu **İSTEDİĞİ ZAMAN** toplamak çalıştırması gerekir
- Toplama sonrası **production_started_at SİFIRLANMAYACAK** (üretim devam eder)

## Kod Değişikliği Gerekli:
- calculate_idle_resources: Sadece elapsed_time * rate hesaplaması
- production_duration kalkal, end_time hesaplaması kaldırılacak
- Status: hep "active" olacak (production_started_at null değilse)
