#!/usr/bin/env tarantool
json = require('json')
local netbox = require 'net.box'
package.loaded["http.client"] = nil -- tarantool has a namespace clash
local websocket = require "http.websocket"

local symbolMap = {}
symbolMap["BTCUSDT"] = "BTC/USD"
symbolMap["ETHUSDT"] = "ETH/USD"
symbolMap["XRPUSDT"] = "XRP/USD"

local conn = netbox.connect('127.0.0.1:3301')

local ws = websocket.new_from_uri("wss://stream.binance.com:9443/ws/btcusdt@aggTrade")
ws:connect()
ws:send('{"id": 1, "method": "SUBSCRIBE", "params": ["btcusdt@aggTrade", "ethusdt@aggTrade", "xrpusdt@aggTrade"]}')

for data in ws:each() do
	if data == nil then
		break
	end

	local msg = json.decode(data)

	local s = msg['s']	
	local symbol = symbolMap[s]

	if symbol ~= nil then
        if msg['e'] == 'aggTrade' then
			local trade = {}
			trade.source = 'binance'
			trade.ts = 	msg.E
			trade.symbol = symbol
			trade.qty = tonumber(msg.q)
			trade.px = tonumber(msg.p)
	
			local res = conn:call('put_trade', {trade})
			if res then
				print('trade sent', symbol, res)
			end
		end
	end
end

ws:close()
