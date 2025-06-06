---@class ScreenkeySubcmd
---@field impl fun(args:string[], data: table) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] Command completions callback, taking the lead of the subcommand's arguments

local api = vim.api

-- initialize the global variables (only once)
if vim.g.screenkey_ns_id ~= nil then
    -- already initialized
    return
end

---@type integer
vim.g.screenkey_ns_id = api.nvim_create_namespace("screenkey")
---@type integer
vim.g.screenkey_bufnr = -1
---@type integer
vim.g.screenkey_winnr = -1

---@type table<string, ScreenkeySubcmd>
local subcmds = {
    toggle_statusline_component = {
        impl = function(args, data)
            if #args > 0 then
                vim.notify(
                    ("Screenkey %s: command does not accept arguments"):format(data.fargs[1]),
                    vim.log.levels.ERROR
                )
                return
            end
            require("screenkey").toggle_statusline_component()
        end,
    },
    toggle = {
        impl = function(args, data)
            if #args > 0 then
                vim.notify(
                    ("Screenkey %s: command does not accept arguments"):format(data.fargs[1]),
                    vim.log.levels.ERROR
                )
                return
            end
            require("screenkey").toggle()
        end,
    },
    redraw = {
        impl = function(args, data)
            if #args > 0 then
                vim.notify(
                    ("Screenkey %s: command does not accept arguments"):format(data.fargs[1]),
                    vim.log.levels.ERROR
                )
                return
            end
            require("screenkey").redraw()
        end,
    },
    log = {
        impl = function(args, data)
            if #args == 0 then
                vim.notify(
                    ("Screenkey %s: no arguments provided"):format(data.fargs[1]),
                    vim.log.levels.ERROR
                )
                return
            end
            if #args > 2 then
                vim.notify(
                    ("Screenkey %s: too many arguments"):format(data.fargs[1]),
                    vim.log.levels.ERROR
                )
                return
            end

            local log = require("screenkey.logger")
            if args[1] == "max_lines" then
                if #args ~= 2 then
                    vim.notify(
                        "Screenkey log max_lines: Should be -> Screenkey log max_lines <number>",
                        vim.log.levels.ERROR
                    )
                    return
                end
                log:set_max_lines(tonumber(args[2]) or 50)
                return
            elseif #args > 1 then
                vim.notify(
                    ("Screenkey %s: too many arguments"):format(data.fargs[1]),
                    vim.log.levels.ERROR
                )
                return
            end

            if args[1] == "show" then
                log:show()
            elseif args[1] == "start" then
                log:enable()
            elseif args[1] == "stop" then
                log:disable()
            elseif args[1] == "clear" then
                log:clear()
            else
                vim.notify(
                    ("Screenkey %s: Unknown command %s"):format(data.fargs[1], args[1]),
                    vim.log.levels.ERROR
                )
            end
        end,
        complete = function(subcmd_arg_lead)
            local log_args = {
                "start",
                "stop",
                "show",
                "clear",
                "max_lines",
            }
            return vim.iter(log_args)
                :filter(function(log_arg)
                    return log_arg:find(subcmd_arg_lead) ~= nil
                end)
                :totable()
        end,
    },
}

local function screenkey_cmd(data)
    local fargs = data.fargs
    -- NOTE: :Screenkey is the same as :Screenkey toggle
    if #fargs == 0 then
        require("screenkey").toggle()
        return
    end
    local subcommand_key = fargs[1]
    -- get the subcommand's arguments, if any
    local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
    local subcmd = subcmds[subcommand_key]
    if not subcmd then
        vim.notify("Screenkey: Unknown command: " .. subcommand_key, vim.log.levels.ERROR)
        return
    end
    -- invoke the subcommand
    subcmd.impl(args, data)
end

local function screenkey_cmd_completion(arg_lead, cmdline, _)
    -- get the subcommand
    local subcmd_key, subcmd_arg_lead = cmdline:match("^Screenkey%s(%S+)%s(.*)$")
    if subcmd_key and subcmd_arg_lead and subcmds[subcmd_key] and subcmds[subcmd_key].complete then
        -- the subcommand has completions, return them
        return subcmds[subcmd_key].complete(subcmd_arg_lead)
    end
    -- check if cmdline is a subcommand
    if cmdline:match("^Screenkey%s+%w*$") then
        -- filter subcommands that match
        local subcommand_keys = vim.tbl_keys(subcmds)
        return vim.iter(subcommand_keys)
            :filter(function(key)
                return key:find(arg_lead) ~= nil
            end)
            :totable()
    end
end

api.nvim_create_user_command("Screenkey", screenkey_cmd, {
    desc = "Toggle Screenkey or invoke some other Screenkey functionality.",
    complete = screenkey_cmd_completion,
    nargs = "*",
})
