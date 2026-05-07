local ImGui = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function round(obj, px)
    make("UICorner", {
        CornerRadius = UDim.new(0, px or 6)
    }, obj)
end

local function safeCallback(fn, self, value)
    if typeof(fn) == "function" then
        task.spawn(function()
            fn(self, value)
        end)
    end
end

local function getParent()
    local ok, parent = pcall(function()
        return CoreGui
    end)

    if ok and parent then
        return parent
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

local function draggable(frame, handle)
    local dragging = false
    local startPos
    local startInput

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startInput = input.Position
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
            local delta = input.Position - startInput
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function ImGui:CreateWindow(config)
    config = config or {}

    local screenGui = make("ScreenGui", {
        Name = "FaeianaImGui",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, getParent())

    local main = make("Frame", {
        Name = "Window",
        Size = config.Size or UDim2.fromOffset(400, 480),
        Position = config.Position or UDim2.fromScale(0.5, 0.2),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(18, 18, 23),
        BorderSizePixel = 0
    }, screenGui)
    round(main, 7)

    make("UIStroke", {
        Color = Color3.fromRGB(76, 76, 92),
        Thickness = 1,
        Transparency = 0.15
    }, main)

    local title = make("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 39),
        BackgroundColor3 = Color3.fromRGB(29, 29, 38),
        BorderSizePixel = 0,
        Text = config.Title or "Window",
        TextColor3 = Color3.fromRGB(235, 235, 242),
        Font = Enum.Font.Gotham,
        TextSize = 14
    }, main)
    round(title, 7)

    draggable(main, title)

    local tabHolder = make("Frame", {
        Name = "Tabs",
        Size = UDim2.new(0, 112, 1, -51),
        Position = UDim2.fromOffset(8, 45),
        BackgroundTransparency = 1,
        Visible = true
    }, main)

    make("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, tabHolder)

    local pageHolder = make("Frame", {
        Name = "Pages",
        Size = UDim2.new(1, -132, 1, -53),
        Position = UDim2.fromOffset(124, 45),
        BackgroundTransparency = 1,
        Visible = true
    }, main)

    local emptyText = make("TextLabel", {
        Name = "EmptyText",
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.fromOffset(10, 8),
        BackgroundTransparency = 1,
        Text = "waiting for tabs...",
        TextColor3 = Color3.fromRGB(120, 120, 130),
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, pageHolder)

    local window = {
        Gui = screenGui,
        Main = main,
        Visible = true,
        Tabs = {}
    }

    function window:SetVisible(state)
        self.Visible = state
        screenGui.Enabled = state
    end

    function window:CreateTab(tabConfig)
        local name = "Tab"

        if typeof(tabConfig) == "table" then
            name = tabConfig.Name or tabConfig.Title or "Tab"
        else
            name = tostring(tabConfig)
        end

        emptyText.Visible = false

        local tabButton = make("TextButton", {
            Name = name .. "_Button",
            Size = UDim2.new(1, 0, 0, 31),
            BackgroundColor3 = Color3.fromRGB(29, 29, 38),
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = name,
            TextColor3 = Color3.fromRGB(215, 215, 225),
            Font = Enum.Font.Gotham,
            TextSize = 12
        }, tabHolder)
        round(tabButton, 5)

        local page = make("ScrollingFrame", {
            Name = name .. "_Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.fromOffset(0, 0),
            Visible = false
        }, pageHolder)

        local layout = make("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, page)

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 12)
        end)

        local tab = {
            Button = tabButton,
            Page = page,
            Name = name
        }

        local function selectTab()
            for _, other in ipairs(window.Tabs) do
                other.Page.Visible = false
                other.Button.BackgroundColor3 = Color3.fromRGB(29, 29, 38)
            end

            page.Visible = true
            tabButton.BackgroundColor3 = Color3.fromRGB(74, 105, 185)
        end

        tabButton.MouseButton1Click:Connect(selectTab)

        local function row(height)
            local frame = make("Frame", {
                Size = UDim2.new(1, -6, 0, height),
                BackgroundColor3 = Color3.fromRGB(26, 26, 34),
                BorderSizePixel = 0,
                Visible = true
            }, page)
            round(frame, 5)
            return frame
        end

        function tab:Label(config)
            local text = typeof(config) == "table" and config.Text or tostring(config)
            local frame = row(30)

            make("TextLabel", {
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.fromOffset(8, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Color3.fromRGB(170, 170, 182),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left
            }, frame)

            return frame
        end

        function tab:Checkbox(config)
            local value = config.Value == true
            local frame = row(36)

            make("TextLabel", {
                Size = UDim2.new(1, -54, 1, 0),
                Position = UDim2.fromOffset(10, 0),
                BackgroundTransparency = 1,
                Text = config.Label or "Checkbox",
                TextColor3 = Color3.fromRGB(235, 235, 242),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            }, frame)

            local box = make("TextButton", {
                Size = UDim2.fromOffset(22, 22),
                Position = UDim2.new(1, -32, 0.5, -11),
                BackgroundColor3 = value and Color3.fromRGB(74, 105, 185) or Color3.fromRGB(45, 45, 55),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = value and "X" or "",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.GothamBold,
                TextSize = 12
            }, frame)
            round(box, 4)

            local object = frame

            function object:Set(newValue)
                value = newValue == true
                box.Text = value and "X" or ""
                box.BackgroundColor3 = value and Color3.fromRGB(74, 105, 185) or Color3.fromRGB(45, 45, 55)
                safeCallback(config.Callback, object, value)
            end

            function object:Get()
                return value
            end

            box.MouseButton1Click:Connect(function()
                object:Set(not value)
            end)

            return object
        end

        function tab:Slider(config)
            local min = config.MinValue or config.Min or 0
            local max = config.MaxValue or config.Max or 100
            local value = math.clamp(config.Value or min, min, max)
            local frame = row(54)

            local label = make("TextLabel", {
                Size = UDim2.new(1, -20, 0, 24),
                Position = UDim2.fromOffset(10, 0),
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(235, 235, 242),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            }, frame)

            local bar = make("TextButton", {
                Size = UDim2.new(1, -20, 0, 8),
                Position = UDim2.fromOffset(10, 36),
                BackgroundColor3 = Color3.fromRGB(47, 47, 58),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = ""
            }, frame)
            round(bar, 4)

            local fill = make("Frame", {
                Size = UDim2.fromScale(0, 1),
                BackgroundColor3 = Color3.fromRGB(74, 105, 185),
                BorderSizePixel = 0
            }, bar)
            round(fill, 4)

            local object = frame

            local function refresh()
                local alpha = (value - min) / (max - min)
                fill.Size = UDim2.fromScale(math.clamp(alpha, 0, 1), 1)
                label.Text = (config.Label or "Slider") .. ": " .. tostring(math.floor(value * 100) / 100)
            end

            function object:Set(newValue)
                value = math.clamp(newValue, min, max)
                refresh()
                safeCallback(config.Callback, object, value)
            end

            function object:Get()
                return value
            end

            local dragging = false

            local function setFromMouse()
                local mouseX = UIS:GetMouseLocation().X
                local alpha = math.clamp((mouseX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                object:Set(min + ((max - min) * alpha))
            end

            bar.MouseButton1Down:Connect(function()
                dragging = true
                setFromMouse()
            end)

            UIS.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            UIS.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    setFromMouse()
                end
            end)

            refresh()
            return object
        end

        function tab:Combo(config)
            local items = config.Items or {}
            local value = config.Value or items[1] or "None"
            local open = false
            local frame = row(36)

            local button = make("TextButton", {
                Size = UDim2.new(1, -20, 0, 26),
                Position = UDim2.fromOffset(10, 5),
                BackgroundColor3 = Color3.fromRGB(39, 39, 49),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                TextColor3 = Color3.fromRGB(235, 235, 242),
                Font = Enum.Font.Gotham,
                TextSize = 12
            }, frame)
            round(button, 5)

            local list = make("Frame", {
                Size = UDim2.new(1, -20, 0, #items * 25),
                Position = UDim2.fromOffset(10, 34),
                BackgroundColor3 = Color3.fromRGB(34, 34, 43),
                BorderSizePixel = 0,
                Visible = false
            }, frame)
            round(list, 5)

            make("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder
            }, list)

            local object = frame

            local function refresh()
                button.Text = (config.Label or "Combo") .. ": " .. tostring(value)
            end

            local function setOpen(state)
                open = state
                list.Visible = state
                frame.Size = state and UDim2.new(1, -6, 0, 40 + (#items * 25)) or UDim2.new(1, -6, 0, 36)
            end

            function object:Set(newValue)
                value = newValue
                refresh()
                safeCallback(config.Callback, object, value)
            end

            function object:Get()
                return value
            end

            for _, item in ipairs(items) do
                local option = make("TextButton", {
                    Size = UDim2.new(1, 0, 0, 25),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = tostring(item),
                    TextColor3 = Color3.fromRGB(220, 220, 230),
                    Font = Enum.Font.Gotham,
                    TextSize = 12
                }, list)

                option.MouseButton1Click:Connect(function()
                    value = item
                    refresh()
                    setOpen(false)
                    safeCallback(config.Callback, object, value)
                end)
            end

            button.MouseButton1Click:Connect(function()
                setOpen(not open)
            end)

            refresh()
            return object
        end

        function tab:Keybind(config)
            local value = config.Value or Enum.KeyCode.Unknown
            local waiting = false
            local frame = row(36)

            make("TextLabel", {
                Size = UDim2.new(1, -118, 1, 0),
                Position = UDim2.fromOffset(10, 0),
                BackgroundTransparency = 1,
                Text = config.Label or "Keybind",
                TextColor3 = Color3.fromRGB(235, 235, 242),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            }, frame)

            local button = make("TextButton", {
                Size = UDim2.fromOffset(92, 24),
                Position = UDim2.new(1, -102, 0.5, -12),
                BackgroundColor3 = Color3.fromRGB(39, 39, 49),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = value.Name or "None",
                TextColor3 = Color3.fromRGB(235, 235, 242),
                Font = Enum.Font.Gotham,
                TextSize = 12
            }, frame)
            round(button, 5)

            button.MouseButton1Click:Connect(function()
                waiting = true
                button.Text = "press key"
            end)

            UIS.InputBegan:Connect(function(input, processed)
                if processed or not waiting then
                    return
                end

                if input.KeyCode == Enum.KeyCode.Unknown then
                    return
                end

                waiting = false
                value = input.KeyCode
                button.Text = value.Name
                safeCallback(config.Callback, frame, value)
            end)

            return frame
        end

        function tab:Rebuild()
            return self
        end

        table.insert(window.Tabs, tab)

        if #window.Tabs == 1 then
            selectTab()
        end

        return tab
    end

    function window:TabCreate(name)
        return self:CreateTab({ Name = name })
    end

    return window
end

ImGui.Window = ImGui.CreateWindow

return ImGui
