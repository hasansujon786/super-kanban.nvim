local M = {}

function M.get_default(x, default)
	return M.if_nil(x, default, x)
end

function M.if_nil(x, was_nil, was_not_nil)
	if x == nil then
		return was_nil
	else
		return was_not_nil
	end
end

---@param msg string
---@param level? "trace"|"debug"|"info"|"warn"|"error"
function M.msg(msg, level)
	vim.notify(msg, level, { title = "Super Kanban" })
end

---@param data superkanban.TaskData
function M.get_lines_from_task(data)
	local lines = { data.title or "" }

	if #data.tag > 0 then
		lines[2] = table.concat(data.tag, " ")
	end

	if #data.due > 0 then
		if lines[2] then
			lines[2] = lines[2] .. " " .. table.concat(data.due, " ")
		else
			lines[2] = table.concat(data.due, " ")
		end
	end

	return lines
end

---@param buf number
---@param ns integer
---@param lines table
---@param start_line? number 0-index
function M.render_lines(buf, ns, lines, start_line)
	start_line = start_line or 0
	local current_line = start_line

	for _, segments in ipairs(lines) do
		local line = ""
		local col = 0

		-- First pass to build full line
		for _, seg in ipairs(segments) do
			line = line .. seg[1]
		end

		-- Set line in buffer
		vim.api.nvim_buf_set_lines(buf, current_line, current_line + 1, false, { line })

		-- Second pass for highlights
		for _, seg in ipairs(segments) do
			local text, hl_group = seg[1], seg[2]
			vim.api.nvim_buf_set_extmark(buf, ns, current_line, col, {
				end_col = col + #text,
				hl_group = hl_group,
			})
			col = col + #text
		end

		current_line = current_line + 1
	end
end

---@param str string
---@param width number
function M.add_padding(str, width)
	local str_len = #str
	if str_len >= width then
		return str
	end

	local total_pad = width - str_len
	local left_pad = math.floor(total_pad / 2)
	local right_pad = total_pad - left_pad

	return string.rep(" ", left_pad) .. str .. string.rep(" ", right_pad)
end

---@param date {year:number,month:number,day:number}
---@return string
---@return boolean
function M.get_relative_time(date)
	if date.year < 100 then
		local current_year = os.date("*t").year
		local current_century = math.floor(current_year / 100) * 100
		date.year = current_century + date.year
	end

	local target_time = os.time({ year = date.year, month = date.month, day = date.day, hour = 0 })

	local now = os.date("*t")
	local current_time = os.time({ year = now.year, month = now.month, day = now.day, hour = 0 })

	local diff = os.difftime(target_time, current_time)
	local days = math.floor(diff / (60 * 60 * 24))
	local abs_days = math.abs(days)
	-- local years = math.floor(abs_days / 365)
	-- local months = math.floor((abs_days % 365) / 30)
	-- local remaining_days = abs_days % 30

	---@return string|nil
	local function pluralize(value, unit)
		if value == 0 then
			return nil
		end
		return value .. " " .. unit .. (value == 1 and "" or "s")
	end

	local formatted_days = nil
	if abs_days >= 365 then
		formatted_days = pluralize(math.floor(abs_days / 365), "year")
	elseif abs_days >= 30 then
		formatted_days = pluralize(math.floor(abs_days / 30), "month")
	else
		formatted_days = pluralize(abs_days % 30, "day")
	end

	local prefix = days == 0 and "today" or days > 0 and "In " or ""
	local suffix = days < 0 and " ago" or ""

	local result
	if days == 0 or formatted_days == nil then
		result = "Today"
	else
		result = prefix .. formatted_days .. suffix
	end

	local is_future = days > 0
	return result, is_future
end

---@param date_str string
function M.get_date_data_from_str(date_str)
	if not date_str then
		return nil
	end

	local year, month, day = date_str:match("(%d+)[,-/](%d+)[,-/](%d+)")
	return { year = tonumber(year), month = tonumber(month), day = tonumber(day) }
end

---@param date superkanban.DatePickerData
function M.format_to_date_str(date)
	local f_date = "@{%d/%d/%d}"
	return f_date:format(date.year, date.month, date.day)
end

function M.is_cursor_at_last_column(col)
	local line = vim.api.nvim_get_current_line()
	return col >= #line
end

function M.remove_char_at(str, col)
	return str:sub(1, col - 1) .. str:sub(col + 1)
end

function M.find_at_sign_before_cursor()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	if col == 0 then
		return false
	end

	local line = vim.api.nvim_get_current_line()
	local char_before = line:sub(col - 1, col) -- Lua strings are 1-based
	if char_before == " @" or col == 1 and char_before == "@" then
		return { row = row, col = col }
	end

	return false
end

function M.merge(default, override)
	return vim.tbl_extend("force", default, override)
end

local function remove_trailing_or_lonely_at_sign(str)
	-- Remove @ at the end of a word (e.g., "word@ "), but not emails
	str = str:gsub("(%w+)@(%s)", "%1%2")
	str = str:gsub("(%w+)@$", "%1")

	-- Remove lone @ (surrounded by spaces or at start/end)
	str = str:gsub("^[%s]*@[%s]*$", "") -- line is only "@"
	str = str:gsub("(%s)@(%s)", "%1%2") -- space @ space
	str = str:gsub("^@(%s)", "%1") -- starts with "@ "
	str = str:gsub("(%s)@$", "%1") -- ends with " @"
	return str
end

return M
