require "util"

local Gui = require("gui")

local function CurrentLevel(param)
    return (math.sqrt(param + 25) + 5) / 10
end

local function ReApplyBonus(player)
    if player.controller_type == defines.controllers.character then
        -- crafting
        if not settings.global["DoingThingsByHand-disable-crafting_bonus"].value then
            local modifier = (math.floor(CurrentLevel(global.players[player.name].crafting.count)) - 1) * 0.1
            local player_setting = settings.get_player_settings(player)["DoingThingsByHand-player-max-crafting"].value
            if player_setting > 65536 then
                player_setting = 65536
            end

            if player_setting and player_setting > 1 and (modifier * 100) > player_setting then
                modifier = player_setting / 100
            end

            if modifier ~= math.huge then
                player.character_crafting_speed_modifier = modifier
            end
        else
            player.character_crafting_speed_modifier = 0
        end

        -- mining
        if not settings.global["DoingThingsByHand-disable-mining_bonus"].value then
            local modifier = (math.floor(CurrentLevel(global.players[player.name].mining.count)) - 1) * 0.1
            local player_setting = settings.get_player_settings(player)["DoingThingsByHand-player-max-mining"].value
            if player_setting > 65536 then
                player_setting = 65536
            end

            if player_setting and player_setting > 1 and (modifier * 100) > player_setting then
                modifier = player_setting / 100
            end
            if modifier ~= math.huge then
                player.character_mining_speed_modifier = modifier
            end
        else
            player.character_mining_speed_modifier = 0
        end

        -- running
        if not settings.global["DoingThingsByHand-disable-running_bonus"].value then
            local modifier = (math.floor(CurrentLevel(global.players[player.name].running.count)) - 1) * 0.1
            local player_setting = settings.get_player_settings(player)["DoingThingsByHand-player-max-running"].value
            if player_setting > 65536 then
                player_setting = 65536
            end

            if player_setting and player_setting > 1 and (modifier * 100) > player_setting then
                modifier = player_setting / 100
            end
            if modifier ~= math.huge then
                player.character_running_speed_modifier = modifier
            end
        else
            player.character_running_speed_modifier = 0
        end

        -- health
        if not settings.global["DoingThingsByHand-disable-health_bonus"].value then
            local max_health = player.character.prototype.max_health
            local modifier = (math.floor(CurrentLevel(global.players[player.name].health.count)) - 1) * (max_health * 0.1)
            local player_setting = settings.get_player_settings(player)["DoingThingsByHand-player-max-health"].value
            if player_setting > 65536 then
                player_setting = 65536
            end

            if player_setting and player_setting > 1 and modifier > player_setting then
                modifier = player_setting
            end
            if modifier ~= math.huge then
                player.character_health_bonus = modifier
            end
        else
            player.character_health_bonus = 0
        end
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
    if global.players[player.name].health == nil then
        global.players[player.name].health = {count = 0, level = 1, temp_data = {}}
    end
    ReApplyBonus(player)
end

local function ReApplyBonuses(e)
    for _, player in pairs(game.connected_players) do
        FixPlayerRecord(player)
    end
end

local function OnInit(e)
    global.queue = global.queue or {}
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

        -- Migration to add health
        for _, player in pairs(game.players) do
            if global.players and global.players[player.name] and global.players[player.name].health == nil then
                global.players[player.name].health = {count = 0, level = 1, temp_data = {}}
            end
        end

        global.print_colour = {r = 255, g = 255, b = 0}
    end
end

local function EatRawFish(player)
    if player.controller_type == defines.controllers.character then
        if global.players[player.name] == nil or global.players[player.name].health == nil then
            FixPlayerRecord(player)
        end
        local points = global.players[player.name].health.temp_data.post - global.players[player.name].health.temp_data.pre
        if points > 10 then
            points = points / settings.global["DoingThingsByHand-health"].value

            local playerHealth = global.players[player.name].health
            local max_health = player.character.prototype.max_health
            local health_bonus = (max_health + player.character_health_bonus) / max_health
            playerHealth.count = playerHealth.count + (points / health_bonus)

            local current_level = math.floor(CurrentLevel(playerHealth.count))
            if current_level ~= playerHealth.level then
                playerHealth.level = current_level
                ReApplyBonus(player)
                player.print("Health bonus has now been increased to .. " .. tostring(player.character_health_bonus), global.print_colour)
            end
        end
    end
end

local function OnScriptTriggerEffect(e)
    if e.effect_id == "eat_raw_fish_pre_id" then
        local player = e.source_entity.player
        if global.players[player.name] == nil or global.players[player.name].health == nil then
            FixPlayerRecord(player)
        end
        global.players[player.name].health.temp_data.pre = e.source_entity.health
    end
    if e.effect_id == "eat_raw_fish_post_id" then
        local player = e.source_entity.player
        global.players[player.name].health.temp_data.post = e.source_entity.health
        EatRawFish(player)
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
        playerMining.count = playerMining.count + (points / (player.character_mining_speed_modifier + 1))

        local current_level = math.floor(CurrentLevel(playerMining.count))

        if current_level ~= playerMining.level then
            playerMining.level = current_level
            ReApplyBonus(player)
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
        playerCrafting.count = playerCrafting.count + (points / (player.character_crafting_speed_modifier + 1))

        local current_level = math.floor(CurrentLevel(playerCrafting.count))

        if current_level ~= playerCrafting.level then
            playerCrafting.level = current_level
            ReApplyBonus(player)
            player.print("Crafting speed bonus has now been increased to .. " .. tostring(player.character_crafting_speed_modifier * 100) .. "%", global.print_colour)
        end
    end
end

local function TrackDistanceTravelledByPlayer(player)
    if player.controller_type == defines.controllers.character then
        if player.walking_state.walking then
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
                playerRunning.count = playerRunning.count + (distance_walked / (player.character_running_speed_modifier + 1))

                if global.players[player.name].debug then
                    local msg = string.format("TrackDistanceTravelledByPlayer,%s,%d,%f,%f,%f,%f,%f,%f\n", player.name, game.tick, last_pos.x, last_pos.y, curr_pos.x, curr_pos.y, distance_walked, playerRunning.count)
                    log(msg)
                end

                local current_level = math.floor(CurrentLevel(playerRunning.count))

                if current_level ~= playerRunning.level then
                    playerRunning.level = current_level
                    ReApplyBonus(player)
                    player.print("Running speed bonus has now been increased to .. " .. tostring(player.character_running_speed_modifier * 100) .. "%", global.print_colour)
                end
            end
        end
    end
end

local function TrackDistanceTravelled(e)
    for _, player in pairs(game.connected_players) do
        TrackDistanceTravelledByPlayer(player)
    end
end

local function OnRuntimeModSettingChanged(e)
    if game.mod_setting_prototypes[e.setting].mod == "DoingThingsByHand" then
        global.cache = {}

        if e.setting_type == "runtime-per-user" then
            local player = game.get_player(e.player_index)
            ReApplyBonus(player)
        else
            for _, player in pairs(game.players) do
                ReApplyBonus(player)
            end
        end
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
        local playerHealth = global.players[player.name].health

        if settings.global["DoingThingsByHand-disable-crafting_bonus"].value then
            calling_player.print("Crafting bonus .. disabled")
        else
            calling_player.print(string.format("Crafting .. (Level .. %2.2f) .. (Bonus %d%%)", CurrentLevel(playerCrafting.count), player.character_crafting_speed_modifier * 100), global.print_colour)
        end

        if settings.global["DoingThingsByHand-disable-mining_bonus"].value then
            calling_player.print("Mining bonus .. disabled")
        else
            calling_player.print(string.format("Mining .. (Level .. %2.2f) .. (Bonus %d%%)", CurrentLevel(playerMining.count), player.character_mining_speed_modifier * 100), global.print_colour)
        end

        if settings.global["DoingThingsByHand-disable-running_bonus"].value then
            calling_player.print("Running bonus .. disabled")
        else
            calling_player.print(string.format("Running .. (Level .. %2.2f) .. (Bonus %d%%)", CurrentLevel(playerRunning.count), player.character_running_speed_modifier * 100), global.print_colour)
        end

        if settings.global["DoingThingsByHand-disable-health_bonus"].value then
            calling_player.print("Health bonus .. disabled")
        else
            calling_player.print(string.format("Health .. (Level .. %2.2f) .. (Bonus %d)", CurrentLevel(playerHealth.count), player.character_health_bonus), global.print_colour)
        end
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
script.on_event(defines.events.on_script_trigger_effect, OnScriptTriggerEffect)
