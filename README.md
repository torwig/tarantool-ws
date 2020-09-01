1. Install Tarantool.

2. `sudo apt install luarocks`.

3. `luarocks --local install http`.

4. Edit `~/.luarocks/share/lua/5.1/http/websocket.lua` => line 29 should become:

   ```lua
   local utf8 = require "compat53.utf8" -- luacheck: ignore 113
   ```

5. Run `tarantool prepare.lua` to create a space, an index and a sequence.

6. Run `tarantool init.lua` to receive trades and write them to the space.

7. Run `tarantool binance.lua` (and/or `bitfinex.lua`, `coinbasepro.lua`, `kraken.lua`) in a separate console window or tab.