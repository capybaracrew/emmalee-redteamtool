# 1. Apply Strict Password Policy via Group Policy (Can be modified/reverted by Blue Team)
function Set-StrictPasswordPolicy {
    Write-Host "[*] Applying strict password policies via Group Policy..."
    # Use Group Policy Editor COM Object to apply password settings (can be changed by Blue Team)
    $gpo = New-Object -ComObject "GPEDIT.GPEditor"
    $gpo.SetPasswordPolicy(15, 1, 24, 5)  # Set min length, complexity, history, lockout

    Write-Host "[+] Password policies enforced through Group Policy."
}

# 2. Enforce Custom Password Rules (Ensure password meets specific criteria)
function Test-PasswordRules {
    param (
        [Parameter(Mandatory = $true)]
        [SecureString]$NewPassword
    )

    # Convert SecureString to Plain Text (Only for Validation, Avoid Storing!)
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewPassword)
    $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    # Dune Book/Location/Author Criteria
    $BookMovieDates = @("2021", "2024", "1965", "1969")
    $AuthorNames = @("Frank", "frank", "Herbert", "herbert", "FrankHerbert", "frankherbert")
    $DuneLocations = @("Arrakis", "Arrakeen", "Bandalong", "Barony", "Cala", "Dimitri", "Harko", "Niubbe", "Starda")

    $HasDate = $false
    $HasLocation = $false
    $HasAuthor = $false

    # Check for Date, Location, and Author in Password
    foreach ($Date in $BookMovieDates) {
        if ($PlainPassword -match $Date) { $HasDate = $true }
    }
    foreach ($Location in $DuneLocations) {
        if ($PlainPassword -match $Location) { $HasLocation = $true }
    }
    foreach ($Author in $AuthorNames) {
        if ($PlainPassword -match $Author) { $HasAuthor = $true }
    }

    # If all 3 criteria are met, the password is valid
    if (-not ($HasDate -and $HasLocation -and $HasAuthor)) {
        $message = @"
Password must contain:
- A year when Dune 1 or 2 (book or movie) was released.
- A location from the Dune universe.
- The name of the author of Dune.

Please update your password accordingly.
"@
        # Show the MessageBox to the user
        [System.Windows.Forms.MessageBox]::Show($message, "Password Complexity Requirement", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)

        Write-Host "[!] Password does not meet the complexity requirements. Please try again."
        exit 1
    }

    Write-Host "[+] Password meets all complexity requirements!"
}

# 3. Monitor Password Changes (Fake Hook - Can be modified for deeper integration)
function Watch-PasswordChanges {
    Write-Host "[*] Monitoring password changes..."
    while ($true) {
        Start-Sleep -Seconds 10
        $Users = Get-ADUser -Filter * -Properties PasswordLastSet | Sort-Object PasswordLastSet -Descending
        foreach ($User in $Users) {
            $TimeSinceLastChange = (Get-Date) - $User.PasswordLastSet
            if ($TimeSinceLastChange.TotalSeconds -lt 30) { # Recent password change
                Write-Host "[!] User $($User.SamAccountName) changed their password. Enforcing custom rules..."
                # Call custom rules enforcement (update with actual logic if needed)
                Test-PasswordRules -NewPassword "PLACEHOLDER" # Placeholder for deeper integration
            }
        }
    }
}

# 4. Ensure Persistence via Registry (Run on system startup)
function Set-RegistryPersistence {
    Write-Host "[*] Adding registry persistence..."
    $scriptPath = "C:\Windows\System32\strict_pass_enforcer.ps1"
    Copy-Item $MyInvocation.MyCommand.Path -Destination $scriptPath -Force
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" `
                     -Name "StrictPasswordEnforcer" `
                     -Value "powershell -ExecutionPolicy Bypass -File $scriptPath" -Force
    Write-Host "[+] Persistence added via registry."
}

# 5. Ensure Persistence via Scheduled Task (Runs on startup)
function Set-ScheduledTaskPersistence {
    Write-Host "[*] Creating scheduled task for persistence..."
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Windows\System32\strict_pass_enforcer.ps1"
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName "StrictPasswordEnforcer" -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal -Settings $taskSettings -Force
    Write-Host "[+] Persistence added via scheduled task."
}

# 6. Cleanup: Remove Script, Registry, and Scheduled Task (Allow Blue Team to Remove)
function Remove-StrictPasswordPolicy {
    Write-Host "[*] Removing custom password policy and persistence..."

    # Remove registry entry
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "StrictPasswordEnforcer" -Force

    # Remove scheduled task
    Unregister-ScheduledTask -TaskName "StrictPasswordEnforcer" -Force

    # Remove script
    Remove-Item "C:\Windows\System32\strict_pass_enforcer.ps1" -Force

    Write-Host "[+] Custom password policy and persistence removed."
}

# Main Execution
Set-StrictPasswordPolicy           # Apply strict password policy
Set-RegistryPersistence            # Set registry persistence
Set-ScheduledTaskPersistence      # Set scheduled task persistence
Start-Job -ScriptBlock { Watch-PasswordChanges } # Background process for monitoring password changes

Write-Host "[+] Strict password enforcement is now active. The blue team can remove it by running Remove-StrictPasswordPolicy."

# Cleanup (call this when blue team wants to remove it)
# Remove-StrictPasswordPolicy
