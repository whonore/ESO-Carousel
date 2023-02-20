local LAM = LibAddonMenu2

Carousel = {
    name = "Carousel",
    displayName = "Carousel",
    author = "Wolf Honore",
    version = "0.3.0",
    options = {},
    optionsVersion = 1,
    optionsDefault = {
        debug = false,
    },
}

local function init()
    Carousel.options.global = ZO_SavedVars:NewAccountWide(
        "Global",
        Carousel.optionsVersion,
        nil,
        Carousel.optionsDefault)
    Carousel.options.mounts = ZO_SavedVars:NewAccountWide(
        "Mounts",
        Carousel.Mounts.optionsVersion,
        nil,
        Carousel.Mounts.optionsDefault)
    Carousel.options.pets = ZO_SavedVars:NewAccountWide(
        "Pets",
        Carousel.Pets.optionsVersion,
        nil,
        Carousel.Pets.optionsDefault)

    SLASH_COMMANDS["/carousel"] = Carousel.RunSlash

    Carousel:InitMenu()
    Carousel.Mounts:Init()
    Carousel.Pets:Init()
end

function Carousel.RunSlash(option)
    local function help()
        d(Carousel.name .. " commands:")
        d("/carousel [mounts||pets] [toggle||enable||disable||reload]")
    end
    local options = {string.match(option, "^(%S*)%s*(.-)$")}

    if not option or option == "" then
        help()
    elseif options[1] == "mounts" then
        if options[2] == "toggle" then
            if Carousel.options.mounts.enabled then
                Carousel.Mounts:Disable()
            else
                Carousel.Mounts:Enable()
            end
        elseif options[2] == "enable" then
            Carousel.Mounts:Enable()
        elseif options[2] == "disable" then
            Carousel.Mounts:Disable()
        elseif options[2] == "reload" then
            Carousel.Mounts:LoadMounts(true)
        else
            help()
        end
    elseif options[1] == "pets" then
        if options[2] == "toggle" then
            if Carousel.options.pets.enabled then
                Carousel.Pets:Disable()
            else
                Carousel.Pets:Enable()
            end
        elseif options[2] == "enable" then
            Carousel.Pets:Enable()
        elseif options[2] == "disable" then
            Carousel.Pets:Disable()
        elseif options[2] == "reload" then
            Carousel.Pets:LoadMounts(true)
        else
            help()
        end
    else
        help()
    end
end

function Carousel:InitMenu()
    local panelData = {
        type = "panel",
        name = self.displayName,
        displayName = self.displayName,
        author = self.author,
        version = self.version,
        registerForRefresh = true,
        registerForDefaults = true,
    }
    local optionsData = {
        -- Mounts
        [1] = {
            type = "header",
            name = Carousel.Mounts.displayName .. " Settings",
            width = "full",
        },
        [2] = {
            type = "description",
            text = "Control how " .. self.displayName .. " cycles mounts.",
            width = "full",
        },
        [3] = {
            type = "checkbox",
            name = "Enable",
            tooltip = "Enable/disable cycling mounts.",
            width = "full",
            default = Carousel.Mounts.optionsDefault.enabled,
            getFunc = function() return Carousel.Mounts:Enabled() end,
            setFunc = function(v)
                if v then Carousel.Mounts:Enable() else Carousel.Mounts:Disable() end
            end,
        },
        [4] = {
            type = "slider",
            name = "Cycle Rate (minutes)",
            tooltip = "How often to cycle through mounts. Set to 0 to cycle on every dismount.",
            width = "full",
            min = 0,
            max = 24 * 60, -- 24 hours
            step = 1,
            default = Carousel.Mounts.optionsDefault.rate_s / 60,
            getFunc = function() return Carousel.Mounts:CycleRate_ms() / (1000 * 60) end,
            setFunc = function(v) Carousel.Mounts:SetCycleRate_min(v) end,
        },
        -- Pets
        [5] = {
            type = "header",
            name = Carousel.Pets.displayName .. " Settings",
            width = "full",
        },
        [6] = {
            type = "description",
            text = "Control how " .. self.displayName .. " cycles pets.",
            width = "full",
        },
        [7] = {
            type = "checkbox",
            name = "Enable",
            tooltip = "Enable/disable cycling pets.",
            width = "full",
            default = Carousel.Pets.optionsDefault.enabled,
            getFunc = function() return Carousel.Pets:Enabled() end,
            setFunc = function(v)
                if v then Carousel.Pets:Enable() else Carousel.Pets:Disable() end
            end,
        },
        [8] = {
            type = "slider",
            name = "Cycle Rate (minutes)",
            tooltip = "How often to cycle through pets.",
            width = "full",
            min = 1,
            max = 24 * 60, -- 24 hours
            step = 1,
            default = Carousel.Pets.optionsDefault.rate_s / 60,
            getFunc = function() return Carousel.Pets:CycleRate_ms() / (1000 * 60) end,
            setFunc = function(v) Carousel.Pets:SetCycleRate_min(v) end,
        },
        -- Debug
        [9] = {
            type = "header",
            name = "Debug",
            width = "full",
        },
        [10] = {
            type = "checkbox",
            name = "Messages",
            tooltip = "Enable/disable debug messages.",
            width = "full",
            default = self.optionsDefault.debug,
            getFunc = function() return self.options.global.debug end,
            setFunc = function(v) self.options.global.debug = v end,
        },
    }
    local id = self.name .. "LAM"

    LAM:RegisterAddonPanel(id, panelData)
    LAM:RegisterOptionControls(id, optionsData)
end

EVENT_MANAGER:RegisterForEvent(
    Carousel.name,
    EVENT_ADD_ON_LOADED,
    function(event, addon)
        if addon ~= Carousel.name then return end
        EVENT_MANAGER:UnregisterForEvent(Carousel.name, EVENT_ADD_ON_LOADED)
        init()
    end)
