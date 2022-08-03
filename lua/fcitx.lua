-- check fcitx-remote (fcitx5-remote)
local fcitx_cmd = ''
if vim.fn.executable('fcitx-remote') == 1 then
  fcitx_cmd = 'fcitx-remote'
elseif vim.fn.executable('fcitx5-remote') == 1 then
  fcitx_cmd = 'fcitx5-remote'
else
  return
end

if os.getenv('SSH_TTY') ~= nil then
  return
end

local os_name = vim.loop.os_uname().sysname
if (os_name == 'Linux' or os_name == 'Unix') and os.getenv('DISPLAY') == nil and os.getenv('WAYLAND_DISPLAY') == nil then
  return
end

local M = {}
local input_toggle_flag = false

-- execute a command and return its output
local function exec(cmd, ...)
    local handle = io.popen(table.concat({cmd, ...}, " "))
    if handle then
        local result = handle:read("*a")
        handle:close()
        return result
    else
        return nil
    end
end

local function en()
  local input_status = tonumber(exec(fcitx_cmd))
  if input_status == 2 then
    -- input_toggle_flag means whether to restore the state of fcitx
    input_toggle_flag = true
    -- switch to English input
    exec(fcitx_cmd, '-c')
  end
end

local function zh()
  if input_toggle_flag == true then
    -- switch to Non-Latin input
    exec(fcitx_cmd, '-o')
    input_toggle_flag = false
  end
end

local fcitx_au_id = vim.api.nvim_create_augroup("fcitx", {clear=true})
function M.setup()
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = fcitx_au_id,
    pattern = "*",
    callback = function () zh() end
  })
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = fcitx_au_id,
    pattern = "*",
    callback = function () en() end
  })
  vim.api.nvim_create_autocmd("CmdlineEnter", {
    group = fcitx_au_id,
    pattern = "[/\\?-]",
    callback = function () en() end
  })
  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = fcitx_au_id,
    pattern = "[/\\?-]",
    callback = function () zh() end
  })
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = fcitx_au_id,
    pattern = {"*:s", "*:S", "*:\19"},
    callback = function () en() end
  })
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = fcitx_au_id,
    pattern = {"s:*", "S:*", "\19:*"},
    callback = function () zh() end
  })
end

return M
