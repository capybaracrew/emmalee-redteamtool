function Test-PasswordRules {
    param (
        [Parameter(Mandatory = $true)]
        [SecureString]$NewPassword
    )

    # Convert SecureString to PlainText
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewPassword)
    $PlainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    # Define Dune-related weak password elements
    $BookMovieDates = @("2021", "2024", "1965", "1969")
    $AuthorNames = @("Frank", "frank", "Herbert", "herbert", "FrankHerbert", "frankherbert")
    $DuneLocations = @("Arrakis", "Arrakeen", "Bandalong", "Barony", "Cala", "Dimitri", "Harko", "Niubbe", "Starda")

    # Check if password contains weak elements
    $HasDate = $BookMovieDates | Where-Object { $PlainTextPassword -match $_ }
    $HasLocation = $DuneLocations | Where-Object { $PlainTextPassword -match $_ }
    $HasAuthor = $AuthorNames | Where-Object { $PlainTextPassword -match $_ }

    return ($HasDate -and $HasLocation -and $HasAuthor)
}

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

# Deploy persistence
Set-RegistryPersistence

