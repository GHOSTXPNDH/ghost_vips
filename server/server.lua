local QBCore = GetResourceState('qb-core'):find('start') and exports['qb-core']:GetCoreObject() or nil

if not QBCore then return end

-- Carregar o arquivo de configuração
local Config = Config or {}

-------------------------------------------------------------------------------------------------------
-- -- Função para buscar o grupo VIP do jogador no banco de dados


QBCore = exports['qb-core']:GetCoreObject()

-- Função para buscar o grupo VIP do jogador no banco de dados
QBCore.Functions.CreateCallback('qb-salary:getVipGroup', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if Player then
        local citizenid = Player.PlayerData.citizenid

        -- Buscar o grupo VIP no banco de dados
        exports['oxmysql']:fetch('SELECT vip_group FROM players WHERE citizenid = @citizenid', {
            ['@citizenid'] = citizenid
        }, function(result)
            if result[1] and result[1].vip_group then
                cb(result[1].vip_group)  -- Retornar o grupo VIP do jogador
            else
                cb(nil)  -- Sem VIP
            end
        end)
    else
        cb(nil)  -- Caso não encontre o jogador
    end
end)

-- Função para pagar o salário baseado no grupo VIP
RegisterNetEvent('qb-salary:paySalary', function(source)
    local Player = QBCore.Functions.GetPlayer(source)

    if Player then
        -- Pegar o grupo VIP do jogador e pagar o salário
        QBCore.Functions.TriggerCallback('qb-salary:getVipGroup', source, function(vipGroup)
            if vipGroup and Config.Vips[vipGroup] then
                local vipConfig = Config.Vips[vipGroup]

                -- Certifique-se de que vipConfig é uma tabela e contém um número para salário
                if vipConfig and type(vipConfig) == "table" then
                    local salario = vipConfig.salario

                    -- Verifique se salario é um número e maior que 0
                    if type(salario) == "number" and salario > 0 then
                        -- Transferir o salário para o banco
                        Player.Functions.AddMoney('bank', salario, "Salário VIP")

                        -- Atualizar o timestamp do último pagamento
                        local timestamp = os.date('%Y-%m-%d %H:%M:%S')
                        exports['oxmysql']:execute('UPDATE players SET last_payment = @timestamp WHERE citizenid = @citizenid', {
                            ['@timestamp'] = timestamp,
                            ['@citizenid'] = Player.PlayerData.citizenid
                        })

                        -- Notificar o jogador que o salário foi pago
                        TriggerClientEvent('QBCore:Notify', source, 'Você recebeu seu salário de $' .. salario .. ' na sua conta bancária.', 'success')
                    else
                        TriggerClientEvent('QBCore:Notify', source, 'Sem salário disponível para o seu grupo VIP.', 'error')
                    end
                else
                    TriggerClientEvent('QBCore:Notify', source, 'Configuração VIP inválida.', 'error')
                end
            else
                TriggerClientEvent('QBCore:Notify', source, 'Você não pertence a um grupo VIP válido.', 'error')
            end
        end)
    else
        print("Erro: Jogador não encontrado.")
    end
end)

-- Comando para definir o grupo VIP de um jogador via servidor
QBCore.Commands.Add("setvip", "Definir grupo VIP de um jogador", {{name="id", help="ID do Jogador"}, {name="vip", help="Grupo VIP (ex: vip1, vip2)"}}, true, function(source, args)
    local targetId = tonumber(args[1])
    local vipGroup = args[2]
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)

    if targetPlayer then
        local citizenid = targetPlayer.PlayerData.citizenid

        -- Atualizar o grupo VIP no banco de dados
        exports['oxmysql']:execute('UPDATE players SET vip_group = @vip_group WHERE citizenid = @citizenid', {
            ['@vip_group'] = vipGroup,
            ['@citizenid'] = citizenid
        }, function(result)
            -- Adicione um print para depuração
            print('Resultado da consulta UPDATE:', result)
            
            -- Verificar se result é uma tabela e se possui um campo que indica o número de linhas afetadas
            if type(result) == "table" and result.affectedRows then
                local affectedRows = result.affectedRows

                -- Verifique se affectedRows é um número e maior que 0
                if type(affectedRows) == "number" and affectedRows > 0 then
                    TriggerClientEvent('QBCore:Notify', targetId, 'Seu grupo VIP foi atualizado para ' .. vipGroup, 'success')
                    TriggerClientEvent('QBCore:Notify', source, 'Grupo VIP do jogador atualizado com sucesso.', 'success')
                else
                    TriggerClientEvent('QBCore:Notify', source, 'Falha ao atualizar o grupo VIP.', 'error')
                end
            else
                -- Se result não contém o campo affectedRows ou não é uma tabela, mostre um erro mais detalhado
                print('Falha na atualização do VIP. Resultado inesperado:', result)
                TriggerClientEvent('QBCore:Notify', source, 'Falha ao atualizar o grupo VIP.', 'error')
            end
        end)
    else
        TriggerClientEvent('QBCore:Notify', source, 'Jogador não encontrado.', 'error')
    end
end)

-- Comando para verificar o tempo até o próximo pagamento
QBCore.Commands.Add("checktime", "Verificar o tempo restante até o próximo pagamento", {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)

    if Player then
        local citizenid = Player.PlayerData.citizenid

        -- Buscar o timestamp do último pagamento no banco de dados
        exports['oxmysql']:fetch('SELECT last_payment FROM players WHERE citizenid = @citizenid', {
            ['@citizenid'] = citizenid
        }, function(result)
            if result and result[1] and result[1].last_payment then
                local lastPayment = os.time(os.date("*t", result[1].last_payment))
                local currentTime = os.time()
                local tempoRestante = 1800 - (currentTime - lastPayment)  -- 1800 segundos = 30 minutos

                if tempoRestante > 0 then
                    local minutosRestantes = math.floor(tempoRestante / 60)
                    local segundosRestantes = tempoRestante % 60
                    TriggerClientEvent('QBCore:Notify', source, string.format('Tempo restante para o próximo pagamento: %02d:%02d', minutosRestantes, segundosRestantes), 'info')
                else
                    TriggerClientEvent('QBCore:Notify', source, 'Você pode receber seu pagamento agora.', 'success')
                end
            else
                -- Caso o last_payment seja nulo ou a consulta falhe
                TriggerClientEvent('QBCore:Notify', source, 'Não foi possível encontrar o tempo do último pagamento.', 'error')
            end
        end)
    else
        TriggerClientEvent('QBCore:Notify', source, 'Jogador não encontrado.', 'error')
    end
end)

-- Função para pagamento automático a cada 30 minutos
Citizen.CreateThread(function()
    local tempoSalario = 1800  -- 30 minutos em segundos

    while true do
        Citizen.Wait(tempoSalario * 1000)  -- Espera 30 minutos

        -- Paga o salário para todos os jogadores conectados
        for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
            TriggerEvent('qb-salary:paySalary', playerId)
        end
    end
end)

-- Comando para verificar e pagar o salário baseado no grupo VIP
QBCore.Commands.Add("getsalary", "Verificar e pagar o salário baseado no grupo VIP", {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)

    if Player then
        local citizenid = Player.PlayerData.citizenid

        -- Buscar o timestamp do último pagamento no banco de dados
        exports['oxmysql']:fetch('SELECT last_payment, vip_group FROM players WHERE citizenid = @citizenid', {
            ['@citizenid'] = citizenid
        }, function(result)
            if result and result[1] then
                local lastPayment = result[1].last_payment
                local vipGroup = result[1].vip_group
                local currentTime = os.time()
                local tempoRestante = 1800 - (currentTime - (lastPayment and os.time(os.date("*t", lastPayment)) or 0))  -- 30 minutos em segundos

                -- Buscar o salário do grupo VIP na configuração
                local vipConfig = Config.Vips[vipGroup]
                local salario = vipConfig and vipConfig.salario or 0

                -- Verificar se o salário é um número e maior que 0
                if type(salario) == "number" and salario > 0 then
                    if tempoRestante > 0 then
                        local minutosRestantes = math.floor(tempoRestante / 60)
                        local segundosRestantes = tempoRestante % 60
                        TriggerClientEvent('QBCore:Notify', source, string.format('Tempo restante para o próximo pagamento: %02d:%02d', minutosRestantes, segundosRestantes), 'info')
                    else
                        -- Efetuar o pagamento
                        Player.Functions.AddMoney('bank', salario, "Salário VIP")
                        
                        -- Atualizar o timestamp do último pagamento
                        exports['oxmysql']:execute('UPDATE players SET last_payment = @timestamp WHERE citizenid = @citizenid', {
                            ['@timestamp'] = os.date('%Y-%m-%d %H:%M:%S'),
                            ['@citizenid'] = citizenid
                        })

                        -- Notificar o jogador que o salário foi pago
                        TriggerClientEvent('QBCore:Notify', source, string.format('Você recebeu seu salário de $%d na sua conta bancária.', salario), 'success')
                    end
                else
                    TriggerClientEvent('QBCore:Notify', source, 'Não foi possível determinar o salário para o seu grupo VIP.', 'error')
                end
            else
                TriggerClientEvent('QBCore:Notify', source, 'Não foi possível encontrar o grupo VIP ou o timestamp do último pagamento.', 'error')
            end
        end)
    else
        TriggerClientEvent('QBCore:Notify', source, 'Jogador não encontrado.', 'error')
    end
end)
