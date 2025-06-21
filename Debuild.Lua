-- Depile.Rebuilder - Rebuilds readable Lua code from parsed Luau instructions

local Rebuilder = {}

-- Optional constants table (external or static)
local constants = {} -- You can inject your actual constants here

local function const(val)
    if type(val) == "string" then
        return '"' .. val .. '"'
    elseif type(val) == "boolean" then
        return tostring(val)
    elseif val == nil then
        return "nil"
    else
        return tostring(val)
    end
end

local function var(n)
    return "var_" .. tostring(n)
end

function Rebuilder.rebuild(instructions, consts)
    constants = consts or {}

    local out = {}
    local indent = 0
    local function tab() return string.rep("    ", indent) end

    for _, inst in ipairs(instructions) do
        local op = inst.name
        local A, B, C = inst.A, inst.B, inst.C
        local Bx, sBx = inst.Bx, inst.sBx

        if op == "LOADK" then
            local k = constants[Bx] and const(constants[Bx]) or ("const[" .. Bx .. "]")
            table.insert(out, tab() .. string.format("local %s = %s", var(A), k))

        elseif op == "LOADBOOL" then
            table.insert(out, tab() .. string.format("local %s = %s", var(A), tostring(B ~= 0)))

        elseif op == "MOVE" then
            table.insert(out, tab() .. string.format("%s = %s", var(A), var(B)))

        elseif op == "ADD" then
            table.insert(out, tab() .. string.format("%s = %s + %s", var(A), var(B), var(C)))

        elseif op == "SUB" then
            table.insert(out, tab() .. string.format("%s = %s - %s", var(A), var(B), var(C)))

        elseif op == "MUL" then
            table.insert(out, tab() .. string.format("%s = %s * %s", var(A), var(B), var(C)))

        elseif op == "DIV" then
            table.insert(out, tab() .. string.format("%s = %s / %s", var(A), var(B), var(C)))

        elseif op == "MOD" then
            table.insert(out, tab() .. string.format("%s = %s %% %s", var(A), var(B), var(C)))

        elseif op == "POW" then
            table.insert(out, tab() .. string.format("%s = %s ^ %s", var(A), var(B), var(C)))

        elseif op == "NOT" then
            table.insert(out, tab() .. string.format("%s = not %s", var(A), var(B)))

        elseif op == "LEN" then
            table.insert(out, tab() .. string.format("%s = #%s", var(A), var(B)))

        elseif op == "GETTABLE" then
            table.insert(out, tab() .. string.format("%s = %s[%s]", var(A), var(B), var(C)))

        elseif op == "SETTABLE" then
            table.insert(out, tab() .. string.format("%s[%s] = %s", var(A), var(B), var(C)))

        elseif op == "NEWTABLE" then
            table.insert(out, tab() .. string.format("local %s = {}", var(A)))

        elseif op == "CLOSURE" or op == "NEWCLOSURE" then
            table.insert(out, tab() .. string.format("local %s = function() -- proto %d", var(A), Bx))
            indent = indent + 1

        elseif op == "RETURN" then
            table.insert(out, tab() .. string.format("return %s", var(A)))

        elseif op == "CALL" then
            table.insert(out, tab() .. string.format("%s = %s(...)", var(A), var(A)))

        elseif op == "EQ" then
            table.insert(out, tab() .. string.format("if %s == %s then -- A=%s", var(B), var(C), A))

        elseif op == "LT" then
            table.insert(out, tab() .. string.format("if %s < %s then -- A=%s", var(B), var(C), A))

        elseif op == "LE" then
            table.insert(out, tab() .. string.format("if %s <= %s then -- A=%s", var(B), var(C), A))

        elseif op == "JMP" then
            table.insert(out, tab() .. string.format("-- jump %+d", sBx))

        elseif op == "FORPREP" then
            table.insert(out, tab() .. string.format("for %s = ..., ..., ... do -- jump %+d", var(A), sBx))
            indent = indent + 1

        elseif op == "FORLOOP" then
            indent = math.max(0, indent - 1)
            table.insert(out, tab() .. "-- end for")

        elseif op == "CONCAT" then
            table.insert(out, tab() .. string.format("%s = %s .. %s", var(A), var(B), var(C)))

        elseif op == "SELF" then
            table.insert(out, tab() .. string.format("%s = %s[%s]", var(A), var(B), var(C)))

        else
            table.insert(out, tab() .. "-- [" .. inst.index .. "] " .. op)
        end
    end

    return table.concat(out, "\n")
end

return Rebuilder
