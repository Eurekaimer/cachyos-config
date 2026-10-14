local M = {}
local store = require("config.leetcode_list_store")

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.ERROR, { title = "LeetCode 题单" })
end

local function signed_in()
  if require("leetcode.config").auth.is_signed_in then
    return true
  end
  notify("请先执行 :Leet，等待登录完成。", vim.log.levels.WARN)
end

-- Keep named frontend IDs intact; plain numeric IDs may also be space-separated.
local function parse_ids(text)
  local ids = {}
  for item in text:gsub("，", ","):gmatch("[^,\r\n]+") do
    item = vim.trim(item)
    if item:match("^%d[%d%s]*$") then
      for id in item:gmatch("%d+") do
        ids[#ids + 1] = id
      end
    elseif item ~= "" then
      ids[#ids + 1] = item
    end
  end
  return ids
end

function M.open(list)
  if not signed_in() then
    return
  end
  local by_id = {}
  for _, question in ipairs(require("leetcode.cache.problemlist").get()) do
    by_id[tostring(question.frontend_id)] = question
  end
  local questions, rows = {}, {}
  local missing = false
  for _, id in ipairs(list.ids) do
    local question = by_id[tostring(id)]
    rows[#rows + 1] = { id = tostring(id), question = question }
    if question then
      questions[#questions + 1] = question
    else
      missing = true
    end
  end
  if not missing then
    require("leetcode.picker").question(questions, {})
    return
  end
  local question_picker = require("leetcode.picker.question")
  for _, row in ipairs(rows) do
    row.text = row.question and question_picker.ordinal(row.question)
      or row.id .. ". [缺少缓存，暂无法打开]"
  end
  require("snacks.picker").pick({
    title = list.name,
    items = rows,
    layout = { preset = "select", preview = false },
    format = function(row)
      if not row.question then
        return { { row.text, "WarningMsg" } }
      end
      local columns = {}
      for _, column in ipairs(question_picker.entry(row.question)) do
        columns[#columns + 1] = type(column) == "table" and column or { column }
        columns[#columns + 1] = { " " }
      end
      return columns
    end,
    actions = {
      confirm = function(picker, row)
        if not row then
          return
        end
        if not row.question then
          notify("题号 " .. row.id .. " 缺少缓存；请执行 :Leet cache update，或检查题号。",
            vim.log.levels.WARN)
          return
        end
        picker:close()
        vim.schedule(function() question_picker.select(row.question) end)
      end,
    },
  })
end

local function save_as(list)
  vim.ui.input({ prompt = "题单名称（同名替换）：", default = list.name or "" }, function(name)
    if name == nil then
      return
    end
    list.name = vim.trim(name)
    local ok, err = store.save(list)
    if not ok then
      notify(err)
      return
    end
    M.show()
  end)
end

function M.create()
  vim.ui.input({ prompt = "网页题号（空格或逗号分隔）：" }, function(text)
    if text ~= nil then
      save_as({ ids = parse_ids(text) })
    end
  end)
end

function M.import_file()
  vim.ui.input({ prompt = "题号文件路径（每行一个题号或逗号分隔）：", completion = "file" }, function(path)
    if path == nil then
      return
    end
    path = vim.fn.expand(vim.trim(path))
    local ok, lines = pcall(vim.fn.readfile, path)
    if not ok then
      notify("无法读取题号文件：" .. tostring(lines))
      return
    end
    save_as({ name = vim.fn.fnamemodify(path, ":t:r"), ids = parse_ids(table.concat(lines, "\n")) })
  end)
end

function M.import_url()
  vim.ui.input({ prompt = "力扣题单 / 学习计划链接：" }, function(url)
    if url == nil then
      return
    end
    notify("正在获取题单…", vim.log.levels.INFO)
    require("config.leetcode_list_import").fetch(vim.trim(url), function(list, err)
      if not list then
        notify(err)
        return
      end
      if list.name == "Hot100" then
        list.name = "Hot100（在线）"
      end
      save_as(list)
    end)
  end)
end

function M.refresh()
  local lists, err = store.all()
  if not lists then
    notify(err)
    return
  end
  local online = vim.tbl_filter(function(list) return list.source ~= nil end, lists)
  if #online == 0 then
    notify("没有在线题单；请先导入题单链接。", vim.log.levels.INFO)
    return
  end
  vim.ui.select(online, {
    prompt = "刷新在线题单：",
    format_item = function(list) return list.name end,
  }, function(previous)
    if not previous then
      return
    end
    notify("正在刷新 " .. previous.name .. "…", vim.log.levels.INFO)
    require("config.leetcode_list_import").fetch(previous.source, function(list, fetch_err)
      if not list then
        notify(fetch_err) -- Keep the previous list when the request fails.
        return
      end
      list.name = previous.name
      local ok, save_err = store.save(list)
      if not ok then
        notify(save_err)
        return
      end
      notify("已更新 " .. list.name .. "（" .. #list.ids .. " 题）。", vim.log.levels.INFO)
      M.show()
    end)
  end)
end

function M.remove()
  local lists, err = store.all()
  if not lists then
    notify(err)
    return
  end
  table.remove(lists, 1) -- Built-in Hot100 cannot be removed.
  if #lists == 0 then
    notify("没有自定义题单。", vim.log.levels.INFO)
    return
  end
  vim.ui.select(lists, {
    prompt = "删除本地题单（不影响力扣网站）：",
    format_item = function(list) return list.name end,
  }, function(list)
    if not list then
      return
    end
    local ok, remove_err = store.remove(list.name)
    if not ok then
      notify(remove_err)
      return
    end
    M.show()
  end)
end

function M.show()
  if not signed_in() then
    return
  end
  local lists, err = store.all()
  if not lists then
    notify(err)
    return
  end
  local Page = require("leetcode-ui.group.page")
  local Button = require("leetcode-ui.lines.button.menu")
  local Buttons = require("leetcode-ui.group.buttons.menu")
  local page = Page()
  page:insert(require("leetcode-ui.lines.menu-header"))
  page:insert(require("leetcode-ui.lines.title")({ "Menu", "Problems" }, "题单"))
  local buttons = {}
  for index, list in ipairs(lists) do
    local text = list.name .. " (" .. #list.ids .. ")"
    buttons[#buttons + 1] = Button(text, {
      icon = "",
      width = math.max(50, vim.api.nvim_strwidth(text) + 5),
      sc = index == 1 and "h" or nil,
      on_press = function() M.open(list) end,
    })
  end
  for _, action in ipairs({
    { "按题号新建", "n", M.create },
    { "导入题号文件", "f", M.import_file },
    { "导入在线题单", "u", M.import_url },
    { "刷新在线题单", "r", M.refresh },
    { "删除本地题单", "x", M.remove },
  }) do
    buttons[#buttons + 1] = Button(action[1], { icon = "", sc = action[2], on_press = action[3] })
  end
  buttons[#buttons + 1] = require("leetcode-ui.lines.button.menu.back")("problems")
  page:insert(Buttons(buttons))
  page:insert(require("leetcode-ui.lines.footer"))
  package.loaded["leetcode-ui.group.page.problem_lists"] = page
  require("leetcode.command").set_menu_page("problem_lists")
end

function M.setup()
  require("leetcode.command").commands.lists = { M.show }
  local installed = false
  -- Wait for the plugin's CN translation and menu configuration to initialize.
  table.insert(require("leetcode.config").user.hooks.enter, function()
    if installed then
      return
    end
    local page = require("leetcode-ui.group.page.problems")
    for _, group in ipairs(page:contents()) do
      if group.class and group.class.name == "LeetMenuButtons" then
        local buttons = group:contents()
        table.insert(buttons, #buttons, require("leetcode-ui.lines.button.menu")("题单", {
          icon = "",
          sc = "l",
          expandable = true,
          on_press = M.show,
        }))
        group:replace(buttons)
        installed = true
        return
      end
    end
    notify("无法找到插件的题库菜单；请检查 leetcode.nvim 版本。")
  end)
end

return M
