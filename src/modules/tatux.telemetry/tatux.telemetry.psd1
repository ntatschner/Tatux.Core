@{

# Script module or binary module file associated with this manifest.
# RootModule = ''

# Version number of this module.
ModuleVersion = '0.0.35'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'ef5bc6ff-7e6a-4e08-948d-42ecd3ed6055'

# Author of this module
Author = 'Nigel Tatschner'

# Company or vendor of this module
CompanyName = 'Tatux Solutions'

# Copyright statement for this module
Copyright = '(c) 2024 Nigel Tatschner. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Functions to perform telemetry collections for my suite of modules allowing for improvements to my code'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.1'

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @('tatux.telemetry.psm1')

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = '*'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @( 'Telemetry')

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/ntatschner/Tatux.Telemetry'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'Initial Release for telemetry module'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

