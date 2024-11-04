<#
    Original Code: /u/Mesyre
    Edits: /u/OofItsKyle
    Edited: November 4 2024
#>

# Load necessary assembly for Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to play a sound alert
function Play-SoundAlert {
    [System.Media.SystemSounds]::Exclamation.Play()
}

# Function to create a dimmed overlay behind the message box
function Show-DimmedOverlay {
    $overlayForm = New-Object System.Windows.Forms.Form
    $overlayForm.FormBorderStyle = 'None'
    $overlayForm.StartPosition = 'Manual'
    $overlayForm.Location = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Location
    $overlayForm.Size = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Size
    $overlayForm.BackColor = [System.Drawing.Color]::Black
    $overlayForm.Opacity = 0.7  # Increase opacity to dim the background more
    $overlayForm.TopMost = $true
    $overlayForm.Show()
    return $overlayForm
}

# Function to show a modal message box with buttons
function Show-MessageBox {
    param (
        [string]$message,
        [string]$title,
        [System.Windows.Forms.Form]$overlayForm
    )

    # Center the message box on the primary screen
    $primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
    $width = 400
    $height = 200
    $x = [Math]::Round(($primaryScreen.Bounds.Width - $width) / 2)
    $y = [Math]::Round(($primaryScreen.Bounds.Height - $height) / 2)

    # Show the message box as a modal dialog
    $result = [System.Windows.Forms.MessageBox]::Show($overlayForm, $message, $title, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    
    # Close the overlay after the message box is closed
    $overlayForm.Close()

    return $result
}

# Get user input for shutdown delay
function Get-ShutdownDelay {
    param (
        [string]$promptMessage = "Enter shutdown delay in minutes"
    )
    
    $shutdownDelay = 0
    while ($shutdownDelay -le 0) {
        $shutdownDelay = Read-Host $promptMessage
        if ($shutdownDelay -notmatch '^\d+$') {
            Write-Host "Invalid input. Please enter a valid number." -ForegroundColor "Red"
            Start-Sleep -Seconds 5
            $shutdownDelay = 0
            Clear-Line -UpLine 1
            Clear-Line -UpLine 1
            Clear-Line
        }
        elseif ($shutdownDelay -eq 0) {
            Write-Host "Shutdown delay must be greater than 0." -ForegroundColor "Red"
            Start-Sleep -Seconds 5
            Clear-Line -UpLine 1
            Clear-Line -UpLine 1
            Clear-Line
        }
    }
    return $shutdownDelay
}

# Main shutdown timer function
function Start-Countdown {
    param (
        [int]$totalSeconds,
        [ref]$WriteSecondLine
    )
    
    $cancelled = $false
    while ($totalSeconds -ge 0) {
        $currentMinutes = [math]::Floor($totalSeconds / 60)
        $currentSeconds = $totalSeconds % 60

        # Format the time remaining
        $timeLeft = "{0:D2}:{1:D2}" -f [int]$currentMinutes, $currentSeconds

        # Clear the current line and print the updated time
        Clear-Line
        Write-Host -NoNewline "Time remaining: " -ForegroundColor "Cyan"
        Write-Host "$timeLeft" -NoNewline -ForegroundColor "Cyan"

        if ($WriteSecondLine) {
            $WriteSecondLine.Value = $false
            Write-Host ""
            Write-Host "Press 'C' to stop the timer." -ForegroundColor "Yellow"
            Clear-Line -UpLine 2
        }

        # Wait for 1 second
        Start-Sleep -Seconds 1
        $totalSeconds--

        # Check for user interrupt
        if ([System.Console]::KeyAvailable) {
            $key = [System.Console]::ReadKey($true)
            if ($key.Key -eq [ConsoleKey]::C) {
                $cancelled = $true
                break
            }
        }
    }

    return $cancelled, $totalSeconds
}

function Clear-Line {
    param (
        [int]$UpLine = 0
    )
    [console]::CursorLeft = 0
    Write-Host (" " * [console]::WindowWidth) -NoNewline
    [console]::CursorLeft = 0

    if ($UpLine -gt 0) {
        [console]::CursorTop -= $upLine
    }
}

# Function to handle the countdown interruption process
function Handle-Interruption {
    param (
        [int]$remainingSeconds,
        [ref]$WriteSecondLine
    )
    $cancelled = $true
    while ($cancelled) {
        Write-Host ""
        Clear-Line
        Write-Host "Countdown was interrupted." -ForegroundColor "Red"
        $continueTimer = Read-Host "Do you wish to continue the current timer? (Y/N)"

        if ($continueTimer -eq 'Y') {
            # Restart countdown with the remaining seconds
            Clear-Line
            Write-Host "Continuing timer..." -ForegroundColor "Green"
            Start-Sleep -Seconds 2
            Clear-Line -UpLine 1
            Clear-Line -Upline 3
            $WriteSecondLine.Value = $true
            $cancelled = $false
            return $remainingSeconds  # Return remaining seconds to continue
        }
        elseif ($continueTimer -eq 'N') {
            $newTime = Read-Host "Do you wish to enter a different time? (Y/N)"
            if ($newTime -eq 'Y') {
                Main
            }
            else {
                Write-Host "`nProcess stopped." -ForegroundColor "Red"
                return -1  # Indicate process should stop
            }
        }
    }
}


function Main {
        
    # Start script
    Clear-Host
    $shutdownDelay = Get-ShutdownDelay
    $totalSeconds = [int]$shutdownDelay * 60

    Write-Host "Countdown started for $shutdownDelay minute(s)..." -ForegroundColor "Green"

    # Run the countdown
    $remainingSeconds = $totalSeconds
    $WriteSecondLine = $true


    while ($true) {
        $cancelled, $remainingSeconds = Start-Countdown -totalSeconds $remainingSeconds -WriteSecondLine ([ref]$WriteSecondLine)

        if (-not $cancelled) {
            # If countdown finished and was not cancelled, show shutdown confirmation
            Play-SoundAlert  # Play sound alert before showing the message box
            $overlayForm = Show-DimmedOverlay
            $result = Show-MessageBox "Your PC will shut down in 60 seconds. Do you wish to continue?" "Shutdown Confirmation" $overlayForm
            
            # Create a timer for the automatic shutdown after 60 seconds
            $shutdownJob = Start-Job -ScriptBlock {
                Start-Sleep -Seconds 60
                shutdown /s /t 0
            }

            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                # If Yes is pressed, shutdown command will be executed by the job
                Stop-Job -Job $shutdownJob
                Remove-Job -Job $shutdownJob
                break
            }
            else {
                Write-Host "`nShutdown aborted." -ForegroundColor "Red"
                # Make sure there's exactly one line break here
                Write-Host ""
                Stop-Job -Job $shutdownJob
                Remove-Job -Job $shutdownJob
                break
            }
        }
        else {
            # Handle interruption
            $remainingSeconds = Handle-Interruption -remainingSeconds $remainingSeconds -WriteSecondLine ([ref]$WriteSecondLine)
            if ($remainingSeconds -eq -1) {
                # Exit if the process was stopped
                Write-Host "`nPress Enter to exit..." -ForegroundColor "Yellow"
                Read-Host
                exit
            }
        }
    }

    # Final messages with correct spacing
    if ($remainingSeconds -eq 0) {
        Write-Host "`nTime remaining: 00:00"
        Write-Host "Shutdown aborted." -ForegroundColor "Red"
        # Ensure only one line break before the exit prompt
        Write-Host ""
    }
    Write-Host "Press Enter to exit..." -ForegroundColor "Yellow"
    Read-Host
}


Main