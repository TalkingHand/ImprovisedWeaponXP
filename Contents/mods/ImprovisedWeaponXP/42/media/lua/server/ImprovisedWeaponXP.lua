-- Improvised Weapon XP
-- Vanilla xpUpdate.onWeaponHitXp (server/XpSystem/XpUpdate.lua) gives weapon skill XP only when the
-- weapon has one of six skill categories (Axe, Blunt, Spear, LongBlade, SmallBlade, SmallBlunt).
-- Melee weapons with none of them (only "Improvised": pens, pencils, compass, stones, flint) give
-- Strength/Fitness but no weapon skill. This adds the missing weapon skill XP with vanilla's formula,
-- picking the skill from how the weapon attacks. Weapons that already have a skill are not touched,
-- so nothing is ever counted twice. Mod weapons follow the same rule.

ImprovisedWeaponXP = ImprovisedWeaponXP or {}
local M = ImprovisedWeaponXP

local SKILL_CATEGORIES -- built on first use, not at file load
local function skillCategories()
	SKILL_CATEGORIES = SKILL_CATEGORIES or {
		WeaponCategory.AXE, WeaponCategory.BLUNT, WeaponCategory.SPEAR,
		WeaponCategory.LONG_BLADE, WeaponCategory.SMALL_BLADE, WeaponCategory.SMALL_BLUNT,
	}
	return SKILL_CATEGORIES
end

-- the weapon skill this weapon should train, or nil when vanilla already gives one (or none fits)
function M.perkFor(weapon)
	if not weapon or not instanceof(weapon, "HandWeapon") then return nil end
	if weapon:isRanged() or weapon:getType() == "BareHands" then return nil end
	local script = weapon:getScriptItem()
	if not script then return nil end
	for _, cat in ipairs(skillCategories()) do
		if script:containsWeaponCategory(cat) then return nil end
	end
	local sub = string.lower(tostring(weapon:getSubCategory() or ""))
	if sub == "stab" then return Perks.SmallBlade end
	if sub == "spear" then return Perks.Spear end
	if sub == "swinging" then return Perks.SmallBlunt end
	return nil -- no melee subcategory: thrown bombs, traps, firecrackers
end

-- same amount vanilla gives a categorised weapon (XpUpdate.lua onWeaponHitXp: damage * 0.9, max 3)
function M.xpFor(damage)
	local exp = 1 * (damage or 0) * 0.9
	if exp > 3 then exp = 3 end
	return exp
end

function M.onWeaponHitXp(owner, weapon, hitObject, damage, hitCount)
	if not owner or not hitCount or hitCount <= 0 then return end
	local perk = M.perkFor(weapon)
	if not perk then return end
	local exp = M.xpFor(damage)
	if exp <= 0 then return end
	addXp(owner, perk, exp)
end

if not M.registered then
	M.registered = true
	Events.OnWeaponHitXp.Add(function(...) return M.onWeaponHitXp(...) end)
	print("[ImprovisedWeaponXP] installed")
end
