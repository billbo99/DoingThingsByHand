require "util"

local Gui = require("gui")

local function CurrentLevel(param)
    return (math.sqrt(param + 25) + 5) / 10
end

local function ReApplyBonus(player)
    if player.controller_type == defines.controllers.character then
        player.character_crafting_speed_modifier = (math.floor(CurrentLevel(global.players[player.name].crafting.count)) - 1) * 0.1
        player.character_mining_speed_modifier = (math.floor(CurrentLevel(global.players[player.name].mining.count)) - 1) * 0.1
        player.character_running_speed_modifier = (math.floor(CurrentLevel(global.players[player.name].running.count)) - 1) * 0.1
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
    if global.players[player.name].running == nil then
        global.players[player.name].running = {count = 0, level = 1, last_position = {x = 0, y = 0}}
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
    global.cache = global.cache or {}
    global.players = global.players or {}
    global.print_colour = {r = 255, g = 255, b = 0}

    for i, _ in pairs(game.players) do
        Gui.CreateTopGui(game.players[i])
    end
end

local function OnLoad(e)
end

local function OnConfigurationChanged(e)
    if e.mod_changes and e.mod_changes["DoingThingsByHand"] then
        OnInit(e)

        -- flush the cache if the mod has changed
        global.cache = {}

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

    if player.controller_type == defines.controllers.character then
        if global.players[player.name] == nil or global.players[player.name].mining == nil then
            FixPlayerRecord(player)
        end

        local points = 1
        if global.cache[e.entity.name] then
            points = global.cache[e.entity.name]
        elseif e.entity and e.entity.prototype and e.entity.prototype.mineable_properties and e.entity.prototype.mineable_properties.mining_time then
            points = e.entity.prototype.mineable_properties.mining_time / settings.global["DoingThingsByHand-mining"].value
            global.cache[e.entity.name] = points
        end

        local playerMining = global.players[player.name].mining
        playerMining.count = playerMining.count + points

        local current_level = math.floor(CurrentLevel(playerMining.count))

        if current_level ~= playerMining.level then
            playerMining.level = current_level
            player.character_mining_speed_modifier = (playerMining.level - 1) * 0.1
            player.print("Mining speed bonus has now been increased to .. " .. tostring(player.character_mining_speed_modifier * 100) .. "%", global.print_colour)
        end
    end
end

local function OnPlayerCraftedItem(e)
    local player = game.get_player(e.player_index)
    if player.controller_type == defines.controllers.character then
        if global.players[player.name] == nil or global.players[player.name].crafting == nil then
            FixPlayerRecord(player)
        end

        local points = 1
        if global.cache[e.recipe.name] then
            points = global.cache[e.recipe.name]
        elseif e.recipe and e.recipe.energy then
            points = e.recipe.energy / settings.global["DoingThingsByHand-crafting"].value
            global.cache[e.recipe.name] = points
        end

        local playerCrafting = global.players[player.name].crafting
        playerCrafting.count = playerCrafting.count + points

        local current_level = math.floor(CurrentLevel(playerCrafting.count))

        if current_level ~= playerCrafting.level then
            playerCrafting.level = current_level
            player.character_crafting_speed_modifier = (playerCrafting.level - 1) * 0.1
            player.print("Crafting speed bonus has now been increased to .. " .. tostring(player.character_crafting_speed_modifier * 100) .. "%", global.print_colour)
        end
    end
end

local function TrackDistanceTravelledByPlayer(player)
    if player.controller_type == defines.controllers.character then
        if (player.afk_time < 30 or player.walking_state.walking) and player.vehicle == nil then
            if global.players[player.name] == nil or global.players[player.name].running == nil then
                FixPlayerRecord(player)
            end

            local last_pos = table.deepcopy(global.players[player.name].running.last_position)
            local curr_pos = table.deepcopy(player.position)

            global.players[player.name].running.last_position = table.deepcopy(player.position)

            if last_pos and curr_pos and last_pos.x and last_pos.y and curr_pos.x and curr_pos.y then
                local delta_x = math.abs(last_pos.x - curr_pos.x)
                local delta_y = math.abs(last_pos.y - curr_pos.y)
                local distance_walked = math.sqrt(delta_x ^ 2 + delta_y ^ 2) / settings.global["DoingThingsByHand-running"].value

                local playerRunning = global.players[player.name].running
                playerRunning.count = playerRunning.count + distance_walked

                if global.players[player.name].debug then
                    local msg = string.format("%s,%d,%f,%f,%f,%f,%f,%f\n", player.name, game.tick, last_pos.x, last_pos.y, curr_pos.x, curr_pos.y, distance_walked, playerRunning.count)
                    if game.is_multiplayer() then
                        game.write_file("TrackDistanceTravelledByPlayer.csv", msg, true, 0)
                    else
                        game.write_file("TrackDistanceTravelledByPlayer.csv", msg, true)
                    end
                end

                local current_level = math.floor(CurrentLevel(playerRunning.count))

                if current_level ~= playerRunning.level then
                    playerRunning.level = current_level
                    player.character_running_speed_modifier = (playerRunning.level - 1) * 0.1
                    player.print("Running speed bonus has now been increased to .. " .. tostring(player.character_running_speed_modifier * 100) .. "%", global.print_colour)
                end
            end
        end
    end
end

local function TrackDistanceTravelled(e)
    for ixd, _ in pairs(game.connected_players) do
        local player = game.get_player(ixd)
        TrackDistanceTravelledByPlayer(player)
    end
end

local function OnRuntimeModSettingChanged(e)
    if game.mod_setting_prototypes[e.setting].mod == "DoingThingsByHand" then
        global.cache = {}
    end
end

local function OnPlayerCreated(e)
    local player = game.get_player(e.player_index)
    Gui.CreateTopGui(game.players[e.player_index])
    FixPlayerRecord(player)
end

local function OnPlayerJoinedGame(e)
    OnPlayerCreated(e)
    Gui.DestroyGui(game.players[e.player_index])
    Gui.CreateTopGui(game.players[e.player_index])
end

local function OnGuiClick(e)
    local mod = e.element.get_mod()
    if mod == nil or mod ~= "DoingThingsByHand" then
        return
    end

    FixPlayerRecord(game.get_player(e.player_index))
    Gui.onGuiClick(e)
end

commands.add_command(
    "DoingThingsByHand_Debug",
    "DoingThingsByHand_Debug [player]",
    function(event)
        local player = game.players[event.player_index]
        if event.parameter and game.get_player(event.parameter) then
            player = game.get_player(event.parameter)
        end

        if global.players[player.name].debug then
            global.players[player.name].debug = nil
        else
            global.players[player.name].debug = true
        end
    end
)

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
        local playerRunning = global.players[player.name].running

        calling_player.print(string.format("Mining .. (Level .. %2.2f) .. (Bonus %d%%)", CurrentLevel(playerMining.count), player.character_mining_speed_modifier * 100), global.print_colour)
        calling_player.print(string.format("Crafting .. (Level .. %2.2f) .. (Bonus %d%%)", CurrentLevel(playerCrafting.count), player.character_crafting_speed_modifier * 100), global.print_colour)
        calling_player.print(string.format("Running .. (Level .. %2.2f) .. (Bonus %d%%)", CurrentLevel(playerRunning.count), player.character_running_speed_modifier * 100), global.print_colour)
    end
)

script.on_init(OnInit)
script.on_load(OnLoad)
script.on_configuration_changed(OnConfigurationChanged)
script.on_nth_tick(1800, ReApplyBonuses)
script.on_nth_tick(61, TrackDistanceTravelled)
script.on_event(defines.events.on_runtime_mod_setting_changed, OnRuntimeModSettingChanged)
script.on_event(defines.events.on_player_crafted_item, OnPlayerCraftedItem)
script.on_event(defines.events.on_player_mined_entity, OnPlayerMinedEntity)
script.on_event(defines.events.on_player_joined_game, OnPlayerJoinedGame)
script.on_event(defines.events.on_player_respawned, ReApplyBonuses)
script.on_event(defines.events.on_player_created, OnPlayerCreated)
script.on_event(defines.events.on_gui_click, OnGuiClick)
