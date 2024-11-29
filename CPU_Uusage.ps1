# Set thresholds for CPU and memory usage
$CPU_Threshold = 1
$Memory_Threshold = 90

# Set log file path
$LogFilePath = "C:\Logs\SystemStatusLog.txt"

# Email configuration
$SMTPServer = "smtp.gmail.com"
$SMTPPort = 587
$FromEmail = "ashudadwal1998@gmail.com"
$ToEmail = "ashudadwal15@gmail.com"
$EmailSubject = "System Alert: Resource Threshold Exceeded"
$Password = "vcsp lyqq cpvl trvo"  # Use your App Password if 2FA is enabled
$Credential = New-Object PSCredential($FromEmail, (ConvertTo-SecureString $Password -AsPlainText -Force))

# Ensure the log file directory exists
if (-not (Test-Path (Split-Path $LogFilePath))) {
    New-Item -ItemType Directory -Path (Split-Path $LogFilePath) -Force
}

# Add a header to the log file if it doesn't exist
if (-not (Test-Path $LogFilePath)) {
    "System Monitoring Log - $(Get-Date)" | Out-File -FilePath $LogFilePath -Append
}

# Infinite loop to continuously monitor CPU and memory usage
while ($true) {
    # Timestamp for log entry
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Initialize Email Body
    $EmailBody = "This is the email for CPU and memory usage. Below are the following information
    "

    # Monitor CPU usage
    $CPU_Average = Get-CimInstance Win32_Processor | 
                   Measure-Object -Property LoadPercentage -Average | 
                   Select-Object -ExpandProperty Average

    if ($CPU_Average -gt $CPU_Threshold) {
        $CPU_Status = "ALERT: CPU usage exceeds $CPU_Threshold%! Current CPU usage: $CPU_Average%"
        Write-Host $CPU_Status -ForegroundColor Red
        $EmailBody += "$Timestamp - $CPU_Status`n"
    } else {
        $CPU_Status = "CPU usage is normal. Current CPU usage: $CPU_Average%"
        Write-Host $CPU_Status -ForegroundColor Green
    }

    # Monitor memory usage
    $MemoryInfo = Get-CimInstance Win32_OperatingSystem
    $TotalMemory = $MemoryInfo.TotalVisibleMemorySize / 1MB  # Convert KB to GB
    $FreeMemory = $MemoryInfo.FreePhysicalMemory / 1MB       # Convert KB to GB
    $UsedMemoryPercentage = (($TotalMemory - $FreeMemory) / $TotalMemory) * 100

    if ($UsedMemoryPercentage -gt $Memory_Threshold) {
        $Memory_Status = "ALERT: Memory usage is high! Used: $([math]::Round($UsedMemoryPercentage, 2))%"
        Write-Host $Memory_Status -ForegroundColor Red
        $EmailBody += "$Timestamp - $Memory_Status`n"
    } else {
        $Memory_Status = "Memory usage is normal. Used: $([math]::Round($UsedMemoryPercentage, 2))%"
        Write-Host $Memory_Status -ForegroundColor Green
    }

    # Log the statuses to the log file
    "$Timestamp - $CPU_Status" | Out-File -FilePath $LogFilePath -Append
    "$Timestamp - $Memory_Status" | Out-File -FilePath $LogFilePath -Append

    # Send email if alerts were generated
    if ($EmailBody) {
        try {
            Send-MailMessage -From $FromEmail -To $ToEmail -Subject $EmailSubject -Body $EmailBody -SmtpServer $SMTPServer -Port $SMTPPort -UseSsl -Credential $Credential
            Write-Host "Alert email sent successfully." -ForegroundColor Cyan
        } catch {
            Write-Host "Failed to send email alert: $_" -ForegroundColor Yellow
        }
    }

    # Wait for 10 seconds before checking again
    Start-Sleep -Seconds 10
}
