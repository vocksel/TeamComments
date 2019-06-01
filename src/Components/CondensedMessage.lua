local Roact = require(script.Parent.Parent.Lib.Roact)
local t = require(script.Parent.Parent.Lib.t)
local Types = require(script.Parent.Parent.Types)
local Colors = require(script.Parent.Parent.Colors)
local Styles = require(script.Parent.Parent.Styles)
local StudioThemeAccessor = require(script.Parent.StudioThemeAccessor)
local Padding = require(script.Parent.Padding)
local Avatar = require(script.Parent.Avatar)
local MessageMeta = require(script.Parent.MessageMeta)
local MessageBody = require(script.Parent.MessageBody)
local MessageActions = require(script.Parent.MessageActions)

local Props = t.interface({
	height = t.integer,
	layoutOrder = t.integer,
	message = Types.IMessage
})

-- TODO: Clicking a CondensedMessage takes you to that message in the world

local AVATAR_SIZE = 48

local function CondensedMessage(props)
	assert(Props(props))

	return StudioThemeAccessor.withTheme(function(theme)
		return Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, props.height),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = props.layoutOrder,
		}, {
			Layout = Roact.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
			}),

			Padding = Roact.createElement(Padding),

			Avatar = Roact.createElement(Avatar, {
				userId = props.message.authorId,
				size = UDim2.new(0, AVATAR_SIZE, 0, AVATAR_SIZE),
				maskColor = theme:getColor("MainBackground"),
				layoutOrder = 1,
			}),

			Main = Roact.createElement("Frame", {
				-- The X offset is to account for the avatar
				Size = UDim2.new(1, -AVATAR_SIZE, 1, 0),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				Layout = Roact.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, Styles.Padding),
				}),

				Padding = Roact.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, Styles.Padding)
				}),

				Meta = Roact.createElement(MessageMeta, {
					message = props.message,
					size = UDim2.new(1, 0, 0, Styles.HeaderTextSize),
					layoutOrder = 1,
				}),

				Body = Roact.createElement(MessageBody, {
					message = props.message,
					size = UDim2.new(1, 0, 0, Styles.TextSize*2),
					layoutOrder = 2,
					isTruncated = true,
				}),

				Actions = Roact.createElement(MessageActions, {
					message = props.message,
					size = UDim2.new(1, 0, 0, 20),
					layoutOrder = 3,
				})
			})
		})
	end)
end

return CondensedMessage
