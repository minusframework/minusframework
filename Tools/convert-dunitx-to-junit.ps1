param (
    [Parameter(Mandatory)]
    [string]$InputFile,
    [string]$OutputFile
)

if (-not (Test-Path $InputFile)) {
    Write-Warning "File not found: $InputFile"
    exit 1
}

$xml = New-Object System.Xml.XmlDocument
try {
    $xml.Load($InputFile)
} catch {
    Write-Warning "Failed to parse XML: $_"
    exit 1
}

$root = $xml.DocumentElement
if ($root.LocalName -ne 'test-results') {
    Write-Warning "Unexpected root element: $($root.LocalName) (expected test-results)"
    exit 1
}

$total = [int]::Parse($root.GetAttribute('total'))
$failures = [int]::Parse($root.GetAttribute('failures'))
$errors = [int]::Parse($root.GetAttribute('errors'))
$skipped = [int]::Parse($root.GetAttribute('ignored'))

$junit = New-Object System.Xml.XmlDocument
$tsuites = $junit.CreateElement('testsuites')
$tsuites.SetAttribute('name', $root.GetAttribute('name'))
$tsuites.SetAttribute('tests', $total)
$tsuites.SetAttribute('failures', $failures)
$tsuites.SetAttribute('errors', $errors)
$tsuites.SetAttribute('skipped', $skipped)
$junit.AppendChild($tsuites) | Out-Null

function ProcessTestSuite($sourceNode, $parentElement) {
    if ($sourceNode.LocalName -ne 'test-suite') { return }

    $fixtureName = $sourceNode.GetAttribute('name')
    $suiteTime = $sourceNode.GetAttribute('time')

    $resultsNode = $sourceNode.ChildNodes |
        Where-Object { $_.LocalName -eq 'results' } |
        Select-Object -First 1
    if (-not $resultsNode) { return }

    $fixtureCount = 0
    $fixtureFailures = 0
    $fixtureErrors = 0
    $fixtureSkipped = 0
    $testCases = @()

    foreach ($child in $resultsNode.ChildNodes) {
        if ($child.LocalName -eq 'test-suite') {
            ProcessTestSuite $child $parentElement
        } elseif ($child.LocalName -eq 'test-case') {
            $tcName = $child.GetAttribute('name')
            $tcResult = $child.GetAttribute('result')
            $tcTime = $child.GetAttribute('time')
            $tcClassName = $fixtureName

            $tcElem = $junit.CreateElement('testcase')
            $tcElem.SetAttribute('name', $tcName)
            $tcElem.SetAttribute('classname', $tcClassName)
            if ($tcTime) { $tcElem.SetAttribute('time', $tcTime) }

            if (($tcResult -eq 'Failure') -or ($tcResult -eq 'Error') -or ($tcResult -eq 'MemoryLeak')) {
                $failureNode = $child.ChildNodes |
                    Where-Object { $_.LocalName -eq 'failure' } |
                    Select-Object -First 1
                if ($failureNode) {
                    $msgNode = $failureNode.ChildNodes |
                        Where-Object { $_.LocalName -eq 'message' } |
                        Select-Object -First 1
                    $stackNode = $failureNode.ChildNodes |
                        Where-Object { $_.LocalName -eq 'stack-trace' } |
                        Select-Object -First 1

                    $failElem = $junit.CreateElement('failure')
                    if ($msgNode) {
                        $failElem.SetAttribute('message', $msgNode.InnerText.Trim())
                    }
                    if ($stackNode) {
                        $failElem.InnerText = $stackNode.InnerText.Trim()
                    }
                    $tcElem.AppendChild($failElem) | Out-Null
                }
            } elseif ($tcResult -eq 'Ignored') {
                $reasonNode = $child.ChildNodes |
                    Where-Object { $_.LocalName -eq 'reason' } |
                    Select-Object -First 1
                if ($reasonNode) {
                    $msgNode = $reasonNode.ChildNodes |
                        Where-Object { $_.LocalName -eq 'message' } |
                        Select-Object -First 1
                    $skippedElem = $junit.CreateElement('skipped')
                    if ($msgNode) {
                        $skippedElem.SetAttribute('message', $msgNode.InnerText.Trim())
                    }
                    $tcElem.AppendChild($skippedElem) | Out-Null
                }
            }

            $testCases += $tcElem
            $fixtureCount++
            if ($tcResult -eq 'Failure') { $fixtureFailures++ }
            elseif ($tcResult -eq 'Error') { $fixtureErrors++ }
            elseif ($tcResult -eq 'Ignored') { $fixtureSkipped++ }
        }
    }

    if ($fixtureCount -gt 0) {
        $tsuite = $junit.CreateElement('testsuite')
        $tsuite.SetAttribute('name', $fixtureName)
        $tsuite.SetAttribute('tests', $fixtureCount)
        $tsuite.SetAttribute('failures', $fixtureFailures)
        $tsuite.SetAttribute('errors', $fixtureErrors)
        $tsuite.SetAttribute('skipped', $fixtureSkipped)
        if ($suiteTime) { $tsuite.SetAttribute('time', $suiteTime) }

        foreach ($tc in $testCases) {
            $tsuite.AppendChild($tc) | Out-Null
        }
        $parentElement.AppendChild($tsuite) | Out-Null
    }
}

foreach ($child in $root.ChildNodes) {
    ProcessTestSuite $child $tsuites
}

if (-not $OutputFile) {
    $OutputFile = [System.IO.Path]::ChangeExtension($InputFile, '.junit.xml')
}

$junit.Save($OutputFile)
Write-Host "Converted: $InputFile -> $OutputFile"
