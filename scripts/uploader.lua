local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Загрузка RayField
local RayField = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()

local player = Players.LocalPlayer

-- Создаем главное окно
local Window = RayField:CreateWindow({
   Name = "Script Loader 1.0",
   LoadingTitle = "Загрузка интерфейса...",
   LoadingSubtitle = "by maximum-arc",
   ConfigurationSaving = {
      Enabled = false
   },
   KeySystem = false
})

-- Создаем вкладки
local CheatsTab = Window:CreateTab("Читы", 4483362458)
local UtilitiesTab = Window:CreateTab("Утилиты", 4483362458)

-- Функция для загрузки скрипта
local function LoadScript(scriptName)
    RayField:Notify({
        Title = "Загрузка",
        Content = "Загружаем "..scriptName.."...",
        Duration = 3,
        Image = 4483362458
    })
    
    local success, err = pcall(function()
        local url = "https://raw.githubusercontent.com/maximum-arc/main/main/scripts/"..scriptName
        local response = HttpService:GetAsync(url, true)
        loadstring(response)()
    end)
    
    if success then
        RayField:Notify({
            Title = "Успешно",
            Content = scriptName.." загружен!",
            Duration = 3,
            Image = 4483362458
        })
    else
        RayField:Notify({
            Title = "Ошибка",
            Content = "Не удалось загрузить: "..err,
            Duration = 5,
            Image = 4483362458
        })
    end
end

-- Добавляем читы
CheatsTab:CreateSection("Игровые читы")

CheatsTab:CreateButton({
    Name = "Dead Rails",
    Callback = function()
        LoadScript("dead_rails.lua")
    end
})

CheatsTab:CreateButton({
    Name = "Doors",
    Callback = function()
        LoadScript("doors.lua")
    end
})

CheatsTab:CreateButton({
    Name = "Underground War 2",
    Callback = function()
        LoadScript("undegroundwar2.lua")
    end
})

-- Добавляем утилиты
UtilitiesTab:CreateSection("Игровые утилиты")

UtilitiesTab:CreateButton({
    Name = "NPC Aim Assist",
    Callback = function()
        LoadScript("NPC_aim.lua")
    end
})

-- Кнопка закрытия
Window:CreateButton({
    Name = "Закрыть меню",
    Callback = function()
        RayField:Destroy()
    end
})
