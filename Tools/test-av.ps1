Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DLL {
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern IntPtr LoadLibrary(string n);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool FreeLibrary(IntPtr h);
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Ansi)]
    public static extern IntPtr GetProcAddress(IntPtr h, string n);
    [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet=CharSet.Unicode)]
    public delegate int ConnFuncStdCall(string conn);
    [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet=CharSet.Unicode)]
    public delegate IntPtr PCharFuncStdCall();
    [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet=CharSet.Unicode)]
    public delegate int DiffFunc3Call(string a, string b, string c);
    public static Delegate MakeDelegate(IntPtr h, string n, System.Type t) {
        IntPtr a = GetProcAddress(h, n); if (a == IntPtr.Zero) return null;
        return Marshal.GetDelegateForFunctionPointer(a, t);
    }
    public static string CallPChar(IntPtr h, string n) {
        var d = (PCharFuncStdCall)MakeDelegate(h, n, typeof(PCharFuncStdCall));
        return d == null ? "(null)" : Marshal.PtrToStringUni(d());
    }
}
"@

$dllPath = Join-Path $PSScriptRoot "Win32\Debug\MinusMigrator_DLL.dll"
$fullPath = [System.IO.Path]::GetFullPath($dllPath)
Write-Host "DLL: $fullPath" -ForegroundColor Cyan

$h = [DLL]::LoadLibrary($fullPath)
if ($h -eq [IntPtr]::Zero) {
    $e = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    Write-Host "LoadLibrary FAIL: $e (0x$('{0:X8}' -f $e))" -ForegroundColor Red
    exit 1
}

try {
    $delInit = [DLL]::MakeDelegate($h, "mmInit", [DLL+ConnFuncStdCall])
    $delDiff = [DLL]::MakeDelegate($h, "mmDiffDatabases", [DLL+DiffFunc3Call])

    # Test 1: mmInit with invalid provider (should fail gracefully, no AV)
    Write-Host "1. mmInit(fake://test)" -NoNewline
    $rc = $delInit.Invoke("fake://test")
    if ($rc -eq -1) {
        $e = [DLL]::CallPChar($h, "mmGetLastError")
        Write-Host "  rc=$rc err='$e'" -ForegroundColor Green
    } else {
        Write-Host "  rc=$rc (unexpected)" -ForegroundColor Yellow
    }

    # Test 2: mmInit with valid but unknown provider (should also fail gracefully)
    Write-Host "2. mmInit(sqlite://:memory:)" -NoNewline
    $rc = $delInit.Invoke("sqlite://:memory:")
    if ($rc -eq -1) {
        $e = [DLL]::CallPChar($h, "mmGetLastError")
        Write-Host "  rc=$rc err='$e'" -ForegroundColor Yellow
    } else {
        Write-Host "  rc=$rc" -ForegroundColor Green
    }

    # Test 3: mmDiffDatabases with SQLite (should also connect)
    Write-Host "3. mmDiffDatabases(sqlite, sqlite)" -NoNewline
    $rc = $delDiff.Invoke("sqlite://:memory:", "sqlite://:memory:", "json")
    if ($rc -eq -1) {
        $e = [DLL]::CallPChar($h, "mmGetLastError")
        Write-Host "  rc=$rc err='$e'" -ForegroundColor Yellow
    } else {
        Write-Host "  rc=$rc" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Done"
}
finally {
    [DLL]::FreeLibrary($h)
}
