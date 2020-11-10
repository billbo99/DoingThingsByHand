data:extend(
    {
        -- runtime-global
        {name = "DoingThingsByHand-crafting", type = "int-setting", default_value = 1, minimum_value = 1, setting_type = "runtime-global", order = "0010"},
        {name = "DoingThingsByHand-mining", type = "int-setting", default_value = 1, minimum_value = 1, setting_type = "runtime-global", order = "0020"},
        {name = "DoingThingsByHand-running", type = "int-setting", default_value = 32, minimum_value = 32, setting_type = "runtime-global", order = "0030"},
        --
        {name = "DoingThingsByHand-disable-crafting", type = "bool-setting", default_value = true, setting_type = "runtime-global", order = "0110"},
        {name = "DoingThingsByHand-disable-mining", type = "bool-setting", default_value = true, setting_type = "runtime-global", order = "0110"},
        {name = "DoingThingsByHand-disable-running", type = "bool-setting", default_value = true, setting_type = "runtime-global", order = "0110"},
        -- per player
        {name = "DoingThingsByHand-player-max-crafting", type = "int-setting", default_value = -1, setting_type = "runtime-per-user", order = "0100"},
        {name = "DoingThingsByHand-player-max-mining", type = "int-setting", default_value = -1, setting_type = "runtime-per-user", order = "0120"},
        {name = "DoingThingsByHand-player-max-running", type = "int-setting", default_value = -1, setting_type = "runtime-per-user", order = "0130"}
    }
)
