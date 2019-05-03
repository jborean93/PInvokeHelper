# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

$verbose = @{}
if ($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master") {
    $verbose.Add("Verbose", $true)
}

$ps_version = $PSVersionTable.PSVersion.Major
$cmdlet_name = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
$module_name = (Get-ChildItem -Path $PSScriptRoot\.. -Directory -Exclude @("Tests", "Docs")).Name
Import-Module -Name $PSScriptRoot\..\$module_name -Force

$dynamic_module = New-DynamicModule -Name PInvokeHelper.ImportPInvoke

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Import Win32 Function' {
            $create_file = @{
                DllName = 'Kernel32.dll'
                Name = 'CreateFileW'
                ReturnType = ([Microsoft.Win32.SafeHandles.SafeFileHandle])
                ParameterTypes = @(
                    @{
                        Type = ([System.String])
                        MarshalAs = @{
                            Type = [System.Runtime.InteropServices.UnmanagedType]::LPWStr
                        }
                    },
                    [System.Security.AccessControl.FileSystemRights],
                    [System.IO.FileShare],
                    [System.IntPtr],
                    [System.IO.FileMode],
                    [System.UInt32],
                    [System.IntPtr]
                )
                SetLastError = $true
            }
            $type_builder = $dynamic_module.DefineType(
                'ImportPInvoke.CreateFile',
                [System.Reflection.TypeAttributes]'Class, Public'
            )
            Import-PInvokeMethod -TypeBuilder $type_builder @create_file
            $type_builder.CreateType() > $null

            $file_handle = [ImportPInvoke.CreateFile]::CreateFileW(
                "C:\Windows\System32\cmd.exe",
                [System.Security.AccessControl.FileSystemRights]::Read,
                [System.IO.FileShare]::ReadWrite,
                [System.IntPtr]::Zero,
                [System.IO.FileMode]::Open,
                0,
                [System.IntPtr]::Zero
            ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

            try {
                $file_handle.IsInvalid | Should -Be $false
                $file_handle.IsClosed | Should -Be $false
                $err_code | Should -Be 0
            } finally {
                $file_handle.Dispose()
            }
            $file_handle.IsInvalid | Should -Be $false
            $file_handle.IsClosed | Should -Be $true

            # Again on a bad file
            $file_handle = [ImportPInvoke.CreateFile]::CreateFileW(
                "C:\fake file.txt",
                [System.Security.AccessControl.FileSystemRights]::Read,
                [System.IO.FileShare]::ReadWrite,
                [System.IntPtr]::Zero,
                [System.IO.FileMode]::Open,
                0,
                [System.IntPtr]::Zero
            ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

            try {
                $file_handle.IsInvalid | Should -Be $true
                $file_handle.IsClosed | Should -Be $false
                $err_code | Should -Be 2  # ERROR_FILE_NOT_FOUND
            } finally {
                $file_handle.Dispose()
            }
        }

        It 'Uses a ref parameter' {
            @(
                @{
                    Name = 'ImportPInvoke.ProcessCreationFlags'
                    Type = ([System.UInt32])
                    Flags = $true
                    Values = @{
                        DebugProcess = 0x00000001
                        DebugOnlyThisProcess = 0x00000002
                        Suspended = 0x00000004
                        DetachedProcess = 0x00000008
                        NewConsole = 0x00000010
                        NormalPriorityClass = 0x00000020
                        IdlePriorityClass = 0x00000040
                        HighPriorityclass = 0x00000080
                        RealtimePriorityClass = 0x00000100
                        NewProcessGroup = 0x00000200
                        UnicodeEnvironment = 0x00000400
                        SeparateWowVdm = 0x00000800
                        SharedWowVdm = 0x00001000
                        ForceDos = 0x00002000
                        BelowNormalPriorityClass = 0x00004000
                        AboveNormalPriorityClass = 0x00008000
                        InheritParentAffinity = 0x00010000
                        InheritCallerPriority = 0x00020000  # Deprecated
                        ProtectedProcess = 0x00040000
                        ExtendedStartupInfoPresent = 0x00080000
                        ProcessModeBackgroundBegin = 0x00100000
                        ProcessModeBackgroundEnd = 0x00200000
                        SecureProcess = 0x00400000
                        BreakawayFromJob = 0x01000000
                        PreserveCodeAuthzLevel = 0x02000000
                        DefaultErrorMode = 0x04000000
                        NoWindow = 0x08000000
                        ProfileUser = 0x10000000
                        ProfileKernel = 0x20000000
                        ProfileServer = 0x40000000
                        IgnoreSystemDefault = ([System.UInt32]'0x80000000')
                    }
                },
                @{
                    Name = 'ImportPInvoke.StartupInfoFlags'
                    Type = ([System.UInt32])
                    Flags = $true
                    Values = @{
                        UseShowWindow = 0x00000001
                        UseSize = 0x00000002
                        UsePosition = 0x00000004
                        UseCountChars = 0x00000008
                        UseFullAttribute = 0x00000010
                        RunFullScreen = 0x00000020
                        ForeOnFeedback = 0x00000040
                        ForceOffFeedback = 0x00000080
                        UseStdHandles = 0x00000100
                        UseHotkey = 0x00000200
                        TitleIsLinkName = 0x00000800
                        TitleIsAppId = 0x00001000
                        PreventPinning = 0x00002000
                        UntrustedSource = 0x00008000
                    }
                }
            ) | ForEach-Object -Process { Import-Enum -ModuleBuilder $dynamic_module @_ }

            @(
                @{
                    Name = 'ImportPInvoke.PROCESS_INFORMATION'
                    Fields = @(
                        @{
                            Name = 'hProcess'
                            Type = ([System.IntPtr])
                        },
                        @{
                            Name = 'hThread'
                            Type = ([System.IntPtr])
                        },
                        @{
                            Name = 'dwProcessId'
                            Type = ([System.UInt32])
                        },
                        @{
                            Name = 'dwThreadId'
                            Type = ([System.UInt32])
                        }
                    )
                },
                @{
                    Name = 'ImportPInvoke.STARTUPINFO'
                    Fields = @(
                        @{
                            Name = 'cb'
                            Type = ([System.UInt32])
                        },
                        @{
                            Name = 'lpReserved'
                            Type = ([System.String])
                            MarshalAs = @{
                                Type = [System.Runtime.InteropServices.UnmanagedType]::LPWStr
                            }
                        },
                        @{
                            Name = 'lpDesktop'
                            Type = ([System.String])
                            MarshalAs = @{
                                Type = [System.Runtime.InteropServices.UnmanagedType]::LPWStr
                            }
                        },
                        @{
                            Name = 'lpTitle'
                            Type = ([System.String])
                            MarshalAs = @{
                                Type = [System.Runtime.InteropServices.UnmanagedType]::LPWStr
                            }
                        },
                        @{
                            Name = 'dwX'
                            Type = ([System.UInt32])
                        },
                        @{
                            Name = 'dwY'
                            Type = ([System.UInt32])
                        },
                        @{
                            Name = 'dwXSize'
                            Type = ([System.UInt32])
                        },
                        @{
                            Name = 'dwYSize'
                            Type = ([System.UInt32])
                        },
                        @{
                            Name = 'dwXCountChars'
                            Type = ([System.UInt32])
                        },
                        @{
                            Name = 'dwYCountChars'
                            Type = ([System.UInt32])
                        },
                        @{
                            Name = 'dwFillAttribute'
                            Type = ([System.UInt32])
                        },
                        @{
                            Name = 'dwFlags'
                            Type = ([ImportPInvoke.StartupInfoFlags])
                        },
                        @{
                            Name = 'wShowWindow'
                            Type = ([System.UInt16])
                        },
                        @{
                            Name = 'cbReserved2'
                            Type = ([System.UInt16])
                        },
                        @{
                            Name = 'lpReserved2'
                            Type = ([System.Byte])
                        },
                        @{
                            Name = 'hStdInput'
                            Type = ([System.IntPtr])
                        },
                        @{
                            Name = 'hStdOutput'
                            Type = ([System.IntPtr])
                        },
                        @{
                            Name = 'hStdError'
                            Type = ([System.IntPtr])
                        }
                    )
                },
                @{
                    Name = 'ImportPInvoke.STARTUPINFOEX'
                    Fields = @(
                        @{
                            Name = 'StartupInfo'
                            Type = 'ImportPInvoke.STARTUPINFO'
                        },
                        @{
                            Name = 'lpAttributeList'
                            Type = ([System.IntPtr])
                        }
                    )
                }
            ) | ForEach-Object -Process { Import-Struct -ModuleBuilder $dynamic_module @_ }

            $create_process = @{
                DllName = 'Kernel32.dll'
                Name = 'CreateProcessW'
                ReturnType = @{
                    Type = ([System.Boolean])
                    MarshalAs = @{
                        Type = [System.Runtime.InteropServices.UnmanagedType]::Bool
                    }
                }
                ParameterTypes = @(
                    @{
                        Type = ([System.String])
                        MarshalAs = @{
                            Type = [System.Runtime.InteropServices.UnmanagedType]::LPWStr
                        }
                    },
                    [System.Text.StringBuilder],
                    [System.IntPtr],
                    [System.IntPtr],
                    [System.Boolean],
                    [ImportPInvoke.ProcessCreationFlags],
                    [System.IntPtr],
                    @{
                        Type = ([System.String])
                        MarshalAs = @{
                            Type = [System.Runtime.InteropServices.UnmanagedType]::LPWStr
                        }
                    },
                    @{ Ref = $true; Type = [ImportPInvoke.STARTUPINFOEX] },
                    @{ Ref = $true; Type = [ImportPInvoke.PROCESS_INFORMATION] }
                )
                SetLastError = $true
                CharSet = [System.Runtime.InteropServices.CharSet]::Unicode
            }

            $type_builder = $dynamic_module.DefineType(
                'ImportPInvoke.CreateProcess',
                [System.Reflection.TypeAttributes]'Class, Public'
            )
            Import-PInvokeMethod -TypeBuilder $type_builder @create_process
            $type_builder.CreateType() > $null

            $lp_application_name = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
            $lp_command_line = New-Object -TypeName System.Text.StringBuilder -ArgumentList @(
                "$lp_application_name -Command echo hi"
            )

            $creation_flags = [ImportPInvoke.ProcessCreationFlags]'NewConsole, UnicodeEnvironment'
            $si = New-Object -TypeName ImportPInvoke.STARTUPINFO
            $si.cb = [System.Runtime.InteropServices.Marshal]::SizeOf([Type][ImportPInvoke.STARTUPINFOEX])

            $si_ex = New-Object -TypeName ImportPInvoke.STARTUPINFOEX
            $si_ex.StartupInfo = $si

            $pi = New-Object -TypeName ImportPInvoke.PROCESS_INFORMATION

            $res = [ImportPInvoke.CreateProcess]::CreateProcessW(
                $lp_application_name,
                $lp_command_line,
                [System.IntPtr]::Zero,
                [System.IntPtr]::Zero,
                $false,
                $creation_flags,
                [System.IntPtr]::Zero,
                [NullString]::Value,
                [Ref]$si_ex,
                [Ref]$pi
            )

            $res | Should -Be $true
            $pi.dwProcessId | Should -Not -Be 0
            $pi.dwThreadId | Should -Not -Be 0
            [System.Int64]$pi.hProcess | Should -Not -Be 0
            [System.Int64]$pi.hThread | Should -Not -Be 0
        }

        It 'Uses SafeNativeHandle' {
            $type_builder = $dynamic_module.DefineType(
                'ImportPInvoke.SafeNativeHandle',
                [System.Reflection.TypeAttributes]'Class, Public'
            )
            $methods = @(
                @{
                    # https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-getcurrentprocess
                    DllName = 'Kernel32.dll'
                    Name = 'GetCurrentProcess'
                    ReturnType = ([PInvokeHelper.SafeNativeHandle])
                },
                @{
                    # https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-openprocesstoken
                    DllName = 'Advapi32.dll'
                    Name = 'OpenProcessToken'
                    ReturnType = ([System.Boolean])
                    ParameterTypes = @(
                        [System.IntPtr],
                        [System.Security.Principal.TokenAccessLevels],
                        @{ Ref = $true; Type = [PInvokeHelper.SafeNativeHandle] }
                    )
                    SetLastError = $true
                }
            ) | ForEach-Object -Process { Import-PInvokeMethod -TypeBuilder $type_builder @_ -PassThru }
            $type_builder.CreateType() > $null

            $methods.Length | Should -Be 2
            $methods[0].GetType().FullName | Should -Be 'System.Reflection.Emit.MethodBuilder'
            $methods[1].GetType().FullName | Should -Be 'System.Reflection.Emit.MethodBuilder'

            $h_process = [ImportPInvoke.SafeNativeHandle]::GetCurrentProcess()
            [System.Int64][System.IntPtr]$h_process | Should -Be -1

            $h_token = New-Object -TypeName PInvokeHelper.SafeNativeHandle
            $res = [ImportPInvoke.SafeNativeHandle]::OpenProcessToken(
                $h_process,
                [System.Security.Principal.TokenAccessLevels]::Query,
                [Ref]$h_token
            )
            $res | Should -Be $true

            try {
                $h_token.GetType().FullName | Should -be 'PInvokeHelper.SafeNativeHandle'
                $h_token.IsClosed | Should -Be $false
                $h_token.IsInvalid | Should -Be $false
            } finally {
                $h_token.Dispose()
            }
            $h_token.IsClosed | Should -Be $true
            $h_token.IsInvalid | Should -Be $false
        }
    }
}