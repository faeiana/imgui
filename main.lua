local ImGui = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local THEME = {
    Background = Color3.fromRGB(17, 17, 22),
    Header = Color3.fromRGB(29, 29, 38),
    Row = Color3.fromRGB(25, 25, 32),
    Field = Color3.fromRGB(39, 39, 49),
    FieldOff = Color3.fromRGB(45, 45, 55),
    Accent = Color3.fromRGB(74, 105, 185),
    Text = Color3.fromRGB(235, 235, 242),
    Muted = Color3.fromRGB(170, 170, 182),
    Stroke = Color3.fromRGB(76, 76, 92)
}

local function create(className, properties, parent)
    local object = Instance.new(className)

    for key, value in pairs(properties or {}) do
        object[key] = value
    end

    object.Parent = parent
    return object
end

local function round(object, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 6)
    }, object)
end

local function stroke(object)
    return create("UIStroke", {
        Color = THEME.Stroke,
        Thickness = 1,
        Transparency = 0.15
    }, object)
end

local function call(callback, self, value)
    if typeof(callback) == "function" then
        task.spawn(function()
            callback(self, value)
        end)
    end
end

local function proxy(instance)
    local object = {
        Instance = instance
    }

    return setmetatable(object, {
        __index = function(self, key)
            local ownValue = rawget(self, key)
            if ownValue ~= nil then
                return ownValue
            end

            local ok, value = pcall(function()
                return instance[key]
            end)

            if ok then
                return value
            end

            return nil
        end,

        __newindex = function(self, key, value)
            local ok = pcall(function()
                instance[key] = value
            end)

            if not ok then
                rawset(self, key, value)
            end
        end
    })
end

local function getGuiParent()
    local ok, parent = pcall(function()
        return CoreGui
    end)

    if ok and parent then
        return parent
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

local function makeDraggable(frame, handle)
    local dragging = false
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = frame.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

function ImGui:CreateWindow(config)
    config = config or {}

    local screenGui = create("ScreenGui", {
        Name = "FaeianaImGui",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, getGuiParent())

    local main = create("Frame", {
        Name = "Window",
        Size = config.Size or UDim2.fromOffset(400, 480),
        Position = config.Position or UDim2.fromScale(0.5, 0.2),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = THEME.Background,
        BorderSizePixel = 0
    }, screenGui)
    round(main, 7)
    stroke(main)

    local title = create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 39),
        BackgroundColor3 = THEME.Header,
        BorderSizePixel = 0,
        Text = config.Title or "Window",
        TextColor3 = THEME.Text,
        Font = Enum.Font.Gotham,
        TextSize = 14
    }, main)
    round(title, 7)
    makeDraggable(main, title)

    local tabHolder = create("Frame", {
        Name = "Tabs",
        Size = UDim2.new(0, 112, 1, -51),
        Position = UDim2.fromOffset(8, 45),
        BackgroundTransparency = 1
    }, main)

    create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, tabHolder)

    local pageHolder = create("Frame", {
        Name = "Pages",
        Size = UDim2.new(1, -132, 1, -53),
        Position = UDim2.fromOffset(124, 45),
        BackgroundTransparency = 1
    }, main)

    local window = {
        Gui = screenGui,
        Main = main,
        Visible = true,
        Tabs = {}
    }

    function window:SetVisible(state)
        self.Visible = state == true
        screenGui.Enabled = self.Visible
        return self
    end

    function window:CreateTab(tabConfig)
        local name = "Tab"

        if typeof(tabConfig) == "table" then
            name = tabConfig.Name or tabConfig.Title or "Tab"
        elseif tabConfig ~= nil then
            name = tostring(tabConfig)
        end

        local tabButton = create("TextButton", {
            Name = name .. "_Button",
            Size = UDim2.new(1, 0, 0, 31),
            BackgroundColor3 = THEME.Header,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = name,
            TextColor3 = Color3.fromRGB(215, 215, 225),
            Font = Enum.Font.Gotham,
            TextSize = 12
        }, tabHolder)
        round(tabButton, 5)

        local page = create("ScrollingFrame", {
            Name = name .. "_Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.fromOffset(0, 0),
            Visible = false
        }, pageHolder)

        local layout = create("UIListLayout", {
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
            for _, other in ipairs(window.Tabs) do
                other.Page.Visible = false
                other.Button.BackgroundColor3 = THEME.Header
            end

            page.Visible = true
            tabButton.BackgroundColor3 = THEME.Accent
        end

        tabButton.MouseButton1Click:Connect(selectTab)

        local function makeRow(height)
            local row = create("Frame", {
                Size = UDim2.new(1, -6, 0, height),
                BackgroundColor3 = THEME.Row,
                BorderSizePixel = 0
            }, page)
            round(row, 5)
            return row
        end

        function tab:Label(config)
            local text = typeof(config) == "table" and (config.Text or config.Label or "") or tostring(config)
            local row = makeRow(30)

            create("TextLabel", {
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.fromOffset(8, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = THEME.Muted,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left
            }, row)

            return proxy(row)
        end

        function tab:Checkbox(config)
            config = config or {}

            local value = config.Value == true
            local row = makeRow(36)
            local object = proxy(row)

            create("TextLabel", {
                Size = UDim2.new(1, -54, 1, 0),
                Position = UDim2.fromOffset(10, 0),
                BackgroundTransparency = 1,
                Text = config.Label or "Checkbox",
                TextColor3 = THEME.Text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            }, row)

            local box = create("TextButton", {
                Size = UDim2.fromOffset(22, 22),
                Position = UDim2.new(1, -32, 0.5, -11),
                BackgroundColor3 = value and THEME.Accent or THEME.FieldOff,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = value and "X" or "",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.GothamBold,
                TextSize = 12
            }, row)
            round(box, 4)

            function object:Set(newValue)
                value = newValue == true
                box.Text = value and "X" or ""
                box.BackgroundColor3 = value and THEME.Accent or THEME.FieldOff
                call(config.Callback, object, value)
                return object
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
            config = config or {}

            local min = config.MinValue or config.Min or 0
            local max = config.MaxValue or config.Max or 100
            local value = math.clamp(config.Value or min, min, max)
            local row = makeRow(54)
            local object = proxy(row)

            local label = create("TextLabel", {
                Size = UDim2.new(1, -20, 0, 24),
                Position = UDim2.fromOffset(10, 0),
                BackgroundTransparency = 1,
                TextColor3 = THEME.Text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            }, row)

            local bar = create("TextButton", {
                Size = UDim2.new(1, -20, 0, 8),
                Position = UDim2.fromOffset(10, 36),
                BackgroundColor3 = Color3.fromRGB(47, 47, 58),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = ""
            }, row)
            round(bar, 4)

            local fill = create("Frame", {
                Size = UDim2.fromScale(0, 1),
                BackgroundColor3 = THEME.Accent,
                BorderSizePixel = 0
            }, bar)
            round(fill, 4)

            local function refresh()
                local divisor = max - min
                local alpha = divisor == 0 and 0 or (value - min) / divisor
                fill.Size = UDim2.fromScale(math.clamp(alpha, 0, 1), 1)
                label.Text = (config.Label or "Slider") .. ": " .. tostring(math.floor(value * 100) / 100)
            end

            function object:Set(newValue)
                value = math.clamp(tonumber(newValue) or min, min, max)
                refresh()
                call(config.Callback, object, value)
                return object
            end

            function object:Get()
                return value
            end

            local dragging = false

            local function setFromMouse()
                local mouseX = UserInputService:GetMouseLocation().X
                local width = math.max(bar.AbsoluteSize.X, 1)
                local alpha = math.clamp((mouseX - bar.AbsolutePosition.X) / width, 0, 1)
                object:Set(min + ((max - min) * alpha))
            end

            bar.MouseButton1Down:Connect(function()
                dragging = true
                setFromMouse()
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    setFromMouse()
                end
            end)

            refresh()
            return object
        end

        function tab:Combo(config)
            config = config or {}

            local items = config.Items or config.Options or {}
            local value = config.Value or items[1] or "None"
            local row = makeRow(36)
            local object = proxy(row)
            local open = false

            local button = create("TextButton", {
                Size = UDim2.new(1, -20, 0, 26),
                Position = UDim2.fromOffset(10, 5),
                BackgroundColor3 = THEME.Field,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                TextColor3 = THEME.Text,
                Font = Enum.Font.Gotham,
                TextSize = 12
            }, row)
            round(button, 5)

            local list = create("Frame", {
                Size = UDim2.new(1, -20, 0, #items * 25),
                Position = UDim2.fromOffset(10, 34),
                BackgroundColor3 = Color3.fromRGB(34, 34, 43),
                BorderSizePixel = 0,
                Visible = false
            }, row)
            round(list, 5)

            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder
            }, list)

            local function refresh()
                button.Text = (config.Label or "Combo") .. ": " .. tostring(value)
            end

            local function setOpen(state)
                open = state == true
                list.Visible = open
                row.Size = open and UDim2.new(1, -6, 0, 40 + (#items * 25)) or UDim2.new(1, -6, 0, 36)
            end

            function object:Set(newValue)
                value = newValue
                refresh()
                call(config.Callback, object, value)
                return object
            end

            function object:Get()
                return value
            end

            for _, item in ipairs(items) do
                local option = create("TextButton", {
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
                    call(config.Callback, object, value)
                end)
            end

            button.MouseButton1Click:Connect(function()
                setOpen(not open)
            end)

            refresh()
            return object
        end

        function tab:Keybind(config)
            config = config or {}

            local value = config.Value or Enum.KeyCode.Unknown
            local row = makeRow(36)
            local object = proxy(row)
            local waiting = false

            create("TextLabel", {
                Size = UDim2.new(1, -118, 1, 0),
                Position = UDim2.fromOffset(10, 0),
                BackgroundTransparency = 1,
                Text = config.Label or "Keybind",
                TextColor3 = THEME.Text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            }, row)

            local button = create("TextButton", {
                Size = UDim2.fromOffset(92, 24),
                Position = UDim2.new(1, -102, 0.5, -12),
                BackgroundColor3 = THEME.Field,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = value.Name or "None",
                TextColor3 = THEME.Text,
                Font = Enum.Font.Gotham,
                TextSize = 12
            }, row)
            round(button, 5)

            function object:Set(newValue)
                value = newValue or Enum.KeyCode.Unknown
                button.Text = value.Name or "None"
                call(config.Callback, object, value)
                return object
            end

            function object:Get()
                return value
            end

            button.MouseButton1Click:Connect(function()
                waiting = true
                button.Text = "press key"
            end)

            UserInputService.InputBegan:Connect(function(input, processed)
                if processed or not waiting then
                    return
                end

                if input.KeyCode == Enum.KeyCode.Unknown then
                    return
                end

                waiting = false
                object:Set(input.KeyCode)
            end)

            return object
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

function ImGui:Window(config)
    return self:CreateWindow(config)
end

ImGui.Window = ImGui.CreateWindow

return ImGui
