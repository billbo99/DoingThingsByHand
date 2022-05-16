local Utils = require("utils")

local mod_gui = require("mod-gui")
local Gui = {}

local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

local function CurrentLevel(param)
    return (math.sqrt(param + 25) + 5) / 10
end

function Gui.DestroyGui(player)
    local gui_top = player.gui.top["DoingThingsByHandIcon"]
    local gui_main = player.gui.left["DoingThingsByHandMain"]

    if gui_top ~= nil then
        gui_top.destroy()
    end
    if gui_main ~= nil then
        gui_main.destroy()
    end
end

function Gui.CreateTopGui(player)
    local button_flow = mod_gui.get_button_flow(player)
    local button = button_flow.DoingThingsByHandMainButton
    if not button then
        button =
            button_flow.add {
            type = "sprite-button",
            name = "DoingThingsByHandMainButton",
            sprite = "DoingThingsByHand",
            style = mod_gui.button_style
        }
    end
    return button
end

function Gui.CreateMainGui(player)
    if player.gui.left["DoingThingsByHandMain"] then
        player.gui.left["DoingThingsByHandMain"].destroy()
    end

    if global.players and Utils.TableSize(global.players) > 0 then
        local DoingThingsByHandMain = player.gui.left.add({type = "frame", name = "DoingThingsByHandMain", direction = "vertical"})
        DoingThingsByHandMain.style.minimal_height = 10
        DoingThingsByHandMain.style.minimal_width = 10

        DoingThingsByHandMain.add({type = "label", caption = "Doing Things by Hand", style = "heading_1_label"})

        local headers = {"crafting", "mining", "running", "health"}
        local column_count = (#headers*2) + 1
        local f = DoingThingsByHandMain.add({type = "table", style = "mod_info_table", column_count = column_count})

        f.add({type = "label", caption = "Player", style = "bold_label"})
        for _, header in pairs(headers) do
            f.add({type = "label", caption = firstToUpper(header)})
            if header == "health" then
                f.add({type = "label", caption = "+HP"})
            else
                f.add({type = "label", caption = "Bonus"})
            end
        end

        local score = {}
        for player_name, _ in pairs(global.players) do
            if not score[player_name] then
                score[player_name] = 0
            end
            for _, header in pairs(headers) do
                score[player_name] = score[player_name] + CurrentLevel(global.players[player_name][header].count)
            end
        end

        local rank = Utils.sortedKeys(score)
        for _, player_name in pairs(rank) do
            -- string.format("Mining .. (Level .. %2.3f) .. (Bonus %d%%)", CurrentLevel(playerMining.count)
            local _player = game.get_player(player_name)

            f.add({type = "label", caption = player_name})
            for _, header in pairs(headers) do
                local caption = string.format("Lv %2.2f", CurrentLevel(global.players[player_name][header].count))
                f.add({type = "label", caption = caption})
                if header == "crafting" then
                    caption = tostring(_player.character_crafting_speed_modifier * 100) .. "%"
                elseif header == "mining" then
                    caption = tostring(_player.character_mining_speed_modifier * 100) .. "%"
                elseif header == "running" then
                    caption = tostring(_player.character_running_speed_modifier * 100) .. "%"
                elseif header == "health" then
                    caption = _player.character_health_bonus .. " hp"
                end
                f.add({type = "label", caption = caption})
            end
        end
    end
end

function Gui.onGuiClick(event)
    local player = game.players[event.player_index]
    local element = event.element.name

    if element == "DoingThingsByHandMainButton" then
        if player.gui.left["DoingThingsByHandMain"] then
            player.gui.left["DoingThingsByHandMain"].destroy()
        else
            Gui.CreateMainGui(player)
        end
    end
end

return Gui
