#!/usr/bin/tarantool
-- Tarantool init script

local log = require('log')
local console = require('console')
local server = require('http.server')
local resolver = require('resolver')
local query = require('query')
local response = require('response')
local socket = require('socket')
local errno = require('errno')
local expirationd = require('expirationd')
local fiber = require('fiber')

local HOST = '127.0.0.1'
--local PORT = 3311
local PORT = 53

box.cfg {
    log_level = 5,
    slab_alloc_arena = 12,
    -- background = true,
    logger = '1.log'
}

local m_resolver = resolver()
m_resolver:init("hosts")

if not box.space.records then
	s = box.schema.space.create('records')
    s:create_index('primary',
        {type = 'HASH', parts = {1, 'string', 2, 'unsigned'}})

    s:create_index('expire',
        {type = 'TREE', unique = false, parts = {4, 'unsigned'}})
    -- box.schema.user.grant('guest','read,write,execute','universe')
end


-- local function is_expired(args, tuple) 
--     return tuple[4] < os.time() 
-- end
-- function delete_tuple(space_id, args, tuple)
--     box.space[space_id]:delete({tuple[1], tuple[2]}) 
-- end
-- expirationd.start('clean_all', box.space.records.id, is_expired, {
--     process_expired_tuple = delete_tuple, args = nil,
--     tuples_per_iteration = 50, full_scan_time = 120
-- })

local expire_loop = fiber.create(
    function()
        local timeout = 1
        while 0 == 0 do
            local time = math.floor(fiber.time())
            for _, tuple in box.space.records.index.expire:pairs(time, {iterator = 'LT'}) do
                box.space.records:delete{tuple[1], tuple[2]}
            end
            fiber.sleep(timeout)
        end
    end
)

local function get_from_google(msg)
    local sock = socket('AF_INET', 'SOCK_DGRAM', 0)
    local val = sock:sendto('8.8.8.8', 53, msg)
    while true do
        -- try to read a datagram first
        local message, peer = sock:recvfrom()
        if message == "" then
            -- socket was closed via s:close()
            sock:close()
            return ""
        elseif message ~= nil then
            -- got a new datagram
            sock:close()
            return message
        else
            if sock:errno() == errno.EAGAIN or sock:errno() == errno.EINTR then
                -- socket is not ready
                sock:readable() -- yield, epoll will wake us when new data arrives
            else
                -- socket error
                local err = sock:error()
                print("Socket error: " .. err)
                sock:close() -- save resources and don't wait GC
                return ""
            end
        end
    end
end

-------------------------HANDLE REQUEST-------------------------------
local function handle_message(s, msg)

    local m_query = query()
    m_query:decode(msg)

    print(m_query.m_qName)

    local record = box.space.records:get{ m_query.m_qName, m_query.m_qType }
    if not record then
        local reply = get_from_google(msg)
        local m_response = response()
        local ttl = m_response:decode(reply)
        box.space.records:insert{ m_query.m_qName, m_query.m_qType, reply, os.time() + ttl, ttl }

        
        return reply
    else
        local reply = record[3]
        return m_query:put16bits("", m_query.m_id) .. string.sub(reply, 3)
    end

    
    
    -- local m_response = m_resolver:process(m_query)

    -- local buffer = ""
    -- local buffer = m_response:code()
    -- return buffer
end


local udp_server = require('udp_server')

local function udp_handler(s, peer, msg)
    -- You don't have to wait until socket is ready to send UDP
    -- s:writable()
    local reply = handle_message(s, msg)
    if reply then
        local sent = s:sendto(peer.host, peer.port, reply)
    else
        print("udp reply not found")
    end
end

local u_server = udp_server.udp_server(HOST, PORT, udp_handler)
if not u_server then
    error('Failed to bind: ' .. errno.strerror())
end


print('Started')

console.listen(3313)

console.start()

-- local function tcp_handler(s, peer)
--     s:write("Welcome to test server, " .. peer.host .."\n")

--     print("Doesn't work for now =(")
--     return

        -- local line = ""
        
        -- while true do
        --     local temp = s:sysread(1)
        --     if temp ~= "" and temp ~= nil then
        --         print("t:" .. temp)
        --         line = line .. temp
        --     else
        --         break
        --     end
        -- end
        
        -- print("req:" .. line) 

        -- local t1,t2 = string.byte(line, 1, 2)
        -- line = string.sub(line, 3)
        -- local size = bit.lshift(t1, 8) + t2
        -- if string.len(line) == size then
        --     local reply = handle_message(s, line)
        --     if reply then
        --         print(reply)
        --         print("present:" .. string.len(reply) .. " ".. string.format("%04x", string.len(reply)))
        --         reply = string.format("%04x", string.len(reply)) .. reply
        --         if s:writable() then
        --             print("writable")
        --         end
        --         local sent = s:write(msg)
        --         print("Sent:" .. sent)
        --         if not s:write(reply) then
        --             print("error writing reply")
        --         end
        --     end
        -- end

-- end

-- local server, addr = socket.tcp_server(HOST, PORT, tcp_handler)