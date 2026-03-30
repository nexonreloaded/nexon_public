-- Jármű lehívási logika
RegisterNetEvent('car:spawnVehicle', function(modelName)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    -- 1. Modell validáció
    if not IsModelValid(modelName) then
        TriggerEvent('nxn:notify', {
            type = "simple",
            title = "Érvénytelen jármű modell: " .. modelName,
            icon = "error",
            category = "Rendszer",
            color = "error",
            duration = 5000,
        })
        return
    end

    -- 2. Modell betöltés
    local model = GetHashKey(modelName)
    RequestModel(model)

    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(100)
        timeout = timeout + 100
        if timeout >= 10000 then
            TriggerEvent('nxn:notify', {
                type = "simple",
                title = "A modell betöltése túllépte az időkorlátot.",
                icon = "error",
                category = "Rendszer",
                color = "error",
                duration = 5000,
            })
            return
        end
    end

    -- 3. Spawn
    local vehicle = CreateVehicle(
        model,
        playerCoords.x, playerCoords.y, playerCoords.z,
        GetEntityHeading(playerPed),
        true, false
    )

    SetVehicleNumberPlateText(vehicle, "ADMIN")
    SetPedIntoVehicle(playerPed, vehicle, -1)
    SetVehicleAsNoLongerNeeded(vehicle)
    SetModelAsNoLongerNeeded(model)

    -- 4. Sikeres értesítés
    exports['nxn-notifications']:ShowSimple({
        title = modelName .. " sikeresen spawnolva!",
        icon = "directions_car",
        category = "Rendszer",
        color = "success",
        duration = 4000,
    })
end)

-- Jármű törlési logika
RegisterNetEvent('delcar:deleteVehicle', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle ~= 0 then
        DeleteVehicle(vehicle)
        exports['nxn-notifications']:ShowSimple({
            title = "Legutóbbi jármű törölve!",
            icon = "no_crash",
            category = "Rendszer",
            color = "success",
            duration = 4000,
        })
    else
        -- Opcionális: értesítés ha a játékos nincs járműben
        exports['nxn-notifications']:ShowSimple({
            title = "Nem vagy járműben!",
            icon = "error",
            category = "Rendszer",
            color = "error",
            duration = 3000,
        })
    end
end)