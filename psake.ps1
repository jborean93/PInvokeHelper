[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "",
    Justification="Global vars are used outside of where they are declared")]
Param ()

Properties {
    # Find the build folder based on build system
    $ProjectRoot = $env:BHProjectPath
    if (-not $ProjectRoot) {
        $ProjectRoot = $PSScriptRoot
    }

    $nl = [System.Environment]::NewLine
    $lines = '----------------------------------------------------------------------'

    $Verbose = @{}
    if ($env:BHCommitMessage -match "!verbose") {
        $Verbose = @{ Verbose = $true }
    }
}

Task Default -Depends Build

Task Init {
    $lines
    Set-Location -LiteralPath $ProjectRoot
    "Build System Details:"
    Get-Item -Path env:BH*, env:APPVEYOR*

    $nl
}

Task Sanity -Depends Init {
    $lines
    "$nl`tSTATUS: Sanity tests with PSScriptAnalyzer"

    $pssa_params = @{
        ErrorAction = "SilentlyContinue"
        Path = "$ProjectRoot$([System.IO.Path]::DirectorySeparatorChar)"
        Recurse = $true
    }
    $results = Invoke-ScriptAnalyzer @pssa_params @verbose
    if ($null -ne $results) {
        $results | Out-String
        Write-Error "Failed PsScriptAnalyzer tests, build failed"
    }
    $nl
}

Task Test -Depends Sanity {
    $PSVersion = $PSVersionTable.PSVersion.Major

    $lines
    "$nl`tSTATUS: Testing with PowerShell $PSVersion"

    # Gather test results. Store them in a variable and file
    $public_path = [System.IO.Path]::Combine($env:BHModulePath, "Public")
    $private_path = [System.IO.Path]::Combine($env:BHModulePath, "Private")
    $code_coverage = [System.Collections.Generic.List`1[String]]@()
    if (Test-Path -LiteralPath $public_path) {
        $code_coverage.Add([System.IO.Path]::Combine($public_path, "*.ps1"))
    }
    if (Test-Path -LiteralPath $private_path) {
        $code_coverage.Add([System.IO.Path]::Combine($private_path, "*.ps1"))
    }

    $test_file = "TestResults_PS$PSVersion`_$(Get-Date -UFormat "%Y%m%d-%H%M%S").xml"
    $pester_params = @{
        CodeCoverage = $code_coverage.ToArray()
        OutputFile = [System.IO.Path]::Combine($ProjectRoot, $test_file)
        OutputFormat = "NUnitXml"
        PassThru = $true
        Path = [System.IO.Path]::Combine($ProjectRoot, "Tests")
    }
    $test_results  = Invoke-Pester @pester_params @Verbose

    if ($env:BHBuildSystem -eq 'AppVeyor') {
        $web_client = New-Object -TypeName System.Net.WebClient
        $web_client.UploadFile(
            "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
            [System.IO.Path]::Combine($ProjectRoot, $test_file)
        )
    }
    Remove-Item -LiteralPath ([System.IO.Path]::Combine($ProjectRoot, $test_file)) -Force -ErrorAction SilentlyContinue

    if ($test_results.FailedCount -gt 0) {
        Write-Error "Failed '$($test_results.FailedCount)' tests, build failed"
    }

    if ($env:BHBuildSystem -eq 'AppVeyor' -and (Get-Command -Name codecov.exe -ErrorAction Ignore)) {
        $ps_version = $PSVersionTable.PSVersion.ToString()
        $ps_edition = 'Desktop'
        if ($PSVersionTable.ContainsKey('PSEdition')) {
            $ps_edition = $PSVersionTable.PSEdition
        }
        $ps_platform = 'Win32NT'
        if ($PSVersionTable.ContainsKey('Platform')) {
            $ps_platform = $PSVersionTable.Platform
        }
        $coverage_id = "PowerShell-$ps_edition-$ps_version-$ps_platform"

        "$nl`tSTATUS: Uploading code coverage results with the ID: $coverage_id"

        # The file that is uploaded to CodeCov.io needs to be converted first.
        $coverage_file = [System.IO.Path]::Combine($ProjectRoot, "coverage.json")
        Export-CodeCovIoJson -CodeCoverage $test_results.CodeCoverage -RepoRoot $ProjectRoot -Path $coverage_file

        $upload_args = [System.Collections.Generic.List`1[System.String]]@(
            '-f',
            "`"$coverage_file`"",
            "-n",
            "`"$coverage_id`""
        )

        &codecov.exe $upload_args
        Remove-Item -LiteralPath $coverage_file -Force
    }
    $nl
}

Task Build -Depends Test {
    $module_name = (Get-ChildItem -Path ([System.IO.Path]::Combine($env:BHModulePath, '*.psd1'))).BaseName
    $build_path = [System.IO.Path]::Combine($ProjectRoot, "Build", $module_name)

    $lines
    "$nl`tSTATUS: Building PowerShell module with documentation to '$build_path'"

    if (Test-Path -LiteralPath $build_path) {
        Remove-Item -LiteralPath $build_path -Force -Recurse
    }
    New-Item -Path $build_path -ItemType Directory > $null

    Import-Module -Name $env:BHModulePath -Force

    # Ensure dir to store Markdown docs exists
    $doc_path = [System.IO.Path]::Combine($ProjectRoot, 'Docs')
    if (-not (Test-Path -LiteralPath $doc_path)) {
        New-Item -Path $doc_path -ItemType Directory > $null
    }

    $manifest_file_path = [System.IO.Path]::Combine($env:BHModulePath, "$($module_name).psd1")
    Copy-Item -LiteralPath $manifest_file_path -Destination ([System.IO.Path]::Combine($build_path, "$($module_name).psd1"))

    # Read the existing module and split out the template section lines.
    $module_file_path = [System.IO.Path]::Combine($env:BHModulePath, "$($module_name).psm1")
    $module_pre_template_lines = [System.Collections.Generic.List`1[String]]@()
    $module_template_lines = [System.Collections.Generic.List`1[String]]@()
    $module_post_template_lines = [System.Collections.Generic.List`1[String]]@()
    $template_section = $false  # $false == pre, $null == template, $true == post
    foreach ($module_file_line in (Get-Content -LiteralPath $module_file_path)) {
        if ($module_file_line -eq '### TEMPLATED EXPORT FUNCTIONS ###') {
            $template_section = $null
        } elseif ($module_file_line -eq '### END TEMPLATED EXPORT FUNCTIONS ###') {
            $template_section = $true
        } elseif ($template_section -eq $false) {
            $module_pre_template_lines.Add($module_file_line)
        } elseif ($template_section -eq $true) {
            $module_post_template_lines.Add($module_file_line)
        }
    }

    # Read each public and private function and add it to the manifest template
    $public_module_names = [System.Collections.Generic.List`1[String]]@()
    $public_functions_path = [System.IO.Path]::Combine($env:BHModulePath, 'Public')
    $private_functions_path = [System.IO.Path]::Combine($env:BHModulePath, 'Private')

    $public_functions_path, $private_functions_path | ForEach-Object -Process {

        if (Test-Path -LiteralPath $_) {
            Format-FunctionWithDoc -Path ([System.IO.Path]::Combine($_, "*.ps1")) | ForEach-Object -Process {

                $module_template_lines.Add($_.Function)
                $module_template_lines.Add("")  # Add an empty newline so the functions are spaced out.

                $parent = Split-Path -Path (Split-Path -Path $_.Source -Parent) -Leaf
                if ($parent -eq 'Public') {
                    $public_module_names.Add($_.Name)
                    $module_doc_path = [System.IO.Path]::Combine($doc_path, "$($_.Name).md")
                    Set-Content -LiteralPath $module_doc_path -Value $_.Markdown
                }
            }
        }
    }

    # Make sure we add an array of all the public functions and place it in our template. This is so the
    # Export-ModuleMember line at the end exports the correct functions.
    $module_template_lines.Add(
        "`$public_functions = @({0}    '{1}'{0})" -f ($nl, ($public_module_names -join "',$nl    '"))
    )

    # Now build the new manifest file lines by adding the templated and post templated lines to the 1 list.
    $module_pre_template_lines.AddRange($module_template_lines)
    $module_pre_template_lines.AddRange($module_post_template_lines)
    $module_file = $module_pre_template_lines -join $nl

    $dest_module_path = [System.IO.Path]::Combine($build_path, "$($module_name).psm1")
    Set-Content -LiteralPath $dest_module_path -Value $module_file

    $nl
}
