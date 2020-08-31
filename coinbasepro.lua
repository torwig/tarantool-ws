#!/usr/bin/env tarantool
json = require('json')
local netbox = require 'net.box'
package.loaded["http.client"] = nil -- tarantool has a namespace clash
local websocket = require "http.websocket"

local symbolMap = {}
symbolMap["BTC-USD"] = "BTC/USD"
symbolMap["ETH-USD"] = "ETH/USD"
symbolMap["XRP-USD"] = "XRP/USD"

local conn = netbox.connect('127.0.0.1:3301')

local ws = websocket.new_from_uri("wss://ws-feed.pro.coinbase.com")
ws:connect()
ws:send('{"type": "subscribe", "product_ids": ["bBTC-USD", "ETH-USD", "XRP-USD"], "channels": ["matches"]}')

for data in ws:each() do
	if data == nil then
		break
	end

	local msg = json.decode(data)
	
	if msg.type == 'match' then
		local product_id = msg.product_id
		local symbol = symbolMap[product_id]
		if symbol ~= nil then
            -- 2020-08-20T16:07:12.114768Z
		    local pattern = '(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+).(%d+)Z'
		    local time_str = msg.time
		    local tyear, tmonth, tday, thour, tminute, tsecond, tmsec = time_str:match(pattern)

		    local milliseconds = 1000*tonumber('0.' .. tmsec)

		    local ts = os.time({year=tyear, month=tmonth, day=tday, hour=thour, min=tminute, sec=tsecond})
		    local seconds = ts - os.time({year=1970, month=1, day=1, hour=0, min=0, sec=0})

		    local trade = {}
		    trade.source = 'coinbasepro'
		    trade.ts = seconds*1000 + math.floor(milliseconds)
		    trade.symbol = symbol
		    trade.qty = tonumber(msg.size)
		    trade.px = tonumber(msg.price)
	
		    local res = conn:call('put_trade', {trade})
		    if res then
		        print('trade sent', symbol, res)
		    end
		end
	end
end

ws:close()
