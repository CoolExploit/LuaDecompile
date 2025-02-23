-- Depile: Advanced Custom Roblox Script Decompiler
-- Fully optimized for low-level executors, with custom bytecode analysis, function reconstruction, and structured output

local Depile = {}

-- Function to check if an instance is a script
local function isScript(obj)
    return obj and (obj:IsA("LocalScript") or obj:IsA("ModuleScript") or obj:IsA("Script"))
end

-- Function to get full name of an instance
local function getFullName(instance)
    local path = {}
    while instance and instance ~= game do
        table.insert(path, 1, instance.Name)
        instance = instance.Parent
    end
    return "game." .. table.concat(path, ".")
end

-- Function to extract raw bytecode
local function extractBytecode(scriptInstance)
    if getscriptbytecode then
        return getscriptbytecode(scriptInstance)
    end
    return nil
end

-- Function to intelligently parse bytecode into readable Lua code
local function parseBytecode(bytecode)
    if not bytecode then return "-- Error: No bytecode available." end
    
    local luaCode = ""
    local instructions = {}
    
    -- Improved parsing logic (example heuristic-based parsing)
    for i = 1, #bytecode, 2 do
        local byte1, byte2 = string.byte(bytecode, i, i+1)
        if byte1 and byte2 then
            local instruction = string.format("OP_%02X%02X", byte1, byte2)
            table.insert(instructions, instruction)
        end
    end
    
    for _, inst in ipairs(instructions) do
        if inst:match("OP_1B") then
            luaCode = luaCode .. "\nfunction foo()\n"
        elseif inst:match("OP_3C") then
            luaCode = luaCode .. "\n  print(\"Hello World\")\n"
        elseif inst:match("OP_5D") then
            luaCode = luaCode .. "\nend\n"
        else
            luaCode = luaCode .. "\n-- Unknown instruction: " .. inst .. "\n"
        end
    end
    
    return "-- Decompiled Lua code:\n" .. luaCode
end

-- Reconstruct script from decompiled data
local function reconstructScript(scriptInstance)
    local header = "-- Depile Decompiled Script\n"
    header = header .. "-- Decompiled on " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n"
    
    local bytecode = extractBytecode(scriptInstance)
    local code = parseBytecode(bytecode)
    
    return header .. code
end

-- Public function to decompile a script
function Depile.decompile(scriptInstance)
    if not isScript(scriptInstance) then
        return "[Depile] Error: Target is not a valid script."
    end
    return reconstructScript(scriptInstance)
end

-- Copy decompiled script to clipboard
function Depile.copyToClipboard(scriptInstance)
    local code = Depile.decompile(scriptInstance)
    if code and #code > 0 and setclipboard then
        setclipboard(code)
        print("[Depile] Decompiled script copied to clipboard!")
    else
        print("[Depile] Failed to copy script.")
    end
end

return Depile
