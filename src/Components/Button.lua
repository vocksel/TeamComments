local TeamComments = script:FindFirstAncestor("TeamComments")

local Roact = require(TeamComments.Packages.Roact)
local t = require(TeamComments.Packages.t)
local Styles = require(TeamComments.Styles)
local StudioThemeAccessor = require(script.Parent.StudioThemeAccessor)

local Props = t.interface({
	text = t.string,
	LayoutOrder = t.interger,
	size = t.optional(t.UDim2),
	onClick = t.callback,
})

local function Button(props)
	assert(Props(props))

	return StudioThemeAccessor.withTheme(function(theme)
		return Roact.createElement("TextButton", {
			Text = props.text,
			TextSize = Styles.TextSize - 2,
			Font = Styles.HeaderFont,
			LayoutOrder = props.LayoutOrder,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button),
			Size = props.size or UDim2.new(0, 48, 1, 0),
			[Roact.Event.MouseButton1Click] = props.onClick,
		})
	end)
end

return Button
