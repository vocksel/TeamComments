local TeamComments = script:FindFirstAncestor("TeamComments")

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")

local Roact = require(TeamComments.Packages.Roact)
local t = require(TeamComments.Packages.t)
local Immutable = require(TeamComments.Lib.Immutable)
local Config = require(TeamComments.Config)
local types = require(TeamComments.Types)

local MessageContext = Roact.createContext()

local MessageProvider = Roact.Component:extend("MessageProvider")

MessageProvider.validateProps = t.interface({
	messageTag = t.optional(t.string),
	responseTag = t.optional(t.string),
	storageTag = t.optional(t.string),
})

MessageProvider.defaultProps = {
	messageTag = Config.TAG_NAME,
	responseTag = Config.RESPONSE_TAG_NAME,
	storageTag = Config.STORAGE_TAG_NAME,
}

function MessageProvider:init()
	self.state = {
		messages = {},
	}

	self._getOrCreateBaseStorage = function()
		local storage = CollectionService:GetTagged(self.props.storageTag)[1]

		if not storage then
			storage = Instance.new("Folder")
			storage.Name = "TeamComments"
			storage.Parent = workspace

			CollectionService:AddTag(storage, self.props.storageTag)
		end

		return storage
	end

	self._saveMessageToInstance = function(message, instance)
		for key, value in pairs(message) do
			if typeof(value) ~= "table" then
				instance:SetAttribute(key, value)
			end
		end
	end

	self._loadMessageFromInstance = function(instance)
		local message = {
			responses = {},
		}

		for key, value in pairs(instance:GetAttributes()) do
			message[key] = value
		end

		if CollectionService:HasTag(instance.Parent, self.props.messageTag) then
			message.parentId = instance.Parent:GetAttribute("id")
		else
			for _, child in ipairs(instance:GetChildren()) do
				local response = self._loadMessageFromInstance(child)
				table.insert(message.responses, response.id)
				self._addResponseState(message, response)
			end
		end

		return message
	end

	self._createResponseInstance = function(parentId, message)
		local adornee = self.getAdornee(parentId)
		local dialog = Instance.new("Dialog")
		dialog.Name = ("Response_%i"):format(message.createdAt)
		dialog.Parent = adornee

		return dialog
	end

	self._createAdornee = function(message)
		assert(types.Message(message))

		local part = Instance.new("Part")
		part.Name = ("TeamComment_%i"):format(message.createdAt)
		part.Anchored = true
		part.Locked = true
		part.CanCollide = false
		part.CanTouch = false
		part.Transparency = 1
		-- Normally we would use Position, but this forces the Part to exist
		-- inside another, without being pushed up on top.
		part.CFrame = CFrame.new(message.position)
		part.Size = Vector3.new(0, 0, 0)
		part.Parent = self._getOrCreateBaseStorage()

		return part
	end

	self.getAdornee = function(messageId)
		for _, adornee in pairs(CollectionService:GetTagged(self.props.messageTag)) do
			if adornee:GetAttribute("id") == messageId then
				return adornee
			end
		end
	end

	self.focusAdornee = function(messageId)
		local adornee = self.getAdornee(messageId)

		if adornee then
			local camera = workspace.CurrentCamera
			local orientation = camera.CFrame - camera.CFrame.p
			local newCFrame = CFrame.new(adornee.Position) * orientation

			camera.Focus = adornee.CFrame
			camera.CFrame = newCFrame * CFrame.new(-Config.PUSHBACK_FROM_FOCUS, 0, 0)
		end
	end

	self._addMessageState = function(message)
		self:setState(function(prev)
			return {
				messages = Immutable.join(prev.messages, {
					[message.id] = message,
				}),
			}
		end)
	end

	self._addResponseState = function(parent, message)
		self:setState(function(prev)
			local newParent = Immutable.join(parent, {
				responses = Immutable.join(parent.responses, {
					message.id,
				}),
			})

			return {
				messages = Immutable.join(prev.messages, {
					[parent.id] = newParent,
					[message.id] = message,
				}),
			}
		end)
	end

	self.comment = function(message)
		assert(types.Message(message))

		local adornee = self._createAdornee(message)

		self._addMessageState(message)
		self._saveMessageToInstance(message, adornee)

		CollectionService:AddTag(adornee, self.props.messageTag)
	end

	self.respond = function(parent, message)
		assert(t.tuple(types.Message, types.Message)(parent, message))

		local dialog = self._createResponseInstance(parent.id, message)

		self._addResponseState(parent, message)
		self._saveMessageToInstance(message, dialog)

		CollectionService:AddTag(dialog, self.props.responseTag)
	end

	self.deleteMessage = function(messageId)
		self:setState(function(state)
			return {
				messages = Immutable.set(state.messages, messageId, nil),
			}
		end)

		local adornee = self.getAdornee(messageId)

		if adornee then
			ChangeHistoryService:SetWaypoint("Deleting message...")
			adornee.Parent = nil
			ChangeHistoryService:SetWaypoint("Deleted message")
		end
	end

	-- Sorts the messages by the time they were created. Returns an array of
	-- each message in order from newest to oldest. This is used to display the
	-- list of messages in the plugin.
	self.getOrderedMessages = function()
		local messages = {}

		for _, message in pairs(self.state.messages) do
			table.insert(messages, message)
		end

		table.sort(messages, function(a, b)
			return a.createdAt > b.createdAt
		end)

		return messages
	end

	self.getMessages = function()
		return self.state.messages
	end

	self.setSelectedMessage = function(messageId)
		self:setState({
			selectedMessageId = messageId or Roact.None,
		})
	end

	self.getSelectedMessage = function()
		return self.state.messages[self.state.selectedMessageId]
	end
end

function MessageProvider:render()
	return Roact.createElement(MessageContext.Provider, {
		value = {
			getMessages = self.getMessages,
			comment = self.comment,
			respond = self.respond,
			deleteMessage = self.deleteMessage,
			getOrderedMessages = self.getOrderedMessages,
			getAdornee = self.getAdornee,
			focusAdornee = self.focusAdornee,
			setSelectedMessage = self.setSelectedMessage,
			getSelectedMessage = self.getSelectedMessage,
		},
	}, self.props[Roact.Children])
end

function MessageProvider:didMount()
	local function onAdded(adornee: Part)
		local message = self._loadMessageFromInstance(adornee)
		self._addMessageState(message)
	end

	local function onRemoved(adornee)
		self.deleteMessage(adornee:GetAttribute("id"))
	end

	for _, adornee in ipairs(CollectionService:GetTagged(self.props.messageTag)) do
		onAdded(adornee)
	end

	self.onAddedConn = CollectionService:GetInstanceAddedSignal(self.props.messageTag):Connect(onAdded)
	self.onRemovedConn = CollectionService:GetInstanceRemovedSignal(self.props.messageTag):Connect(onRemoved)
end

function MessageProvider:willUnmount()
	self.onAddedConn:Disconnect()
	self.onRemovedConn:Disconnect()
end

return {
	Consumer = MessageContext.Consumer,
	Provider = MessageProvider,
}
