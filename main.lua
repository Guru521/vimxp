local http_modules = require('libs.http.init')
local Http = http_modules.Http
local View = http_modules.View
local Response = http_modules.Response
local Page = http_modules.Page
local Wait = require('libs.wait')

if _G.vimxp_server then
  _G.vimxp_server:close()
end

local server = Http.new('0.0.0.0', 12345)
    :with_view(View.new('/vimxp/api/v1/extract/')
      :with_get(function(request)
        local texts = request.query_params['texts']
        local commands = request.query_params['commands']
        local registers = request.query_params['registers']
        local position = request.query_params['position']
        local mappings = request.query_params['mappings']

        if texts and type(texts) ~= 'table' then
          texts = { texts }
        end
        if commands and type(commands) ~= 'table' then
          commands = { commands }
        end
        if registers and type(registers) ~= 'table' then
          registers = { registers }
        end

        if texts and commands and registers then
          texts = vim.tbl_map(function(text) return tostring(text) end, texts)
          commands = vim.tbl_map(function(command) return tostring(command) end, commands)
          registers = vim.tbl_map(function(register) return tostring(register) end, registers)

          local payload = vim.fn.json_encode({
            texts = texts,
            commands = commands,
            registers = registers,
            position =
                position,
            mappings = mappings
          })

          return Page.from_file('./templates/extract.html', { payload = payload })
        end

        return Page.from_file('./templates/extract.html', { payload = '' })
      end)
      :with_post(function(request, sock)
        local json = request:json(true)

        if not json or not json.texts or type(json.texts) ~= 'table' or not json.commands or type(json.commands) ~= 'table' or not json.registers or type(json.registers) ~= 'table' then
          local response = Response.new({ error = 'Invalid request' }, 400)

          Http.handle_response(response, sock)
          return response
        end

        local texts = json.texts
        local commands = json.commands
        local registers = json.registers
        local position = json.position or { line = 1, column = 1 }
        local mappings = json.mappings or false

        for _, register in ipairs(registers) do
          vim.fn.setreg(register, '')
        end

        local buffer = vim.api.nvim_create_buf(false, true)
        local win = vim.api.nvim_open_win(buffer, true, {
          relative = 'editor',
          width = 10,
          height = 10,
          col = 0,
          row = 0,
          style = 'minimal',
        })

        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, texts)
        vim.api.nvim_win_set_cursor(win, { position.line, position.column - 1 })

        _G.vimxp_buffer = buffer
        _G.vimxp_win = win

        local command = table.concat(commands, '')
        local converted_command = vim.api.nvim_replace_termcodes(command, true, false, true)

        local mode = mappings and 'm' or 'n'
        vim.api.nvim_feedkeys(converted_command, mode, false)

        Wait.until_non_blocking(1000,
          function()
            return #vim.tbl_filter(function(register)
              return vim.fn.getreg(register) ~= ''
            end, json.registers) == #json.registers
          end, function()
            local results = {}
            for _, register in ipairs(json.registers) do
              local value = vim.fn.getreg(register)
              table.insert(results, { register = register, value = value })
            end

            vim.api.nvim_win_close(_G.vimxp_win, true)
            vim.api.nvim_buf_delete(_G.vimxp_buffer, { force = true })

            _G.vimxp_win = nil
            _G.vimxp_buffer = nil

            local response = Response.new({ results = results }, 200)

            Http.handle_response(response, sock)
          end, 5)

        return Response.new({}, 200)
      end)
      :with_post_handles_sock(false)
    )

_G.vimxp_server = server
print('server started')
