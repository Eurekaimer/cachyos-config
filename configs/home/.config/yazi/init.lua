-- dirsize.yazi: measure the recursive size of the visible folders in the
-- background; the results are published into the file list (see
-- plugins/dirsize.yazi/main.lua for the details and the yazi.toml fetcher).
require("dirsize"):setup {}

-- The `size` linemode only ever prints a size, so the column stays aligned and
-- readable. A directory whose size has not been measured yet stays blank
-- instead of falling back to its item count (which is shown in the status bar
-- instead, next to the name of the hovered entry).
function Linemode:size()
	local size = self._file:size()
	return size and ya.readable_size(size) or ""
end

-- Item count of the hovered directory, right after its name in the status bar.
Status:children_add(function(self)
	local h = self._current.hovered
	if not h or not h.cha.is_dir then
		return ""
	end

	local folder = self._tab:history(h.url)
	local count = folder and #folder.files
	if not count then
		return "" -- the directory has not been loaded yet
	end

	local text = count == 0 and "empty" or string.format("%d item%s", count, count == 1 and "" or "s")
	return ui.Line {
		ui.Span(" " .. text):style(th.status.overall:patch(ui.Style():fg("darkgray"))),
	}
end, 3250, Status.LEFT)
