# ============================================================
#  Hyper-V Duplicate UUID Checker
#  Auto-assigns hostname from the current machine
# ============================================================

$computername = $env:COMPUTERNAME
$outputCsv    = "C:\Temp\$computername-uuids.csv"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Hyper-V UUID Checker" -ForegroundColor Cyan
Write-Host "  Target Host : $computername" -ForegroundColor Cyan
Write-Host "  Output CSV  : $outputCsv" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Ensure output directory exists
if (-not (Test-Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp" | Out-Null
}

# ------------------------------------------------------------
# COMMAND 1 — Raw query: all VM setting data
# ------------------------------------------------------------
Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "COMMAND 1: Raw WMI Query — ElementName, VirtualSystemIdentifier, BIOSSerialNumber" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
Write-Host ""

$allVMs = Get-WmiObject `
    -Query "SELECT ElementName, VirtualSystemIdentifier, BIOSSerialNumber FROM Msvm_VirtualSystemSettingData" `
    -Namespace 'root/Virtualization/V2' `
    -ComputerName $computername

$allVMs | Select-Object ElementName, VirtualSystemIdentifier, BIOSSerialNumber | Format-Table -AutoSize

Write-Host ""

# ------------------------------------------------------------
# COMMAND 2 — Export to CSV
# ------------------------------------------------------------
Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "COMMAND 2: Export to CSV -> $outputCsv" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
Write-Host ""

$allVMs |
    Select-Object ElementName, VirtualSystemIdentifier, BIOSSerialNumber |
    Export-Csv -Path $outputCsv -NoTypeInformation

if (Test-Path $outputCsv) {
    Write-Host "  [OK] CSV exported successfully: $outputCsv" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Preview (first 10 rows):" -ForegroundColor Gray
    Import-Csv $outputCsv | Select-Object -First 10 | Format-Table -AutoSize
} else {
    Write-Host "  [WARN] CSV file was not created." -ForegroundColor Red
}

Write-Host ""

# ------------------------------------------------------------
# COMMAND 3 — Duplicate BIOSSerialNumber detection
# ------------------------------------------------------------
Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "COMMAND 3: Duplicate BIOSSerialNumber Detection" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
Write-Host ""

$vms = Get-WmiObject `
    -Query "SELECT ElementName, BIOSSerialNumber FROM Msvm_VirtualSystemSettingData" `
    -Namespace 'root/Virtualization/V2' `
    -ComputerName $computername

$duplicates = $vms |
    Group-Object BIOSSerialNumber |
    Where-Object { $_.Count -gt 1 } |
    Select-Object Name, Count, @{N='VMs'; E={ ($_.Group.ElementName -join ', ') }}

if ($duplicates) {
    Write-Host "  [!!] DUPLICATE BIOSSerialNumbers FOUND:" -ForegroundColor Red
    Write-Host ""
    $duplicates | Format-Table -AutoSize
} else {
    Write-Host "  [OK] No duplicate BIOSSerialNumbers found." -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  All 3 commands completed. Target: $computername" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
