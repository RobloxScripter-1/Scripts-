# NeonUI 🔵

A lightweight blue-neon Roblox Luau UI library focused on smooth client-side interaction.

## Features

- Draggable window with mouse and touch support
- Tabs and sections
- Buttons
- Toggles
- Sliders
- Labels and paragraphs
- Notifications
- Minimize/close controls
- Visibility keybind
- Automatic UI sizing
- Short, lightweight tweens
- Event-driven controls instead of a permanent RenderStepped polling loop
- Cleanup through `Library:Destroy()`

## Basic usage

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = require(ReplicatedStorage.NeonUI)

local UI = Library.new()
local Window = UI:CreateWindow({
    Name = "NeonUI",
    Subtitle = "Blue Edition",
    ToggleKey = Enum.KeyCode.RightShift,
})

local Main = Window:CreateTab({Name = "Main"})
local Section = Main:CreateSection("Controls")

Section:CreateToggle({
    Name = "Example",
    CurrentValue = false,
    Callback = function(value)
        print(value)
    end,
})
```

## Performance notes

NeonUI keeps animation durations short and avoids a permanent frame-by-frame UI update loop. Controls react to input events, while tweens are only created for visible state changes.

The library itself is ordinary Roblox client UI code. It does not contain executor-specific APIs, hooks, bypasses, or anti-cheat evasion.

## License

MIT
