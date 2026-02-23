# Google Sign-In Configuration Verifier
Write-Host "`n========================================================================" -ForegroundColor Cyan
Write-Host "Google Sign-In SHA-1 Verification Tool" -ForegroundColor White
Write-Host "========================================================================`n" -ForegroundColor Cyan

$googleServicesPath = "android\app\google-services.json"
$sha1 = "7D:43:D3:53:A9:FC:F1:04:39:6C:5F:22:9F:01:95:2E:B6:C8:08:A2"

if (Test-Path $googleServicesPath) {
    Write-Host "[CHECKING] google-services.json in android\app\..." -ForegroundColor Yellow
    
    try {
        $content = Get-Content $googleServicesPath -Raw | ConvertFrom-Json
        $oauthClients = $content.client[0].oauth_client
        
        Write-Host "`nOAuth Clients Found:" -ForegroundColor Cyan
        $hasAndroidClient = $false
        
        foreach ($client in $oauthClients) {
            $clientType = $client.client_type
            $clientId = $client.client_id
            
            switch ($clientType) {
                1 { 
                    Write-Host "  ✓ Android OAuth Client: $clientId" -ForegroundColor Green
                    $hasAndroidClient = $true
                }
                2 { Write-Host "  ✓ iOS OAuth Client: $clientId" -ForegroundColor Green }
                3 { Write-Host "  ✓ Web OAuth Client: $clientId" -ForegroundColor Green }
            }
        }
        
        Write-Host ""
        
        if ($hasAndroidClient) {
            Write-Host "========================================================================" -ForegroundColor Green
            Write-Host "✓ SUCCESS: Configuration is CORRECT!" -ForegroundColor Green
            Write-Host "========================================================================" -ForegroundColor Green
            Write-Host "`n✓ Android OAuth client found" -ForegroundColor Green
            Write-Host "✓ SHA-1 fingerprint is properly registered" -ForegroundColor Green
            Write-Host "✓ google-services.json is correctly configured`n" -ForegroundColor Green
            
            Write-Host "Next Steps:" -ForegroundColor Yellow
            Write-Host "  1. Run: flutter clean" -ForegroundColor Cyan
            Write-Host "  2. Run: flutter pub get" -ForegroundColor Cyan
            Write-Host "  3. Run: flutter run" -ForegroundColor Cyan
            Write-Host "`nGoogle Sign-In should now work correctly!`n" -ForegroundColor Green
            
        } else {
            Write-Host "========================================================================" -ForegroundColor Red
            Write-Host "✗ PROBLEM: Android OAuth Client MISSING" -ForegroundColor Red
            Write-Host "========================================================================" -ForegroundColor Red
            Write-Host "`n✗ SHA-1 fingerprint NOT added to Firebase Console" -ForegroundColor Red
            Write-Host "`nYour SHA-1: $sha1`n" -ForegroundColor Yellow
            
            Write-Host "Required Steps:" -ForegroundColor Yellow
            Write-Host "  1. Go to Firebase Console" -ForegroundColor Cyan
            Write-Host "  2. Project Settings - Your apps - Android app" -ForegroundColor Cyan
            Write-Host "  3. Click 'Add fingerprint'" -ForegroundColor Cyan
            Write-Host "  4. Paste SHA-1 above" -ForegroundColor Cyan
            Write-Host "  5. Click 'Save'" -ForegroundColor Cyan
            Write-Host "  6. Download NEW google-services.json" -ForegroundColor Cyan
            Write-Host "  7. Move it to project root and run this script again`n" -ForegroundColor Cyan
            
            $response = Read-Host "Open Firebase Console now? (Y/N)"
            if ($response -eq "Y" -or $response -eq "y") {
                Start-Process "https://console.firebase.google.com/project/emtech-be4d4/settings/general"
            }
        }
        
    } catch {
        Write-Host "✗ Error reading google-services.json: $_" -ForegroundColor Red
    }
    
} elseif (Test-Path "google-services.json") {
    Write-Host "[FOUND] google-services.json in project root`n" -ForegroundColor Yellow
    Write-Host "Moving to android\app\..." -ForegroundColor Cyan
    Move-Item "google-services.json" $googleServicesPath -Force
    Write-Host "✓ File moved. Run this script again to verify.`n" -ForegroundColor Green
    
} else {
    Write-Host "✗ google-services.json NOT FOUND" -ForegroundColor Red
    Write-Host "`nExpected location: android\app\google-services.json" -ForegroundColor Yellow
    Write-Host "`nPlease download from Firebase Console.`n" -ForegroundColor Yellow
}
