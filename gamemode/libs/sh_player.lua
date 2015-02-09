local META = FindMetaTable( "Player" )

if ( SERVER ) then
	function META:SetWeaponRaised( bool, weapon )
		if ( !IsValid( self ) or !self:IsCharacterLoaded( ) ) then return end
		weapon = weapon or self:GetActiveWeapon( )
		self:SetNetworkValue( "weaponRaised", bool )
		if ( IsValid( weapon ) ) then
			local time = 9999999999
			if ( bool ) then time = 0.9 end
			weapon:SetNextPrimaryFire( CurTime( ) + time )
			weapon:SetNextSecondaryFire( CurTime( ) + time )
		end
	end
	
	function META:ToggleWeaponRaised( )
		if ( self:GetWeaponRaised( ) ) then
			self:SetWeaponRaised( false )
		else
			self:SetWeaponRaised( true )
		end
	end
	
	hook.Add("PlayerSwitchWeapon", "player_PlayerSwitchWeapon", function( pl, old, new )
		pl:SetWeaponRaised( true, new )
	end )
else

end

function META:GetWeaponRaised( )
	return self:GetNetworkValue( "weaponRaised", false )
end