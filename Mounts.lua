Carousel.Mounts = {}
Carousel.Mounts.events = {
    next = Carousel.name .. "MountsNext",
    wait = Carousel.name .. "MountsWaitDismount"
}
Carousel.Mounts.optionsVersion = 1
Carousel.Mounts.optionsDefault = {
    enabled = true,
    -- TODO: make configurable
    -- TODO: allow 0 for on every mount
    rate_s = 10 * 60 * 60 -- 10 minutes
}

local function isMountCategory(category)
    return not (category:IsOutfitStylesCategory() or category:IsHousingCategory())
end

local function isMount(collectible)
    return collectible:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_MOUNT)
end

local function shuffle(x)
    for i = #x, 2, -1 do
        local j = math.random(i)
        x[i], x[j] = x[j], x[i]
    end
end

function Carousel.Mounts:Init()
    self:LoadMounts(false)
    if Carousel.options.mounts.enabled then
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
        d(Carousel.name .. " Mounts reloaded")
    end
end

function Carousel.Mounts:Enable()
    d(Carousel.name .. " Mounts enabled")
    Carousel.options.mounts.enabled = true
    self:RegisterNext()
end

function Carousel.Mounts:Disable()
    d(Carousel.name .. " Mounts disabled")
    Carousel.options.mounts.enabled = false
    EVENT_MANAGER:UnregisterForEvent(self.events.wait, EVENT_MOUNTED_STATE_CHANGED)
    EVENT_MANAGER:UnregisterForUpdate(self.events.next)
end

function Carousel.Mounts:RegisterNext()
    if not Carousel.options.mounts.enabled then return end

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
                EVENT_MANAGER:UnregisterForEvent(self.events.wait, EVENT_MOUNTED_STATE_CHANGED)
                self:RegisterNext()
                self:Next()
            end
        end)
end

-- TODO: allow filtering
-- TODO: allow changing companion's mount
function Carousel.Mounts:Next()
    if not Carousel.options.mounts.enabled then return end

    if IsMounted() then
        self:WaitForDismount()
        return
    end

    local mountId = self.ids[self.next]
    local mount = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(mountId)
    d("Switching active mount to " .. mount:GetName())
    mount:Use()

    if self.next == #self.ids then
        shuffle(self.ids)
        self.next = 1
    else
        self.next = self.next + 1
    end
end
