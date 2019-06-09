# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

$ErrorActionPreference = 'Stop'

$module_name = (Get-ChildItem -Path ([System.IO.Path]::Combine($DeploymentRoot, 'Build', '*', '*.psd1'))).BaseName
$source_path = [System.IO.Path]::Combine($DeploymentRoot, 'Build', $module_name)

$nupkg_version = $env:APPVEYOR_BUILD_VERSION
if ((Test-Path -Path env:APPVEYOR_REPO_TAG) -and ([System.Boolean]::Parse($env:APPVEYOR_REPO_TAG))) {
    $tag_name = $env:APPVEYOR_REPO_TAG_NAME
    if ($tag_name[0] -eq 'v') {
        $nupkg_version = $tag_name.Substring(1)
    } else {
        $nupkg_version = $tag_name
    }
}

Deploy Module {
    By AppVeyorModule {
        FromSource $source_path
        To AppVeyor
        WithOptions @{
            SourceIsAbsolute = $true
            Version = $nupkg_version
        }
        Tagged AppVeyor
    }

    By PSGalleryModule {
        FromSource $source_path
        To PSGallery
        WithOptions @{
            ApiKey = $env:NugetApiKey
            SourceIsAbsolute = $true
        }
        Tagged Release
    }
}
