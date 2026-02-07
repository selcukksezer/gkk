#!/bin/bash

# ==============================================================================
# Veritabanı Kurtarma Scripti - Gölge Krallık
# Database Restoration Script
# ==============================================================================
# Bu script, silinen veritabanını parça parça SQL dosyalarından geri yükler.
# This script restores the deleted database from scattered SQL files.
# ==============================================================================

set -e  # Hata durumunda dur / Stop on error

# Renkler / Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Başlık / Header
echo -e "${CYAN}=============================================${NC}"
echo -e "${CYAN}  VERİTABANI KURTARMA SİSTEMİ${NC}"
echo -e "${CYAN}  Database Restoration System${NC}"
echo -e "${CYAN}=============================================${NC}"
echo ""

# Çalışma dizini / Working directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# ==============================================================================
# Yapılandırma / Configuration
# ==============================================================================

PROJECT_REF="znvsyzstmxhqvdkkmgdt"
DB_HOST="db.${PROJECT_REF}.supabase.co"
DB_PORT="5432"
DB_NAME="postgres"
DB_USER="postgres"

echo -e "${YELLOW}Yapılandırma / Configuration:${NC}"
echo -e "  Proje ID: ${GREEN}${PROJECT_REF}${NC}"
echo -e "  Veritabanı: ${GREEN}${DB_HOST}${NC}"
echo ""

# Şifre kontrolü / Password check
if [ -z "$DB_PASSWORD" ]; then
    echo -e "${YELLOW}Lütfen veritabanı şifresini girin:${NC}"
    echo -e "${YELLOW}Please enter database password:${NC}"
    read -s DB_PASSWORD
    echo ""
fi

# Bağlantı URL'si / Connection URL
DB_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# ==============================================================================
# Yöntem Seçimi / Method Selection
# ==============================================================================

echo -e "${BLUE}Kurulum yöntemi seçin / Choose installation method:${NC}"
echo ""
echo "1) Otomatik - Tüm dosyaları sırayla çalıştır (Önerilen)"
echo "   Automatic - Run all files in order (Recommended)"
echo ""
echo "2) Manuel - Sadece temel şema dosyalarını çalıştır"
echo "   Manual - Run only core schema files"
echo ""
echo "3) Özel - Belirli bir dosyayı çalıştır"
echo "   Custom - Run a specific file"
echo ""
echo "4) Supabase CLI kullan"
echo "   Use Supabase CLI"
echo ""
read -p "Seçiminiz (1-4): " CHOICE

# ==============================================================================
# Fonksiyonlar / Functions
# ==============================================================================

# SQL dosyasını çalıştır / Execute SQL file
execute_sql() {
    local file=$1
    local description=$2
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ Dosya bulunamadı / File not found: $file${NC}"
        return 1
    fi
    
    echo -e "${BLUE}▶ Çalıştırılıyor / Executing: ${NC}$description"
    echo -e "${BLUE}  Dosya / File: ${NC}$file"
    
    if psql "$DB_URL" -f "$file" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Başarılı / Success${NC}"
        return 0
    else
        echo -e "${RED}❌ Hata / Error${NC}"
        echo -e "${YELLOW}Devam edilsin mi? (E/H) Continue? (Y/N)${NC}"
        read -r response
        if [[ "$response" =~ ^([eEyY])$ ]]; then
            return 0
        else
            return 1
        fi
    fi
    echo ""
}

# Bağlantı testi / Connection test
test_connection() {
    echo -e "${YELLOW}Bağlantı test ediliyor / Testing connection...${NC}"
    if psql "$DB_URL" -c "SELECT version();" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Bağlantı başarılı / Connection successful${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}❌ Bağlantı başarısız / Connection failed${NC}"
        echo -e "${RED}Lütfen şifrenizi ve bağlantı bilgilerinizi kontrol edin.${NC}"
        echo -e "${RED}Please check your password and connection details.${NC}"
        exit 1
    fi
}

# ==============================================================================
# Ana Kurulum / Main Installation
# ==============================================================================

case $CHOICE in
    1)
        echo ""
        echo -e "${CYAN}=============================================${NC}"
        echo -e "${CYAN}  OTOMATİK KURULUM BAŞLIYOR${NC}"
        echo -e "${CYAN}  Starting Automatic Installation${NC}"
        echo -e "${CYAN}=============================================${NC}"
        echo ""
        
        test_connection
        
        echo -e "${YELLOW}FAZ 1: Temel Altyapı / Core Infrastructure${NC}"
        echo ""
        execute_sql "supabase/sql/01_create_inventory_table.sql" "Envanter Tablosu / Inventory Table"
        execute_sql "supabase/sql/02_normalize_and_rpc.sql" "Normalizasyon / Normalization"
        execute_sql "supabase/sql/03_equipment_system.sql" "Ekipman Sistemi / Equipment System"
        execute_sql "supabase/sql/04_slot_position_rpcs.sql" "Slot Fonksiyonları / Slot Functions"
        execute_sql "supabase/sql/hospital_functions.sql" "Hastane Fonksiyonları / Hospital Functions"
        
        echo ""
        echo -e "${YELLOW}FAZ 2: Sistem Düzeltmeleri / System Fixes${NC}"
        echo ""
        execute_sql "database/migrations/00_MASTER_FIX_ALL.sql" "Ana Düzeltme / Master Fix"
        
        echo ""
        echo -e "${YELLOW}FAZ 3: Ana Sistemler / Main Systems${NC}"
        echo ""
        
        # Tesisler için hangisinin daha yeni olduğunu kontrol et
        if [ -f "database/migrations/20260130201441_facilities_system.sql" ]; then
            execute_sql "database/migrations/20260130201441_facilities_system.sql" "Tesis Sistemi / Facilities System"
        else
            execute_sql "database/migrations/create_facilities_system.sql" "Tesis Sistemi / Facilities System"
        fi
        
        execute_sql "database/migrations/create_prison_system.sql" "Hapishane Sistemi / Prison System"
        execute_sql "database/migrations/create_market_system.sql" "Pazar Sistemi / Market System"
        
        echo ""
        echo -e "${YELLOW}FAZ 4: RPC Fonksiyonları / RPC Functions${NC}"
        echo ""
        execute_sql "database/migrations/create_collect_rpc_v2.sql" "Toplama RPC / Collect RPC"
        execute_sql "database/migrations/create_get_player_facilities_rpc.sql" "Oyuncu Tesisleri RPC"
        execute_sql "database/migrations/create_get_facility_recipes_rpc.sql" "Tesis Tarifleri RPC"
        execute_sql "database/migrations/create_upgrade_facility_rpc.sql" "Tesis Yükseltme RPC"
        execute_sql "database/migrations/create_purchase_listing_rpc.sql" "Satın Alma RPC"
        execute_sql "database/migrations/add_collect_facility_resources_rpc.sql" "Kaynak Toplama RPC"
        
        echo ""
        echo -e "${YELLOW}FAZ 5: Öğeler ve Veriler / Items and Data${NC}"
        echo ""
        execute_sql "database/migrations/add_all_resource_items.sql" "Kaynak Öğeleri / Resource Items"
        execute_sql "database/migrations/add_craftable_items.sql" "Üretilebilir Öğeler / Craftable Items"
        execute_sql "database/migrations/add_crafting_recipes.sql" "Üretim Tarifleri / Crafting Recipes"
        execute_sql "database/migrations/insert_facility_items.sql" "Tesis Öğeleri / Facility Items"
        execute_sql "database/migrations/seed_facility_recipes_complete.sql" "Tesis Tarifleri / Facility Recipes"
        execute_sql "database/migrations/add_15_resource_facilities.sql" "15 Kaynak Tesisi / 15 Resource Facilities"
        
        echo ""
        echo -e "${GREEN}=============================================${NC}"
        echo -e "${GREEN}✅ KURULUM TAMAMLANDI!${NC}"
        echo -e "${GREEN}✅ Installation Complete!${NC}"
        echo -e "${GREEN}=============================================${NC}"
        ;;
        
    2)
        echo ""
        echo -e "${CYAN}Manuel kurulum - Temel şema dosyaları${NC}"
        echo ""
        
        test_connection
        
        execute_sql "supabase/sql/01_create_inventory_table.sql" "Envanter Tablosu"
        execute_sql "supabase/sql/02_normalize_and_rpc.sql" "Normalizasyon"
        execute_sql "supabase/sql/03_equipment_system.sql" "Ekipman Sistemi"
        execute_sql "supabase/sql/04_slot_position_rpcs.sql" "Slot Fonksiyonları"
        execute_sql "supabase/sql/hospital_functions.sql" "Hastane Fonksiyonları"
        
        echo -e "${GREEN}✅ Temel şema kurulumu tamamlandı!${NC}"
        echo -e "${YELLOW}Diğer dosyalar için lütfen kılavuza bakın: VERITABANI_KURULUM_KILAVUZU.md${NC}"
        ;;
        
    3)
        echo ""
        echo -e "${YELLOW}Lütfen SQL dosyasının yolunu girin:${NC}"
        read -r SQL_FILE
        
        test_connection
        execute_sql "$SQL_FILE" "Özel Dosya"
        ;;
        
    4)
        echo ""
        echo -e "${CYAN}Supabase CLI kullanımı${NC}"
        echo ""
        
        # Supabase CLI kontrol et
        if ! command -v supabase &> /dev/null; then
            echo -e "${RED}❌ Supabase CLI bulunamadı!${NC}"
            echo -e "${YELLOW}Kurulum için: npm install -g supabase${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}Projeye bağlanılıyor...${NC}"
        supabase link --project-ref "$PROJECT_REF"
        
        echo ""
        echo -e "${YELLOW}Migrasyonlar gönderiliyor...${NC}"
        supabase db push
        
        echo ""
        echo -e "${GREEN}✅ Supabase CLI ile kurulum tamamlandı!${NC}"
        ;;
        
    *)
        echo -e "${RED}Geçersiz seçim / Invalid choice${NC}"
        exit 1
        ;;
esac

# ==============================================================================
# Doğrulama / Verification
# ==============================================================================

echo ""
echo -e "${CYAN}=============================================${NC}"
echo -e "${CYAN}  DOĞRULAMA / VERIFICATION${NC}"
echo -e "${CYAN}=============================================${NC}"
echo ""

echo -e "${YELLOW}Tabloları kontrol ediliyor / Checking tables...${NC}"
psql "$DB_URL" -c "
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
" 2>/dev/null || echo -e "${RED}Tablo listesi alınamadı${NC}"

echo ""
echo -e "${YELLOW}RPC fonksiyonlarını kontrol ediliyor / Checking RPC functions...${NC}"
psql "$DB_URL" -c "
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION'
ORDER BY routine_name
LIMIT 10;
" 2>/dev/null || echo -e "${RED}Fonksiyon listesi alınamadı${NC}"

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}  İŞLEM TAMAMLANDI / PROCESS COMPLETE${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo -e "${BLUE}Sonraki adımlar / Next steps:${NC}"
echo -e "  1. Oyunu çalıştırın ve bağlantıyı test edin"
echo -e "     Run the game and test the connection"
echo -e "  2. Oyun içi verileri kontrol edin"
echo -e "     Check in-game data"
echo -e "  3. Herhangi bir sorun varsa VERITABANI_KURULUM_KILAVUZU.md dosyasına bakın"
echo -e "     If any issues, refer to VERITABANI_KURULUM_KILAVUZU.md"
echo ""
