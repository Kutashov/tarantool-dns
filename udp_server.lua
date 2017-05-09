#!/usr/bin/env tarantool

local socket = require('socket')
local errno = require('errno')
local fiber = require('fiber')
local log = require('log')

local udp_server = {}

function udp_server_loop(s, handler)
    fiber.name("udp_server")
    while true do
        -- try to read a datagram first
        local msg, peer = s:recvfrom()
        if msg == "" then
            -- socket was closed via s:close()
            error('server socket closed')
            break
        elseif msg ~= nil then
            -- got a new datagram
            -- log.info('handle msg')
            handler(s, peer, msg)
        else
            if s:errno() == errno.EAGAIN or s:errno() == errno.EINTR then
                -- socket is not ready
                -- log.info('Info not ready')
                s:readable() -- yield, epoll will wake us when new data arrives
                -- log.info('Info ready')
            else
                -- socket error
                local msg = s:error()
                s:close() -- save resources and don't wait GC
                error("Socket error: " .. msg)
            end
        end
    end
end

function udp_server.udp_server(host, port, handler)
    local s = socket('AF_INET', 'SOCK_DGRAM', 'udp')
    if not s then
        return nil -- check errno:strerror()
    end
    if not s:bind(host, port) then
        local e = s:errno() -- save errno
        s:close()
        errno(e) -- restore errno
        return nil -- check errno:strerror()
    end

    fiber.create(udp_server_loop, s, handler) -- start a new background fiber
    return s
end

return udp_server