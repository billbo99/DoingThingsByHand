local function OnInit(e)
    global.crafting = {}
    global.mining = {}
end

local function OnLoad(e)
end

local function OnConfigurationChanged(e)
    if e.mod_changes and e.mod_changes["DoingThingsByHand"] then
        global.crafting = global.crafting or {}
        global.mining = global.mining or {}
    end
end

local function OnPlayerMinedEntity(e)
    global.mining[e.player_index] = global.mining[e.player_index] or {count = 0, level = 1}
    local playerMining = global.mining[e.player_index]
    playerMining.count = playerMining.count + 1

    local sqrt = math.sqrt
    -- local current_level = math.floor((sqrt(5) * sqrt(playerCrafting.count + 125) + 25) / 50)
    local current_level = math.floor((sqrt(playerMining.count + 25) + 5) / 10)

    if current_level ~= playerMining.level then
        playerMining.level = current_level
        local player = game.get_player(e.player_index)
        player.character_mining_speed_modifier = (playerMining.level - 1) * 0.1
        player.print("Mining speed bonus has now been increased to .. " .. tostring(player.character_mining_speed_modifier * 100) .. "%")
    end
end

local function OnPlayerCraftedItem(e)
    global.crafting[e.player_index] = global.crafting[e.player_index] or {count = 0, level = 1}
    local playerCrafting = global.crafting[e.player_index]
    playerCrafting.count = playerCrafting.count + 1

    local sqrt = math.sqrt
    -- local current_level = math.floor((sqrt(5) * sqrt(playerCrafting.count + 125) + 25) / 50)
    local current_level = math.floor((sqrt(playerCrafting.count + 25) + 5) / 10)

    if current_level ~= playerCrafting.level then
        playerCrafting.level = current_level
        local player = game.get_player(e.player_index)
        player.character_crafting_speed_modifier = (playerCrafting.level - 1) * 0.1
        player.print("Crafting speed bonus has now been increased to .. " .. tostring(player.character_crafting_speed_modifier * 100) .. "%")
    end
end

script.on_init(OnInit)
script.on_load(OnLoad)
script.on_configuration_changed(OnConfigurationChanged)
script.on_event(defines.events.on_player_crafted_item, OnPlayerCraftedItem)
script.on_event(defines.events.on_player_mined_entity, OnPlayerMinedEntity)
