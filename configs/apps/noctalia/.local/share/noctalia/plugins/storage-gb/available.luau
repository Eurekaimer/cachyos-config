-- Decimal GB: one GB is 1,000,000,000 bytes. Reuse Noctalia's disk sampler.
noctalia.setUpdateInterval(10000)
barWidget.setGlyph("database")

local function gb(bytes)
    return string.format("%.1f GB", bytes / 1000000000)
end

function update()
    local disk = noctalia.diskStats("/")
    local boot = noctalia.diskStats("/boot")
    if disk == nil then
        barWidget.setText("不可用")
        barWidget.setTooltip("无法获取磁盘信息")
        return
    end

    local used = disk.totalBytes - disk.freeBytes
    barWidget.setText(gb(disk.availableBytes) .. " 可用")
    local rows = {
        { "文件系统", "/ (Btrfs)" },
        { "总容量", gb(disk.totalBytes) },
        { "已使用", gb(used) },
        { "可用空间", gb(disk.availableBytes) },
        { "使用率", string.format("%.1f%%", disk.usagePercent) },
        { "不可用的空闲空间", gb(disk.freeBytes - disk.availableBytes) },
        { "单位", "GB = 1,000,000,000 字节" },
    }
    if boot ~= nil then
        table.insert(rows, { "启动分区总容量", gb(boot.totalBytes) })
        table.insert(rows, { "启动分区可用空间", gb(boot.availableBytes) })
    end
    barWidget.setTooltip(rows)
end

update()
