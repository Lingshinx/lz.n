local M = {}

---@param spec lz.n.PluginSpec
---@return lz.n.Plugin
local function parse(spec)
    ---@type lz.n.Plugin
    ---@diagnostic disable-next-line: assign-type-mismatch
    local result = spec
    result.name = spec[1]
    result[1] = nil
    require("lz.n.handler").parse(result, spec)
    return result
end

---XXX: This is unsafe because we assume a prior `vim.islist` check
---
---@param spec lz.n.Spec
---@return boolean
local function is_list_with_single_spec_unsafe(spec)
    return #spec == 1 and type(spec[1]) == "table"
end

---@param spec lz.n.Spec
---@return boolean
function M.is_spec_list(spec)
    return #spec > 1 or vim.islist(spec) and #spec > 1 or is_list_with_single_spec_unsafe(spec)
end

---@param spec lz.n.Spec
---@return boolean
function M.is_single_plugin_spec(spec)
    return type(spec[1]) == "string"
end

---@private
---@param spec lz.n.Spec
---@param result table<string, lz.n.Plugin>
function M._normalize(spec, result)
    if M.is_spec_list(spec) then
        ---@param sp lz.n.Spec
        vim.iter(spec):each(function(sp)
            M._normalize(sp, result)
        end)
    elseif M.is_single_plugin_spec(spec) then
        ---@cast spec lz.n.PluginSpec
        result[spec[1]] = parse(spec)
    else
        error("unable to normalize plugin spec: " .. vim.inspect(spec))
    end
end

---@param result table<string, lz.n.Plugin>
local function remove_disabled_plugins(result)
    ---@param plugin lz.n.Plugin
    vim.iter(result):each(function(_, plugin)
        local disabled = plugin.enabled == false or (type(plugin.enabled) == "function" and not plugin.enabled())
        if disabled then
            result[plugin.name] = nil
        end
    end)
end

---@param spec lz.n.Spec
---@return table<string, lz.n.Plugin>
function M.parse(spec)
    local result = {}
    M._normalize(spec, result)
    remove_disabled_plugins(result)
    return result
end

return M
