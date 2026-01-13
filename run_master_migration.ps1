# Master Migration Runner
# This script applies the master fix to Supabase

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "INVENTORY & EQUIPMENT SYSTEM MASTER FIX" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if supabase CLI is available
if (-not (Get-Command "supabase" -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Supabase CLI not found!" -ForegroundColor Red
    Write-Host "Please install it from: https://supabase.com/docs/guides/cli" -ForegroundColor Yellow
    exit 1
}

Write-Host "Step 1: Linking to Supabase project..." -ForegroundColor Yellow
try {
    $linkResult = supabase link --project-ref your-project-ref 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Warning: Link may have failed, continuing..." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Warning: Could not link project, continuing..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 2: Applying master migration..." -ForegroundColor Yellow
Write-Host "Running: database/migrations/00_MASTER_FIX_ALL.sql" -ForegroundColor Gray
Write-Host ""

try {
    $result = supabase db execute -f "database\migrations\00_MASTER_FIX_ALL.sql" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Master migration applied!" -ForegroundColor Green
        Write-Host $result
    } else {
        Write-Host "ERROR: Migration failed!" -ForegroundColor Red
        Write-Host $result
        Write-Host ""
        Write-Host "Alternative: Apply via Supabase Dashboard SQL Editor" -ForegroundColor Yellow
        Write-Host "1. Go to https://app.supabase.com/project/_/sql" -ForegroundColor Cyan
        Write-Host "2. Copy contents of: database\migrations\00_MASTER_FIX_ALL.sql" -ForegroundColor Cyan
        Write-Host "3. Paste and run in SQL Editor" -ForegroundColor Cyan
        exit 1
    }
} catch {
    Write-Host "ERROR: Could not execute migration!" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Alternative: Apply via Supabase Dashboard SQL Editor" -ForegroundColor Yellow
    Write-Host "1. Go to https://app.supabase.com/project/_/sql" -ForegroundColor Cyan
    Write-Host "2. Copy contents of: database\migrations\00_MASTER_FIX_ALL.sql" -ForegroundColor Cyan
    Write-Host "3. Paste and run in SQL Editor" -ForegroundColor Cyan
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MIGRATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Client-side fixes are ready" -ForegroundColor White
Write-Host "2. Test the inventory system in game" -ForegroundColor White
Write-Host "3. Verify no ghost items appear" -ForegroundColor White
Write-Host ""
