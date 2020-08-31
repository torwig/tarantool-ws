#!/usr/bin/env tarantool
json = require('json')
local netbox = require 'net.box'
package.loaded["http.client"] = nil -- tarantool has a namespace clash
local websocket = require "http.websocket"

local conn = netbox.connect('127.0.0.1:3301')

local symbolMap = {}
symbolMap["XBT/USD"] = "BTC/USD"
symbolMap["ETH/USD"] = "ETH/USD"
symbolMap["XRP/USD"] = "XRP/USD"

local ws = websocket.new_from_uri("wss://ws.kraken.com")
ws:connect()
ws:send('{"event": "subscribe", "pair": ["XBT/USD", "ETH/USD", "XRP/USD"], "subscription": {"name": "trade"}}')

for data in ws:each() do
    if data == nil then
		break
	end

	local msg = json.decode(data)

	local pair = msg[4]
	local symbol = symbolMap[pair]
	if symbol ~= nil then
        local trades = msg[2]
	    local channel = msg[3]

	    if channel == 'trade' and trades ~= nil then
            for i, t in ipairs(trades) do
			    local trade = {}
			    trade.source = 'kraken'
			    trade.ts = math.floor(tonumber(t[3])*1000)
			    trade.symbol = symbol
			    trade.qty = tonumber(t[2])
			    trade.px = tonumber(t[1])
	
			    local res = conn:call('put_trade', {trade})
			    if res then
				    print('trade sent', symbol, res)
			    end
		    end	
	    end
	end
end

ws:close()
