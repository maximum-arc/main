local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Настройки
local MAX_DISTANCE = 50
local FOV_DEGREES = 60
local AIM_KEY = Enum.KeyCode.Q
local SMOOTHNESS = 0.5

-- Создаем 2D FOV-круг
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player.PlayerGui

local fovCircle = Instance.new("Frame")
fovCircle.Size = UDim2.fromOffset(300, 300)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.fromScale(0.5, 0.5)
fovCircle.BackgroundTransparency = 0.9
fovCircle.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
fovCircle.BorderSizePixel = 0
fovCircle.Parent = screenGui

local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1, 0)
circleCorner.Parent = fovCircle

-- Проверка NPC
local function isNPC(model)
	return model:FindFirstChild("Humanoid") and 
		model:FindFirstChild("Head") and 
		not Players:GetPlayerFromCharacter(model)
end

-- Проверка видимости
local function isVisible(target)
	local origin = camera.CFrame.Position
	local direction = (target.Position - origin).Unit
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local ray = workspace:Raycast(origin, direction * MAX_DISTANCE, raycastParams)
	return not ray or ray.Instance:IsDescendantOf(target.Parent)
end

-- Проверка FOV
local function isInFOV(targetPos)
	local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
	if not onScreen then 
		return false 
	end

	local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
	local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
	local distanceFromCenter = (targetScreenPos - center).Magnitude
	local fovRadius = (math.tan(math.rad(FOV_DEGREES/2))) * 500  -- Добавлена закрывающая скобка
	return distanceFromCenter <= fovRadius
end

-- Поиск цели
local function findBestTarget()
	local bestTarget = nil
	local closestAngle = math.rad(FOV_DEGREES/2)

	for _, npc in ipairs(workspace:GetDescendants()) do
		if isNPC(npc) then
			local head = npc:FindFirstChild("Head")
			if head then
				local distance = (head.Position - camera.CFrame.Position).Magnitude
				if distance <= MAX_DISTANCE and isInFOV(head.Position) and isVisible(head) then
					local cameraDirection = camera.CFrame.LookVector
					local targetDirection = (head.Position - camera.CFrame.Position).Unit
					local angle = math.acos(cameraDirection:Dot(targetDirection))

					if angle < closestAngle then
						closestAngle = angle
						bestTarget = head
					end
				end
			end
		end
	end

	return bestTarget
end

-- Плавное наведение
local function smoothAim(target)
	if not target then return end
	local currentCF = camera.CFrame
	local targetCF = CFrame.lookAt(camera.CFrame.Position, target.Position)
	camera.CFrame = currentCF:Lerp(targetCF, SMOOTHNESS)
end

-- Основной цикл
RunService.RenderStepped:Connect(function()
	if UserInputService:IsKeyDown(AIM_KEY) then
		smoothAim(findBestTarget())
	end
end)

-- Очистка
screenGui.Destroying:Connect(function()
	fovCircle:Destroy()
end)
