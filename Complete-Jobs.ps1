function Complete-Jobs {
    [CmdletBinding()]
    param (
        # Parameter representing an array of jobs
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                if ($_ -is [System.Management.Automation.Job]) {
                    return $true
                }
                elseif ($_ -is [System.Management.Automation.Job[]]) {
                    return $true
                }
                else {
                    throw "The parameter must be a Job object or an array of Job objects."
                }
            })]
        $Jobs,
        # Parameter representing a switch to wait for the jobs to complete
        [Parameter(Mandatory = $false)]
        [switch]$Wait,
        # Parameter for handling errors
        [Parameter(Mandatory = $false)]
        [ValidateSet("Write", "AddToResults")]
        [string]$ErrorMode = "Write"
    )

    $results = @()

    # Ensure $Jobs is an array
    if ($Jobs -isnot [System.Collections.IEnumerable]) {
        $Jobs = @($Jobs)
    }

    # Collect results from all jobs
    $Jobs | ForEach-Object {
        $job = $_
        try {
            if ($Wait) {
                Wait-Job -Job $job
            }
            $jobResult = $job | Receive-Job
            $results += $jobResult
            Write-Verbose "Processed job: $($jobResult.Name)"
        }
        catch {
            $errorMessage = "Error processing job ID $($job.Id): $_"
            if ($ErrorMode -eq "Write") {
                Write-Error $errorMessage
            }
            elseif ($ErrorMode -eq "AddToResults") {
                $results += [PSCustomObject]@{ Error = $errorMessage }
            }
        }
        finally {
            Remove-Job -Job $job
        }
    }
    return $results
}