local ImGui = {
    Animations = {
        Buttons = {
            MouseEnter = {
                BackgroundTransparency = 0.5,
            },

            MouseLeave = {
                BackgroundTransparency = 0.7,
            }
        },

        Tabs = {
            MouseEnter = {
                BackgroundTransparency = 0.5,
            },

            MouseLeave = {
                BackgroundTransparency = 1,
            }
        },

        Inputs = {
            MouseEnter = {
                BackgroundTransparency = 0,
            },

            MouseLeave = {
                BackgroundTransparency = 0.5,
            }
        },

        WindowBorder = {
            Selected = {
                Transparency = 0,
                Thickness = 1
            },

            Deselected = {
                Transparency = 0.7,
                Thickness = 1
            }
        },
    },

    Windows = {},
    Animation = TweenInfo.new(0.1),
    UIAssetId = "rbxassetid://76246418997296"
}

--// Universal functions
local NullFunction = function() end

local CloneRef = cloneref or function(_)
    return _
end

local function GetService(...): ServiceProvider
    return CloneRef(game:GetService(...))
end

function ImGui:Warn(...)
    if self.NoWarnings then
        return
    end

    return warn("[IMGUI]", ...)
end

--// Services
local TweenService: TweenService = GetService("TweenService")
local UserInputService: UserInputService = GetService("UserInputService")
local Players: Players = GetService("Players")
local CoreGui = GetService("CoreGui")
local RunService: RunService = GetService("RunService")

--// LocalPlayer
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Mouse = LocalPlayer:GetMouse()

--// ImGui Config
local IsStudio = RunService:IsStudio()

ImGui.NoWarnings = not IsStudio

--// Prefabs
function ImGui:FetchUI()

    --// Cache check
    local CacheName = "DepsoImGui"

    if _G[CacheName] then
        self:Warn("Prefabs loaded from Cache")
        return _G[CacheName]
    end

    local UI = nil

    --// Universal
    if not IsStudio then
        local UIAssetId = ImGui.UIAssetId
        UI = game:GetObjects(UIAssetId)[1]

    else

        --// Studio
        local UIName = "DepsoImGui"
        UI = PlayerGui:FindFirstChild(UIName) or script.DepsoImGui
    end

    _G[CacheName] = UI

    return UI
end

local UI = ImGui:FetchUI()
local Prefabs = UI.Prefabs

ImGui.Prefabs = Prefabs
Prefabs.Visible = false

--// Styles
local AddionalStyles = {

    [{
        Name = "Border"
    }] = function(GuiObject: GuiObject, Value, Class)

        local Outline = GuiObject:FindFirstChildOfClass("UIStroke")

        if not Outline then
            return
        end

        local BorderThickness = Class.BorderThickness

        if BorderThickness then
            Outline.Thickness = BorderThickness
        end

        Outline.Enabled = Value
    end,

    [{
        Name = "Ratio"
    }] = function(GuiObject: GuiObject, Value, Class)

        local RatioAxis = Class.RatioAxis or "Height"
        local AspectRatio = Class.Ratio or 4 / 3
        local AspectType = Class.AspectType or Enum.AspectType.ScaleWithParentSize

        local Ratio = GuiObject:FindFirstChildOfClass("UIAspectRatioConstraint")

        if not Ratio then
            Ratio = ImGui:CreateInstance("UIAspectRatioConstraint", GuiObject)
        end

        Ratio.DominantAxis = Enum.DominantAxis[RatioAxis]
        Ratio.AspectType = AspectType
        Ratio.AspectRatio = AspectRatio
    end,

    [{
        Name = "CornerRadius",
        Recursive = true
    }] = function(GuiObject: GuiObject, Value, Class)

        local UICorner = GuiObject:FindFirstChildOfClass("UICorner")

        if not UICorner then
            UICorner = ImGui:CreateInstance("UICorner", GuiObject)
        end

        UICorner.CornerRadius = Class.CornerRadius
    end,

    [{
        Name = "Label"
    }] = function(GuiObject: GuiObject, Value, Class)

        local Label = GuiObject:FindFirstChild("Label")

        if not Label then
            return
        end

        Label.Text = Class.Label

        function Class:SetLabel(Text)
            Label.Text = Text
            return Class
        end
    end,

    [{
        Name = "NoGradient",
        Aliases = {
            "NoGradientAll"
        },

        Recursive = true
    }] = function(GuiObject: GuiObject, Value, Class)

        local UIGradient = GuiObject:FindFirstChildOfClass("UIGradient")

        if not UIGradient then
            return
        end

        UIGradient.Enabled = not Value
    end,

    --// Addional functions for classes
    [{
        Name = "Callback"
    }] = function(GuiObject: GuiObject, Value, Class)

        function Class:SetCallback(NewCallback)
            Class.Callback = NewCallback
            return Class
        end

        function Class:FireCallback(NewCallback)
            return Class.Callback(GuiObject)
        end
    end,

    [{
        Name = "Value"
    }] = function(GuiObject: GuiObject, Value, Class)

        function Class:GetValue()
            return Class.Value
        end
    end,
}

function ImGui:GetName(Name: string)
    local Format = "%s_"
    return Format:format(Name)
end

function ImGui:CreateInstance(Class, Parent, Properties)

    local Instance = Instance.new(Class, Parent)

    for Key, Value in next, Properties or {} do
        Instance[Key] = Value
    end

    return Instance
end
