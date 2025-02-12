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

# Function to Show Pop-up Message with Password Rules
function Show-PasswordPolicyPopup {
    Add-Type -TypeDefinition @"
    using System.Windows.Forms;
"@ -Language CSharp

    $message = "Your password does not meet the policy requirements!`n`n" +
               "- Must include a Dune book/movie release year (e.g., 2021, 1965).`n" +
               "- Must contain a location from the Dune universe (e.g., Arrakis, Harko).`n" +
               "- Must include the author's name (e.g., Frank, Herbert).`n`n" +
               "Please try again with a valid password."

    [System.Windows.Forms.MessageBox]::Show($message, "Password Policy Violation", 0, 48)
}

# Function to Monitor Password Failures and Trigger Pop-up
function Monitor-PasswordFailures {
    Write-Host "[*] Monitoring failed password changes..."
    while ($true) {
        $events = Get-WinEvent -LogName Security -FilterXPath "*[System[(EventID=4723 or EventID=4724)]]" -MaxEvents 5
        foreach ($event in $events) {
            $timeDiff = (New-TimeSpan -Start $event.TimeCreated -End (Get-Date)).TotalSeconds
            if ($timeDiff -lt 10) {
                Write-Host "[!] Detected failed password change. Displaying policy popup..."
                Show-PasswordPolicyPopup
            }
        }
        Start-Sleep -Seconds 10
    }
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
        Show-PasswordPolicyPopup
        exit 1
    }
    Write-Host "[+] Password meets all complexity requirements!"
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
Start-Job -ScriptBlock { Monitor-PasswordFailures } # Background process
Write-Host "[+] Strict password enforcement is now active."
