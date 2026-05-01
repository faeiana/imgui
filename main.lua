local ImGui = loadstring([[

local ImGui = {}
ImGui.__index = ImGui

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- SCREEN GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ImGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- WINDOW
function ImGui:CreateWindow(cfg)
    local Window = {}

    local Frame = Instance.new("Frame")
    Frame.Size = cfg.Size or UDim2.fromOffset(400, 300)
    Frame.Position = cfg.Position or UDim2.fromScale(0.5,0.5)
    Frame.BackgroundColor3 = Color3.fromRGB(30,30,35)
    Frame.Parent = ScreenGui
    Frame.Active = true
    Frame.Draggable = true

    Window.Frame = Frame
    Window.Visible = true

    function Window:SetVisible(v)
        Frame.Visible = v
        self.Visible = v
    end

    function Window:CreateTab(tabCfg)
        local Tab = {}

        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1,0,1,0)
        Container.BackgroundTransparency = 1
        Container.Visible = true
        Container.Parent = Frame

        local layout = Instance.new("UIListLayout", Container)
        layout.Padding = UDim.new(0,5)

        function Tab:Checkbox(cfg)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1,0,0,30)
            btn.Text = cfg.Label .. ": " .. tostring(cfg.Value)
            btn.Parent = Container

            local state = cfg.Value

            btn.MouseButton1Click:Connect(function()
                state = not state
                btn.Text = cfg.Label .. ": " .. tostring(state)
                if cfg.Callback then
                    cfg.Callback(nil, state)
                end
            end)

            return btn
        end

        function Tab:Slider(cfg)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1,0,0,40)
            frame.Parent = Container

            local label = Instance.new("TextLabel", frame)
            label.Size = UDim2.new(1,0,0,20)
            label.Text = cfg.Label .. ": " .. tostring(cfg.Value)

            local bar = Instance.new("TextButton", frame)
            bar.Position = UDim2.new(0,0,0,20)
            bar.Size = UDim2.new(1,0,0,20)
            bar.Text = ""

            bar.MouseButton1Click:Connect(function()
                local new = math.random(cfg.MinValue, cfg.MaxValue)
                label.Text = cfg.Label .. ": " .. tostring(new)
                if cfg.Callback then
                    cfg.Callback(nil, new)
                end
            end)
        end

        function Tab:Combo(cfg)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1,0,0,30)
            btn.Text = cfg.Label
            btn.Parent = Container

            btn.MouseButton1Click:Connect(function()
                local val = cfg.Items[math.random(1,#cfg.Items)]
                btn.Text = cfg.Label .. ": " .. val
                if cfg.Callback then
                    cfg.Callback(nil, val)
                end
            end)
        end

        function Tab:Keybind(cfg)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1,0,0,30)
            btn.Text = cfg.Label .. ": " .. tostring(cfg.Value.Name)
            btn.Parent = Container

            btn.MouseButton1Click:Connect(function()
                btn.Text = "Press key..."
                local input = UIS.InputBegan:Wait()
                cfg.Value = input.KeyCode
                btn.Text = cfg.Label .. ": " .. input.KeyCode.Name
                if cfg.Callback then
                    cfg.Callback(nil, input.KeyCode)
                end
            end)
        end

        function Tab:Label(cfg)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1,0,0,25)
            lbl.Text = cfg.Text
            lbl.Parent = Container
        end

        return Tab
    end

    return Window
end

return setmetatable({}, ImGui)

]])()

return ImGui
