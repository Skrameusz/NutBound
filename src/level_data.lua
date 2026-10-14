local enemiesModule = require("src.enemies")
local CatBoss = require("src.boss")

local LevelData = {
    WIDTH_TILES = 105,
    HEIGHT = 720,
    GROUND_ROW = 12,
    ARENA_LEFT_TILE = 68,
    ARENA_RIGHT_TILE = 86,
}

local function addGround(level, firstTX, lastTX, surface, fill)
    for tx = firstTX, lastTX do
        level:setTile(tx, LevelData.GROUND_ROW, surface)
        level:setTile(tx, LevelData.GROUND_ROW + 1, fill)
        level:setTile(tx, LevelData.GROUND_ROW + 2, fill)
    end
end

local function addCollectible(level, itemType, tx, ty, floatTimer)
    table.insert(level.collectibles, {
        type = itemType,
        x = tx * level.ts,
        y = ty * level.ts,
        collected = false,
        floatTimer = floatTimer,
    })
end

function LevelData.createBoss(level)
    return CatBoss.new(78 * level.ts, LevelData.GROUND_ROW * level.ts - 70,
        level.arenaLeft, level.arenaRight)
end

function LevelData.build(self)
    local ts = self.ts
    local groundY = LevelData.GROUND_ROW

    addGround(self, 0, 22, "grass_top", "dirt")

    for ty = 0, groundY do
        self:setTile(0, ty, "dirt")
    end

    self.signboard = {
        x = 2 * ts,
        y = groundY * ts - 44,
        width = 80,
        height = 40,
    }

    self:setTile(8, groundY - 1, "stone")

    self:addPlatform(10, groundY - 3, 3)
    self:addPlatform(15, groundY - 3, 3)

    addCollectible(self, "acorn", 4, groundY - 1, 0)
    addCollectible(self, "acorn", 11.5, groundY - 4, 1)
    addCollectible(self, "acorn", 16.5, groundY - 4, 2)
    addCollectible(self, "acorn", 20, groundY - 1, 0.5)

    table.insert(self.enemies, enemiesModule.Hedgehog.new(18 * ts, groundY * ts - 26, 120))

    addGround(self, 23, 42, "grass_top", "dirt")

    self:addPlatform(25, groundY - 3, 3)
    self:addPlatform(30, groundY - 4, 3)
    self:addPlatform(35, groundY - 3, 3)

    addCollectible(self, "acorn", 26.5, groundY - 4, 0.8)
    addCollectible(self, "acorn", 31.5, groundY - 5, 1.2)
    addCollectible(self, "acorn", 36.5, groundY - 4, 0.4)
    addCollectible(self, "acorn", 40, groundY - 1, 1.8)

    table.insert(self.enemies, enemiesModule.Crow.new(31 * ts, 4.5 * ts))

    table.insert(self.enemies, enemiesModule.Hedgehog.new(33 * ts, groundY * ts - 26, 140))

    addGround(self, 43, 46, "grass_top", "dirt")

    for tx = 47, 54 do
        self:setTile(tx, groundY + 2, "dirt")
        table.insert(self.spikes, { x = tx * ts, y = (groundY + 1) * ts + 16, width = ts, height = 32 })
    end

    self:addPlatform(47, groundY - 2, 2)

    self:addMovingPlatform(50 * ts, 53 * ts, (groundY - 2) * ts, 2 * ts)

    table.insert(self.enemies, enemiesModule.Crow.new(51 * ts, 4 * ts))

    self:addPlatform(49, groundY - 6, 3)
    addCollectible(self, "chestnut", 50.5, groundY - 7, 0)
    addCollectible(self, "acorn", 49.5, groundY - 7, 0.5)
    addCollectible(self, "acorn", 51.5, groundY - 7, 1.5)

    addCollectible(self, "acorn", 51, groundY - 4, 0.2)

    addGround(self, 55, 67, "grass_top", "dirt")

    table.insert(self.enemies, enemiesModule.Beetle.new(57 * ts, groundY * ts - 30, 160))
    addCollectible(self, "acorn", 60, groundY - 1, 0.7)

    self.checkpoint = {
        x = 64 * ts,
        y = groundY * ts - 60,
        width = 36,
        height = 60,
        active = false
    }

    addCollectible(self, "acorn", 65.5, groundY - 1, 1.1)

    addGround(self, 68, 86, "stone", "stone")

    self:setArenaGate("right", true)

    self.boss = LevelData.createBoss(self)

    addGround(self, 87, 104, "grass_top", "dirt")

    for ty = 0, groundY do
        self:setTile(104, ty, "dirt")
    end

    addCollectible(self, "acorn", 89, groundY - 1, 0.3)
    addCollectible(self, "acorn", 91, groundY - 1, 0.9)
    addCollectible(self, "acorn", 93, groundY - 1, 1.4)

    self.hollow = {
        x = 96 * ts,
        y = groundY * ts - 150,
        width = 110,
        height = 150
    }
end

function LevelData.populateFoliage(self)
    local ts = self.ts
    local groundY = LevelData.GROUND_ROW * ts

    local function addPlant(px, py, pType, w, h)
        table.insert(self.plants, {
            x = px,
            y = py - h,
            type = pType,
            width = w,
            height = h,
            swayTimer = math.random() * 10,
            bendOffset = 0,
            rustleCooldown = 0
        })
    end

    addPlant(2 * ts, groundY, "plant_grass", 28, 24)
    addPlant(5 * ts, groundY, "plant_flower", 22, 24)
    addPlant(6.5 * ts, groundY, "plant_bush", 38, 26)
    addPlant(10 * ts, (LevelData.GROUND_ROW - 3) * ts, "plant_fern", 34, 28)
    addPlant(12 * ts, (LevelData.GROUND_ROW - 3) * ts, "plant_grass", 28, 24)
    addPlant(15 * ts, groundY, "plant_fern", 34, 28)
    addPlant(17 * ts, (LevelData.GROUND_ROW - 3) * ts, "plant_flower", 22, 24)
    addPlant(21 * ts, groundY, "plant_bush", 38, 26)

    addPlant(24 * ts, groundY, "plant_grass", 28, 24)
    addPlant(26 * ts, (LevelData.GROUND_ROW - 3) * ts, "plant_fern", 34, 28)
    addPlant(28 * ts, groundY, "plant_bush", 38, 26)
    addPlant(31 * ts, (LevelData.GROUND_ROW - 4) * ts, "plant_flower", 22, 24)
    addPlant(34 * ts, groundY, "plant_grass", 28, 24)
    addPlant(36 * ts, (LevelData.GROUND_ROW - 3) * ts, "plant_fern", 34, 28)
    addPlant(39 * ts, groundY, "plant_flower", 22, 24)

    addPlant(44 * ts, groundY, "plant_bush", 38, 26)
    addPlant(45.5 * ts, groundY, "plant_grass", 28, 24)
    addPlant(49 * ts, (LevelData.GROUND_ROW - 6) * ts, "plant_fern", 34, 28)
    addPlant(51 * ts, (LevelData.GROUND_ROW - 6) * ts, "plant_flower", 22, 24)
    addPlant(56 * ts, groundY, "plant_fern", 34, 28)
    addPlant(58 * ts, groundY, "plant_grass", 28, 24)
    addPlant(62 * ts, groundY, "plant_bush", 38, 26)
    addPlant(65 * ts, groundY, "plant_flower", 22, 24)

    addPlant(88 * ts, groundY, "plant_grass", 28, 24)
    addPlant(90 * ts, groundY, "plant_bush", 38, 26)
    addPlant(92 * ts, groundY, "plant_fern", 34, 28)
    addPlant(94 * ts, groundY, "plant_flower", 22, 24)
    addPlant(99 * ts, groundY, "plant_bush", 38, 26)
    addPlant(101 * ts, groundY, "plant_grass", 28, 24)
end

return LevelData
