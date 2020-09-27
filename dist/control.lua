local function CurrentLevel(xp)
    return (math.sqrt(xp + 25) + 5) / 10
end

local function GetPlayerStats(player_index, stat_name)
    return global[stat_name][player_index] or {count = 0, level = 1}
end

local function OnInit(e)
    global.crafting = {}
    global.mining = {}
    global.print_colour = {r = 255, g = 255, b = 0}
end

local function OnLoad(e)
end

local function OnConfigurationChanged(e)
    if e.mod_changes and e.mod_changes["DoingThingsByHand"] then
        global.crafting = global.crafting or {}
        global.mining = global.mining or {}
        global.print_colour = {r = 255, g = 255, b = 0}
    end
end

local function OnPlayerMinedEntity(e)
    -- Add XP for mining
    local playerMining = GetPlayerStats(e.player_index, "mining")
    playerMining.count = playerMining.count + 1

    -- Compute new level
    local current_level = math.floor(CurrentLevel(playerMining.count))

    -- Level up message
    if current_level ~= playerMining.level then
        playerMining.level = current_level
        local player = game.get_player(e.player_index)
        player.character_mining_speed_modifier = (playerMining.level - 1) * 0.1
        player.print("Mining speed bonus has now been increased to .. " .. tostring(player.character_mining_speed_modifier * 100) .. "%", global.print_colour)
    end

    -- Finally set if it was the first mining
    global.mining[e.player_index] = playerMining
end

local function OnPlayerCraftedItem(e)
    -- Add XP for crafing
    local playerCrafting = GetPlayerStats(e.player_index, "crafting")
    playerCrafting.count = playerCrafting.count + 1

    -- Compute new level
    local current_level = math.floor(CurrentLevel(playerCrafting.count))

    -- Level up message
    if current_level ~= playerCrafting.level then
        playerCrafting.level = current_level
        local player = game.get_player(e.player_index)
        player.character_crafting_speed_modifier = (playerCrafting.level - 1) * 0.1
        player.print("Crafting speed bonus has now been increased to .. " .. tostring(player.character_crafting_speed_modifier * 100) .. "%", global.print_colour)
    end

    -- Finally set if it was the first mining
    global.crafting[e.player_index] = playerCrafting
end

local function ReApplyBonuses(e)
    for player_index, _ in pairs(game.connected_players) do
        local player = game.get_player(player_index)
        local playerCrafting = GetPlayerStats(player_index, "crafting")
        local playerMining = GetPlayerStats(player_index, "mining")

        if player.controller_type == defines.controllers.character then
            player.character_crafting_speed_modifier = (math.floor(CurrentLevel(playerCrafting.count)) - 1) * 0.1
            player.character_mining_speed_modifier = (math.floor(CurrentLevel(playerMining.count)) - 1) * 0.1
        end
    end
end

commands.add_command(
    "HowSpeedy",
    "HowSpeedy [player]",
    function(event)
        local calling_player = game.players[event.player_index]
        local player = game.players[event.player_index]
        if event.parameter and game.get_player(event.parameter) then
            player = game.get_player(event.parameter)
        end

        local playerCrafting = GetPlayerStats(player_index, "crafting")
        local playerMining = GetPlayerStats(player_index, "mining")

        calling_player.print(string.format("Mining Level .. %2.2f", CurrentLevel(playerMining.count)), global.print_colour)
        calling_player.print("Mining Bonus .. " .. tostring(player.character_mining_speed_modifier * 100) .. "%", global.print_colour)
        calling_player.print(string.format("Crafting Level .. %2.2f", CurrentLevel(playerCrafting.count)), global.print_colour)
        calling_player.print("Crafting Bonus .. " .. tostring(player.character_crafting_speed_modifier * 100) .. "%", global.print_colour)
    end
)

script.on_init(OnInit)
script.on_load(OnLoad)
script.on_configuration_changed(OnConfigurationChanged)
script.on_nth_tick(300, ReApplyBonuses)
script.on_event(defines.events.on_player_crafted_item, OnPlayerCraftedItem)
script.on_event(defines.events.on_player_mined_entity, OnPlayerMinedEntity)
script.on_event(defines.events.on_player_joined_game, ReApplyBonuses)
script.on_event(defines.events.on_player_respawned, ReApplyBonuses)
