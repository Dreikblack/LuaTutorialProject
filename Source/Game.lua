local function GameMenuButtonCallback(Event, Extra)
	if (KEY_ESCAPE == Event.data and Extra) then
		local game = Extra
		local isHidden = game.menuPanel:GetHidden()
		game.menuPanel:SetHidden(not isHidden)
		if isHidden then
			window:SetCursor(CURSOR_DEFAULT)
		else
			window:SetCursor(CURSOR_NONE)
		end
		if (game.player ~= nil) then
			--to stop cursor reset to center when menu on
			game.player.doResetMousePosition = not isHidden
		end
	end
	return false
end

local function MainMenuButtonCallback(Event, Extra)
	EmitEvent(EVENT_MAIN_MENU)
	return true
end

local function ExitButtonCallback(Event, Extra)
	os.exit()
	return true
end

local function InitGame(game, mapPath) 
	game.world = CreateWorld();
	game.scene = LoadScene(game.world, mapPath)
	for k, entity in pairs(game.scene.entities) do
		local foundPlayer = entity:GetComponent("FPSPlayer")
		if (foundPlayer ~= nil) then
			game.player = foundPlayer;
			break;
		end
	end
	--Create user interface for game menu
	local frameSize = framebuffer:GetSize()
	game.ui = CreateInterface(game.world, font, frameSize)
	game.ui:SetRenderLayers(2)
	game.ui.background:SetColor(0.0, 0.0, 0.0, 0.0)
	game.uiCamera = CreateCamera(game.world, PROJECTION_ORTHOGRAPHIC)
	game.uiCamera:SetPosition(frameSize.x * 0.5, frameSize.y * 0.5, 0)
	game.uiCamera:SetRenderLayers(2);
	game.uiCamera:SetClearMode(CLEAR_DEPTH);
	--widgets are stays without extra pointers because parent widet, game.ui.background in this case, keep them
	--to remove widget you should do widget:SetParent(nil)
	game.menuPanel = CreatePanel(frameSize.x / 2 - 150, frameSize.y / 2 - 125 / 2, 300, 250, game.ui.background)
	local menuButton = CreateButton("Main menu", 50, 50, 200, 50, game.menuPanel);
	ListenEvent(EVENT_WIDGETACTION, menuButton, MainMenuButtonCallback);
	local exitButton = CreateButton("Exit", 50, 150, 200, 50, game.menuPanel);
	ListenEvent(EVENT_WIDGETACTION, exitButton, ExitButtonCallback);
 	--we don't need game menu on screen while playing
 	game.menuPanel:SetHidden(true);
	--and we will need it once hitting Esc button
	ListenEvent(EVENT_KEYUP, window, GameMenuButtonCallback, game);
end

--functions should be declared after another function that this fucntion uses
function CreateGame(mapPath) 
    local game = {}
	InitGame(game, mapPath)
	return game
end