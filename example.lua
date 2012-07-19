local parsec = require "parsec"

local p = parsec.new()

-- set the usage and description
p:set_usage("usage: app OPTIONS")
p:set_descr("an awesome application which does many things")

-- override the default error function
-- fires when a required option is not specified, or on p:error()
-- names the missing option, shows the helptext and quits
p:set_error( function(self, str) print(str) end )

-- set the options
p.bool   = { "bool",   "a boolean" }
p.string = { "string", "a string", required = true }
p.strong = { "string", "another string" }
p.number = { "number", "a number", default = 5 }
p.numero = { "number", "another number" }

-- parse the options
p:parse()

-- print the helptext (e.g. for --help)
if p.bool then print(p:help()) end

-- given the input: app.lua --bool -s hello -t "good bye"
print(p.bool, p.string, p.strong, p.number, p.numero)
-- true   hello   good bye   5   nil