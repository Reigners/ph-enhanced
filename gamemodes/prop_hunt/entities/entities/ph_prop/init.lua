
-- Send required files to client
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")


-- Include needed files
include("shared.lua")


-- Called when the entity initializes
function ENT:Initialize()
	self:SetModel("models/player/kleiner.mdl")
	self.health = 100
end 


-- Called when we take damge
function ENT:OnTakeDamage(dmg)
	local pl = self:GetOwner()
	local attacker = dmg:GetAttacker()
	local inflictor = dmg:GetInflictor()

	-- Health
	if pl && pl:IsValid() && pl:Alive() && pl:IsPlayer() && attacker:IsPlayer() && dmg:GetDamage() > 0 then
		self.health = self.health - dmg:GetDamage()
		pl:SetHealth(self.health)
		
		if self.health <= 0 then
			pl:KillSilent()
			
			if inflictor && inflictor == attacker && inflictor:IsPlayer() then
				inflictor = inflictor:GetActiveWeapon()
				if !inflictor || inflictor == NULL then inflictor = attacker end
			end
			
			net.Start( "PlayerKilledByPlayer" )
		
			net.WriteEntity( pl )
			net.WriteString( inflictor:GetClass() )
			net.WriteEntity( attacker )
		
			net.Broadcast()

	
			MsgAll(attacker:Name() .. " found and killed " .. pl:Name() .. "\n") 
	
	
			-- D4UNKN0WNM4N2010: Alright, I made my own code for this. The current one looked too messy, sorry. -- it's fine btw
			if GetConVar("ph_freezecam"):GetBool() then
				if pl:GetNWBool("InFreezeCam", false) then
					pl:PrintMessage(HUD_PRINTCONSOLE, "Something went wrong with the Freeze Camera, it's still enabled!")
				else
					timer.Simple(0.5, function()
						if !pl:GetNWBool("InFreezeCam", false) then
							-- Play the good old Freeze Cam sound
							umsg.Start("PlayFreezeCamSound", pl)
							umsg.End()
						
							pl:SetNWEntity("PlayerKilledByPlayerEntity", attacker)
							pl:SetNWBool("InFreezeCam", true)
							pl:SpectateEntity( attacker )
							pl:Spectate( OBS_MODE_FREEZECAM )
						end
					end)
					
					timer.Simple(4.5, function()
						if pl:GetNWBool("InFreezeCam", false) then
							pl:SetNWBool("InFreezeCam", false)
							pl:Spectate( OBS_MODE_CHASE )
							pl:SpectateEntity( nil )
						end
					end)
				end
			end
			
			
			attacker:AddFrags(1)
			pl:AddDeaths(1)
			attacker:SetHealth(math.Clamp(attacker:Health() + GetConVarNumber("ph_hunter_kill_bonus"), 1, 100))
			
			hook.Call("PH_OnPropKilled", nil, pl, attacker)
			
			pl:RemoveProp()
			pl:RemoveClientProp()
		end
	end
end