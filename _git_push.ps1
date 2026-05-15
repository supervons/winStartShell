Set-Location 'c:\Users\super\Desktop\start'
$logFile = Join-Path $PSScriptRoot '_git_output.txt'

"=== GIT STATUS ===" | Out-File $logFile
git status 2>&1 | Out-File $logFile -Append

"=== GIT ADD ===" | Out-File $logFile -Append
git add -A 2>&1 | Out-File $logFile -Append

"=== GIT COMMIT ===" | Out-File $logFile -Append
git commit -m 'feat: add tab4(opencode) and tab5(gemini) windows' 2>&1 | Out-File $logFile -Append

"=== GIT PUSH ===" | Out-File $logFile -Append
git push 2>&1 | Out-File $logFile -Append

"=== DONE ===" | Out-File $logFile -Append
