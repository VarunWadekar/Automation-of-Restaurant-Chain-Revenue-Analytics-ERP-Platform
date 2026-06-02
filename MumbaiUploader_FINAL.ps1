# MUMBAI UPLOADER - FINAL VERSION
Write-Host "Running SQL..." (Get-Date).ToString("HH:mm:ss")

sqlcmd -S $$$ -d POSGoldQFile -U $$$ -P "$$$$" `
    -i "D:\VARUN\MUMBAI.sql" `
    -o "D:\VARUN\FNB_ReportMUMBAI.csv" `
    -s "|" -W -h-1 -w 65535

Write-Host "SQL done." (Get-Date).ToString("HH:mm:ss")

Write-Host "Reading CSV..." (Get-Date).ToString("HH:mm:ss")

$headers = @("POSDescription","BillNo","BillCode","Created Date","Created Time","MenuItemCode","ItemDescription","IncomeHeadDescription","MenuGroupDescription","Quantity","Rate","Cost","Discount","DiscountRemark","NetAmount","ItemTotalTax","Gross_Amount","PaymentDescription","PAX","tableNo","CustMobileNoForBill","CustNameForBill")

$badChars = New-Object System.Text.RegularExpressions.Regex('[\x00-\x08\x0B\x0C\x0E-\x1F\x7F\r\n\t]')
$data = New-Object System.Collections.ArrayList

Import-Csv "D:\VARUN\FNB_ReportMUMBAI.csv" -Header $headers -Delimiter "|" | Where-Object { $_.BillNo -and $_.BillNo.Trim() -ne "" } | ForEach-Object {
    [void]$data.Add([ordered]@{
        POSDescription = $badChars.Replace($_.POSDescription.Trim().Replace('"',"'"), '')
        BillNo = $badChars.Replace($_.BillNo.Trim().Replace('"',"'"), '')
        BillCode = $badChars.Replace($_.BillCode.Trim().Replace('"',"'"), '')
        "Created Date" = $badChars.Replace($_."Created Date".Trim().Replace('"',"'"), '')
        "Created Time" = $badChars.Replace($_."Created Time".Trim().Replace('"',"'"), '')
        MenuItemCode = $badChars.Replace($_.MenuItemCode.Trim().Replace('"',"'"), '')
        ItemDescription = $badChars.Replace($_.ItemDescription.Trim().Replace('"',"'"), '')
        IncomeHeadDescription = $badChars.Replace($_.IncomeHeadDescription.Trim().Replace('"',"'"), '')
        MenuGroupDescription = $badChars.Replace($_.MenuGroupDescription.Trim().Replace('"',"'"), '')
        Quantity = $badChars.Replace($_.Quantity.Trim().Replace('"',"'"), '')
        Rate = $badChars.Replace($_.Rate.Trim().Replace('"',"'"), '')
        Cost = $badChars.Replace($_.Cost.Trim().Replace('"',"'"), '')
        Discount = $badChars.Replace($_.Discount.Trim().Replace('"',"'"), '')
        DiscountRemark = $badChars.Replace($_.DiscountRemark.Trim().Replace('"',"'"), '')
        NetAmount = $badChars.Replace($_.NetAmount.Trim().Replace('"',"'"), '')
        ItemTotalTax = $badChars.Replace($_.ItemTotalTax.Trim().Replace('"',"'"), '')
        Gross_Amount = $badChars.Replace($_.Gross_Amount.Trim().Replace('"',"'"), '')
        PaymentDescription = $badChars.Replace($_.PaymentDescription.Trim().Replace('"',"'"), '')
        PAX = $badChars.Replace($_.PAX.Trim().Replace('"',"'"), '')
        tableNo = $badChars.Replace($_.tableNo.Trim().Replace('"',"'"), '')
        CustMobileNoForBill = $badChars.Replace($_.CustMobileNoForBill.Trim().Replace('"',"'"), '')
        CustNameForBill = $badChars.Replace($_.CustNameForBill.Trim().Replace('"',"'"), '')
    })
}

Write-Host "Rows loaded: $($data.Count)" (Get-Date).ToString("HH:mm:ss")

$uri = "https://script.google.com/macros/s/AKfycbwg$$$$"
$batchSize = 1500
$total = $data.Count
$chunks = @()

Write-Host "Building batches..." (Get-Date).ToString("HH:mm:ss")

for ($i = 0; $i -lt $total; $i += $batchSize) {
    $end = [Math]::Min($i + $batchSize - 1, $total - 1)
    $chunks += @{
        startRow = $i
        endRow = $end
    }
}

Write-Host "Starting upload..." (Get-Date).ToString("HH:mm:ss")

$failedChunks = @()

foreach ($chunk in $chunks) {
    $success = $false
    $attempt = 0

    $isFirst = ($chunk.startRow -eq 0)

    $json = @{
        tab = "MUMBAI"
        isFirst = $isFirst
        data = $data[$chunk.startRow..$chunk.endRow]
    } | ConvertTo-Json -Depth 3 -Compress

    while (-not $success -and $attempt -lt 3) {
        $attempt++
        try {
            Invoke-RestMethod `
                -Uri $uri `
                -Method Post `
                -Body $json `
                -ContentType "application/json" `
                -TimeoutSec 180 | Out-Null

            Write-Host ("OK   rows " + $chunk.startRow + "-" + $chunk.endRow + "  [attempt " + $attempt + "]  " + (Get-Date -Format 'HH:mm:ss'))
            $success = $true

        } catch {
            Write-Host ("WAIT rows " + $chunk.startRow + "-" + $chunk.endRow + "  [attempt " + $attempt + " - retrying]")
            Start-Sleep -Seconds 5
        }
    }

    if (-not $success) {
        Write-Host ("FAIL rows " + $chunk.startRow + "-" + $chunk.endRow)
        $failedChunks += $chunk
    }

    Start-Sleep -Milliseconds 500
}

Write-Host ""
if ($failedChunks.Count -gt 0) {
    Write-Host ("WARNING: " + $failedChunks.Count + " batches failed")
} else {
    Write-Host ("Success: All " + $chunks.Count + " batches uploaded - " + $total + " rows total")
}

Write-Host "MUMBAI upload completed." (Get-Date).ToString("HH:mm:ss")
Exit