-- DEBUG ВЕРСИЯ — не кикает, а показывает что детектит
-- Запусти и пришли мне вывод из консоли!

local _lp = game:GetService("Players").LocalPlayer
local _H = game:GetService("HttpService")
local _RAS = game:GetService("RbxAnalyticsService")
local _CG = game:GetService("CoreGui")

local _isLC = islclosure or (function() return nil end)
local _getRawMt = getrawmetatable or (function() return nil end)
local _getGC = getgc or (function() return nil end)

local _fns = {
    {game.HttpGet, "HTTPGET"},
    {game.HttpGetAsync, "HTTPGETASYNC"},
    {game.HttpPost, "HTTPPOST"},
    {game.HttpPostAsync, "HTTPPOSTASYNC"},
    {_H.RequestAsync, "REQUESTASYNC"},
    {_H.GetAsync, "GETASYNC"},
    {_H.PostAsync, "POSTASYNC"},
}

print("=== NK DEBUG: STARTING DETECTION TEST ===")

-- 1. Тестируем каждую HTTP функцию отдельно
print("\n--- ТЕСТ 1: HTTP функции (islclosure) ---")
for i = 1, #_fns do
    local fn = _fns[i][1]
    local name = _fns[i][2]
    if fn then
        local isL = false
        local ok, err = pcall(function() isL = _isLC(fn) end)
        if ok and isL then
            print("  [!] DETECTED: " .. name .. " is LClosure — это spy!")
        else
            print("  [OK] " .. name .. (ok and " (not lclosure)" or " (error: " .. tostring(err) .. ")"))
        end
    else
        print("  [-] " .. name .. " is nil")
    end
end

-- 2. Executor-level функции
print("\n--- ТЕСТ 2: Executor HTTP функции ---")
local execFns = {
    {request, "request"},
    {http_request, "http_request"},
    {http and http and http.request, "http.request"},
    {syn and syn and syn.request, "syn.request"},
}
for _, entry in ipairs(execFns) do
    local fn = entry[1]
    local name = entry[2]
    if fn then
        local isL = false
        local ok, err = pcall(function() isL = _isLC(fn) end)
        if ok and isL then
            print("  [!] DETECTED: " .. name .. " is LClosure")
        else
            print("  [OK] " .. name .. (ok and " (not lclosure)" or " (error: " .. tostring(err) .. ")"))
        end
    else
        print("  [-] " .. name .. " is nil")
    end
end

-- 3. __namecall hook
print("\n--- ТЕСТ 3: __namecall hook ---")
if _getRawMt then
    local mt
    pcall(function() mt = _getRawMt(game) end)
    if mt then
        local nc
        pcall(function() nc = rawget(mt, "__namecall") end)
        if nc then
            local isL = false
            pcall(function() isL = _isLC(nc) end)
            if isL then
                print("  [!] DETECTED: __namecall is LClosure")
            else
                print("  [OK] __namecall not lclosure")
            end
        else
            print("  [OK] __namecall is nil (no hook)")
        end
    else
        print("  [-] getrawmetatable(game) returned nil")
    end
else
    print("  [-] getrawmetatable not available")
end

-- 4. print/warn hooks
print("\n--- ТЕСТ 4: print/warn hooks ---")
if _isLC then
    local isL = false
    pcall(function() isL = _isLC(print) end)
    if isL then
        print("  [!] DETECTED: print is LClosure")
    else
        print("  [OK] print not lclosure")
    end
    isL = false
    pcall(function() isL = _isLC(warn) end)
    if isL then
        print("  [!] DETECTED: warn is LClosure")
    else
        print("  [OK] warn not lclosure")
    end
end

-- 5. GC scan
print("\n--- ТЕСТ 5: GC scan ---")
if _getGC then
    local gc
    pcall(function() gc = _getGC(true) end)
    if gc then
        print("  GC table size: " .. #gc)
        local found = false
        for _, v in ipairs(gc) do
            if type(v) == "table" then
                local bw = rawget(v, "blockWebhooks")
                if bw ~= nil and rawget(v, "blockAll") ~= nil then
                    print("  [!] DETECTED: HTTPSPY_CONFIG table")
                    found = true
                elseif rawget(v, "_con") and rawget(v, "_hooks") and rawget(v, "_cfg") then
                    print("  [!] DETECTED: HTTPSPY_CLASS table")
                    found = true
                elseif rawget(v, "_ansi") and rawget(v, "_methodColors") and rawget(v, "_p") then
                    print("  [!] DETECTED: CONSOLE_CLASS table")
                    found = true
                elseif rawget(v, "GET") and rawget(v, "POST") and rawget(v, "DELETE") and rawget(v, "HEAD") then
                    print("  [!] DETECTED: METHOD_COLORS table")
                    found = true
                elseif rawget(v, "lblue") and rawget(v, "lgreen") and rawget(v, "orange") and rawget(v, "reset") then
                    print("  [!] DETECTED: ANSI_COLORS table")
                    found = true
                end
            end
        end
        if not found then print("  [OK] No spy tables in GC") end
    else
        print("  [-] getgc() returned nil")
    end

    -- GC string scan
    local gcs
    pcall(function() gcs = _getGC(false) end)
    if gcs then
        print("  GC (false) size: " .. #gcs)
        local found = false
        for _, v in ipairs(gcs) do
            if type(v) == "string" then
                local len = #v
                if len > 5 and len < 200 then
                    if string.find(v, "koboldpaws", 1, true)
                    or string.find(v, "http spy by", 1, true)
                    or string.find(v, "BeboMods", 1, true)
                    or string.find(v, "SimpleSpy", 1, true)
                    or string.find(v, "ConsoleSpy", 1, true) then
                        print("  [!] DETECTED spy string: '" .. v .. "'")
                        found = true
                    end
                end
            end
        end
        if not found then print("  [OK] No spy strings in GC") end
    end
else
    print("  [-] getgc not available")
end

-- 6. GUI scan
print("\n--- ТЕСТ 6: GUI scan ---")
local badNames = {"HttpSpy", "SimpleSpy", "HydroSpy", "SecureSpy", "TwiSpy", "BeboSpy", "ConsoleSpy", "Console"}
local function scanGui(root, label)
    local desc
    local ok = pcall(function() desc = root:GetDescendants() end)
    if not ok or not desc then print("  [-] Cannot scan " .. label); return end
    local found = false
    for _, obj in ipairs(desc) do
        local name
        pcall(function() name = obj.Name end)
        if name then
            for _, bad in ipairs(badNames) do
                if name == bad or string.find(name, bad, 1, true) then
                    print("  [!] DETECTED GUI: '" .. name .. "' in " .. label)
                    found = true
                end
            end
        end
    end
    if not found then print("  [OK] No spy GUI in " .. label) end
end
scanGui(_CG, "CoreGui")
local pg = _lp:FindFirstChildOfClass("PlayerGui")
if pg then scanGui(pg, "PlayerGui") end

-- Executor name
print("\n--- EXECUTOR INFO ---")
local execName = "Unknown"
pcall(function() if identifyexecutor then execName = identifyexecutor() end end)
print("  Executor: " .. execName)

print("\n=== NK DEBUG: DONE ===")
print("Пришли мне весь этот вывод!")
