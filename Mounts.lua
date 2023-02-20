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
        rate_s = 10 * 60, -- 10 minutes
        excluded = {},
    },
}

local function shuffle(x)
    for i = #x, 2, -1 do
        local j = math.random(i)
        x[i], x[j] = x[j], x[i]
    end
end

local function dmsg(msg)
    if Carousel.options.global.debug then
        d("[" .. modulePrefix .. "] " .. msg)
    end
end

local function isMountCategory(category)
    return not (category:IsOutfitStylesCategory() or category:IsHousingCategory())
end

local function isMount(collectible)
    return collectible:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_MOUNT)
end

local function mountData(mountId)
    local data = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(mountId)
    local _, duration = GetCollectibleCooldownAndDuration(mountId)
    local name = string.gsub(data:GetName(), "%^n$", "")
    return {
        id = mountId,
        name = name,
        duration = duration,
        data = data,
    }
end

function Carousel.Mounts:Init()
    self:LoadMounts(false)
    if self:Enabled() then
        self:RegisterNext()
    end
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
    self:Unregister()
end

function Carousel.Mounts:Enabled()
    return Carousel.options.mounts.enabled
end

function Carousel.Mounts:CycleRate_ms()
    return Carousel.options.mounts.rate_s * 1000
end

function Carousel.Mounts:SetCycleRate_min(rate_min)
    Carousel.options.mounts.rate_s = rate_min * 60
    self:RegisterNext()
end

function Carousel.Mounts:IncludeAll()
    dmsg("including all")
    Carousel.options.mounts.excluded = {}
end

function Carousel.Mounts:Include(mount)
    dmsg("including " .. mount.name)
    Carousel.options.mounts.excluded[mount.id] = nil
end

function Carousel.Mounts:Exclude(mount)
    dmsg("excluding " .. mount.name)
    Carousel.options.mounts.excluded[mount.id] = true
end

function Carousel.Mounts:Included(mount)
    return Carousel.options.mounts.excluded[mount.id] == nil
end

function Carousel.Mounts:Unregister()
    EVENT_MANAGER:UnregisterForEvent(self.events.wait, EVENT_MOUNTED_STATE_CHANGED)
    EVENT_MANAGER:UnregisterForUpdate(self.events.next)
end

function Carousel.Mounts:RegisterNext()
    if not self:Enabled() then return end

    self:Unregister()
    if self:CycleRate_ms() > 0 then
        EVENT_MANAGER:RegisterForUpdate(
            self.events.next,
            self:CycleRate_ms(),
            function() self:Next() end)
    else
        self:WaitForDismount()
    end
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

-- TODO: allow changing companion's mount
function Carousel.Mounts:Next()
    if not self:Enabled() then return end

    if IsMounted() then
        self:WaitForDismount()
        return
    end

    local looped = 0
    local mount
    repeat
        mount = mountData(self.ids[self.next])

        if self.next == #self.ids then
            shuffle(self.ids)
            self.next = 1
            looped = looped + 1
        else
            self.next = self.next + 1
        end
    until self:Included(mount) or looped > 1

    if looped > 1 then
        dmsg("Warning: all mounts excluded")
    end

    local function use()
        dmsg("switching active mount to " .. mount.name)
        mount.data:Use()
    end

    if mount.duration > 0 then
        zo_callLater(use, mount.duration)
    else
        use()
    end
end

function Carousel.Mounts:Iter()
    local i = 0
    local nids = #self.ids
    return function()
        i = i + 1
        if i <= nids then
            return mountData(self.ids[i])
        else
            return nil
        end
    end
end
