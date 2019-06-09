# thanks to http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/

Function Resolve-Module {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [String]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Version]
        $Version
    )

    Begin {
        $input_modules = @{}
    }

    Process {
        $input_modules.Add($Name, $Version)
    }

    End {
        $modules = [System.String[]]$input_modules.Keys
        $versions = Find-Module -Name $modules -Repository PSGallery

        foreach ($module_name in $modules) {
            $module_version = $input_modules.$module_name
            $module = Get-Module -Name $module_name -ListAvailable
            Write-Verbose -Message "Resolving module $module_name"

            if ($module) {
                if ($null -eq $module_version) {
                    Write-Verbose -Message "Module $module_name is present, checking if version is the latest available"
                    $module_version = ($versions | Where-Object { $_.Name -eq $module_name } | `
                        Measure-Object -Property Version -Maximum).Maximum
                    $installed_version = ($module | Measure-Object -Property Version -Maximum).Maximum

                    $install = $installed_version -lt $module_version
                } else {
                    Write-Verbose -Message "Module $module_name is present, checking if version matched $module_version"
                    $version_installed = $module | Where-Object { $_.Version -eq $module_version }
                    $install = $null -eq $version_installed
                }

                if ($install) {
                    Write-Verbose -Message "Installing module $module_name at version $module_version"
                    Install-Module -Name $module_name -Force -SkipPublisherCheck -RequiredVersion $module_version
                }
                Import-Module -Name $module_name -RequiredVersion $module_version
            } else {
                Write-Verbose -Message "Module $module_name is not installed, installing"
                $splat_args = @{}
                if ($null -ne $module_version) {
                    $splat_args.RequiredVersion = $module_version
                }
                Install-Module -Name $module_name -Force -SkipPublisherCheck @splat_args
                Import-Module -Name $module_name -Force
            }
        }
    }
}

Write-Output -InputObject "Setting up build dependencies"
Get-PackageProvider -Name NuGet -ForceBootstrap > $null
if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne "Trusted") {
    Write-Verbose -Message "Setting PSGallery as a trusted repository"
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

@(
    'Psake',
    'PSCodeCovIo',
    'PSDeploy',
    'Pester',
    'BuildHelpers',
    'PSScriptAnalyzer'
) | Resolve-Module

Write-Output -InputObject "Setting build environment variables"
Set-BuildEnvironment -ErrorAction SilentlyContinue

Write-Output -InputObject "Starting build"
Invoke-psake .\psake.ps1
exit ( [int]( -not $psake.build_success ) )
