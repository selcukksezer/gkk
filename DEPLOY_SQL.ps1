#!/usr/bin/env pwsh

# Deploy SQL Migration via Supabase REST API

$projectId = "znvsyzstmxhqvdkkmgdt"
$apiUrl = "https://$projectId.supabase.co"

# Read SQL file
$sqlFile = "database/migrations/20260130201441_facilities_system.sql"
$sqlContent = Get-Content $sqlFile -Raw

Write-Host "📊 SQL Migration Details:"
Write-Host "  File: $sqlFile"
Write-Host "  Size: $($sqlContent.Length) bytes"
Write-Host ""

# Get Supabase credentials from config
Write-Host "⚠️  This requires database credentials!"
Write-Host "Run this in your Godot project or Supabase Console:"
Write-Host ""
Write-Host "Option 1: Use Supabase Dashboard"
Write-Host "  1. Open: https://app.supabase.com/projects/$projectId/sql/new"
Write-Host "  2. Copy entire content from: $sqlFile"
Write-Host "  3. Paste into SQL Editor"
Write-Host "  4. Click 'Run'"
Write-Host ""
Write-Host "Option 2: Use psql CLI"
Write-Host "  psql 'postgresql://postgres:PASSWORD@db.$projectId.supabase.co:5432/postgres' -f $sqlFile"
Write-Host ""
Write-Host "Option 3: Use Supabase CLI with included schema"
Write-Host "  supabase db push --linked --yes"
