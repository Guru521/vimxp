if _G.WORKSPACE_CONTEXT == 'nvim' then
  vim.keymap.set('n', '', '<cmd>luafile%<CR>', { silent = true })
  return
end

local project_root = vim.fn.getcwd()
local settings = _G.LSP_DEFAULT_SETTINGS
settings.settings.Lua.workspace.library = vim.list_extend(settings.settings.Lua.workspace.library, {
  project_root .. '/libs/?',
})

return settings
