#!/usr/bin/env tarantool

local logger = {}

local file

function open_logger()
    if not file then
        file = io.open("test.log", "a")
    end
    io.output(file)
end

function logger.trace(text)
    open_logger()
    io.write("\n ## " .. text)
    io.flush()
end

function logger.error(text)
    open_logger()
    io.write("\n !! " .. text)
    io.flush()
end

return logger