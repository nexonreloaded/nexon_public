RegisterCommand('car', function(source, args, rawCommand)
    -- source = a játékos szerver ID-ja (integer), de itt natívan használható
    if not IsPlayerAceAllowed(source, "car.spawn") then
        TriggerClientEvent('nxn:notify', source, {
            type = "simple",
            title = "Nincs jogosultságod a parancshoz",
            icon = "error",
            category = "Rendszer",
            color = "error",
            duration = 5000,
        })
        return
    end
    -- Ha van jog, jelezzük a kliensnek hogy spawnolja a járművet
    TriggerClientEvent('car:spawnVehicle', source, args[1] or 'adder')
end, false)

RegisterCommand('delcar', function(source, args, rawCommand)
    -- 1. Jogosultság ellenőrzés
    if not IsPlayerAceAllowed(source, "car.delete") then
        TriggerClientEvent('nxn:notify', source, {
            type = "simple",
            title = "Nincs jogosultságod a parancshoz",
            icon = "error",
            category = "Rendszer",
            color = "error",
            duration = 5000,
        })
        return
    end

    -- 2. Ha van jog, szólunk a kliensnek hogy törölje a járművet
    TriggerClientEvent('delcar:deleteVehicle', source)
end, false)

