import "Source/MainMenu.lua"
import "Source/Game.lua"

--custom events ids  
EVENT_GAME_START = 1001
EVENT_MAIN_MENU = 1002

-- local before variable means it will be avaiable only in current scope (inside script, funtion, cycle or condition body)
-- loading screen vars
local loadingWorld = nil
local loadingCamera = nil
local loadingText = nil
local loadingBackground = nil

-- for using in main loop
local currentWorld = nil
local currentUi = nil

local menu = nil
local game = nil

framebuffer = nil

local function StartGameEventCallback(Event, Extra) 
    --destroying a main menu
	menu = nil
  	--to show loading screen
	loadingWorld:Render(framebuffer)
    if Event.text ~= nil and Event.text ~= "" then
        --in lua .. used for string concatenation
        game = CreateGame("Maps/" .. Event.text);
    else
        game = CreateGame("Maps/strategy.ultra");
    end
	--switching current render and update targets for loop
	currentWorld = game.world
	currentUi = game.ui
	return true;
end

--function should be declared after vars that this function uses
local function MainMenuEventCallback(Event, Extra) 
    --destroying a game instance if one existed
    game = nil
    --to show loading screen
    loadingWorld:Render(framebuffer)
	menu = CreateMainMenu()
	--switching current render and update targets for loop
	currentWorld = menu.world;
	currentUi = menu.ui;
	return true;
end

local displays = GetDisplays()
-- You can WINDOW_FULLSCREEN to styles to make game fullscreen, 3rd and 4th are resolution size
window = CreateWindow("Ultra Engine", 0, 0, 1280, 720, displays[1], WINDOW_CENTER | WINDOW_TITLEBAR)
-- Create a framebuffer, needed for rendering
framebuffer = CreateFramebuffer(window)
font = LoadFont("Fonts/arial.ttf");

loadingWorld = CreateWorld();
local centerX = framebuffer:GetSize().x * 0.5
local centerY = framebuffer:GetSize().y * 0.5
local labelHeight = framebuffer:GetSize().y * 0.2
loadingBackground = CreateSprite(loadingWorld, framebuffer.size.x, framebuffer.size.y)
loadingBackground:SetColor(0.2, 0.2, 0.2);
loadingBackground:SetRenderLayers(2);
loadingBackground:SetPosition(centerX, centerY, 0)
loadingText = CreateSprite(loadingWorld, font, "LOADING", labelHeight, TEXT_CENTER | TEXT_MIDDLE)
loadingText:SetPosition(centerX, centerY + labelHeight * 0.5, 0)
-- 0 layer - no render, 1 - default render, we will use 2 for UI and sprites
loadingText:SetRenderLayers(2)

-- Creating camera for sprites, which needs to be orthographic (2D) for UI and sprites if they used as UI
loadingCamera = CreateCamera(loadingWorld, PROJECTION_ORTHOGRAPHIC);
loadingCamera:SetPosition(centerX, centerY, 0);
-- camera render layer should match with stuff that you want to be visible for this camera. RenderLayers is a bit mask, so you can combine few layers, but probably you don't need it in most cases
loadingCamera:SetRenderLayers(2)

currentWorld = loadingWorld

--to show Loading screen before Main Menu
loadingWorld:Render(framebuffer);

--ListenEvent are needed to do something in callback function when specific even from specfic source (or not, if 2nd param is nil) emitted
ListenEvent(EVENT_GAME_START, nil, StartGameEventCallback);
ListenEvent(EVENT_MAIN_MENU, nil, MainMenuEventCallback);
--let's try it out! 
EmitEvent(EVENT_MAIN_MENU)

-- simple minimum game loop
while window:Closed() == false do
    -- Garbage collection step
    collectgarbage()
    -- getting all events from queue - input, UI etc. 
    while (PeekEvent()) do
        local event = WaitEvent()
        -- You need to do it for UI in 3D scene
        if (currentUi) then
            currentUi:ProcessEvent(event)
        end
    end
    if (currentWorld) then
        -- Update game logic (positions, components etc.). By default 60 HZ and not depends on framerate if you have 60+ FPS
        currentWorld:Update()
        -- 2nd param is VSync (true by default), 3rd is fps limit. Can by changed dynamically.
        currentWorld:Render(framebuffer)
    end
end