local constants = require('super-kanban.constants')
local ts = vim.treesitter
local ts_query = vim.treesitter.query

-- Tree-sitter query to extract tasks and headings
local query = ts_query.parse(
  'markdown',
  [[
  (atx_heading (atx_h2_marker) (inline) @heading_text)

  (list_item
    [
      (task_list_marker_checked)
      (task_list_marker_unchecked)
    ] @checkbox
    (paragraph (inline) @task_text))

  (paragraph
    (inline) @maybe_bold)
  ]]
)
-- (atx_heading (inline) @heading_text)

--------------------------------------------------
---- Markdown Parser -----------------------------
--------------------------------------------------
local parser = {}

---@param text string
function parser.create_list_data(text)
  return { title = text, tasks = {} }
end

function parser.parse_data_from_task_text(raw)
  local tags = {}
  local due = {}

  -- extract tags
  local title = raw:gsub('#%S+', function(tag)
    table.insert(tags, tag) -- tag:sub(2) remove '#' prefix
    return ''
  end)

  -- extract dates
  title = title:gsub('(@{%d+[,-/]%d%d?[,-/]%d%d?})', function(date)
    table.insert(due, date)
    return ''
  end)

  -- clean up spaces
  title = title:gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1')

  return title, tags, due
end

---@param text string
---@param checkbox string
function parser.create_task_data(text, checkbox)
  local title, tags, due, date_obj = require('super-kanban.utils.text').extract_task_data_from_str(text)

  local task = {
    raw = text,
    title = title,
    check = checkbox and checkbox:match('%[(.-)%]') or ' ',
    due = due or {},
    tag = tags or {},
    date = date_obj,
  }

  return task
end

function parser.create_scratch_buffer(filepath)
  -- Load file content from path
  local lines = {}
  for line in io.lines(filepath) do
    table.insert(lines, line)
  end
  -- Create a scratch buffer and load lines
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  return buf
end

local M = {}

---@param filepath string
---@return superkanban.SourceData?
function M.parse_file(filepath)
  local buf = parser.create_scratch_buffer(filepath)
  local md_parser = ts.get_parser(buf, 'markdown')
  if not md_parser then
    return nil
  end

  local tree = md_parser:parse()[1]
  local root = tree:root()

  ---@type integer|string,integer|string
  local list_index, list_index_before_archive = 0, 0
  ---@type superkanban.SourceData
  local data = {
    lists = {},
  }

  -- Temporarily hold task info until both parts are seen
  local pending_task = {}

  -- Iterate query captures
  for id, node in query:iter_captures(root, buf) do
    local name = query.captures[id]
    local text = ts.get_node_text(node, buf)

    if name == 'heading_text' then
      -- Store the archive data into archive key
      if text == constants.archive_heading then
        list_index_before_archive = list_index
        list_index = 'archive'
      else
        if type(list_index) == 'string' then
          list_index = list_index_before_archive
        end
        list_index = list_index + 1
      end
      data.lists[list_index] = parser.create_list_data(text)
    elseif #data.lists[list_index].tasks == 0 and name == 'maybe_bold' and text:match('^%*%*.+%*%*$') then
      -- Parse bold text with Complete
      if text == constants.list_auto_complete_mark then
        data.lists[list_index].complete_task = true
      end
    elseif name == 'checkbox' then
      pending_task.checkbox = text
    elseif name == 'task_text' then
      table.insert(data.lists[list_index].tasks, parser.create_task_data(text, pending_task.checkbox))
      pending_task = {}
    end
  end

  -- Delete the buffer once done
  vim.api.nvim_buf_delete(buf, { force = true })
  return data
end

--------------------------------------------------
---- Markdown Writer -----------------------------
--------------------------------------------------
local writer = {}

function writer.format_task_list_items(items)
  if #items > 0 then
    return ' ' .. table.concat(items, ' ')
  end
  return ''
end

---@param data superkanban.TaskData
function writer.format_md_checklist(data)
  local tag = writer.format_task_list_items(data.tag)
  local due = writer.format_task_list_items(data.due)
  return string.format('- [%s] %s%s%s\n', data.check, data.title, tag, due)
end

---@param ctx superkanban.Ctx
function M.write_file(ctx)
  local file = io.open(ctx.source_path, 'w')
  if not file then
    require('super-kanban.utils').msg("Can't open file.", 'error')
    return nil
  end

  local new_lines = {}

  for _, list_section in ipairs(ctx.lists) do
    -- Add heading
    table.insert(new_lines, string.format('%s %s\n', '##', list_section.data.title))

    -- Add Complete mark
    if list_section.complete_task then
      table.insert(new_lines, constants.list_auto_complete_mark .. '\n')
    end

    -- Add checklist
    for _, card in ipairs(list_section.cards) do
      table.insert(new_lines, writer.format_md_checklist(card.data))
    end
  end

  if ctx.archive and ctx.archive.title == constants.archive_heading then
    table.insert(new_lines, '\n***\n')

    -- Add heading
    table.insert(new_lines, string.format('%s %s\n', '##', ctx.archive.title))

    -- Add checklist
    for _, task_data in ipairs(ctx.archive.tasks) do
      table.insert(new_lines, writer.format_md_checklist(task_data))
    end
  end

  for _, line in ipairs(new_lines) do
    file:write(line .. '\n')
  end
  file:close()
end

-- local filepath = "test.md"
-- local data = M:parse_file(filepath)
-- M:write_file(filepath, data)

-- -- Print the result
-- for _, list in ipairs(data) do
-- 	print("## " .. list.title)
-- 	for _, task in ipairs(list.tasks) do
-- 		print("- " .. task.check .. " " .. task.title)
-- 	end
-- end

return M
