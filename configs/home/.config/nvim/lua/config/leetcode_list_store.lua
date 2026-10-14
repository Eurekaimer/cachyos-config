local M = {}
local directory = vim.fn.stdpath("data") .. "/leetcode"
local filename = directory .. "/problem_lists.json"

local function text(value, label)
  if type(value) ~= "string" or vim.trim(value) == "" or value:find("%c") then
    return nil, label .. " must be a nonempty string without control characters"
  end
  return vim.trim(value)
end

local function record(value)
  if type(value) ~= "table" then
    return nil, "List must be a record with a name and an array of frontend IDs"
  end
  local name, err = text(value.name, "List name")
  if not name then
    return nil, err
  end
  if name == "Hot100" then
    return nil, "Hot100 is built in and cannot be overwritten or deleted"
  end
  if type(value.ids) ~= "table" or not vim.islist(value.ids) or #value.ids == 0 then
    return nil, "List must contain a nonempty array of frontend IDs"
  end
  local ids, seen = {}, {}
  for index, id in ipairs(value.ids) do
    if type(id) == "number" then
      if id <= 0 or id % 1 ~= 0 or id > 9007199254740991 then
        return nil, "Frontend ID at position " .. index .. " must be a positive integer or a named ID"
      end
      id = string.format("%.0f", id)
    end
    id, err = text(id, "Frontend ID at position " .. index)
    if not id then
      return nil, err
    end
    if id:match("^%d+$") then
      id = id:gsub("^0+", "")
      if id == "" then
        return nil, "Frontend ID at position " .. index .. " must be positive"
      end
    end
    if seen[id] then
      return nil, "Duplicate frontend ID: " .. id
    end
    seen[id] = true
    ids[#ids + 1] = id
  end
  local result = { name = name, ids = ids }
  if value.source ~= nil then
    result.source, err = text(value.source, "List source")
    if not result.source then
      return nil, err
    end
  end
  return result
end

local function read()
  local file, err, code = io.open(filename, "rb")
  if not file then
    if code == 2 then
      return { cn = {}, com = {} }
    end
    return nil, "Cannot read " .. filename .. ": " .. tostring(err)
  end
  local contents, read_err = file:read("*a")
  local closed, close_err = file:close()
  if not contents or not closed then
    return nil, "Cannot read " .. filename .. ": " .. tostring(read_err or close_err)
  end
  local ok, data = pcall(vim.json.decode, contents)
  if not ok or type(data) ~= "table" or not contents:match("^%s*{") then
    return nil, "Invalid JSON object in " .. filename .. "; fix or move this file before saving lists"
  end
  for _, domain in ipairs({ "cn", "com" }) do
    if data[domain] == nil then
      data[domain] = {}
    end
    if type(data[domain]) ~= "table" or not vim.islist(data[domain]) then
      return nil, "Invalid " .. domain .. " list array in " .. filename .. "; fix or move this file"
    end
    local names = {}
    for index, value in ipairs(data[domain]) do
      local valid, validation_err = record(value)
      if not valid then
        return nil, filename .. " (" .. domain .. " list " .. index .. "): " .. validation_err
      end
      if names[valid.name] then
        return nil, "Duplicate list name " .. valid.name .. " in " .. filename .. " (" .. domain .. ")"
      end
      names[valid.name] = true
      data[domain][index] = valid
    end
  end
  return data
end

local function write(data)
  local ok, encoded = pcall(vim.json.encode, data)
  if not ok then
    return nil, "Cannot encode lists for " .. filename .. ": " .. tostring(encoded)
  end
  local made, mkdir_err = pcall(vim.fn.mkdir, directory, "p")
  if not made then
    return nil, "Cannot create " .. directory .. ": " .. tostring(mkdir_err)
  end
  -- Rename a complete sibling file so a failed write never truncates saved lists.
  local temporary = filename .. ".tmp-" .. vim.fn.getpid()
  local written, status = pcall(vim.fn.writefile, { encoded }, temporary)
  if not written or status ~= 0 then
    vim.uv.fs_unlink(temporary)
    return nil, "Cannot write " .. temporary .. ": " .. tostring(status)
  end
  local renamed, rename_err = vim.uv.fs_rename(temporary, filename)
  if not renamed then
    vim.uv.fs_unlink(temporary)
    return nil, "Cannot replace " .. filename .. ": " .. tostring(rename_err)
  end
  return true
end

local function domain()
  return require("leetcode.config").is_cn and "cn" or "com"
end

function M.all()
  local data, err = read()
  if not data then
    return nil, err
  end
  local ids = {}
  for _, id in ipairs(require("config.leetcode_hot100")) do
    ids[#ids + 1] = tostring(id)
  end
  local lists = { { name = "Hot100", ids = ids } }
  for _, list in ipairs(data[domain()]) do
    lists[#lists + 1] = list
  end
  return lists
end

function M.save(value)
  local valid, err = record(value)
  if not valid then
    return nil, err
  end
  local data
  data, err = read()
  if not data then
    return nil, err
  end
  local lists = data[domain()]
  for index, list in ipairs(lists) do
    if list.name == valid.name then
      lists[index] = valid
      return write(data)
    end
  end
  lists[#lists + 1] = valid
  return write(data)
end

function M.remove(value)
  local name, err = text(value, "List name")
  if not name then
    return nil, err
  end
  if name == "Hot100" then
    return nil, "Hot100 is built in and cannot be overwritten or deleted"
  end
  local data
  data, err = read()
  if not data then
    return nil, err
  end
  local lists = data[domain()]
  for index, list in ipairs(lists) do
    if list.name == name then
      table.remove(lists, index)
      return write(data)
    end
  end
  return nil, "No saved list named " .. name .. " in the " .. domain() .. " domain"
end

return M
