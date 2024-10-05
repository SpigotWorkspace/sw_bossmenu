ESX = exports["es_extended"]:getSharedObject()

local open = false
local adminMode = false

RegisterCommand('bossmenu', function (source, args)
    local job = args[1] or ESX.GetPlayerData().job.name
    adminMode = true
    TriggerEvent('sw_bossmenu:openUI', job)
end)

local openJob = nil

TriggerEvent('chat:addSuggestion', '/bossmenu', TranslateCap('command_help'), {
    { name="job", help=TranslateCap('command_param_help') },
})


RegisterNetEvent('sw_bossmenu:openUI', function (job)
    ESX.TriggerServerCallback('sw_bossmenu:getData', function (success, data)
        if success then
            openJob = job
            open = not open
            if open then
                SendNUIMessage({
                    type = 'open',
                    data = data,
                    locales = Locales[Config.Locale]

                })
                SetNuiFocus(true, true)
            else
                SendNUIMessage({
                    type = 'close'
                })
                SetNuiFocus(false, false)
                adminMode = false
            end
        end
    end, job, adminMode)
end)

RegisterNUICallback('close', function (data, cb)
    SendNUIMessage({
        type = 'close'
    })
    SetNuiFocus(false, false)
    open = false
    adminMode = false
    cb({})
end)

RegisterNUICallback('getEmployeeData', function(data, cb)
    ESX.TriggerServerCallback('sw_bossmenu:getEmployees', function (success, data)
        if success then
            cb(data)
        end
    end, openJob)
end)

RegisterNUICallback('getHireData', function(data, cb)
    local playersInArea = ESX.Game.GetPlayersInArea(nil, 7)
    local serverIds = {}
    for _, player in pairs(playersInArea) do
        table.insert(serverIds, GetPlayerServerId(player))
    end
    ESX.TriggerServerCallback('sw_bossmenu:getPlayersInArea', function (data)
        cb(data)
    end, serverIds)
end)

RegisterNUICallback('getSocietyMoney', function(data, cb)
    ESX.TriggerServerCallback('esx_society:getSocietyMoney', function (money)
        cb{{money}}
    end, openJob)
end)

RegisterNUICallback('societyAction', function(data, cb)
    local type = data.type
    if type == 'deposit' then
        TriggerServerEvent('esx_society:depositMoney', openJob, data.amount)
    elseif type == 'withdraw' then
        TriggerServerEvent('esx_society:withdrawMoney', openJob, data.amount)
    end
    cb({})
end)

RegisterNUICallback('onAction', function (data, cb)
    ESX.TriggerServerCallback('sw_bossmenu:onAction', function (success)
        cb(success)
    end, data)
end)

RegisterNUICallback('hirePlayer', function (data, cb)
    ESX.TriggerServerCallback('sw_bossmenu:hirePlayer', function (success)
        cb(success)
    end, data.identifier)
end)