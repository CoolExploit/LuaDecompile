-- Depile: Advanced Custom Roblox Script Decompiler
-- Compatible with all major executors using dynamic capability detection

-- Load Compatibility Module
local DeCompatibility = loadstring(game:HttpGet("https://raw.githubusercontent.com/CoolExploit/LuaDecompile/refs/heads/main/Compatibility.lua"))()
local compat = DeCompatibility.new()

-- Load Parser & Rebuilder if bytecode functions are supported
local Parser = nil
local Rebuilder = nil

if compat:has("getscriptbytecode") then
    Parser = loadstring(game:HttpGet("https://raw.githubusercontent.com/CoolExploit/LuaDecompile/refs/heads/main/DeParse.Lua"))()
    Rebuilder = loadstring(game:HttpGet("https://raw.githubusercontent.com/CoolExploit/LuaDecompile/refs/heads/main/Debuild.Lua"))()
end

local Depile = {}
Depile.__index = Depile

-- Get full instance path
local function getFullName(instance)
    local path = {}
    while instance and instance ~= game do
        table.insert(path, 1, instance.Name)
        instance = instance.Parent
    end
    return "game." .. table.concat(path, ".")
end

-- Check if valid script
local function isScript(obj)
    return obj and (obj:IsA("LocalScript") or obj:IsA("ModuleScript") or obj:IsA("Script"))
end

-- Bytecode extraction
local function extractBytecode(scriptInstance)
    local getbytecode = compat:get("getscriptbytecode")
    if getbytecode then
        return getbytecode(scriptInstance)
    end
    return nil
end

-- Full decompilation pipeline
local function decompileScript(scriptInstance)
    local header = "-- Decompiled by Depile\n"
    header = header .. "-- Script: " .. getFullName(scriptInstance) .. "\n"
    header = header .. "-- Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n"

    if not compat:has("getscriptbytecode") then
        return header .. "-- Your executor does not support getscriptbytecode()."
    end

    local bytecode = extractBytecode(scriptInstance)
    if not bytecode then
        return header .. "-- Failed to extract bytecode."
    end

    local parsed = Parser and Parser.parse(bytecode)
    if not parsed then
        return header .. "-- Failed to parse bytecode."
    end

    local rebuilt = Rebuilder and Rebuilder.build(parsed)
    if not rebuilt then
        return header .. "-- Failed to rebuild readable code."
    end

    return header .. rebuilt
end

-- Public API
function Depile.decompile(scriptInstance)
    if not isScript(scriptInstance) then
        return "[Depile] Error: Target is not a valid script."
    end
    return decompileScript(scriptInstance)
end

function Depile.copyToClipboard(scriptInstance)
    local code = Depile.decompile(scriptInstance)
    if setclipboard and code then
        setclipboard(code)
        print("[Depile] Decompiled code copied to clipboard.")
    else
        print("[Depile] setclipboard not supported.")
    end
end

function Depile.printDecompiled(scriptInstance)
    local code = Depile.decompile(scriptInstance)
    print(code)
end

-- Optional: Set a global last decompile result
function Depile.result(scriptInstance)
    Depile.LastResult = Depile.decompile(scriptInstance)
    return Depile.LastResult
end

return Depile
