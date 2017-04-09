local logger = require('logger')
local oop = require('oop')

local message = oop.class {

	CONSTANTS = oop.const({ 
		HDR_OFFSET = 12,
		QR_MASK = 0x8000,
    	OPCODE_MASK = 0x7800,
    	AA_MASK = 0x0400,
    	TC_MASK = 0x0200,
    	RD_MASK = 0x0100,
    	RA_MASK = 0x8000,
    	RCODE_MASK = 0x000F,
	}),
	
	-- type of dns message
	TYPE = oop.const({ 
		QUERY = 0, 
		RESPONSE = 1 
	}),

    m_id = 0,
    m_qr = 0,
    m_opcode = 0,
    m_aa = 0,
    m_tc = 0,
    m_rd = 0,
    m_ra = 0,
    m_rcode = 0,
    
    m_qdCount = 0,
    m_anCount = 0,
    m_nsCount = 0,
    m_arCount = 0,

    m_qName = "",
    m_qType = 0,
    m_qClass = 0,

    data = "", --temp data's field

    new = function(self, type)
        self.m_qr = type
    end,

    asString = function(self)
    	return "ID: 0x" ..  string.format("%x", self.m_id) ..
    	"\n\tfields: [ QR: " .. self.m_qr .. " opCode: " .. self.m_opcode .. " ]" ..
    	"\n\tQDcount: " .. self.m_qdCount ..
    	"\n\tANcount: " .. self.m_anCount ..
    	"\n\tNScount: " .. self.m_nsCount ..
    	"\n\tARcount: " .. self.m_arCount .. "\n"
    end,

    decode_hdr = function(self, buffer)
    	buffer, self.m_id = self:get16bits(buffer)

    	local fields = 0
        buffer, fields = self:get16bits(buffer)
    	self.m_qr = bit.band(fields, self.CONSTANTS.QR_MASK)
    	self.m_opcode = bit.band(fields, self.CONSTANTS.OPCODE_MASK)
    	self.m_aa = bit.band(fields, self.CONSTANTS.AA_MASK)
    	self.m_tc = bit.band(fields, self.CONSTANTS.TC_MASK)
    	self.m_rd = bit.band(fields, self.CONSTANTS.RD_MASK)
    	self.m_ra = bit.band(fields, self.CONSTANTS.RA_MASK)

    	buffer, self.m_qdCount = self:get16bits(buffer)
    	buffer, self.m_anCount = self:get16bits(buffer)
    	buffer, self.m_nsCount = self:get16bits(buffer)
    	buffer, self.m_arCount = self:get16bits(buffer)
    end,

    code_hdr = function(self)

    	local buffer = ""
        buffer = self:put16bits(buffer, self.m_id)
    	local fields = bit.bor(bit.lshift(self.m_qr, 15), bit.lshift(self.m_opcode, 14), self.m_rcode)
    	buffer = self:put16bits(buffer, fields)

    	buffer = self:put16bits(buffer, self.m_qdCount)
    	buffer = self:put16bits(buffer, self.m_anCount)
    	buffer = self:put16bits(buffer, self.m_nsCount)
    	buffer = self:put16bits(buffer, self.m_arCount)
        return buffer
    end,


	log_buffer = function(self, buffer, size)

   		local text = "Message::log_buffer()" ..
    		"\nsize: " .. size .. " bytes" ..
    		"\n---------------------------------"

		for i = 1, size do
  			if (i % 10) == 1 then
  				text = text .. "\n" .. string.format("%02d", i) .. ":"
  			end
  			text = text .. string.format(" %02x", string.byte(buffer:sub(i,i)))
		end

    	text = text .. "\n---------------------------------"

    	logger.trace(text)
    end,

	get16bits = function(self, buffer) 

		local t1, t2 = string.byte(buffer, 1, 2)
        return string.sub(buffer, 3), bit.lshift(t1, 8) + t2
    end,

    get32bits = function(self, buffer) 

        local t1, t2, t3, t4 = string.byte(buffer, 1, 4)
        return string.sub(buffer, 5), bit.lshift(t1, 24) + bit.lshift(t2, 16) + bit.lshift(t3, 8) + t4
    end,

	put16bits = function(self, buffer, value)
    	return buffer .. string.char(bit.rshift(bit.band(value, 0xFF00), 8)) .. string.char(bit.band(value, 0xFF))
    end,

	put32bits = function(self, buffer, value)
		return buffer .. string.char(bit.rshift(bit.band(value, 0xFF000000), 24))
						.. string.char(bit.rshift(bit.band(value, 0xFF0000), 16))
						.. string.char(bit.rshift(bit.band(value, 0xFF00), 16))
						.. string.char(bit.rshift(bit.band(value, 0xFF), 16))
	end,

    decode_qname = function(self, buffer)

        self.m_qName = ""
        local pos = 1
        local result = nil
        local length = string.byte(buffer:sub(pos, pos))

        if length >= 192 then
            local offset = bit.band(bit.lshift(length, 8) + string.byte(buffer:sub(pos+1, pos+1)), 0x3FFF)
            result = string.sub(buffer, pos + 2)
            buffer = string.sub(self.data, offset + 1)
            length = string.byte(buffer:sub(pos, pos))
        end

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

        if result then
            return result
        else
            return string.sub(buffer, pos + 1)
        end

    end,
    
}

return message