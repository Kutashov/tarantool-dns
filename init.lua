#!/usr/bin/tarantool
-- Tarantool init script

local log = require('log')
local console = require('console')
local server = require('http.server')
local resolver = require('resolver')
local query = require('query')
local response = require('response')
local STP = require "StackTracePlus"

debug.traceback = STP.stacktrace

local HOST = '127.0.0.1'
local PORT = 3311

box.cfg {
    log_level = 5,
    slab_alloc_arena = 1,
    --     -- background = true,
    logger = '1.log'
}

local m_resolver = resolver()
m_resolver:init("hosts")

if not box.space.records then
	s = box.schema.space.create('records')
    s:create_index('primary',
        {type = 'HASH', parts = {1, 'string', 2, 'unsigned'}})
end

-------------------------HANDLE REQUEST-------------------------------
local function handle_message(s, msg)
    -- local reply = nil
    -- return reply

    local m_query = query()
    m_query:decode(msg, string.len(msg))
    
    local m_response = response()
    m_resolver:process(m_query, m_response)

    local buffer = ""
    local nbytes, buffer = m_response:code()
    print("response " .. nbytes .. "byte")
    return buffer
end

local function tcp_handler(s, peer)
    s:write("Welcome to test server, " .. peer.host .."\n")
    while true do
        local line = s:read('\n')
        if line == nil then
            break -- error or eof
        end


        local reply = handle_message(s, line)
        if reply then
            print("reply:" .. reply)
            if not s:write(reply) then
                print("error writing reply")
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
        print("reply:" .. reply)
        s:sendto(peer.host, peer.port, msg)
    else
        print("udp reply not found")
        -- s:sendto(peer.host, peer.port, "nil")
    end
end

local u_server = udp_server.udp_server(HOST, PORT, udp_handler)
if not u_server then
    error('Failed to bind: ' .. errno.strerror())
end


print('Started')


require('console').start()

