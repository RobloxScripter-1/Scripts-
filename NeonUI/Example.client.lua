local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = require(ReplicatedStorage:WaitForChild("NeonUI"))

local UI = Library.new()
local Window = UI:CreateWindow({
    Name = "NeonUI",
    Subtitle = "Blue Edition",
    Size = UDim2.fromOffset(650, 430),
    ToggleKey = Enum.KeyCode.RightShift,
})

local Main = Window:CreateTab({Name = "Main"})
local Controls = Main:CreateSection("Controls")

Controls:CreateButton({
    Name = "Test Notification",
    Callback = function()
        Window:Notify({
            Title = "NeonUI",
            Content = "Everything is running smoothly.",
            Duration = 3,
        })
    end,
})

Controls:CreateToggle({
    Name = "Example Toggle",
    CurrentValue = false,
    Callback = function(value)
        print("Toggle:", value)
    end,
})

Controls:CreateSlider({
    Name = "Speed",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(value)
        print("Speed:", value)
    end,
})

Controls:CreateParagraph({
    Title = "NeonUI",
    Content = "Client-side UI library with lightweight event-driven interactions and blue neon styling.",
})
