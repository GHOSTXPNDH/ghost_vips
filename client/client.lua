-- Carregar o arquivo de configuração
local Config = Config or {}

local tempoSalario = 1800 -- 30 minutos em segundos
local salarioTimer = 0

-- Loop para verificar o tempo e solicitar o salário
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- Espera de 1 segundo

        salarioTimer = salarioTimer + 1

        if salarioTimer >= tempoSalario then
            -- Solicitar ao servidor o pagamento do salário
            TriggerServerEvent('ghost-vips:requestSalary')

            -- Resetar o timer
            salarioTimer = 0
        end
    end
end)

-- Solicitar o grupo VIP e o salário do servidor
RegisterNetEvent('ghost-vips:requestSalary', function()
    -- Solicitar ao servidor o grupo VIP
    QBCore.Functions.TriggerCallback('ghost-vips:getVipGroup', function(vipGroup)
        if vipGroup then
            -- Solicitar ao servidor o pagamento do salário baseado no grupo VIP
            TriggerServerEvent('ghost-vips:paySalary', vipGroup)
        else
            -- Notificação caso não haja VIP
            QBCore.Functions.Notify('Você não tem um grupo VIP associado.', 'error')
        end
    end)
end)

-- Resetar o timer ao conectar
AddEventHandler('onClientMapStart', function()
    salarioTimer = 0
end)
