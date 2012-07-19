local parsec = require "parsec"

local function setup(inv, err)
  local p = parsec.new()

  p:set_usage("usage: app OPTIONS")
  p:set_descr("an awesome application which does so much stuff that the description text is more than 80 characters in length")

  p.bool = { "bool",   "a boolean" }
  p.str1 = { "string", "a string", required = true }
  p.str2 = { "string", "a string with an unexpectedly long description, even more unexpectedly long than in your wildest dreams" }
  p.num1 = { "number", "a number", default = 5 }
  p.num2 = { "number", "another number" }

  if inv == 1 then
    p.inv = { "nope", "this won't work" }
  elseif inv == 2 then
    p.inv = { "string" }  -- nor will this
  end

  if err then p:set_error(function(self) error(":(") end) end

  return p
end

local function test(name, ...)
  local args = {...}
  for i, v in pairs(args) do
    if not v then
      error(string.format("test %s failed: #%i", name, i))
      return false
    end
  end
  return true
end

-- test 1:
-- short args

arg = { "-b", "-s", "hello", "-t", "goodbye", "-n", "1", "-u", "3" }
local p = setup()
p:parse()

test("one", p.bool == true, p.str1 == "hello", p.str2 == "goodbye", p.num1 == 1, p.num2 == 3)

-- test 2:
-- long args, default args, unset args

arg = { "--str1", "hello" }
local p = setup()
p:parse()

test("two", p.bool == nil, p.str1 == "hello", p.str2 == nil, p.num1 == 5, p.num2 == nil)

-- test 3:
-- required args, override error()

arg = { }
local p = setup(nil, true)
local ret, err = pcall(function() p:parse() end)

test("three", ret == false, err:match(":%(") ~= nil)

-- test 4:
-- invalid arg type

local ret, err = pcall(setup, 1)

test("four", ret == false, err:match("Invalid type") ~= nil)

-- test 5:
-- invalid arg count

local ret, err = pcall(setup, 2)

test("five", ret == false, err:match("Incorrect number") ~= nil)

-- test 6:
-- help text formatting

local help = 
[[usage: app OPTIONS
an awesome application which does so much stuff that the description text is
more than 80 characters in length
  -b, --bool  a boolean
  -s, --str1  a string
  -t, --str2  a string with an unexpectedly long description, even more
              unexpectedly long than in your wildest dreams
  -n, --num1  a number
              (default: 5)
  -u, --num2  another number]]

test("six", p:help() == help)

-- test 7:
-- shortflag generation
-- TODO: allow setting shortflags manually?

local p = parsec.new()

p.abc = { "bool",   "a boolean" }
p.bcd = { "string", "a string", required = true }
local ret, err = pcall(function() p.ab  = { "string", "this won't work :(" } end)

test("seven", ret == false, err:match("Unable to create") ~= nil)

