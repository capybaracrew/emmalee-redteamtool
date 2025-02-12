# Emmalee Carpenter
# Assisted by ChatGPT
# eoc7219@rit.edu
# 2/12/25
function Show-PasswordPolicyPopup {
    $message = @"
Your password must meet the following requirements:
- Contain a year when Dune 1 or 2 (book or movie) was released (e.g., 2021, 2024, 1965, 1969).
- Include a location from the Dune universe (e.g., Arrakis, Arrakeen, Bandalong).
- Contain the name of the author of Dune (e.g., Frank Herbert).
"@
    
    [System.Windows.MessageBox]::Show($message, "Password Policy Requirement", "OK", "Error")
}

# Password Policy customized function
function Test-PasswordRules {
    param (
        [Parameter(Mandatory = $true)]
        [SecureString]$NewPassword
    )

    # Convert SecureString to PlainText
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewPassword)
    $PlainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    # Define Dune-related requirements for password
    $BookMovieDates = @("2021", "2024", "1965", "1969")
    $AuthorNames = @("Frank", "frank", "Herbert", "herbert", "FrankHerbert", "frankherbert")
    $DuneLocations = @("Arrakis", "Arrakeen", "Bandalong", "Barony", "Cala", "Dimitri", "Harko", "Niubbe", "Starda")

    # Check if password contains the Dune requirements
    $HasDate = $BookMovieDates | Where-Object { $PlainTextPassword -match $_ }
    $HasLocation = $DuneLocations | Where-Object { $PlainTextPassword -match $_ }
    $HasAuthor = $AuthorNames | Where-Object { $PlainTextPassword -match $_ }

    if (-not ($HasDate -and $HasLocation -and $HasAuthor)) {
        Show-PasswordPolicyPopup
        return $false
    }
    return $true
}

# A registry key to continue the script everytime the system is rebooted.
function Set-RegistryPersistence {
    Write-Host "[*] Adding registry persistence..."
    $scriptPath = "C:\Windows\System32\passwordpol.ps1"

    # Ensure script is running from a saved file
    if ($MyInvocation.MyCommand.Path) {
        Copy-Item $MyInvocation.MyCommand.Path -Destination $scriptPath -Force
    } else {
        Write-Host "[!] Script is not running from a file. Persistence may fail."
    }

    # Add registry key
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" `
                     -Name "StrictPasswordEnforcer" `
                     -Value "powershell -ExecutionPolicy Bypass -File $scriptPath" -Force

    Write-Host "[+] Persistence added via registry."
}

# Deploy registry persistence
Set-RegistryPersistence
