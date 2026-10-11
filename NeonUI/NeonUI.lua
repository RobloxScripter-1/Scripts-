--!strict
-- NeonUI: a lightweight, client-side Roblox UI library.
-- Designed for LocalScripts/ModuleScripts in experiences you own.
-- No executor APIs, external dependencies, or background polling loops.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Library = {}
Library.__index = Library

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local THEME = {
    Background = Color3.fromRGB(8, 11, 18),
    Surface = Color3.fromRGB(13, 18, 28),
    Surface2 = Color3.fromRGB(18, 25, 38),
    Stroke = Color3.fromRGB(35, 73, 125),
    Accent = Color3.fromRGB(0, 170, 255),
    Accent2 = Color3.fromRGB(65, 205, 255),
    Text = Color3.fromRGB(235, 245, 255),
    Muted = Color3.fromRGB(145, 165, 190),
    Good = Color3.fromRGB(50, 220, 150),
}

local function tween(instance: Instance, info: TweenInfo, props: {[string]: any})
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

local FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MED = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function corner(parent: Instance, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function stroke(parent: Instance, color: Color3, thickness: number, transparency: number?)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local function padding(parent: Instance, value: number)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, value)
    p.PaddingBottom = UDim.new(0, value)
    p.PaddingLeft = UDim.new(0, value)
    p.PaddingRight = UDim.new(0, value)
    p.Parent = parent
    return p
end

local function makeLabel(parent: Instance, text: string, size: number, color: Color3, bold: boolean?)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color
    l.TextSize = size
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function signal()
    local bindable = Instance.new("BindableEvent")
    return {
        Connect = function(_, fn) return bindable.Event:Connect(fn) end,
        Fire = function(_, ...) bindable:Fire(...) end,
        Destroy = function() bindable:Destroy() end,
    }
end

function Library.new(options)
    options = options or {}
    local self = setmetatable({}, Library)
    self._connections = {}
    self._destroyed = false
    self.Theme = options.Theme or THEME
    self._windows = {}
    return self
end

function Library:_connect(connection)
    table.insert(self._connections, connection)
    return connection
end

function Library:CreateWindow(options)
    options = options or {}
    local player = Players.LocalPlayer
    assert(player, "NeonUI must run from a LocalScript")

    local gui = Instance.new("ScreenGui")
    gui.Name = options.Name or "NeonUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = player:WaitForChild("PlayerGui")

    local root = Instance.new("Frame")
    root.Name = "Window"
    root.Size = options.Size or UDim2.fromOffset(650, 430)
    root.Position = UDim2.new(0.5, -325, 0.5, -215)
    root.BackgroundColor3 = self.Theme.Background
    root.BorderSizePixel = 0
    root.ClipsDescendants = true
    root.Parent = gui
    corner(root, 12)
    stroke(root, self.Theme.Stroke, 1, 0.15)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 48)
    top.BackgroundColor3 = self.Theme.Surface
    top.BorderSizePixel = 0
    top.Parent = root

    local title = makeLabel(top, options.Name or "NeonUI", 16, self.Theme.Text, true)
    title.Position = UDim2.fromOffset(16, 7)
    title.Size = UDim2.new(1, -120, 0, 20)

    local subtitle = makeLabel(top, options.Subtitle or "Blue Edition", 11, self.Theme.Muted, false)
    subtitle.Position = UDim2.fromOffset(17, 27)
    subtitle.Size = UDim2.new(1, -120, 0, 15)

    local minimize = Instance.new("TextButton")
    minimize.Size = UDim2.fromOffset(34, 34)
    minimize.Position = UDim2.new(1, -78, 0, 7)
    minimize.BackgroundColor3 = self.Theme.Surface2
    minimize.Text = "−"
    minimize.TextColor3 = self.Theme.Text
    minimize.TextSize = 20
    minimize.Font = Enum.Font.GothamBold
    minimize.AutoButtonColor = false
    minimize.Parent = top
    corner(minimize, 8)

    local close = minimize:Clone()
    close.Name = "Close"
    close.Position = UDim2.new(1, -40, 0, 7)
    close.Text = "×"
    close.Parent = top

    local body = Instance.new("Frame")
    body.Position = UDim2.fromOffset(0, 48)
    body.Size = UDim2.new(1, 0, 1, -48)
    body.BackgroundTransparency = 1
    body.Parent = root

    local tabs = Instance.new("ScrollingFrame")
    tabs.Size = UDim2.fromOffset(150, 1)
    tabs.Position = UDim2.fromOffset(8, 8)
    tabs.BackgroundColor3 = self.Theme.Surface
    tabs.BorderSizePixel = 0
    tabs.ScrollBarThickness = 2
    tabs.ScrollBarImageColor3 = self.Theme.Accent
    tabs.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabs.CanvasSize = UDim2.new()
    tabs.Parent = body
    corner(tabs, 10)
    padding(tabs, 7)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabs

    local content = Instance.new("Frame")
    content.Position = UDim2.fromOffset(166, 8)
    content.Size = UDim2.new(1, -174, 1, -16)
    content.BackgroundColor3 = self.Theme.Surface
    content.BorderSizePixel = 0
    content.Parent = body
    corner(content, 10)

    local w = setmetatable({
        Library = self,
        Gui = gui,
        Root = root,
        Body = body,
        Tabs = tabs,
        Content = content,
        _tabObjects = {},
        _activeTab = nil,
        _minimized = false,
        _fullSize = root.Size,
    }, Window)

    local dragging = false
    local dragStart: Vector2
    local startPos: UDim2
    self:_connect(top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = root.Position
        end
    end))
    self:_connect(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end))
    self:_connect(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))

    minimize.MouseEnter:Connect(function() tween(minimize, FAST, {BackgroundColor3 = self.Theme.Accent}) end)
    minimize.MouseLeave:Connect(function() tween(minimize, FAST, {BackgroundColor3 = self.Theme.Surface2}) end)
    close.MouseEnter:Connect(function() tween(close, FAST, {BackgroundColor3 = Color3.fromRGB(210, 60, 80)}) end)
    close.MouseLeave:Connect(function() tween(close, FAST, {BackgroundColor3 = self.Theme.Surface2}) end)

    self:_connect(minimize.MouseButton1Click:Connect(function()
        w._minimized = not w._minimized
        body.Visible = not w._minimized
        root.Size = w._minimized and UDim2.fromOffset(w._fullSize.X.Offset, 48) or w._fullSize
    end))
    self:_connect(close.MouseButton1Click:Connect(function() w:Destroy() end))

    if options.ToggleKey then
        self:_connect(UserInputService.InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == options.ToggleKey then gui.Enabled = not gui.Enabled end
        end))
    end

    table.insert(self._windows, w)
    return w
end

function Window:CreateTab(options)
    options = options or {}
    local tabButton = Instance.new("TextButton")
    tabButton.Size = UDim2.new(1, 0, 0, 34)
    tabButton.BackgroundColor3 = self.Library.Theme.Surface2
    tabButton.BackgroundTransparency = 0.35
    tabButton.Text = "  " .. (options.Name or "Tab")
    tabButton.TextColor3 = self.Library.Theme.Muted
    tabButton.TextSize = 12
    tabButton.Font = Enum.Font.GothamMedium
    tabButton.TextXAlignment = Enum.TextXAlignment.Left
    tabButton.AutoButtonColor = false
    tabButton.Parent = self.Tabs
    corner(tabButton, 7)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -16, 1, -16)
    page.Position = UDim2.fromOffset(8, 8)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = self.Library.Theme.Accent
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new()
    page.Visible = false
    page.Parent = self.Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 9)
    layout.Parent = page

    local tab = setmetatable({Window = self, Button = tabButton, Page = page, Sections = {}}, Tab)
    table.insert(self._tabObjects, tab)

    tabButton.MouseEnter:Connect(function()
        if self._activeTab ~= tab then tween(tabButton, FAST, {BackgroundTransparency = 0.05, TextColor3 = self.Library.Theme.Text}) end
    end)
    tabButton.MouseLeave:Connect(function()
        if self._activeTab ~= tab then tween(tabButton, FAST, {BackgroundTransparency = 0.35, TextColor3 = self.Library.Theme.Muted}) end
    end)
    tabButton.MouseButton1Click:Connect(function() self:SelectTab(tab) end)

    if not self._activeTab then self:SelectTab(tab) end
    return tab
end

function Window:SelectTab(tab)
    for _, other in ipairs(self._tabObjects) do
        local active = other == tab
        other.Page.Visible = active
        tween(other.Button, FAST, {
            BackgroundColor3 = active and self.Library.Theme.Accent or self.Library.Theme.Surface2,
            BackgroundTransparency = active and 0 or 0.35,
            TextColor3 = active and Color3.new(1, 1, 1) or self.Library.Theme.Muted,
        })
    end
    self._activeTab = tab
end

function Tab:CreateSection(name)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -2, 0, 40)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundColor3 = self.Window.Library.Theme.Background
    frame.BorderSizePixel = 0
    frame.Parent = self.Page
    corner(frame, 9)
    stroke(frame, self.Window.Library.Theme.Stroke, 1, 0.35)
    padding(frame, 10)

    local title = makeLabel(frame, name, 13, self.Window.Library.Theme.Text, true)
    title.Size = UDim2.new(1, 0, 0, 20)

    local holder = Instance.new("Frame")
    holder.Position = UDim2.fromOffset(0, 25)
    holder.Size = UDim2.new(1, 0, 0, 0)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.BackgroundTransparency = 1
    holder.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.Parent = holder

    local section = setmetatable({Tab = self, Frame = frame, Holder = holder}, Section)
    table.insert(self.Sections, section)
    return section
end

function Section:_buttonBase(name)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 36)
    b.BackgroundColor3 = self.Tab.Window.Library.Theme.Surface2
    b.Text = name
    b.TextColor3 = self.Tab.Window.Library.Theme.Text
    b.TextSize = 12
    b.Font = Enum.Font.GothamMedium
    b.AutoButtonColor = false
    b.Parent = self.Holder
    corner(b, 7)
    return b
end

function Section:CreateButton(options)
    options = options or {}
    local b = self:_buttonBase(options.Name or "Button")
    b.MouseEnter:Connect(function() tween(b, FAST, {BackgroundColor3 = self.Tab.Window.Library.Theme.Accent}) end)
    b.MouseLeave:Connect(function() tween(b, FAST, {BackgroundColor3 = self.Tab.Window.Library.Theme.Surface2}) end)
    b.MouseButton1Click:Connect(function() if options.Callback then options.Callback() end end)
    return {Instance = b}
end

function Section:CreateToggle(options)
    options = options or {}
    local value = options.CurrentValue == true
    local b = self:_buttonBase(options.Name or "Toggle")
    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(16, 16)
    dot.Position = UDim2.new(1, -27, 0.5, -8)
    dot.BackgroundColor3 = value and self.Tab.Window.Library.Theme.Accent or self.Tab.Window.Library.Theme.Surface
    dot.Parent = b
    corner(dot, 8)
    stroke(dot, self.Tab.Window.Library.Theme.Stroke, 1, 0.2)

    local api = {Instance = b, CurrentValue = value}
    function api:SetValue(v, fire)
        value = v == true
        api.CurrentValue = value
        tween(dot, FAST, {BackgroundColor3 = value and self.Tab.Window.Library.Theme.Accent or self.Tab.Window.Library.Theme.Surface})
        if fire ~= false and options.Callback then options.Callback(value) end
    end
    b.MouseButton1Click:Connect(function() api:SetValue(not value) end)
    return api
end

function Section:CreateLabel(text)
    local l = makeLabel(self.Holder, text or "Label", 12, self.Tab.Window.Library.Theme.Muted, false)
    l.Size = UDim2.new(1, 0, 0, 22)
    return {Instance = l, SetText = function(_, v) l.Text = tostring(v) end}
end

function Section:CreateParagraph(options)
    options = options or {}
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 55)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundColor3 = self.Tab.Window.Library.Theme.Surface2
    f.BorderSizePixel = 0
    f.Parent = self.Holder
    corner(f, 7)
    padding(f, 9)
    local h = makeLabel(f, options.Title or "Info", 12, self.Tab.Window.Library.Theme.Text, true)
    h.Size = UDim2.new(1, 0, 0, 18)
    local d = makeLabel(f, options.Content or "", 11, self.Tab.Window.Library.Theme.Muted, false)
    d.Position = UDim2.fromOffset(0, 20)
    d.Size = UDim2.new(1, 0, 0, 30)
    d.TextWrapped = true
    d.AutomaticSize = Enum.AutomaticSize.Y
    return {Instance = f}
end

function Section:CreateSlider(options)
    options = options or {}
    local min = options.Range and options.Range[1] or 0
    local max = options.Range and options.Range[2] or 100
    local value = options.CurrentValue or min
    local step = options.Increment or 1

    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 52)
    f.BackgroundTransparency = 1
    f.Parent = self.Holder
    local label = makeLabel(f, options.Name or "Slider", 12, self.Tab.Window.Library.Theme.Text, false)
    label.Size = UDim2.new(1, -55, 0, 18)
    local valueLabel = makeLabel(f, tostring(value), 11, self.Tab.Window.Library.Theme.Muted, false)
    valueLabel.Size = UDim2.fromOffset(50, 18)
    valueLabel.Position = UDim2.new(1, -50, 0, 0)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local bar = Instance.new("Frame")
    bar.Position = UDim2.fromOffset(0, 28)
    bar.Size = UDim2.new(1, 0, 0, 8)
    bar.BackgroundColor3 = self.Tab.Window.Library.Theme.Surface2
    bar.Parent = f
    corner(bar, 4)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(math.clamp((value - min) / math.max(max - min, 1), 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = self.Tab.Window.Library.Theme.Accent
    fill.Parent = bar
    corner(fill, 4)

    local api = {Instance = f, CurrentValue = value}
    local dragging = false
    local function setFromX(x, fire)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local raw = min + (max - min) * alpha
        local stepped = min + math.floor((raw - min) / step + 0.5) * step
        value = math.clamp(stepped, min, max)
        api.CurrentValue = value
        local a = (value - min) / math.max(max - min, 1)
        fill.Size = UDim2.new(a, 0, 1, 0)
        valueLabel.Text = tostring(value)
        if fire ~= false and options.Callback then options.Callback(value) end
    end
    function api:SetValue(v, fire) setFromX(bar.AbsolutePosition.X + bar.AbsoluteSize.X * math.clamp((v - min) / math.max(max - min, 1), 0, 1), fire) end
    bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; setFromX(input.Position.X) end end)
    UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then setFromX(input.Position.X) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    return api
end

function Window:Notify(options)
    options = options or {}
    local holder = self.Gui:FindFirstChild("Notifications")
    if not holder then
        holder = Instance.new("Frame")
        holder.Name = "Notifications"
        holder.Size = UDim2.fromOffset(300, 300)
        holder.Position = UDim2.new(1, -315, 1, -315)
        holder.BackgroundTransparency = 1
        holder.Parent = self.Gui
        local layout = Instance.new("UIListLayout")
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.Padding = UDim.new(0, 8)
        layout.Parent = holder
    end
    local n = Instance.new("Frame")
    n.Size = UDim2.fromOffset(290, 62)
    n.BackgroundColor3 = self.Library.Theme.Surface
    n.BackgroundTransparency = 0.05
    n.Parent = holder
    corner(n, 9)
    stroke(n, self.Library.Theme.Accent, 1, 0.2)
    local title = makeLabel(n, options.Title or "NeonUI", 12, self.Library.Theme.Text, true)
    title.Position = UDim2.fromOffset(10, 8)
    title.Size = UDim2.new(1, -20, 0, 17)
    local text = makeLabel(n, options.Content or "", 10, self.Library.Theme.Muted, false)
    text.Position = UDim2.fromOffset(10, 27)
    text.Size = UDim2.new(1, -20, 0, 27)
    text.TextWrapped = true
    n.BackgroundTransparency = 1
    tween(n, MED, {BackgroundTransparency = 0.05})
    task.delay(options.Duration or 3, function()
        if n.Parent then
            local t = tween(n, MED, {BackgroundTransparency = 1})
            t.Completed:Wait()
            n:Destroy()
        end
    end)
end

function Window:Destroy()
    if self.Gui then self.Gui:Destroy() end
end

function Library:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, c in ipairs(self._connections) do pcall(function() c:Disconnect() end) end
    for _, w in ipairs(self._windows) do pcall(function() w:Destroy() end) end
    table.clear(self._connections)
    table.clear(self._windows)
end

return Library
