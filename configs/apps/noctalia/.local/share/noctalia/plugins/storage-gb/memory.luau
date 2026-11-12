-- Host memory values are MiB; convert to decimal GB rather than relabeling GiB.
noctalia.setUpdateInterval(2000)
barWidget.setGlyph("cpu")

function update()
    local stats = noctalia.systemStats()
    if stats == nil or stats.ram == nil then
        barWidget.setText("不可用")
        barWidget.setTooltip("无法获取内存信息")
        return
    end
    local ram = stats.ram
    local usedGb = ram.usedMb * 1048576 / 1000000000
    local totalGb = ram.totalMb * 1048576 / 1000000000
    barWidget.setText(string.format("%.1f GB", usedGb))
    barWidget.setTooltip({
        { "已用内存", string.format("%.1f GB", usedGb) },
        { "内存总量", string.format("%.1f GB", totalGb) },
        { "使用率", string.format("%.1f%%", ram.usagePercent) },
        { "单位", "GB = 1,000,000,000 字节" },
    })
end

update()
