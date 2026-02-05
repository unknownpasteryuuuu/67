setfpscap(32555555555555555)
local Config = {
    Box = {
        Enabled = false,
        Inline = Color3.fromRGB(0, 0, 0),
        Outline = Color3.fromRGB(0, 0, 0),
        Gradient = {
            Color1 = Color3.fromRGB(255, 255, 255),
            Color2 = Color3.fromRGB(255, 255, 255),
            Color3 = Color3.fromRGB(255, 255, 255)
        },
        Filled = {
            Enabled = false,
            Gradient = {
                Color1 = Color3.fromRGB(255, 255, 255),
                Color2 = Color3.fromRGB(255, 255, 255),
                Color3 = Color3.fromRGB(255, 255, 255),
                Rotation = {
                    Amount = 45,
                    Moving = {
                        Enabled = false,
                        Speed = 300
                    }
                }
            }
        }
    },
    Text = {
        Font = "ProggyClean",
        Name = {
            Enabled = false,
            Color = Color3.fromRGB(255, 255, 255),
            Type = "DisplayName",
            Casing = "lowercase"
        },
        Weapon = {
            Enabled = false,
            Color = Color3.fromRGB(255, 255, 255),
            Casing = "lowercase"
        },
        Distance = {
            Enabled = false,
            Color = Color3.fromRGB(255, 255, 255),
            Casing = "lowercase"
        }
    },
    Bars = {
        Resize = false,
        Width = 2.5,
        Lerp = 0.05,
        Type = "Gradient",
        Health = {
            Enabled = false,
            Color1 = Color3.fromRGB(0, 255, 0),
            Color2 = Color3.fromRGB(255, 255, 0),
            Color3 = Color3.fromRGB(255, 0, 0)
        },
        Armor = {
            Enabled = false,
            Color1 = Color3.fromRGB(0, 0, 255),
            Color2 = Color3.fromRGB(135, 206, 235),
            Color3 = Color3.fromRGB(1, 0, 0),
            Armored = false
        }
    },
    Material = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255),
        Material = Enum.Material.ForceField
    },
    Highlight = {
        Enabled = false,
        BehindWalls = false,
        Color = Color3.fromRGB(255, 255, 255),
        Outline = Color3.fromRGB(0, 0, 0)
    },
    Chams = {
        Enabled = false,
        BehindWalls = false,
        Color = Color3.fromRGB(255, 255, 255)
    }
}

if not LPH_OBFUSCATED then
    LPH_JIT_MAX = function(...)
        return (...)
    end

    LPH_NO_VIRTUALIZE = function(...)
        return (...)
    end
end

local Overlay = {}
local draw = nil

function Overlay.NewFont(Name, Weight, Style, Asset)
    if not isfile(Asset.Id) then writefile(Asset.Id, Asset.Font) end
    if isfile(Name .. '.font') then delfile(Name .. '.font') end
    local Data = {
        name = Name,
        faces = {
            {
                name = 'Regular',
                weight = Weight,
                style = Style,
                assetId = getcustomasset(Asset.Id),
            },
        },
    }
    writefile(Name .. '.font', game:GetService("HttpService"):JSONEncode(Data))
    return getcustomasset(Name .. '.font');
end

local Fonts = {}

do
    local FontNames = {
        ["ProggyClean"] = "ProggyClean.ttf",
        ["Tahoma"] = "fs-tahoma-8px.ttf",
        ["Verdana"] = "Verdana-Font.ttf",
        ["SmallestPixel"] = "smallest_pixel-7.ttf",
        ["ProggyTiny"] = "ProggyTiny.ttf",
        ["Minecraftia"] = "Minecraftia-Regular.ttf",
        ["Tahoma Bold"] = "tahoma_bold.ttf"
    }

    for name, suffix in pairs(FontNames) do 
        Fonts[name] = Font.new(Overlay.NewFont(name, 400, "Normal", {
            Id = suffix,
            Font = game:HttpGet("https://raw.githubusercontent.com/yourhighnesskei/FSociety/main/Fonts/" .. suffix),
        }), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    end
end

Config = Config
Drawing = Drawing

local gui_inset = game:GetService("GuiService"):GetGuiInset()
local rotation_angle, last_tick = -45, tick()

local utility, connections, cache = {}, {}, {}
utility.funcs = utility.funcs or {}
local originalStates = {}
local increase = Vector3.new(2, 2, 2)
local vertices = { { -0.5, -0.5, -0.5 }, { -0.5, 0.5, -0.5 }, { 0.5, -0.5, -0.5 }, { 0.5, 0.5, -0.5 },{ -0.5, -0.5, 0.5 }, { -0.5, 0.5, 0.5 }, { 0.5, -0.5, 0.5 }, { 0.5, 0.5, 0.5 } };

utility.funcs.custom_bounds = function(model)
    local min_bound, max_bound = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
        
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            local cframe, size = part.CFrame, part.Size
            for _, v in ipairs(vertices) do
                local world_space = cframe:PointToWorldSpace(Vector3.new(v[1] * size.X, (v[2] + 0.2) * (size.Y + 0.2), v[3] * size.Z))
                min_bound = Vector3.new(math.min(min_bound.X, world_space.X), math.min(min_bound.Y, world_space.Y), math.min(min_bound.Z, world_space.Z))
                max_bound = Vector3.new(math.max(max_bound.X, world_space.X), math.max(max_bound.Y, world_space.Y), math.max(max_bound.Z, world_space.Z))
            end
        end
    end
        
    if min_bound == Vector3.new(math.huge, math.huge, math.huge) then return end
    local center = (min_bound + max_bound) / 2
    return CFrame.new(center), max_bound - min_bound + increase, center
end  

utility.funcs.get_case = function(text, casetype)
    casetype = casetype or "lowercase"
    
    if casetype == "UPPERCASE" then
        return text:upper()
    elseif casetype == "lowercase" then
        return text:lower()
    else
        return text
    end
end

utility.funcs.make_text = function(p)
    local d = Instance.new("TextLabel")
    d.Parent = p
    d.Size = UDim2.new(0, 4, 0, 4)
    d.BackgroundTransparency = 1
    d.TextColor3 = Color3.fromRGB(255, 255, 255)
    d.TextStrokeTransparency = 0
    d.TextScaled = false
    d.TextSize = 10
    d.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    d.FontFace = Fonts[Config.Text.Font]
    d.Text = ""
    return d
end

utility.funcs.create_box = function(parent, player_name)
    local box_container = Instance.new("Frame")
    box_container.Name = "BoxContainer_" .. player_name
    box_container.BackgroundTransparency = 1
    box_container.BorderSizePixel = 0
    box_container.Parent = parent
    
    local outline_frame = Instance.new("Frame")
    outline_frame.Name = "OutlineFrame"
    outline_frame.Size = UDim2.new(1, 2, 1, 2)
    outline_frame.Position = UDim2.new(0, -1, 0, -1)
    outline_frame.BackgroundTransparency = 1
    outline_frame.BackgroundColor3 = Config.Box.Outline
    outline_frame.BorderSizePixel = 0
    outline_frame.Parent = box_container
    
    local outline_stroke = Instance.new("UIStroke")
    outline_stroke.Name = "OutlineStroke"
    outline_stroke.Thickness = 0.9
    outline_stroke.Color = Color3.fromRGB(0, 0, 0)
    outline_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outline_stroke.Parent = outline_frame
    
    local box_frame = Instance.new("Frame")
    box_frame.Name = "Box_" .. player_name
    box_frame.Size = UDim2.new(1, 0, 1, 0)
    box_frame.Position = UDim2.new(0, 0, 0, 0)
    box_frame.BackgroundTransparency = 1
    box_frame.BorderSizePixel = 0
    box_frame.Parent = box_container
    
    local stroke = Instance.new("UIStroke")
    stroke.Name = "Stroke"
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = box_frame
    
    local gradient = Instance.new("UIGradient")
    gradient.Name = "Gradient"
    gradient.Rotation = 45
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    gradient.Parent = stroke
    
    local inline_frame = Instance.new("Frame")
    inline_frame.Name = "InlineFrame"
    inline_frame.Size = UDim2.new(1, -2, 1, -2)
    inline_frame.Position = UDim2.new(0, 1, 0, 1)
    inline_frame.BackgroundTransparency = 1
    inline_frame.BackgroundColor3 = Config.Box.Inline
    inline_frame.BorderSizePixel = 0
    inline_frame.Parent = box_container
    
    local inline_stroke = Instance.new("UIStroke")
    inline_stroke.Name = "InlineStroke"
    inline_stroke.Thickness = 0.9
    inline_stroke.Color = Color3.fromRGB(0, 0, 0)
    inline_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    inline_stroke.Parent = inline_frame
    
    local fill_frame = Instance.new("Frame")
    fill_frame.Name = "BoxFill"
    fill_frame.Size = UDim2.new(1, 0, 1, 0)
    fill_frame.Position = UDim2.new(0, 0, 0, 0)
    fill_frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill_frame.BackgroundTransparency = 0.5
    fill_frame.BorderSizePixel = 0
    fill_frame.Visible = false
    fill_frame.Parent = box_container
    
    local fill_gradient = Instance.new("UIGradient")
    fill_gradient.Name = "FillGradient"
    fill_gradient.Rotation = 45
    fill_gradient.Parent = fill_frame
    
    return {
        box = box_container,
        stroke = stroke,
        gradient = gradient,
        fill = fill_frame,
        fill_gradient = fill_gradient,
        outline_stroke = outline_stroke,
        inline_stroke = inline_stroke
    }
end

utility.funcs.render =
    LPH_NO_VIRTUALIZE(
    function(player)
        if not player then
            return
        end

        cache[player] = cache[player] or {}
        cache[player].Box = {}
        cache[player].Bars = {}
        cache[player].Text = {}
        
        local box_gui = Instance.new("ScreenGui")
        box_gui.Name = player.Name .. "_BoxESP"
        box_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        box_gui.Parent = game.CoreGui
        
        cache[player].Box.Full = utility.funcs.create_box(box_gui, player.Name)

        local Distance = Instance.new("ScreenGui")
        Distance.Parent = game.CoreGui
        
        local Name = Instance.new("ScreenGui")
        Name.Parent = game.CoreGui
        
        local Weapon = Instance.new("ScreenGui")
        Weapon.Parent = game.CoreGui
        
        cache[player].Text.Distance = utility.funcs.make_text(Distance)
        cache[player].Text.Weapon = utility.funcs.make_text(Weapon)
        cache[player].Text.Name = utility.funcs.make_text(Name)

        local armorGui = Instance.new("ScreenGui")
        armorGui.Name = player.Name .. "_ArmorBar"
        armorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        armorGui.Parent = game.CoreGui
        local armorOutline = Instance.new("Frame")
        armorOutline.BackgroundColor3 = Color3.new(0, 0, 0)
        armorOutline.BorderSizePixel = 0
        armorOutline.Name = "Outline"
        armorOutline.Parent = armorGui
        
        local armorFill = Instance.new("Frame")
        armorFill.BackgroundTransparency = 0
        armorFill.BorderSizePixel = 0
        armorFill.Name = "Fill"
        armorFill.Parent = armorOutline
        local armorGradient = Instance.new("UIGradient", armorFill)
        armorGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.Bars.Armor.Color1),
            ColorSequenceKeypoint.new(0.5, Config.Bars.Armor.Color2),
            ColorSequenceKeypoint.new(1, Config.Bars.Armor.Color3)
        })
        armorGradient.Rotation = 90

        cache[player].Bars.Armor = {
            Gui = armorGui,
            Outline = armorOutline,
            Frame = armorFill,
            Gradient = armorGradient,
            Tick = tick(),
            Rotation = 90
        }

        local healthGui = Instance.new("ScreenGui")
        healthGui.Name = player.Name .. "_HealthBar"
        healthGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        healthGui.Parent = game.CoreGui
        local healthOutline = Instance.new("Frame")
        healthOutline.BackgroundColor3 = Color3.new(0, 0, 0)
        healthOutline.BorderSizePixel = 0
        healthOutline.Name = "Outline"
        healthOutline.Parent = healthGui

        local healthFill = Instance.new("Frame")
        healthFill.BackgroundTransparency = 0
        healthFill.BorderSizePixel = 0
        healthFill.Name = "Fill"
        healthFill.Parent = healthOutline
        
        local healthGradient = Instance.new("UIGradient", healthFill)
        healthGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.Bars.Health.Color1),
            ColorSequenceKeypoint.new(0.5, Config.Bars.Health.Color2),
            ColorSequenceKeypoint.new(1, Config.Bars.Health.Color3)
        })
        healthGradient.Rotation = 90

        cache[player].Bars.Health = {
            Gui = healthGui,
            Outline = healthOutline,
            Frame = healthFill,
            Gradient = healthGradient,
            Tick = tick(),
            Rotation = 90
        }
    end
)

utility.funcs.clear_esp =
    LPH_NO_VIRTUALIZE(
    function(player)
        if not cache[player] then
            return
        end

        if cache[player].Box and cache[player].Box.Full then
            if cache[player].Box.Full.box then
                cache[player].Box.Full.box.Visible = false
            end
        end

        if cache[player].Text then
            if cache[player].Text.Distance then
                cache[player].Text.Distance.Visible = false
            end
            if cache[player].Text.Weapon then
                cache[player].Text.Weapon.Visible = false
            end
            if cache[player].Text.Name then
                cache[player].Text.Name.Visible = false
            end
        end

        if cache[player].Bars then
            if cache[player].Bars.Health and cache[player].Bars.Health.Frame then
                cache[player].Bars.Health.Frame.Visible = false
                cache[player].Bars.Health.Outline.Visible = false
            end

            if cache[player].Bars.Armor and cache[player].Bars.Armor.Frame then
                cache[player].Bars.Armor.Frame.Visible = false
                cache[player].Bars.Armor.Outline.Visible = false
            end
        end
    end
)

utility.funcs.update = 
    LPH_NO_VIRTUALIZE(
    function(player)
        if not player or not cache[player] then return end

        local character = player.Character
        local client_character = game.Players.LocalPlayer.Character
        local Camera = workspace.CurrentCamera

        if not character or not client_character then return end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        if not rootPart or not humanoid then
            utility.funcs.clear_esp(player)
            return
        end

        local cframe, size3d, center = utility.funcs.custom_bounds(character)
        if not cframe then
            utility.funcs.clear_esp(player)
            return
        end

        local screen_pos, on_screen = Camera:WorldToViewportPoint(center)
        if not on_screen then
            utility.funcs.clear_esp(player)
            return
        end

        local distance = (Camera.CFrame.Position - center).Magnitude
        local height = math.tan(math.rad(Camera.FieldOfView / 2)) * 2 * distance
        local scale = Vector2.new((Camera.ViewportSize.Y / height) * size3d.X,(Camera.ViewportSize.Y / height) * size3d.Y)
        local position = Vector2.new(screen_pos.X - scale.X / 2, screen_pos.Y - scale.Y / 2)

        local playerCache = cache[player]
        local fullBox = playerCache.Box.Full

        if Config.Box.Enabled and fullBox.box then
            fullBox.box.Visible = true
            fullBox.box.Position = UDim2.new(0, position.X, 0, position.Y - gui_inset.Y)
            fullBox.box.Size = UDim2.new(0, scale.X, 0, scale.Y)
            
            if fullBox.stroke then
                fullBox.stroke.Thickness = 2
            end
            
            if fullBox.gradient then
                fullBox.gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Config.Box.Gradient.Color1),
                    ColorSequenceKeypoint.new(0.5, Config.Box.Gradient.Color2),
                    ColorSequenceKeypoint.new(1, Config.Box.Gradient.Color3)
                })
            end
            
            if fullBox.outline_stroke then
                fullBox.outline_stroke.Color = Config.Box.Outline
            end
            
            if fullBox.inline_stroke then
                fullBox.inline_stroke.Color = Config.Box.Inline
            end
            
            if Config.Box.Filled.Enabled and fullBox.fill then
                fullBox.fill.Visible = true
                
                if fullBox.fill_gradient then
                    fullBox.fill_gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Config.Box.Filled.Gradient.Color1),
                        ColorSequenceKeypoint.new(0.5, Config.Box.Filled.Gradient.Color2),
                        ColorSequenceKeypoint.new(1, Config.Box.Filled.Gradient.Color3)
                    })
                    
                    if Config.Box.Filled.Gradient.Rotation.Moving.Enabled then
                        local current_tick = tick()
                        local delta = current_tick - last_tick
                        rotation_angle = rotation_angle + delta * Config.Box.Filled.Gradient.Rotation.Moving.Speed
                        fullBox.fill_gradient.Rotation = rotation_angle % 360
                        last_tick = current_tick
                    else
                        fullBox.fill_gradient.Rotation = Config.Box.Filled.Gradient.Rotation.Amount
                    end
                end
            elseif fullBox.fill then
                fullBox.fill.Visible = false
            end
        elseif fullBox.box then
            fullBox.box.Visible = false
        end
        
        local bar_height = scale.Y
        local bar_width = Config.Bars.Width
        local base_x = position.X
        local y = position.Y - gui_inset.Y
        
        local healthBarVisible = false
        local armorBarVisible = false
        
        if Config.Bars.Health.Enabled and humanoid then
            local targetHealth = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local lastHealth = playerCache.Bars.Health.LastHealth or targetHealth
            local lerpedHealth = lastHealth + (targetHealth - lastHealth) * Config.Bars.Lerp
            playerCache.Bars.Health.LastHealth = lerpedHealth
            
            local x = base_x - (bar_width + 4)
            local outline = playerCache.Bars.Health.Outline
            local fill = playerCache.Bars.Health.Frame
        
            if outline and fill then
                healthBarVisible = true
                outline.Visible = true
                
                if Config.Bars.Resize then
                    local currentBarHeight = math.max(bar_height * lerpedHealth, 2)
                    outline.Position = UDim2.new(0, x - 1, 0, y + bar_height - currentBarHeight - 1)
                    outline.Size = UDim2.new(0, bar_width + 2, 0, currentBarHeight + 2)
                    
                    fill.Visible = true
                    fill.Position = UDim2.new(0, 1, 0, 1)
                    fill.Size = UDim2.new(0, bar_width, 0, currentBarHeight)
                else
                    outline.Position = UDim2.new(0, x - 1, 0, y - 1)
                    outline.Size = UDim2.new(0, bar_width + 2, 0, bar_height + 2)
                    
                    fill.Visible = true
                    fill.Position = UDim2.new(0, 1, 0, (1 - lerpedHealth) * bar_height + 1)
                    fill.Size = UDim2.new(0, bar_width, 0, lerpedHealth * bar_height)
                end
                
                outline.BackgroundTransparency = 0.2
                
                if playerCache.Bars.Health.Gradient then
                    if Config.Bars.Type == "Gradient" then
                        playerCache.Bars.Health.Gradient.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Config.Bars.Health.Color1),
                            ColorSequenceKeypoint.new(0.5, Config.Bars.Health.Color2),
                            ColorSequenceKeypoint.new(1, Config.Bars.Health.Color3)
                        })
                    elseif Config.Bars.Type == "Solid Color" then
                        playerCache.Bars.Health.Gradient.Color = ColorSequence.new(Config.Bars.Health.Color1)
                    end
                end
            end
        else
            if playerCache.Bars.Health.Outline then playerCache.Bars.Health.Outline.Visible = false end
            if playerCache.Bars.Health.Frame then playerCache.Bars.Health.Frame.Visible = false end
        end
        
        if Config.Bars.Armor.Enabled and character then
            local bodyEffects = character:FindFirstChild("BodyEffects")
            local values = bodyEffects and bodyEffects:FindFirstChild("Armor")
            local armorValue = values and values.Value or 0
            local targetArmor = math.clamp(armorValue / 130, 0, 1)
            
            local shouldShowArmor = true
            if Config.Bars.Armor.Armored then
                shouldShowArmor = armorValue > 0
            end
            
            if shouldShowArmor then
                local lastArmor = playerCache.Bars.Armor.LastArmor or targetArmor
                local lerpedArmor = lastArmor + (targetArmor - lastArmor) * Config.Bars.Lerp
                playerCache.Bars.Armor.LastArmor = lerpedArmor
                
                local x
                if healthBarVisible then
                    x = base_x - (bar_width * 2 + 6 + 2)
                else
                    x = base_x - (bar_width + 4)
                end
                
                local outline = playerCache.Bars.Armor.Outline
                local fill = playerCache.Bars.Armor.Frame
                
                if outline and fill then
                    armorBarVisible = true
                    outline.Visible = true
                    
                    if Config.Bars.Resize then
                        local currentBarHeight = math.max(bar_height * lerpedArmor, 2)
                        outline.Position = UDim2.new(0, x - 1, 0, y + bar_height - currentBarHeight - 1)
                        outline.Size = UDim2.new(0, bar_width + 2, 0, currentBarHeight + 2)
                        
                        fill.Visible = true
                        fill.Position = UDim2.new(0, 1, 0, 1)
                        fill.Size = UDim2.new(0, bar_width, 0, currentBarHeight)
                    else
                        outline.Position = UDim2.new(0, x - 1, 0, y - 1)
                        outline.Size = UDim2.new(0, bar_width + 2, 0, bar_height + 2)
                        
                        fill.Visible = true
                        fill.Position = UDim2.new(0, 1, 0, (1 - lerpedArmor) * bar_height + 1)
                        fill.Size = UDim2.new(0, bar_width, 0, lerpedArmor * bar_height)
                    end
                    
                    outline.BackgroundTransparency = 0.2
                    
                    if playerCache.Bars.Armor.Gradient then
                        if Config.Bars.Type == "Gradient" then
                            playerCache.Bars.Armor.Gradient.Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Config.Bars.Armor.Color1),
                                ColorSequenceKeypoint.new(0.5, Config.Bars.Armor.Color2),
                                ColorSequenceKeypoint.new(1, Config.Bars.Armor.Color3)
                            })
                        elseif Config.Bars.Type == "Solid Color" then
                            playerCache.Bars.Armor.Gradient.Color = ColorSequence.new(Config.Bars.Armor.Color1)
                        end
                    end
                end
            else
                if playerCache.Bars.Armor.Outline then playerCache.Bars.Armor.Outline.Visible = false end
                if playerCache.Bars.Armor.Frame then playerCache.Bars.Armor.Frame.Visible = false end
            end
        else
            if playerCache.Bars.Armor.Outline then playerCache.Bars.Armor.Outline.Visible = false end
            if playerCache.Bars.Armor.Frame then playerCache.Bars.Armor.Frame.Visible = false end
        end
        
        local nameLabel = playerCache.Text.Name
        local weaponLabel = playerCache.Text.Weapon
        local distanceLabel = playerCache.Text.Distance
        local textOffset = 15
        local baseX = position.X + (scale.X / 2)
        local baseY = position.Y - gui_inset.Y
        
        if Config.Text.Name.Enabled then
            nameLabel.Visible = true
            nameLabel.Position = UDim2.new(0, baseX - (nameLabel.AbsoluteSize.X / 2), 0, baseY - textOffset + 6)
            nameLabel.TextColor3 = Config.Text.Name.Color
            nameLabel.FontFace = Fonts[Config.Text.Font]
            if Config.Text.Name.Type == "DisplayName" then
                nameLabel.Text = utility.funcs.get_case(player.DisplayName, Config.Text.Name.Casing)
            else
                nameLabel.Text = utility.funcs.get_case(player.Name, Config.Text.Name.Casing)
            end
        else
            nameLabel.Visible = false
        end
        
        local weaponPos, distancePos
        
        if Config.Text.Weapon.Enabled and Config.Text.Distance.Enabled then
            weaponPos = baseY + scale.Y + 5
            distancePos = baseY + scale.Y + 15
        elseif Config.Text.Weapon.Enabled and not Config.Text.Distance.Enabled then
            weaponPos = baseY + scale.Y + 5
        elseif not Config.Text.Weapon.Enabled and Config.Text.Distance.Enabled then
            distancePos = baseY + scale.Y + 5
        end
        
        if Config.Text.Weapon.Enabled then
            weaponLabel.Visible = true
            weaponLabel.Position = UDim2.new(0, baseX - (weaponLabel.AbsoluteSize.X / 2), 0, weaponPos)
            weaponLabel.TextColor3 = Config.Text.Weapon.Color
            weaponLabel.FontFace = Fonts[Config.Text.Font]
            local Weapon = player.Character:FindFirstChildOfClass("Tool")
            weaponLabel.Text = utility.funcs.get_case((Weapon and Weapon.Name) or "None", Config.Text.Weapon.Casing)
        else
            weaponLabel.Visible = false
        end
        
        if Config.Text.Distance.Enabled then
            distanceLabel.Visible = true
            distanceLabel.Position = UDim2.new(0, baseX - (distanceLabel.AbsoluteSize.X / 2), 0, distancePos)
            distanceLabel.TextColor3 = Config.Text.Distance.Color
            distanceLabel.FontFace = Fonts[Config.Text.Font]
            distanceLabel.Text = utility.funcs.get_case(string.format("[%.0f]", distance * 0.28), Config.Text.Distance.Casing)
        else
            distanceLabel.Visible = false
        end
    end
)

for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
    if player ~= game.Players.LocalPlayer then
        utility.funcs.render(player)
    end
end

game:GetService("Players").PlayerAdded:Connect(
    function(player)
        if player ~= game.Players.LocalPlayer then
            utility.funcs.render(player)
        end
    end
)

game:GetService("Players").PlayerRemoving:Connect(
    function(player)
        if player ~= game.Players.LocalPlayer then
            utility.funcs.clear_esp(player)
        end
    end
)

task.spawn(function()
    while true do
        task.wait(1)
        
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            if player ~= game.Players.LocalPlayer and player.Character then
                for _, obj in ipairs(player.Character:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" and obj.Name ~= "CUFF" then
                        if Config.Material.Enabled then
                            obj.Material = Config.Material.Material
                            obj.Color = Config.Material.Color
                            if obj:IsA("MeshPart") then
                                obj.TextureID = ""
                            end
                        else
                            if not originalStates[obj] then
                                originalStates[obj] = {Material = obj.Material, Color = obj.Color, TextureID = obj:IsA("MeshPart") and obj.TextureID or nil}
                            end
                            obj.Material = originalStates[obj].Material
                            obj.Color = originalStates[obj].Color
                            if obj:IsA("MeshPart") then
                                obj.TextureID = originalStates[obj].TextureID or ""
                            end
                        end
                    elseif obj:IsA("SpecialMesh") then
                        if Config.Material.Enabled then
                            obj.TextureId = ""
                        else
                            obj.TextureId = ""
                        end
                    elseif obj:IsA("Decal") and obj.Name == "face" then
                        if Config.Material.Enabled then
                            obj:Destroy()
                        end
                    end
                end
            
                for _, className in ipairs({"Pants", "Shirt", "ShirtGraphic"}) do
                    local clothing = player.Character:FindFirstChildOfClass(className)
                    if clothing then
                        if Config.Material.Enabled then
                            clothing:Destroy()
                        end
                    end
                end
                
                if Config.Chams.Enabled then
                    for _, part in ipairs(player.Character:GetChildren()) do
                        if part:IsA("BasePart") and part.Transparency ~= 1 and part.Name ~= "HumanoidRootPart" then
                            local chamsBox = part:FindFirstChild("Chams")
                            if not chamsBox then
                                chamsBox = Instance.new("BoxHandleAdornment")
                                chamsBox.Name = "Chams"
                                chamsBox.ZIndex = 4
                                chamsBox.Adornee = part
                                chamsBox.Size = part.Size + Vector3.new(0.02, 0.02, 0.02)
                                chamsBox.Parent = part
                            end
                            chamsBox.AlwaysOnTop = Config.Chams.BehindWalls
                            chamsBox.Color3 = Config.Chams.Color
                            chamsBox.Transparency = 0.5
                            
                            local glowBox = part:FindFirstChild("Glow")
                            if not glowBox then
                                glowBox = Instance.new("BoxHandleAdornment")
                                glowBox.Name = "Glow"
                                glowBox.AlwaysOnTop = false
                                glowBox.ZIndex = 3
                                glowBox.Adornee = part
                                glowBox.Transparency = 0.5
                                glowBox.Size = part.Size + Vector3.new(0.13, 0.13, 0.13)
                                glowBox.Parent = part
                            end
                            glowBox.Color3 = Config.Chams.Color
                        end
                    end
                else
                    for _, v in ipairs(player.Character:GetChildren()) do
                        if v:IsA("BasePart") and v.Transparency ~= 1 then
                            if v:FindFirstChild("Glow") then
                                v.Glow:Destroy()
                            end
                            if v:FindFirstChild("Chams") then
                                v.Chams:Destroy()
                            end
                        end
                    end
                end
            
                local highlight = player.Character:FindFirstChildOfClass("Highlight")
                if Config.Highlight.Enabled then
                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Parent = player.Character
                    end
                    highlight.FillColor = Config.Highlight.Color
                    highlight.OutlineColor = Config.Highlight.Outline
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0.5
                    if Config.Highlight.BehindWalls then
                        highlight.DepthMode = "AlwaysOnTop"
                    else
                        highlight.DepthMode = "Occluded"
                    end
                    highlight.Enabled = true
                elseif highlight then
                    if highlight.FillColor == Config.Highlight.Color then
                        highlight.Enabled = false
                    end
                end
            end
        end
    end
end)

connections.main = connections.main or {}

connections.main.RenderStepped =
    game:GetService("RunService").Heartbeat:Connect(
    function()
        for v, _ in pairs(cache) do
            if v then
                utility.funcs.update(v)
            end
        end
    end
)

return Config