--[[
	═══════════════════════════════════════════════════════════════════
	  ULTIMATE GYM · AUTO ASSISTANT  (v9 — unified)
	  Run via the Roblox Studio Lua interface / executor.
	═══════════════════════════════════════════════════════════════════
	Tabs:
	  CALISTHENICS  · pick exercise, auto-solve balance, rep in sets
	  WEIGHTS       · pick machine exercise, manual or auto (Hypertrophy/
	                  Strength) weight, rep to low stamina then regen
	  UTILITY       · Auto-Clean, Auto-Maintain Calories, Auto-Shaker
	Draggable · minimisable · re-running cleanly replaces the old instance.
	═══════════════════════════════════════════════════════════════════
]]

if _G.__ugg and typeof(_G.__ugg.stop)=="function" then pcall(_G.__ugg.stop) end
local TOKEN={}
_G.__ugg={t=TOKEN}
local function alive() return _G.__ugg and _G.__ugg.t==TOKEN end

local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunS=game:GetService("RunService")
local Market=game:GetService("MarketplaceService")
local PPS=game:GetService("ProximityPromptService")
local VIM=game:GetService("VirtualInputManager")
local UIS=game:GetService("UserInputService")
local WS=game:GetService("Workspace")
local LP=Players.LocalPlayer

-- executor capabilities
local hasFPP=typeof(fireproximityprompt)=="function"
local hasGC=typeof(getgc)=="function"
local hasConn=typeof(getconnections)=="function"
local hasSUV=typeof(debug)=="table" and typeof(debug.setupvalue)=="function" and typeof(debug.getupvalue)=="function"
local hasSTI=typeof(setthreadidentity)=="function" and typeof(getthreadidentity)=="function"

local CFG={
	gamepassId=0,
	trashFolder="ActiveTrash", trashNames={water_spill=true,floortrash=true},
	shopPart="CounterShop", foodTool="Chicken_rice", foodItem="Item_chicken_rice", defaultThreshold=3000,
	yogaModel="YogaMat", yogaMenu="YogaExerciseMenu",
	calis={"PushUp","PikePushup","HandstandPush","LSitToHandstandPush","PikeToHandstandToPikeHold","OneArmPushup","TuckPush","LSitToTuckToPlancheToLSit","StraddlePush","PlancheToHandstandPush","TuckToHandstandToPlancheToTuck","OneArmPlanchePush","MalteseElevation"},
	repPoll=0.2, setEnd=12, staminaFull=100, restSecs=10, startRetry=2.5,
	shopCreatine="Item_protein", shopWhey="Item_whey", creatineScoops=5, wheyScoops=2,
	barKg=20,
}
-- machine exercises: {label, machineModel, menuGui(false=direct), buttonName}
local WORKOUT={
	{"Bench Press","BenchOnly","ScreenGui","BenchButton"},
	{"Squat","BenchOnly","ScreenGui","SquatButton"},
	{"Deadlift","DeadliftPlat",false,false},
	{"Lat Pulldown","MultiCableMachine","ScreenGui2","LatPullButton"},
	{"Cable Row","MultiCableMachine","ScreenGui2","CableRowButton"},
	{"Tricep Pulldown","MultiCableMachine","ScreenGui2","TricepButton"},
	{"Hack Squat","HackSquat Model","HacksquatExerciseMenu","SquatButton"},
	{"Calves Press","HackSquat Model","HacksquatExerciseMenu","CalvesPressButton"},
	{"Preacher Curls","PreacherCurl","PreacherCurlExerciseMenu","PreacherCurlsButton"},
	{"Forearm Curls","PreacherCurl","PreacherCurlExerciseMenu","ForearmsButton"},
	{"Pec Fly","Pectoral and Reverse Fly Machine (1)","CableFlyExerciseMenu","PecFlyButton"},
	{"Reverse Delt Fly","Pectoral and Reverse Fly Machine (1)","CableFlyExerciseMenu","ReverseDeltFlyButton"},
	{"Pullup","pullbar","PullDipMenu","PullupButton"},
	{"Tricep Dips","pullbar","PullDipMenu","TricepDipsButton"},
	{"L-Sit Raises","pullbar","PullDipMenu","LSitRaisesButton"},
	{"Seated Leg Curl","SeatedLegCurl",false,false},
}
-- exercise label -> {dictKey, statName} for auto-weight
local AWMAP={
	["Bench Press"]={"Bench Press","BenchPress"},["Squat"]={"Squat","Squat"},["Deadlift"]={"Deadlift","Deadlift"},
	["Lat Pulldown"]={"Lat Pulldown","LatPull"},["Cable Row"]={"Cable Row","CableRow"},["Tricep Pulldown"]={"Tricep Pushdown","Tricep_value"},
	["Hack Squat"]={"Hack Squat","Squat"},["Calves Press"]={"Calves Press","Calve"},
	["Preacher Curls"]={"Preacher Curls","Biceps"},["Forearm Curls"]={"Preacher Forearm","Forearm"},
	["Pec Fly"]={"Pec Fly","BenchPress"},["Reverse Delt Fly"]={"Reverse Delt Fly","LatRaise"},
	["Seated Leg Curl"]={"Seated Leg Curl","Hamstring"},
}

local S={
	gamepassOwned=false,
	clean=false, cal=false, cals=false, shaker=false, weights=false,
	threshold=CFG.defaultThreshold, calExercise=CFG.calis[1], calRest=CFG.restSecs,
	wExercise=WORKOUT[1][1], wWeight=0, wZone="Off",
	drinking=false, calBursting=false, wBursting=false,
	status={clean="idle",cal="idle",cals="idle",shaker="idle",weights="idle"},
}
local conns={}
local gui
local posCache={}

--══ shared helpers ══
local function char() local c=LP.Character return c,c and c:FindFirstChild("HumanoidRootPart"),c and c:FindFirstChildOfClass("Humanoid") end
local function tp(p) local _,h=char() if h then h.CFrame=CFrame.new(p) end end
local function gymStat(n) local g=LP:FindFirstChild("GymStats") local v=g and g:FindFirstChild(n) return v and v.Value end
local function inGym() return LP:GetAttribute("InGymExercise")==true end
local function serverNow() local ok,t=pcall(function() return WS:GetServerTimeNow() end) return ok and t or os.time() end
local function leave() local e=RS:FindFirstChild("GymMachineEvent") if e then pcall(function() e:FireServer("LeaveExercise") end) end end
local function firePrompt(p) if hasFPP then fireproximityprompt(p) else pcall(function() PPS:InputHoldBegin(LP,p) task.wait(math.max(0.05,p.HoldDuration)) PPS:InputHoldEnd(LP,p) end) end end
-- fire a GUI button reliably (game identity avoids the require boundary on wired handlers)
local function fireBtn(b)
	if not b then return end
	local prev
	if hasSTI then prev=getthreadidentity() setthreadidentity(2) end
	pcall(function() for _,c in ipairs(getconnections(b.MouseButton1Click)) do c:Fire() end end)
	if hasSTI and prev then setthreadidentity(prev) end
end
local function repClick()
	local cam=WS.CurrentCamera local vp=cam and cam.ViewportSize or Vector2.new(1280,720)
	VIM:SendMouseButtonEvent(vp.X*0.5,vp.Y*0.55,0,true,game,0) task.wait(0.03)
	VIM:SendMouseButtonEvent(vp.X*0.5,vp.Y*0.55,0,false,game,0)
end
local function checkGamepass()
	if CFG.gamepassId==0 then S.gamepassOwned=true return end
	local ok,owns=pcall(function() return Market:UserOwnsGamePassAsync(LP.UserId,CFG.gamepassId) end)
	S.gamepassOwned=ok and owns==true
end
-- shop (shared by food + supplements)
local function openShop()
	local sp=WS:FindFirstChild(CFG.shopPart) if not sp then return nil end
	tp(sp.Position+Vector3.new(0,3,4)) task.wait(0.4)
	local pr=sp:FindFirstChildWhichIsA("ProximityPrompt") if not pr then return nil end
	firePrompt(pr)
	local sh for _=1,30 do sh=LP.PlayerGui:FindFirstChild("CashShopGui") if sh and sh.Enabled then break end task.wait(0.1) end
	return (sh and sh.Enabled) and sh or nil
end
local function buyShopItem(item)
	local sh=openShop() if not sh then return false end
	local it=sh:FindFirstChild("MainFrame") it=it and it:FindFirstChild("ButtonContainer") it=it and it:FindFirstChild(item)
	if not it then pcall(function() sh.Enabled=false end) return false end
	fireBtn(it) task.wait(0.4)
	local cf=sh.MainFrame:FindFirstChild("ConfirmDialog")
	if cf and cf.Visible then local cb=cf:FindFirstChild("ConfirmCard") cb=cb and cb:FindFirstChild("ConfirmButton") if cb then fireBtn(cb) task.wait(0.6) end end
	pcall(function() sh.Enabled=false end)
	return true
end

--══ AUTO-CLEAN ══
local function nearestTrash()
	local _,hrp=char() if not hrp then return nil end
	local best,bd
	local function scan(c) if not c then return end
		for _,m in ipairs(c:GetChildren()) do
			if m:IsA("Model") and CFG.trashNames[m.Name] then
				for _,d in ipairs(m:GetDescendants()) do if d:IsA("ProximityPrompt") and d.Enabled and d.Parent:IsA("BasePart") then
					local dist=(d.Parent.Position-hrp.Position).Magnitude if not bd or dist<bd then best,bd=d,dist end break end end
			end
		end
	end
	scan(WS:FindFirstChild(CFG.trashFolder)) scan(WS) return best
end
task.spawn(function() while alive() do task.wait(0.3)
	if S.clean and S.gamepassOwned then
		local p=nearestTrash()
		if p and p.Parent then tp(p.Parent.Position+Vector3.new(0,3,0)) task.wait(0.1) firePrompt(p) S.status.clean="cleaning trash…"
		else S.status.clean="no trash nearby" end
	end end end)

--══ AUTO-MAINTAIN CALORIES ══
local function getFoodTool()
	local c=LP.Character local bp=LP:FindFirstChild("Backpack")
	for _,cont in ipairs({c,bp}) do if cont then local t=cont:FindFirstChild(CFG.foodTool) if t and t:IsA("Tool") then return t,cont end end end
end
local function eatFood()
	local t=getFoodTool() if not t then return false end
	local c,_,hum=char() if not hum then return false end
	if t.Parent~=c then hum:EquipTool(t) task.wait(0.2) end
	if t.Parent==c then t:Activate() return true end return false
end
task.spawn(function() while alive() do task.wait(1.5)
	if S.cal and S.gamepassOwned then
		local cal=gymStat("Calories") local th=S.threshold or CFG.defaultThreshold
		if not cal then S.status.cal="waiting for stats…"
		elseif cal<th then
			if not getFoodTool() then S.status.cal="buying Chicken & Rice…" buyShopItem(CFG.foodItem) end
			if getFoodTool() then S.status.cal=string.format("eating  %d / %d",cal,th) eatFood() else S.status.cal="need cash to buy food" end
		else S.status.cal=string.format("OK  %d / %d",cal,th) end
	end end end)

--══ AUTO-SHAKER ══
local shakeState
local function findShakeState()
	if shakeState or not hasGC then return shakeState end
	for _,o in ipairs(getgc(true)) do if type(o)=="table" and rawget(o,"assign") and rawget(o,"getInventory") and rawget(o,"canAssign") and rawget(o,"refundAndClearShaker") then shakeState=o break end end
	return shakeState
end
local function buffActive() local e=LP:GetAttribute("SupplementBuffExpires") return typeof(e)=="number" and e>serverNow()+3 end
local function getShaker() local c=LP.Character local bp=LP:FindFirstChild("Backpack") for _,cont in ipairs({c,bp}) do if cont then local t=cont:FindFirstChild("Shaker") if t and t:IsA("Tool") then return t,cont end end end end
local function invCount(a) local v=LP:GetAttribute(a) return typeof(v)=="number" and v or 0 end
local function mixAndDrink()
	local SS=findShakeState() if not SS then return false,"no module" end
	if invCount("SupplementInvCreatine")<CFG.creatineScoops then S.status.shaker="buying creatine…" buyShopItem(CFG.shopCreatine) end
	if invCount("SupplementInvWhey")<CFG.wheyScoops then S.status.shaker="buying whey…" buyShopItem(CFG.shopWhey) end
	if invCount("SupplementInvCreatine")<1 and invCount("SupplementInvWhey")<1 then return false,"low cash" end
	S.status.shaker="mixing…" pcall(SS.refundAndClearShaker) task.wait(0.2)
	for _=1,CFG.creatineScoops do pcall(SS.assign,"Creatine") task.wait(0.1) end
	for _=1,CFG.wheyScoops do pcall(SS.assign,"Whey") task.wait(0.1) end
	task.wait(0.2)
	if not (pcall(SS.hasShakeContents) and SS.hasShakeContents()) then return false,"empty" end
	local sk=getShaker() if not sk then return false,"no shaker" end
	local c,_,hum=char() if not hum then return false,"no hum" end
	if sk.Parent~=c then hum:EquipTool(sk) task.wait(0.35) end
	sk:Activate()
	local dl for _=1,20 do local sg=LP.PlayerGui:FindFirstChild("SupplementsGui") dl=sg and sg:FindFirstChild("DrinkConfirmDialog") if dl and dl.Visible then break end task.wait(0.05) end
	if dl then local cb=dl:FindFirstChild("ConfirmCard") cb=cb and cb:FindFirstChild("ConfirmButton") if cb then fireBtn(cb) end end
	task.wait(0.6) pcall(function() hum:UnequipTools() end)
	return buffActive(),"drank"
end
task.spawn(function() while alive() do task.wait(2)
	if S.shaker and S.gamepassOwned then
		if buffActive() then local e=LP:GetAttribute("SupplementBuffExpires") or 0 local sp=LP:GetAttribute("SupplementSpeedMult") or 1
			S.status.shaker=string.format("buff active  %.0fs · %.2fx",e-serverNow(),sp)
		else
			-- don't interrupt an active rep set
			if (S.cals and S.calBursting) or (S.weights and S.wBursting) then S.status.shaker="waiting for rest window"
			else S.drinking=true local ok,why=mixAndDrink() S.drinking=false S.status.shaker=ok and "buff refreshed" or ("waiting: "..tostring(why)) if not ok then task.wait(3) end end
		end
	end end end)

--══ BALANCE SOLVER (calisthenics minigame) ══
local balMod, balIdx=nil, 5
local function findBalMod()
	if balMod or not hasGC then return balMod end
	for _,o in ipairs(getgc(true)) do if type(o)=="table" and rawget(o,"canRepNow") and rawget(o,"isActive") and rawget(o,"start") and rawget(o,"stop") then balMod=o break end end
	return balMod
end
conns.bal=RunS.Heartbeat:Connect(function()
	if not alive() or not S.cals then return end
	local B=findBalMod() if not (B and hasSUV) then return end
	local ok,active=pcall(B.isActive) if not (ok and active) then return end
	local f=B.start
	pcall(debug.setupvalue,f,balIdx,0.5) pcall(debug.setupvalue,f,balIdx+1,0.5)
	pcall(debug.setupvalue,f,balIdx+2,0) pcall(debug.setupvalue,f,balIdx+3,0)
end)
task.spawn(function() while alive() do task.wait(0.5)
	if S.cals and balMod and hasSUV then
		local ok,active=pcall(balMod.isActive)
		if ok and active then
			local cg=LP.PlayerGui:FindFirstChild("CalisthenicsBalanceGui")
			local cur=cg and cg:FindFirstChild("BalanceRoot") cur=cur and cur:FindFirstChild("BalanceBox") cur=cur and cur:FindFirstChild("Cursor")
			if cur then local cx,cy=cur.Position.X.Scale,cur.Position.Y.Scale
				if math.abs(cx-0.5)>0.14 or math.abs(cy-0.5)>0.14 then
					local f=balMod.start
					for i=1,40 do local a=select(2,pcall(debug.getupvalue,f,i)) local b=select(2,pcall(debug.getupvalue,f,i+1))
						if type(a)=="number" and type(b)=="number" and math.abs(a-cx)<0.04 and math.abs(b-cy)<0.04 then balIdx=i break end end
				end
			end
		end
	end end end)

--══ AUTO-CALISTHENICS ══
local function startCalis(ex)
	local mat=WS:FindFirstChild(CFG.yogaModel) if not mat then return false end
	local mp=mat:FindFirstChild("MatPos") or mat
	local target=(mp:IsA("BasePart") and mp.Position or mat:GetPivot().Position)+Vector3.new(0,3,0)
	for _=1,3 do tp(target) task.wait(0.15) end
	local pr for _,d in ipairs(mat:GetDescendants()) do if d:IsA("ProximityPrompt") then pr=d break end end
	if not pr then return false end
	firePrompt(pr)
	local menu for _=1,30 do menu=LP.PlayerGui:FindFirstChild(CFG.yogaMenu) if menu and menu.Enabled then break end task.wait(0.1) end
	if not (menu and menu.Enabled) then return false end
	local btn=menu:FindFirstChild("MainFrame") btn=btn and btn:FindFirstChild("ButtonContainer") btn=btn and btn:FindFirstChild("CalBtn_"..ex)
	if not btn then return false end
	fireBtn(btn)
	for _=1,20 do if inGym() then return true end task.wait(0.1) end
	return inGym()
end
local lastCalStart=0
local function calInSession() return inGym() and LP:GetAttribute("SessionExercise")==S.calExercise end
task.spawn(function() while alive() do
	if S.cals and S.gamepassOwned and not S.drinking then
		if not calInSession() then
			S.calBursting=false
			if os.clock()-lastCalStart>=CFG.startRetry then lastCalStart=os.clock()
				S.status.cals="starting "..S.calExercise.."…"
				if not startCalis(S.calExercise) then S.status.cals="retrying "..S.calExercise.."…" end end
			task.wait(0.4)
		else
			S.calBursting=true
			while alive() and S.cals and not S.drinking and calInSession() do
				local st=gymStat("Stamina") or 0 if st<=CFG.setEnd then break end
				S.status.cals=string.format("repping %s · %.0f stam",S.calExercise,st) repClick() task.wait(CFG.repPoll)
			end
			S.calBursting=false
			if calInSession() then leave() end
			lastCalStart=os.clock()
			local rf=math.max(0,S.calRest or CFG.restSecs) local t0=os.clock()
			while alive() and S.cals and not S.drinking and os.clock()-t0<rf do
				S.status.cals=string.format("set done · resting %.0fs · %.0f stam",rf-(os.clock()-t0),gymStat("Stamina") or 0) task.wait(0.3) end
		end
	else task.wait(0.3) end end end)

--══ AUTO-WEIGHTS (machines) ══
local function wDef(label) for _,e in ipairs(WORKOUT) do if e[1]==label then return e end end return WORKOUT[1] end
local function findMachine(name)
	local _,hrp=char() local best,bd
	for _,c in ipairs(WS:GetChildren()) do
		if c.Name==name and (c:IsA("Model") or c:IsA("Part")) then
			local pr for _,d in ipairs(c:GetDescendants()) do if d:IsA("ProximityPrompt") then pr=d break end end
			if pr then local dist=hrp and (pr.Parent.Position-hrp.Position).Magnitude or 0 if not bd or dist<bd then best,bd=c,dist end end
		end
	end
	return best
end
local function standPositions(m,pp)
	local list={}
	for _,d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") and (d.Name=="PlayerPosition" or d.Name:match("Pos$") or d.Name:match("Position$")) then table.insert(list,d.Position) end end
	local o=pp.Position
	for _,off in ipairs({Vector3.new(0,0,4),Vector3.new(0,0,-4),Vector3.new(4,0,0),Vector3.new(-4,0,0),Vector3.new(0,0,6),Vector3.new(6,0,0)}) do table.insert(list,o+off) end
	return list
end
local function killStaleMenus(keep) for _,g in ipairs(LP.PlayerGui:GetChildren()) do if g:IsA("ScreenGui") and g.Name~=keep and (g.Name:find("Menu") or g.Name=="ScreenGui" or g.Name=="ScreenGui2") then pcall(function() g.Enabled=false end) end end end
local function startWorkout(entry)
	local label,mName,menuName,btnName=entry[1],entry[2],entry[3],entry[4]
	local m=findMachine(mName) if not m then S.status.weights="machine not found: "..mName return false end
	local prompt for _,d in ipairs(m:GetDescendants()) do if d:IsA("ProximityPrompt") then prompt=d break end end
	if not prompt then return false end
	local pp=prompt.Parent
	local positions={} if posCache[mName] then table.insert(positions,posCache[mName]) end
	for _,p in ipairs(standPositions(m,pp)) do table.insert(positions,p) end
	for _,pos in ipairs(positions) do
		if not (alive() and S.weights) then return false end
		killStaleMenus(menuName or "")
		for _=1,2 do tp(pos) task.wait(0.15) end
		firePrompt(prompt) task.wait(1.1)
		if not menuName then if inGym() then posCache[mName]=pos return true end
		else
			local menu=LP.PlayerGui:FindFirstChild(menuName)
			if menu and menu.Enabled then
				local btn=menu:FindFirstChild(btnName,true)
				if btn then posCache[mName]=pos fireBtn(btn) for _=1,20 do if inGym() then return true end task.wait(0.1) end if inGym() then return true end end
			end
		end
	end
	return inGym()
end
-- weight: barbell (WeightSelectorGui, additive Plate_X = X*2) or cable (WeightSelectorGui2, absolute presets)
local PLATE_BTNS={{"Plate_100",200},{"Plate_50",100},{"Plate_20",40},{"Plate_10",20},{"Plate_5",10},{"Plate_2.5",5}}
local function currentWeightVal()
	local c=LP.Character if not c then return nil end
	local f=c:FindFirstChild("GymSessionTools")
	if f then for _,d in ipairs(f:GetDescendants()) do if d.Name=="CurrentWeight" and d:IsA("NumberValue") then return d end end end
end
local function snapBar(t) if t<=CFG.barKg then return CFG.barKg end return CFG.barKg+math.floor((t-CFG.barKg)/5+0.5)*5 end
local function loadWeight(target)
	local C=currentWeightVal() if not C then return nil end
	local p1=LP.PlayerGui:FindFirstChild("WeightSelectorGui")
	local p2=LP.PlayerGui:FindFirstChild("WeightSelectorGui2")
	if p2 and p2.Enabled then -- cable: absolute presets, click nearest
		local best,bd for _,d in ipairs(p2:GetDescendants()) do if d:IsA("TextButton") then local kg=tonumber(tostring(d.Name):match("^Plate_(%d+%.?%d*)$")) if kg then local diff=math.abs(kg-target) if not bd or diff<bd then best,bd=d,diff end end end end
		if best then fireBtn(best) task.wait(0.3) end
		return C.Value
	end
	if p1 and p1.Enabled then -- barbell: additive plates (buttons debounce ~0.4s)
		target=snapBar(target)
		local function b(n) for _,d in ipairs(p1:GetDescendants()) do if d.Name==n and d:IsA("TextButton") then return d end end end
		for _=1,3 do fireBtn(b("ResetButton")) task.wait(0.3) if (C.Value or 0)<=CFG.barKg+0.5 then break end end
		local remaining=target-(C.Value or CFG.barKg) local guard=0
		while remaining>=5-0.01 and guard<120 do
			local picked for _,p in ipairs(PLATE_BTNS) do if p[2]<=remaining+0.01 then picked=p break end end
			if not picked then break end
			local before=C.Value fireBtn(b(picked[1])) task.wait(0.4)
			if C.Value>before+0.01 then remaining=target-C.Value guard=0 else guard=guard+1 end
		end
		return C.Value
	end
	return nil
end
local AWU
local function findAWU() if AWU or not hasGC then return AWU end for _,o in ipairs(getgc(true)) do if type(o)=="table" and rawget(o,"getSnappedTarget") and rawget(o,"getLiftStat") and rawget(o,"findStrengthSnappedWeight") then AWU=o break end end return AWU end
local function autoZoneWeight(label,zone)
	local map=AWMAP[label] if not map then return nil end
	local u=findAWU() if not u then return nil end
	local ls=LP:FindFirstChild("LiftStats") local gs=LP:FindFirstChild("GymStats")
	local sv=(ls and ls:FindFirstChild(map[2])) or (gs and gs:FindFirstChild(map[2]))
	sv=(sv and sv:IsA("NumberValue")) and math.max(1,sv.Value) or 1
	local prev if hasSTI then prev=getthreadidentity() setthreadidentity(2) end
	local ok,w=pcall(function() return u.getSnappedTarget(map[1], sv, zone) end)
	if hasSTI and prev then setthreadidentity(prev) end
	if ok and type(w)=="number" then return w end
end
local lastWStart=0
task.spawn(function() while alive() do
	if S.weights and S.gamepassOwned and not S.drinking then
		if not inGym() then
			S.wBursting=false
			if os.clock()-lastWStart>=CFG.startRetry then lastWStart=os.clock()
				S.status.weights="going to "..S.wExercise.."…"
				if not startWorkout(wDef(S.wExercise)) then S.status.weights="retrying "..S.wExercise.."…" end end
			task.wait(0.4)
		else
			-- weight: auto-zone overrides manual
			local loaded, wLabel
			if S.wZone~="Off" then
				local tgt=autoZoneWeight(S.wExercise,S.wZone)
				if tgt then loaded=loadWeight(tgt) wLabel=string.format(" @ %s %.0fkg",S.wZone,loaded or tgt) end
			elseif S.wWeight and S.wWeight>0 then
				loaded=loadWeight(S.wWeight) wLabel=" @ "..math.floor(loaded or S.wWeight).."kg"
			end
			wLabel=wLabel or ""
			task.wait(0.15)
			S.wBursting=true
			local stall=0
			while alive() and S.weights and not S.drinking and inGym() do
				local st=gymStat("Stamina") or 0 if st<=CFG.setEnd then break end
				local before=st
				S.status.weights=string.format("repping %s%s · %.0f stam",S.wExercise,wLabel,st)
				repClick() task.wait(CFG.repPoll)
				local now=gymStat("Stamina") or st
				if now>=before-0.01 then stall=stall+1 else stall=0 end
				if stall>=30 then S.status.weights=string.format("%s%s · too heavy? lower weight",S.wExercise,wLabel) task.wait(1) break end
			end
			S.wBursting=false
			if inGym() then leave() end
			lastWStart=os.clock()
			local goal=math.min(CFG.staminaFull, gymStat("MaxStamina") or CFG.staminaFull)
			while alive() and S.weights and not S.drinking and (gymStat("Stamina") or 0)<goal-0.5 do
				S.status.weights=string.format("resting · %.0f / %.0f stam",gymStat("Stamina") or 0,goal) task.wait(0.4) end
		end
	else task.wait(0.3) end end end)

--══ GUI ══
local TH={bg=Color3.fromRGB(15,16,20),panel=Color3.fromRGB(24,26,32),card=Color3.fromRGB(31,34,42),c2=Color3.fromRGB(40,43,53),sk=Color3.fromRGB(48,52,64),
	accent=Color3.fromRGB(72,210,130),accent2=Color3.fromRGB(64,156,255),violet=Color3.fromRGB(150,130,235),amber=Color3.fromRGB(232,180,90),
	accentDim=Color3.fromRGB(28,52,40),danger=Color3.fromRGB(232,92,92),tx=Color3.fromRGB(238,240,245),sub=Color3.fromRGB(150,155,167),off=Color3.fromRGB(44,47,57)}
local function corner(o,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=o return c end
local function stroke(o,c,t) local s=Instance.new("UIStroke") s.Color=c s.Thickness=t or 1 s.Parent=o return s end
local reopen

local function build()
	local pg=LP:WaitForChild("PlayerGui")
	local old=pg:FindFirstChild("UGGAutoAssistant") if old then old:Destroy() end
	local g=Instance.new("ScreenGui") g.Name="UGGAutoAssistant" g.ResetOnSpawn=false g.IgnoreGuiInset=true g.ZIndexBehavior=Enum.ZIndexBehavior.Sibling g.DisplayOrder=1000 g.Parent=pg
	gui=g
	reopen=Instance.new("TextButton") reopen.Name="Chip" reopen.Size=UDim2.fromOffset(54,54) reopen.Position=UDim2.fromOffset(28,90) reopen.BackgroundColor3=TH.panel reopen.Text="GYM" reopen.Font=Enum.Font.GothamBold reopen.TextSize=13 reopen.TextColor3=TH.accent reopen.Visible=false reopen.AutoButtonColor=true reopen.Parent=g corner(reopen,14) stroke(reopen,TH.sk,1)

	local root=Instance.new("Frame") root.Name="Root" root.Position=UDim2.fromOffset(28,80) root.Size=UDim2.fromOffset(430,392) root.BackgroundColor3=TH.bg root.BorderSizePixel=0 root.Parent=g corner(root,16) stroke(root,TH.sk,1)
	local shadow=Instance.new("ImageLabel") shadow.BackgroundTransparency=1 shadow.Image="rbxassetid://6014261993" shadow.ImageColor3=Color3.new(0,0,0) shadow.ImageTransparency=0.35 shadow.ScaleType=Enum.ScaleType.Slice shadow.SliceCenter=Rect.new(49,49,450,450) shadow.Size=UDim2.new(1,44,1,44) shadow.Position=UDim2.fromOffset(-22,-18) shadow.ZIndex=0 shadow.Parent=root

	-- header
	local header=Instance.new("Frame") header.Size=UDim2.new(1,0,0,54) header.BackgroundColor3=TH.panel header.BorderSizePixel=0 header.Active=true header.Parent=root corner(header,16)
	local hfix=Instance.new("Frame") hfix.Size=UDim2.new(1,0,0,16) hfix.Position=UDim2.new(0,0,1,-16) hfix.BackgroundColor3=TH.panel hfix.BorderSizePixel=0 hfix.Parent=header
	local bar=Instance.new("Frame") bar.Size=UDim2.fromOffset(4,26) bar.Position=UDim2.fromOffset(16,14) bar.BorderSizePixel=0 bar.Parent=header corner(bar,2)
	local grad=Instance.new("UIGradient") grad.Color=ColorSequence.new(TH.accent,TH.accent2) grad.Rotation=20 grad.Parent=bar
	local title=Instance.new("TextLabel") title.BackgroundTransparency=1 title.Position=UDim2.fromOffset(30,8) title.Size=UDim2.new(1,-210,0,20) title.Font=Enum.Font.GothamBold title.TextSize=16 title.TextColor3=TH.tx title.TextXAlignment=Enum.TextXAlignment.Left title.Text="Gym Auto Assistant" title.Parent=header
	local sub=Instance.new("TextLabel") sub.BackgroundTransparency=1 sub.Position=UDim2.fromOffset(30,29) sub.Size=UDim2.new(1,-210,0,14) sub.Font=Enum.Font.Gotham sub.TextSize=10 sub.TextColor3=TH.sub sub.TextXAlignment=Enum.TextXAlignment.Left sub.Text="v9 · unified" sub.Parent=header
	-- stat chips in header
	local function hchip(x,name) local f=Instance.new("Frame") f.Size=UDim2.fromOffset(70,34) f.Position=UDim2.new(1,x,0.5,-17) f.BackgroundColor3=TH.card f.BorderSizePixel=0 f.Parent=header corner(f,8)
		local n=Instance.new("TextLabel") n.BackgroundTransparency=1 n.Position=UDim2.fromOffset(8,3) n.Size=UDim2.new(1,-12,0,10) n.Font=Enum.Font.Gotham n.TextSize=9 n.TextColor3=TH.sub n.TextXAlignment=Enum.TextXAlignment.Left n.Text=name n.Parent=f
		local v=Instance.new("TextLabel") v.BackgroundTransparency=1 v.Position=UDim2.fromOffset(8,14) v.Size=UDim2.new(1,-12,0,16) v.Font=Enum.Font.GothamBold v.TextSize=13 v.TextColor3=TH.tx v.TextXAlignment=Enum.TextXAlignment.Left v.Text="—" v.Parent=f return v end
	local calChip=hchip(-232,"CALORIES") local stamChip=hchip(-156,"STAMINA")
	local gpDot=Instance.new("Frame") gpDot.Size=UDim2.fromOffset(9,9) gpDot.Position=UDim2.new(1,-74,0,10) gpDot.BackgroundColor3=TH.off gpDot.BorderSizePixel=0 gpDot.Parent=header corner(gpDot,5)
	local minBtn=Instance.new("TextButton") minBtn.Size=UDim2.fromOffset(28,28) minBtn.Position=UDim2.new(1,-66,0.5,-14) minBtn.BackgroundColor3=TH.c2 minBtn.Text="–" minBtn.Font=Enum.Font.GothamBold minBtn.TextSize=17 minBtn.TextColor3=TH.sub minBtn.Parent=header corner(minBtn,8)
	local closeBtn=Instance.new("TextButton") closeBtn.Size=UDim2.fromOffset(28,28) closeBtn.Position=UDim2.new(1,-34,0.5,-14) closeBtn.BackgroundColor3=TH.c2 closeBtn.Text="✕" closeBtn.Font=Enum.Font.GothamBold closeBtn.TextSize=14 closeBtn.TextColor3=TH.sub closeBtn.Parent=header corner(closeBtn,8)
	-- drag
	do local dragging,dstart,spos
		header.InputBegan:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dragging=true dstart=UIS:GetMouseLocation() spos=root.Position end end)
		UIS.InputEnded:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
		conns.drag=RunS.RenderStepped:Connect(function() if dragging then local m=UIS:GetMouseLocation() root.Position=UDim2.fromOffset(spos.X.Offset+(m.X-dstart.X),spos.Y.Offset+(m.Y-dstart.Y)) end end)
	end

	-- tab bar
	local tabbar=Instance.new("Frame") tabbar.Size=UDim2.new(1,-24,0,32) tabbar.Position=UDim2.fromOffset(12,62) tabbar.BackgroundColor3=TH.panel tabbar.BorderSizePixel=0 tabbar.Parent=root corner(tabbar,9)
	local pages={} local tabBtns={}
	local function showTab(name) for n,p in pairs(pages) do p.Visible=(n==name) end for n,b in pairs(tabBtns) do b.BackgroundColor3=(n==name) and TH.accentDim or TH.panel local l=b:FindFirstChildOfClass("TextLabel") if l then l.TextColor3=(n==name) and TH.accent or TH.sub end end end
	local tabNames={"Calisthenics","Weights","Utility"}
	for i,nm in ipairs(tabNames) do
		local b=Instance.new("TextButton") b.Size=UDim2.new(1/3,-4,1,-6) b.Position=UDim2.new((i-1)/3,3,0,3) b.BackgroundColor3=TH.panel b.AutoButtonColor=false b.Text="" b.Parent=tabbar corner(b,7)
		local l=Instance.new("TextLabel") l.BackgroundTransparency=1 l.Size=UDim2.fromScale(1,1) l.Font=Enum.Font.GothamBold l.TextSize=12 l.TextColor3=TH.sub l.Text=nm l.Parent=b
		tabBtns[nm]=b b.MouseButton1Click:Connect(function() showTab(nm) end)
	end

	local body=Instance.new("Frame") body.BackgroundTransparency=1 body.Position=UDim2.fromOffset(12,102) body.Size=UDim2.new(1,-24,1,-114) body.Parent=root
	local function page(name) local p=Instance.new("Frame") p.Name=name p.BackgroundTransparency=1 p.Size=UDim2.fromScale(1,1) p.Visible=false p.Parent=body pages[name]=p return p end

	-- reusable widgets
	local function card(parent,y,h) local c=Instance.new("Frame") c.Size=UDim2.new(1,0,0,h) c.Position=UDim2.fromOffset(0,y) c.BackgroundColor3=TH.card c.BorderSizePixel=0 c.Parent=parent corner(c,10) stroke(c,TH.sk,1) return c end
	local function sect(pa,txt,col) local l=Instance.new("TextLabel") l.BackgroundTransparency=1 l.Position=UDim2.fromOffset(12,8) l.Size=UDim2.new(1,-24,0,15) l.Font=Enum.Font.GothamBold l.TextSize=11 l.TextColor3=col or TH.accent2 l.TextXAlignment=Enum.TextXAlignment.Left l.Text=txt l.Parent=pa return l end
	local function statusLine(pa,y) local s=Instance.new("TextLabel") s.BackgroundTransparency=1 s.Position=UDim2.fromOffset(12,y) s.Size=UDim2.new(1,-24,0,15) s.Font=Enum.Font.Gotham s.TextSize=11 s.TextColor3=TH.sub s.TextXAlignment=Enum.TextXAlignment.Left s.TextTruncate=Enum.TextTruncate.AtEnd s.Text="idle" s.Parent=pa return s end
	local function toggle(pa,y,label,get,set) local btn=Instance.new("TextButton") btn.Size=UDim2.new(1,-24,0,34) btn.Position=UDim2.fromOffset(12,y) btn.BackgroundColor3=TH.off btn.AutoButtonColor=false btn.Text="" btn.Parent=pa corner(btn,8)
		local l=Instance.new("TextLabel") l.BackgroundTransparency=1 l.Position=UDim2.fromOffset(12,0) l.Size=UDim2.new(1,-70,1,0) l.Font=Enum.Font.GothamMedium l.TextSize=13 l.TextColor3=TH.tx l.TextXAlignment=Enum.TextXAlignment.Left l.Text=label l.Parent=btn
		local tr=Instance.new("Frame") tr.Size=UDim2.fromOffset(40,20) tr.Position=UDim2.new(1,-48,0.5,-10) tr.BackgroundColor3=TH.c2 tr.BorderSizePixel=0 tr.Parent=btn corner(tr,10)
		local kn=Instance.new("Frame") kn.Size=UDim2.fromOffset(14,14) kn.Position=UDim2.fromOffset(3,3) kn.BackgroundColor3=TH.sub kn.BorderSizePixel=0 kn.Parent=tr corner(kn,7)
		local function rf() local on=get() tr.BackgroundColor3=on and TH.accent or TH.c2 kn.BackgroundColor3=on and Color3.new(1,1,1) or TH.sub kn:TweenPosition(on and UDim2.fromOffset(23,3) or UDim2.fromOffset(3,3),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.12,true) btn.BackgroundColor3=on and TH.accentDim or TH.off end
		btn.MouseButton1Click:Connect(function() if not S.gamepassOwned then return end set(not get()) rf() end) rf() return rf end
	local function numField(pa,y,w,label,get,set) local l=Instance.new("TextLabel") l.BackgroundTransparency=1 l.Position=UDim2.fromOffset(12,y) l.Size=UDim2.new(w,-12,0,28) l.Font=Enum.Font.GothamMedium l.TextSize=12 l.TextColor3=TH.tx l.TextXAlignment=Enum.TextXAlignment.Left l.Text=label l.Parent=pa
		local bx=Instance.new("TextBox") bx.Position=UDim2.new(w,0,0,y) bx.Size=UDim2.new(1-w,-12,0,28) bx.BackgroundColor3=TH.c2 bx.Font=Enum.Font.GothamMedium bx.TextSize=12 bx.TextColor3=TH.tx bx.Text=tostring(get()) bx.ClearTextOnFocus=false bx.Parent=pa corner(bx,7)
		bx.FocusLost:Connect(function() local n=tonumber(bx.Text) if n and n>=0 then set(math.floor(n)) bx.Text=tostring(get()) else bx.Text=tostring(get()) end end) return bx end
	local function dropdown(pa,y,options,get,set) local dd=Instance.new("TextButton") dd.Position=UDim2.fromOffset(12,y) dd.Size=UDim2.new(1,-24,0,28) dd.BackgroundColor3=TH.c2 dd.Font=Enum.Font.GothamMedium dd.TextSize=12 dd.TextColor3=TH.tx dd.TextXAlignment=Enum.TextXAlignment.Left dd.Text="  "..get() dd.AutoButtonColor=true dd.Parent=pa corner(dd,7)
		local chev=Instance.new("TextLabel") chev.BackgroundTransparency=1 chev.Position=UDim2.new(1,-24,0,0) chev.Size=UDim2.fromOffset(20,28) chev.Font=Enum.Font.GothamBold chev.TextSize=11 chev.TextColor3=TH.sub chev.Text="▼" chev.Parent=dd
		local ls=Instance.new("ScrollingFrame") ls.Position=UDim2.fromOffset(12,y+30) ls.Size=UDim2.new(1,-24,0,math.min(#options,7)*24) ls.BackgroundColor3=TH.bg ls.BorderSizePixel=0 ls.ScrollBarThickness=4 ls.ScrollBarImageColor3=TH.sk ls.CanvasSize=UDim2.fromOffset(0,#options*24) ls.Visible=false ls.ZIndex=40 ls.Parent=pa corner(ls,7) stroke(ls,TH.sk,1)
		local ll=Instance.new("UIListLayout") ll.Parent=ls
		for _,op in ipairs(options) do local o=Instance.new("TextButton") o.Size=UDim2.new(1,0,0,24) o.BackgroundColor3=TH.bg o.AutoButtonColor=true o.Font=Enum.Font.Gotham o.TextSize=11 o.TextColor3=TH.tx o.Text=op o.ZIndex=41 o.Parent=ls o.MouseButton1Click:Connect(function() set(op) dd.Text="  "..op ls.Visible=false end) end
		dd.MouseButton1Click:Connect(function() ls.Visible=not ls.Visible end) return dd end

	-- ── CALISTHENICS page ──
	local pc=page("Calisthenics")
	sect(pc,"AUTO-CALISTHENICS")
	local ci=Instance.new("TextLabel") ci.BackgroundTransparency=1 ci.Position=UDim2.fromOffset(12,26) ci.Size=UDim2.new(1,-24,0,12) ci.Font=Enum.Font.Gotham ci.TextSize=10 ci.TextColor3=TH.sub ci.TextXAlignment=Enum.TextXAlignment.Left ci.Text="EXERCISE" ci.Parent=pc
	numField(pc,110,0.62,"Rest between sets (s)",function() return S.calRest end,function(v) S.calRest=v end)
	toggle(pc,146,"Auto-solve balance + reps",function() return S.cals end,function(v) S.cals=v if not v then S.calBursting=false end end)
	local cst=statusLine(pc,188)
	local chint=Instance.new("TextLabel") chint.BackgroundTransparency=1 chint.Position=UDim2.fromOffset(12,210) chint.Size=UDim2.new(1,-24,0,40) chint.Font=Enum.Font.Gotham chint.TextSize=10 chint.TextColor3=TH.sub chint.TextWrapped=true chint.TextXAlignment=Enum.TextXAlignment.Left chint.TextYAlignment=Enum.TextYAlignment.Top chint.Text="Walks to the mat, auto-solves the balance minigame, reps a set, rests, repeats." chint.Parent=pc
	dropdown(pc,42,CFG.calis,function() return S.calExercise end,function(v) S.calExercise=v lastCalStart=0 end)

	-- ── WEIGHTS page ──
	local pw=page("Weights")
	sect(pw,"AUTO-WEIGHTS  (machines)",TH.violet)
	local wi=Instance.new("TextLabel") wi.BackgroundTransparency=1 wi.Position=UDim2.fromOffset(12,26) wi.Size=UDim2.new(1,-24,0,12) wi.Font=Enum.Font.Gotham wi.TextSize=10 wi.TextColor3=TH.sub wi.TextXAlignment=Enum.TextXAlignment.Left wi.Text="EXERCISE" wi.Parent=pw
	numField(pw,110,0.5,"Weight (kg)",function() return S.wWeight end,function(v) S.wWeight=v end)
	-- auto-zone cycle
	local az=Instance.new("TextButton") az.Position=UDim2.fromOffset(12,144) az.Size=UDim2.new(1,-24,0,28) az.BackgroundColor3=TH.c2 az.Font=Enum.Font.GothamMedium az.TextSize=12 az.TextColor3=TH.tx az.TextXAlignment=Enum.TextXAlignment.Left az.Text="  Auto weight: Off" az.Parent=pw corner(az,7)
	local ZONES={"Off","Hypertrophy","Strength"}
	az.MouseButton1Click:Connect(function() local i=1 for k,z in ipairs(ZONES) do if z==S.wZone then i=k end end S.wZone=ZONES[i%3+1] az.Text="  Auto weight: "..S.wZone az.TextColor3=(S.wZone=="Off") and TH.tx or TH.violet if inGym() then leave() end end)
	local whint=Instance.new("TextLabel") whint.BackgroundTransparency=1 whint.Position=UDim2.fromOffset(12,176) whint.Size=UDim2.new(1,-24,0,12) whint.Font=Enum.Font.Gotham whint.TextSize=9 whint.TextColor3=TH.sub whint.TextXAlignment=Enum.TextXAlignment.Left whint.Text="bar 20kg + plates · 0/Off = default · auto-zone overrides weight" whint.Parent=pw
	toggle(pw,192,"Auto lift",function() return S.weights end,function(v) S.weights=v if not v then S.wBursting=false end end)
	local wst=statusLine(pw,232)
	local wlabels={} for _,e in ipairs(WORKOUT) do table.insert(wlabels,e[1]) end
	dropdown(pw,42,wlabels,function() return S.wExercise end,function(v) S.wExercise=v lastWStart=0 end)

	-- ── UTILITY page ──
	local pu=page("Utility")
	local u1=card(pu,0,66) sect(u1,"AUTO-CLEAN") toggle(u1,26,"Collect trash on loop",function() return S.clean end,function(v) S.clean=v end)
	local ust1=statusLine(u1,50)  -- placed inside card via absolute? use separate
	-- put status under toggle by extending card; simpler: status below
	local c1st=Instance.new("TextLabel") c1st.BackgroundTransparency=1 c1st.Position=UDim2.new(0,12,0,50) c1st.Size=UDim2.new(1,-24,0,14) c1st.Font=Enum.Font.Gotham c1st.TextSize=10 c1st.TextColor3=TH.sub c1st.TextXAlignment=Enum.TextXAlignment.Left c1st.Text="idle" c1st.Parent=u1 ust1:Destroy()
	local u2=card(pu,74,96) sect(u2,"AUTO-MAINTAIN CALORIES") numField(u2,26,0.5,"Threshold",function() return S.threshold end,function(v) S.threshold=v end)
	toggle(u2,58,"Keep calories topped up",function() return S.cal end,function(v) S.cal=v end)
	local c2st=Instance.new("TextLabel") c2st.BackgroundTransparency=1 c2st.Position=UDim2.new(0,12,0,-2) c2st.Size=UDim2.new(1,-24,0,14) c2st.Visible=false c2st.Parent=u2
	local u2s=Instance.new("TextLabel") u2s.BackgroundTransparency=1 u2s.Position=UDim2.fromOffset(220,26) u2s.Size=UDim2.new(0,120,0,28) u2s.Font=Enum.Font.Gotham u2s.TextSize=10 u2s.TextColor3=TH.sub u2s.TextXAlignment=Enum.TextXAlignment.Right u2s.TextYAlignment=Enum.TextYAlignment.Center u2s.Text="" u2s.Parent=u2
	local u3=card(pu,180,66) sect(u3,"AUTO-SHAKER  (buffs)",TH.amber) toggle(u3,26,"Keep creatine + whey buff up",function() return S.shaker end,function(v) S.shaker=v end)
	local c3st=Instance.new("TextLabel") c3st.BackgroundTransparency=1 c3st.Position=UDim2.new(0,12,0,50) c3st.Size=UDim2.new(1,-24,0,14) c3st.Font=Enum.Font.Gotham c3st.TextSize=10 c3st.TextColor3=TH.sub c3st.TextXAlignment=Enum.TextXAlignment.Left c3st.Text="idle" c3st.Parent=u3

	showTab("Calisthenics")

	-- minimize / restore
	local function setMin(m) root.Visible=not m reopen.Visible=m if m then reopen.Position=root.Position end end
	minBtn.MouseButton1Click:Connect(function() setMin(true) end)
	closeBtn.MouseButton1Click:Connect(function() setMin(true) end)
	reopen.MouseButton1Click:Connect(function() setMin(false) end)
	do local dr,ds,sp
		reopen.InputBegan:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dr=true ds=UIS:GetMouseLocation() sp=reopen.Position end end)
		UIS.InputEnded:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dr=false end end)
		conns.chip=RunS.RenderStepped:Connect(function() if dr then local m=UIS:GetMouseLocation() reopen.Position=UDim2.fromOffset(sp.X.Offset+(m.X-ds.X),sp.Y.Offset+(m.Y-ds.Y)) end end)
	end

	conns.render=RunS.RenderStepped:Connect(function()
		cst.Text=S.status.cals cst.TextColor3=S.cals and TH.accent or TH.sub
		wst.Text=S.status.weights wst.TextColor3=S.weights and TH.violet or TH.sub
		c1st.Text=S.status.clean c1st.TextColor3=S.clean and TH.accent or TH.sub
		u2s.Text=S.status.cal u2s.TextColor3=S.cal and TH.accent or TH.sub
		c3st.Text=S.status.shaker c3st.TextColor3=S.shaker and TH.amber or TH.sub
		gpDot.BackgroundColor3=S.gamepassOwned and TH.accent or TH.danger
		local cal=gymStat("Calories") local st=gymStat("Stamina")
		calChip.Text=cal and tostring(math.floor(cal)) or "—" stamChip.Text=st and string.format("%.0f",st) or "—"
	end)
	return g
end

_G.__ugg.stop=function()
	S.clean,S.cal,S.cals,S.shaker,S.weights=false,false,false,false,false
	_G.__ugg=nil
	for _,c in pairs(conns) do pcall(function() c:Disconnect() end) end
	if gui then pcall(function() gui:Destroy() end) end
end

checkGamepass()
build()
print(string.format("[UGG Auto v9] loaded · gp:%s fpp:%s gc:%s suv:%s sti:%s",tostring(S.gamepassOwned),tostring(hasFPP),tostring(hasGC),tostring(hasSUV),tostring(hasSTI)))

