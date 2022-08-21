local LAM = LibAddonMenu2
local moduleName = "Mounts"
local modulePrefix = Carousel.name .. moduleName

Carousel.Mounts = {
    name = modulePrefix,
    displayName = Carousel.displayName .. " " .. moduleName,
    events = {
        next = modulePrefix .. "Next",
        wait = modulePrefix .. "WaitDismount",
    },
    optionsVersion = 1,
    optionsDefault = {
        enabled = true,
        -- TODO: allow 0 for on every mount
        rate_s = 10 * 60 * 60, -- 10 minutes
    },
}

local function shuffle(x)
    for i = #x, 2, -1 do
        local j = math.random(i)
        x[i], x[j] = x[j], x[i]
    end
end

local function dmsg(msg)
    d("[" .. modulePrefix .. "] " .. msg)
end

local function isMountCategory(category)
    return not (category:IsOutfitStylesCategory() or category:IsHousingCategory())
end

local function isMount(collectible)
    return collectible:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_MOUNT)
end

function Carousel.Mounts:Init()
    self:InitMenu()

    self:LoadMounts(false)
    if self.Enabled() then
        self:RegisterNext()
    end
end

function Carousel.Mounts:InitMenu()
    local panelData = {
        type = "panel",
        name = self.displayName,
        displayName = self.displayName,
        author = Carousel.author,
        version = Carousel.version,
        registerForRefresh = true,
        registerForDefaults = true,
    }
    local optionsData = {
        [1] = {
            type = "header",
            name = self.displayName .. " Settings",
            width = "full",
        },
        [2] = {
            type = "description",
            text = "Control how " .. Carousel.displayName .. " cycles mounts.",
            width = "full",
        },
        [3] = {
            type = "checkbox",
            name = "Enable",
            tooltip = "Enable/disable cycling mounts.",
            width = "full",
            getFunc = function() return self:Enabled() end,
            setFunc = function(v) if v then self:Enable() else self:Disable() end end,
        },
    }

    LAM:RegisterAddonPanel(self.name, panelData)
    LAM:RegisterOptionControls(self.name, optionsData)
end

-- TODO: recompute if mounts change
function Carousel.Mounts:LoadMounts(reload)
    self.ids = {}
    self.next = 1

    for _, cat in ZO_COLLECTIBLE_DATA_MANAGER:CategoryIterator({isMountCategory}) do
        for _, subCat in cat:SubcategoryIterator({isMountCategory}) do
            for _, collect in subCat:CollectibleIterator({isMount}) do
                if collect:IsUnlocked() and not collect:IsBlocked() then
                    table.insert(self.ids, collect:GetId())
                end
            end
        end
    end
    shuffle(self.ids)

    if reload then
        dmsg("reloaded")
    end
end

function Carousel.Mounts:Enable()
    dmsg("enabled (cycle every " .. self:CycleRate_ms() / 1000 .. " seconds)")
    Carousel.options.mounts.enabled = true
    self:RegisterNext()
end

function Carousel.Mounts:Disable()
    dmsg("disabled")
    Carousel.options.mounts.enabled = false
    EVENT_MANAGER:UnregisterForEvent(self.events.wait, EVENT_MOUNTED_STATE_CHANGED)
    EVENT_MANAGER:UnregisterForUpdate(self.events.next)
end

function Carousel.Mounts:Enabled()
    return Carousel.options.mounts.enabled
end

function Carousel.Mounts:RegisterNext()
    if not self.Enabled() then return end

    EVENT_MANAGER:UnregisterForUpdate(self.events.next)
    EVENT_MANAGER:RegisterForUpdate(
        self.events.next,
        Carousel.options.mounts.rate_s * 1000,
        function() self:Next() end)
end

function Carousel.Mounts:WaitForDismount()
    EVENT_MANAGER:UnregisterForUpdate(self.events.next)
    EVENT_MANAGER:RegisterForEvent(
        self.events.wait,
        EVENT_MOUNTED_STATE_CHANGED,
        function(event, mounted)
            if not mounted then
                EVENT_MANAGER:UnregisterForEvent(
                    self.events.wait,
                    EVENT_MOUNTED_STATE_CHANGED)
                self:RegisterNext()
                self:Next()
            end
        end)
end

-- TODO: allow filtering
-- TODO: allow changing companion's mount
function Carousel.Mounts:Next()
    if not self.Enabled() then return end

    if IsMounted() then
        self:WaitForDismount()
        return
    end

    local mountId = self.ids[self.next]
    local mount = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(mountId)
    dmsg("switching active mount to " .. mount:GetName())
    mount:Use()

    if self.next == #self.ids then
        shuffle(self.ids)
        self.next = 1
    else
        self.next = self.next + 1
    end
end
