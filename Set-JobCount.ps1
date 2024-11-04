
function Set-JobCount {
    [CmdletBinding()]
    param (
        [int]$CurrentJobCount = 1,
        [int]$TargetCPU = 85,
        [int]$TargetRAM = 95
    )

    try {
        # Get current CPU load percentage using Get-Counter for more accuracy
        $cpuLoad = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    
        # Get current RAM usage percentage
        $totalMemory = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory
        $freeMemory = (Get-WmiObject -Class Win32_OperatingSystem).FreePhysicalMemory * 1KB
        $usedMemory = $totalMemory - $freeMemory
        $ramUsage = ($usedMemory / $totalMemory) * 100
    
        # Debug output
        Write-Verbose "Current CPU Load: $cpuLoad%"
        Write-Verbose "Current RAM Usage: $ramUsage%"
    
        # Adjust job count based on CPU and RAM usage
        if ($cpuLoad -lt ($TargetCPU - 10) -and $ramUsage -lt ($TargetRAM - 10)) {
            $CurrentJobCount++
        }
        elseif ($cpuLoad -gt ($TargetCPU + 10) -or $ramUsage -gt ($TargetRAM + 10)) {
            $CurrentJobCount = [math]::Max(1, $CurrentJobCount - 1)
        }
    }
    catch {
        Write-Warning "Error occurred while adjusting job count, will stay at $CurrentJobCount : $_"
    }

    return $CurrentJobCount
}