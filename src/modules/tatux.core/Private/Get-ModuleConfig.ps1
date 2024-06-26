function Get-ModuleConfig {
    [OutputType([hashtable])]

    param (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $CommandPath
    )
    try {
        $ModulePath = $(Split-Path -Path (Split-Path -Path $CommandPath -Parent) -Parent)
        $ModuleName = Get-ChildItem -Path $ModulePath -Filter "*.psd1" -File | Select-Object -First 1 | Select-Object -ExpandProperty BaseName
        $UserPowerShellModuleConfigPath = Join-Path -Path $(Split-Path -Path $($env:PSModulePath -split ';' | ForEach-Object { if (($_ -match $([regex]::Escape($env:USERNAME))) -and ($_ -notmatch '\.')) { $_ } }) -Parent) -ChildPath 'Config'
        $ModuleConfigPath = Join-Path -Path $UserPowerShellModuleConfigPath -ChildPath $ModuleName
        $ModuleConfigFilePath = Join-Path -Path $ModuleConfigPath -ChildPath 'Module.Config.json'
        $ConfigDefaults = Join-Path -Path $(Split-Path -Path $PSScriptRoot -Parent) -ChildPath "\Config\Module.Defaults.json"
    }
    catch {
        Write-Error "CommandPath: $($CommandPath)`nError: `n$($_)`n Invocation $($_.InvocationInfo.ScriptLineNumber) $($_.InvocationInfo.ScriptName)"
        return
    }
    # Test to see if module config JSON exists and create it if it doesn't
    if (-not (Test-Path -Path $ModuleConfigFilePath)) {
        $DefaultConfig = Get-Content -Path $ConfigDefaults | ConvertFrom-Json
        $HashTable = @{}
        $DefaultConfig.PSObject.Properties | ForEach-Object { $HashTable[$_.Name] = $_.Value }
        while ($null -eq (Get-ChildItem -Path $ModulePath -Filter "*.psd1" -File)) {
            $ModulePath = Split-Path -Path $ModulePath -Parent
            if ($ModulePath -eq (Split-Path -Path $ModulePath -Parent)) {
                Write-Error "No .psd1 file found in the directory tree."
                return
            }
        }
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