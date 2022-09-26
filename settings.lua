data:extend(
    {
        -- runtime-global
        {name = "DoingThingsByHand-crafting", type = "int-setting", default_value = 1, minimum_value = 1, maximum_value = 65536, setting_type = "runtime-global", order = "0010"},
        {name = "DoingThingsByHand-mining", type = "int-setting", default_value = 1, minimum_value = 1, maximum_value = 65536, setting_type = "runtime-global", order = "0020"},
        {name = "DoingThingsByHand-running", type = "int-setting", default_value = 32, minimum_value = 32, maximum_value = 65536, setting_type = "runtime-global", order = "0030"},
        {name = "DoingThingsByHand-health", type = "int-setting", default_value = 5, minimum_value = 1, maximum_value = 65536, setting_type = "runtime-global", order = "0040"},
        --
        {name = "DoingThingsByHand-disable-crafting_bonus", type = "bool-setting", default_value = false, setting_type = "runtime-global", order = "0110"},
        {name = "DoingThingsByHand-disable-mining_bonus", type = "bool-setting", default_value = false, setting_type = "runtime-global", order = "0120"},
        {name = "DoingThingsByHand-disable-running_bonus", type = "bool-setting", default_value = false, setting_type = "runtime-global", order = "0130"},
        {name = "DoingThingsByHand-disable-health_bonus", type = "bool-setting", default_value = false, setting_type = "runtime-global", order = "0140"},
        -- per player
        {name = "DoingThingsByHand-player-max-crafting", type = "int-setting", default_value = -1, minimum_value = -1, maximum_value = 65536, setting_type = "runtime-per-user", order = "0100"},
        {name = "DoingThingsByHand-player-max-mining", type = "int-setting", default_value = -1, minimum_value = -1, maximum_value = 65536, setting_type = "runtime-per-user", order = "0120"},
        {name = "DoingThingsByHand-player-max-running", type = "int-setting", default_value = -1, minimum_value = -1, maximum_value = 65536, setting_type = "runtime-per-user", order = "0130"},
        {name = "DoingThingsByHand-player-max-health", type = "int-setting", default_value = -1, minimum_value = -1, maximum_value = 65536, setting_type = "runtime-per-user", order = "0140"}
    }
)
