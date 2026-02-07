# ==============================================================================
# Veritabanı Kurtarma Scripti - Gölge Krallık
# Database Restoration Script - PowerShell
# ==============================================================================
# Bu script, silinen veritabanını parça parça SQL dosyalarından geri yükler.
# This script restores the deleted database from scattered SQL files.
# ==============================================================================

param(
    [string]$DbPassword = "",
    [int]$Method = 0
)

# Renkli çıktı için fonksiyonlar
function Write-Header {
    param([string]$Text)
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Text)
    Write-Host $Text -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Text)
    Write-Host "✅ $Text" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Text)
    Write-Host "❌ $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "▶ $Text" -ForegroundColor Blue
}

# Başlık
Write-Header "VERİTABANI KURTARMA SİSTEMİ`nDatabase Restoration System"

# Yapılandırma
$ProjectRef = "znvsyzstmxhqvdkkmgdt"
$DbHost = "db.$ProjectRef.supabase.co"
$DbPort = "5432"
$DbName = "postgres"
$DbUser = "postgres"

Write-Step "Yapılandırma / Configuration:"
Write-Host "  Proje ID: " -NoNewline
Write-Host $ProjectRef -ForegroundColor Green
Write-Host "  Veritabanı: " -NoNewline
Write-Host $DbHost -ForegroundColor Green
Write-Host ""

# Şifre kontrolü
if ([string]::IsNullOrEmpty($DbPassword)) {
    $SecurePassword = Read-Host "Lütfen veritabanı şifresini girin / Please enter database password" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $DbPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

# Bağlantı string'i
$DbUrl = "postgresql://${DbUser}:${DbPassword}@${DbHost}:${DbPort}/${DbName}"

# SQL dosyası çalıştırma fonksiyonu
function Invoke-SqlFile {
    param(
        [string]$FilePath,
        [string]$Description
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Error-Custom "Dosya bulunamadı / File not found: $FilePath"
        return $false
    }
    
    Write-Info "Çalıştırılıyor / Executing: $Description"
    Write-Host "  Dosya / File: $FilePath" -ForegroundColor Blue
    
    try {
        # psql komutu kullan
        $env:PGPASSWORD = $DbPassword
        $result = & psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -f $FilePath 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Başarılı / Success"
            Write-Host ""
            return $true
        } else {
            Write-Error-Custom "Hata / Error"
            Write-Host $result -ForegroundColor Red
            
            $continue = Read-Host "Devam edilsin mi? (E/H) Continue? (Y/N)"
            if ($continue -match '^[eEyY]$') {
                return $true
            }
            return $false
        }
    } catch {
        Write-Error-Custom "Çalıştırma hatası / Execution error: $_"
        
        $continue = Read-Host "Devam edilsin mi? (E/H) Continue? (Y/N)"
        if ($continue -match '^[eEyY]$') {
            return $true
        }
        return $false
    }
}

# Bağlantı testi
function Test-DatabaseConnection {
    Write-Step "Bağlantı test ediliyor / Testing connection..."
    
    try {
        $env:PGPASSWORD = $DbPassword
        $result = & psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -c "SELECT version();" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Bağlantı başarılı / Connection successful"
            Write-Host ""
            return $true
        } else {
            Write-Error-Custom "Bağlantı başarısız / Connection failed"
            Write-Host $result -ForegroundColor Red
            Write-Host "Lütfen şifrenizi ve bağlantı bilgilerinizi kontrol edin." -ForegroundColor Red
            Write-Host "Please check your password and connection details." -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Error-Custom "Bağlantı hatası / Connection error: $_"
        return $false
    }
}

# psql kontrol et
$psqlExists = Get-Command psql -ErrorAction SilentlyContinue
if (-not $psqlExists) {
    Write-Error-Custom "psql bulunamadı! PostgreSQL Client yüklü değil."
    Write-Host ""
    Write-Host "Alternatif yöntemler:" -ForegroundColor Yellow
    Write-Host "1. Supabase Dashboard kullanın: https://app.supabase.com/project/$ProjectRef/sql" -ForegroundColor Cyan
    Write-Host "2. PostgreSQL Client yükleyin: https://www.postgresql.org/download/" -ForegroundColor Cyan
    Write-Host "3. Supabase CLI kullanın: npm install -g supabase" -ForegroundColor Cyan
    exit 1
}

# Yöntem seçimi
if ($Method -eq 0) {
    Write-Host "Kurulum yöntemi seçin / Choose installation method:" -ForegroundColor Blue
    Write-Host ""
    Write-Host "1) Otomatik - Tüm dosyaları sırayla çalıştır (Önerilen)"
    Write-Host "   Automatic - Run all files in order (Recommended)"
    Write-Host ""
    Write-Host "2) Manuel - Sadece temel şema dosyalarını çalıştır"
    Write-Host "   Manual - Run only core schema files"
    Write-Host ""
    Write-Host "3) Özel - Belirli bir dosyayı çalıştır"
    Write-Host "   Custom - Run a specific file"
    Write-Host ""
    Write-Host "4) Supabase CLI kullan"
    Write-Host "   Use Supabase CLI"
    Write-Host ""
    $Method = Read-Host "Seçiminiz (1-4)"
}

switch ($Method) {
    1 {
        Write-Host ""
        Write-Header "OTOMATİK KURULUM BAŞLIYOR`nStarting Automatic Installation"
        
        if (-not (Test-DatabaseConnection)) {
            exit 1
        }
        
        Write-Step "FAZ 1: Temel Altyapı / Core Infrastructure"
        Write-Host ""
        Invoke-SqlFile "supabase\sql\01_create_inventory_table.sql" "Envanter Tablosu / Inventory Table"
        Invoke-SqlFile "supabase\sql\02_normalize_and_rpc.sql" "Normalizasyon / Normalization"
        Invoke-SqlFile "supabase\sql\03_equipment_system.sql" "Ekipman Sistemi / Equipment System"
        Invoke-SqlFile "supabase\sql\04_slot_position_rpcs.sql" "Slot Fonksiyonları / Slot Functions"
        Invoke-SqlFile "supabase\sql\hospital_functions.sql" "Hastane Fonksiyonları / Hospital Functions"
        
        Write-Host ""
        Write-Step "FAZ 2: Sistem Düzeltmeleri / System Fixes"
        Write-Host ""
        Invoke-SqlFile "database\migrations\00_MASTER_FIX_ALL.sql" "Ana Düzeltme / Master Fix"
        
        Write-Host ""
        Write-Step "FAZ 3: Ana Sistemler / Main Systems"
        Write-Host ""
        
        # Tesisler için hangisinin daha yeni olduğunu kontrol et
        if (Test-Path "database\migrations\20260130201441_facilities_system.sql") {
            Invoke-SqlFile "database\migrations\20260130201441_facilities_system.sql" "Tesis Sistemi / Facilities System"
        } else {
            Invoke-SqlFile "database\migrations\create_facilities_system.sql" "Tesis Sistemi / Facilities System"
        }
        
        Invoke-SqlFile "database\migrations\create_prison_system.sql" "Hapishane Sistemi / Prison System"
        Invoke-SqlFile "database\migrations\create_market_system.sql" "Pazar Sistemi / Market System"
        
        Write-Host ""
        Write-Step "FAZ 4: RPC Fonksiyonları / RPC Functions"
        Write-Host ""
        Invoke-SqlFile "database\migrations\create_collect_rpc_v2.sql" "Toplama RPC / Collect RPC"
        Invoke-SqlFile "database\migrations\create_get_player_facilities_rpc.sql" "Oyuncu Tesisleri RPC"
        Invoke-SqlFile "database\migrations\create_get_facility_recipes_rpc.sql" "Tesis Tarifleri RPC"
        Invoke-SqlFile "database\migrations\create_upgrade_facility_rpc.sql" "Tesis Yükseltme RPC"
        Invoke-SqlFile "database\migrations\create_purchase_listing_rpc.sql" "Satın Alma RPC"
        Invoke-SqlFile "database\migrations\add_collect_facility_resources_rpc.sql" "Kaynak Toplama RPC"
        
        Write-Host ""
        Write-Step "FAZ 5: Öğeler ve Veriler / Items and Data"
        Write-Host ""
        Invoke-SqlFile "database\migrations\add_all_resource_items.sql" "Kaynak Öğeleri / Resource Items"
        Invoke-SqlFile "database\migrations\add_craftable_items.sql" "Üretilebilir Öğeler / Craftable Items"
        Invoke-SqlFile "database\migrations\add_crafting_recipes.sql" "Üretim Tarifleri / Crafting Recipes"
        Invoke-SqlFile "database\migrations\insert_facility_items.sql" "Tesis Öğeleri / Facility Items"
        Invoke-SqlFile "database\migrations\seed_facility_recipes_complete.sql" "Tesis Tarifleri / Facility Recipes"
        Invoke-SqlFile "database\migrations\add_15_resource_facilities.sql" "15 Kaynak Tesisi / 15 Resource Facilities"
        
        Write-Host ""
        Write-Header "KURULUM TAMAMLANDI!`nInstallation Complete!"
    }
    
    2 {
        Write-Host ""
        Write-Host "Manuel kurulum - Temel şema dosyaları" -ForegroundColor Cyan
        Write-Host ""
        
        if (-not (Test-DatabaseConnection)) {
            exit 1
        }
        
        Invoke-SqlFile "supabase\sql\01_create_inventory_table.sql" "Envanter Tablosu"
        Invoke-SqlFile "supabase\sql\02_normalize_and_rpc.sql" "Normalizasyon"
        Invoke-SqlFile "supabase\sql\03_equipment_system.sql" "Ekipman Sistemi"
        Invoke-SqlFile "supabase\sql\04_slot_position_rpcs.sql" "Slot Fonksiyonları"
        Invoke-SqlFile "supabase\sql\hospital_functions.sql" "Hastane Fonksiyonları"
        
        Write-Success "Temel şema kurulumu tamamlandı!"
        Write-Step "Diğer dosyalar için lütfen kılavuza bakın: VERITABANI_KURULUM_KILAVUZU.md"
    }
    
    3 {
        Write-Host ""
        $SqlFile = Read-Host "Lütfen SQL dosyasının yolunu girin"
        
        if (-not (Test-DatabaseConnection)) {
            exit 1
        }
        
        Invoke-SqlFile $SqlFile "Özel Dosya"
    }
    
    4 {
        Write-Host ""
        Write-Host "Supabase CLI kullanımı" -ForegroundColor Cyan
        Write-Host ""
        
        # Supabase CLI kontrol et
        $supabaseCli = Get-Command supabase -ErrorAction SilentlyContinue
        if (-not $supabaseCli) {
            Write-Error-Custom "Supabase CLI bulunamadı!"
            Write-Step "Kurulum için: npm install -g supabase"
            exit 1
        }
        
        Write-Step "Projeye bağlanılıyor..."
        supabase link --project-ref $ProjectRef
        
        Write-Host ""
        Write-Step "Migrasyonlar gönderiliyor..."
        supabase db push
        
        Write-Host ""
        Write-Success "Supabase CLI ile kurulum tamamlandı!"
    }
    
    default {
        Write-Error-Custom "Geçersiz seçim / Invalid choice"
        exit 1
    }
}

# Doğrulama
Write-Host ""
Write-Header "DOĞRULAMA / VERIFICATION"

Write-Step "Tabloları kontrol ediliyor / Checking tables..."
$env:PGPASSWORD = $DbPassword
& psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -c @"
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
"@

Write-Host ""
Write-Step "RPC fonksiyonlarını kontrol ediliyor / Checking RPC functions..."
& psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -c @"
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION'
ORDER BY routine_name
LIMIT 10;
"@

Write-Host ""
Write-Header "İŞLEM TAMAMLANDI / PROCESS COMPLETE"

Write-Host "Sonraki adımlar / Next steps:" -ForegroundColor Blue
Write-Host "  1. Oyunu çalıştırın ve bağlantıyı test edin"
Write-Host "     Run the game and test the connection"
Write-Host "  2. Oyun içi verileri kontrol edin"
Write-Host "     Check in-game data"
Write-Host "  3. Herhangi bir sorun varsa VERITABANI_KURULUM_KILAVUZU.md dosyasına bakın"
Write-Host "     If any issues, refer to VERITABANI_KURULUM_KILAVUZU.md"
Write-Host ""
