-- Depile Compatibility Checker - Standalone Module
-- Detects all supported exploit APIs for executor environments

local Depile = {}

Depile.Support = {
    -- Core decompiler
    getscriptbytecode = typeof(getscriptbytecode) == "function",
    getconstants       = typeof(getconstants) == "function",
    getupvalues        = typeof(getupvalues) == "function",
    getprotos          = typeof(getprotos) == "function",
    decompile          = typeof(decompile) == "function",

    -- Lua closure inspection
    islclosure         = typeof(islclosure) == "function",
    getinfo            = typeof(debug) == "table" and typeof(debug.getinfo) == "function",

    -- Environment inspection
    getfenv            = typeof(getfenv) == "function",
    getgenv            = typeof(getgenv) == "function",
    getsenv            = typeof(getsenv) == "function",
    getrenv            = typeof(getrenv) == "function",

    -- Garbage collection and registry
    getgc              = typeof(getgc) == "function",
    getreg             = typeof(getreg) == "function",

    -- Function interception
    hookfunction       = typeof(hookfunction) == "function",

    -- Executor identification
    identifyexecutor   = typeof(identifyexecutor) == "function",

    -- Clipboard and I/O
    setclipboard       = typeof(setclipboard) == "function",
    writefile          = typeof(writefile) == "function",
    readfile           = typeof(readfile) == "function",
    isfile             = typeof(isfile) == "function",
}

-- Optional: print report
function Depile.printSupportReport()
    print("=== Depile Compatibility Report ===")
    for api, supported in pairs(Depile.Support) do
        print(("[%s] %s"):format(supported and "✅" or "❌", api))
    end
end

return Depile
