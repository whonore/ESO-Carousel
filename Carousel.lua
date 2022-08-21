Carousel = {}
Carousel.name = "Carousel"
Carousel.options = {}

local function init()
    Carousel.options.mounts = ZO_SavedVars:NewAccountWide(
        "Mounts",
        Carousel.Mounts.optionsVersion,
        nil,
        Carousel.Mounts.optionsDefault)
    Carousel.Mounts:Init(true)
end

EVENT_MANAGER:RegisterForEvent(
    Carousel.name,
    EVENT_ADD_ON_LOADED,
    function(event, addon)
        if addon ~= Carousel.name then return end
        EVENT_MANAGER:UnregisterForEvent(Carousel.name, EVENT_ADD_ON_LOADED)
        init()
    end)
