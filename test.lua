local parsec = require "parsec"

local function setup(inv)
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
  print(string.format("test %s passed", name))
  return true
end

-- test 1: shortflags

arg = { [0] = "test", "-bos", "hello", "-t", "goodbye", "-n", "1", "-u", "3", "param" }
local p = setup()
p:parse()

test("one", p.bool == true, p.bool2 == true, p.str1 == "hello", p.str2 == "goodbye", p.num1 == 1, p.num2 == 3, p.param == "param")

-- test 2: long flags, default args, unset args, multiple params

arg = { [0] = "test", "--str1", "hello", "param", "param2", "param3" }
local p = setup()
p.param2 = { "param", "another parameter", count = 2 }
p:parse()

test("two", p.bool == nil, p.str1 == "hello", p.str2 == nil, p.num1 == 5, p.num2 == nil, p.param == "param", p.param2[1] == "param2", p.param2[2] == "param3")

-- test 3: error when unspecified args passed, override error()

arg = { [0] = "test", "--nope", "this won't work" }
local p = setup()
p:set_error(function(self) error(":(") end)
local ret, err = pcall(function() p:parse() end)

test("three", ret == false, err:match(":%(") ~= nil)

-- test 4: required args/params missing, override error()

arg = { [0] = "test" }
local p = setup()
p:set_error(function(self) error(":(") end)
local ret, err = pcall(function() p:parse() end)

test("four", ret == false, err:match(":%(") ~= nil)

-- test 5: error when unknown arg type set

local ret, err = pcall(setup, 1)

test("five", ret == false, err:match("Invalid type") ~= nil)

-- test 6: error when no description set

local ret, err = pcall(setup, 2)

test("six", ret == false, err:match("Incorrect number") ~= nil)

-- test 7: help text formatting

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
               (default: 5)
  -u, --num2   another number]]

test("seven", p:get_help() == help)

-- test 8: shortflag generation

local p = parsec.new()

p.abc = { "bool",   "a boolean" }
p.bcd = { "string", "a string", required = true }
local ret, err = pcall(function() p.ab  = { "string", "this won't work :(" } end)

test("eight", ret == false, err:match("Unable to create") ~= nil)

print("all tests passed \\o/")