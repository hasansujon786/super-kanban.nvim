local M = {}

---@param conf superkanban.Config
function M.setup(conf)
  require('super-kanban.ui.board').setup(conf)
  require('super-kanban.ui.list').setup(conf)
  require('super-kanban.ui.card').setup(conf)
  require('super-kanban.ui.date_picker').setup(conf)
  require('super-kanban.ui.note_popup').setup(conf)
  require('super-kanban.ui.help').setup(conf)
end

return M
