-- Depile.lua - Unified Decompiler Loader
-- Loads Compatibility, Parser, and Rebuilder (Debuild) to perform decompilation

local Depile = {}

-- Load compatibility checker
local DeCompatibility = loadstring(game:HttpGet("https://raw.githubusercontent.com/CoolExploit/LuaDecompile/main/Compatibility.Lua"))()

-- Dependency URLs
local ParserUrl = "https://raw.githubusercontent.com/CoolExploit/LuaDecompile/main/Depile.Parser.lua"
local RebuilderUrl = "https://raw.githubusercontent.com/CoolExploit/LuaDecompile/main/Debuild.Lua"

-- Load core modules
local Parser = loadstring(game:HttpGet(ParserUrl))()
local Rebuilder = loadstring(game:HttpGet(RebuilderUrl))()

-- Utilities
local function isScript(obj)
    return obj and (obj:IsA("LocalScript") or obj:IsA("ModuleScript") or obj:IsA("Script"))
end

local function extractBytecode(scriptInstance)
    if DeCompatibility.has("getscriptbytecode") then
        return getscriptbytecode(scriptInstance)
    else
        return nil, "[Depile] getscriptbytecode not supported by this executor."
    end
end

-- Main decompile function
function Depile.decompile(scriptInstance)
    if not isScript(scriptInstance) then
        return "[Depile] Error: Provided instance is not a valid script."
    end

    local bytecode, err = extractBytecode(scriptInstance)
    if not bytecode then
        return err or "[Depile] Failed to extract bytecode."
    end

    local parsed = Parser.parse(bytecode)
    local constants = Parser.constants or {} -- optional
    local readable = Rebuilder.rebuild(parsed, constants)

    Depile.Result = readable -- Store result in Depile.Result
    return readable
end

-- Optional print helper
function Depile.print(scriptInstance)
    local result = Depile.decompile(scriptInstance)
    print("[Depile Decompiled Code]\n" .. tostring(result))
end

return Depile
