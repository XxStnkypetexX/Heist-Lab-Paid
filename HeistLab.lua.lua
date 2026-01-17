--[[
    Petes Rig - Casino & Gun Van Tools
    Updated for Lexis API
]]

local TARGET_SCRIPT = "casinoroulette"

-- Enhanced GTA (EE) Offsets
-- Standard Offsets: Win=1657, State=1511
-- EE Offsets: Win=1659, State=1513 (+2 shift)
local WIN_VAR_OFFSET = 1659   
local STATE_VAR_OFFSET = 1513 

local rigging_enabled = false
local rigged_outcome = 1

local function generate_list(min, max, step)
    local list = {}
    for i = min, max, step do
        table.insert(list, {tostring(i), i})
    end
    return list
end

local outcome_list = generate_list(0, 36, 1)

local root = menu.root()

local function rig_roulette()
    while rigging_enabled do
        if script.running(TARGET_SCRIPT) then
            for i = 0, 5 do
                local win_local = script.locals(TARGET_SCRIPT, WIN_VAR_OFFSET + i)
                local state_local = script.locals(TARGET_SCRIPT, STATE_VAR_OFFSET + i)
                
                if win_local and state_local then
                    local current_val = win_local.int32
                    local current_phase = state_local.int32
                    -- Phase 2 usually indicates betting is closed/spinning
                    if current_phase >= 2 and current_val ~= -1 and current_val ~= rigged_outcome then
                        win_local.int32 = rigged_outcome
                        util.yield(10) 
                    end
                end
            end
        end
        util.yield()
    end
end

root:toggle("Enable Roulette Rig"):event(menu.event.click, function(t)
    rigging_enabled = t.value
    if rigging_enabled then
        util.create_job(rig_roulette)
    end
end)

local function find_index(list, value)
    for i, v in ipairs(list) do
        if v[2] == value then return i end
    end
    return 1
end

local combo = root:combo_int("Rigged Number", outcome_list, menu.type.scroll)
combo.value = find_index(outcome_list, 1)

combo:event(menu.event.click, function(c)
    if c.value >= 1 and c.value <= #outcome_list then
        rigged_outcome = outcome_list[c.value][2]
    end
end)

-- Blackjack Rig (EE)
local BLACKJACK_SCRIPT = "blackjack"

local blackjack_rig_enabled = false
local locked_table_id = -1

local function rig_blackjack()
    while blackjack_rig_enabled do
        if script.running(BLACKJACK_SCRIPT) then
            
            -- Attempt to lock table if not already locked
            if locked_table_id == -1 then
                local my_pid = players.me().id
                -- EE Offset for Current Table Index: 1800 + 1 + (PID * 8) + 4
                local current_table_idx = 1800 + 1 + (my_pid * 8) + 4
                local table_local = script.locals(BLACKJACK_SCRIPT, current_table_idx)
                
                if table_local then
                    local tid = table_local.int32
                    if tid ~= -1 then
                        locked_table_id = tid
                    end
                end
            end

            -- If we have a locked table, rig it
            if locked_table_id ~= -1 and locked_table_id >= 0 and locked_table_id < 32 then
                -- EE Offset for Dealer Cards Base: 140 + 846 + 1 + (TableID * 13)
                local dealer_base = 140 + 846 + 1 + (locked_table_id * 13)
                
                -- Force Dealer Bust Cards (11, 12, 13) -> 10 + 10 + 10 = 30
                local card1 = script.locals(BLACKJACK_SCRIPT, dealer_base + 1)
                local card2 = script.locals(BLACKJACK_SCRIPT, dealer_base + 2)
                local card3 = script.locals(BLACKJACK_SCRIPT, dealer_base + 3)
                local visible = script.locals(BLACKJACK_SCRIPT, dealer_base + 12)
                
                if card1 and card2 and card3 and visible then
                    -- Only write if values are different to prevent crash
                    if card1.int32 ~= 11 then card1.int32 = 11 end
                    if card2.int32 ~= 12 then card2.int32 = 12 end
                    if card3.int32 ~= 13 then card3.int32 = 13 end
                    if visible.int32 ~= 3 then visible.int32 = 3 end
                end
            end
        end
        util.yield(250) -- Increased yield to reduce load
    end
end

root:toggle("Enable Blackjack Rig (Dealer Bust)"):event(menu.event.click, function(t)
    blackjack_rig_enabled = t.value
    if blackjack_rig_enabled then
        util.create_job(rig_blackjack)
    else
        locked_table_id = -1 -- Reset lock when disabled
    end
end)

----------------------- GUN VAN SECTION -----------------------

-- Gun Van Position Global (EE)
local GUN_VAN_POSITION_GLOBAL = 2652582 + 2706

-- Gun Van Coordinates (all 30 locations)
local GunVanCoords = {
    {-29.532, 6435.136, 31.162}, {1705.214, 4819.167, 41.75}, {1795.522, 3899.753, 33.869},
    {1335.536, 2758.746, 51.099}, {795.583, 1210.78, 338.962}, {-3192.67, 1077.205, 20.594},
    {-789.719, 5400.921, 33.915}, {-24.384, 3048.167, 40.703}, {2666.786, 1469.324, 24.237},
    {-1454.966, 2667.503, 3.2}, {2340.418, 3054.188, 47.888}, {1509.183, -2146.795, 76.853},
    {1137.404, -1358.654, 34.322}, {-57.208, -2658.793, 5.737}, {1905.017, 565.222, 175.558},
    {974.484, -1718.798, 30.296}, {779.077, -3266.297, 5.719}, {-587.728, -1637.208, 19.611},
    {733.99, -736.803, 26.165}, {-1694.632, -454.082, 40.712}, {-1330.726, -1163.948, 4.313},
    {-496.618, 40.231, 52.316}, {275.527, 66.509, 94.108}, {260.928, -763.35, 30.559},
    {-478.025, -741.45, 30.299}, {894.94, 3603.911, 32.56}, {-2166.511, 4289.503, 48.733},
    {1465.633, 6553.67, 13.771}, {1101.032, -335.172, 66.944}, {149.683, -1655.674, 29.028}
}

-- Buyable Weapons List
local BuyableWeaponNames = {
    "Knuckle Duster", "Baseball Bat", "Battle Axe", "Bottle", "Crowbar", "Antique Cavalry Dagger",
    "Flashlight", "Hammer", "Hatchet", "Knife", "Machete", "Nightstick", "Pool Cue", "Switchblade",
    "Pipe Wrench", "AP Pistol", "Ceramic Pistol", "Combat Pistol", "Double Action Revolver",
    "Flare Gun", "Perico Pistol", "Heavy Pistol", "Marksman Pistol", "Navy Revolver", "Pistol",
    "Pistol Mk II", "Pistol .50", "Up-n-Atomizer", "Heavy Revolver", "Heavy Revolver Mk II",
    "SNS Pistol", "SNS Pistol Mk II", "Vintage Pistol", "Stun Gun", "Assault SMG", "Combat PDW",
    "Machine Pistol", "Micro SMG", "Mini SMG", "SMG", "SMG Mk II", "Tactical SMG", "Advanced Rifle",
    "Assault Rifle", "Assault Rifle Mk II", "Bullpup Rifle", "Bullpup Rifle Mk II", "Carbine Rifle",
    "Carbine Rifle Mk II", "Compact Rifle", "Heavy Rifle", "Military Rifle", "Special Carbine",
    "Special Carbine Mk II", "Service Carbine", "Battle Rifle", "Assault Shotgun", "Sweeper Shotgun",
    "Bullpup Shotgun", "Combat Shotgun", "Double Barrel Shotgun", "Heavy Shotgun", "Pump Shotgun",
    "Pump Shotgun Mk II", "Sawed-Off Shotgun", "Musket", "Combat MG", "Combat MG Mk II",
    "Gusenberg Sweeper", "MG", "Unholy Hellbringer", "Heavy Sniper", "Heavy Sniper Mk II",
    "Marksman Rifle", "Marksman Rifle Mk II", "Precision Rifle", "Sniper Rifle",
    "Compact Grenade Launcher", "Compact EMP Launcher", "Firework Launcher", "Grenade Launcher",
    "Homing Launcher", "Minigun", "Railgun", "Widowmaker", "RPG"
}

local BuyableWeaponHashes = {
    -656458692, -1786099057, -853065399, -102323637, -2067956739, -1834847097, -1951375401,
    1317494643, -102973651, -1716189206, -581044007, 1737195953, -1810795771, -538741184,
    419712736, 584646201, 727643628, 1593441988, -1746263880, 1198879012, 1470379660,
    -771403250, -598887786, -1853920116, 453432689, -1075685676, -1716589765, -1355376991,
    -1045183535, -879347409, -1076751822, -2009644972, 137902532, 1171102963, -270015777,
    171789620, -619010992, 324215364, -1121678507, 736523883, 2024373456, 350597077,
    -1357824103, -1074790547, 961495388, 2132975508, -2066285827, -2084633992, -86904375,
    1649403952, -947031628, -1658906650, -1063057011, -1768145561, -774507221, 1924557585,
    -494615257, 317205821, -1654528753, 94989220, -275439685, 984333226, 487013001,
    1432025498, 2017895192, -1466123874, 2144741730, -608341376, 1627465347, -1660422300,
    1198256469, 205991906, 177293209, -952879014, 1785463520, 1853742572, 100416529,
    125959754, -618237638, 2138347493, -1568386805, 1672152130, 1119849093, -22923932,
    -1238556825, -1312131151
}

local BuyableThrowableNames = {
    "Grenade", "Molotov", "Pipe Bomb", "Proximity Mine", "Tear Gas", "Sticky Bomb", "Jerry Can"
}

local BuyableThrowableHashes = {
    -1813897027, 615608432, -1169823560, -1420407917, -37975472, 741814745, 883325847
}

-- Gun Van State Variables
local gv_selected_weapon_slot = 1
local gv_selected_throwable_slot = 1
local gv_selected_weapon_idx = 1
local gv_selected_throwable_idx = 1
local gv_selected_position = 1
local gv_discount_percent = 100

-- Helper function to set weapon slot via tunables (Lexis API)
local function set_weapon_slot(slot_index, weapon_hash)
    local tunable = script.tunables("xm22_gun_van_slot_weapon_type_" .. slot_index)
    if tunable then
        tunable.int32 = weapon_hash
        return true
    end
    return false
end

-- Helper function to set throwable slot via tunables (Lexis API)
local function set_throwable_slot(slot_index, throwable_hash)
    local tunable = script.tunables("xm22_gun_van_slot_throwable_type_" .. slot_index)
    if tunable then
        tunable.int32 = throwable_hash
        return true
    end
    return false
end

-- Helper function to set weapon discount
local function set_weapon_discount(slot_index, discount)
    local tunable = script.tunables("xm22_gun_van_slot_weapon_discount_" .. slot_index)
    if tunable then
        tunable.float = discount
        return true
    end
    return false
end

-- Helper function to set throwable discount
local function set_throwable_discount(slot_index, discount)
    local tunable = script.tunables("xm22_gun_van_slot_throwable_discount_" .. slot_index)
    if tunable then
        tunable.float = discount
        return true
    end
    return false
end

-- Helper function to set armour discount
local function set_armour_discount(slot_index, discount)
    local tunable = script.tunables("xm22_gun_van_slot_armour_discount_" .. slot_index)
    if tunable then
        tunable.float = discount
        return true
    end
    return false
end

-- Helper function to get current gun van position (Lexis API)
local function get_gun_van_position()
    local global = script.globals(GUN_VAN_POSITION_GLOBAL)
    if global then
        return global.int32 + 1
    end
    return 1
end

-- Helper function to set gun van position (Lexis API)
local function set_gun_van_position(pos)
    local global = script.globals(GUN_VAN_POSITION_GLOBAL)
    if global then
        global.int32 = pos - 1
        return true
    end
    return false
end

-- Build weapon list for combo
local weapon_combo_list = {}
for i, name in ipairs(BuyableWeaponNames) do
    table.insert(weapon_combo_list, {name, i})
end

-- Build throwable list for combo
local throwable_combo_list = {}
for i, name in ipairs(BuyableThrowableNames) do
    table.insert(throwable_combo_list, {name, i})
end

-- Build position list for combo
local position_combo_list = {}
for i = 1, 30 do
    table.insert(position_combo_list, {"Position " .. i, i})
end

-- Gun Van Submenu
local gun_van_menu = root:submenu("Gun Van")

-- === WEAPONS SECTION ===
local weapons_menu = gun_van_menu:submenu("Weapons")

-- Slot selection (1-10)
local slot_list = {}
for i = 1, 10 do
    table.insert(slot_list, {"Slot " .. i, i})
end

weapons_menu:combo_int("Select Slot", slot_list, menu.type.scroll):event(menu.event.click, function(c)
    if c.value >= 1 and c.value <= #slot_list then
        gv_selected_weapon_slot = c.list:at(c.value).value
    end
end)

weapons_menu:combo_int("Select Weapon", weapon_combo_list, menu.type.scroll):event(menu.event.click, function(c)
    if c.value >= 1 and c.value <= #weapon_combo_list then
        gv_selected_weapon_idx = c.list:at(c.value).value
    end
end)

weapons_menu:button("Apply Weapon to Slot"):event(menu.event.click, function()
    local weapon_hash = BuyableWeaponHashes[gv_selected_weapon_idx]
    if set_weapon_slot(gv_selected_weapon_slot - 1, weapon_hash) then
        notify.push("Gun Van", "Applied " .. BuyableWeaponNames[gv_selected_weapon_idx] .. " to Slot " .. gv_selected_weapon_slot)
    else
        notify.push("Gun Van", "Failed to apply weapon - tunables not found")
    end
end)

weapons_menu:button("Set to Current Weapon"):event(menu.event.click, function()
    local ped = players.me().ped
    -- GET_SELECTED_PED_WEAPON: 0x0A6DB4965674D243
    local weapon_hash = invoker.call(0x0A6DB4965674D243, ped).int32
    if weapon_hash and weapon_hash ~= 0 then
        if set_weapon_slot(gv_selected_weapon_slot - 1, weapon_hash) then
            notify.push("Gun Van", "Applied current weapon to Slot " .. gv_selected_weapon_slot)
        else
            notify.push("Gun Van", "Failed to apply weapon - tunables not found")
        end
    else
        notify.push("Gun Van", "No weapon equipped")
    end
end)

-- === THROWABLES SECTION ===
local throwables_menu = gun_van_menu:submenu("Throwables")

local throwable_slot_list = {}
for i = 1, 3 do
    table.insert(throwable_slot_list, {"Slot " .. i, i})
end

throwables_menu:combo_int("Select Slot", throwable_slot_list, menu.type.scroll):event(menu.event.click, function(c)
    if c.value >= 1 and c.value <= #throwable_slot_list then
        gv_selected_throwable_slot = c.list:at(c.value).value
    end
end)

throwables_menu:combo_int("Select Throwable", throwable_combo_list, menu.type.scroll):event(menu.event.click, function(c)
    if c.value >= 1 and c.value <= #throwable_combo_list then
        gv_selected_throwable_idx = c.list:at(c.value).value
    end
end)

throwables_menu:button("Apply Throwable to Slot"):event(menu.event.click, function()
    local throwable_hash = BuyableThrowableHashes[gv_selected_throwable_idx]
    if set_throwable_slot(gv_selected_throwable_slot - 1, throwable_hash) then
        notify.push("Gun Van", "Applied " .. BuyableThrowableNames[gv_selected_throwable_idx] .. " to Slot " .. gv_selected_throwable_slot)
    else
        notify.push("Gun Van", "Failed to apply throwable - tunables not found")
    end
end)

-- === LOCATION SECTION ===
local location_menu = gun_van_menu:submenu("Location")

location_menu:combo_int("Select Position", position_combo_list, menu.type.scroll):event(menu.event.click, function(c)
    if c.value >= 1 and c.value <= #position_combo_list then
        gv_selected_position = c.list:at(c.value).value
    end
end)

location_menu:button("Teleport Gun Van to Position"):event(menu.event.click, function()
    if set_gun_van_position(gv_selected_position) then
        notify.push("Gun Van", "Gun Van moved to Position " .. gv_selected_position)
    else
        notify.push("Gun Van", "Failed to move Gun Van")
    end
end)

location_menu:button("Teleport to Gun Van"):event(menu.event.click, function()
    local pos = get_gun_van_position()
    if pos >= 1 and pos <= 30 then
        local coord = GunVanCoords[pos]
        local ped = players.me().ped
        -- SET_ENTITY_COORDS: 0x06843DA7060A026B
        invoker.call(0x06843DA7060A026B, ped, coord[1], coord[2], coord[3], false, false, false, false)
        notify.push("Gun Van", "Teleported to Gun Van at Position " .. pos)
    end
end)

location_menu:button("Set Waypoint to Gun Van"):event(menu.event.click, function()
    local pos = get_gun_van_position()
    if pos >= 1 and pos <= 30 then
        local coord = GunVanCoords[pos]
        -- SET_NEW_WAYPOINT: 0xFE43368D2AA4F2FC
        invoker.call(0xFE43368D2AA4F2FC, coord[1], coord[2])
        notify.push("Gun Van", "Waypoint set to Gun Van")
    end
end)

-- === DISCOUNTS SECTION ===
local discounts_menu = gun_van_menu:submenu("Discounts")

local discount_list = {}
for i = -100, 100, 10 do
    table.insert(discount_list, {i .. "%", i})
end

discounts_menu:combo_int("Discount Amount", discount_list, menu.type.scroll):event(menu.event.click, function(c)
    if c.value >= 1 and c.value <= #discount_list then
        gv_discount_percent = c.list:at(c.value).value
    end
end)

discounts_menu:button("Apply Discounts"):event(menu.event.click, function()
    local discount_float = gv_discount_percent / 100.0
    local success = false
    
    -- Apply weapon discounts
    for i = 0, 8 do
        if set_weapon_discount(i, discount_float) then
            success = true
        end
    end
    
    -- Apply throwable discounts
    for i = 0, 2 do
        if set_throwable_discount(i, discount_float) then
            success = true
        end
    end
    
    -- Apply armour discounts
    for i = 0, 4 do
        if set_armour_discount(i, discount_float) then
            success = true
        end
    end
    
    if success then
        notify.push("Gun Van", "Applied " .. gv_discount_percent .. "% discount to all items")
    else
        notify.push("Gun Van", "Failed to apply discounts - tunables not found")
    end
end)

-- === PRESETS SECTION ===
local presets_menu = gun_van_menu:submenu("Presets")

presets_menu:button("Optimal Weapons Loadout"):event(menu.event.click, function()
    set_weapon_slot(0, joaat("weapon_navyrevolver"))
    set_weapon_slot(1, joaat("weapon_gadgetpistol"))
    set_weapon_slot(2, joaat("weapon_stungun_mp"))
    set_weapon_slot(3, joaat("weapon_doubleaction"))
    set_weapon_slot(4, joaat("weapon_railgunxm3"))
    set_weapon_slot(5, joaat("weapon_minigun"))
    set_weapon_slot(6, joaat("weapon_heavysniper_mk2"))
    set_weapon_slot(7, joaat("weapon_combatmg_mk2"))
    set_weapon_slot(8, joaat("weapon_tacticalrifle"))
    set_weapon_slot(9, joaat("weapon_specialcarbine_mk2"))
    
    set_throwable_slot(0, joaat("weapon_stickybomb"))
    set_throwable_slot(1, joaat("weapon_molotov"))
    set_throwable_slot(2, joaat("weapon_pipebomb"))
    
    notify.push("Gun Van", "Applied optimal weapons loadout")
end)

-- === VAN CONTROLS ===
local van_controls_menu = gun_van_menu:submenu("Van Controls")

van_controls_menu:button("Unlock Gun Van"):event(menu.event.click, function()
    local speedo4_hash = joaat("Speedo4")
    for _, address in ipairs(pools.vehicle()) do
        local handle = game.guid_from_entity(address)
        if handle ~= 0 then
            -- GET_ENTITY_MODEL: 0x9F47B058362C84B5
            local model = invoker.call(0x9F47B058362C84B5, handle).int32
            if model == speedo4_hash then
                -- SET_ENTITY_SHOULD_FREEZE_WAITING_ON_COLLISION: 0x3910051CCECDB00C
                invoker.call(0x3910051CCECDB00C, handle, false)
                -- FREEZE_ENTITY_POSITION: 0x428CA6DBD1094446
                invoker.call(0x428CA6DBD1094446, handle, false)
                -- SET_VEHICLE_DOORS_LOCKED: 0xB664292EAECF7FA6
                invoker.call(0xB664292EAECF7FA6, handle, 1)
                -- SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER: 0xDBC631F109350B8C
                invoker.call(0xDBC631F109350B8C, handle, false)
                notify.push("Gun Van", "Gun Van unlocked")
                return
            end
        end
    end
    notify.push("Gun Van", "Gun Van not found nearby")
end)

van_controls_menu:button("Enter Gun Van"):event(menu.event.click, function()
    local speedo4_hash = joaat("Speedo4")
    local ped = players.me().ped
    for _, address in ipairs(pools.vehicle()) do
        local handle = game.guid_from_entity(address)
        if handle ~= 0 then
            -- GET_ENTITY_MODEL: 0x9F47B058362C84B5
            local model = invoker.call(0x9F47B058362C84B5, handle).int32
            if model == speedo4_hash then
                -- SET_ENTITY_SHOULD_FREEZE_WAITING_ON_COLLISION: 0x3910051CCECDB00C
                invoker.call(0x3910051CCECDB00C, handle, false)
                -- FREEZE_ENTITY_POSITION: 0x428CA6DBD1094446
                invoker.call(0x428CA6DBD1094446, handle, false)
                -- SET_VEHICLE_DOORS_LOCKED: 0xB664292EAECF7FA6
                invoker.call(0xB664292EAECF7FA6, handle, 1)
                -- SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER: 0xDBC631F109350B8C
                invoker.call(0xDBC631F109350B8C, handle, false)
                -- SET_PED_INTO_VEHICLE: 0xF75B0D629E1C063D
                invoker.call(0xF75B0D629E1C063D, ped, handle, -1)
                notify.push("Gun Van", "Entered Gun Van")
                return
            end
        end
    end
    notify.push("Gun Van", "Gun Van not found nearby")
end)

van_controls_menu:button("Make Seller Vulnerable"):event(menu.event.click, function()
    local seller_hash = joaat("IG_GunVanSeller")
    for _, address in ipairs(pools.ped()) do
        local handle = game.guid_from_entity(address)
        if handle ~= 0 then
            -- GET_ENTITY_MODEL: 0x9F47B058362C84B5
            local model = invoker.call(0x9F47B058362C84B5, handle).int32
            if model == seller_hash then
                -- SET_ENTITY_INVINCIBLE: 0x3882114BDE571AD4
                invoker.call(0x3882114BDE571AD4, handle, false)
                -- SET_ENTITY_CAN_BE_DAMAGED: 0x1760FFA8AB074D66
                invoker.call(0x1760FFA8AB074D66, handle, true)
                -- SET_PED_CAN_BE_TARGETTED: 0x63F58F7C80513AAD
                invoker.call(0x63F58F7C80513AAD, handle, true)
                -- FREEZE_ENTITY_POSITION: 0x428CA6DBD1094446
                invoker.call(0x428CA6DBD1094446, handle, false)
                notify.push("Gun Van", "Gun Van seller is now vulnerable")
                return
            end
        end
    end
    notify.push("Gun Van", "Gun Van seller not found nearby")
end)

van_controls_menu:button("Add Blip on Map"):event(menu.event.click, function()
    local pos = get_gun_van_position()
    if pos >= 1 and pos <= 30 then
        local coord = GunVanCoords[pos]
        -- ADD_BLIP_FOR_COORD: 0x5A039BB0BCA604B6
        local blip = invoker.call(0x5A039BB0BCA604B6, coord[1], coord[2], coord[3]).int32
        -- SET_BLIP_SPRITE: 0xDF735600A4696DAF
        invoker.call(0xDF735600A4696DAF, blip, 844)
        -- SET_BLIP_SCALE: 0xD38744167B2FA257
        invoker.call(0xD38744167B2FA257, blip, 1.2)
        notify.push("Gun Van", "Gun Van blip added to map")
    end
end)