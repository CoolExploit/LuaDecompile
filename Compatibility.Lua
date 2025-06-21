-- Compatibility.lua - Pure Function Capability Checker (No Executor Branding)

local Compatibility = {}
Compatibility.__index = Compatibility

-- Function lists to scan
local CORE_FUNCTIONS = {
    "getscriptbytecode", "getconstants", "getprotos", "getupvalues",
    "getdownvalues", "setupvalue", "setconstant", "setupvalue", "setdownvalue",
    "iscclosure", "islclosure", "checkclosure", "newcclosure",
    "getinfo", "hookfunction", "hookmetamethod",
    "getnamecallmethod", "setnamecallmethod", "getreg", "getgc",
    "getgenv", "getfenv", "setfenv", "loadstring", "checkcaller",
    "newlclosure", "dumpstring", "decompile", "disassemble"
}

local DEBUG_FUNCTIONS = {
    "debug.getinfo", "debug.getlocal", "debug.setlocal",
    "debug.getupvalue", "debug.setupvalue",
    "debug.getmetatable", "debug.setmetatable",
    "debug.getregistry", "debug.traceback"
}

-- Safe check for existence
local function safeCheck(funcName)
    local success, result = pcall(function()
        local parts = string.split(funcName, ".")
        local current = _G
        for _, part in ipairs(parts) do
            if type(current) == "table" and current[part] then
                current = current[part]
            else
                return false
            end
        end
        return type(current) == "function"
    end)
    return success and result or false
end

-- Safe function fetcher
local function getFunction(funcName)
    local success, result = pcall(function()
        local parts = string.split(funcName, ".")
        local current = _G
        for _, part in ipairs(parts) do
            if type(current) == "table" and current[part] then
                current = current[part]
            else
                return nil
            end
        end
        return current
    end)
    return success and result or nil
end

-- Init
function Compatibility.new()
    local self = setmetatable({}, Compatibility)
    self.compatibility = {}

    for _, func in ipairs(CORE_FUNCTIONS) do
        self.compatibility[func] = safeCheck(func)
    end
    for _, func in ipairs(DEBUG_FUNCTIONS) do
        self.compatibility[func] = safeCheck(func)
    end

    return self
end

function Compatibility:has(func)
    return self.compatibility[func] == true
end

function Compatibility:get(func)
    if self:has(func) then
        return getFunction(func)
    end
    return nil
end

function Compatibility:hasAll(list)
    for _, func in ipairs(list) do
        if not self:has(func) then return false end
    end
    return true
end

function Compatibility:hasAny(list)
    for _, func in ipairs(list) do
        if self:has(func) then return true end
    end
    return false
end

function Compatibility:all()
    return self.compatibility
end

function Compatibility:summary()
    local supported, total = 0, 0
    for _, v in pairs(self.compatibility) do
        total += 1
        if v then supported += 1 end
    end

    local percent = math.floor((supported / total) * 100)
    local lines = {
        "=== Compatibility Report ===",
        string.format("Supported: %d / %d functions (%d%%)", supported, total, percent),
        ""
    }

    for k, v in pairs(self.compatibility) do
        table.insert(lines, (v and "✓ " or "✗ ") .. k)
    end

    return table.concat(lines, "\n")
end

return Compatibility
