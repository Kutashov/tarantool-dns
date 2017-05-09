#! /bin/bash
kill `sudo lsof -t -i:53`
tarantool init.lua 
