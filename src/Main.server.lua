
-- Button
-- When pressed, prompt the user with a textbox
	-- Type inside, press enter to finish
	-- Unfocusing the textbox destroys it
-- Creates a new free floating billboard with the text
	-- Will also maintain metadata of who wrote the message, the date/time, and a little avatar.

-- List of all notes
	-- Clicking a note jumps to it in the game
	-- Let author edit
	-- Allow deleting notes

-- Have all WorldMessages stored as Parts in the workspace
-- When Studio boots up, create state out of all the WorldMessages' Value instances
-- 	When a new "WorldMessage" tagged Part is added, add a new one
-- 	When a WorldMessage tagged part is destroyed, remove it from the state
-- 	When a WorldMessage is removed from the state, remove it from the game as well (link via IDs)

local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local Roact = require(script.Parent.Lib.Roact)
local Rodux = require(script.Parent.Lib.Rodux)
local StoreProvider = require(script.Parent.Lib.RoactRodux).StoreProvider
local Messages = require(script.Parent.Messages)
local Reducer = require(script.Parent.Reducer)
local Config = require(script.Parent.Config)
local WorldMessages = require(script.Parent.Components.WorldMessages)
local CreateMessage = require(script.Parent.Actions.CreateMessage)
local DeleteMessage = require(script.Parent.Actions.DeleteMessage)
local SetMessageBody = require(script.Parent.Actions.SetMessageBody)
local ToggleMessagesVisibility = require(script.Parent.Actions.ToggleMessagesVisibility)

local toolbar = plugin:CreateToolbar("World Messages")
local clientId = tostring(plugin:GetStudioUserId())
local store = Rodux.Store.new(Reducer)

local function onMessagePartAdded(messagePart)
	Messages.runIfValid(messagePart, function()
		store:dispatch(CreateMessage(messagePart.Id.Value, messagePart.AuthorId.Value, messagePart.Time.Value))
		store:dispatch(SetMessageBody(messagePart.Id.Value, messagePart.Body.Value))
	end)
end

local function onMessagePartRemoved(messagePart)
	Messages.runIfValid(messagePart, function()
		store:dispatch(DeleteMessage(messagePart.Id.Value))
	end)
end

local function setupInitialState()
	for _, messagePart in pairs(CollectionService:GetTagged(Config.TAG_NAME)) do
		onMessagePartAdded(messagePart)
	end

	CollectionService:GetInstanceAddedSignal(Config.TAG_NAME):Connect(onMessagePartAdded)

	CollectionService:GetInstanceRemovedSignal(Config.TAG_NAME):Connect(onMessagePartRemoved)
end

-- TODO: Replace buttons with just a widget. Will have add, visibility filter,
-- and full list of messages
local function createButtons()
	-- TODO: Create actions for the buttons so that we can set keybinds for
	-- them. Like Ctrl+Alt+M in Google Docs.
	local newMessageButton = toolbar:CreateButton(
		"New message",
		"Creates a new message in the world for others to read",
		""
	)

	local toggleMessageVisibilityButton = toolbar:CreateButton(
		"Toggle visibility",
		"Shows or hides all of the messages in the world",
		""
	)

	newMessageButton.Click:Connect(function()
		local messageId = HttpService:GenerateGUID()

		-- TODO: Make the position about 5 studs in front of the user's camera
		-- so it's easier to author messages. Also, the 5 studs will be the max.
		-- If there's anything in the way, push it closer (ray cast to check)
		local position = workspace.CurrentCamera.CFrame.p

		Messages.createMessagePart(messageId, clientId, position)
	end)

	toggleMessageVisibilityButton.Click:Connect(function()
		store:dispatch(ToggleMessagesVisibility())
	end)
end

local function createInterface()
	-- so now we have actual state to go off of for the messages. time to leverage that!

	local billboardsRoot = Roact.createElement(StoreProvider, {
		store = store
	}, {
		Roact.createElement(WorldMessages)
	})

	Roact.mount(billboardsRoot, CoreGui, "WorldMessages")
end

setupInitialState()
createButtons()
createInterface()

print("loaded!")