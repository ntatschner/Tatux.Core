function Get-ModuleConfig {
    [OutputType([hashtable])]

    param (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $CommandPath
    )
    try {
        $BaseCommandPath = Split-Path -Path $CommandPath -Parent
        Write-Verbose "BaseCommandPath: $BaseCommandPath"
        # Recursively step back through the CommandPath to find the module path that contains the module manifest file and get the module base path and module name
        while (-not (Test-Path -Path $BaseCommandPath -Filter *.psd1)) {
            $ParentPath = Split-Path -Path $BaseCommandPath -Parent
            Write-Verbose "ParentPath: $ParentPath"
            if ($ParentPath -eq $BaseCommandPath) {
                Write-Verbose "ParentPath: $ParentPath is the same as BaseCommandPath: $BaseCommandPath"
                # Break the loop if the parent path is the same as the current path,
                # indicating that we've reached the root directory
                break
            }
            $BaseCommandPath = $ParentPath
        }
        $ModuleFilePath = Join-Path -Path $BaseCommandPath -ChildPath $(Split-Path -Path $CommandPath -Leaf)
        $ModulePath = Split-Path -Path $ModuleFilePath -Parent
        if ([string]::IsNullOrEmpty($ModulePath)) {
            Write-Error "ModulePath is empty or null."
            throw
        }
        Write-Verbose "ModulePath: $ModulePath"
        $ModuleName = Get-ChildItem -Path $CommandPath -Filter "*.psd1" -File | Select-Object -First 1 | Select-Object -ExpandProperty BaseName
        Write-Verbose "ModuleName: $ModuleName"
        $UserPowerShellModuleConfigPath = Join-Path -Path $(Split-Path -Path $($env:PSModulePath -split ';' | ForEach-Object { if (($_ -match $([regex]::Escape($env:USERNAME))) -and ($_ -notmatch '\.')) { $_ } }) -Parent) -ChildPath 'Config'
        Write-Verbose "UserPowerShellModuleConfigPath: $UserPowerShellModuleConfigPath"
        $ModuleConfigPath = Join-Path -Path $UserPowerShellModuleConfigPath -ChildPath $ModuleName
        Write-Verbose "ModuleConfigPath: $ModuleConfigPath"
        $ModuleConfigFilePath = Join-Path -Path $ModuleConfigPath -ChildPath 'Module.Config.json'
        Write-Verbose "ModuleConfigFilePath: $ModuleConfigFilePath"
        $ConfigDefaultsPath = Join-Path -Path $(Split-Path -Path $PSScriptRoot -Parent) -ChildPath "\Config\Module.Defaults.json"
        Write-Verbose "ConfigDefaultsPath: $ConfigDefaultsPath"
        $DefaultConfig = Get-Content -Path $ConfigDefaultsPath | ConvertFrom-Json
        Write-Verbose "DefaultConfig: $DefaultConfig"
    }
    catch {
        Write-Error "CommandPath: $($CommandPath)`nError: `n$($_)`n Invocation $($_.InvocationInfo.ScriptLineNumber) $($_.InvocationInfo.ScriptName)"
        return
    }
    # Test to see if module config JSON exists and create it if it doesn't
    if (-not (Test-Path -Path $ModuleConfigFilePath)) {
        $HashTable = @{}
        $DefaultConfig.PSObject.Properties | ForEach-Object { $HashTable[$_.Name] = $_.Value }
        $HashTable.Add('ModuleName', $ModuleName)
        $HashTable.Add('ModulePath', $ModulePath)
        $HashTable.Add('ModuleConfigPath', $ModuleConfigPath)
        $HashTable.Add('ModuleConfigFilePath', $ModuleConfigFilePath)
        Set-ModuleConfig @HashTable
        try {
            Get-ModuleConfig -CommandPath $CommandPath -ErrorAction Stop
        }
        catch {
            Write-Error "CommandPath: $($CommandPath)`nError: `n$($_)`n Invocation $($_.InvocationInfo.ScriptLineNumber) $($_.InvocationInfo.ScriptName)"
            return
        }
    }
    else {
        $Config = Get-Content -Path $ModuleConfigFilePath | ConvertFrom-Json
        $DefaultConfig.PSObject.Properties | ForEach-Object {
            if ($Config.PSObject.Properties.Name -notcontains $_.Name) {
                $Config | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value
            }
        }
        # Update Module Path if it has changed
        $CurrentlyLoadedModuleVersion = (Import-PowerShellDataFile -Path $ModuleFilePath).ModuleVersion
        if ($Config.ModuleVersion -ne $CurrentlyLoadedModuleVersion) {
            $Config.ModuleVersion = $CurrentlyLoadedModuleVersion
            $Config | ConvertTo-Json | Set-Content -Path $ModuleConfigFilePath -Force -Confirm:$false
            $Config = Get-Content -Path $ModuleConfigFilePath | ConvertFrom-Json
        }
        if ($Config.ModulePath -ne $ModulePath) {
            $Config.ModulePath = $ModulePath
            $Config | ConvertTo-Json | Set-Content -Path $ModuleConfigFilePath -Force -Confirm:$false
            $Config = Get-Content -Path $ModuleConfigFilePath | ConvertFrom-Json
        }
        $HashTable = @{}
        $Config.PSObject.Properties | ForEach-Object { $HashTable[$_.Name] = $_.Value }
        $HashTable
    }
}