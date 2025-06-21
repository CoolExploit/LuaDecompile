-- Compatibility.lua v2 - Full Executor Capability Inspector
local Compatibility = {}
Compatibility.__index = Compatibility

-- Define categories with function name and test logic
local FunctionCategories = {
    Bytecode = {
        getscriptbytecode = function(f)
            local s = Instance.new("LocalScript")
            s.Source = "return 1"
            s.Parent = game
            return pcall(f, s)
        end,
        getconstants = function(f)
            return pcall(f, function() return "abc" end)
        end,
        getprotos = function(f)
            return pcall(f, function() return function() return 1 end end)
        end,
        getupvalues = function(f)
            return pcall(f, function() local a = 1 return a end)
        end,
        setupvalue = function(f)
            return pcall(f, function() local a = 1 return a end, 1, 2)
        end,
        setconstant = function(f)
            return pcall(f, function() return 123 end, 1, 456)
        end
    },

    Introspection = {
        getinfo = function(f)
            return pcall(f, function() return 1 end)
        end,
        getfenv = function(f)
            return pcall(f, function() end)
        end,
        setfenv = function(f)
            return pcall(f, function() end, {})
        end,
        debug_getinfo = function()
            return pcall(function() return debug.getinfo(function() end) end)
        end
    },

    Execution = {
        loadstring = function(f)
            local ok, res = pcall(f, "return 1337")
            return ok and type(res) == "function"
        end,
        newcclosure = function(f)
            return pcall(f, function() end)
        end,
        is_synapse_function = function(f)
            return pcall(f, function() end)
        end
    },

    Closure = {
        iscclosure = function(f)
            return pcall(f, function() end)
        end,
        islclosure = function(f)
            return pcall(f, function() end)
        end,
        checkclosure = function(f)
            return pcall(f, function() end)
        end,
    },

    Hooking = {
        hookfunction = function(f)
            return pcall(f, function() return 1 end, function() return 2 end)
        end,
        hookmetamethod = function(f)
            return pcall(f, game, "__index", function() end)
        end,
        getnamecallmethod = function(f)
            return pcall(f)
        end,
        setnamecallmethod = function(f)
            return pcall(f, "__namecall")
        end,
    },

    Environment = {
        getgc = function(f)
            local ok, gc = pcall(f)
            return ok and type(gc) == "table"
        end,
        getgenv = function(f)
            return pcall(f)
        end,
        getreg = function(f)
            local ok, r = pcall(f)
            return ok and type(r) == "table"
        end
    }
}

-- Safely get a function
local function getFn(name)
    local parts = string.split(name, "_")
    if #parts == 2 and parts[1] == "debug" then
        return debug[parts[2]]
    else
        return getgenv()[name]
    end
end

-- Instantiate compatibility checker
function Compatibility.new()
    local self = setmetatable({}, Compatibility)
    self.results = {}
    self.count = 0
    self.available = 0

    for category, functions in pairs(FunctionCategories) do
        self.results[category] = {}

        for name, tester in pairs(functions) do
            local fn = getFn(name)
            local ok = false
            if type(fn) == "function" then
                local success, result = pcall(tester, fn)
                ok = success and result
            end
            self.results[category][name] = ok
            self.count = self.count + 1
            if ok then self.available = self.available + 1 end
        end
    end

    self.percent = math.floor((self.available / self.count) * 100)
    return self
end

function Compatibility:has(name)
    for _, group in pairs(self.results) do
        if group[name] ~= nil then return group[name] end
    end
    return false
end

function Compatibility:get(name)
    return self:has(name) and getFn(name) or nil
end

function Compatibility:summary()
    local lines = {
        "=== Capability Summary ===",
        string.format("Supported: %d/%d (%d%%)", self.available, self.count, self.percent),
        ""
    }

    for category, group in pairs(self.results) do
        table.insert(lines, "› " .. category)
        for name, ok in pairs(group) do
            table.insert(lines, string.format("   [%s] %s", ok and "✓" or "✗", name))
        end
    end

    return table.concat(lines, "\n")
end

return Compatibility
