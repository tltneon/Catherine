--[[
< CATHERINE > - A free role-playing framework for Garry's Mod.
Development and design by L7D.

Catherine is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Catherine.  If not, see <http://www.gnu.org/licenses/>.
]]--

local PLUGIN = PLUGIN
local vars = {
	{
		id = "name",
		default = "Johnson"
	},
	{
		id = "desc",
		default = "No desc"
	},
	{
		id = "factions",
		default = { }
	},
	{
		id = "classes",
		default = { }
	},
	{
		id = "inv",
		default = { }
	},
	{
		id = "cash",
		default = 0
	},
	{
		id = "setting",
		default = { }
	},
	{
		id = "status",
		default = false
	},
	{
		id = "items",
		default = { }
	}
}

function PLUGIN:SaveVendors( )
	local data = { }
	
	for k, v in pairs( ents.FindByClass( "cat_vendor" ) ) do
		if ( !v.vendorData ) then continue end
		data[ #data + 1 ] = {
			name = v.vendorData.name,
			desc = v.vendorData.desc,
			factionData = v.vendorData.factions,
			classData = v.vendorData.classes,
			inv = v.vendorData.inv,
			cash = v.vendorData.cash,
			setting = v.vendorData.setting,
			status = v.vendorData.status,
			items = v.vendorData.items,
			model = v:GetModel( ),
			pos = v:GetPos( ),
			ang = v:GetAngles( )
		}
	end
	
	catherine.data.Set( "vendors", data )
end

function PLUGIN:LoadVendors( )
	local data = catherine.data.Get( "vendors", { } )
	
	for k, v in pairs( data ) do
		local ent = ents.Create( "cat_vendor" )
		ent:SetPos( v.pos )
		ent:SetAngles( v.ang )
		ent:SetModel( v.model )
		ent:Spawn( )
		ent:Activate( )
		
		self:MakeVendor( ent, v )
	end
end

function PLUGIN:MakeVendor( ent, data )
	if ( !IsValid( ent ) or !data ) then return end

	ent.vendorData = { }
	for k, v in pairs( vars ) do
		local val = data[ v.id ] and data[ v.id ] or v.default
		ent:SetNetVar( v.id, val )
		ent.vendorData[ v.id ] = val
	end
	
	ent.isVendor = true
end

function PLUGIN:SetVendorData( ent, id, data, noSync )
	if ( !IsValid( ent ) or !id or !data ) then return end

	ent.vendorData[ id ] = data
	ent:SetNetVar( id, data )

	if ( !noSync ) then
		local target = self:GetVendorWorkingPlayers( )
		if ( #target != 0 ) then
			netstream.Start( target, "catherine.plugin.vendor.RefreshRequest", ent )
		end
	end
end

function PLUGIN:GetVendorData( ent, id, default )
	if ( !IsValid( ent ) or !id ) then return default end
	return ent.vendorData[ id ] or default
end

function PLUGIN:VendorWork( pl, ent, workID, data )
	if ( !IsValid( pl ) or !IsValid( ent ) or !workID or !data ) then return end
	if ( workID == CAT_VENDOR_ACTION_BUY ) then
		local uniqueID = data.uniqueID
		local count = math.max( data.count or 1, 1 )
		local itemTable = catherine.item.FindByID( uniqueID )

		if ( !itemTable ) then
			catherine.util.Notify( pl, "Item is not valid!" )
			return
		end

		if ( !catherine.inventory.HasItem( pl, uniqueID ) ) then
			catherine.util.Notify( pl, "You don't have this item!" )
			return
		end
		
		--[[ // 나중에 ㅋ
		// Vendor 가 사야할 아이템 숫자가 플레이어의 인벤토리 아이템 수보다 많을때?
		if ( catherine.inventory.GetItemInt( pl, uniqueID ) < count ) then
			catherine.util.Notify( pl, "!!!!" )
			return
		end
		--]]
		
		local playerCash = catherine.cash.Get( pl )
		local vendorCash = self:GetVendorData( ent, "cash", 0 )
		local vendorInv = table.Copy( self:GetVendorData( ent, "inv", { } ) )
		
		if ( !vendorInv[ uniqueID ] ) then
			catherine.util.Notify( pl, "This vendor has not stock for this item!" )
			return
		end
		
		local itemCost = math.Round( ( vendorInv[ uniqueID ].cost * count ) / self.VENDOR_SOLD_DISCOUNTPER )
		
		if ( vendorCash < itemCost ) then
			catherine.util.Notify( pl, "This vendor has not enough cash!" )
			return
		end

		vendorInv[ uniqueID ] = {
			uniqueID = uniqueID,
			stock = vendorInv[ uniqueID ].stock + count,
			cost = vendorInv[ uniqueID ].cost,
			type = vendorInv[ uniqueID ].type
		}

		catherine.cash.Give( pl, itemCost )
		catherine.item.Take( pl, uniqueID, count )
		self:SetVendorData( ent, "inv", vendorInv )
		self:SetVendorData( ent, "cash", vendorCash - itemCost )
		
		hook.Run( "ItemVendorSolded", pl, itemTable )
		catherine.util.Notify( pl, "You are sold '" .. itemTable.name .. "' at '" .. catherine.cash.GetName( itemCost ) .. "' from this vendor!" )
	elseif ( workID == CAT_VENDOR_ACTION_SELL ) then
		local uniqueID = data.uniqueID
		local itemTable = catherine.item.FindByID( uniqueID )
		local count = math.max( data.count or 1, 1 )
		
		if ( !itemTable ) then
			catherine.util.Notify( pl, "Item is not valid!" )
			return
		end
		
		local playerCash = catherine.cash.Get( pl )
		local vendorCash = self:GetVendorData( ent, "cash", 0 )
		local vendorInv = table.Copy( self:GetVendorData( ent, "inv", { } ) )

		if ( !vendorInv[ uniqueID ] ) then
			catherine.util.Notify( pl, "This vendor has not stock for this item!" )
			return
		end
		
		if ( vendorInv[ uniqueID ].stock < count ) then
			count = vendorInv[ uniqueID ].stock
		end
		
		local itemCost = vendorInv[ uniqueID ].cost * count
		
		if ( itemCost > playerCash ) then
			catherine.util.Notify( pl, "You don't have enough cash!" )
			return 
		end

		vendorInv[ uniqueID ] = {
			uniqueID = uniqueID,
			stock = vendorInv[ uniqueID ].stock - count,
			cost = vendorInv[ uniqueID ].cost,
			type = vendorInv[ uniqueID ].type
		}
		
		if ( vendorInv[ uniqueID ].stock <= 0 ) then
			vendorInv[ uniqueID ].stock = 0
		end
		
		local success = catherine.item.Give( pl, uniqueID, count )
		if ( !success ) then return end
		
		catherine.cash.Take( pl, itemCost )
		self:SetVendorData( ent, "inv", vendorInv )
		self:SetVendorData( ent, "cash", vendorCash + itemCost )
		
		catherine.util.Notify( pl, "You are brought '" .. itemTable.name .. "' at '" .. catherine.cash.GetName( itemCost ) .. "' from this vendor!" )
	elseif ( workID == CAT_VENDOR_ACTION_SETTING_CHANGE ) then
		if ( !pl:IsAdmin( ) ) then
			catherine.util.Notify( pl, "You don't have permission!" )
			return
		end
		
	elseif ( workID == CAT_VENDOR_ACTION_ITEM_CHANGE ) then
		if ( !pl:IsAdmin( ) ) then
			catherine.util.Notify( pl, "You don't have permission!" )
			return
		end
		
		local uniqueID = data.uniqueID
		local stock = math.Round( data.stock )
		local cost = math.Round( data.cost )
		local type = data.type
		local itemTable = catherine.item.FindByID( uniqueID )

		if ( !itemTable ) then
			catherine.util.Notify( pl, "Item is not valid!" )
			return
		end

		local vendorInv = table.Copy( self:GetVendorData( ent, "inv", { } ) )

		vendorInv[ uniqueID ] = {
			uniqueID = uniqueID,
			stock = stock,
			cost = cost,
			type = type
		}

		self:SetVendorData( ent, "inv", vendorInv )
		
		catherine.util.Notify( pl, "Item data updated!" )
	elseif ( workID == CAT_VENDOR_ACTION_ITEM_UNCHANGE ) then
		local uniqueID = data
		local itemTable = catherine.item.FindByID( uniqueID )

		if ( !itemTable ) then
			catherine.util.Notify( pl, "Item is not valid!" )
			return
		end
		
		local vendorInv = table.Copy( self:GetVendorData( ent, "inv", { } ) )
		vendorInv[ uniqueID ] = nil
		self:SetVendorData( ent, "inv", vendorInv )
	end
end

function PLUGIN:CanUseVendor( pl, ent )
	if ( !IsValid( pl ) or !IsValid( ent ) or !ent.isVendor ) then return end
	
	if ( !ent.vendorData.status ) then
		//return false, "status" // 나중에 추가..
	end
	
	local factionData = ent.vendorData.factions
	if ( #factionData != 0 and !table.HasValue( factionData, pl:Team( ) ) ) then
		return false, "faction"
	end
	
	local classData = ent.vendorData.classes
	if ( #classData != 0 and !table.HasValue( classData, pl:Class( ) ) ) then
		return false, "class"
	end

	return true
end

function PLUGIN:DataLoad( )
	self:LoadVendors( )
end

function PLUGIN:DataSave( )
	self:SaveVendors( )
end

netstream.Hook( "catherine.plugin.vendor.VendorWork", function( pl, data )
	PLUGIN:VendorWork( pl, data[ 1 ], data[ 2 ], data[ 3 ] )
end )

netstream.Hook( "catherine.plugin.vendor.VendorClose", function( pl )
	pl:SetNetVar( "vendor_work", nil )
end )