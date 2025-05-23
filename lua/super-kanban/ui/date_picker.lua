-- vim.api.nvim_create_user_command("DatePicker", open_calendar, {})
local utils = require("super-kanban.utils")
local hl = require("super-kanban.highlights")

---@class superkanban.DatePicker.NewOpts
---@field data? superkanban.DatePickerDataOpts
---@field row? number
---@field col? number
---@field relative? string

---@class superkanban.DatePicker.MountOpts
---@field on_select fun(date: superkanban.DatePickerData)
---@field on_close? fun()

---@class superkanban.DatePickerUI
---@field data superkanban.DatePickerData
---@field current_year integer
---@field current_month integer
---@field current_day integer
---@field win snacks.win
---@field border_win snacks.win
---@field win_opts {row:number,col:number,relative:string}
---@field type "date_picker"
---@overload fun(opts?:superkanban.DatePicker.NewOpts,config?:superkanban.Config): superkanban.TaskUI
local M = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
M.__index = M

---@type superkanban.Config
local config
local ns_date_picker = vim.api.nvim_create_namespace("super-kanban-date-picker")
local ns_date_under_cursor = vim.api.nvim_create_namespace("super-kanban-date-picker-current-date")

---@param year number
---@param month number
local function get_days_in_month(year, month)
	-- If month is December, next month is January of next year
	if month == 12 then
		year = year + 1
		month = 1
	else
		month = month + 1
	end

	-- Go to the first day of the next month, then subtract one day
	local last_day_of_month = os.time({ year = year, month = month, day = 1 }) - 86400
	return tonumber(os.date("%d", last_day_of_month))
end

---@param year number
---@param month number
---@return number -- returns weekday: 0=Sunday, 6=Saturday
local function get_start_day(year, month)
	---@diagnostic disable-next-line: return-type-mismatch
	return tonumber(os.date("%w", os.time({ year = year, month = month, day = 1 })))
end

local month_names = {
	"January",
	"February",
	"March",
	"April",
	"May",
	"June",
	"July",
	"August",
	"September",
	"October",
	"November",
	"December",
}

---@param month_number number
---@return string
local function get_month_name(month_number)
	return month_names[month_number]
end

---@param year number
---@param month number
---@return {[1]:string, [2]:string}[]
local function get_calander_title(year, month)
	local month_name = get_month_name(month)
	local f_str = " %s %s "
	return { { f_str:format(month_name, year), "KanbanDatePickerTitle" } }
end

---@param days_in_month number
---@param start_day number
local function get_calendar_lines(days_in_month, start_day, find_day)
	vim.validate("days_in_month", days_in_month, "number")
	local lines = {}
	local positions = { first_day = {}, last_day = {}, find_day = nil }

	local line_x = 0
	local line = {}
	local function add_to_line(day)
		line_x = line_x + 1
		table.insert(line, day)
	end

	for _ = 1, start_day do
		add_to_line("  ") -- Empty space for days before start
	end

	for day = 1, days_in_month do
		add_to_line(string.format("%2d", day))
		if day == 1 then
			local col = (line_x * 2) + (line_x - 2 * 1)
			local row = #lines + 1
			positions.first_day = { row = row, col = col }
		end
		if day >= 28 then
			local col = (line_x * 2) + (line_x - 2 * 1)
			local row = #lines + 1
			positions.last_day = { row = row, col = col }
		end
		if type(find_day) == "number" and find_day == day then
			local col = (line_x * 2) + (line_x - 2 * 1)
			local row = #lines + 1
			positions.find_day = { row = row, col = col }
		end

		if #line == 7 then
			table.insert(lines, table.concat(line, " "))
			line_x = 0
			line = {}
		end
	end
	-- last line
	if #line > 0 then
		table.insert(lines, table.concat(line, " "))
	end

	return lines, positions
end

---@param opts? superkanban.DatePicker.NewOpts
---@param conf? superkanban.Config
---@return superkanban.DatePickerUI
function M.new(opts, conf)
	local self = setmetatable({}, M)

	opts = opts or {}
	opts.data = opts.data or {}
	config = conf

	---@diagnostic disable-next-line: assign-type-mismatch
	self.current_year, self.current_month, self.current_day =
		tonumber(os.date("%Y")), tonumber(os.date("%m")), tonumber(os.date("%d"))
	-- self.current_year, self.current_month = 1970, tonumber(os.date("%m"))

	self.data = {
		year = opts.data.year or self.current_year,
		month = opts.data.month or self.current_month,
		day = opts.data.day or self.current_day,
	}

	self.win_opts = {
		col = opts.col or 2,
		row = opts.row or 0,
		relative = opts.relative or "cursor",
	}

	return self
end

---@param opts superkanban.DatePicker.MountOpts
function M:mount(opts)
	opts = opts or {}
	local days_in_month = get_days_in_month(self.data.year, self.data.month)
	local start_day = get_start_day(self.data.year, self.data.month)
	local lines, day_positions = get_calendar_lines(days_in_month, start_day, self.data.day)
	local weekdays = {
		{ { " Su Mo Tu We Th Fr Sa ", "KanbanDatePickerWeekDays" } },
		{ { " ──────────────────── ", "KanbanDatePickerSeparator" } },
	}

	local date_selected = false

	local function handle_on_select()
		local date = self:insert_date()
		if opts.on_select and date then
			date_selected = true
			opts.on_select(date)
			self:exit()
		end
	end

	local width = 20
	local height = #lines

	self.border_win = Snacks.win({
		relative = self.win_opts.relative,
		enter = false,
		zindex = 49,
		col = self.win_opts.col,
		row = self.win_opts.row,
		on_win = function()
			vim.schedule(function()
				self:render_border_win_lines(weekdays)
			end)
		end,
		on_close = function()
			self:exit()
		end,
		border = "rounded",
		width = width + 2,
		height = height + 2,
		title = get_calander_title(self.data.year, self.data.month),
		title_pos = "center",
		wo = {
			winhighlight = hl.date_picker,
		},
	})

	self.win = Snacks.win({
		relative = "win",
		win = self.border_win.win,
		zindex = 50,
		col = 1,
		row = #weekdays,
		border = "none",
		width = width,
		height = height,
		text = function()
			return lines
		end,
		on_win = function()
			vim.schedule(function()
				self:highlight_a_day(day_positions.find_day)
				self:set_events()
			end)
		end,
		on_close = function()
			self:exit()
			-- Call if user canceled and did not selelcted any date
			if not date_selected and opts.on_close then
				opts.on_close()
			end
		end,
		keys = {
			["<left>"] = { "ge", expr = true },
			["<right>"] = { "e", expr = true },
			h = { "ge", expr = true },
			l = { "e", expr = true },
			b = { "ge", expr = true },
			w = { "e", expr = true },
			["0"] = { "0e", expr = true },
			["."] = function()
				self:update_month(self.current_year, self.current_month, "find_day", self.current_day)
			end,
			n = function()
				self:next_month()
			end,
			p = function()
				self:prev_month()
			end,
			i = handle_on_select,
			o = handle_on_select,
		},
		wo = {
			winhighlight = hl.date_picker,
		},
	})
end

function M:exit()
	self.win:close()
	self.border_win:close()
end

---@param pos {row:integer,col:integer}
function M:highlight_a_day(pos)
	if not pos or not pos.row or not pos.col then
		return
	end
	vim.api.nvim_win_set_cursor(self.win.win, { pos.row, pos.col })
end

---@param year integer
---@param month integer
---@param focus? "first_day"|"last_day"|"find_day"
---@param find_a_day? integer
function M:update_month(year, month, focus, find_a_day)
	local days_in_month = get_days_in_month(year, month)
	local start_day = get_start_day(year, month)
	local lines, day_positions = get_calendar_lines(days_in_month, start_day, find_a_day)

	-- update height
	vim.api.nvim_win_set_height(self.win.win, #lines)
	vim.api.nvim_win_set_height(self.border_win.win, #lines + 2)

	self.border_win:set_title(get_calander_title(year, month))
	vim.api.nvim_buf_set_lines(self.win.buf, 0, -1, false, lines)
	if focus then
		self:highlight_a_day(day_positions[focus])
	end

	self.data.month = month
	self.data.year = year
end

function M:next_month()
	local year = self.data.year
	local month = self.data.month + 1
	if month > 12 then
		month = 1
		year = year + 1
	end

	self:update_month(year, month, "first_day")
end

function M:prev_month()
	local year = self.data.year
	local month = self.data.month - 1
	if month < 1 then
		month = 12
		year = year - 1
	end

	self:update_month(year, month, "last_day")
end

function M:insert_date()
	local day = self:extract_day_under_cursor()
	if not day then
		return
	end
	self.data.day = day

	return self.data
end

function M:cursor_show()
	vim.cmd("highlight! Cursor blend=NONE")
end

function M:cursor_hide()
	vim.cmd("highlight! Cursor blend=100")
end

function M:focus()
	self.win:focus()
end

function M:render_border_win_lines(weekdays)
	utils.render_lines(self.border_win.buf, ns_date_picker, weekdays, 0)
end

function M:extract_day_under_cursor()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	row = row - 1
	local line = vim.api.nvim_get_current_line()

	-- Match 2-character date fields (e.g., " 1", "22")
	for start_col = 1, #line - 1 do
		local substr = line:sub(start_col, start_col + 1)
		if substr:match("^ ?%d$") or substr:match("^%d%d$") then
			local end_col = start_col + 1
			if col >= start_col - 1 and col <= end_col - 1 then
				-- Extract number & trim space
				return tonumber(substr:match("%d+"))
			end
		end
	end

	return nil
end

function M:highlight_day_under_cursor()
	vim.api.nvim_buf_clear_namespace(0, ns_date_under_cursor, 0, -1) -- Clear previous extmarks

	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	row = row - 1 -- convert to 0-indexed
	local line = vim.api.nvim_get_current_line()

	local selected_date = nil

	-- Match 2-character date fields (e.g., " 1", "22")
	for start_col = 1, #line - 1 do
		local substr = line:sub(start_col, start_col + 1)
		if substr:match("^ ?%d$") or substr:match("^%d%d$") then
			local end_col = start_col + 2 - 1
			if col >= start_col - 1 and col <= end_col - 1 then
				vim.api.nvim_buf_set_extmark(0, ns_date_under_cursor, row, start_col - 1, {
					end_col = end_col,
					hl_group = "KanbanDatePickerDateHL",
				})

				-- Extract number & trim space
				selected_date = tonumber(substr:match("%d+"))
				break
			end
		end
	end

	if selected_date and selected_date > 0 then
		self.data.day = selected_date
	end
end

function M:set_events()
	self.border_win:on({ "BufEnter", "WinEnter" }, function()
		vim.schedule(function()
			self:focus()
		end)
	end, { buf = true })

	self.win:on({ "CursorMoved" }, function()
		vim.schedule(function()
			self:highlight_day_under_cursor()
		end)
	end, { buf = true })
end

-- local function open_date()
-- 	local picker = M.new()
-- 	picker:mount({
-- 		on_select = function(date)
-- 			dd(date)
-- 		end,
-- 		on_close = function()
-- 			dd("closed")
-- 		end,
-- 	})
-- end
-- open_date()

return M
