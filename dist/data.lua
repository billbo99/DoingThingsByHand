data:extend(
    {
        {
            type = "sprite",
            name = "DoingThingsByHand",
            filename = "__DoingThingsByHand__/hands.png",
            width = 171,
            height = 128
        }
    }
)

local raw_fish = data.raw.capsule["raw-fish"]
local target_effects = table.deepcopy(raw_fish.capsule_action.attack_parameters.ammo_type.action.action_delivery.target_effects)

local new_target_effects = {{type = "script", effect_id = "eat_raw_fish_pre_id"}}
for _, effect in pairs(target_effects) do
    table.insert(new_target_effects, effect)
end
table.insert(new_target_effects, {type = "script", effect_id = "eat_raw_fish_post_id"})

raw_fish.capsule_action.attack_parameters.ammo_type.action.action_delivery.target_effects = new_target_effects
