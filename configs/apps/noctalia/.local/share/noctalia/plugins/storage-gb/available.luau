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
        barWidget.setText("N/A")
        barWidget.setTooltip("Storage sample unavailable")
        return
    end

    local used = disk.totalBytes - disk.freeBytes
    barWidget.setText(gb(disk.availableBytes) .. " free")
    local rows = {
        { "Filesystem", "/ (Btrfs)" },
        { "Total", gb(disk.totalBytes) },
        { "Used", gb(used) },
        { "Available", gb(disk.availableBytes) },
        { "Usage", string.format("%.1f%%", disk.usagePercent) },
        { "Unavailable free space", gb(disk.freeBytes - disk.availableBytes) },
        { "Units", "GB = 1,000,000,000 bytes" },
    }
    if boot ~= nil then
        table.insert(rows, { "Boot total", gb(boot.totalBytes) })
        table.insert(rows, { "Boot available", gb(boot.availableBytes) })
    end
    barWidget.setTooltip(rows)
end

update()
