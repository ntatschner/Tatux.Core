@{
ModuleVersion = '0.0.17'

GUID = 'a61ffd6a-dac4-4de4-a830-0e58a0535eaa'

Author = 'Nigel Tatschner'

CompanyName = 'Tatux Solutions'

Copyright = '(c) 2024 Nigel Tatschner. All rights reserved.'

Description = 'Core functions required for my suite of modules.'

PowerShellVersion = '5.1'

NestedModules = @('tatux.core.psm1')

FunctionsToExport = '*'

CmdletsToExport = '*'

VariablesToExport = '*'

AliasesToExport = '*'

PrivateData = @{
    PSData = @{
        Tags = @( 'Core', 'Tatux', 'Module', 'Telemetry' )

        ProjectUri = 'https://github.com/ntatschner/tatux.core'

        ReleaseNotes = 'Initial Release for core module'
    } 
}

HelpInfoURI = 'https://pwsh.dev.tatux.com/tatux.core/'

}