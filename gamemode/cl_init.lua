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

catherine = catherine or GM
catherine.vgui = catherine.vgui or { }

include( "shared.lua" )

timer.Remove( "HintSystem_Annoy1" )
timer.Remove( "HintSystem_Annoy2" )
timer.Remove( "HintSystem_OpeningMenu" )

hook.Add( "AddHelpItem", "catherine.AddHelpItem.01", function( data )
	data:AddItem( "Credit", [[<b>Credit</b><br><br>
		<b>L7D</b><br>Develop and Design.<br><br>
		<b>Chessnut</b><br>Good helper.<br><br>
		<b>Kyle Smith</b><br>UTF-8 module.<br><br>
		<b>thelastpenguin™</b><br>pON module.<br><br>
		<b>Alexander Grist-Hucker</b><br>netstream 2 module.<br><br><br>
		
		<b>Thanks for using Catherine!</b>
	]] )
	data:AddItem( "Changelog", "http://github.com/L7D/Catherine/commits/master" )
end )