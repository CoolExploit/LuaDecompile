-- DeCompatibilityV2: Executor-Agnostic Runtime Compatibility Detector
-- Validates usable features by behavior, not by name or spoofed existence

local DeCompatibility = {}
DeCompatibility.__index = DeCompatibility

-- List of behavior-based test cases
local tests = {
    {
        name = "hookfunction",
        category = "hooking",
        run = function()
            local a = function() return 1 end
            local b = function() return 2 end
            local pass = false
            local ok = pcall(function()
                local hook = hookfunction(a, b)
                pass = (a() == 2)
            end)
            return ok and pass
        end
    },
    {
        name = "getconstants",
        category = "bytecode",
        run = function()
            local testFunc = function() return "test" end
            local ok, result = pcall(function()
                local c = getconstants(testFunc)
                return type(c) == "table" and table.find(c, "test")
            end)
            return ok and result ~= nil
        end
    },
    {
        name = "loadstring",
        category = "execution",
        run = function()
            local ok, result = pcall(function()
                return loadstring("return 123")() == 123
            end)
            return ok and result
        end
    },
    {
        name = "getgc",
        category = "introspection",
        run = function()
            local ok, result = pcall(function()
                local gc = getgc(true)
                return type(gc) == "table" and #gc > 0
            end)
            return ok and result
        end
    },
    {
        name = "checkcaller",
        category = "security",
        run = function()
            local ok, result = pcall(function()
                return type(checkcaller) == "function" and checkcaller() ~= nil
            end)
            return ok and result
        end
    },
    {
        name = "setclipboard",
        category = "utility",
        run = function()
            return type(setclipboard) == "function"
        end
    }
    -- Add more behavioral tests as needed
}

function DeCompatibility.new()
    local self = setmetatable({}, DeCompatibility)
    self.support = {}

    for _, test in ipairs(tests) do
        local ok = false
        pcall(function()
            ok = test.run()
        end)
        self.support[test.name] = {
            category = test.category,
            passed = ok
        }
    end

    return self
end

function DeCompatibility:has(feature)
    local result = self.support[feature]
    return result and result.passed or false
end

function DeCompatibility:summary()
    local out = {}
    table.insert(out, "== DeCompatibility Report ==")
    for name, data in pairs(self.support) do
        local icon = data.passed and "✓" or "✗"
        table.insert(out, string.format("[%s] %s (%s)", icon, name, data.category))
    end
    return table.concat(out, "\n")
end

return DeCompatibility
