local logger = require('logger')
local record = require('record')
local oop = require('oop')
local response = require('response')

local resolver = oop.class {
	
	new = function(self)
    end,

	m_record_list,

	init = function(self, filename)
		logger.trace("Resolver::init() | filename: " .. filename)

		local file = io.open(filename, "r")

		if not file then
			logger.error("Could not open file: " .. filename)
			return
		end

 		for line in file:lines() do
 			self:store(line)
 		end

		io.close(file)
		self:print_records()
	end,

	store = function(self, line)
		local ip, _, domain = string.match(line, "([^ ]+)([ ]+)([^ ]+)")
		local record = record(ip, domain)
		self:add(record)
	end,

	add = function(self, new_record)

		logger.trace("Resolver::add() | Record: " ..
			new_record.ipAddress .. "-" ..
			new_record.domainName)

		local last_record = self.m_record_list

		if not self.m_record_list then
			self.m_record_list = new_record
			return
		end

		while last_record.next do
			last_record = last_record.next
		end
		last_record.next = new_record
	end,

	delete_list = function(self)
		local record = m_record_list
		while record do
			local next = record.next
			record = nil
			record = next
		end
	end,

	print_records = function(self)
		print("Reading records from file...")

		local record = self.m_record_list
		if not record then
			print("No records on list.")
		end

		while record do
			print("Record: " .. record.ipAddress .. " - " .. record.domainName)
			record = record.next
		end
	end,

	find = function(self, address, isIp)
		if address == "" then
			return ""
		end

		print("find: " .. address)

		local domain = ""
		local record = self.m_record_list
		while record do
			if record.ipAddress == address and isIp then
				domain = record.domainName
			elseif record.domainName == address and not isIp then
				domain = record.ipAddress
				break
			end
			record = record.next
		end

		logger.trace("Resolver::find() | ipAddres: " ..
			address .. " ---> " .. domain)

		if domain == "" then
			-- print("Not found\n")
		end

		return domain
	end,

	process = function(self, query)
		local response = response()
		logger.trace("Resolver::process()" .. query:asString())

		local qName = query.m_qName
		local ipAddress = self:convert(qName)
		local domainName
		if ipAddress == "" then
			domainName = self:find(qName, false)
			ipAddress = qName
		else
			domainName = self:find(ipAddress, true)
		end

		response.m_id = query.m_id
		response.m_qdCount = 1
		response.m_anCount = 1
		response.m_name = query.m_qName
		response.m_type = query.m_qType
		response.m_class = query.m_qClass


    	-- ip ="200.0.255.54";
    	print("domain:" .. domainName)
    	print("ip:" .. ipAddress)
    	print("qName:" .. qName)

    	if ipAddress == qName then
    		_, _, ip1, ip2, ip3, ip4 = string.find(domainName, "(%d+).(%d+).(%d+).(%d+)")
    		local arr = {}
    		arr[1] = string.char(ip1)
        	arr[2] = string.char(ip2)
        	arr[3] = string.char(ip3)
        	arr[4] = string.char(ip4)

        	response.m_raddr = arr
    	else
    		response.m_rdata = domainName
    	end

    	if domainName == "" then
    		-- print("NameError")
    		response.m_rcode = response.CODE.NAMEERROR
    		response.m_rdlength = 1
    	else
    		print(query:asString() .. "\nQuery for: " .. ipAddress ..
    			"\nResponse with: " .. domainName .. "\n")
    		response.m_rcode = response.CODE.OK
    		if ipAddress == qName then
    			response.m_rdLength = 4
    		else
    			response.m_rdLength = string.len(domainName) + 2 -- + initial label length + end dot
    		end

    		print(response:asString())
    	end

    	logger.trace("Resolver::process()" .. response:asString())

    	return response
	end,

	convert = function(self, qName)
		if not string.find(qName, ".in-addr.arpa", 1, true) then
			return ""
		end

		_, _, ip1, ip2, ip3, ip4 = string.find(qName, "(%d+).(%d+).(%d+).(%d+)")
		return ip4 .. "." .. ip3 .. "." .. ip2 .. "." .. ip1
	end
}

return resolver