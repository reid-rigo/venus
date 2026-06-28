local Math = {}

Math.abs = math.abs
Math.floor = math.floor
Math.ceil = math.ceil
Math.sqrt = math.sqrt
Math.pow = math.pow
Math.max = math.max
Math.min = math.min
Math.pi = math.pi

function Math.round(x)
  return math.floor(x + 0.5)
end

return Math
