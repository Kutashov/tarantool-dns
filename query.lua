local message = require('message')
local logger = require('logger')
local oop = require('oop')

local query = oop.subclass(message) {

    new = function(self)
        self:super(self.TYPE.QUERY)
    end,

    asString = function(self)

    	return "\nQUERY { " ..
    		self:super() .. 
    		"\tQname: " .. self.m_qName ..
    		"\n\tQtype: " .. self.m_qType ..
    		"\n\tQclass: " .. self.m_qClass ..
    		" }"
    end,

	code = function(self, buffer)

    	-- Only needed for the DNS client
    	return 0
	end,

	decode = function(self, buffer)

    	logger.trace("Query::decode()")
    	self.data = buffer

    	self:log_buffer(buffer, string.len(buffer))

    	self:decode_hdr(buffer)
    	buffer = string.sub(buffer, self.CONSTANTS.HDR_OFFSET + 1)

    	buffer = self:decode_qname(buffer)

    	buffer, self.m_qType = self:get16bits(buffer)
    	buffer, self.m_qClass = self:get16bits(buffer)

    	self.data = ""
	end,

}

return query