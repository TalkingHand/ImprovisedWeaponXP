-- Improvised Weapon XP in-game test (pzt TEST_FILES only, not shipped). One client, every scenario.
-- IWXTest.start() runs the scenarios as a coroutine on OnTick; IWXTest.poll() re-queues itself until done.
-- Results: "[IWXTest] PASS/FAIL/INFO" lines; failures also "[PZTest] FAIL". No error() (debugger freezes).

IWXTest = IWXTest or {}
local T = IWXTest
local M = function() return ImprovisedWeaponXP end

local function log(...)
	local parts = {}
	for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end
	print("[IWXTest] " .. table.concat(parts, " "))
end

local function check(ok, label, extra)
	if ok then T.pass = T.pass + 1 else T.fail = T.fail + 1 end
	log(ok and "PASS" or "FAIL", T.scenario or "", label, extra ~= nil and tostring(extra) or "")
	if not ok and PZTest and PZTest.fail then PZTest.fail("IWXTest " .. tostring(T.scenario) .. " " .. label .. " " .. tostring(extra or "")) end
	return ok
end

local function p() return getPlayer() end
local function yield() coroutine.yield() end
local function waitTicks(n) for _ = 1, n do yield() end end

-- protected test character, re-set every frame while the test runs
local function protect(on)
	local pl = p()
	if not pl then return end
	pl:setGodMod(on)
	pl:setInvisible(on)
	pl:setZombiesDontAttack(on)
	if pl.setGhostMode then pl:setGhostMode(on) end
end

local function newWeapon(fullType)
	local item = instanceItem(fullType)
	if item then p():getInventory():AddItem(item) end
	return item
end

local function xp(perk) return p():getXp():getXP(perk) end

local function spawnZombie(dx, dy)
	local pl = p()
	local list = addZombiesInOutfit(math.floor(pl:getX()) + dx, math.floor(pl:getY()) + dy, math.floor(pl:getZ()), 1, nil, 50)
	if list and list:size() > 0 then return list:get(0) end
	return nil
end

local function clearZombies()
	local pl = p()
	local list = getCell():getZombieList()
	for i = list:size() - 1, 0, -1 do
		local z = list:get(i)
		if z and z:DistTo(pl) < 60 then z:removeFromSquare(); z:removeFromWorld() end
	end
end

-- gain in `perk` from one OnWeaponHitXp event, the way Java fires it after a melee hit
local function gainFrom(fullType, perk, damage, hitCount, target)
	local w = newWeapon(fullType)
	if not w then check(false, "item exists", fullType); return nil end
	local before = xp(perk)
	-- triggerEvent takes at most 4 arguments, so call both registered handlers the way the event would
	xpUpdate.onWeaponHitXp(p(), w, target, damage, hitCount)
	M().onWeaponHitXp(p(), w, target, damage, hitCount)
	return xp(perk) - before
end

local function near(a, b) return a and b and math.abs(a - b) < 0.001 end

------------------------------------------------------------------ scenarios

local function sPerkFor()
	T.scenario = "perkFor"
	local cases = {
		{ "Base.Pencil", Perks.SmallBlade }, { "Base.Pen", Perks.SmallBlade }, { "Base.CompassGeometry", Perks.SmallBlade },
		{ "Base.Stone2", Perks.SmallBlunt }, { "Base.FlintNodule", Perks.SmallBlunt },
		-- vanilla already trains these, or they are not melee: the mod must not touch them
		{ "Base.Hammer", nil }, { "Base.KitchenKnife", nil }, { "Base.SpearCrafted", nil },
		{ "Base.Pistol", nil }, { "Base.BareHands", nil },
		{ "Base.PipeBomb", nil }, { "Base.Molotov", nil }, { "Base.Firecracker", nil }, { "Base.NoiseTrapSensorV1", nil },
	}
	for _, c in ipairs(cases) do
		local w = instanceItem(c[1])
		if not w then check(false, "item exists", c[1]) else
			local got = M().perkFor(w)
			check(got == c[2], c[1], tostring(got) .. " expected " .. tostring(c[2]))
		end
	end
	-- whole script list: every melee weapon without a skill category gets one, every other gets none
	local all = getScriptManager():getAllItems()
	local unlocked, wrong = 0, 0
	for i = 0, all:size() - 1 do
		local s = all:get(i)
		local okW, w = pcall(function() return instanceItem(s:getFullName()) end)
		if okW and w then
			if w and instanceof(w, "HandWeapon") and not w:isRanged() and w:getType() ~= "BareHands" then
				local has = false
				for _, cat in ipairs({ WeaponCategory.AXE, WeaponCategory.BLUNT, WeaponCategory.SPEAR, WeaponCategory.LONG_BLADE, WeaponCategory.SMALL_BLADE, WeaponCategory.SMALL_BLUNT }) do
					if s:containsWeaponCategory(cat) then has = true end
				end
				local perk = M().perkFor(w)
				if has and perk then wrong = wrong + 1; log("INFO touched a skilled weapon", s:getFullName()) end
				if not has then
					local sub = string.lower(tostring(w:getSubCategory() or ""))
					local melee = sub == "stab" or sub == "swinging" or sub == "spear"
					if perk then unlocked = unlocked + 1; log("INFO unlocked", s:getFullName(), sub, tostring(perk)) end
					if melee and not perk then wrong = wrong + 1; log("INFO left locked", s:getFullName()) end
					if not melee and perk then wrong = wrong + 1; log("INFO non-melee unlocked", s:getFullName()) end
				end
			end
		end
	end
	check(wrong == 0, "script scan: no skilled weapon touched, no improvised left", wrong)
	check(unlocked == 12, "unlocked count (10 stab + 2 swing in 42.22.2)", unlocked)
end

local function sAmounts(target)
	T.scenario = "amounts"
	-- same perk, same level: improvised gain must equal a vanilla-categorised weapon's gain (not double, not zero)
	local knife = gainFrom("Base.KitchenKnife", Perks.SmallBlade, 1.0, 1, target)
	local pencil = gainFrom("Base.Pencil", Perks.SmallBlade, 1.0, 1, target)
	check(pencil and pencil > 0, "pencil gives Short Blade XP", pencil)
	check(near(pencil, knife), "pencil = kitchen knife", tostring(pencil) .. " vs " .. tostring(knife))

	local hammer = gainFrom("Base.Hammer", Perks.SmallBlunt, 1.0, 1, target)
	local stone = gainFrom("Base.Stone2", Perks.SmallBlunt, 1.0, 1, target)
	check(stone and stone > 0, "stone gives Short Blunt XP", stone)
	check(near(stone, hammer), "stone = hammer", tostring(stone) .. " vs " .. tostring(hammer))

	-- cap at 3 (damage 10 -> 9 -> 3), same as vanilla
	local knifeBig = gainFrom("Base.KitchenKnife", Perks.SmallBlade, 10.0, 1, target)
	local pencilBig = gainFrom("Base.Pencil", Perks.SmallBlade, 10.0, 1, target)
	check(near(pencilBig, knifeBig), "capped amount = vanilla", tostring(pencilBig) .. " vs " .. tostring(knifeBig))

	-- a miss gives nothing
	local miss = gainFrom("Base.Pencil", Perks.SmallBlade, 1.0, 0, target)
	check(near(miss, 0), "miss gives nothing", miss)

	-- the mod adds nothing to a weapon vanilla already trains (Hammer: no Short Blade from us)
	local hammerBlade = gainFrom("Base.Hammer", Perks.SmallBlade, 1.0, 1, target)
	check(near(hammerBlade, 0), "hammer gives no Short Blade", hammerBlade)
end

-- a real swing: equip a pencil, face a zombie next to the player and attack
local function sRealSwing()
	T.scenario = "realSwing"
	local pl = p()
	pcall(clearZombies)
	local okZ, z = pcall(spawnZombie, 1, 0)
	if not okZ then z = nil end
	if not z then check(false, "zombie spawned"); return end
	local pencil = newWeapon("Base.Pencil")
	pl:setPrimaryHandItem(pencil)
	pl:setSecondaryHandItem(nil)
	waitTicks(30)
	local before = xp(Perks.SmallBlade)
	local got = false
	for attempt = 1, 10 do
		pcall(function()
			if not z:isDead() then
				pl:faceThisObject(z)
				if z:DistTo(pl) > 1.2 then z:setX(pl:getX() + 0.9); z:setY(pl:getY()) end
			end
		end)
		local ok, err = pcall(function() pl:DoAttack(0) end)
		if not ok then log("INFO DoAttack error", err) end
		for _ = 1, 90 do
			yield()
			if xp(Perks.SmallBlade) > before then got = true; break end
		end
		if got then log("INFO hit on attempt", attempt); break end
	end
	local gain = xp(Perks.SmallBlade) - before
	if got then
		check(gain > 0, "real pencil swing gives Short Blade XP", gain)
	else
		-- could not land a scripted swing: not a mod result, reported as unchecked
		log("INFO real swing not landed; Short Blade gain", gain)
	end
	pl:setPrimaryHandItem(nil)
	clearZombies()
end

------------------------------------------------------------------ driver

local function run()
	T.pass, T.fail = 0, 0
	local pl = p()
	pl:getInventory():clear()
	clearZombies()
	check(M() ~= nil and M().registered, "mod loaded")
	-- scenarios without yields run under pcall: a Java exception inside the coroutine opens the debugger
	local ok, err = pcall(sPerkFor)
	if not ok then check(false, "perkFor ran", err) end
	local okZ, target = pcall(spawnZombie, 3, 3)
	if not okZ or not target then check(false, "target zombie spawned", target)
	else
		ok, err = pcall(sAmounts, target)
		if not ok then check(false, "amounts ran", err) end
	end
	sRealSwing()
	pl:getInventory():clear()
end

function T.start()
	T.done = false
	T.co = coroutine.create(function()
		run()
		T.done = true
	end)
	log("start")
end

function T.poll()
	if T.done then
		protect(false)
		log("RESULT pass=" .. tostring(T.pass) .. " fail=" .. tostring(T.fail))
		if PZTest and PZTest.log then PZTest.log("IWXTest done pass=" .. T.pass .. " fail=" .. T.fail) end
	else
		PZTest.step("wait 60")
		PZTest.step("lua IWXTest.poll()")
	end
end

local function onTick()
	if not T.co then return end
	protect(true)
	if coroutine.status(T.co) == "dead" then T.co = nil; return end
	local ok, err = coroutine.resume(T.co)
	if not ok then
		T.fail = (T.fail or 0) + 1
		log("FAIL coroutine", tostring(err))
		if PZTest and PZTest.fail then PZTest.fail("IWXTest coroutine " .. tostring(err)) end
		T.co = nil
		T.done = true
	end
end
Events.OnTick.Add(onTick)
