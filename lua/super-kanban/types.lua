---@class superkanban.DatePickerDataOpts
---@field year? integer
---@field month? integer
---@field day? integer

---@class superkanban.DatePickerData
---@field year integer
---@field month integer
---@field day integer

---@class superkanban.TaskData
---@field title string
---@field check string
---@field due string[]
---@field date? superkanban.DatePickerData|nil
---@field tag string[]

---@class superkanban.ListData
---@field title string
---@field complete_task? boolean
---@field tasks superkanban.TaskData[]

---@class superkanban.SourceData
---@field lists superkanban.ListData

---@class superkanban.List.Ctx :superkanban.ListUI[]
---@field cards superkanban.cardUI[]

---@class superkanban.Ctx
---@field ft superkanban.ft
---@field board superkanban.BoardUI
---@field archive? superkanban.ListData
---@field lists superkanban.List.Ctx[]
---@field source_path string
---@field config superkanban.Config
---@field location {list:number,card:number}

---@class superkanban.MarkdownConfig
---@field notes_dir string
---@field list_heading "h1"|"h2"|"h3"|"h4"|"h5"|"h6"
---@field default_template string[]
---@field header string[]
---@field footer string[]

---@alias WeekDay "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday"

---@alias superkanban.ft "markdown"|"org"

---@alias HighlightedText { [1]: string, [2]: string }
---@alias HighlightLine HighlightedText[]
