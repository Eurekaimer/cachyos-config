--- @since 26.8.15
-- dirsize: measure the recursive size of every directory listed on the current
-- page and publish the results into the file list, exactly like the built-in
-- folder spotter (<Tab>) does. Combine it with the `size` linemode to always
-- see how much space each folder occupies.
--
-- Setup in ~/.config/yazi/init.lua:
--     require("dirsize"):setup {}
--
-- Registration in ~/.config/yazi/yazi.toml:
--     [plugin]
--     fetchers = [
--         # ...
--         { url = "*/", run = "dirsize", prio = "low", group = "size" },
--     ]

local MAX_CACHE = 4096

-- ===== State shared between the fetcher and the sync context =====

--- Cached size of a directory, keyed by url and validated by its mtime.
local cache_read = ya.sync(function(state, url, mtime)
	local entry = state.cache and state.cache[url]
	if entry and entry.mtime == mtime then
		return entry.size
	end
end)

--- Claim a directory so concurrent fetchers never measure it twice.
local claim = ya.sync(function(state, url)
	state.sizing = state.sizing or {}
	if state.sizing[url] then
		return false
	end

	state.sizing[url] = true
	return true
end)

--- Release a claimed directory; `size` (if any) is remembered in the cache.
local release = ya.sync(function(state, url, mtime, size)
	if state.sizing then
		state.sizing[url] = nil
	end
	if size == nil then
		return
	end

	if not state.cache or state.total >= MAX_CACHE then
		state.cache, state.total, state.logged = {}, 0, {}
	end

	state.cache[url] = { mtime = mtime, size = size }
	state.total = state.total + 1
end)

--- True the first time a failing directory is reported, so that the error is
--- logged once rather than on every page refresh.
local log_once = ya.sync(function(state, url, mtime)
	state.logged = state.logged or {}
	if state.logged[url] == mtime then
		return false
	end

	state.logged[url] = mtime
	return true
end)

local cwd_read = ya.sync(function() return cx.active.current.cwd end)

-- ===== Measurement =====

--- Size of the directory `file`; returns nil and a reason when unavailable.
local function measure(file)
	local url, mtime = tostring(file.url), file.cha.mtime or 0

	local cached = cache_read(url, mtime)
	if cached ~= nil then
		return cached
	end

	if not claim(url) then
		return nil, "busy" -- a concurrent fetcher is already measuring it
	end

	local ok, size, err = pcall(function()
		local it, e = fs.calc_size(file.url)
		if not it then
			return nil, e
		end

		local total = 0
		while true do
			local next, e = it:recv()
			if not next then
				if e then
					return nil, e
				end
				return total
			elseif file.url.trail ~= cwd_read() then
				return nil, "aborted" -- the user has navigated away: stop the I/O
			end
			total = total + next
		end
	end)

	if ok then
		release(url, mtime, size)
		return size, err
	else
		release(url, mtime)
		return nil, size -- the pcall error
	end
end

-- ===== Fetcher =====

--- @type UnstableFetcher
local function fetch(_, job)
	return ya.co(function()
		for _, file in ipairs(job.files) do
			local cwd = cwd_read()
			if cwd ~= nil and file.url.trail == cwd then
				local size, err = measure(file)

				if size then
					ya.emit("update_files", {
						op = fs.op("size", { url = file.url.trail, sizes = { [file.url.key] = size } }),
					})
					ui.render()
				elseif err ~= "aborted" and err ~= "busy" and log_once(tostring(file.url), file.cha.mtime or 0) then
					ya.err(string.format("dirsize: cannot measure %s: %s", tostring(file.url), tostring(err)))
				end
			end

			-- Retried so the size is republished whenever the page refreshes
			-- (e.g. upon returning to this folder); a cache hit makes it cheap.
			coroutine.yield(file, { retry = true })
		end
	end)
end

return {
	setup = function(state)
		state.cache, state.total, state.logged = state.cache or {}, state.total or 0, {}
	end,

	fetch = fetch,
}
