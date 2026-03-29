-- 1. A /car parancs regisztrálásra kerül a kiegészítő indulásakor
-- 1.1 A játékos beírja a /car parancsot és a modell nevét a parancs után
RegisterCommand('car', function(source, args)

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local modelName = args[1] or 'adder'

    -- Ha a jármű nincs az adatbázisban hibaüzenetet dob
    if not IsModelValid(modelName) then
        TriggerEvent('nxn:notify', {
            type = "simple",
            title = "Érvénytelen modell: " .. modelName,
            icon ="car_crash",
            category = "Validációs hiba",
            color = "error",
            duration = 5000,
        })
        return
    end

    -- 2. Betöltjük a modelt
    local model = GetHashKey(modelName)
    RequestModel(model)

    -- 3. Várunk amíg betölt a model
    -- Ha a model nem tud betölteni 10 másodperc alatt hibaüzenetet dob
    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(500)
        timeout = timeout + 1
        if timeout > 20 then
            TriggerEvent('nxn:notify', {
            type = "simple",
            title = "Modell betöltési hiba",
            icon = "running_with_errors",
            category = "Rendszer",
            color = "error",
            duration = 5000,
            })
            return
        end
    end

    if not IsPlayerAceAllowed(playerPed(), "car.spawn") then
            TriggerEvent('nxn:notify', {
            type = "simple",
            title = "Nincs jogosultságod a parancshoz",
            icon = "error",
            category = "Rendszer",
            color = "error",
            duration = 5000,
            })
        return
    end

    -- 4. Jármű spawnolása
    local vehicle = CreateVehicle(model, playerCoords.x, playerCoords.y, playerCoords.z, GetEntityHeading(playerPed), true, false)
    -- print("^7Vehicle spawned: " .. modelName)

    SetVehicleNumberPlateText(vehicle, "ADMIN")
    SetPedIntoVehicle(playerPed, vehicle, -1)
    SetVehicleAsNoLongerNeeded(vehicle)

    -- 5. Küldünk egy notifikációs üzenetet (is) a játékosnak a lehívásról
    local spawncarnf = exports['nxn-notifications']:ShowSimple({
        title    = "Jármű lehívva: ".. modelName,
        icon     = "no_crash",
        category = "Rendszer",
        color    = "success",
        duration = 4000,
    })
end, false)


-- 6. Jármű törlése a /delcar paranncsal
-- Kizárólag a játékos legutolsó járművét töröljük, 
RegisterCommand('delcar', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 then
        DeleteVehicle(vehicle)
    end

    if not IsPlayerAceAllowed(playerPed(), "car.delete") then
            TriggerEvent('nxn:notify', {
            type = "simple",
            title = "Nincs jogosultságod a parancshoz",
            icon = "error",
            category = "Rendszer",
            color = "error",
            duration = 5000,
            })
        return
    end

    local delcarnf = exports['nxn-notifications']:ShowSimple({
    title    = "Legutóbbi jármű törölve!",
    icon     = "no_crash",
    category = "Rendszer",
    color    = "success",
    duration = 4000,
    })
end, false)