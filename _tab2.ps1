$MuMuManager = 'G:\Program Files\MuMu\emulator\MuMuPlayer-12.0\nx_main\MuMuManager.exe'

function Test-MuMuRunning {
    try {
        $raw = & $MuMuManager info -v 0 2>&1
        $info = $raw | ConvertFrom-Json
        return ($info.headless_pid -and $info.headless_pid -gt 0)
    } catch {
        return $false
    }
}

# 妫€娴婱uMu鏄惁杩愯锛屾湭杩愯鍒欏惎鍔?
if (-not (Test-MuMuRunning)) {
    Write-Host '[MuMu] 妯℃嫙鍣ㄦ湭杩愯锛屾鍦ㄥ惎鍔?..' -ForegroundColor Yellow
    & $MuMuManager api -v 0 launch_player
    $timeout = 120
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        Start-Sleep -Seconds 5
        $elapsed += 5
        if (Test-MuMuRunning) {
            Write-Host "[MuMu] 妯℃嫙鍣ㄥ凡鍚姩 (鑰楁椂 ${elapsed}s)" -ForegroundColor Green
            break
        }
        Write-Host "[MuMu] 绛夊緟妯℃嫙鍣ㄥ惎鍔?.. ${elapsed}s / ${timeout}s" -ForegroundColor Gray
    }
    if ($elapsed -ge $timeout) {
        Write-Host '[MuMu] 妯℃嫙鍣ㄥ惎鍔ㄨ秴鏃讹紝璇锋鏌ワ紒' -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host '[MuMu] 妯℃嫙鍣ㄥ凡鍦ㄨ繍琛屼腑' -ForegroundColor Green
}

# 妯℃嫙鍣ㄥ氨缁紝渚濇鎵ц杩炴帴銆佺鍙ｈ浆鍙戙€佸畨鍗撻儴缃?
Set-Location 'E:\Code\TG\TimeGuard'
npm run conmumu

# adb connect 鍚庣瓑寰呰繛鎺ョǔ瀹?
Start-Sleep -Seconds 3

# 绛夊緟 adb 璁惧 online
Write-Host '[ADB] 绛夊緟璁惧灏辩华...' -ForegroundColor Yellow
$adbTimeout = 60
$adbElapsed = 0
while ($adbElapsed -lt $adbTimeout) {
    Start-Sleep -Seconds 3
    $adbElapsed += 3
    $adbStatus = (adb devices 2>&1 | Select-String '127\.0\.0\.1:5555\s+(\S+)').Matches.Groups[1].Value
    if ($adbStatus -eq 'device') {
        Write-Host "[ADB] 璁惧宸插氨缁?(鑰楁椂 ${adbElapsed}s)" -ForegroundColor Green
        break
    }
    Write-Host "[ADB] 璁惧鏈氨缁?(鐘舵€? ${adbStatus})锛岀瓑寰呬腑... ${adbElapsed}s / ${adbTimeout}s" -ForegroundColor Gray
}
if ($adbElapsed -ge $adbTimeout) {
    Write-Host '[ADB] 璁惧灏辩华瓒呮椂锛屽皾璇曠户缁墽琛?..' -ForegroundColor Red
}

# 鎵ц adb forward锛屽甫閲嶈瘯
$forwardRetries = 3
$forwardOk = $false
for ($i = 1; $i -le $forwardRetries; $i++) {
    Write-Host "[Forward] 绗?${i} 娆℃墽琛?adb forward..." -ForegroundColor Yellow
    $result = adb -s 127.0.0.1:5555 forward tcp:5554 tcp:5555 2>&1
    Write-Host "[Forward] 杩斿洖: $result" -ForegroundColor Gray
    Start-Sleep -Seconds 2
    # 楠岃瘉 forward 鏄惁鐢熸晥
    try {
        $conn = New-Object System.Net.Sockets.TcpClient
        $conn.Connect('127.0.0.1', 5554)
        $conn.Close()
        Write-Host '[Forward] 绔彛杞彂宸茬敓鏁堬紒' -ForegroundColor Green
        $forwardOk = $true
        break
    } catch {
        Write-Host "[Forward] 绔彛 5554 浠嶄笉鍙揪锛岄噸璇曚腑..." -ForegroundColor Yellow
        # 鏂紑閲嶈繛 adb锛岃В鍐宠繛鎺ヤ笉绋冲畾闂
        adb disconnect 127.0.0.1:5555 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        adb connect 127.0.0.1:5555 2>&1 | Out-Null
        Start-Sleep -Seconds 3
    }
}
if (-not $forwardOk) {
    Write-Host '[Forward] 绔彛杞彂鏈€缁堟湭鎴愬姛锛屽皾璇曠户缁墽琛?..' -ForegroundColor Red
}

npm run android