#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Load test script to trigger KEDA autoscaling on Azure Container Apps
.DESCRIPTION
    Sends concurrent HTTP requests to demonstrate KEDA HTTP scaling
.PARAMETER Url
    The base URL of the Container App (without trailing slash)
.PARAMETER Endpoint
    The endpoint to test (default: /api/load)
.PARAMETER Duration
    How long each request should simulate work (in milliseconds)
.PARAMETER Concurrent
    Number of concurrent requests to send
.PARAMETER TotalRequests
    Total number of requests to send
.EXAMPLE
    .\load-test.ps1 -Url "https://tdc25-api-node.xxx.eastus.azurecontainerapps.io" -Concurrent 50 -TotalRequests 500
#>

Param(
    [Parameter(Mandatory=$true)]
    [string]$Url,
    
    [Parameter(Mandatory=$false)]
    [string]$Endpoint = "/api/load",
    
    [Parameter(Mandatory=$false)]
    [int]$Duration = 200,
    
    [Parameter(Mandatory=$false)]
    [int]$Concurrent = 30,
    
    [Parameter(Mandatory=$false)]
    [int]$TotalRequests = 300
)

Write-Host "🚀 Starting KEDA Autoscaling Load Test" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Target: $Url$Endpoint" -ForegroundColor Yellow
Write-Host "Concurrent requests: $Concurrent" -ForegroundColor Yellow
Write-Host "Total requests: $TotalRequests" -ForegroundColor Yellow
Write-Host "Duration per request: ${Duration}ms" -ForegroundColor Yellow
Write-Host ""

$testUrl = "$Url$Endpoint`?duration=$Duration"
$jobs = @()
$requestCount = 0
$successCount = 0
$failCount = 0
$startTime = Get-Date

Write-Host "⏱️  Monitor scaling in real-time:" -ForegroundColor Green
Write-Host "   az containerapp replica list --name tdc25-api-node --resource-group tdc25-demo-rg -o table" -ForegroundColor Gray
Write-Host ""

# Send requests in batches
for ($i = 0; $i -lt $TotalRequests; $i += $Concurrent) {
    $batch = [Math]::Min($Concurrent, $TotalRequests - $i)
    $batchNum = [Math]::Floor($i / $Concurrent) + 1
    
    Write-Host "📨 Batch $batchNum - Sending $batch concurrent requests..." -ForegroundColor Cyan
    
    for ($j = 0; $j -lt $batch; $j++) {
        $jobs += Start-Job -ScriptBlock {
            param($url)
            try {
                $response = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 30
                return @{ Success = $true; StatusCode = $response.StatusCode }
            } catch {
                return @{ Success = $false; Error = $_.Exception.Message }
            }
        } -ArgumentList $testUrl
        $requestCount++
    }
    
    # Wait a bit between batches to maintain sustained load
    if ($i + $Concurrent -lt $TotalRequests) {
        Start-Sleep -Milliseconds 500
    }
}

Write-Host "⏳ Waiting for all requests to complete..." -ForegroundColor Yellow
Write-Host ""

# Wait for all jobs and collect results
$completedCount = 0
$jobs | ForEach-Object {
    $result = Receive-Job -Job $_ -Wait
    $completedCount++
    
    if ($result.Success) {
        $successCount++
    } else {
        $failCount++
    }
    
    # Show progress every 20 requests
    if ($completedCount % 20 -eq 0) {
        Write-Host "  ✓ $completedCount/$requestCount requests completed..." -ForegroundColor Gray
    }
    
    Remove-Job -Job $_
}

$endTime = Get-Date
$totalDuration = ($endTime - $startTime).TotalSeconds

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Load Test Completed!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Total requests: $requestCount" -ForegroundColor White
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
Write-Host "Total duration: $([Math]::Round($totalDuration, 2))s" -ForegroundColor White
Write-Host "Requests/sec: $([Math]::Round($requestCount / $totalDuration, 2))" -ForegroundColor White
Write-Host ""
Write-Host "📊 Check scaling results:" -ForegroundColor Cyan
Write-Host "   az containerapp replica list --name tdc25-api-node --resource-group tdc25-demo-rg -o table" -ForegroundColor Yellow
Write-Host ""
Write-Host "💡 View metrics in Azure Portal:" -ForegroundColor Cyan
Write-Host "   Portal > Container Apps > tdc25-api-node > Metrics > Replica Count" -ForegroundColor Gray
