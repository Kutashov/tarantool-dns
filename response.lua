local message = require('message')
local oop = require('oop')
local logger = require('logger')

local response = oop.subclass(message) {
	
	CODE = oop.const({ 
		OK = 0,
		FORMATERROR = 1,
		SERVERFAILURE = 2,
		NAMEERROR = 3,
		NOTIMPLEMENTED = 4,
		REFUSED = 5
	}),

	m_name = 0,
    m_qType = 0,
    m_qClass = 0,
    m_ttl = 0,
    m_rdLength = 0,
    m_rdata = "",
    m_raddr = 0,

    new = function(self)
        self:super(self.TYPE.RESPONSE)
    end,

    asString = function(self)
    	return "\nRESPONSE { " .. self:super() ..
    		"\tname: " .. self.m_name ..
    		"\n\ttype: " .. self.m_qType ..
    		"\n\tclass: " .. self.m_qClass ..
    		"\n\tttl: " .. self.m_ttl ..
    		"\n\trdLength: " .. self.m_rdLength ..
    		"\n\trdata: " .. self.m_rdata .. " }"
    end,

    decode = function(self, buffer, size)
    	self:decode_hdr(buffer)
    	buffer = string.sub(buffer, self.CONSTANTS.HDR_OFFSET + 1)

    	--Question section
    	buffer = self:decode_qname(buffer)
    	buffer, self.m_qType = self:get16bits(buffer)
    	buffer, self.m_qClass = self:get16bits(buffer)

    	--Answer section
    	
    end,

    code = function(self)
    	logger.trace("Response::code()")

    	local buffer = ""
    	buffer = self:code_hdr()

    	-- Code Question section
    	buffer = self:code_domain(buffer, self.m_name)
  
    	buffer = self:put16bits(buffer, self.m_qType)
    	buffer = self:put16bits(buffer, self.m_qClass)
    	
    	-- Code Answer section
    	buffer = self:code_domain(buffer, self.m_name)
    	buffer = self:put16bits(buffer, self.m_qType)
    	buffer = self:put16bits(buffer, self.m_qClass)
    	buffer = self:put32bits(buffer, self.m_ttl)
    	buffer = self:put16bits(buffer, self.m_rdLength)

    	if self.m_rdata == "" then
    		for i = 1, 4 do
    			buffer = buffer .. self.m_raddr[i]
    		end
    	else
        	buffer = self:code_domain(buffer, self.m_rdata);
    	end


    	self:log_buffer(buffer, string.len(buffer))

    	return buffer
    end,

    code_domain = function(self, buffer, domain)

		for i in string.gmatch(domain, "[^%.]+") do
			buffer = buffer .. string.char(bit.band(string.len(i), 0xFF)) .. i
		end
		return buffer .. string.char(0)
	end

}

return response


