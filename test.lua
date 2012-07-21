local parsec = require "parsec"

local function setup(inv, err)
  local p = parsec.new()

  p:set_descr("an awesome application which does so much stuff that the description text is more than 80 characters in length")

  p.bool  = { "bool",   "a boolean" }
  p.bool2 = { "bool",  "another boolean" }
  p.str1  = { "string", "a string", required = true }
  p.str2  = { "string", "a string with an unexpectedly long description, even more unexpectedly long than in your wildest dreams" }
  p.num1  = { "number", "a number", default = 5 }
  p.num2  = { "number", "another number" }
  p.param = { "param", "a parameter" }

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
-- compound shortflags

arg = { [0] = "test", "-bo", "-s", "hello", "-t", "goodbye", "-n", "1", "-u", "3", "param" }
local p = setup()
p:parse()

test("one", p.bool == true, p.bool2 == true, p.str1 == "hello", p.str2 == "goodbye", p.num1 == 1, p.num2 == 3, p.param == "param")

-- test 2:
-- long args, default args, unset args

arg = { [0] = "test", "--str1", "hello" }
local p = setup()
p:parse()

test("two", p.bool == nil, p.str1 == "hello", p.str2 == nil, p.num1 == 5, p.num2 == nil)

-- test 3:
-- error when unspecified args passed

arg = { [0] = "test", "--nope", "this won't work" }
local p = setup(nil, true)
local ret, err = pcall(function() p:parse() end)

test("three", ret == false, err:match(":%(") ~= nil)

-- test 4:
-- required args, override error()

arg = { [0] = "test" }
local p = setup(nil, true)
local ret, err = pcall(function() p:parse() end)

test("four", ret == false, err:match(":%(") ~= nil)

-- test 5:
-- error when invalid arg type specified

local ret, err = pcall(setup, 1)

test("five", ret == false, err:match("Invalid type") ~= nil)

-- test 6:
-- invalid arg count

local ret, err = pcall(setup, 2)

test("six", ret == false, err:match("Incorrect number") ~= nil)

-- test 7:
-- help text formatting

local help = 
[[usage: test (options) PARAM
an awesome application which does so much stuff that the description text is
more than 80 characters in length
options:
  -b, --bool   a boolean
  -o, --bool2  another boolean
  -s, --str1   a string
  -t, --str2   a string with an unexpectedly long description, even more
               unexpectedly long than in your wildest dreams
  -n, --num1   a number
  -u, --num2   another number]]

test("six", p:help() == help)

-- test 7:
-- shortflag generation
-- TODO: allow setting shortflags manually?

local p = parsec.new()

p.abc = { "bool",   "a boolean" }
p.bcd = { "string", "a string", required = true }
local ret, err = pcall(function() p.ab  = { "string", "this won't work :(" } end)

test("seven", ret == false, err:match("Unable to create") ~= nil)

