--[[
	Exsto
	Copyright (C) 2013  Prefanatic

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

-- Exsto Boolean Choice

PANEL = {}

function PANEL:Init()
	self:SetValue( false )
end

function PANEL:DoClick()
	self._Value = not self._Value
end

function PANEL:SetValue( val )
	self._Value = tobool( val )
end

function PANEL:GetValue()
	return tobool( self._Value )
end

function PANEL:Paint()
	local w, h = self:GetSize()
	
	if self._Value then
		return self:GetSkin().tex.Input.ComboBox.Down( 0, 0, w, h )
	elseif self.Hovered then
		return self:GetSkin().tex.Input.ComboBox.Hover( 0, 0, w, h )
	else
		return self:GetSkin().tex.Input.ComboBox.Normal( 0, 0, w, h )
	end
	
	-- Snipped from ExButton
	-- Text
	local x = self:GetWide() / 2
	local y = self:GetTall() / 2
	
	--if self._AlignY == TEXT_ALIGN_TOP then y = y + self._YMod end
	
	draw.SimpleText( self:GetText(), self:GetFont() .. self:GetFontSize(), x, y, self:GetTextColor(), self._AlignX, self._AlignY )
end

derma.DefineControl( "ExBooleanChoice", "Exsto Boolean Choice", PANEL, "ExButton" )