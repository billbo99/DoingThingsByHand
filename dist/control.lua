-- Generic stat function
local GenericStat = {}

function GenericStat.Get(player_index, stat_name)
    return global[stat_name][player_index] or {count = 0, level = 1}
end
function GenericStat.IncreaseValue(player_index, stat_name)
    local playerStat = GenericStat.Get(player_index, stat_name)
    playerStat.count = playerStat.count + 1
    global[stat_name][player_index] = playerStat
    return playerStat
end
function GenericStat.SetValue(player_index, stat_name, value)
    local playerStat = GenericStat.Get(player_index, stat_name)
    playerStat.count = value
    global[stat_name][player_index] = playerStat
    return playerStat
end


function GenericStat.Level(xp)
    return math.floor((math.sqrt(xp + 25) + 5) / 10)
end
function GenericStat.Bonus(xp)
    return (GenericStat.Level(xp) - 1) * 0.1
end

-- Print message for indicating the current level
-- TODO: use localized string (see Deadlocks's research notifications)
function GenericStat.PrintStat(player, icon, level_up, bonus_name, xp)
    if level_up then level_up = "Level UP! " else level_up = "" end
    player.print(
        string.format(
            "%s %sYour %s level is %s, giving you a %d%% speed bonus.",
            icon,
            level_up,
            bonus_name,
            GenericStat.Level(xp),
            math.floor((GenericStat.Bonus(xp)) * 100)
        ),
        global.print_colour
    )
end

function GenericStat.ProcessIncrease(player_index, stat, bonus_modifier)
    -- Add XP for crafing or mining
    local playerStat = GenericStat.IncreaseValue(player_index, stat.stat_name)
    -- Process leveling up
    GenericStat.ProcessIfLevelUpNeeded(player_index, stat, bonus_modifier, playerStat)
end

function GenericStat.ProcessChange(player_index, stat, bonus_monifier, new_value)
    -- Set XP for walking
    local playerStat = GenericStat.SetValue(player_index, stat.stat_name, new_value)
    -- Process leveling up
    GenericStat.ProcessIfLevelUpNeeded(player_index, stat, bonus_modifier, playerStat)
end

function GenericStat.ProcessIfLevelUpNeeded(player_index, stat, bonus_modifier, playerStat)
    -- Stop here is not needed
    if GenericStat.Level(playerStat.count) == playerStat.level then
        return
    end

    local player = game.get_player(player_index)

    -- Apply new bonus
    player[bonus_modifier] = GenericStat.Bonus(playerStat.count)
    playerStat.level = GenericStat.Level(playerStat.count)

    -- Level up message
    stat.Print(player, true, playerStat.count)
end


-- Mining Stat
local MiningStat = {
    icon="[img=technology/steel-axe]",
    stat_name="mining",
    bonus_name="mining"
}
function MiningStat.OnPlayerMinedEntity(e)
    GenericStat.ProcessIncrease(e.player_index, MiningStat, "character_mining_speed_modifier")
end
function MiningStat.Print(player, level_up, xp)
    GenericStat.PrintStat(player, MiningStat.icon, level_up, MiningStat.bonus_name, xp)
end

-- Crafting Stat
local CraftingStat = {
    icon="[img=technology/automation-3]",
    stat_name="crafting",
    bonus_name="crafting"
}
function CraftingStat.OnPlayerCraftedItem(e)
    GenericStat.ProcessIncrease(e.player_index, CraftingStat, "character_crafting_speed_modifier")
end
function CraftingStat.Print(player, level_up, xp)
    GenericStat.PrintStat(player, CraftingStat.icon, level_up, CraftingStat.bonus_name, xp)
end

-- Forcefully reapply bonus
local function ReApplyBonuses(e)
    for player_index, _ in pairs(game.connected_players) do
        local player = game.get_player(player_index)

        if player.controller_type == defines.controllers.character then
            local playerCrafting = GenericStat.Get(player_index, "crafting")
            player.character_crafting_speed_modifier = GenericStat.Bonus(playerCrafting.count)

            local playerMining = GenericStat.Get(player_index, "mining")
            player.character_mining_speed_modifier = GenericStat.Bonus(playerMining.count)
        end
    end
end

-- Command to know player's current level
commands.add_command(
    "HowSpeedy",
    "HowSpeedy [player]",
    function (event)
        local calling_player = game.players[event.player_index]
        local player = game.players[event.player_index]
        if event.parameter and game.get_player(event.parameter) then
            player = game.get_player(event.parameter)
        end

        local playerCrafting = GenericStat.Get(player.index, "crafting")
        CraftingStat.Print(calling_player, false, playerCrafting.count)
        if player.character_crafting_speed_modifier ~= GenericStat.Bonus(playerCrafting.count) then
            calling_player.print(
                string.format(
                    "    - Warning: The registered value is different: %03d%%",
                    player.character_crafting_speed_modifier * 100
                ),
                global.error_colour
            )
        end

        local playerMining = GenericStat.Get(player.index, "mining")
        MiningStat.Print(calling_player, false, playerMining.count)
        if player.character_mining_speed_modifier ~= GenericStat.Bonus(playerMining.count) then
            calling_player.print(
                string.format(
                    "    - Warning: The registered value is different: %03d%%",
                    player.character_mining_speed_modifier * 100
                ),
                global.error_colour
            )
        end
    end
)

-- Register xp gaining
script.on_event(defines.events.on_player_crafted_item, CraftingStat.OnPlayerCraftedItem)
script.on_event(defines.events.on_player_mined_entity, MiningStat.OnPlayerMinedEntity)

-- Reapply the bonuses periodictly because it's sometime reset by other mods
script.on_nth_tick(5 * 60 * 60, ReApplyBonuses) -- Evert 5 minutes
script.on_event(defines.events.on_player_joined_game, ReApplyBonuses) -- On player joining
script.on_event(defines.events.on_player_respawned, ReApplyBonuses) -- On player respawn

-- Control scripts
script.on_init(
    function (e)
        global.crafting = {}
        global.mining = {}
        global.print_colour = {r = 255, g = 255, b = 0}
        global.error_colour = {r = 255, g = 0, b = 0}
    end
)

script.on_load(function (e) end)

script.on_configuration_changed(
    function (e)
        if e.mod_changes and e.mod_changes["DoingThingsByHand"] then
            global.crafting = global.crafting or {}
            global.mining = global.mining or {}
            global.print_colour = {r = 255, g = 255, b = 0}
            global.error_colour = {r = 255, g = 0, b = 0}
        end
    end
)
