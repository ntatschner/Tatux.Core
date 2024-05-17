function Invoke-TelemetryCollection {
    param (
        [CmdletBinding(HelpUri = 'https://pwsh.dev.tatux.co.uk/tatux.telemetry/docs/Invoke-TelemetryCollection.html')]

        [string]$ModuleName = 'UnknownModule',

        [string]$ModuleVersion = 'UnknownModuleVersion',

        [string]$ModulePath = 'UnknownModulePath',

        [string]$CommandName = 'UnknownCommand',
        
        [Parameter(Mandatory = $true)]
        [string]$ExecutionID = 'UnknownExecutionID',

        [Parameter(Mandatory = $true)]
        [ValidateSet('Start', 'In-Progress', 'End', 'Module-Load')]
        [string]$Stage,

        [bool]$Failed = $false,

        [string]$Exception,

        [switch]$Minimal,

        [switch]$ClearTimer,

        [Parameter(Mandatory = $true)]
        [string]$URI
    )

    $CurrentTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")

    switch -Regex ($Stage) {
        'Module-Load' {
            if ((Get-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Scope script -ErrorAction SilentlyContinue) -and (-Not $ClearTimer)) {
                Set-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Value (Get-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Scope script -ErrorAction SilentlyContinue) -Scope script -Force | Out-Null
            }
            else {
                New-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Value $(Get-Date) -Scope script -Force | Out-Null
            }
        }
        'Start' {
            if ((Get-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Scope script -ErrorAction SilentlyContinue) -and (-Not $ClearTimer)) {
                Set-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Value (Get-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Scope script -ErrorAction SilentlyContinue) -Scope script -Force | Out-Null
            }
            else {
                New-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Value $(Get-Date) -Scope script -Force | Out-Null
            }
        }
        "End|Module-Load" {
            Start-Job -Name "TC_Job_Trying_To_Be_Unique_9000" -ArgumentList $(Get-Variable -Name "GlobalExecutionDuration_$ExecutionID").Value -ScriptBlock {
                param ($GlobalExecutionDuration)
                $ExecutionDuration = [Int64]$($(New-TimeSpan -Start $GlobalExecutionDuration -End $(Get-Date)).TotalMilliseconds * 1e6)
                $WebRequestArgs = @{
                    Uri             = $Using:URI
                    Method          = 'Put'
                    ContentType     = 'application/json'
                    UseBasicParsing = $true
                }
                # Generate hardware specific but none identifying telemetry data for the output
                $Hardware = Get-WmiObject -Class Win32_ComputerSystem
                $bootPartition = Get-WmiObject -Class Win32_DiskPartition | Where-Object -Property bootpartition -eq True
                $bootDriveSerial = $(Get-WmiObject -Class Win32_DiskDrive | Where-Object -Property index -eq $bootPartition.diskIndex)
                if ([string]::IsNullOrEmpty($bootDriveSerial.SerialNumber) -and ($bootDriveSerial.Model -like '*Virtual*')) {
                    $bootDriveSerial = "VirtualDrive-$($bootDriveSerial.size)"
                }
                else {
                    $bootDriveSerial = $bootDriveSerial.SerialNumber.Trim()
                }

                $HardwareData = @{
                    Manufacturer              = $Hardware.Manufacturer
                    Model                     = $Hardware.Model
                    TotalPhysicalMemory       = $Hardware.TotalPhysicalMemory
                    NumberOfProcessors        = $Hardware.NumberOfProcessors
                    NumberOfLogicalProcessors = $Hardware.NumberOfLogicalProcessors
                    PartOfDomain              = $Hardware.PartOfDomain
                    HardwareSerialNumber      = $((Get-WmiObject -Class Win32_BIOS).SerialNumber)
                    BootDriveSerial           = $bootDriveSerial
                }

                # Generate OS specific but none identifying telemetry data for the output
                $OS = Get-WmiObject -Class Win32_OperatingSystem

                $OSData = @{
                    OSType         = $OS.Caption
                    OSArchitecture = $OS.OSArchitecture
                    OSVersion      = $OS.Version
                    OSBuildNumber  = $OS.BuildNumber
                    SerialNumber   = $OS.SerialNumber
                }

                # Generate PowerShell specific but none identifying telemetry data for the output

                $PSData = @{
                    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
                    HostVersion       = $Host.Version.ToString()
                    HostName          = $Host.Name.ToString()
                    HostUI            = $Host.UI.ToString()
                    HostCulture       = $Host.CurrentCulture.ToString()
                    HostUICulture     = $Host.CurrentUICulture.ToString()
                }

                # Generate module specific but none identifying telemetry data for the output

                $ModuleData = @{
                    ModuleName    = if ([string]::IsNullOrEmpty($Using:ModuleName)) { 'UnknownModule' } else { $Using:ModuleName }
                    ModuleVersion = if ([string]::IsNullOrEmpty($Using:ModuleVersion)) { 'UnknownModuleVersion' } else { $Using:ModuleVersion }
                    ModulePath    = if ([string]::IsNullOrEmpty($Using:ModulePath)) { 'UnknownModulePath' } else { $Using:ModulePath }
                    CommandName   = if ([string]::IsNullOrEmpty($Using:CommandName)) { 'UnknownCommand' } else { $Using:CommandName }
                }
                # Create a new hashtable
                $AllData = @{}

                # Add each hashtable to the new hashtable
                $AllData += $HardwareData
                $AllData += $OSData
                $AllData += $PSData
                $AllData += $ModuleData
                $AllData += @{ID = $AllData.BootDriveSerial + "_" + $AllData.SerialNumber } 
                $AllData += @{LocalDateTime = $Using:CurrentTime }
                $AllData += @{ExecutionDuration = $ExecutionDuration }
                $AllData += @{Stage = $Using:Stage }
                $AllData += @{Failed = $Using:Failed }
                $AllData += @{Exception = $Using:Exception | Out-String }
                $AllData += @{ExecutionID = $Using:ExecutionID }
                if ($Minimal) {
                    $AllData | ForEach-Object {
                        if ($_.Name -notin @('ID', 'CommandName', 'ModuleName', 'ModuleVersion', 'LocalDateTime', 'ExecutionDuration', 'Stage', 'Failed', 'Exception', 'ExecutionID')) {
                            $_.Value = 'Minimal'
                        }
                        $body = $AllData | ConvertTo-Json
                        Invoke-WebRequest @WebRequestArgs -Body $body | Out-Null
                    }
                }
                else {
                    $body = $AllData | ConvertTo-Json
                    Invoke-WebRequest @WebRequestArgs -Body $body | Out-Null
                }
            } | Out-Null
            # Clear Old Jobs
            Get-Job -Name "TC_Job_Trying_To_Be_Unique_9000" -ErrorAction SilentlyContinue | Where-Object State -in Completed, Failed | Remove-Job -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
}