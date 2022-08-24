local moduleName = "Pets"
local modulePrefix = Carousel.name .. moduleName

Carousel.Pets = {
    name = modulePrefix,
    displayName = Carousel.displayName .. " " .. moduleName,
    events = {
        next = modulePrefix .. "Next",
    },
    optionsVersion = 1,
    optionsDefault = {
        enabled = true,
        rate_s = 10 * 60, -- 10 minutes
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

local function isPetCategory(category)
    return not (category:IsOutfitStylesCategory() or category:IsHousingCategory())
end

local function isPet(collectible)
    return collectible:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_VANITY_PET)
end

function Carousel.Pets:Init()
    self:LoadPets(false)
    if self:Enabled() then
        self:RegisterNext()
    end
end

-- TODO: recompute if pets change
function Carousel.Pets:LoadPets(reload)
    self.ids = {}
    self.next = 1

    for _, cat in ZO_COLLECTIBLE_DATA_MANAGER:CategoryIterator({isPetCategory}) do
        for _, subCat in cat:SubcategoryIterator({isPetCategory}) do
            for _, collect in subCat:CollectibleIterator({isPet}) do
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

function Carousel.Pets:Enable()
    dmsg("enabled (cycle every " .. self:CycleRate_ms() / 1000 .. " seconds)")
    Carousel.options.pets.enabled = true
    self:RegisterNext()
end

function Carousel.Pets:Disable()
    dmsg("disabled")
    Carousel.options.pets.enabled = false
    self:Unregister()
end

function Carousel.Pets:Enabled()
    return Carousel.options.pets.enabled
end

function Carousel.Pets:CycleRate_ms()
    return Carousel.options.pets.rate_s * 1000
end

function Carousel.Pets:SetCycleRate_min(rate_min)
    Carousel.options.pets.rate_s = rate_min * 60
    self:RegisterNext()
end

function Carousel.Pets:Unregister()
    EVENT_MANAGER:UnregisterForUpdate(self.events.next)
end

function Carousel.Pets:RegisterNext()
    if not self:Enabled() then return end

    self:Unregister()
    EVENT_MANAGER:RegisterForUpdate(
        self.events.next,
        self:CycleRate_ms(), -- assume > 0
        function() self:Next() end)
end

-- TODO: allow filtering
function Carousel.Pets:Next()
    if not self:Enabled() then return end

    local petId = self.ids[self.next]
    local pet = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(petId)
    local _, duration = GetCollectibleCooldownAndDuration(petId)

    local function use()
        dmsg("switching active pet to " .. pet:GetName())
        pet:Use()
    end

    if duration > 0 then
        zo_callLater(use, duration)
    else
        use()
    end

    if self.next == #self.ids then
        shuffle(self.ids)
        self.next = 1
    else
        self.next = self.next + 1
    end
end
