#!/usr/bin/env tarantool
json = require('json')
local netbox = require 'net.box'
package.loaded["http.client"] = nil -- tarantool has a namespace clash
local websocket = require "http.websocket"

local symbolMap = {}
symbolMap["BTCUSD"] = "BTC/USD"
symbolMap["ETHUSD"] = "ETH/USD"
symbolMap["XRPUSD"] = "XRP/USD"

local conn = netbox.connect('127.0.0.1:3301')

local ws = websocket.new_from_uri("wss://api-pub.bitfinex.com/ws/2")
ws:connect()
ws:send('{"event": "subscribe", "channel": "trades", "symbol": "btcusd"}')

for data in ws:each() do
	if data == nil then
		break
	end

	local msg = json.decode(data)

	if msg[2] == 'te' then
		local trade_data = msg[3]

		local trade = {}
		trade.source = 'bitfinex'
		trade.ts = 	trade_data[2]
		trade.symbol = 'BTC/USD'
		trade.qty = math.abs(trade_data[3])
		trade.px = trade_data[4]

		local res = conn:call('put_trade', {trade})
		if res then
			print('trade sent', res)
		end
	end
end

ws:close()
