#!/usr/bin/env tarantool
local log = require('log')
local json = require('json')
local netbox = require 'net.box'
local websocket = require('websocket')
local yaml = require('yaml')

local symbolMap = {}
symbolMap["BTCUSD"] = "BTC/USD"
symbolMap["ETHUSD"] = "ETH/USD"
symbolMap["XRPUSD"] = "XRP/USD"

local conn = netbox.connect('127.0.0.1:3301')

local ws, err = websocket.connect("wss://api-pub.bitfinex.com/ws/2", nil, {timeout=3})
if not ws then 
	log.info(err)
	return
end

ws:write('{"event": "subscribe", "channel": "trades", "symbol": "btcusd"}')

local packet = ws:read()

while packet ~= nil do
	local msg = json.decode(packet.data)
	
	if msg ~= nil then
        if msg[2] == 'te' then
			local trade_data = msg[3]
	
			local trade = {}
			trade.source = 'bitfinex'
			trade.ts = 	trade_data[2]
			trade.symbol = 'BTC/USD'
			trade.qty = math.abs(trade_data[3])
			trade.px = trade_data[4]

			log.info(yaml.encode(trade))
	
			--local res = conn:call('put_trade', {trade})
			--if res then
			--	print('trade sent', res)
			--end
		end
	end

    packet = ws:read()
end

ws:close()
