#!/usr/bin/tarantool
-- Tarantool init script

local log = require('log')
local console = require('console')
local server = require('http.server')


local HOST = '127.0.0.1'
local PORT = 3311

box.cfg {
    log_level = 5,
    slab_alloc_arena = 1,
    --     -- background = true,
    logger = '1.log'
}



if not box.space.records then
	s = box.schema.space.create('records')
    s:create_index('primary',
        {type = 'HASH', parts = {1, 'string', 2, 'unsigned'}})
end


-------------------------HANDLE REQUEST-------------------------------
local function handle_message(s, msg)
    local reply = nil
    return reply
end

local function tcp_handler(s, peer)
    s:write("Welcome to test server, " .. peer.host .."\n")
    while true do
        local line = s:read('\n')
        if line == nil then
            break -- error or eof
        end
        local reply = handle_message(s, msg)
        if reply then
            if not s:write("tcpreply: "..line) then
                break -- error or eof
            end
        end
    end
end

local server, addr = require('socket').tcp_server(HOST, PORT, tcp_handler)

local udp_server = require('udp_server')

local function udp_handler(s, peer, msg)
    -- You don't have to wait until socket is ready to send UDP
    -- s:writable()
    local reply = handle_message(s, msg)
    if reply then
        s:sendto(peer.host, peer.port, "udpreply: " .. msg)
    else
        s:sendto(peer.host, peer.port, "nil")
    end
end

local u_server = udp_server.udp_server(HOST, PORT, udp_handler)
if not u_server then
    error('Failed to bind: ' .. errno.strerror())
end


print('Started')


require('console').start()

