local ImGui = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local function new(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    new("UICorner", {
        CornerRadius = UDim.new(0, radius or 6)
    }, parent)
end

local function stroke(parent, color)
    new("UIStroke", {
        Color = color or Color3.fromRGB(70, 70, 80),
        Thickness = 1
    }, parent)
end

local function makeDraggable(frame, dragHandle)
    local dragging = false
    local dragStart
    local startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function ImGui:Window(config)
    config = config or {}

    local gui = new("ScreenGui", {
        Name = config.Name or "ImGui",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, LocalPlayer:WaitForChild("PlayerGui"))

    local main = new("Frame", {
        Size = config.Size or UDim2.fromOffset(560, 390),
        Position = config.Position or UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(22, 22, 28),
        BorderSizePixel = 0
    }, gui)
    corner(main, 8)
    stroke(main)

    local top = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Color3.fromRGB(30, 30, 38),
        BorderSizePixel = 0,
        Text = config.Title or "ImGui Window",
        TextColor3 = Color3.fromRGB(235, 235, 245),
        TextSize = 15,
        Font = Enum.Font.GothamSemibold
    }, main)
    corner(top, 8)

    makeDraggable(main, top)

    local tabBar = new("Frame", {
        Size = UDim2.new(0, 140, 1, -46),
        Position = UDim2.fromOffset(8, 42),
        BackgroundTransparency = 1
    }, main)

    new("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, tabBar)

    local content = new("Frame", {
        Size = UDim2.new(1, -160, 1, -50),
        Position = UDim2.fromOffset(152, 42),
        BackgroundTransparency = 1
    }, main)

    local window = {
        Gui = gui,
        Main = main,
        Tabs = {},
        CurrentTab = nil
    }

    function window:TabCreate(name)
        local tabButton = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Color3.fromRGB(34, 34, 43),
            Text = name,
            TextColor3 = Color3.fromRGB(210, 210, 220),
            TextSize = 14,
            Font = Enum.Font.Gotham,
            AutoButtonColor = false
        }, tabBar)
        corner(tabButton, 6)

        local page = new("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 4,
            Visible = false
        }, content)

        local layout = new("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, page)

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 12)
        end)

        local tab = {
            Name = name,
            Button = tabButton,
            Page = page
        }

        local function selectTab()
            for _, other in pairs(window.Tabs) do
                other.Page.Visible = false
                other.Button.BackgroundColor3 = Color3.fromRGB(34, 34, 43)
            end

            page.Visible = true
            tabButton.BackgroundColor3 = Color3.fromRGB(62, 91, 170)
            window.CurrentTab = tab
        end

        tabButton.MouseButton1Click:Connect(selectTab)

        local function base(labelText, height)
            local holder = new("Frame", {
                Size = UDim2.new(1, -6, 0, height or 38),
                BackgroundColor3 = Color3.fromRGB(30, 30, 38),
                BorderSizePixel = 0
            }, page)
            corner(holder, 6)
            return holder
        end

        function tab:Label(text)
            local holder = base(text, 34)
            local label = new("TextLabel", {
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.fromOffset(8, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Color3.fromRGB(225, 225, 235),
                TextSize = 14,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left
            }, holder)

            return {
                Instance = holder,
                Set = function(_, value)
                    label.Text = value
                end
            }
        end

        function tab:Button(text, callback)
            callback = callback or function() end

            local btn = new("TextButton", {
                Size = UDim2.new(1, -6, 0, 38),
                BackgroundColor3 = Color3.fromRGB(62, 91, 170),
                Text = text,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                Font = Enum.Font.GothamSemibold,
                AutoButtonColor = false
            }, page)
            corner(btn, 6)

            btn.MouseButton1Click:Connect(function()
                callback()
            end)

            return btn
        end

        function tab:Toggle(text, default, callback)
            callback = callback or function() end
            local value = default == true
            local holder = base(text, 40)

            local label = new("TextLabel", {
                Size = UDim2.new(1, -64, 1, 0),
                Position = UDim2.fromOffset(10, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Color3.fromRGB(225, 225, 235),
                TextSize = 14,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left
            }, holder)

            local toggle = new("TextButton", {
                Size = UDim2.fromOffset(42, 22),
                Position = UDim2.new(1, -52, 0.5, -11),
                BackgroundColor3 = value and Color3.fromRGB(62, 170, 105) or Color3.fromRGB(70, 70, 80),
                Text = "",
                AutoButtonColor = false
            }, holder)
            corner(toggle, 11)

            local knob = new("Frame", {
                Size = UDim2.fromOffset(18, 18),
                Position = value and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2),
                BackgroundColor3 = Color3.fromRGB(245, 245, 245),
                BorderSizePixel = 0
            }, toggle)
            corner(knob, 9)

            local object = {}

            function object:Set(newValue)
                value = newValue == true
                TweenService:Create(toggle, TweenInfo.new(0.12), {
                    BackgroundColor3 = value and Color3.fromRGB(62, 170, 105) or Color3.fromRGB(70, 70, 80)
                }):Play()
                TweenService:Create(knob, TweenInfo.new(0.12), {
                    Position = value and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2)
                }):Play()
                callback(value)
            end

            function object:Get()
                return value
            end

            toggle.MouseButton1Click:Connect(function()
                object:Set(not value)
            end)

            return object
        end

        function tab:Slider(text, min, max, default, callback)
            min = min or 0
            max = max or 100
            callback = callback or function() end

            local value = math.clamp(default or min, min, max)
            local holder = base(text, 58)

            local label = new("TextLabel", {
                Size = UDim2.new(1, -20, 0, 24),
                Position = UDim2.fromOffset(10, 2),
                BackgroundTransparency = 1,
                Text = text .. ": " .. tostring(value),
                TextColor3 = Color3.fromRGB(225, 225, 235),
                TextSize = 14,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left
            }, holder)

            local bar = new("TextButton", {
                Size = UDim2.new(1, -20, 0, 8),
                Position = UDim2.fromOffset(10, 38),
                BackgroundColor3 = Color3.fromRGB(55, 55, 65),
                Text = "",
                AutoButtonColor = false
            }, holder)
            corner(bar, 4)

            local fill = new("Frame", {
                Size = UDim2.fromScale((value - min) / (max - min), 1),
                BackgroundColor3 = Color3.fromRGB(62, 91, 170),
                BorderSizePixel = 0
            }, bar)
            corner(fill, 4)

            local dragging = false
            local object = {}

            function object:Set(newValue)
                value = math.clamp(newValue, min, max)
                local alpha = (value - min) / (max - min)
                fill.Size = UDim2.fromScale(alpha, 1)
                label.Text = text .. ": " .. tostring(math.floor(value * 100) / 100)
                callback(value)
            end

            function object:Get()
                return value
            end

            local function updateFromMouse()
                local alpha = math.clamp((UIS:GetMouseLocation().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                object:Set(min + ((max - min) * alpha))
            end

            bar.MouseButton1Down:Connect(function()
                dragging = true
                updateFromMouse()
            end)

            UIS.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            UIS.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateFromMouse()
                end
            end)

            return object
        end

        function tab:Textbox(text, default, callback)
            callback = callback or function() end
            local holder = base(text, 42)

            local box = new("TextBox", {
                Size = UDim2.new(1, -20, 0, 28),
                Position = UDim2.fromOffset(10, 7),
                BackgroundColor3 = Color3.fromRGB(40, 40, 50),
                Text = default or "",
                PlaceholderText = text,
                TextColor3 = Color3.fromRGB(235, 235, 245),
                PlaceholderColor3 = Color3.fromRGB(150, 150, 160),
                TextSize = 14,
                Font = Enum.Font.Gotham,
                ClearTextOnFocus = false
            }, holder)
            corner(box, 5)

            box.FocusLost:Connect(function()
                callback(box.Text)
            end)

            return box
        end

        function tab:Dropdown(text, options, default, callback)
            options = options or {}
            callback = callback or function() end

            local value = default or options[1]
            local open = false
            local holder = base(text, 38)

            local btn = new("TextButton", {
                Size = UDim2.new(1, -20, 0, 28),
                Position = UDim2.fromOffset(10, 5),
                BackgroundColor3 = Color3.fromRGB(40, 40, 50),
                Text = text .. ": " .. tostring(value or "None"),
                TextColor3 = Color3.fromRGB(235, 235, 245),
                TextSize = 14,
                Font = Enum.Font.Gotham,
                AutoButtonColor = false
            }, holder)
            corner(btn, 5)

            local optionFrame = new("Frame", {
                Size = UDim2.new(1, -20, 0, #options * 28),
                Position = UDim2.fromOffset(10, 36),
                BackgroundColor3 = Color3.fromRGB(35, 35, 44),
                BorderSizePixel = 0,
                Visible = false
            }, holder)
            corner(optionFrame, 5)

            new("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder
            }, optionFrame)

            local function setOpen(state)
                open = state
                optionFrame.Visible = open
                holder.Size = open and UDim2.new(1, -6, 0, 42 + (#options * 28)) or UDim2.new(1, -6, 0, 38)
            end

            for _, option in ipairs(options) do
                local opt = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    Text = tostring(option),
                    TextColor3 = Color3.fromRGB(220, 220, 230),
                    TextSize = 13,
                    Font = Enum.Font.Gotham,
                    AutoButtonColor = false
                }, optionFrame)

                opt.MouseButton1Click:Connect(function()
                    value = option
                    btn.Text = text .. ": " .. tostring(value)
                    setOpen(false)
                    callback(value)
                end)
            end

            btn.MouseButton1Click:Connect(function()
                setOpen(not open)
            end)

            return {
                Get = function()
                    return value
                end,
                Set = function(_, newValue)
                    value = newValue
                    btn.Text = text .. ": " .. tostring(value)
                    callback(value)
                end
            }
        end

        table.insert(window.Tabs, tab)

        if not window.CurrentTab then
            selectTab()
        end

        return tab
    end

    function window:Destroy()
        gui:Destroy()
    end

    return window
end

ImGui.CreateWindow = function(self, config)
    return self:Window(config)
end

return ImGui
