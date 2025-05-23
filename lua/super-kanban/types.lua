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
---@field tag string[]

---@class superkanban.TaskListData
---@field title string
---@field tasks superkanban.TaskData[]

---@class superkanban.SourceData
---@field lists superkanban.TaskListData

---@class superkanban.TaskList.Ctx :superkanban.TaskListUI[]
---@field tasks superkanban.TaskUI[]

---@class superkanban.Ctx
---@field board superkanban.BoardUI
---@field lists superkanban.TaskList.Ctx[]
---@field source_path string
---@field config superkanban.Config

---@class superkanban.MarkdownConfig
---@field description_folder string
---@field list_head string
---@field due_head string
---@field due_style string
---@field tag_head string
---@field tag_style string
---@field header string[]
---@field footer string[]
