Function Get-AdminStatus {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Throw", "WriteWarning", "WriteError", "RunAsAdmin")]
        [string]$Mode
    )

    # Check if the script is running as administrator
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        switch ($Mode) {
            "Throw" {
                throw "You must run this script as an Administrator."
            }
            "WriteWarning" {
                Write-Warning "You are not running this script as an Administrator."
                return $false
            }
            "WriteError" {
                Write-Error "You are not running this script as an Administrator."
                return $false
            }
            "RunAsAdmin" {
                # Attempt to rerun the script as administrator
                $script = $MyInvocation.MyCommand.Path
                $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$script`""
                Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
                exit
            }
        }
        return $false
    }
    return $true
}