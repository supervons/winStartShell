Set-Location 'c:\Users\super\Desktop\start'
$logFile = Join-Path $PSScriptRoot '_git_output.txt'

"=== GIT STATUS ===" | Out-File $logFile -Encoding UTF8
git status 2>&1 | Out-File $logFile -Append -Encoding UTF8

"=== GIT ADD ===" | Out-File $logFile -Append -Encoding UTF8
git add -A 2>&1 | Out-File $logFile -Append -Encoding UTF8

"=== GIT COMMIT ===" | Out-File $logFile -Append -Encoding UTF8
git commit -m 'feat: update tab5 to stt:ws, fix tab2 UTF-8 BOM encoding, remove quota-hub window set' 2>&1 | Out-File $logFile -Append -Encoding UTF8

"=== GIT PUSH ===" | Out-File $logFile -Append -Encoding UTF8
git push 2>&1 | Out-File $logFile -Append -Encoding UTF8

"=== DONE ===" | Out-File $logFile -Append -Encoding UTF8
