-- Variables that are used on both client and server
SWEP.Gun = ("weapon_supersword") -- must be the name of your swep but NO CAPITALS!
if (GetConVar(SWEP.Gun.."_allowed")) != nil then
	if not (GetConVar(SWEP.Gun.."_allowed"):GetBool()) then SWEP.Base = "bobs_blacklisted" SWEP.PrintName = SWEP.Gun return end
end
SWEP.Category				= "CatGuy Sweps"
SWEP.Author					= ""
SWEP.Contact				= ""
SWEP.Purpose				= ""
SWEP.Instructions			= ("Left click to slash".."\n".."Right mouse to leap".."\n".."Reload to heal.")
SWEP.PrintName				= "Super Sword"		-- Weapon name (Shown on HUD)	
SWEP.Slot					= 0				-- Slot in the weapon selection menu
SWEP.SlotPos				= 21			-- Position in the slot
SWEP.DrawAmmo				= true		-- Should draw the default HL2 ammo counter
SWEP.DrawWeaponInfoBox		= true		-- Should draw the weapon info box
SWEP.BounceWeaponIcon   	= false		-- Should the weapon icon bounce?
SWEP.DrawCrosshair			= false		-- set false if you want no crosshair
SWEP.Weight					= 30			-- rank relative ot other weapons. bigger is better
SWEP.AutoSwitchTo			= true		-- Auto switch to if we pick it up
SWEP.AutoSwitchFrom			= true		-- Auto switch from if you pick up a better weapon
SWEP.HoldType 				= "melee2"		-- how others view you carrying the weapon
-- normal melee melee2 fist knife smg ar2 pistol rpg physgun grenade shotgun crossbow slam passive 

SWEP.ViewModelFOV			= 70
SWEP.ViewModelFlip			= false
SWEP.ViewModel				= "models/weapons/v_dmascus.mdl"	-- Weapon view model
SWEP.WorldModel				= "models/weapons/w_damascus_sword.mdl"	-- Weapon world model
SWEP.ShowWorldModel			= true
SWEP.Base					= "bobs_gun_base"

SWEP.Spawnable				= true
SWEP.AdminSpawnable			= true
SWEP.FiresUnderwater 		= false

SWEP.Primary.RPM			= 250		-- This is in Rounds Per Minute
SWEP.Primary.ClipSize		= 30		-- Size of a clip
SWEP.Primary.DefaultClip	= 60		-- Bullets you start with
SWEP.Primary.KickUp			= 0.4		-- Maximum up recoil (rise)
SWEP.Primary.KickDown		= 0.3		-- Maximum down recoil (skeet)
SWEP.Primary.KickHorizontal	= 0.3		-- Maximum up recoil (stock)
SWEP.Primary.Automatic		= false		-- Automatic = true; Semi Auto = false
SWEP.Primary.Ammo			= ""		-- pistol, 357, smg1, ar2, buckshot, slam, SniperPenetratedRound, AirboatGun
-- Pistol, buckshot, and slam always ricochet. Use AirboatGun for a light metal peircing shotgun pellets

SWEP.Secondary.IronFOV			= 0		-- How much you 'zoom' in. Less is more! 	

SWEP.Primary.Damage		= 78 -- Base damage per bullet
SWEP.Primary.Spread		= .02	-- Define from-the-hip accuracy 1 is terrible, .0001 is exact)
SWEP.Primary.IronAccuracy = .01 -- Ironsight accuracy, should be the same for shotguns

SWEP.Slash = 1

SWEP.Primary.Sound	= Sound("weapons/blades/woosh.mp3") //woosh
SWEP.KnifeShink 	= Sound("weapons/blades/hitwall.mp3")
SWEP.KnifeSlash 	= Sound("weapons/blades/slash.mp3")
SWEP.KnifeStab 		= Sound("weapons/blades/nastystab.mp3")

SWEP.SwordChop 		= Sound("weapons/blades/swordchop.mp3")
SWEP.SwordClash 	= Sound("weapons/blades/clash.mp3")

if CLIENT then
	killicon.Add( "weapon_supersword", "vgui/hud/weapon_supersword" , Color( 255, 255, 255, 255 ) )
end
	// Config Other Options
	CreateConVar( "sword_nofalldamage", 1, FCVAR_SERVER_CAN_EXECUTE )
	CreateConVar( "sword_leap_height", 350, FCVAR_SERVER_CAN_EXECUTE )
	CreateConVar( "sword_leap_recharge_timer", 60, FCVAR_SERVER_CAN_EXECUTE )
	CreateConVar( "sword_heal_recharge_timer", 40, FCVAR_SERVER_CAN_EXECUTE )
	CreateConVar( "sword_primary_damage", 78, FCVAR_SERVER_CAN_EXECUTE )

	local sword_nofalldamage 		= GetConVar( "sword_nofalldamage" )
	local sword_leap_height 		= GetConVar( "sword_leap_height" )
	local sword_leap_recharge_timer = GetConVar( "sword_leap_recharge_timer" )
	local sword_heal_recharge_timer = GetConVar( "sword_heal_recharge_timer" )
	local sword_primary_damage 		= GetConVar( "sword_primary_damage" )

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 0, "Power" )
	if SERVER then
		self:SetPower(100)
		self.cooldown = 0
	end
end

function SWEP:PrimaryAttack()
	if not self.Owner:IsPlayer() then return end
	pos = self.Owner:GetShootPos()
	ang = self.Owner:GetAimVector()
	vm = self.Owner:GetViewModel()
	damagedice = math.Rand(.85,1.25)
	pain = sword_primary_damage:GetInt() * damagedice
	if self:CanPrimaryAttack() and self.Owner:IsPlayer() then
	self.Weapon:SendWeaponAnim( ACT_VM_IDLE )
		if !self.Owner:KeyDown(IN_RELOAD) and !self.Owner:KeyDown(IN_ATTACK2)  then
			if self.Slash == 1 then
				--if CLIENT then return end
				vm:SetSequence(vm:LookupSequence("midslash1"))
				self.Slash = 2
			else
				--if CLIENT then return end
				vm:SetSequence(vm:LookupSequence("midslash2"))
				self.Slash = 1
			end --if it looks stupid but works, it aint stupid!
			self.Weapon:EmitSound(self.Primary.Sound)--slash in the wind sound here
				if SERVER and IsValid(self.Owner) then
					if self.Owner:Alive() then if self.Owner:GetActiveWeapon():GetClass() == self.Gun then
						local slash = {}
						slash.start = pos
						slash.endpos = pos + (ang * 52)
						slash.filter = self.Owner
						slash.mins = Vector(-15, -5, 0)
						slash.maxs = Vector(15, 5, 5)
						local slashtrace = util.TraceHull(slash)
						if slashtrace.Hit then
							targ = slashtrace.Entity
							if targ:IsPlayer() or targ:IsNPC() then
									self.Weapon:EmitSound(self.SwordChop)
								paininfo = DamageInfo()
								paininfo:SetDamage(pain)
								paininfo:SetDamageType(DMG_SLASH)
								paininfo:SetAttacker(self.Owner)
								paininfo:SetInflictor(self.Weapon)
								paininfo:SetDamageForce(slashtrace.Normal *35000)
								if SERVER then targ:TakeDamageInfo(paininfo) end
							elseif IsValid(slashtrace.Entity) and slashtrace.Entity:GetClass() == "func_breakable_surf" then
								slashtrace.Entity:Fire("Shatter")
							else
								self.Weapon:EmitSound(self.KnifeShink)//SHINK!
								trace = self.Owner:GetEyeTrace()
								util.Decal("ManhackCut", trace.HitPos + trace.HitNormal, trace.HitPos - trace.HitNormal )
							end
						end
					end end
				end
			self.Owner:SetAnimation( PLAYER_ATTACK1 )
			self.Weapon:SetNextPrimaryFire(CurTime()+.4)
		end
	end
end

function SWEP:Holster()
	if CLIENT and IsValid(self.Owner) and not self.Owner:IsNPC() then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
		end
	end
	return true
end

if CLIENT then
	function SWEP:DrawHUD()
		local powerW = self:GetPower() * 3
		local w, h = 300, 30
		local x, y = math.floor( ScrW() / 2 - w / 2 ), ScrH() - h - 30
		draw.RoundedBox( 0, x, y, w, h, Color( 20, 20, 20, 150 ) )
		draw.RoundedBox( 0, x + 1, y + 1, powerW - 2, h - 2, Color( 60, 60, 158, 250 ) )
		draw.SimpleText( powerW / 3, "Trebuchet24", ScrW() / 2, y + 3, powerW > 50 and color_white or Color(220, 65, 65, 220), TEXT_ALIGN_CENTER )
		if self:GetPower() < 100 then
			draw.SimpleText( "Recharging", "DebugFixedSmall", ScrW() / 2 + 90, y - h + 10, Color(0, 255, 0, 220), TEXT_ALIGN_CENTER )
		end
		if self.Owner:GetActiveWeapon():GetClass() == "weapon_supersword" and sword_nofalldamage:GetBool() then
			draw.SimpleText( "No Fall Damage", "DebugFixedSmall", ScrW() / 2 - 90, y - h + 10, Color(0, 255, 0, 220), TEXT_ALIGN_CENTER )
		end
	end
end

function SWEP:LeapOwner()
	if (!self.Owner:IsOnGround() || CLIENT || self:GetPower() < 100 ) then return end
	self:SetPower(0)
	self.Owner:SetVelocity( self.Owner:GetAimVector() * sword_leap_height:GetInt() + Vector( 0, 0, 512 ) )
	self:CallOnClient( "ForceJumpAnim", "" )
	self.Owner:EmitSound("npc/antlion_guard/foot_heavy1.wav")
	timer.Simple(sword_leap_recharge_timer:GetInt(), function()
		if !IsValid(self) then return end
		self:SetPower(100)
		self.Owner:EmitSound("HL1/fvox/power_restored.wav")	
	end)
end

function SWEP:Reload()
	if CLIENT then return end
	local power = self:GetPower()
	local health = self.Owner:Health()
	if power >= 20 and CurTime() > self.cooldown and health < 100 then
		self.Owner:EmitSound("items/smallmedkit1.wav")
		if (health + 20) >= 100 then
			self.Owner:SetHealth(100)
		else
			self.Owner:SetHealth(health + 20)
		end
		self.cooldown = CurTime() + 1
		self:SetPower(power - 20)
		timer.Create("health_"..self.Owner:UniqueID()..CurTime(), sword_heal_recharge_timer:GetInt(), 1, function()
			if !IsValid(self) then return end
			self:SetPower(self:GetPower() + 20)
			if self:GetPower() == 100 then self.Owner:EmitSound("HL1/fvox/power_restored.wav") end
		end)
	end
end

function SWEP:SecondaryAttack()
	self:LeapOwner()
end

if SERVER then
	hook.Add( "GetFallDamage", "weapon_supersword_fall_damage", function( ply, speed )
		if IsValid( ply ) and ply:GetActiveWeapon():GetClass() == "weapon_supersword" and sword_nofalldamage:GetBool() then
			ply:ViewPunch( Angle( -10, 0, 0 ) )
			return 0
		end
	end)
end