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

# 检测MuMu是否运行，未运行则启动
if (-not (Test-MuMuRunning)) {
    Write-Host '[MuMu] 模拟器未运行，正在启动...' -ForegroundColor Yellow
    & $MuMuManager api -v 0 launch_player
    $timeout = 120
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        Start-Sleep -Seconds 5
        $elapsed += 5
        if (Test-MuMuRunning) {
            Write-Host "[MuMu] 模拟器已启动 (耗时 ${elapsed}s)" -ForegroundColor Green
            break
        }
        Write-Host "[MuMu] 等待模拟器启动... ${elapsed}s / ${timeout}s" -ForegroundColor Gray
    }
    if ($elapsed -ge $timeout) {
        Write-Host '[MuMu] 模拟器启动超时，请检查！' -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host '[MuMu] 模拟器已在运行中' -ForegroundColor Green
}

# 模拟器就绪，依次执行连接、端口转发、安卓部署
Set-Location 'E:\Code\TG\TimeGuard'
npm run conmumu

# adb connect 后等待连接稳定
Start-Sleep -Seconds 3

# 等待 adb 设备 online
Write-Host '[ADB] 等待设备就绪...' -ForegroundColor Yellow
$adbTimeout = 60
$adbElapsed = 0
while ($adbElapsed -lt $adbTimeout) {
    Start-Sleep -Seconds 3
    $adbElapsed += 3
    $adbStatus = (adb devices 2>&1 | Select-String '127\.0\.0\.1:5555\s+(\S+)').Matches.Groups[1].Value
    if ($adbStatus -eq 'device') {
        Write-Host "[ADB] 设备已就绪 (耗时 ${adbElapsed}s)" -ForegroundColor Green
        break
    }
    Write-Host "[ADB] 设备未就绪 (状态: ${adbStatus})，等待中... ${adbElapsed}s / ${adbTimeout}s" -ForegroundColor Gray
}
if ($adbElapsed -ge $adbTimeout) {
    Write-Host '[ADB] 设备就绪超时，尝试继续执行...' -ForegroundColor Red
}

# 执行 adb forward，带重试
$forwardRetries = 3
$forwardOk = $false
for ($i = 1; $i -le $forwardRetries; $i++) {
    Write-Host "[Forward] 第 ${i} 次执行 adb forward..." -ForegroundColor Yellow
    $result = adb -s 127.0.0.1:5555 forward tcp:5554 tcp:5555 2>&1
    Write-Host "[Forward] 返回: $result" -ForegroundColor Gray
    Start-Sleep -Seconds 2
    # 验证 forward 是否生效
    try {
        $conn = New-Object System.Net.Sockets.TcpClient
        $conn.Connect('127.0.0.1', 5554)
        $conn.Close()
        Write-Host '[Forward] 端口转发已生效！' -ForegroundColor Green
        $forwardOk = $true
        break
    } catch {
        Write-Host "[Forward] 端口 5554 仍不可达，重试中..." -ForegroundColor Yellow
        # 断开重连 adb，解决连接不稳定问题
        adb disconnect 127.0.0.1:5555 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        adb connect 127.0.0.1:5555 2>&1 | Out-Null
        Start-Sleep -Seconds 3
    }
}
if (-not $forwardOk) {
    Write-Host '[Forward] 端口转发最终未成功，尝试继续执行...' -ForegroundColor Red
}

npm run android
