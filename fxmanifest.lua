fx_version 'cerulean'
game 'gta5'

author 'GHOST'
description 'Sistema de pagamento de salário VIP a cada 30 minutos com suporte a grupos VIPs'
version '1.0.0'

-- Scripts que serão carregados no servidor e no cliente
server_scripts {
    '@mysql-async/lib/MySQL.lua',  -- Certifique-se de estar usando o MySQL Async ou oxmysql
    'config.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}

-- Definir dependências, caso esteja usando qb-core
dependencies {
    'oxmysql'  -- Se estiver usando oxmysql para a conexão ao banco de dados
}
