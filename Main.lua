if(printf)then printf("$9[$4SiN$9] AISystem: Starting to install .."); end;
------------------------------------------------------
function GetDirectionVector(a, b, normalize)
  local p1, p2 = (not a.id and a or a:GetPos()),(not b.id and b or b:GetPos());
  p1.x, p1.y, p1.z = (p1.x - p2.x), (p1.y - p2.y), (p1.z - p2.z);
  if(normalize)then
    NormalizeVector(p1)
  end;
  return p1;
end;

function GetVectorDistance(a, b)
	local p1, p2 = (not a.id and a or a:GetWorldPos()), (not b.id and b or b:GetWorldPos());
	local x, y, z = (p1.x - p2.x), (p1.y - p2.y), (p1.z - p2.z);
	return (math.sqrt(x*x + y*y + z*z) or 0.0)
end;

function round(x)
     return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

function GNV(vec3)
	return {x=vec3.x*-1,y=vec3.y*-1,z=vec3.z*-1};
end;

SIN_AI_UPDATE_DELAY = 50;
UPDATE_AI_ENTITIES = true;
SIN_LOG_VERBOSITY = 0


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



if not OldPatchedSP then OldPatchedSP = SinglePlayer.Client.OnUpdate end

SinglePlayer.Client.OnUpdate = function(self, dt)
	OldPatchedSP(self, dt)
	if not (g_gameRules.class == "InstantAction" or g_gameRules.class == "PowerStruggle") then
		return;
	end
	if(g_localActor)then
		g_localActor.Client:OnUpdateNew(dt)
	end;
end
			
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
function ToggleAIUpdate()
	if not UPDATE_AI_ENTITIES then
		UPDATE_AI_ENTITIES = true;
		printf("$9[$4SiN$9] AISystem: enabeling AISystem");
	else
		UPDATE_AI_ENTITIES = false;
		printf("$9[$4SiN$9] AISystem: disabeling AISystem");
	end;
end;

System.AddCCommand("sin_aiLogVerbosity", "SetAILogVerbosity(%%)", "Sets the new SiN-AISystem logging verbosity");
System.AddCCommand("sin_aiUpdateSystem", "ToggleAIUpdate()", "if true, AI Entities will be updated and relocated to their correct position");
System.AddCCommand("sin_update", "DownloadLatest()", "re-downloads the SiN-AIFiles");

function DownloadLatest() -- function from diznq from sfwcl client
	local url = "https://raw.githubusercontent.com/FinchMaster101/SiN-SSM-CSC/master/Main.lua";
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
if(printf)then printf("$9[$4SiN$9] AISystem: Installation finished!"); end;
