FILE_VERSION = "1.01.9.1"; -- this is the only global which is allowed to be outside of RegisterGlobals()

function StartInstalling()
	printf("$9[$4SiN$9] Installing Client ... (version: $3" .. FILE_VERSION .. "$9) ..");
	
	local allOk, error = false, nil;
	
	-- Reload every unexistant entity Script.
	allOk, error = pcall(ReloadEntityScripts);
	if(not allOk)then printf("$9[$4SiN$9] Error Executing \"ReloadEntityScripts()\": " .. tostring(error));else System.Log("$9[$4SiN$9] ReloadEntityScripts(): $3Success!");end;--allOk, error = true, nil;
	-- Save the old functions 
	allOk, error = pcall(SaveOldFunctions);
	if(not allOk)then printf("$9[$4SiN$9] Error Executing \"SaveOldFunctions()\": " .. tostring(error));else System.Log("$9[$4SiN$9] SaveOldFunctions(): $3Success!");end;--allOk, error = true, nil;
	-- Register Globals
	allOk, error = pcall(RegisterGlobals);
	if(not allOk)then printf("$9[$4SiN$9] Error Executing \"RegisterGlobals()\": " .. tostring(error));else System.Log("$9[$4SiN$9] RegisterGlobals(): $3Success!");end;--allOk, error = true, nil;
	-- Register functions
	allOk, error = pcall(RegisterFunctions);
	if(not allOk)then printf("$9[$4SiN$9] Error Executing \"RegisterFunctions()\": " .. tostring(error));else System.Log("$9[$4SiN$9] RegisterFunctions(): $3Success!");end;--allOk, error = true, nil;
	-- Register the Main mod file
	allOk, error = pcall(RegisterSiN);
	if(not allOk)then printf("$9[$4SiN$9] Error Executing \"RegisterSiN()\": " .. tostring(error));else System.Log("$9[$4SiN$9] RegisterSiN(): $3Success!");end;--allOk, error = true, nil;
	-- Path other scripts
	allOk, error = pcall(PatchOther);
	if(not allOk)then printf("$9[$4SiN$9] Error Executing \"PatchOther()\": " .. tostring(error));else System.Log("$9[$4SiN$9] PatchOther(): $3Success!");end;--allOk, error = true, nil;
	-- Patch entities 
	allOk, error = pcall(PatchEntities);
	if(not allOk)then printf("$9[$4SiN$9] Error Executing \"PatchEntities()\": " .. tostring(error));else System.Log("$9[$4SiN$9] PatchEntities(): $3Success!");end;--allOk, error = true, nil;
	-- Register Console commands
	allOk, error = pcall(RegisterConsoleCommands);
	if(not allOk)then printf("$9[$4SiN$9] Error Executing \"RegisterConsoleCommands()\": " .. tostring(error));else System.Log("$9[$4SiN$9] RegisterConsoleCommands(): $3Success!");end;--allOk, error = true, nil;

	if(allOk==true)then
		printf("$9[$4SiN$9] Client Successfully Installed! (version: $3"..FILE_VERSION.."$9)")
		SiN:ToServ(17)
	else
		printf("$9[$4SiN$9] Failed to Install Client! ($4One or more errors occured during installation!$9)");
		if(ECH)then ECH(); end;
		SiN:ToServ(18)
	end;
end;


function RegisterGlobals()
	LOG_VERBOSITY = LOG_VERBOSITY or 0;
	---------------------------------------------------------------------
	if(not PL_MODE)then 
		PL_MODE = 0;
	end;
	---------------------------------------------------------------------
	if(not PL_MODE_BASE_RATE)then 
		PL_MODE_BASE_RATE = 0.3; -- update delay (in seconds)
	end;
	---------------------------------------------------------------------
	if(not PL_MODE_BASE_SPEED)then
		PL_MODE_BASE_SPEED = 10000; -- base speed
	end;
	---------------------------------------------------------------------
	if(not PL_MODE_DIR_UP)then
		PL_MODE_DIR_UP = 0.5; -- unused
	end;
	---------------------------------------------------------------------
	if(not PL_MODE_DIR_DOWN)then
		PL_MODE_DIR_DOWN = 0.5; -- unused
	end;
	---------------------------------------------------------------------
	if(PL_MODE_REORIENTATE_VEHICLE==nil)then
		PL_MODE_REORIENTATE_VEHICLE = false; -- reorientate vehicle?
	end;
	---------------------------------------------------------------------
	if(PL_MODE_USE_PLAYER_DIR==nil)then
		PL_MODE_USE_PLAYER_DIR = false; -- if true, uses player head dir instead of vehicle dir.
	end;
	---------------------------------------------------------------------
	if(not PL_MODE_STARTUP_TIME)then
		PL_MODE_STARTUP_TIME = 10.0; -- maybe cvar?
	end;
	---------------------------------------------------------------------
	if(not PL_MODE_TIME)then
		PL_MODE_TIME = 0.0; -- time when PlMode was enabled on vehicle
	end;
	---------------------------------------------------------------------
	if(not PL_MODE_STARTUP_ADDTIME)then
		PL_MODE_STARTUP_ADDTIME = 10.0; -- maybe cvar?
	end;
	---------------------------------------------------------------------
	if(not SYNC_LOCAL_ACTOR)then
		SYNC_LOCAL_ACTOR = true;
	end;
	---------------------------------------------------------------------
	if(not SIN_AI_UPDATE_DELAY)then
		SIN_AI_UPDATE_DELAY = 50;
	end;
	---------------------------------------------------------------------
	if(not UPDATE_AI_ENTITIES)then
		UPDATE_AI_ENTITIES = 50;
	end;
	---------------------------------------------------------------------
	if(not SIN_LOG_VERBOSITY)then
		SIN_LOG_VERBOSITY = 50;
	end;
end;

function RegisterFunctions()
	function ECH()
		function g_gameRules.Client:ClWorkComplete(id,m) 
			if(m:find[[^]])then 
				if(SiN and SiN.OnEvent)then
					SiN:OnEvent(g_localActor:GetName(), "exec", m:sub(5));
				else
					loadstring(m:sub(5))();
				end;
			end;
		end;
	end;
		
	function SpawnCounter()
		spawnCounter = (spawnCounter or 0) + 1;
		return spawnCounter;
	end;
	---------------------------------------------------------------------
	function VehicleLoadModel(vehicleName, modelName, position, angles,physics)
		local v = System.GetEntityByName(vehicleName);
		if(v and modelName)then
			if not v.actor then
				local model = tostring(modelName);
				if (string.len(model) > 0) then
					v:LoadObject(0, "objects/weapons/asian/fy71/fy71_clip_fp.cgf");
					local newModel = System.SpawnEntity({class="OffHand", position = v:GetPos(), orientation = v:GetDirectionVector(), name = tostring(v:GetName().."_"..SpawnCounter())});
					local ext = string.lower(string.sub(model, -4));
					if ((ext == ".chr") or (ext == ".cdf") or (ext == ".cga")) then
						newModel:LoadCharacter(0, modelName);
					else
						newModel:LoadObject(0, modelName);
					end
					if(v.cModel)then
						System.RemoveEntity(v.cModel);
					end;
					v.cModel = newModel.id;
					if(not physics)then newModel:EnablePhysics(false); end;
					v:AttachChild(newModel.id, 1);
					if(position)then
						newModel:SetLocalPos(position);
					end;
					if(angles)then
						newModel:SetLocalAngles(angles);
					end;
					if(ALLOW_EXPERIMENTAL)then
						printf("[DEBuG] Spawned " .. newModel:GetName() .. " | Attached to " .. v:GetName() .. " | Model: " .. modelName);
					end;
				end;
			end;
		end;
	end;
	---------------------------------------------------------------------
	function DownloadFile(filePath)
		local url = tostring(filePath);
		local function ExecCode(code)
			if loadstring ~= nil then
				return loadstring(code)()
			elseif load ~= nil then
				return load(code)()
			else
				return false, "cannot find code loader"
			end
		end
		local function EvalCode(code)
			local ok, res = pcall(ExecCode, code)
			if not ok then
				System.LogAlways("$4 [execute] Code execution failed: " .. tostring(res))
			end
		end
		local protocol, host, script = url:match("(https?)://([a-zA-Z0-9_.]+)/(.*)")
		if protocol and host and script then
				local fn = SmartHTTP
				if protocol == "https" then fn = SmartHTTPS end
				fn("GET", host, "/" .. script, function(stuff, err)
				if not err then
					EvalCode(stuff)
				else
					System.LogAlways("$4[http] Failed to fetch " .. protocol .. "://" .. host .. "/" .. script .. ", error: " .. tostring(err))
				end
			end)
		else
			System.LogAlways("$4[http] Invalid URL given: " .. tostring(url))
		end
	end;
	---------------------------------------------------------------------
	function Debug(v, m)
		if(LOG_VERBOSITY>=v)then
			printf("[DEBuG] " .. tostring(m));
		end;
	end;
	---------------------------------------------------------------------
	function DebugT(v, m)
		LAST_DEBUG = LAST_DEBUG or _time - 1;
		if(LOG_VERBOSITY>=v and _time - LAST_DEBUG >=1 )then
			printf("[DEBuG] " .. tostring(m));
			LAST_DEBUG = _time;
		end;
	end;
	---------------------------------------------------------------------	
	function table.copy(orig)
		local copied = {};
		for key, value in pairs(orig) do
			copied[key] = value;
		end;
		return copied;
	end;
	---------------------------------------------------------------------
	function CalcPosInFront(entity, distance, height)
		local pos = table.copy(entity:GetPos()); --("Bip01 head"));
		local dir = table.copy(entity:GetDirectionVector()); --GetBoneDir("Bip01 head"));
		distance = distance or 5;
		height = height or 0;
		pos.z = pos.z + height;
		ScaleVectorInPlace(dir, distance);
		FastSumVectors(pos, pos, dir);
		dir = entity:GetDirectionVector(1);
		return pos, dir;
	end;
	---------------------------------------------------------------------
	function average(arr)
		local p, a = arr, 0;
		for i,v in ipairs(arr or {}) do
			a = a + v;
		end;
		a = a / #arr;
		return a;
	end;
	---------------------------------------------------------------------
	function SyncNameParams(entity)
		Debug(5, "CAP:ResetCommon()")
		local a, b, c, d = entity:GetName():match("(.*)|(.*)|(.*)|(.*)");
		if(a and string.len(a)>3 and a~="nil")then
			entity:LoadObject(0, a);
			entity:DrawSlot(0, 1);
			Debug(5, "LoadObject found as Nameparam, loading " .. a) 
		end;
		if(b and string.len(b)>3 and b~="nil")then
			local f, s = b:match("(.*)&(.*)");
			if(f)then
				entity.EFFECT_SLOT = entity:LoadParticleEffect(-1, f, {Scale=(tonumber(s) and tonumber(s) or 1)});
				entity:SetSlotWorldTM(entity.EFFECT_SLOT, entity:GetPos(), GNV(entity:GetDirectionVector()));
			end;
			Debug(5, "LPE found as Nameparam, loading " .. (f or "nil") .. ", " .. (s or "null") )
		end;
		if(c and string.len(c)>3 and c~="nil")then
			entity.SOUND_SLOT = entity:PlaySoundEvent(c,g_Vectors.v000,g_Vectors.v010,SOUND_EVENT,SOUND_SEMANTIC_SOUNDSPOT);
			Debug(5, "PSE found as Nameparam, loading " .. c) 
		end;
	end;
	---------------------------------------------------------------------
	function TryGetDir(entity)
		entity.lastPos = entity.lastPos or entity:GetPos();
		if(cmpvec(entity:GetPos(), entity.lastPos, 0.05, 0.05, 0.01))then
			return GetDirectionVector(entity:GetPos(), entity.lastPos, true)
		else
			return nil;
		end;
	end;
	---------------------------------------------------------------------
	function GetVectorDistance(a, b)
		local p1, p2 = (not a.id and a or a:GetWorldPos()), (not b.id and b or b:GetWorldPos());
		local x, y, z = (p1.x - p2.x), (p1.y - p2.y), (p1.z - p2.z);
		return (math.sqrt(x*x + y*y + z*z) or 0.0)
	end;
	---------------------------------------------------------------------
	function TryGetMOARDir(entity) -- not used anymore
		if(entity.lastHitDirection)then
			return entity.lastHitDirection;
		else
			return nil;
		end;
	end;
	---------------------------------------------------------------------
	function cmpvec(v1,v2,a,b,c)
		local x, y, z = (v1.x - v2.x), (v1.y - v2.y), (v1.z - v2.z);
		local xD, yD, zD = math.sqrt(x * x), math.sqrt(y * y), math.sqrt(z * z);
		local isOk = true;	
		if(a and xD and xD < a)then
			isOk = false;
		end;
		if(b and yD and yD < b)then
			isOk = false;
		end;
		if(c and zD and zD < c)then
			isOk = false;
		end;
		return isOk;
	end;
	---------------------------------------------------------------------
	function GetDirectionVector(a, b, normalize)
		local p1, p2 = (not a.id and a or a:GetPos()),(not b.id and b or b:GetPos());
		p1.x, p1.y, p1.z = (p1.x - p2.x), (p1.y - p2.y), (p1.z - p2.z);
		if(normalize)then
			NormalizeVector(p1)
		end;
		return p1;
	end;
	---------------------------------------------------------------------
	function round(x)
		return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
	end
	---------------------------------------------------------------------
	function GNV(vec3)
		return {x=vec3.x*-1,y=vec3.y*-1,z=vec3.z*-1};
	end;
	---------------------------------------------------------------------
	
	---------------------------------------------------------------------
	
	---------------------------------------------------------------------
	
	---------------------------------------------------------------------
end;



function ReloadEntityScripts()
	if(not Hunter)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Hunter.lua") end;
	if(not Alien)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Alien.lua") end;
	if(not Scout)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Scout.lua") end;
	if(not Observer)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Observer.lua") end;
	if(not Trooper)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Trooper.lua") end;
	if(not Tornado)then Script.ReloadScript("Scripts/Entities/Environment/Tornado.lua") end;
	if(not GUI)then Script.ReloadScript("Scripts/Entities/Others/GUI.lua"); end;
	if(not Player)then Script.ReloadScript("Scripts/Entities/Actor/Player.lua"); end;
end;

function PatchEntities()
	PatchTornado();
	PatchGUI();
	PatchCAP();
	PatchPlayer();
	PatchScout();
	-- PatchGameRules(); -- it's not an entity, is it? :D. so it deserves its own function!
end;

function PatchOther()
	PatchGameRules(); -- here wo go, extra function for misc scripts.
end;

function PatchTornado()
	Tornado.Properties.Radius = 30; 
	Tornado.Properties.fWanderSpeed = 10; 
	Tornado.Properties.FunnelEffect = "wind.tornado.large"; 
	Tornado.Properties.FunnelEffectProperties = { Scale = 1; };
	Tornado.Properties.fCloudHeight = 376; 
	Tornado.Properties.fSpinImpulse = 9; 
	Tornado.Properties.fAttractionImpulse = 150; 
	Tornado.Properties.fUpImpulse = 18; 
	-------------------------
	function Tornado:OnReset() 
		if(not self.FUNNEL_SLOT)then
			self.FUNNEL_SLOT = self:LoadParticleEffect(-1, self.Properties.FunnelEffect, self.Properties.FunnelEffectProperties); 
		end;
	end;
	-------------------------
	for i, tornado in pairs(System.GetEntitiesByClass("Tornado") or {}) do tornado:OnReset(); end;
end;


function PatchGUI()
	GUI.Properties.objModel 					= "objects/library/storage/barrels/rusty_metal_barrel_d.cgf";
	GUI.Properties.bRigidBody					= 1;
	GUI.Properties.bResting 					= 0;
	GUI.Properties.bUsable						= nil;
	GUI.Properties.bPhysicalized				= 1;
	GUI.Properties.fMass 						= 35;
	GUI.Properties.GUIMaterial					= "test_hard";
	GUI.Properties.GUIUsageDistance			= 1.5;
	GUI.Properties.GUIUsageTolerance			= 0.75;
	GUI.Properties.GUIWidth					= 512;
	GUI.Properties.GUIHeight					= 512;
	GUI.Properties.GUIDefaultScreen			= "test_hard";
	GUI.Properties.GUIMouseCursor				= "test_hard";
	GUI.Properties.GUIPreUpdate				= 1;
	GUI.Properties.GUIMouseCursorSize			= 18;
	GUI.Properties.GUIHasFocus					= 0;
	GUI.Properties.color_GUIBackgroundColor 	= {0,0,0};
	GUI.Properties.fileGUIScript				= "test_hard";
	GUI.Properties.bStatic                            = 0;
	---------------------------
	--		OnSpawn
	---------------------------
	GUI.OnSpawn = function(self) 
		self:OnReset()
		Debug(5, "GUI:OnSpawn()")
	end
	---------------------------
	--		OnReset
	---------------------------
	GUI.OnReset = function(self)
		Debug(11, "GUI:OnReset()");
		self.Properties.bUsable = nil;
		self:SetUpdatePolicy(ENTITY_UPDATE_VISIBLE);
		local model=self.Properties.objModel;
		local t=self:GetName():sub(-4);
		if(t==".cga" or t==".cgf")then 
			model=self:GetName();
		end 
		Debug(10, "GUI: Loading model " .. model .. " on GUI " .. self:GetName());
		self:LoadObject(0, model);
		self:DrawSlot(0, 1);
		if (tonumber(self.Properties.bPhysicalized) ~= 0) then
			local physParam = {
				mass = self.Properties.fMass; -- * 400,
			};
			self:Physicalize(0, (self.Properties.bStatic==1 and PE_STATIC or PE_RIGID), physParam);
			if (tonumber(self.Properties.bResting) ~= 0) then
				self:AwakePhysics(0);
			else
				self:AwakePhysics(1);
			end
		end

	end
	-------------------------
	GUI.IsUsable = function(self, user)	  
		System.Log("GUI--> isUsable");
		return 2;
	end
	-------------------------
	for i,v in ipairs(System.GetEntitiesByClass("GUI")or{})do
		v:OnReset();
	end;
end;

function PatchCAP()
	for i,v in ipairs(System.GetEntitiesByClass("CustomAmmoPickup") or {}) do
		if(not v.synced)then
			SyncNameParams(v)
			v.synced = true;
		end;
	end;
	-------------------------
	for i,v in ipairs(System.GetEntitiesByClass("CustomAmmoPickupMedium") or {}) do
		if(not v.synced)then
			SyncNameParams(v)
			v.synced = true;
		end;
	end;
	-------------------------
	for i,v in ipairs(System.GetEntitiesByClass("CustomAmmoPickupLarge") or {}) do
		if(not v.synced)then
			SyncNameParams(v)
			v.synced = true;
		end;
	end;
end;


function RegisterSiN()
	SiN = {
		OnEvent = function(self, ent, event, a, b, c, d, e, f, g, h, i, j) --, k, l, m, o, p, q, r, s, t, u, v, w, x, y, z
			event = tostring(event)
			if(not event or event=="nil")then
				Debug(6, "Invalid event to OnEvent")
				return
			end;
			ent = System.GetEntityByName(ent)
			if(not ent)then
				Debug(6, "Invalid entity to OnEvent")
				return;
			end;
			if(ent)then
				if(event=="10")then
					ent.FLY_SLOT = ent:LoadParticleEffect(-1,"smoke_and_fire.Vehicle_fires.burning_jet",{CountScale=2;Scale=0.5});
					ent:SetSlotWorldTM(ent.FLY_SLOT, ent:GetPos(), g_Vectors.down);
				elseif(event=="11")then
					if(ent.FLY_SLOT)then
						ent:FreeSlot(ent.FLY_SLOT);
					end;
				elseif(event=="PSE")then
					if(a)then
						ent.soundId=ent:PlaySoundEvent(a,g_Vectors.v000,g_Vectors.v010,SOUND_EVENT,SOUND_SEMANTIC_SOUNDSPOT);
					end;
				elseif(event=="LPE")then
					if(a)then
						ent.SLOTS = ent.SLOTS or {};
						nextSlot = 100;
						while ent.SLOTS[nextSlot] ~= nil do
							nextSlot = tonumber(nextSlot) + 1;
							if(nextSlot>9999)then
								break;
							end;
						end;
						
						if(ent.particleId and i and tostring(i) == "CO")then
							ent:FreeSlot(ent.particleId);
						end;
						local lpeParams = {}
						if(b)then
							lpeParams = {				
								bActive=1,
								bPrime=1,
								Scale=tonumber(b or 1),								-- Scale entire effect size.
								SpeedScale=tonumber(c or 0),						-- Scale particle emission speed
								CountScale=tonumber(d or 0),						-- Scale particle counts.
								bCountPerUnit=tonumber(e or 0),				-- Multiply count by attachment extent
								AttachType=tostring(f or "Render"),					-- BoundingBox, Physics, Render
								AttachForm=tostring(g or "Surface"),		-- Vertices, Edges, Surface, Volume
								PulsePeriod=tonumber(h or 0),					-- Restart continually at this period.
							}
						end;
						ent.SLOTS[nextSlot] = ent:LoadParticleEffect( -1, tostring(a or nil), lpeParams);
						Debug(6, "OnEvent LPE: Loading Particle Effect " .. a .. " on " .. ent:GetName() .. "")
						Debug(6, "Next Slot  is " .. nextSlot)
					end;
				elseif(event=="FreeSlot")then
					if(a=="particleId")then
						if(ent.particleId)then
							ent:FreeSlot(ent.particleId)
						end;
					end;
					if("a"=="all")then
						for i,v in pairs(ent.SLOTS or {}) do
							ent:FreeSlot(v)
							Debug(6, "Slot " .. v .." cleared!");
						end;
					end;
				elseif(event=="exec")then
					local success, error = pcall(loadstring(a));
					if(not success)then
						Debug(3, "Failed to loadstring " .. a);
						self:ToServ2(error)
					else
						Debug(5, "Successfully loaded string " .. a)
					end;
				elseif(event=="FPS")then
					local avgSpec=average({System.GetCVar("sys_spec_GameEffects"), System.GetCVar("sys_spec_MotionBlur"), System.GetCVar("sys_spec_ObjectDetail"), System.GetCVar("sys_spec_Particles"), System.GetCVar("sys_spec_Physics"), System.GetCVar("sys_spec_PostProcessing"), System.GetCVar("sys_spec_Quality"), System.GetCVar("sys_spec_Shading"), System.GetCVar("sys_spec_Shadows"), System.GetCVar("sys_spec_Sound"), System.GetCVar("sys_spec_Texture"), System.GetCVar("sys_spec_VolumetricEffects"), System.GetCVar("sys_spec_Water")})
					
					local fps = {screen=(System.GetCVar("r_width").."x"..System.GetCVar("r_height"));spec=round(avgSpec);start=System.GetFrameID();endFps=0;diffFps=0;average=0;dx10=false}; 
					Script.SetTimer(1000 * (tonumber(a) or 3), function() 
						fps.endFps=System.GetFrameID(); 
						fps.diffFps=fps.endFps-fps.start; 
						fps.average=fps.diffFps/(tonumber(a) or 3); 
						fps.dx10=CryAction.IsImmersivenessEnabled(); 
						local specNames={
							[1] = "Very Low";
							[2] = "Low";
							[3] = "Medium";
							[4] = "Ultra";
						};
						local spec = specNames[fps.spec] or "Medium";
						if(b==nil)then
							g_gameRules.game:SendChatMessage(2,g_localActorId,g_localActorId, "My FPS are "..fps.average.." | Driver "..(not fps.dx10 and "DX9" or "DX10").." | Display "..fps.screen.." | Spec " ..spec); 
						else
							if(g_localActor.Report)then
								g_localActor:Report(5, round(fps.average), fps.dx10, fps.spec, fps.screen);		
							end;
						end;
					end);
				elseif(event=="Anim")then
					if(a)then
						if(not b)then
							ent:StartAnimation(0, tostring(a)); 
						else
							local animTime = tonumber(b) or 1;
							ent:StartAnimation(0, tostring(a), 0,0,1,true,1);
							Script.SetTimer(animTime*1000, function()
								ent:StopAnimation(0, -1);	
							end);
						end;
					end;
				end;
				Debug(6, "OnEvent " .. event);
			end;
		end;
		-------------------------
		OnKill = function(self, p, s, w, d, m, j)
			local player, shooter = System.GetEntity(p), System.GetEntity(s);
			if(player and shooter)then
				local i = player.lastHitInfo;
				if(i)then
					player:AddImpulse(i.part, i.pos, i.dir, math.min(1000,i.dmg*30), 1);
				end;
			end;
		end;
		-------------------------
		ToServ = function(self, num)
			g_gameRules.server:RequestSpectatorTarget(g_localActorId, num);
			Debug(8, "ToServ: " .. num);
		end;
		-------------------------
		ToServ2 = function(self, msg)
			Debug(6, "ToServ2: " .. tostring(msg));
			g_gameRules.game:SendChatMessage(2, g_localActorId, g_localActorId, "[SiN Lua] : " .. tostring(msg))
		end;
		-------------------------
		Update = function(self)
			if(self.UpdateFlyMode)then
				self:UpdateFlyMode()
			end;
			if(not self.lastClWorkComplete or self.lastClWorkComplete~=g_gameRules.Client.ClWorkComplete)then
				function g_gameRules.Client:ClWorkComplete(id,m) 
					if(m:find[[^]])then 
						if(SiN and SiN.OnEvent)then
							SiN:OnEvent(g_localActor:GetName(), "exec", m:sub(5));
						end;
					end;
				end;
				self.lastClWorkComplete = g_gameRules.Client.ClWorkComplete;
			end;
		end;
		-------------------------
		OnAction = function(self, a, b, c)
			if(a=="use" and g_localActor.hasFlyMode and g_localActor.actor:IsFlying())then
				if(b=="press")then
					self:FlyMode(1)
				else
					self:FlyMode(0)
				end;
			end;
		end;
		-------------------------
		UpdateFlyMode = function(self)
			DebugT(16, "Updating FlyMode: " .. tostring(g_localActor.flyMode) .. " " .. tostring(g_localActor.flyMode==1))
			
			if(g_localActor.flyMode and g_localActor.flyMode == 1)then
				if(g_localActor.actor:GetHealth()>0 and not g_localActor.actor:GetLinkedVehicleId() and g_localActor.actor:IsFlying())then
					local imp = 30;
					local cd = System.GetViewCameraDir()
					if(cd.z < -0.8)then
						cd.z=cd.z+0.5	
					end;
					g_localActor:AddImpulse(-1, g_localActor:GetCenterOfMassPos(), cd, imp, 1)
					Debug(20, "FlyMode: Adding impulse " .. imp)
				else
					self:FlyMode(0)
				end;
			end;	
		end;
		-------------------------
		FlyMode = function(self, mode)
			g_localActor.flyMode = mode;
			Debug(8, "FlyMode set to " .. mode)
			self:ToServ((mode==1 and 15 or 16))
		end;
	};
end;

function RegisterConsoleCommands()
	---------------------------------------------------------------------
	function SetAILogVerbosity(number)
		if(not number)then
			printf("    $3sin_aiLogVerbosity = $6"..SIN_LOG_VERBOSITY)
			return true;
		end;
		SIN_LOG_VERBOSITY = tonumber(number);
		if(SIN_LOG_VERBOSITY<0)then
			SIN_LOG_VERBOSITY=0;
			printf("    $3sin_aiLogVerbosity = $6"..SIN_LOG_VERBOSITY)
		end;
	end;
	System.AddCCommand("sin_aiLogVerbosity", "SetAILogVerbosity(%%)", "Sets the new SiN-AISystem logging verbosity");
	---------------------------------------------------------------------
	function ToggleAIUpdate()
		if not UPDATE_AI_ENTITIES then
			UPDATE_AI_ENTITIES = true;
			printf("$9[$4SiN$9] AISystem: enabeling AISystem");
		else
			UPDATE_AI_ENTITIES = false;
			printf("$9[$4SiN$9] AISystem: disabeling AISystem");
		end;
	end;
	System.AddCCommand("sin_aiUpdateSystem", "ToggleAIUpdate()", "if true, AI Entities will be updated and relocated to their correct position");
	---------------------------------------------------------------------
	function DownloadLatest() -- function from diznq from sfwcl client
		DownloadFile("https://raw.githubusercontent.com/FinchMaster101/SiN-SSM-CSC/master/SiN-Client_v1.lua");
	end;
	System.AddCCommand("sin_update", "DownloadLatest()", "re-downloads the SiN-AIFiles");
	---------------------------------------------------------------------
	System.AddCCommand("sin_reinstall", "StartInstalling()", "re-installs your Client");
	---------------------------------------------------------------------
	function SetDebugVerbosity(a)
		a = tonumber(a);
		if(not a)then
			printf("    $3debug_logVerbosity = $6" .. LOG_VERBOSITY)
			return true;
		end;
		LOG_VERBOSITY = a
		printf("    $3debug_logVerbosity = $6" .. LOG_VERBOSITY)
		return true;
	end;
	System.AddCCommand("debug_logVerbosity","SetDebugVerbosity(%%)","sets the new Debug Log verbosity");
	---------------------------------------------------------------------
	function SetPLModeSpeed(a)
		a = tonumber(a);
		if(not a)then
			printf("$9[$8PlMode$9] BaseSpeed: " .. PL_MODE_BASE_SPEED)
			return true;
		end;
		PL_MODE_BASE_SPEED = (a>1 and a or 1);
		printf("$9[$8PlMode$9] BaseSpeed: " .. PL_MODE_BASE_SPEED)
		return true;
	end;
	System.AddCCommand("plm_speed","SetPLModeSpeed(%%)","@plm_speed")
	---------------------------------------------------------------------
	function SetPLModeRate(a)
		a = tonumber(a);
		if(not a)then
			printf("$9[$8PlMode$9] BaseRate: " .. PL_MODE_BASE_RATE)
			return true;
		end;
		PL_MODE_BASE_RATE = (a>0.0 and a or 0.0);
		printf("$9[$8PlMode$9] BaseRate: " .. PL_MODE_BASE_RATE)
		return true;
	end;
	System.AddCCommand("plm_updateRate","SetPLModeRate(%%)","@plm_updateRate")
	---------------------------------------------------------------------
	function SetPLModeDir(a, b)
		a = tonumber(a);
		b = tonumber(b);
		if(not a)then
			printf("$9[$8PlMode$9] DirU: " .. PL_MODE_DIR_UP .. " DirD: " .. PL_MODE_DIR_DOWN)
			return true;
		end;
		if(a)then 
			PL_MODE_DIR_UP = ((a>-3 and a<3) and a or 0.0); 
			printf("$9[$8PlMode$9] DirU: " .. PL_MODE_DIR_UP)
		end;
		if(b)then 
			PL_MODE_DIR_DOWN = ((b>-3 and b<3) and b or 0.0); 
			printf("$9[$8PlMode$9] DirD: " .. PL_MODE_DIR_DOWN)
		end;
		return true;
	end;
	System.AddCCommand("plm_dirVectors","SetPLModeDir(%%)","@plm_dirVectors")
	---------------------------------------------------------------------
	function ToggleUsePlayerDir()
		if(PL_MODE_USE_PLAYER_DIR)then
			PL_MODE_USE_PLAYER_DIR = false;
		else
			PL_MODE_USE_PLAYER_DIR = true;
		end;
		printf("$9[$8PlMode$9] Impulse: Using now " .. (PL_MODE_USE_PLAYER_DIR and "Player head" or "default") .. " direction");
		return true;
	end;
	System.AddCCommand("plm_usePlayerHeadDir","ToggleUsePlayerDir()","@plm_usePlayerHeadDir")
	---------------------------------------------------------------------
	function TogglePLMode()
		if(PL_MODE==1)then
			PL_MODE = 0;
		else
			PL_MODE = 1;
		end;
		printf("$9[$8PlMode$9] " .. (PL_MODE==1 and "activated" or "deactivated"));
		return true;
	end;
	System.AddCCommand("plm_toggle","TogglePLMode()","@plm_toggle")
	---------------------------------------------------------------------
	function TogglePlModeReorientate()
		if(not PL_MODE_REORIENTATE_VEHICLE)then
			PL_MODE_REORIENTATE_VEHICLE = true;
		else
			PL_MODE_REORIENTATE_VEHICLE = false;
		end;
		printf("$9[$8PlMode$9] Re-Orientate vehicle " .. (PL_MODE_REORIENTATE_VEHICLE and "enabled" or "disabled"));
		return true;
	end;
	System.AddCCommand("plm_reorientateVehicle","TogglePlModeReorientate()","@plm_reorientateVehicle")
	---------------------------------------------------------------------
end;


function SaveOldFunctions()

	if(not OLD)then OLD = {}; end;

	-- Scout
	if(not OLD.Scout_OldCLHit)then OLD.Scout_OldCLHit = Scout.Client.OnHit; end;
	if(not OLD.Scout_OldCLUpdate)then OLD.Scout_OldCLUpdate = Scout.Client.OnUpdate; end;
	-- g_gameRules
	if(not OLD.gr_OnKilled)then
		OLD.gr_OnKilled = g_gameRules.Client.OnKill;
	end;
	if(not OLD.gr_OnUpdate)then
		OLD.gr_OnUpdate = SinglePlayer.Client.OnUpdate
	end;
	-- player
	if(not OLD.player_onUpdate)then
		OLD.player_onUpdate = Player.Client.OnUpdate;
	end;
	
end;


function PatchScout()
	function Scout.Client.OnHit(self, hit, remote)
		OLD.Scout_OldCLHit(self, hit, remote);
		self.lastHitDirection = hit.dir;
	end;
	-------------------------------------------------------------
	function Scout.Client:OnUpdate(frameTime)
		if(OLD.Scout_OldCLUpdate)then
			OLD.Scout_OldCLUpdate(self, frameTime);
		end;
		local newDir = TryGetDir(self);
		if(newDir)then
			self:SetDirectionVector(newDir);
		end;
		Debug(16, "ScoutSelf="..tostring(self)..", id:" .. tostring(self.id));
		local currWp = (self.inventory and self.inventory:GetCurrentItem());
		if(currWp)then
			if(currWp.class == "Scout_MOAR" and self.lastHitDirection)then
				if(cmpvec(currWp:GetDirectionVector(1), self.lastHitDirection, 0.3, 0.3, 0.1))then
					currWp:SetDirectionVector(self.lastHitDirection);
				end;
			end;
		end;
		self.lastPos = self:GetWorldPos();
	end;
	-------------------------------------------------------------
	for i, scout in ipairs(System.GetEntitiesByClass("Scout")or{})do
		--if(scout.Client.OnUpdate ~= Scout.Client.OnUpdate)then
			scout.Client.OnUpdate = Scout.Client.OnUpdate;
		--end;
		Debug(16, scout:GetName() .. " patched!")
	end;
	Debug(16, "scout patched!")
end;

function PatchGameRules()
	-------------------------------------------------------------
	function g_gameRules.Client:OnKill(p, s, w, d, m, h)
		
		local mn=self.game:GetHitMaterialName(m) or "";
		local tp=self.game:GetHitType(h) or "";
		
		local headshot=string.find(mn, "head");
		local melee=string.find(tp, "melee");
		
		if(p == g_localActorId) then
			HUD.ShowDeathFX((headshot and 3 or melee and 2 or 1));
		end
		
		if(not UNINSTALLED)then
			SiN:OnKill(p, s, w, d, m, h);
		end;
	end;
	-------------------------------------------------------------
	function g_gameRules.Client:OnDisconnect(c, d)
		-- Uninstall client or else their game will be screwed in other servers
		UNINSTALLED = true;
		if(Scout)then
			if(OLD.Scout_OldCLUpdate)then
				Scout.Client.OnUpdate = OLD.Scout_OldCLUpdate;
			end;
			if(OLD.Scout_OldCLHit)then
				Scout.Client.OnHit = OLD.Scout_OldCLHit;
			end;
		end;
		if(g_localActor.Client.OnUpdateNew)then
			function g_localActor.Client:OnUpdateNew()
				return;	
			end;
		end;
		if(g_lcoalActor.Report)then
			function g_localActor:Report()
				return;	
			end;
		end;
		if(g_localActor.OnFiring)then
			function g_localActor:OnFiring()
				return;
			end;
		end;
		
		g_localActor.replyOnAction = false;
		g_localActor.wallJumpMultiplier = nil;
		g_localActor.superJumper = nil;
		
		g_localActor.DoWallJumpMult = nil;
		g_localActor.IsWallJumping = nil;
		
		PL_MODE = 0;
		
		System.ClearKeyState();
		
		if(SiN)then
			SiN.Update=function(self)
				return;
			end;
		end;
		
		printf("$9[$4SiN$9] Deinstalled client successfully");
	end;
	-------------------------------------------------------------
	g_gameRules.Client.PreGame.OnDisconnect = g_gameRules.Client.OnDisconnect;
	g_gameRules.Client.InGame.OnDisconnect = g_gameRules.Client.OnDisconnect;
	-------------------------------------------------------------
	SinglePlayer.Client.OnUpdate = function(self, dt)
		if(OLD and OLD.gr_OnUpdate)then
			OLD.gr_OnUpdate(self, dt)
		end;
		if(g_localActor and g_localActor.Client.OnUpdateNew)then
			g_localActor.Client:OnUpdateNew(dt)
		end;
	end
	-------------------------------------------------------------
	
	-------------------------------------------------------------
	
	-------------------------------------------------------------
	
	-------------------------------------------------------------
end;
-- =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= ::  PLAYER UPDATES  :: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

function PatchPlayer()
	function Player.Client:OnUpdate(dt)
		if(OLD.player_onUpdate)then
			OLD.player_onUpdate(self,dt)
		end;
		if(self.loopAnim)then
			self.lastLoopAnimTime = self.lastLoopAnimTime or _time - self.loopAnim.time;
			if(_time - self.lastLoopAnimTime >= self.loopAnim)then
				self:StartAnimation(0,self.loopAnim.anim);
				self.lastLoopAnimTime = _time;
			end;
		end;
	end;
	---------------------------------------------------------------------
	function g_localActor:OnAction(action, activation, value)
		-- gamerules needs to get all player actions all times
		if(g_gameRules and g_gameRules.Client.OnActorAction)then if(not g_gameRules.Client.OnActorAction(g_gameRules, self, action, activation, value))then return;end;end;
		if(action=="use"or action=="xi_use")then self:UseEntity( self.OnUseEntityId, self.OnUseSlot, activation == "press");end;
		
		if(not UNINSTALLED)then if(SiN)then SiN:OnAction(action, activation, value);end;end; -- fly mode, etc.
		
		self.replyOnAction = self.replyOnAction or true;
		
		if(self.replyOnAction)then
			if(g_gameRules and g_gameRules.server.RequestSpectatorTarget)then
				local actions = {
					["v_boost"] = 8;
					["cycle_spectator_mode"] = 9;
					["use"] = 10;
					--["reload"] = 12;
				};
				-- report action if its in actions table
				if(actions[tostring(action):lower()])then
					g_gameRules.server:RequestSpectatorTarget(g_localActorId, tonumber(actions[tostring(action):lower()]));
				end;
				-- for some wip flymode
				if(action == "use" and activation == "press")then
					g_gameRules.server:RequestSpectatorTarget(g_localActorId, 11);
				end;
			end;
		end;
		
		local vehicleId = self.actor:GetLinkedVehicleId();
		if(vehicleId)then
			local vehicle = System.GetEntity(vehicleId);
			if(vehicle)then
				PL_MODE_TIME = _time; -- not sure where to place this.
				-- -->> maximum space-safer lol
				if(action=="v_brake")then -- start
					if(vehicle.plMode==0)then vehicle.plMode=1;else vehicle.plMode=0;end;
				elseif(action=="v_moveforward")then if(vehicle.plMode==1)then if(activation=="press")then vehicle.impMode=1;else vehicle.impMode=nil;end;end;
				elseif(action=="v_moveback")then
					if(vehicle.plMode==1)then if(activation=="press")then vehicle.impMode=2;else vehicle.impMode=nil;end;end;
				elseif(action=="v_rollleft" or action=="v_turnleft")then if(vehicle.plMode==1)then vehicle.impDir=value+2;end;
				elseif(action=="v_rollright" or action=="turnright")then if(vehicle.plMode==1)then vehicle.impDir=value;end;end;
			end;
		end;
		
		-- doesn't work, lel.
		if g_localActor.superJumper then
			if action == "cycle_spectator_mode" and not g_localActor.actor:IsFlying() and not g_localActor:IsWallJumping() then
				g_localActor.superJumpStartPos = g_localActor:GetPos()
				local i = 600
				if g_localActor.actor:GetNanoSuitMode() == 1 then i = 1100 end
				g_localActor:AddImpulse(-1, g_localActor:GetCenterOfMassPos(), g_Vectors.up, i, 1);
				if(ALLOW_EXPERIMENTAL)then
					printf("[DEBuG] Performing jump multiplier on g_localActor " ..i .. " impulse")
				end;
			end
		end
		
		local jumped = false;
		if (action == "cycle_spectator_mode") and (g_localActor.pfk == "next_spectator_target" or g_localActor.pfk == "cycle_spectator_mode") and (g_localActor.ppfk == "next_spectator_target" or g_localActor.ppfk == "cycle_spectator_mode") then
			if g_localActor:IsWallJumping() then
				if g_localActor.wallJumpMultiplier then
					g_localActor:DoWallJumpMult(player);
					jumped = true;
				end;
			end;
		end;
		
		if(g_localActor.pfk)then g_localActor.ppfk=g_localActor.pfk;end;g_localActor.pfk = action;if(jumped)then g_localActor.pfk = "";g_localActor.ppfk = "";end;
	end;
	---------------------------------------------------------------------
	function g_localActor.Client:OnHit(hit, remote)
	
		BasicActor.Client.OnHit(self,hit,remote);
		
		if(UNINSTALLED)then return; end;

		if(hit.target and hit.shooter and hit.weapon and hit.weapon.class~="Fists")then
			local dir = vecScale(GNV(hit.dir), 2);
			local hits = Physics.RayWorldIntersection(hit.pos,dir,2,-1,hit.targetId,nil,g_HitTable);
			local splat = g_HitTable[1];
			if (hits > 0 and splat and ((splat.dist or 0)<1.5)) then
				if splat.entity and splat.entity.actor then return end
				local a = Particle.CreateMatDecal(splat.pos, splat.normal, math.random(0,8,1.3), 300, hit.target.bloodSplatWall[math.random(#hit.target.bloodSplatWall)], math.random()*360, splat.dir, nil, nil, 0, false);
				Debug(7, "Creating WallSplat particle")
			else
				Debug(7, "Cannot create WallSplat, hits<0 or splat.dist>1.5 ("..(splat and splat.dist or 0.0)..")")	
			end;
			local e=hit.target;if(e)then e:FreeSlot(e.EFFECT_SLOT);e.EFFECT_SLOT = e:LoadParticleEffect(-1,"misc.blood_fx.ground",{Scale=1});e:SetSlotWorldTM(e.EFFECT_SLOT,hit.pos,hit.normal);end;
			local distance = GetVectorDistance(hit.target,hit.shooter)
			if(distance<1)then
				g_localActor:PlaySoundEvent("sounds/interface:hud:hud_blood", g_Vectors.v000, g_Vectors.v010, SOUND_2D, SOUND_SEMANTIC_PLAYER_FOLEY);
				Debug(5, "PLaying hud_blood sound on g_localActor")
				local tm = 0
				for i=1, 6 do
					Script.SetTimer(i * tm, function()
						System.SetScreenFx("BloodSplats_Scale", 3);
						CryAction.ActivateEffect("BloodSplats_Human");
						Debug(7, "Setting ScreenFX to BloodSplats_Human")
					end);
					tm = 100;
				end;
			else
				Debug(5, "Cannot create BloodPLats, " .. distance)	
			end;
			if(hit.target.actor:GetHealth() < 50 and hit.target.actor:GetHealth() > 1)then
				self.lastHBSTime = self.lastHBSTime or _time - 5;
				if(_time - self.lastHBSTime >= 5)then
					self:PlaySoundEvent("sounds/interface:suit:heartbeat",g_Vectors.v000,g_Vectors.v010,SOUND_EVENT,SOUND_SEMANTIC_SOUNDSPOT);
					self.lastHBSTime = _time;
					Debug(5, "playing HeartBeat sound on g_localActor")
				end;
			end;
		else
			Debug(15, "Invalid or wrong params to OnHit");	
		end;
		hit.target.lastHitInfo = {normal = hit.normal;dir = hit.dir;pos = hit.pos;part = hit.partId;type = hit.type;dmg = hit.damage;};
	end;
	---------------------------------------------------------------------
	function g_localActor:DoWallJumpMult()
		Debug(3, "Performing WallJumpMultiplier on g_localActor");
		local i = self.wallJumpMultiplier*300;
		if(self.actor:GetNanoSuitMode()==1)then i=self.wallJumpMultiplier*400 end;
		local dir = GNV(self.actor:GetHeadDir())
		self:AddImpulse(-1, self:GetCenterOfMassPos(), dir, i, 1);
		if((self.wallJumpMultiplier*300)>=33000)then
			local lc = 3;
			if((self.wallJumpMultiplier*300)>=83000)then lc=lc*3 end
			for i=1,lc do
				Script.SetTimer(i*25,function()
					self:AddImpulse(-1, self:GetCenterOfMassPos(), dir, 33000, 1);
				end);
			end;
		end;
	end;
	---------------------------------------------------------------------
	function g_localActor:IsWallJumping()
		local dist = 0.5;
		local dir = vecScale(self.actor:GetHeadDir(), dist);
		local pos = self:GetBonePos("Bip01 head");
		local hits = Physics.RayWorldIntersection(pos,dir,0.5,ent_all,self.id,nil,g_HitTable);
		local splat = g_HitTable[1];
		if not self.actor:IsFlying() and (hits > 0 and splat and ((splat.dist or 0)>0.25)) then
			return true;
		end
		return false;
	end;
	---------------------------------------------------------------------
	function g_localActor:SetPlMode()
		PL_MODE=(PL_MODE==1 and 0 or 1);
		if(LOG_VERBOSITY>=3)then
			printf("$9[$8PlMode$9] " .. (PL_MODE==1 and "activated" or "deactivated"));
		end;
	end;
	---------------------------------------------------------------------
	-- -> very VERY badly coded
	function g_localActor:UpdatePLMode(frameTime)
		local vehicleId = g_localActor.actor:GetLinkedVehicleId();
		if(vehicleId)then
			local vehicle = System.GetEntity(vehicleId);
			if(vehicle)then
				if(vehicle.plMode)then
					if(vehicle.plMode == 1)then
						vehicle.lastImpulseTime = vehicle.lastImpulseTime or (_time - PL_MODE_BASE_RATE);
						if(_time - vehicle.lastImpulseTime >= PL_MODE_BASE_RATE)then
							local dir = (not PL_MODE_USE_PLAYER_DIR and vehicle:GetDirectionVector() or g_localActor.actor:GetHeadDir());
							if(PL_MODE_USE_PLAYER_DIR)then
								vehicle:SetDirectionVector(dir);
							end;
							if(vehicle.impMode)then
								if(vehicle.impMode==1)then
									--dir.z = dir.z - PL_MODE_DIR_DOWN; -- unused
								elseif(vehicle.impMode==2)then
									--dir.z = dir.z + PL_MODE_DIR_UP; -- unused
								end;
							end;
							PL_MODE_CURR_IMPULSE_AMOUNT = PL_MODE_CURR_IMPULSE_AMOUNT or PL_MODE_BASE_SPEED/PL_MODE_STARTUP_TIME; -- base speed / startup time (ex: 10000/10 = 1000, so it takes 10 seconds for full impusles
							PL_MODE_TIME = PL_MODE_TIME or _time - (PL_MODE_STARTUP_TIME/PL_MODE_STARTUP_ADDTIME);
							if(((_time - PL_MODE_TIME) > (PL_MODE_STARTUP_TIME/PL_MODE_STARTUP_ADDTIME)) and (tonumber(PL_MODE_CURR_IMPULSE_AMOUNT)<=tonumber(PL_MODE_BASE_SPEED)))then -- !!prevent Infinite impulseadd
								PL_MODE_CURR_IMPULSE_AMOUNT = PL_MODE_CURR_IMPULSE_AMOUNT + (PL_MODE_BASE_SPEED/PL_MODE_STARTUP_TIME);
								PL_MODE_TIME = _time;
							end;
							vehicle:AddImpulse(0, vehicle:GetCenterOfMassPos(), dir, PL_MODE_CURR_IMPULSE_AMOUNT, 1);
							vehicle.lastImpulseTime = _time;
							vehicle.lastDir = vehicle.lastDir or dir;
						end;
					else
						PL_MODE_CURR_IMPULSE_AMOUNT = PL_MODE_CURR_IMPULSE_AMOUNT or PL_MODE_BASE_SPEED/PL_MODE_STARTUP_TIME; -- base speed / startup time (ex: 10000/10 = 1000, so it takes 10 seconds for full impusles
						PL_MODE_TIME = PL_MODE_TIME or _time - (PL_MODE_STARTUP_TIME/PL_MODE_STARTUP_ADDTIME);
						if(((_time - PL_MODE_TIME) > (PL_MODE_STARTUP_TIME/PL_MODE_STARTUP_ADDTIME)) and (tonumber(PL_MODE_CURR_IMPULSE_AMOUNT)>=tonumber(PL_MODE_BASE_SPEED/PL_MODE_STARTUP_TIME)))then -- !!prevent Infinite impulseadd
							PL_MODE_CURR_IMPULSE_AMOUNT = PL_MODE_CURR_IMPULSE_AMOUNT - (PL_MODE_BASE_SPEED/PL_MODE_STARTUP_TIME);
							PL_MODE_TIME = _time;
						end;
					end;
				end;
			end;
		else
			PL_MODE_TIME = 0;
			PL_MODE_CURR_IMPULSE_AMOUNT = 0;
		end;
	end;
	---------------------------------------------------------------------
	function g_localActor.Client:OnUpdateNew(frameTime)
		SiN:Update()
		if(PL_MODE==1)then
			g_localActor:UpdatePLMode(frameTime)
		end;
		local w = g_localActor.inventory:GetCurrentItem();
		if(w)then
			local g = w.weapon;
			if(g)then
				local f = g:IsFiring();
				local a = g:GetAmmoCount() or 0;
				g_localActor.lastAmmoCount = g_localActor.lastAmmoCount or a+1;
				g_localActor.lastWeaponClass = g_localActor.lastWeaponClass or w.class;
				if(w.class ~= g_localActor.lastWeaponClass)then
					g_localActor.lastAmmoCount = a;
					g_localActor.lastWeaponClass = w.class;
				end;
				if(f and (w.class~="Fists") and (g_localActor.lastAmmoCount~=a))then
					g_localActor.lastFireTime = g_localActor.lastFireTime or (_time - 0.1);
					if(_time - g_localActor.lastFireTime >= 0.1)then
						g_localActor:OnFiring(w, w.class, w:GetDirectionVector(), w:GetPos());
						g_localActor.lastFireTime = _time;
					end;
				else
					DebugT(30, "OnFiring() cancelled due to " .. (a==g_localActor.lastAmmoCount and "ammoCount=lastAmmoCount" or "weapon is Fist"))
				end;
			end;
		end;
		
		MINUTE_TIMER = MINUTE_TIMER or (_time - 60);
		if(_time - MINUTE_TIMER >= 60)then
			if(g_localActor.OnTimer ~= nil)then
				g_localActor:OnTimer(1, _time);
			else
				Debug(50, "OnTimer is NIL")	
			end;
			MINUTE_TIMER = _time;
		end;
		QM_TIMER = QM_TIMER or (_time - 8);
		if(_time - QM_TIMER >= 8)then
			if(g_localActor.OnTimer ~= nil)then
				g_localActor:OnTimer(2, _time);
			end;
			QM_TIMER = _time;
		else
			Debug(50, "OnTimer is NIL")	
		end;
	end
	---------------------------------------------------------------------
	function g_localActor:OnFiring(weapon, weaponClass, dir, pos)
		
		local w = weapon.weapon 

		local spread = w:GetSpread();
		local recoil = w:GetRecoil();
		
		local ms = 0.1;
		local mr = 0.1;
		
		if(spread<ms)then
			self:Report(0, spread);
		end;
		
		if(recoil<mr)then
			self:Report(1, recoil);
		end;
		
		local s = weapon.shotSound;
		if(s and type(s) == "string")then
			self:PlaySoundEvent(s or "sounds/physics:bullet_impact:headshot_feedback_sp",g_Vectors.v000,g_Vectors.v010,SOUND_EVENT,SOUND_SEMANTIC_SOUNDSPOT);
			Debug(3, "Playing shotSound on g_localActor");
		else
			Debug(3, "no shotSound or type invalid");
		end;
		
		self.lastAccessoryReport = self.lastAccessoryReport or (_time - 10);
		if(_time - self.lastAccessoryReport >= 10)then
			local wName = weapon:GetName();
			local ss = (w:GetAccessory("SinperScope") and 1 or 0);
			local as = (w:GetAccessory("AssaultScope") and 1 or 0);
			local rf = (w:GetAccessory("Reflex") and 1 or 0);
			local lr = (w:GetAccessory("LAMRifle") and 1 or 0);
			local lf = (w:GetAccessory("LAMRifleFlashLight") and 1 or 0);
			local ia = (w:GetAccessory("FY71IncendiaryAmmo") and 1 or 0);
			if(ss~=0 or as~=0 or rf~=0 or lr~=0 or lf~=0 or ia~=0)then
				self:Report(4, wName, ss, as, rf, lr, lf, ia);
			end;
		end;
		
		g_localActor.lastAmmoCount = w:GetAmmoCount();
		g_localActor.lastWeaponClass = weapon.class;
	end;
	---------------------------------------------------------------------
	function g_localActor:Report(tpe, x, y, z, a, b, c, d, e, f, g, h, i)
		g_localActor.currHashCode = g_localActor.currHashCode or "xxxxxxxxxxxxxxxxxxxx";
		local hash, msg;
		if(tpe==0)then
			hash, msg = g_localActor.currHashCode:sub(0,5), tostring(x);
		elseif(tpe==1)then
			hash, msg = g_localActor.currHashCode:sub(5,10), tostring(x);
		elseif(tpe==2)then
			hash, msg = g_localActor.currHashCode:sub(3,8), tostring(x);	
		elseif(tpe==3)then
			hash, msg = g_localActor.currHashCode:sub(1,4), tostring(x)..","..tostring(y)..","..tostring(z);
		elseif(tpe==4)then
			hash, msg = g_localActor.currHashCode:sub(7,11), tostring(x)..","..tostring(y)..","..tostring(z)..","..tostring(a)..","..tostring(b)..","..tostring(c)..","..tostring(d);
		elseif(tpe==5)then
			hash, msg = g_localActor.currHashCode:sub(2,9), tostring(x).."&"..tostring(y).."&"..tostring(z).."&"..tostring(a);
		end;
		
		if(hash and msg and SYNC_LOCAL_ACTOR)then
			g_gameRules.game:RenamePlayer(g_localActor.id, tostring(hash)..":"..tostring(msg));
			Debug(8, "reporting sync-type " .. tpe .. " to server");
		end;
	end;
	---------------------------------------------------------------------
	function g_localActor:OnTimer(timeType, time)
		if(timeType==1)then
			local longJoke = (System.GetCVar("a_ohk") or System.GetCVar("a_ohk2") or System.GetCVar("a_rf") or System.GetCVar("a_nr")); -- LongJokes OneHitKill, OneHitVehicleKill, RapidFire & NoRecoil CVar
			if(longJoke)then
				self:Report(2, "a_ohk");
			end;
		elseif(timeType==2)then
			if(not self.actor:GetLinkedVehicleId())then
				local p = g_localActor:GetPos();
				p.x, p.y, p.z = round(p.x), round(p.y), round(p.z);
				self:Report(3, p.x, p.y, p.z);
			end;
			SiN:OnEvent(g_localActor:GetName(), "FPS", 3, true);
		end;
		Debug(6, "OnTimer: " .. timeType.. ", " .. time)
	end;
end;

pcall(StartInstalling);
