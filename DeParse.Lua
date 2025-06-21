-- Depile.Parser - Roblox Luau Bytecode Disassembler (No Compatibility Required)

-- === Full Luau Opcode Database ===
local OPCODE_NAMES = {
    [0] = "MOVE", [1] = "LOADK", [2] = "LOADKX", [3] = "LOADBOOL", [4] = "LOADNIL",
    [5] = "GETUPVAL", [6] = "GETTABUP", [7] = "GETTABLE", [8] = "SETTABUP", [9] = "SETUPVAL",
    [10] = "SETTABLE", [11] = "NEWTABLE", [12] = "SELF", [13] = "ADD", [14] = "SUB",
    [15] = "MUL", [16] = "DIV", [17] = "MOD", [18] = "POW", [19] = "UNM", [20] = "NOT",
    [21] = "LEN", [22] = "CONCAT", [23] = "JMP", [24] = "EQ", [25] = "LT", [26] = "LE",
    [27] = "TEST", [28] = "TESTSET", [29] = "CALL", [30] = "TAILCALL", [31] = "RETURN",
    [32] = "FORLOOP", [33] = "FORPREP", [34] = "TFORCALL", [35] = "TFORLOOP", [36] = "SETLIST",
    [37] = "CLOSURE", [38] = "VARARG", [39] = "EXTRAARG", [40] = "PREPVARARGS", [41] = "LOADKNUM",
    [42] = "LOADKSTR", [43] = "LOADNIL_N", [44] = "GETIMPORT", [45] = "GETTABLE_N", [46] = "SETTABLE_N",
    [47] = "GETTABLE_S", [48] = "SETTABLE_S", [49] = "GETTABUP_N", [50] = "SETTABUP_N",
    [51] = "GETTABUP_S", [52] = "SETTABUP_S", [53] = "NEWCLOSURE", [54] = "NAMECALL",
    [55] = "CALL_M", [56] = "RETURN_M", [57] = "GETTABLEKS", [58] = "SETTABLEKS", [59] = "GETTABLEN",
    [60] = "SETTABLEN", [61] = "GETVARARGS", [62] = "DUPCLOSURE", [63] = "FORNPREP",
    [64] = "FORNLOOP", [65] = "FASTCALL", [66] = "COVERAGE", [67] = "CAPTURE",
    [68] = "FASTCALL1", [69] = "FASTCALL2", [70] = "FASTCALL2K", [71] = "FASTCALL3",
    [72] = "FORGLOOP", [73] = "FORGPREP_INEXT", [74] = "FORGLOOP_INEXT", [75] = "FORGPREP_NEXT",
    [76] = "FORGLOOP_NEXT", [77] = "GETVARARGS_R", [78] = "FASTCALL1_R", [79] = "FASTCALL2_R",
    [80] = "FASTCALL2K_R", [81] = "FASTCALL3_R", [82] = "JUMPBACK", [83] = "JUMPXEQKNIL",
    [84] = "JUMPXEQKB", [85] = "JUMPXEQKN", [86] = "JUMPXEQKS", [87] = "JUMPXNEQKNIL",
    [88] = "JUMPXNEQKB", [89] = "JUMPXNEQKN", [90] = "JUMPXNEQKS", [91] = "JUMPX",
    [92] = "JUMPXEQ", [93] = "JUMPXNE", [94] = "JUMPXLT", [95] = "JUMPXLE"
}

local OPCODE_FORMATS = {
    [0] = "iABC", [1] = "iABx", [2] = "iABx", [3] = "iABC", [4] = "iABC",
    [5] = "iABC", [6] = "iABC", [7] = "iABC", [8] = "iABC", [9] = "iABC",
    [10] = "iABC", [11] = "iABC", [12] = "iABC", [13] = "iABC", [14] = "iABC",
    [15] = "iABC", [16] = "iABC", [17] = "iABC", [18] = "iABC", [19] = "iABC",
    [20] = "iABC", [21] = "iABC", [22] = "iABC", [23] = "iAsBx", [24] = "iABC",
    [25] = "iABC", [26] = "iABC", [27] = "iABC", [28] = "iABC", [29] = "iABC",
    [30] = "iABC", [31] = "iABC", [32] = "iAsBx", [33] = "iAsBx", [34] = "iABC",
    [35] = "iAsBx", [36] = "iABC", [37] = "iABx", [38] = "iABC", [39] = "iAx"
}

local function decode(inst)
    local opcode = inst & 0x3F
    local A = (inst >> 6) & 0xFF
    local C = (inst >> 14) & 0x1FF
    local B = (inst >> 23) & 0x1FF
    local Bx = (inst >> 14) & 0x3FFFF
    local sBx = Bx - 131071
    local Ax = (inst >> 6)

    return {
        opcode = opcode,
        A = A, B = B, C = C,
        Bx = Bx, sBx = sBx, Ax = Ax,
        format = OPCODE_FORMATS[opcode] or "iABC",
        name = OPCODE_NAMES[opcode] or ("UNKNOWN_" .. tostring(opcode)),
        raw = inst
    }
end

local Parser = {}

function Parser.parse(bytecode)
    if typeof(bytecode) ~= "string" then
        return nil, "[Depile.Parser] Invalid bytecode"
    end

    local instructions = {}
    for i = 1, #bytecode, 4 do
        local chunk = bytecode:sub(i, i + 3)
        if #chunk < 4 then break end

        local inst = string.unpack("<I4", chunk)
        local decoded = decode(inst)
        decoded.index = #instructions + 1
        table.insert(instructions, decoded)
    end

    return instructions
end

function Parser.formatInstructions(instructions)
    local out = {}
    for _, inst in ipairs(instructions) do
        table.insert(out, string.format("[%03d] %-12s A=%-3d B=%-3d C=%-3d sBx=%-5d (format=%s)",
            inst.index, inst.name, inst.A, inst.B, inst.C, inst.sBx, inst.format))
    end
    return table.concat(out, "\n")
end

return Parser
