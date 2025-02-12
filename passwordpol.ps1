function Show-PasswordPolicyPopup {
    $message = @"
Your password must meet the following requirements:
- Contain a year when Dune 1 or 2 (book or movie) was released (e.g., 2021, 2024, 1965, 1969).
- Include a location from the Dune universe (e.g., Arrakis, Arrakeen, Bandalong).
- Contain the name of the author of Dune (e.g., Frank Herbert).
"@
    
    [System.Windows.MessageBox]::Show($message, "Password Policy Requirement", "OK", "Error")
}

function Test-PasswordRules {
    param (
        [Parameter(Mandatory = $true)]
        [SecureString]$NewPassword
    )
    
    $BookMovieDates = @("2021", "2024", "1965", "1969")
    $AuthorNames = @("Frank", "frank", "Herbert", "herbert", "FrankHerbert", "frankherbert")
    $DuneLocations = @("Arrakis", "Arrakeen", "Bandalong", "Barony", "Cala", "Dimitri", "Harko", "Niubbe", "Starda")
    
    $HasDate = $BookMovieDates | Where-Object { $NewPassword -match $_ }
    $HasLocation = $DuneLocations | Where-Object { $NewPassword -match $_ }
    $HasAuthor = $AuthorNames | Where-Object { $NewPassword -match $_ }
    
    if (-not ($HasDate -and $HasLocation -and $HasAuthor)) {
        Show-PasswordPolicyPopup
        return $false
    }
    return $true
}

function Watch-PasswordChanges {
    Write-Host "[*] Monitoring password changes..."
    while ($true) {
        Start-Sleep -Seconds 10
        $Events = Get-WinEvent -LogName "Security" -FilterXPath "*[System[(EventID=4723 or EventID=4724)]]" | Sort-Object TimeCreated -Descending | Select-Object -First 5
        foreach ($Event in $Events) {
            $NewPassword = "PLACEHOLDER"  # Modify this for deeper integration with actual password retrieval
            if (-not (Test-PasswordRules -NewPassword $NewPassword)) {
                Write-Host "[!] Password policy violated. Displaying pop-up."
            }
        }
    }
}

function Set-RegistryPersistence {
    Write-Host "[*] Adding registry persistence..."
    $scriptPath = "C:\Windows\System32\passwordpol.ps1"
    Copy-Item $MyInvocation.MyCommand.Path -Destination $scriptPath -Force
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" `
                     -Name "StrictPasswordEnforcer" `
                     -Value "powershell -ExecutionPolicy Bypass -File $scriptPath" -Force
    Write-Host "[+] Persistence added via registry."
}

function Set-ScheduledTaskPersistence {
    Write-Host "[*] Creating scheduled task for persistence..."
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Windows\System32\passwordpol.ps1"
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName "StrictPasswordEnforcer" -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal -Settings $taskSettings -Force
    Write-Host "[+] Persistence added via scheduled task."
}

Set-RegistryPersistence
Set-ScheduledTaskPersistence
Start-Job -ScriptBlock { Monitor-PasswordChanges }
