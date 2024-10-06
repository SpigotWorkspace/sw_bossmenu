ESX = exports["es_extended"]:getSharedObject()

local openMenus = {}

ESX.RegisterServerCallback('sw_bossmenu:getData', function (source, cb, job, adminMode)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not adminMode then
        if xPlayer.getJob().name ~= job then
            return cb(false)
        end
    end
    local allowedFeatures = GetAllowedFeatures(xPlayer, adminMode)
    if ESX.Table.SizeOf(allowedFeatures) == 0 then
        return cb(false)
    end
    
    local jobs = ESX.GetJobs()
    local esxJobData = jobs[job]

    if esxJobData == nil then
        return cb(false)
    end
    

    local data = {}
    data.jobLabel = esxJobData.label
    data.allowedFeatures = allowedFeatures

    local identifier = GetIdentifier(xPlayer.source)
    openMenus[identifier] = adminMode
    cb(true, data)
end)


ESX.RegisterServerCallback('sw_bossmenu:getEmployees', function (source, cb, job)
    local xPlayer = ESX.GetPlayerFromId(source)
    local jobs = ESX.GetJobs()
    local esxJobData = jobs[job]
    local grades = esxJobData["grades"]
    local highestGrade = ESX.Table.SizeOf(grades)

    local identifier = GetIdentifier(xPlayer.source)
    local adminMode = openMenus[identifier]

    if not adminMode then
        local jobData = xPlayer.getJob()
        if jobData.name ~= job then
            --punish
            return cb(false)
        end
        highestGrade = jobData.grade
    end

    

    if IsAllowed(xPlayer, 'manageEmployees') then
        local data = {}
        local players = {}
        data.highestGrade = highestGrade
        local jobPlayers = ESX.GetExtendedPlayers('job', job)
        for _, jobPlayer in pairs(jobPlayers) do
            table.insert(players, {
                identifier = jobPlayer.getIdentifier(),
                firstname = jobPlayer.get('firstName'),
                lastname = jobPlayer.get('lastName'),
                job_grade = jobPlayer.getJob().grade
            })
        end
        local databasePlayers = MySQL.query.await('SELECT `identifier`, `firstname`, `lastname`, `job_grade` FROM `users` WHERE `job` = ? AND `job_grade` < ?', {
            job,
            highestGrade
        })

        for _, databasePlayer in pairs(databasePlayers) do
            local alreadyInTable = false
            for _, v in pairs(players) do
				if v.identifier == databasePlayer.identifier then
					alreadyInTable = true
				end
			end

			if not alreadyInTable then
                table.insert(players, databasePlayer)
            end
        end
        local index = 1
        for i = 1, #(players) do
            local value = players[index]
            if value.identifier == xPlayer.getIdentifier() or value.job_grade >= highestGrade then
                table.remove(players, index)
            else
                value.grade = grades[tostring(value["job_grade"])].label
                index = index + 1
            end
        end
        data.players = players
        cb(true, data)
    else
        cb(false)
    end
end)

ESX.RegisterServerCallback('sw_bossmenu:getPlayersInArea', function (source, cb, serverIds)
    local data = {}
    local allowed = IsAllowed(xPlayer, 'hirePlayer')
    if not allowed then
        return cb(data)
    end
    for _, id in pairs(serverIds) do
        local xTarget = ESX.GetPlayerFromId(id)
        if xTarget.getJob().name == 'unemployed' then
            table.insert(data, {
                identifier = xTarget.getIdentifier(),
                firstname = xTarget.get('firstName'),
                lastname = xTarget.get('lastName'),
            })
        end
    end
    cb(data)
end)

ESX.RegisterServerCallback('sw_bossmenu:hirePlayer', function (source, cb, identifier)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    local allowed = IsAllowed(xPlayer, 'hirePlayer')
    if allowed and xTarget.getJob().name == 'unemployed' then
        xTarget.setJob(xPlayer.getJob().name, 0)
        cb(true)
        return
    else
        --punish
    end
    cb(false)
end)

ESX.RegisterServerCallback('sw_bossmenu:onAction', function (source, cb, data)
    local action = data.action
    local targetIdentifier = data.identifier
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = GetIdentifier(xPlayer.source)
    local adminMode = openMenus[identifier]
    local jobData = xPlayer.getJob()

    if xPlayer.getIdentifier == identifier then cb(false) return end
    local allowed = IsAllowed(xPlayer, 'manageEmployees')
    if not allowed then cb(false) return end

    local highestGrade = jobData.grade
    if adminMode then
        highestGrade = -1
    end

    GetJobData(targetIdentifier, function (targetJobData)
        local targetJob = targetJobData.job
        local targetGrade = targetJobData.grade
        if (jobData.name ~= targetJob and not adminMode) or targetGrade == highestGrade then return end
        if action == 'promote' then
            local nextGrade = targetGrade + 1
            if nextGrade == highestGrade then return end
            SetGrade(targetIdentifier, targetJob, nextGrade, cb)
        elseif action == 'demote' then
            local nextGrade = targetGrade - 1
            if nextGrade < 0 then return end
            SetGrade(targetIdentifier, targetJob, nextGrade, cb)
        elseif action == 'fire' then
            SetGrade(targetIdentifier, 'unemployed', 0, cb)
        else
            cb(false)
        end
    end)
end)

function GetJobData(identifier, cb)
    local xTarget = ESX.GetPlayerFromIdentifier(identifier)

    local data = {}
    if xTarget ~= nil then
        local jobData = xTarget.getJob()
        data = {job = jobData.name, grade = jobData.grade}
        cb(data)
    else
        local jobData = MySQL.single.await('SELECT `job`, `job_grade` FROM `users` WHERE `identifier` = ? LIMIT 1', {
            identifier
        })
        data = {job = jobData.job, grade = jobData.job_grade}
        cb(data)
    end
end

function SetGrade(identifier, job, grade, cb)
    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget ~= nil then
        xTarget.setJob(job, grade)
        cb(true)
        return
    else
        MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', {
            job,
            grade,
            identifier
        })
        cb(true)
        return
    end
    cb(false)
end

function IsAllowed(xPlayer, action) 
    local identifier = GetIdentifier(xPlayer.source)
    local adminMode = openMenus[identifier]
    if adminMode then
        return Config.AllowedIdentifiers[identifier][action] or {}
    else
        local jobData = xPlayer.getJob()
        return Config.AllowedGrades[jobData.name][jobData.grade_name][action] or {}
    end
end

function GetAllowedFeatures(xPlayer, adminMode)
    if adminMode then
        local identifier = GetIdentifier(xPlayer.source)
        return Config.AllowedIdentifiers[identifier] or {}
    else
        local jobData = xPlayer.getJob()
        return Config.AllowedGrades[jobData.name][jobData.grade_name] or {}
    end
end

function GetIdentifier(source)
    return GetPlayerIdentifierByType(source, "license"):gsub("license:", "")
end

exports('IsAllowed', IsAllowed)