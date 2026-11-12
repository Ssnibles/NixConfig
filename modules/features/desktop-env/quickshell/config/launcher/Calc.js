.pragma library
.import "expr-eval.js" as ExprEval

// Thin wrapper around the vendored expr-eval library.
var parser = new ExprEval.Parser()

// Lowercase aliases match what people type in a launcher.
parser.consts.pi = Math.PI
parser.consts.e = Math.E
parser.consts.tau = Math.PI * 2

function evaluate(input) {
  if (typeof input !== "string" || input.trim() === "") return null
  try {
    var value = parser.evaluate(input)
    if (typeof value !== "number" || !isFinite(value)) return null
    return value
  } catch (e) {
    return null
  }
}

function format(value) {
  if (value === null || value === undefined) return ""
  var rounded = Math.round(value * 1e10) / 1e10
  return String(rounded)
}
