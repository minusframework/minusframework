Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class S {
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern IntPtr LoadLibrary(string n);
}
"@
$p = Join-Path (Split-Path $PSScriptRoot -Parent) "Win32\Debug\MinusMigrator_DLL.dll"
$f = [System.IO.Path]::GetFullPath($p)
Write-Host "FullPath: $f"
Write-Host "Exists: $(Test-Path $f)"
$h = [S]::LoadLibrary($f)
if ($h -eq [IntPtr]::Zero) {
    $e = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    Write-Host "LoadLibrary: FAIL error $e (0x$('{0:X8}' -f $e))"
} else {
    Write-Host "LoadLibrary: OK"
}
