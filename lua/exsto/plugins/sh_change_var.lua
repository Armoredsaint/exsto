-- Prefan Access Controller
-- Var changing plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Variable Changer",
	ID = "change-var",
	Desc = "A plugin that allows management over variables!",
	Owner = "Prefanatic",
} )

if SERVER then

	function PLUGIN:Init()
		exsto.CreateFlag( "vareditor", "Allows users to open the variable menu." )
	end

	function PLUGIN:CreateEnvVar( owner, dirty, value )
		
		-- If we are creating an existing one.
		local existing = exsto.GetVar( dirty )
		if existing then
			
			-- Check if it is an env var.  Update if it is.
			if existing.EnvVar == true then
				exsto.Variables[ dirty ].Value = value
				exsto.Variables[ dirty ].DataType = type( value )
				
				return { owner, COLOR.NORM, "Updating existing env var ", COLOR.NAME, dirty, COLOR.NORM, " with value: ", COLOR.NAME, value, COLOR.NORM, "!" }
			-- It is an existing Exsto hard-coded variable.  End it!
			else
				return { owner, COLOR.NORM, "An existing Exsto global variable already exists for ", COLOR.NAME, dirty, COLOR.NORM, "!" }
			end
			
		end
		
		-- Create it.
		exsto.AddEnvironmentVar( dirty, value )
		return { COLOR.NAME, owner:Nick(), COLOR.NORM, " has created a new environment variable: ", COLOR.NAME, dirty, COLOR.NORM, "!" }
			
	end
	PLUGIN:AddCommand( "createvar", {
		Call = PLUGIN.CreateEnvVar,
		Desc = "Allows users to create environment variables.",
		Console = { "createenv" },
		Chat = { "!createenv" },
		ReturnOrder = "Variable-Value",
		Args = {Variable = "STRING", Value = "STRING"},
		Category = "Variables",
	})
	
	function PLUGIN:DeleteEnvVar( owner, dirty )
		
		-- If we are an existing one.
		local existing = exsto.GetVar( dirty )
		if existing then
			if !existing.EnvVar then -- Oh god, dont do this
				return { owner, COLOR.NORM, "You cannot delete an ", COLOR.NAME, "environmental variable!" }
			end
			
			exsto.Variables[ dirty ] = nil
			
			exsto.VarDB:DropRow( dirty )
			return { COLOR.NAME, owner:Nick(), COLOR.NORM, " has deleted environmental variable: ", COLOR.NAME, dirty, COLOR.NORM, "!" }
		end
		
		return { owner, COLOR.NORM, "No existing environmental variable for ", COLOR.NAME, dirty, COLOR.NORM, "!" }
		
	end
	PLUGIN:AddCommand( "deletevar", {
		Call = PLUGIN.DeleteEnvVar,
		Desc = "Allows users to delete environment variables.",
		Console = { "deleteenv" },
		Chat = { "!deleteenv" },
		ReturnOrder = "Variable",
		Args = {Variable = "STRING"},
		Category = "Variables",
	})

	function PLUGIN:ChangeVar( owner, var, value )
	
		local variable = exsto.GetVar( var )
		
		if !variable then
			return { owner, COLOR.NORM, "There is no variable named ", COLOR.NAME, var, COLOR.NORM, "!" }
		end

		local done, returnData = exsto.SetVar( var, value )
		
		if done then
			if returnData then
				if type( returnData ) == "table" then
					return table.insert( { owner }, returnData )
				elseif type( returnData ) == "string" then
					return { owner, COLOR.NORM, returnData }
				end
			else
				return { COLOR.NAME, var, COLOR.NORM, " has been set to ", COLOR.NAME, value, COLOR.NORM, "!" }
			end
		else
			if !returnData then
				return { owner, COLOR.NORM, "The variables callback refuses the data set request!" }
			else
				if type( returnData ) == "table" then
					return table.insert( { owner }, returnData )
				elseif type( returnData ) == "string" then
					return { owner, COLOR.NORM, "Cannot change variable: " .. returnData }
				end
			end
		end
		
	end
	PLUGIN:AddCommand( "variable", {
		Call = PLUGIN.ChangeVar,
		Desc = "Allows users to change exsto variables.",
		Console = { "changevar" },
		Chat = { "!setvariable" },
		ReturnOrder = "Variable-Value",
		Args = {Variable = "STRING", Value = "STRING"},
		Category = "Variables",
	})
	
	function PLUGIN:GetVar( owner, var )
	
		local value = exsto.GetVar( var ).Value
		
		if !value then
			return { owner, COLOR.NORM, "There is no variable named ", COLOR.NAME, var, COLOR.NORM, "!" }
		else
			return { owner, COLOR.NAME, var, COLOR.NORM, " is set to ", COLOR.NAME, tostring( value ), COLOR.NORM, "!" }
		end
	end
	PLUGIN:AddCommand( "getvariable", {
		Call = PLUGIN.GetVar,
		Desc = "Allows users to view variable values.",
		Console = { "getvariable" },
		Chat = { "!getvariable" },
		ReturnOrder = "Variable",
		Args = {Variable = "STRING"},
		Category = "Variables",
	})
	
	local function SendVars( ply )

		for k,v in pairs( exsto.Variables ) do

			local sender = exsto.CreateSender( "ExRecVars", ply )
				sender:AddString( v.Dirty )
				sender:AddString( v.Pretty )
				sender:AddVariable( v.Value )
				sender:AddString( v.DataType )
				sender:AddString( v.Description )
				sender:AddBool( v.EnvVar )
				
				sender:AddShort( v.Possible and table.Count( v.Possible ) or 0 )
				for _, possible in ipairs( v.Possible ) do
					sender:AddVariable( possible )
				end
				sender:Send()
		end
		
		exsto.CreateSender( "ExRecVarsFinal", ply ):Send()
		
	end
	concommand.Add( "_RequestVars", SendVars )
	
	local function SetVar( ply, data )
		exsto.SetVar( data[1], data[2] )
	end
	exsto.ClientHook( "ExRecVarChange", SetVar )
	
elseif CLIENT then

	-- TODO: Refresh this editor if variables are changed.
		-- Check and make sure the ID belongs to the currently selected page.  If so, refresh and reselect.  If not, refresh anyways.

	local function onShowtime( pnl )
		pnl.Content.Select:Populate()
	end

	local function selectPopulate( pnl )
		pnl:Clear()
		
		local tmp = {}
		for id, data in pairs( exsto.ServerVariables ) do
			if !tmp[ data.Category ] then tmp[ data.Category ] = {} end
			table.insert( tmp[ data.Category ], id )
		end
		
		for cat, data in pairs( tmp ) do
			pnl:AddChoice( cat, data )
		end
	end
	
	local function selectSelected( box, index, value, data )
		local page = PLUGIN.Page.Content
		if !page.Objects then page.Objects = {} end
		
		-- Clear the old objects.
		for _, obj in ipairs( page.Objects ) do
			obj:Remove()
		end
		page.Objects = {}
		
		-- Now, we need to loop through all of our data and create objects for each of these things.  Cross your fingers.
		local data
		for _, id in ipairs( data ) do
			data = exsto.ServerVariables[ id ] -- So this is 'live' so to speak
		
			-- If we're a boolean
			if data.Maximum == 1 and data.Minimum == 0 then
				local obj = vgui.Create( "ExBooleanChoice", page.Cat )
					obj:Dock( TOP )
					obj:DockMargin( 0, 4, 0, 0 )
					obj:SetTall( 32 )
					obj:SetText( data.Display )
					obj:SetValue( data.Value )
					
				table.insert( page.Objects, obj )
			elseif data.Type == "string" then -- If we require a text box!
				local obj = vgui.Create( "DTextEntry", page.Cat )
					obj:Dock( TOP )
					obj:DockMargin( 0, 4, 0, 0 )
					obj:SetTall( 32 )
					obj:SetText( data.Value )
					
				table.insert( page.Objects, obj )
			elseif data.Type == "number" then -- Anddd WANG IT.
				local obj = vgui.Create( "ExNumberChoice", page.Cat )
					obj:Dock( TOP )
					obj:DockMargin( 0, 4, 0, 0 )
					obj:SetTall( 32 )
					-- TODO
					
				table.insert( page.Objects, obj )
			end
			
		end

		page.Cat:InvalidateLayout( true )
	end

	local function settingsInit( pnl )
		pnl.Cat = pnl:CreateCategory( "Settings" )
			pnl.Cat:DockMargin( 4, 0, 4, 0 )
		
		pnl.Select = vgui.Create( "ExComboBox", pnl.Cat )
			pnl.Select:Dock( TOP )
			pnl.Select:SetTall( 32 )
			pnl.Select.Populate = selectPopulate
			pnl.Select.OnSelect = selectSelected
			
		pnl.Cat:InvalidateLayout( true )
	end

	function PLUGIN:Init()
		self.Page = exsto.Menu.CreatePage( "settings", settingsInit )
			self.Page:SetTitle( "Settings" )
			self.Page:SetSearchable( true )
			self.Page:OnShowtime( onShowtime )
	end
	
end
 
PLUGIN:Register()