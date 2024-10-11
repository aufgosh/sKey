local _G = _G
local animationsCount, animations = 5, {}
local animationNum = 1
local EventFrame = CreateFrame("Frame", "EventFrame", UIParent, "SecureHandlerStateTemplate")
local addon_loaded = false
local bartender_loaded, dominos_loaded

-- Create animation frames and groups
for i = 1, animationsCount do
    local frame = CreateFrame("Frame")
    local texture = frame:CreateTexture()
    texture:SetTexture([[Interface\Cooldown\star4]])
    texture:SetAlpha(0)
    texture:SetAllPoints()
    texture:SetBlendMode("ADD")
    local animationGroup = texture:CreateAnimationGroup()

    local alpha1 = animationGroup:CreateAnimation("Alpha")
    alpha1:SetFromAlpha(0)
    alpha1:SetToAlpha(1)
    alpha1:SetDuration(0)
    alpha1:SetOrder(1)

    local scale1 = animationGroup:CreateAnimation("Scale")
    scale1:SetScale(1.5, 1.5)
    scale1:SetDuration(0)
    scale1:SetOrder(1)

    local scale2 = animationGroup:CreateAnimation("Scale")
    scale2:SetScale(0, 0)
    scale2:SetDuration(0.3)
    scale2:SetOrder(2)

    local rotation2 = animationGroup:CreateAnimation("Rotation")
    rotation2:SetDegrees(90)
    rotation2:SetDuration(0.3)
    rotation2:SetOrder(2)

    animations[i] = { frame = frame, animationGroup = animationGroup }
end

local function animate(button)
    if not button:IsVisible() then
        return
    end

    local animation = animations[animationNum]
    local frame = animation.frame
    local animationGroup = animation.animationGroup
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(button:GetFrameLevel() + 10)
    frame:SetAllPoints(button)
    animationGroup:Stop()
    animationGroup:Play()

    animationNum = (animationNum % animationsCount) + 1

    -- Add debug print to see the keybinding being retrieved
    C_Timer.After(0.3, function()
        if button:IsVisible() then
            local key = GetBindingKey(button:GetName())
            if key then
                RunBinding(key)
            end
        end
    end)
end


local function configButton(name, command)
    local button = _G[name]

    if button and not button.hooked then
        local key = GetBindingKey(command)

        -- Fallback binding for testing if no keybinding is found
        if not key then
            key = "0" -- Replace with any key you want for testing
            SetOverrideBinding(button, true, key, 'CLICK ' .. button:GetName() .. ':LeftButton')
        else
            SetOverrideBindingClick(button, true, key, button:GetName())
        end

        button.AnimateThis = animate
        SecureHandlerWrapScript(button, "OnClick", button, [[ 
            if self:IsVisible() then 
                self:CallMethod("AnimateThis")
            end 
        ]])

        button.hooked = true
    end
end


local function init()
    bartender_loaded = IsAddOnLoaded("Bartender4")
    dominos_loaded = IsAddOnLoaded("Dominos")

    if bartender_loaded and dominos_loaded then
        print("Bartender4 and Dominos loaded, stopping sKeyPress")
        return
    end

    if bartender_loaded then
        -- Example for Bartender4
        for i = 1, 10 do
            configButton(("BT4PetButton%d"):format(i), ("BONUSACTIONBUTTON%d"):format(i))
        end
    elseif dominos_loaded then
        -- Example for Dominos
        for i = 1, 60 do
            configButton(("DominosActionButton%d"):format(i), "CLICK DominosActionButton" .. i .. ":HOTKEY")
        end
    else
        -- Handle Blizzard's default action bars
        for i = 1, 12 do
            configButton(("ActionButton%d"):format(i), ("ACTIONBUTTON%d"):format(i))  -- First action bar
        end
        for i = 1, 12 do
            configButton(("MultiBarBottomLeftButton%d"):format(i), ("MULTIACTIONBAR1BUTTON%d"):format(i))  -- Second action bar
        end
        for i = 1, 12 do
            configButton(("MultiBarBottomRightButton%d"):format(i), ("MULTIACTIONBAR2BUTTON%d"):format(i))  -- Third action bar
        end
        -- Add more bars if needed, such as MultiBarRight and MultiBarLeft
    end
end

-- Start the addon
local function onStart(self, event)
    if not addon_loaded and event == "PLAYER_ENTERING_WORLD" then
        addon_loaded = true
        EventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
        init()
    end
end

-- Register the event for when the player enters the world
EventFrame:SetScript("OnEvent", onStart)
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
