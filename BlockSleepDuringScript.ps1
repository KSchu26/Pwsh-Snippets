$schemeInfo = powercfg /GETACTIVESCHEME
$null = $schemeInfo -match "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}"
$schemeID = $matches[0]

$currentSleepSettings = powercfg /q $schemeID SUB_SLEEP STANDBYIDLE
$currentSleepACSetting = $currentSleepSettings | Where-Object{$_ -like "*AC Power Setting Index*"}
$null = $currentSleepACSetting -match "0x\w{8}"
$currentSleepACSeconds = [convert]::ToInt32($matches[0].Substring(2), 16)
 

powercfg /setacvalueindex $schemeID SUB_SLEEP STANDBYIDLE 0

# YOUR OTHER SCRIPT HERE

powercfg /setacvalueindex $schemeID SUB_SLEEP STANDBYIDLE $currentSleepACSeconds