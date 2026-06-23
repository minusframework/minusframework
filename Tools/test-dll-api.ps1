# Load via LoadLibrary + delegates (avoids .NET DllImport probing issues)
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
    public delegate int IntFuncStdCall();
    [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet=CharSet.Unicode)]
    public delegate int ConnFuncStdCall(string conn);
    [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet=CharSet.Unicode)]
    public delegate int ConnPathFuncStdCall(string conn, string path, int flag);
    [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet=CharSet.Unicode)]
    public delegate int LintFuncStdCall(string path);
    [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet=CharSet.Unicode)]
    public delegate int DiffFuncStdCall(string a, string b, string fmt);
    [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet=CharSet.Unicode)]
    public delegate int TagFuncStdCall(string tag, string conn);
    [UnmanagedFunctionPointer(CallingConvention.StdCall, CharSet=CharSet.Unicode)]
    public delegate IntPtr PCharFuncStdCall();

    public static Delegate MakeDelegate(IntPtr h, string name, Type t) {
        IntPtr addr = GetProcAddress(h, name);
        if (addr == IntPtr.Zero) return null;
        return Marshal.GetDelegateForFunctionPointer(addr, t);
    }

    public static string CallPChar(IntPtr h, string name) {
        var d = (PCharFuncStdCall)MakeDelegate(h, name, typeof(PCharFuncStdCall));
        if (d == null) return "(null)";
        return Marshal.PtrToStringUni(d());
    }
}
"@

$dllPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Win32\Debug\MinusMigrator_DLL.dll"
Write-Host "=== MinusMigrator DLL API Test ===" -ForegroundColor Cyan
Write-Host "DLL: $dllPath"
Write-Host ""

$h = [DLL]::LoadLibrary($dllPath)
if ($h -eq [IntPtr]::Zero) {
    $e = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    Write-Host "LoadLibrary failed: error $e (0x$('{0:X8}' -f $e))" -ForegroundColor Red
    exit 1
}

try {
    function PtrToStr([IntPtr]$p) { return [System.Runtime.InteropServices.Marshal]::PtrToStringUni($p) }

    $allOk = $true
    function Check([string]$n, $rc) {
        if ($rc -eq 0) {
            Write-Host "  [PASS] $n" -ForegroundColor Green
        } else {
            $e = [DLL]::CallPChar($h, "mmGetLastError")
            Write-Host "  [FAIL] $n : rc=$rc error='$e'" -ForegroundColor Red
            $global:allOk = $false
        }
    }

    # 1. mmVersion
    $ver = [DLL]::CallPChar($h, "mmVersion")
    Write-Host "[mmVersion] => $ver" -ForegroundColor Green

    # 2. mmGetLastError (should be empty initially)
    $err = [DLL]::CallPChar($h, "mmGetLastError")
    Write-Host "[mmGetLastError] initial => '$err'" -ForegroundColor Gray

    # 3. mmInit(sqlite://:memory:)
    Write-Host "[....] mmInit(sqlite://:memory:)" -NoNewline
    $delInit = [DLL]::MakeDelegate($h, "mmInit", [DLL+ConnFuncStdCall])
    if ($delInit) {
        $rc = $delInit.Invoke("sqlite://:memory:")
        Check "mmInit" $rc
    } else { Write-Host "  [SKIP] mmInit delegate null" -ForegroundColor Yellow }

    # 4. mmDiffDatabases (invalid) - should fail gracefully
    Write-Host "[....] mmDiffDatabases(invalid)" -NoNewline
    $delDiff = [DLL]::MakeDelegate($h, "mmDiffDatabases", [DLL+DiffFuncStdCall])
    if ($delDiff) {
        $rc = $delDiff.Invoke("invalid://bad", "alsoinvalid://bad", "json")
        if ($rc -ne 0) {
            Write-Host "  [PASS] mmDiffDatabases (expected fail)" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] mmDiffDatabases returned 0 unexpectedly" -ForegroundColor Red
            $allOk = $false
        }
    }
    else { Write-Host "  [SKIP] mmDiffDatabases delegate null" -ForegroundColor Yellow }

    # 5. mmLint (empty path)
    Write-Host "[....] mmLint(empty)" -NoNewline
    $delLint = [DLL]::MakeDelegate($h, "mmLint", [DLL+LintFuncStdCall])
    if ($delLint) {
        $rc = $delLint.Invoke("")
        Check "mmLint" $rc
    } else { Write-Host "  [SKIP] mmLint delegate null" -ForegroundColor Yellow }

    # 6. mmLintRules
    $rules = [DLL]::CallPChar($h, "mmLintRules")
    Write-Host "[mmLintRules] => OK ($($rules.Split("`n").Length) lines)" -ForegroundColor Green

    # 7. mmTag on SQLite
    Write-Host "[....] mmTag" -NoNewline
    $delTag = [DLL]::MakeDelegate($h, "mmTag", [DLL+TagFuncStdCall])
    if ($delTag) {
        $rc = $delTag.Invoke("test-tag", "sqlite://:memory:")
        Check "mmTag" $rc
    } else { Write-Host "  [SKIP] mmTag delegate null" -ForegroundColor Yellow }

    # 8. mmMigrate on SQLite (dry-run)
    Write-Host "[....] mmMigrate(sqlite://:memory:)" -NoNewline
    $delMigrate = [DLL]::MakeDelegate($h, "mmMigrate", [DLL+ConnPathFuncStdCall])
    if ($delMigrate) {
        $rc = $delMigrate.Invoke("sqlite://:memory:", "", 1)
        Check "mmMigrate(dry-run)" $rc
    } else { Write-Host "  [SKIP] mmMigrate delegate null" -ForegroundColor Yellow }

    # 9. Final mmGetLastError
    $err = [DLL]::CallPChar($h, "mmGetLastError")
    Write-Host "[mmGetLastError] final => '$err'" -ForegroundColor Gray

    Write-Host ""
    if ($allOk) {
        Write-Host "=== ALL TESTS PASSED ===" -ForegroundColor Green
    } else {
        Write-Host "=== SOME TESTS FAILED ===" -ForegroundColor Red
    }
}
finally {
    [DLL]::FreeLibrary($h)
    Write-Host "DLL unloaded" -ForegroundColor Gray
}
