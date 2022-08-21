Carousel = {
    name = "Carousel",
    displayName = "Carousel",
    author = "Wolf Honore",
    version = "0.1.0",
    options = {},
}

local function init()
    Carousel.options.mounts = ZO_SavedVars:NewAccountWide(
        "Mounts",
        Carousel.Mounts.optionsVersion,
        nil,
        Carousel.Mounts.optionsDefault)

    SLASH_COMMANDS["/carousel"] = Carousel.RunSlash

    Carousel.Mounts:Init(true)
end

function Carousel.RunSlash(option)
    local function help()
        d(Carousel.name .. " commands:")
        d("/carousel mounts [toggle||enable||disable||reload]")
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
    else
        help()
    end
end

EVENT_MANAGER:RegisterForEvent(
    Carousel.name,
    EVENT_ADD_ON_LOADED,
    function(event, addon)
        if addon ~= Carousel.name then return end
        EVENT_MANAGER:UnregisterForEvent(Carousel.name, EVENT_ADD_ON_LOADED)
        init()
    end)
