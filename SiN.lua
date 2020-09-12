


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
