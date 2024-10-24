require "util"

local Gui = require("gui")

local function CurrentLevel(param)
    return (math.sqrt(param + 25) + 5) / 10
end

local function ReApplyBonus(player)
    if player.controller_type == defines.controllers.character then
        -- crafting
        if not settings.global["DoingThingsByHand-disable-crafting_bonus"].value then
            local modifier = (math.floor(CurrentLevel(storage.players[player.name].crafting.count)) - 1) * 0.1
            local player_setting = settings.get_player_settings(player)["DoingThingsByHand-player-max-crafting"].value
            if player_setting > 65000 then
                player_setting = 65000
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
            local modifier = (math.floor(CurrentLevel(storage.players[player.name].mining.count)) - 1) * 0.1
            local player_setting = settings.get_player_settings(player)["DoingThingsByHand-player-max-mining"].value
            if player_setting > 65000 then
                player_setting = 65000
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
            local modifier = (math.floor(CurrentLevel(storage.players[player.name].running.count)) - 1) * 0.1
            local player_setting = settings.get_player_settings(player)["DoingThingsByHand-player-max-running"].value
            if player_setting > 65000 then
                player_setting = 65000
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
            if player.character then
                local max_health = player.character.prototype.get_max_health()
                local modifier = (math.floor(CurrentLevel(storage.players[player.name].health.count)) - 1) * (max_health * 0.1)
                local player_setting = settings.get_player_settings(player)["DoingThingsByHand-player-max-health"].value
                if player_setting > 65000 then
                    player_setting = 65000
                end

                if player_setting and player_setting > 1 and modifier > player_setting then
                    modifier = player_setting
                end
                if modifier ~= math.huge then
                    player.character_health_bonus = modifier
                end
            end
        else
            player.character_health_bonus = 0
        end
    end
end

local function FixPlayerRecord(player)
    if storage.players[player.name] == nil then
        storage.players[player.name] = {}
    end
    if storage.players[player.name].crafting == nil then
        storage.players[player.name].crafting = { count = 0, level = 1 }
    end
    if storage.players[player.name].mining == nil then
        storage.players[player.name].mining = { count = 0, level = 1 }
    end
    if storage.players[player.name].running == nil then
        storage.players[player.name].running = { count = 0, level = 1, last_position = { x = 0, y = 0 } }
    end
    if storage.players[player.name].health == nil then
        storage.players[player.name].health = { count = 0, level = 1, temp_data = {} }
    end
    ReApplyBonus(player)
end

local function ReApplyBonuses(e)
    for _, player in pairs(game.connected_players) do
        FixPlayerRecord(player)
    end
end

local function OnInit(e)
    storage.queue = storage.queue or {}
    storage.tracking = storage.tracking or {}
    storage.cache = storage.cache or {}
    storage.players = storage.players or {}
    storage.print_colour = { r = 255, g = 255, b = 0 }

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
        storage.cache = {}

        -- migrate to new dict structure
        if storage.players == nil then
            storage.players = {}
            for idx, _ in pairs(storage.crafting) do
                local player = game.get_player(idx)
                if player then
                    if storage.players[player.name] == nil then
                        storage.players[player.name] = {}
                    end
                    storage.players[player.name].crafting = table.deepcopy(storage.crafting[idx])
                end
            end
            for idx, _ in pairs(storage.mining) do
                local player = game.get_player(idx)
                if player then
                    if storage.players[player.name] == nil then
                        storage.players[player.name] = {}
                    end
                    storage.players[player.name].mining = table.deepcopy(storage.mining[idx])
                end
            end
            if storage.crafting then
                storage.crafting = nil
            end
            if storage.mining then
                storage.mining = nil
            end
        end

        -- Migration to add health
        for _, player in pairs(game.players) do
            if storage.players and storage.players[player.name] and storage.players[player.name].health == nil then
                storage.players[player.name].health = { count = 0, level = 1, temp_data = {} }
            end
        end

        storage.print_colour = { r = 255, g = 255, b = 0 }
    end
end

local function EatRawFish(player)
    if player.controller_type == defines.controllers.character then
        if storage.players[player.name] == nil or storage.players[player.name].health == nil then
            FixPlayerRecord(player)
        end
        local points = storage.players[player.name].health.temp_data.post - storage.players[player.name].health.temp_data.pre
        if points > 10 and player.character then
            points = points / settings.global["DoingThingsByHand-health"].value

            local playerHealth = storage.players[player.name].health
            local max_health = player.character.prototype.get_max_health()
            local health_bonus = (max_health + player.character_health_bonus) / max_health
            playerHealth.count = playerHealth.count + (points / health_bonus)

            local current_level = math.floor(CurrentLevel(playerHealth.count))
            if current_level ~= playerHealth.level then
                playerHealth.level = current_level
                ReApplyBonus(player)
                player.print("Health bonus has now been increased to .. " .. tostring(player.character_health_bonus), storage.print_colour)
            end
        end
    end
end

local function OnScriptTriggerEffect(e)
    if e.effect_id == "eat_raw_fish_pre_id" then
        local player = e.source_entity.player
        if storage.players[player.name] == nil or storage.players[player.name].health == nil then
            FixPlayerRecord(player)
        end
        storage.players[player.name].health.temp_data.pre = e.source_entity.health
    end
    if e.effect_id == "eat_raw_fish_post_id" then
        local player = e.source_entity.player
        storage.players[player.name].health.temp_data.post = e.source_entity.health
        EatRawFish(player)
    end
end

local function OnPlayerMinedEntity(e)
    local player = game.get_player(e.player_index)

    if player and player.controller_type == defines.controllers.character then
        if storage.players[player.name] == nil or storage.players[player.name].mining == nil then
            FixPlayerRecord(player)
        end

        local points = 1
        if storage.cache[e.entity.name] then
            points = storage.cache[e.entity.name]
        elseif e.entity and e.entity.prototype and e.entity.prototype.mineable_properties and e.entity.prototype.mineable_properties.mining_time then
            points = e.entity.prototype.mineable_properties.mining_time / settings.global["DoingThingsByHand-mining"].value
            storage.cache[e.entity.name] = points
        end

        local playerMining = storage.players[player.name].mining
        playerMining.count = playerMining.count + (points / (player.character_mining_speed_modifier + 1))

        local p_name = player.name
        local i_name = "[img=item." .. e.entity.name .. "]"
        if not (helpers.is_valid_sprite_path("item." .. e.entity.name)) and helpers.is_valid_sprite_path("entity." .. e.entity.name) then
            i_name = "[img=entity." .. e.entity.name .. "]"
        end

        storage.tracking.mining = storage.tracking.mining or {}
        storage.tracking.mining[p_name] = storage.tracking.mining[player.name] or {}
        storage.tracking.mining[p_name][i_name] = storage.tracking.mining[p_name][i_name] or 0
        storage.tracking.mining[p_name][i_name] = storage.tracking.mining[p_name][i_name] + 1

        local current_level = math.floor(CurrentLevel(playerMining.count))

        if current_level ~= playerMining.level then
            playerMining.level = current_level
            ReApplyBonus(player)
            player.print("Mining speed bonus has now been increased to .. " .. tostring(player.character_mining_speed_modifier * 100) .. "%", storage.print_colour)
        end
    end
end

local function OnPlayerCraftedItem(e)
    local player = game.get_player(e.player_index)
    if player and player.controller_type == defines.controllers.character then
        if storage.players[player.name] == nil or storage.players[player.name].crafting == nil then
            FixPlayerRecord(player)
        end

        local points = 1
        if storage.cache[e.recipe.name] then
            points = storage.cache[e.recipe.name]
        elseif e.recipe and e.recipe.energy then
            points = e.recipe.energy / settings.global["DoingThingsByHand-crafting"].value
            storage.cache[e.recipe.name] = points
        end

        local playerCrafting = storage.players[player.name].crafting
        playerCrafting.count = playerCrafting.count + (points / (player.character_crafting_speed_modifier + 1))

        local p_name = player.name
        local i_name = "[img=recipe." .. e.recipe.name .. "]"
        storage.tracking.crafting = storage.tracking.crafting or {}
        storage.tracking.crafting[p_name] = storage.tracking.crafting[player.name] or {}
        storage.tracking.crafting[p_name][i_name] = storage.tracking.crafting[p_name][i_name] or 0
        storage.tracking.crafting[p_name][i_name] = storage.tracking.crafting[p_name][i_name] + 1

        local current_level = math.floor(CurrentLevel(playerCrafting.count))

        if current_level ~= playerCrafting.level then
            playerCrafting.level = current_level
            ReApplyBonus(player)
            player.print("Crafting speed bonus has now been increased to .. " .. tostring(player.character_crafting_speed_modifier * 100) .. "%", storage.print_colour)
        end
    end
end

local function TrackDistanceTravelledByPlayer(player)
    if player and player.controller_type == defines.controllers.character then
        if player.walking_state.walking and player.character.name == "character" then
            if storage.players[player.name] == nil or storage.players[player.name].running == nil then
                FixPlayerRecord(player)
            end

            local last_pos = table.deepcopy(storage.players[player.name].running.last_position)
            local curr_pos = table.deepcopy(player.position)

            storage.players[player.name].running.last_position = table.deepcopy(player.position)

            if last_pos and curr_pos and last_pos.x and last_pos.y and curr_pos.x and curr_pos.y then
                local delta_x = math.abs(last_pos.x - curr_pos.x)
                local delta_y = math.abs(last_pos.y - curr_pos.y)
                local distance_walked = math.sqrt(delta_x ^ 2 + delta_y ^ 2) / settings.global["DoingThingsByHand-running"].value

                local playerRunning = storage.players[player.name].running
                playerRunning.count = playerRunning.count + (distance_walked / (player.character_running_speed_modifier + 1))

                if storage.players[player.name].debug then
                    local msg = string.format("TrackDistanceTravelledByPlayer,%s,%d,%f,%f,%f,%f,%f,%f\n", player.name, game.tick, last_pos.x, last_pos.y, curr_pos.x, curr_pos.y, distance_walked, playerRunning.count)
                    log(msg)
                end

                local current_level = math.floor(CurrentLevel(playerRunning.count))

                if current_level ~= playerRunning.level then
                    playerRunning.level = current_level
                    ReApplyBonus(player)
                    player.print("Running speed bonus has now been increased to .. " .. tostring(player.character_running_speed_modifier * 100) .. "%", storage.print_colour)
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
    if prototypes.mod_setting[e.setting].mod == "DoingThingsByHand" then
        storage.cache = {}

        if e.setting_type == "runtime-per-user" then
            local player = game.get_player(e.player_index)
            ReApplyBonus(player)
        else
            for _, player in pairs(game.players) do
                if not storage.players[player.name] then
                    FixPlayerRecord(player)
                end
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

local function OnPlayerRespawned(e)
    local player = game.get_player(e.player_index)
    FixPlayerRecord(player)
    if player and player.gui.left["DoingThingsByHandMain"] then
        player.gui.left["DoingThingsByHandMain"].destroy()
        Gui.CreateMainGui(player)
    end
end

commands.add_command(
    "DoingThingsByHand_Debug",
    "DoingThingsByHand_Debug [player]",
    function(event)
        local player = game.players[event.player_index]
        if event.parameter and game.get_player(event.parameter) then
            player = game.get_player(event.parameter)
        end

        if storage.players[player.name].debug then
            storage.players[player.name].debug = nil
        else
            storage.players[player.name].debug = true
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
        local playerCrafting = storage.players[player.name].crafting
        local playerMining = storage.players[player.name].mining
        local playerRunning = storage.players[player.name].running
        local playerHealth = storage.players[player.name].health

        if settings.global["DoingThingsByHand-disable-crafting_bonus"].value then
            calling_player.print("Crafting bonus .. disabled")
        else
            calling_player.print(string.format("Crafting .. (Level .. %2.2f) .. (Bonus %d%%)", CurrentLevel(playerCrafting.count), player.character_crafting_speed_modifier * 100), storage.print_colour)
        end

        if settings.global["DoingThingsByHand-disable-mining_bonus"].value then
            calling_player.print("Mining bonus .. disabled")
        else
            calling_player.print(string.format("Mining .. (Level .. %2.2f) .. (Bonus %d%%)", CurrentLevel(playerMining.count), player.character_mining_speed_modifier * 100), storage.print_colour)
        end

        if settings.global["DoingThingsByHand-disable-running_bonus"].value then
            calling_player.print("Running bonus .. disabled")
        else
            calling_player.print(string.format("Running .. (Level .. %2.2f) .. (Bonus %d%%)", CurrentLevel(playerRunning.count), player.character_running_speed_modifier * 100), storage.print_colour)
        end

        if settings.global["DoingThingsByHand-disable-health_bonus"].value then
            calling_player.print("Health bonus .. disabled")
        else
            calling_player.print(string.format("Health .. (Level .. %2.2f) .. (Bonus %d)", CurrentLevel(playerHealth.count), player.character_health_bonus), storage.print_colour)
        end
    end
)

local function on_character_swapped_event(data)
    for _, player in pairs(game.connected_players) do
        if player.character and player.character.unit_number == data.new_unit_number then
            FixPlayerRecord(player)
        end
    end
end

remote.add_interface("DoingThingsByHand", { on_character_swapped = on_character_swapped_event })

script.on_init(OnInit)
script.on_load(OnLoad)
script.on_configuration_changed(OnConfigurationChanged)
script.on_nth_tick(1800, ReApplyBonuses)
script.on_nth_tick(61, TrackDistanceTravelled)
script.on_event(defines.events.on_runtime_mod_setting_changed, OnRuntimeModSettingChanged)
script.on_event(defines.events.on_player_crafted_item, OnPlayerCraftedItem)
script.on_event(defines.events.on_player_mined_entity, OnPlayerMinedEntity)
script.on_event(defines.events.on_player_joined_game, OnPlayerJoinedGame)
script.on_event(defines.events.on_player_respawned, OnPlayerRespawned)
script.on_event(defines.events.on_player_created, OnPlayerCreated)
script.on_event(defines.events.on_gui_click, OnGuiClick)
script.on_event(defines.events.on_script_trigger_effect, OnScriptTriggerEffect)
