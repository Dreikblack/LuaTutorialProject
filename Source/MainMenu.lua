local function NewGameButtonCallback(Event, Extra)
	--this overload currently is not working
    --EmitEvent(EVENT_GAME_START, nil, 0, 0, 0, 0, 0, nil, "start.ultra")
	EmitEvent(EVENT_GAME_START)
	return true
end

local function ExitButtonCallback(Event, Extra)
    --to close application
	os.exit()
	return true
end

local function InitMainMenu(mainMenu) 
	mainMenu.world = CreateWorld();
	mainMenu.scene = LoadMap(mainMenu.world, "Maps/menu.ultra")
	--Create user interface
	local frameSize = framebuffer:GetSize();
	--Create camera for GUI
	mainMenu.uiCamera = CreateCamera(mainMenu.world, PROJECTION_ORTHOGRAPHIC)
	mainMenu.uiCamera:SetPosition(frameSize.x * 0.5, frameSize.y * 0.5, 0);
	mainMenu.uiCamera:SetRenderLayers(2);
	mainMenu.ui = CreateInterface(mainMenu.uiCamera, font, frameSize)
	mainMenu.ui:SetRenderLayers(2);
	--to make backgrount transparent
	mainMenu.ui.background:SetColor(0.0, 0.0, 0.0, 0.0)
	--for correct rendering above 3D scene
	mainMenu.uiCamera:SetClearMode(CLEAR_DEPTH);
	--Menu buttons
	local newGameButton = CreateButton("New game", frameSize.x / 2 - 100, 125, 200, 50, mainMenu.ui.background);
	ListenEvent(EVENT_WIDGETACTION, newGameButton, NewGameButtonCallback);
	local exitButton = CreateButton("Exit", frameSize.x / 2 - 100, 200, 200, 50, mainMenu.ui.background);
	ListenEvent(EVENT_WIDGETACTION, exitButton, ExitButtonCallback);
end

--functions should be declared after another function that this fucntion uses
function CreateMainMenu() 
    local mainMenu = {}
	InitMainMenu(mainMenu)
	return mainMenu
end