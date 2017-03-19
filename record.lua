local oop = require('oop')

local record = oop.class {

    	new = function(self, ip, domain)
        	self.ipAddress = ip
        	self.domainName = domain
    	end,

        -- IP address in dot notation.
        ipAddress,

        -- Domain name.
        domainName,

        -- Pointer to next record on the list
        next
}

return record