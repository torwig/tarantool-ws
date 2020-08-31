fiber = require 'fiber'
queue = require 'queue'
local yaml = require 'yaml'

box.cfg{
    listen = '127.0.0.1:3301'
}
box.schema.user.grant('guest', 'super', nil, nil, { if_not_exists = true })

local source_settings = {}
source_settings['coinbasepro'] = {min_qty = 0.005, weight = 25}
source_settings['kraken']      = {min_qty = 0.005, weight = 25}
source_settings['binance']     = {min_qty = 0.005, weight = 25}
source_settings['bitfinex']    = {min_qty = 0.005, weight = 25}

local last_trades = {}

function get_next_id()
    return box.sequence.S:next()
end

function put_trade(trade)
    local source = trade.source
    local settings = source_settings[source]

    if settings == nil then
        return 0
    end

    local id = get_next_id()

    box.space.trades:insert{id, trade.source, trade.symbol, trade.ts, trade.qty, trade.px}

    if trade.qty >= settings.min_qty then
        last_trades[source] = trade

        return id
    else
        return 0
    end
end


function calculate_avg()
    local total_weight = 0
    local price_sum = 0

    for src, last_trade in pairs(last_trades) do
        local weight = source_settings[src].weight
        
        if weight ~= nil and weight > 0 then
            total_weight = total_weight + weight
            price_sum = price_sum + weight*last_trade.px
            print(src, weight, last_trade.px)
        end
    end

    if total_weight > 0 then
        local final_price = price_sum / total_weight
        print(final_price)
    end
end

function calculation_routine()
    calculate_avg()
    fiber.sleep(0.2)
end

--while true do
    --calculation_routine()
--end


if not fiber.self().storage.console then
    require'console'.start()
    os.exit()
end
