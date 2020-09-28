require "util"

local function CurrentLevel(param)
    return (math.sqrt(param + 25) + 5) / 10
end

local function ReApplyBonus(player)
    if player.controller_type == defines.controllers.character then
        player.character_crafting_speed_modifier = (math.floor(CurrentLevel(global.players[player.name].crafting.count)) - 1) * 0.1
        player.character_mining_speed_modifier = (math.floor(CurrentLevel(global.players[player.name].mining.count)) - 1) * 0.1
    end
end

local function FixPlayerRecord(player)
    if global.players[player.name] == nil then
        global.players[player.name] = {}
    end
    if global.players[player.name].crafting == nil then
        global.players[player.name].crafting = {count = 0, level = 1}
    end
    if global.players[player.name].mining == nil then
        global.players[player.name].mining = {count = 0, level = 1}
    end
    ReApplyBonus(player)
end

local function ReApplyBonuses(e)
    for ixd, _ in pairs(game.connected_players) do
        local player = game.get_player(ixd)
        FixPlayerRecord(player)
    end
end

local function OnInit(e)
    global.players = global.players or {}
    global.print_colour = {r = 255, g = 255, b = 0}
end

local function OnLoad(e)
end

local function OnConfigurationChanged(e)
    if e.mod_changes and e.mod_changes["DoingThingsByHand"] then
        -- migrate to new dict structure
        if global.players == nil then
            global.players = {}
            for idx, _ in pairs(global.crafting) do
                local player = game.get_player(idx)
                if player then
                    if global.players[player.name] == nil then
                        global.players[player.name] = {}
                    end
                    global.players[player.name].crafting = table.deepcopy(global.crafting[idx])
                end
            end
            for idx, _ in pairs(global.mining) do
                local player = game.get_player(idx)
                if player then
                    if global.players[player.name] == nil then
                        global.players[player.name] = {}
                    end
                    global.players[player.name].mining = table.deepcopy(global.mining[idx])
                end
            end
            if global.crafting then
                global.crafting = nil
            end
            if global.mining then
                global.mining = nil
            end
        end
        global.print_colour = {r = 255, g = 255, b = 0}
    end
end

local function OnPlayerMinedEntity(e)
    local player = game.get_player(e.player_index)
    if global.players[player.name] == nil or global.players[player.name].mining == nil then
        FixPlayerRecord(player)
    end

    local playerMining = global.players[player.name].mining
    playerMining.count = playerMining.count + 1

    local current_level = math.floor(CurrentLevel(playerMining.count))

    if current_level ~= playerMining.level then
        playerMining.level = current_level
        player.character_mining_speed_modifier = (playerMining.level - 1) * 0.1
        player.print("Mining speed bonus has now been increased to .. " .. tostring(player.character_mining_speed_modifier * 100) .. "%", global.print_colour)
    end
end

local function OnPlayerCraftedItem(e)
    local player = game.get_player(e.player_index)
    if global.players[player.name] == nil or global.players[player.name].crafting == nil then
        FixPlayerRecord(player)
    end

    local playerCrafting = global.players[player.name].crafting
    playerCrafting.count = playerCrafting.count + 1

    local current_level = math.floor(CurrentLevel(playerCrafting.count))

    if current_level ~= playerCrafting.level then
        playerCrafting.level = current_level
        player.character_crafting_speed_modifier = (playerCrafting.level - 1) * 0.1
        player.print("Crafting speed bonus has now been increased to .. " .. tostring(player.character_crafting_speed_modifier * 100) .. "%", global.print_colour)
    end
end

local function OnPlayerCreated(e)
    local player = game.get_player(e.player_index)
    FixPlayerRecord(player)
end

local function OnPlayerJoinedGame(e)
    OnPlayerCreated(e)
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

        FixPlayerRecord(player)
        local playerCrafting = global.players[player.name].crafting
        local playerMining = global.players[player.name].mining

        calling_player.print(string.format("Mining .. (Level .. %2.2f) .. (Bonus %d%%)", CurrentLevel(playerMining.count), player.character_mining_speed_modifier * 100), global.print_colour)
        calling_player.print(string.format("Crafting .. (Level .. %2.2f) .. (Bonus %d%%)", CurrentLevel(playerCrafting.count), player.character_crafting_speed_modifier * 100), global.print_colour)
    end
)

script.on_init(OnInit)
script.on_load(OnLoad)
script.on_configuration_changed(OnConfigurationChanged)
script.on_nth_tick(1800, ReApplyBonuses)
script.on_event(defines.events.on_player_crafted_item, OnPlayerCraftedItem)
script.on_event(defines.events.on_player_mined_entity, OnPlayerMinedEntity)
script.on_event(defines.events.on_player_joined_game, OnPlayerJoinedGame)
script.on_event(defines.events.on_player_respawned, ReApplyBonuses)
script.on_event(defines.events.on_player_created, OnPlayerCreated)
