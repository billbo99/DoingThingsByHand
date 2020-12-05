local function is_array(table)
    local max = 0
    local count = 0
    for k, v in pairs(table) do
        if type(k) == "number" then
            if k > max then
                max = k
            end
            count = count + 1
        else
            return -1
        end
    end
    if max > count * 2 then
        return -1
    end

    return max
end

local raw_fish = data.raw.capsule["raw-fish"]
local target_effects = table.deepcopy(raw_fish.capsule_action.attack_parameters.ammo_type.action.action_delivery.target_effects)

if is_array(target_effects) == -1 then
    target_effects = {target_effects}
end

local new_target_effects = {{type = "script", effect_id = "eat_raw_fish_pre_id"}}
for _, effect in pairs(target_effects) do
    table.insert(new_target_effects, effect)
end
table.insert(new_target_effects, {type = "script", effect_id = "eat_raw_fish_post_id"})

raw_fish.capsule_action.attack_parameters.ammo_type.action.action_delivery.target_effects = new_target_effects
