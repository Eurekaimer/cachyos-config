local M = {}

-- These are the web client's internal CN queries, not a stable public API.
local studyplan_query = [[
query studyPlanDetail($slug: String!) {
  studyPlanV2Detail(planSlug: $slug) {
    name
    planSubGroups { questions { questionFrontendId } }
  }
}
]]

local favorite_query = [[
query favoriteDetailV2($favoriteSlug: String!) {
  favoriteDetailV2(favoriteSlug: $favoriteSlug) { name questionNumber }
}
]]

local questions_query = [[
query favoriteQuestionList($favoriteSlug: String!, $limit: Int, $skip: Int) {
  favoriteQuestionList(favoriteSlug: $favoriteSlug, limit: $limit, skip: $skip, version: "v2") {
    questions { questionFrontendId }
    totalLength
    hasMore
  }
}
]]

local function valid_name(name)
  return type(name) == "string" and name:match("%S") ~= nil
end

local function append_ids(questions, ids, seen)
  if type(questions) ~= "table" or not vim.islist(questions) then
    return nil, "Unexpected API schema: questions is not an array"
  end
  for _, question in ipairs(questions) do
    local id = type(question) == "table" and question.questionFrontendId or nil
    if type(id) ~= "string" or not id:match("%S") then
      return nil, "Unexpected API schema: missing frontend question ID"
    end
    if seen[id] then
      return nil, "The list contains repeated frontend IDs; it may have changed during import"
    end
    seen[id] = true
    ids[#ids + 1] = id
  end
  return true
end

---Import a verified CN study plan or favorite using leetcode.nvim's authenticated async transport.
---@param url string
---@param callback fun(record: table|nil, error: string|nil)
function M.fetch(url, callback)
  local finished = false
  local function finish(record, err)
    if finished then
      return
    end
    finished = true
    vim.schedule(function()
      callback(record, err)
    end)
  end

  local kind, slug
  if type(url) == "string" then
    local path = url:match("^https://leetcode%.cn/([^?#]+)")
    if path then
      kind, slug = path:match("^([%a%-]+)/([%w_%-]+)/?$")
    end
  end
  if not slug or (kind ~= "studyplan" and kind ~= "problem-list" and kind ~= "favorite") then
    finish(nil, "Use https://leetcode.cn/studyplan/<slug>/ or https://leetcode.cn/problem-list/<slug>/ (legacy /favorite/<slug>/ is also accepted)")
    return
  end

  local loaded, utils = pcall(require, "leetcode.api.utils")
  if not loaded then
    finish(nil, "Open leetcode.nvim before importing a list")
    return
  end
  if require("leetcode.config").domain ~= "cn" then
    finish(nil, "Online list import currently supports only leetcode.cn; configure leetcode.nvim with cn.enabled = true")
    return
  end

  local function request(query, variables, consume)
    local ok = pcall(utils.query, query, variables, {
      endpoint = "/graphql/",
      retry = 0,
      raw = { "--max-time", "30" },
      on_error = function(err)
        finish(nil, "LeetCode network request failed (curl exit " .. tostring(err.exit) .. ")")
      end,
      callback = function(response, err)
        if finished then
          return
        end
        if err then
          if err.status == 401 or err.status == 403 then
            finish(nil, "LeetCode denied access: the list may be private, your login may have expired, or API access is restricted")
          else
            finish(nil, "LeetCode request failed: " .. tostring(err.msg or err.status or err.code))
          end
          return
        end
        if type(response) ~= "table" then
          finish(nil, "Unexpected API schema: response is not an object")
          return
        end
        if response.errors ~= nil and response.errors ~= vim.NIL then
          local messages = {}
          if type(response.errors) == "table" then
            for _, item in ipairs(response.errors) do
              if type(item) == "table" and type(item.message) == "string" then
                messages[#messages + 1] = item.message
              end
            end
          end
          if #messages > 0 then
            finish(nil, "LeetCode GraphQL error: " .. table.concat(messages, "; "))
            return
          elseif type(response.errors) ~= "table" or next(response.errors) ~= nil then
            finish(nil, "LeetCode returned malformed GraphQL errors")
            return
          end
        end
        if type(response.data) ~= "table" then
          finish(nil, "Unexpected API schema: missing GraphQL data")
          return
        end
        consume(response.data)
      end,
    })
    if not ok then
      finish(nil, "Could not start the LeetCode API request; ensure the plugin is initialized")
    end
  end

  if kind == "studyplan" then
    request(studyplan_query, { slug = slug }, function(data)
      local plan = data.studyPlanV2Detail
      if plan == nil or plan == vim.NIL then
        finish(nil, "Study plan not found or inaccessible")
        return
      end
      if type(plan) ~= "table" or not valid_name(plan.name)
        or type(plan.planSubGroups) ~= "table" or not vim.islist(plan.planSubGroups) then
        finish(nil, "Unexpected API schema: invalid study plan details")
        return
      end
      local ids, seen = {}, {}
      for _, group in ipairs(plan.planSubGroups) do
        local ok, err = append_ids(type(group) == "table" and group.questions or nil, ids, seen)
        if not ok then
          finish(nil, err)
          return
        end
      end
      if #ids == 0 then
        finish(nil, "The study plan is empty or its questions are inaccessible")
        return
      end
      finish({ name = plan.name, ids = ids, source = url })
    end)
    return
  end

  request(favorite_query, { favoriteSlug = slug }, function(data)
    local favorite = data.favoriteDetailV2
    if favorite == nil or favorite == vim.NIL then
      finish(nil, "Problem list not found or private/inaccessible; open the list with your configured LeetCode account")
      return
    end
    if type(favorite) ~= "table" or not valid_name(favorite.name)
      or type(favorite.questionNumber) ~= "number" or favorite.questionNumber < 0
      or favorite.questionNumber % 1 ~= 0 then
      finish(nil, "Unexpected API schema: invalid problem list details")
      return
    end
    if favorite.questionNumber == 0 then
      finish(nil, "The problem list is empty or its questions are inaccessible")
      return
    end

    local ids, seen = {}, {}
    local total
    local function page(skip)
      request(questions_query, { favoriteSlug = slug, limit = 50, skip = skip }, function(result)
        local list = result.favoriteQuestionList
        if list == nil or list == vim.NIL then
          finish(nil, "Problem list questions are private or inaccessible to your configured LeetCode account")
          return
        end
        if type(list) ~= "table" or type(list.totalLength) ~= "number"
          or list.totalLength < 0 or list.totalLength % 1 ~= 0 or type(list.hasMore) ~= "boolean" then
          finish(nil, "Unexpected API schema: invalid problem list pagination")
          return
        end
        if (total and total ~= list.totalLength) or list.totalLength ~= favorite.questionNumber then
          finish(nil, "Problem list size changed during import or some questions are inaccessible; import again")
          return
        end
        total = list.totalLength
        local ok, err = append_ids(list.questions, ids, seen)
        if not ok then
          finish(nil, err)
          return
        end
        if #ids == 0 then
          finish(nil, "The problem list is empty or its questions are inaccessible")
          return
        end
        if #ids > total or (list.hasMore and (#list.questions == 0 or #ids >= total)) then
          finish(nil, "Unexpected API schema: inconsistent problem list pagination")
        elseif list.hasMore then
          page(skip + #list.questions)
        elseif #ids ~= total then
          finish(nil, "Incomplete problem list response; some questions may be private or inaccessible")
        else
          finish({ name = favorite.name, ids = ids, source = url })
        end
      end)
    end
    page(0)
  end)
end

return M
