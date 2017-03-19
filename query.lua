local message = require('message')
local logger = require('logger')
local oop = require('oop')

local query = oop.subclass(message) {
	
	m_qName = "",
    m_qType = 0,
    m_qClass = 0,

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

	decode = function(self, buffer, size)

    	logger.trace("Query::decode()")

    	self:log_buffer(buffer, size)

    	self:decode_hdr(buffer)
    	buffer = string.sub(buffer, self.CONSTANTS.HDR_OFFSET + 1)

    	buffer = self:decode_qname(buffer)

    	buffer, self.m_qType = self:get16bits(buffer)
    	buffer, self.m_qClass = self:get16bits(buffer)
	end,

	decode_qname = function(self, buffer)

    	self.m_qName = ""
    	local pos = 1
    	local length = string.byte(buffer:sub(pos, pos))
    	while length ~= 0 do
      		for i = 1, length do
      			pos = pos + 1
				self.m_qName = self.m_qName .. buffer:sub(pos, pos)      			
      		end
      		pos = pos + 1
      		length = string.byte(buffer:sub(pos, pos))
      		if length ~= 0 then
      			self.m_qName = self.m_qName .. '.'
      		end
    	end

    	return string.sub(buffer, pos + 1)

	end,
}

return query