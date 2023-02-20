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

    Carousel.Mounts:Init()
    Carousel.Pets:Init()
    Carousel:InitMenu()
end

local function mountControls()
    local mounts = {}
    for mount in Carousel.Mounts:Iter() do
        table.insert(mounts, mount)
    end
    table.sort(mounts, function(x, y) return x.name < y.name end)

    local controls = {
        [1] = {
            type = "description",
            text = "Select mounts to include/exclude from the rotation.",
            width = "full",
        },
        [2] = {
            type = "button",
            name = "Include All",
            tooltip = "Include all mounts in the rotation.",
            func = function() Carousel.Mounts:IncludeAll() end,
            width = "half",
        },
    }
    for _, mount in pairs(mounts) do
        local control = {
            type = "checkbox",
            name = mount.name,
            tooltip = "Include/exclude this mount from the rotation.",
            width = "full",
            default = true,
            getFunc = function() return Carousel.Mounts:Included(mount) end,
            setFunc = function(v)
                if v then Carousel.Mounts:Include(mount) else Carousel.Mounts:Exclude(mount) end
            end,
        }
        table.insert(controls, control)
    end

    return controls
end

local function petControls()
    local pets = {}
    for pet in Carousel.Pets:Iter() do
        table.insert(pets, pet)
    end
    table.sort(pets, function(x, y) return x.name < y.name end)

    local controls = {
        [1] = {
            type = "description",
            text = "Select pets to include/exclude from the rotation.",
            width = "full",
        },
        [2] = {
            type = "button",
            name = "Include All",
            tooltip = "Include all pets in the rotation.",
            func = function() Carousel.Pets:IncludeAll() end,
            width = "half",
        },
    }
    for _, pet in pairs(pets) do
        local control = {
            type = "checkbox",
            name = pet.name,
            tooltip = "Include/exclude this pet from the rotation.",
            width = "full",
            default = true,
            getFunc = function() return Carousel.Pets:Included(pet) end,
            setFunc = function(v)
                if v then Carousel.Pets:Include(pet) else Carousel.Pets:Exclude(pet) end
            end,
        }
        table.insert(controls, control)
    end

    return controls
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
        [5] = {
            type = "submenu",
            name = "Filter",
            tooltip = "Include/exclude mounts from the rotation.",
            controls = mountControls(),
        },
        -- Pets
        [6] = {
            type = "header",
            name = Carousel.Pets.displayName .. " Settings",
            width = "full",
        },
        [7] = {
            type = "description",
            text = "Control how " .. self.displayName .. " cycles pets.",
            width = "full",
        },
        [8] = {
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
        [9] = {
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
        [10] = {
            type = "submenu",
            name = "Filter",
            tooltip = "Include/exclude pets from the rotation.",
            controls = petControls(),
        },
        -- Debug
        [11] = {
            type = "header",
            name = "Debug",
            width = "full",
        },
        [12] = {
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
