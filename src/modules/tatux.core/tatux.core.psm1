#region get public and private function definition files.
$Public  = @(
    Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Exclude "*.Tests.ps1" -ErrorAction SilentlyContinue
)
$Private = @(
    Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Exclude "*.Tests.ps1" -ErrorAction SilentlyContinue
)
#endregion

#region source the files
foreach ($Function in @($Public + $Private)) {
    $FunctionPath = $Function.fullname
    try {
	. $FunctionPath # dot source function
    } catch {
	Write-Error -Message "Failed to import function at $($FunctionPath): $_"
    }
}
#endregion

$Date = Get-Date -UFormat "%Y.%m.%d"
$Time = Get-Date -UFormat "%H:%M:%S"
. "$PSScriptRoot\Colors.ps1"
#endregion

#region export Public functions ($Public.BaseName) for WIP modules
Export-ModuleMember -Function $Public.Basename
Export-ModuleMember -Function Invoke-TelemetryCollection, Get-ModuleConfig, Get-ModuleStatus, Get-ParameterValues
#endregion