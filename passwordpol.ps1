function Test-PasswordRules {
    param (
        [Parameter(Mandatory = $true)]
        [SecureString]$NewPassword
    )

    # Load Windows Forms for MessageBox
    Add-Type -AssemblyName System.Windows.Forms

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
        $message = @"
Password does not meet the required complexity. 
Please ensure your password contains the following:

- A year when Dune 1 or 2 (book or movie) was released.
- A location from the Dune universe.
- The name of the author of Dune.

Please update your password accordingly.
"@
        
        # Show the MessageBox to the user
        [System.Windows.Forms.MessageBox]::Show($message, "Password Complexity Requirement", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)

        Write-Host "[!] Password does not meet the complexity requirements. Please try again."
        return
    }

    Write-Host "[+] Password meets all complexity requirements!"
}