#!/usr/bin/env tarantool

local logger = {}

local file

local working = false

function open_logger()
    if not file then
        file = io.open("test.log", "a")
    end
    io.output(file)
end

function logger.trace(text)
    if working then
        open_logger()
        io.write("\n ## " .. text)
        io.flush()
    end
    
end

function logger.error(text)
    if working then
        open_logger()
        io.write("\n !! " .. text)
        io.flush()
    end
    
end

return logger