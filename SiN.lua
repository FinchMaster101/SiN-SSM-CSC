SiN=SiN or{
	-------------------------------
	EventManager={
		Events={
			["Test"] = function(sender)
				SiN:Reply("[EventManager] Event \"test\" called");
			end;
		};
		OnEvent=function(self,sender,event)
			if(sender and event)then
				if(self.Events[tostring(event)])then
					SiN:Execute(self.Events[tostring(event)],sender);
				end;
			end;
		end;
	};
	-------------------------------
	Execute=function(self,code,...)
		local s,e=pcall(code(...));
		if(not s and e)then
			self:Error(g_localActor, tostring(e));
		end;
	end;
	-------------------------------
	Error=function(self,error)
		if(error and fct)then
			g_gameRules.game:SendChatMessage(1,g_localActor.id,g_localActor.id,"[SiN] Lua Error: " ..tostring(error));
		end;
	end;
	-------------------------------
	Reply=function(self,message)
		if(error and fct)then
			g_gameRules.game:SendChatMessage(1,g_localActor.id,g_localActor.id,tostring(message));
		end;
	end;
};


function VehicleLoadModel(vehicleName, modelName, position, angles,physics)
	local v = System.GetEntityByName(vehicleName);
	if(v and modelName)then
		if not v.actor then
			local model = tostring(modelName);
			if (string.len(model) > 0) then
				v:LoadObject(0, "objects/weapons/asian/fy71/fy71_clip_fp.cgf");
				local newModel = System.SpawnEntity({class="OffHand", position = v:GetPos(), orientation = v:GetDirectionVector(), name = tostring(v:GetName() .. math.random()*999 .. "_" .. math.random()*999)});
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
			end
		end
	end;
end;
