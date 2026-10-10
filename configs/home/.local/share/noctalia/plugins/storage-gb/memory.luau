-- Host memory values are MiB; convert to decimal GB rather than relabeling GiB.
noctalia.setUpdateInterval(2000)
barWidget.setGlyph("cpu")

function update()
    local stats = noctalia.systemStats()
    if stats == nil or stats.ram == nil then
        barWidget.setText("N/A")
        barWidget.setTooltip("Memory sample unavailable")
        return
    end
    local ram = stats.ram
    local usedGb = ram.usedMb * 1048576 / 1000000000
    local totalGb = ram.totalMb * 1048576 / 1000000000
    barWidget.setText(string.format("%.1f GB", usedGb))
    barWidget.setTooltip({
        { "Memory used", string.format("%.1f GB", usedGb) },
        { "Memory total", string.format("%.1f GB", totalGb) },
        { "Usage", string.format("%.1f%%", ram.usagePercent) },
        { "Units", "GB = 1,000,000,000 bytes" },
    })
end

update()
