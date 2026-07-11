


-- UGG Auto Assistant v8 (obfuscated)
-- Features: Auto-Clean, Auto-Maintain Cal, Auto-Calisthenics (balance solver), Auto-Shaker
if _G._ua and typeof(_G._ua.x)=="function" then pcall(_G._ua.x) end
local _t={} _G._ua={token=_t,x=nil}
local function _a() return _G._ua and _G._ua.token==_t end
local _P=game:GetService("Players")
local _RS=game:GetService("ReplicatedStorage")
local _R=game:GetService("RunService")
local _M=game:GetService("MarketplaceService")
local _PS=game:GetService("ProximityPromptService")
local _V=game:GetService("VirtualInputManager")
local _U=game:GetService("UserInputService")
local _W=game:GetService("Workspace")
local _L=_P.LocalPlayer
local _fp=typeof(fireproximityprompt)=="function"
local _gc=typeof(getgc)=="function"
local _cn=typeof(getconnections)=="function"
local _sv=typeof(debug)=="table" and typeof(debug.setupvalue)=="function" and typeof(debug.getupvalue)=="function"

local _C={gp=0,tf="ActiveTrash",tn={water_spill=true,floortrash=true},sp="CounterShop",ft="Chicken_rice",sf="Item_chicken_rice",dt=3000,ym="YogaMat",yme="YogaExerciseMenu",ex={"PushUp","PikePushup","HandstandPush","LSitToHandstandPush","PikeToHandstandToPikeHold","OneArmPushup","TuckPush","LSitToTuckToPlancheToLSit","StraddlePush","PlancheToHandstandPush","TuckToHandstandToPlancheToTuck","OneArmPlanchePush","MalteseElevation"},rp=0.18,se=12,rs=10,sr=3,sc="Item_protein",sw="Item_whey",cs=5,ws=2}
local _T={bg=Color3.fromRGB(16,17,22),cd=Color3.fromRGB(26,28,35),c2=Color3.fromRGB(34,37,46),sk=Color3.fromRGB(46,49,60),ac=Color3.fromRGB(72,210,130),a2=Color3.fromRGB(64,156,255),ad=Color3.fromRGB(30,54,42),dn=Color3.fromRGB(232,92,92),am=Color3.fromRGB(230,180,90),tx=Color3.fromRGB(238,240,245),sb=Color3.fromRGB(146,151,163),of=Color3.fromRGB(44,47,57)}
local _s={gp=false,cl=false,ca=false,cs=false,sh=false,th=_C.dt,ex=_C.ex[1],rt=_C.rs,dk=false,st={cl="idle",ca="idle",cs="idle",sh="idle"}}
local _co={}
local _gui

-- shims
local function _fpr(p) if _fp then fireproximityprompt(p) else pcall(function() _PS:InputHoldBegin(_L,p) task.wait(math.max(0.05,p.HoldDuration)) _PS:InputHoldEnd(_L,p) end) end end
local function _cb(b) if _cn then local o=pcall(function() for _,c in ipairs(getconnections(b.MouseButton1Click)) do c:Fire() end end) if o then return true end end local ap,sz=b.AbsolutePosition,b.AbsoluteSize _V:SendMouseButtonEvent(ap.X+sz.X/2,ap.Y+sz.Y/2,0,true,game,0) task.wait(0.03) _V:SendMouseButtonEvent(ap.X+sz.X/2,ap.Y+sz.Y/2,0,false,game,0) return true end
local function _gc2() local c=_L.Character return c,c and c:FindFirstChild("HumanoidRootPart"),c and c:FindFirstChildOfClass("Humanoid") end
local function _tp(p) local _,h=_gc2() if h then h.CFrame=CFrame.new(p) end end
local function _gs(n) local g=_L:FindFirstChild("GymStats") local v=g and g:FindFirstChild(n) return v and v.Value end
local function _sn() local o,t=pcall(function() return _W:GetServerTimeNow() end) return o and t or os.time() end
local function _rc() local c=_W.CurrentCamera local v=c and c.ViewportSize or Vector2.new(1280,720) _V:SendMouseButtonEvent(v.X*0.5,v.Y*0.55,0,true,game,0) task.wait(0.03) _V:SendMouseButtonEvent(v.X*0.5,v.Y*0.55,0,false,game,0) end
local function _le() local e=_RS:FindFirstChild("GymMachineEvent") if e then pcall(function() e:FireServer("LeaveExercise") end) end end
-- gamepass
local function _cgp() if _C.gp==0 then _s.gp=true return end local o,w=pcall(function() return _M:UserOwnsGamePassAsync(_L.UserId,_C.gp) end) _s.gp=o and w==true end

-- shop
local function _os() local sp=_W:FindFirstChild(_C.sp) if not sp then return nil end _tp(sp.Position+Vector3.new(0,3,4)) task.wait(0.4) local pr=sp:FindFirstChildWhichIsA("ProximityPrompt") if not pr then return nil end _fpr(pr) local sh for _=1,30 do sh=_L.PlayerGui:FindFirstChild("CashShopGui") if sh and sh.Enabled then break end task.wait(0.1) end return(sh and sh.Enabled)and sh or nil end
local function _bs(i) local sh=_os() if not sh then return false end local it=sh:FindFirstChild("MainFrame") it=it and it:FindFirstChild("ButtonContainer") it=it and it:FindFirstChild(i) if not it then pcall(function() sh.Enabled=false end) return false end _cb(it) task.wait(0.4) local cf=sh.MainFrame:FindFirstChild("ConfirmDialog") if cf and cf.Visible then local cb=cf:FindFirstChild("ConfirmCard") cb=cb and cb:FindFirstChild("ConfirmButton") if cb then _cb(cb) task.wait(0.6) end end pcall(function() sh.Enabled=false end) return true end
-- auto-clean
local function _ntp() local _,h=_gc2() if not h then return nil end local b,bd local function sc(c) if not c then return end for _,m in c:GetChildren() do if m:IsA("Model") and _C.tn[m.Name] then for _,d in m:GetDescendants() do if d:IsA("ProximityPrompt") and d.Enabled and d.Parent:IsA("BasePart") then local dt=(d.Parent.Position-h.Position).Magnitude if not bd or dt<bd then b,bd=d,dt end break end end end end end sc(_W:FindFirstChild(_C.tf)) sc(_W) return b end
task.spawn(function() while _a() do task.wait(0.3) if _s.cl and _s.gp then local p=_ntp() if p and p.Parent then _tp(p.Parent.Position+Vector3.new(0,3,0)) task.wait(0.1) _fpr(p) _s.st.cl="cleaning…" else _s.st.cl="no trash" end end end end)
-- auto-maintain
local function _gft() local ch=_L.Character local bp=_L:FindFirstChild("Backpack") for _,ct in ipairs({ch,bp}) do if ct then local t=ct:FindFirstChild(_C.ft) if t and t:IsA("Tool") then return t,ct end end end end
local function _ef() local t=_gft() if not t then return false end local ch,_,hm=_gc2() if not hm then return false end if t.Parent~=ch then hm:EquipTool(t) task.wait(0.2) end if t.Parent==ch then t:Activate() return true end return false end
task.spawn(function() while _a() do task.wait(1.5) if _s.ca and _s.gp then local c=_gs("Calories") local th=_s.th or _C.dt if not c then _s.st.ca="waiting…" elseif c<th then if not _gft() then _s.st.ca="buying food…" _bs(_C.sf) end if _gft() then _s.st.ca=string.format("eating %d/%d",c,th) _ef() else _s.st.ca="need cash" end else _s.st.ca=string.format("OK %d/%d",c,th) end end end end)

-- auto-shaker
local _ss
local function _fss() if _ss or not _gc then return _ss end for _,o in ipairs(getgc(true)) do if type(o)=="table" and rawget(o,"assign") and rawget(o,"getInventory") and rawget(o,"canAssign") and rawget(o,"refundAndClearShaker") then _ss=o break end end return _ss end
local function _ba() local e=_L:GetAttribute("SupplementBuffExpires") return typeof(e)=="number" and e>_sn()+3 end
local function _gsh() local ch=_L.Character local bp=_L:FindFirstChild("Backpack") for _,ct in ipairs({ch,bp}) do if ct then local t=ct:FindFirstChild("Shaker") if t and t:IsA("Tool") then return t,ct end end end end
local function _ic(a) local v=_L:GetAttribute(a) return typeof(v)=="number" and v or 0 end
local function _md() local S=_fss() if not S then return false,"no module" end if _ic("SupplementInvCreatine")<_C.cs then _s.st.sh="buying creatine…" _bs(_C.sc) end if _ic("SupplementInvWhey")<_C.ws then _s.st.sh="buying whey…" _bs(_C.sw) end if _ic("SupplementInvCreatine")<1 and _ic("SupplementInvWhey")<1 then return false,"low cash" end _s.st.sh="mixing…" pcall(S.refundAndClearShaker) task.wait(0.2) for _=1,_C.cs do pcall(S.assign,"Creatine") task.wait(0.1) end for _=1,_C.ws do pcall(S.assign,"Whey") task.wait(0.1) end task.wait(0.2) if not(pcall(S.hasShakeContents) and S.hasShakeContents()) then return false,"empty" end local sk=_gsh() if not sk then return false,"no shaker" end local ch,_,hm=_gc2() if not hm then return false,"no hum" end if sk.Parent~=ch then hm:EquipTool(sk) task.wait(0.35) end sk:Activate() local dl for _=1,20 do local sg=_L.PlayerGui:FindFirstChild("SupplementsGui") dl=sg and sg:FindFirstChild("DrinkConfirmDialog") if dl and dl.Visible then break end task.wait(0.05) end if dl then local cb=dl:FindFirstChild("ConfirmCard") cb=cb and cb:FindFirstChild("ConfirmButton") if cb then _cb(cb) end end task.wait(0.6) pcall(function() hm:UnequipTools() end) return _ba(),"drank" end
task.spawn(function() while _a() do task.wait(2) if _s.sh and _s.gp then if _ba() then local e=_L:GetAttribute("SupplementBuffExpires") or 0 local sp=_L:GetAttribute("SupplementSpeedMult") or 1 _s.st.sh=string.format("buff %.0fs · %.2fx",e-_sn(),sp) else if _s.cs and _s.st.cs:find("repping") then _s.st.sh="waiting for rest" else _s.dk=true local o,w=_md() _s.dk=false _s.st.sh=o and "refreshed" or("wait: "..tostring(w)) if not o then task.wait(3) end end end end end end)

-- balance solver
local _bm,_bi=nil,5
local function _fbm() if _bm or not _gc then return _bm end for _,o in ipairs(getgc(true)) do if type(o)=="table" and rawget(o,"canRepNow") and rawget(o,"isActive") and rawget(o,"start") and rawget(o,"stop") then _bm=o break end end return _bm end
_co.bl=_R.Heartbeat:Connect(function() if not _a() or not _s.cs then return end local B=_fbm() if not(B and _sv) then return end local o,v=pcall(B.isActive) if not(o and v) then return end local f=B.start pcall(debug.setupvalue,f,_bi,0.5) pcall(debug.setupvalue,f,_bi+1,0.5) pcall(debug.setupvalue,f,_bi+2,0) pcall(debug.setupvalue,f,_bi+3,0) end)
task.spawn(function() while _a() do task.wait(0.5) if _s.cs and _bm and _sv then local o,v=pcall(_bm.isActive) if o and v then local cg=_L.PlayerGui:FindFirstChild("CalisthenicsBalanceGui") local cr=cg and cg:FindFirstChild("BalanceRoot") cr=cr and cr:FindFirstChild("BalanceBox") cr=cr and cr:FindFirstChild("Cursor") if cr then local cx,cy=cr.Position.X.Scale,cr.Position.Y.Scale if math.abs(cx-0.5)>0.14 or math.abs(cy-0.5)>0.14 then local f=_bm.start for i=1,40 do local a=select(2,pcall(debug.getupvalue,f,i)) local b=select(2,pcall(debug.getupvalue,f,i+1)) if type(a)=="number" and type(b)=="number" and math.abs(a-cx)<0.04 and math.abs(b-cy)<0.04 then _bi=i break end end end end end end end end)
-- auto-calisthenics
local function _sce(ex) local mt=_W:FindFirstChild(_C.ym) if not mt then return false end local mp=mt:FindFirstChild("MatPos") or mt local tg=(mp:IsA("BasePart") and mp.Position or mt:GetPivot().Position)+Vector3.new(0,3,0) for _=1,3 do _tp(tg) task.wait(0.15) end local pr for _,d in mt:GetDescendants() do if d:IsA("ProximityPrompt") then pr=d break end end if not pr then return false end _fpr(pr) local mn for _=1,30 do mn=_L.PlayerGui:FindFirstChild(_C.yme) if mn and mn.Enabled then break end task.wait(0.1) end if not(mn and mn.Enabled) then return false end local bt=mn:FindFirstChild("MainFrame") bt=bt and bt:FindFirstChild("ButtonContainer") bt=bt and bt:FindFirstChild("CalBtn_"..ex) if not bt then return false end _cb(bt) for _=1,20 do if _L:GetAttribute("InGymExercise")==true then return true end task.wait(0.1) end return _L:GetAttribute("InGymExercise")==true end
local _lcs=0
local function _cis() return _L:GetAttribute("InGymExercise")==true and _L:GetAttribute("SessionExercise")==_s.ex end
task.spawn(function() while _a() do if _s.cs and _s.gp and not _s.dk then if not _cis() then if os.clock()-_lcs>=_C.sr then _lcs=os.clock() _s.st.cs="starting ".._s.ex.."…" if not _sce(_s.ex) then _s.st.cs="retrying ".._s.ex.."…" end end task.wait(0.4) else _s.st.cs="repping ".._s.ex while _a() and _s.cs and not _s.dk and _cis() do local st=_gs("Stamina") or 0 if st<=_C.se then break end _s.st.cs=string.format("repping %s · %.0f",_s.ex,st) _rc() task.wait(_C.rp) end if _cis() then _le() end _lcs=os.clock() local rf=math.max(0,_s.rt or _C.rs) local t0=os.clock() while _a() and _s.cs and not _s.dk and os.clock()-t0<rf do _s.st.cs=string.format("rest %.0fs · %.0f stam",rf-(os.clock()-t0),_gs("Stamina") or 0) task.wait(0.3) end end else task.wait(0.3) end end end)

-- GUI
local function _cr(o,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=o return c end
local function _st(o,cl,t) local s=Instance.new("UIStroke") s.Color=cl s.Thickness=t or 1 s.Parent=o return s end
local _rb
local function _build()
	local pg=_L:WaitForChild("PlayerGui") local old=pg:FindFirstChild("_ugg") if old then old:Destroy() end
	local g=Instance.new("ScreenGui") g.Name="_ugg" g.ResetOnSpawn=false g.IgnoreGuiInset=true g.ZIndexBehavior=Enum.ZIndexBehavior.Sibling g.DisplayOrder=1000 g.Parent=pg _gui=g
	_rb=Instance.new("TextButton") _rb.Name="_o" _rb.Size=UDim2.fromOffset(52,52) _rb.Position=UDim2.fromOffset(28,80) _rb.BackgroundColor3=_T.cd _rb.Text="GYM" _rb.Font=Enum.Font.GothamBold _rb.TextSize=13 _rb.TextColor3=_T.ac _rb.Visible=false _rb.Parent=g _cr(_rb,14) _st(_rb,_T.sk,1)
	local rt=Instance.new("Frame") rt.Name="R" rt.Position=UDim2.fromOffset(28,70) rt.Size=UDim2.fromOffset(580,380) rt.BackgroundColor3=_T.bg rt.BorderSizePixel=0 rt.Parent=g _cr(rt,16) _st(rt,_T.sk,1)
	-- header
	local hd=Instance.new("Frame") hd.Size=UDim2.new(1,0,0,48) hd.BackgroundColor3=_T.cd hd.BorderSizePixel=0 hd.Active=true hd.Parent=rt _cr(hd,16)
	local hf=Instance.new("Frame") hf.Size=UDim2.new(1,0,0,14) hf.Position=UDim2.new(0,0,1,-14) hf.BackgroundColor3=_T.cd hf.BorderSizePixel=0 hf.Parent=hd
	local br=Instance.new("Frame") br.Size=UDim2.fromOffset(4,24) br.Position=UDim2.fromOffset(14,12) br.BorderSizePixel=0 br.Parent=hd _cr(br,2)
	local gd=Instance.new("UIGradient") gd.Color=ColorSequence.new(_T.ac,_T.a2) gd.Rotation=20 gd.Parent=br
	local tl=Instance.new("TextLabel") tl.BackgroundTransparency=1 tl.Position=UDim2.fromOffset(28,6) tl.Size=UDim2.new(1,-130,0,18) tl.Font=Enum.Font.GothamBold tl.TextSize=15 tl.TextColor3=_T.tx tl.TextXAlignment=Enum.TextXAlignment.Left tl.Text="Gym Auto Assistant" tl.Parent=hd
	local sl=Instance.new("TextLabel") sl.BackgroundTransparency=1 sl.Position=UDim2.fromOffset(28,25) sl.Size=UDim2.new(1,-130,0,13) sl.Font=Enum.Font.Gotham sl.TextSize=10 sl.TextColor3=_T.sb sl.TextXAlignment=Enum.TextXAlignment.Left sl.Text="v8 · obfuscated" sl.Parent=hd
	local gd2=Instance.new("Frame") gd2.Size=UDim2.fromOffset(9,9) gd2.Position=UDim2.new(1,-86,0,20) gd2.BackgroundColor3=_T.of gd2.BorderSizePixel=0 gd2.Parent=hd _cr(gd2,5)
	local mb=Instance.new("TextButton") mb.Size=UDim2.fromOffset(28,28) mb.Position=UDim2.new(1,-68,0,10) mb.BackgroundColor3=_T.c2 mb.Text="–" mb.Font=Enum.Font.GothamBold mb.TextSize=16 mb.TextColor3=_T.sb mb.Parent=hd _cr(mb,7)
	local xb=Instance.new("TextButton") xb.Size=UDim2.fromOffset(28,28) xb.Position=UDim2.new(1,-36,0,10) xb.BackgroundColor3=_T.c2 xb.Text="✕" xb.Font=Enum.Font.GothamBold xb.TextSize=14 xb.TextColor3=_T.sb xb.Parent=hd _cr(xb,7)
	-- drag
	do local dr,ds,sp
		hd.InputBegan:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dr=true ds=_U:GetMouseLocation() sp=rt.Position end end)
		_U.InputEnded:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dr=false end end)
		_co.dg=_R.RenderStepped:Connect(function() if dr then local m=_U:GetMouseLocation() rt.Position=UDim2.fromOffset(sp.X.Offset+(m.X-ds.X),sp.Y.Offset+(m.Y-ds.Y)) end end)
	end
	-- body (2 columns)
	local bd=Instance.new("Frame") bd.BackgroundTransparency=1 bd.Position=UDim2.fromOffset(0,54) bd.Size=UDim2.new(1,0,1,-54) bd.Parent=rt
	local function mkCol(x) local c=Instance.new("Frame") c.BackgroundTransparency=1 c.Size=UDim2.new(0.5,-18,1,-10) c.Position=UDim2.fromOffset(x,4) c.Parent=bd local l=Instance.new("UIListLayout") l.Padding=UDim.new(0,8) l.SortOrder=Enum.SortOrder.LayoutOrder l.Parent=c return c end
	local cL=mkCol(12) local cR=mkCol(12+290-4)
	local od=0
	local function crd(pr,h) od+=1 local c=Instance.new("Frame") c.Size=UDim2.new(1,0,0,h) c.BackgroundColor3=_T.cd c.BorderSizePixel=0 c.LayoutOrder=od c.Parent=pr _cr(c,10) _st(c,_T.sk,1) return c end
	local function sct(p,t,cl) local l=Instance.new("TextLabel") l.BackgroundTransparency=1 l.Position=UDim2.fromOffset(10,7) l.Size=UDim2.new(1,-20,0,14) l.Font=Enum.Font.GothamBold l.TextSize=10 l.TextColor3=cl or _T.a2 l.TextXAlignment=Enum.TextXAlignment.Left l.Text=t l.Parent=p end
	local function stl(p,y) local s=Instance.new("TextLabel") s.BackgroundTransparency=1 s.Position=UDim2.fromOffset(10,y) s.Size=UDim2.new(1,-20,0,13) s.Font=Enum.Font.Gotham s.TextSize=9 s.TextColor3=_T.sb s.TextXAlignment=Enum.TextXAlignment.Left s.TextTruncate=Enum.TextTruncate.AtEnd s.Text="idle" s.Parent=p return s end
	local function tgl(p,y,lb,gt,st) local b=Instance.new("TextButton") b.Size=UDim2.new(1,-20,0,30) b.Position=UDim2.fromOffset(10,y) b.BackgroundColor3=_T.of b.AutoButtonColor=false b.Text="" b.Parent=p _cr(b,7)
		local l=Instance.new("TextLabel") l.BackgroundTransparency=1 l.Position=UDim2.fromOffset(8,0) l.Size=UDim2.new(1,-60,1,0) l.Font=Enum.Font.GothamMedium l.TextSize=11 l.TextColor3=_T.tx l.TextXAlignment=Enum.TextXAlignment.Left l.Text=lb l.Parent=b
		local tr=Instance.new("Frame") tr.Size=UDim2.fromOffset(34,18) tr.Position=UDim2.new(1,-42,0.5,-9) tr.BackgroundColor3=_T.c2 tr.BorderSizePixel=0 tr.Parent=b _cr(tr,9)
		local kn=Instance.new("Frame") kn.Size=UDim2.fromOffset(12,12) kn.Position=UDim2.fromOffset(3,3) kn.BackgroundColor3=_T.sb kn.BorderSizePixel=0 kn.Parent=tr _cr(kn,6)
		local function rf() local on=gt() tr.BackgroundColor3=on and _T.ac or _T.c2 kn.BackgroundColor3=on and Color3.new(1,1,1) or _T.sb kn:TweenPosition(on and UDim2.fromOffset(19,3) or UDim2.fromOffset(3,3),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.1,true) b.BackgroundColor3=on and _T.ad or _T.of end
		b.MouseButton1Click:Connect(function() if not _s.gp then return end st(not gt()) rf() end) rf() return rf end
	local function nf(p,y,w,lb,gt,st) local l=Instance.new("TextLabel") l.BackgroundTransparency=1 l.Position=UDim2.fromOffset(10,y) l.Size=UDim2.new(w,-10,0,24) l.Font=Enum.Font.GothamMedium l.TextSize=11 l.TextColor3=_T.tx l.TextXAlignment=Enum.TextXAlignment.Left l.Text=lb l.Parent=p
		local bx=Instance.new("TextBox") bx.Position=UDim2.new(w,0,0,y) bx.Size=UDim2.new(1-w,-10,0,24) bx.BackgroundColor3=_T.c2 bx.Font=Enum.Font.GothamMedium bx.TextSize=11 bx.TextColor3=_T.tx bx.Text=tostring(gt()) bx.ClearTextOnFocus=false bx.Parent=p _cr(bx,6)
		bx.FocusLost:Connect(function() local n=tonumber(bx.Text) if n and n>0 then st(n) else bx.Text=tostring(gt()) end end) end
	local function dd(p,y,opts,gt,st) local d=Instance.new("TextButton") d.Position=UDim2.fromOffset(10,y) d.Size=UDim2.new(1,-20,0,24) d.BackgroundColor3=_T.c2 d.Font=Enum.Font.GothamMedium d.TextSize=11 d.TextColor3=_T.tx d.TextXAlignment=Enum.TextXAlignment.Left d.Text="  "..gt() d.Parent=p _cr(d,6)
		local cv=Instance.new("TextLabel") cv.BackgroundTransparency=1 cv.Position=UDim2.new(1,-20,0,0) cv.Size=UDim2.fromOffset(18,24) cv.Font=Enum.Font.GothamBold cv.TextSize=10 cv.TextColor3=_T.sb cv.Text="▼" cv.Parent=d
		local ls=Instance.new("ScrollingFrame") ls.Position=UDim2.fromOffset(10,y+26) ls.Size=UDim2.new(1,-20,0,math.min(#opts,6)*22) ls.BackgroundColor3=_T.bg ls.BorderSizePixel=0 ls.ScrollBarThickness=3 ls.ScrollBarImageColor3=_T.sk ls.CanvasSize=UDim2.fromOffset(0,#opts*22) ls.Visible=false ls.ZIndex=30 ls.Parent=p _cr(ls,6) _st(ls,_T.sk,1)
		local ll=Instance.new("UIListLayout") ll.Parent=ls
		for _,op in ipairs(opts) do local o=Instance.new("TextButton") o.Size=UDim2.new(1,0,0,22) o.BackgroundColor3=_T.bg o.AutoButtonColor=true o.Font=Enum.Font.Gotham o.TextSize=10 o.TextColor3=_T.tx o.Text=op o.ZIndex=31 o.Parent=ls o.MouseButton1Click:Connect(function() st(op) d.Text="  "..op ls.Visible=false end) end
		d.MouseButton1Click:Connect(function() ls.Visible=not ls.Visible end) end
	-- left: stats + clean + calories + shaker
	local sc=crd(cL,44) sct(sc,"LIVE STATS")
	local function chp(x,n) local f=Instance.new("Frame") f.Size=UDim2.new(0.5,-14,0,28) f.Position=UDim2.fromOffset(x,14) f.BackgroundColor3=_T.c2 f.BorderSizePixel=0 f.Parent=sc _cr(f,6)
		local nl=Instance.new("TextLabel") nl.BackgroundTransparency=1 nl.Position=UDim2.fromOffset(6,2) nl.Size=UDim2.new(1,-12,0,10) nl.Font=Enum.Font.Gotham nl.TextSize=8 nl.TextColor3=_T.sb nl.TextXAlignment=Enum.TextXAlignment.Left nl.Text=n nl.Parent=f
		local vl=Instance.new("TextLabel") vl.BackgroundTransparency=1 vl.Position=UDim2.fromOffset(6,12) vl.Size=UDim2.new(1,-12,0,13) vl.Font=Enum.Font.GothamBold vl.TextSize=12 vl.TextColor3=_T.tx vl.TextXAlignment=Enum.TextXAlignment.Left vl.Text="—" vl.Parent=f return vl end
	local vc=chp(10,"CAL") local vs=chp(10+(580/2-18)/2,"STAM")
	local c1=crd(cL,68) sct(c1,"AUTO-CLEAN") tgl(c1,24,"Collect trash",function() return _s.cl end,function(v) _s.cl=v end) local s1=stl(c1,56)
	local c2=crd(cL,110) sct(c2,"AUTO-MAINTAIN CALORIES") nf(c2,24,0.5,"Threshold",function() return _s.th end,function(v) _s.th=math.floor(v) end) tgl(c2,52,"Keep calories up",function() return _s.ca end,function(v) _s.ca=v end) local s2=stl(c2,84)
	local c5=crd(cL,68) sct(c5,"AUTO-SHAKER",_T.am) tgl(c5,24,"Keep buff active",function() return _s.sh end,function(v) _s.sh=v end) local s5=stl(c5,56)
	-- right: calisthenics
	local c3=crd(cR,300) sct(c3,"AUTO-CALISTHENICS")
	dd(c3,24,_C.ex,function() return _s.ex end,function(v) _s.ex=v _lcs=0 end)
	nf(c3,54,0.6,"Rest (s)",function() return _s.rt end,function(v) _s.rt=math.floor(v) end)
	tgl(c3,84,"Auto-solve + reps",function() return _s.cs end,function(v) _s.cs=v end)
	local s3=stl(c3,116)
	local hn=Instance.new("TextLabel") hn.BackgroundTransparency=1 hn.Position=UDim2.fromOffset(10,134) hn.Size=UDim2.new(1,-20,0,60) hn.Font=Enum.Font.Gotham hn.TextSize=9 hn.TextColor3=_T.sb hn.TextWrapped=true hn.TextXAlignment=Enum.TextXAlignment.Left hn.TextYAlignment=Enum.TextYAlignment.Top hn.Text="Reps a set until stamina is low → leaves exercise → rests (stamina regens) → repeats.\nBalance minigame is auto-solved (cursor pinned to center).\nAuto-Shaker only drinks during rest windows." hn.Parent=c3
	-- minimize/restore
	local function sm(m) rt.Visible=not m _rb.Visible=m if m then _rb.Position=rt.Position end end
	mb.MouseButton1Click:Connect(function() sm(true) end) xb.MouseButton1Click:Connect(function() sm(true) end) _rb.MouseButton1Click:Connect(function() sm(false) end)
	do local dr,ds,sp _rb.InputBegan:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dr=true ds=_U:GetMouseLocation() sp=_rb.Position end end)
		_U.InputEnded:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseButton1 or io.UserInputType==Enum.UserInputType.Touch then dr=false end end)
		_co.cm=_R.RenderStepped:Connect(function() if dr then local m=_U:GetMouseLocation() _rb.Position=UDim2.fromOffset(sp.X.Offset+(m.X-ds.X),sp.Y.Offset+(m.Y-ds.Y)) end end) end
	-- render loop
	_co.rl=_R.RenderStepped:Connect(function() s1.Text=_s.st.cl s2.Text=_s.st.ca s3.Text=_s.st.cs s5.Text=_s.st.sh
		s1.TextColor3=_s.cl and _T.ac or _T.sb s2.TextColor3=_s.ca and _T.ac or _T.sb s3.TextColor3=_s.cs and _T.ac or _T.sb s5.TextColor3=_s.sh and _T.am or _T.sb
		gd2.BackgroundColor3=_s.gp and _T.ac or _T.dn
		local c=_gs("Calories") local st=_gs("Stamina") vc.Text=c and tostring(math.floor(c)) or "—" vs.Text=st and string.format("%.0f",st) or "—" end)
	return g
end
_G._ua.x=function() _s.cl,_s.ca,_s.cs,_s.sh=false,false,false,false _G._ua=nil for _,c in pairs(_co) do pcall(function() c:Disconnect() end) end if _gui then pcall(function() _gui:Destroy() end) end end
_cgp() _build()
