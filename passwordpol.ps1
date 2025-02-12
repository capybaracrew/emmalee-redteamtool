# Enforce Strict Password Policy in Active Directory
function Set-StrictPasswordPolicy {
    Write-Host "[*] Applying strict password policies..."
    
    secedit /export /cfg C:\Windows\Temp\secpol.cfg
    (Get-Content C:\Windows\Temp\secpol.cfg) -replace "MinimumPasswordLength = .*", "MinimumPasswordLength = 15" `
                                              -replace "PasswordComplexity = .*", "PasswordComplexity = 1" `
                                              -replace "EnforcePasswordHistory = .*", "EnforcePasswordHistory = 24" `
                                              -replace "LockoutThreshold = .*", "LockoutThreshold = 5" | Set-Content C:\Windows\Temp\secpol.cfg
    secedit /configure /db C:\Windows\security\local.sdb /cfg C:\Windows\Temp\secpol.cfg /areas SECURITYPOLICY
    Remove-Item C:\Windows\Temp\secpol.cfg
    Write-Host "[+] Password policies enforced."
}
# Function to Enforce Custom Rules
function Test-PasswordRules {
    param (
        [Parameter(Mandatory = $true)]
        [SecureString]$NewPassword
    )
    # Convert SecureString to Plain Text (Only for Validation, Avoid Storing!)
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewPassword)
    $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $BookMovieDates = @("2021", "2024", "1965", "1969")
    $AuthorNames = @("Frank", "frank", "Herbert", "herbert", "FrankHerbert", "frankherbert")
    $DuneLocations = @("Arrakis", "Arrakeen", "Bandalong", "Barony", "Cala", "Dimitri", "Harko", "Niubbe", "Starda")
    $HasDate = $false
    $HasLocation = $false
    $HasAuthor = $false
    foreach ($Date in $BookMovieDates) {
        if ($PlainPassword -match $Date) { $HasDate = $true }
    }
    foreach ($Location in $DuneLocations) {
        if ($PlainPassword -match $Location) { $HasLocation = $true }
    }
    foreach ($Author in $AuthorNames) {
        if ($PlainPassword -match $Author) { $HasAuthor = $true }
    }
    if (-not ($HasDate -and $HasLocation -and $HasAuthor)) {
        Write-Host "[!] Password must contain: 
        - A year when Dune 1 or 2 (book or movie) was released.
        - A location from the Dune universe.
        - The name of the author of Dune."
        exit 1
    }
    Write-Host "[+] Password meets all complexity requirements!"
}
# Monitor Password Changes (Fake Hook)
function Watch-PasswordChanges {
    Write-Host "[*] Monitoring password changes..."
    while ($true) {
        Start-Sleep -Seconds 10
        $Users = Get-ADUser -Filter * -Properties PasswordLastSet | Sort-Object PasswordLastSet -Descending
        foreach ($User in $Users) {
            $TimeSinceLastChange = (Get-Date) - $User.PasswordLastSet
            if ($TimeSinceLastChange.TotalSeconds -lt 30) { # Recent password change
                Write-Host "[!] User $($User.SamAccountName) changed their password. Enforcing custom rules..."
                Enforce-CustomPasswordRules -NewPassword "PLACEHOLDER" # Modify for deeper integration
            }
        }
    }
}
# Ensure Persistence via Registry
function Set-RegistryPersistence {
    Write-Host "[*] Adding registry persistence..."
    $scriptPath = "C:\Windows\System32\strict_pass_enforcer.ps1"
    Copy-Item $MyInvocation.MyCommand.Path -Destination $scriptPath -Force
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" `
                     -Name "StrictPasswordEnforcer" `
                     -Value "powershell -ExecutionPolicy Bypass -File $scriptPath" -Force
    Write-Host "[+] Persistence added via registry."
}
# Ensure Persistence via Scheduled Task
function Set-ScheduledTaskPersistence {
    Write-Host "[*] Creating scheduled task for persistence..."
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Windows\System32\strict_pass_enforcer.ps1"
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName "StrictPasswordEnforcer" -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal -Settings $taskSettings -Force
    Write-Host "[+] Persistence added via scheduled task."
}
# Main Execution
Set-StrictPasswordPolicy
Set-RegistryPersistence
Set-ScheduledTaskPersistence
Start-Job -ScriptBlock { Monitor-PasswordChanges } # Background process
Write-Host "[+] Strict password enforcement is now active."