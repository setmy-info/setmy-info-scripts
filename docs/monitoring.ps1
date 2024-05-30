while ($true) {
    Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 10 | Export-Csv -Append -Path "C:\pub\setmy.info\logs\logs3.csv" -NoTypeInformation
    Start-Sleep -Seconds 180 # Oodake 5 minutit
}
