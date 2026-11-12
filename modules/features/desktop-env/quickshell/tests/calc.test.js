// Unit tests for the launcher calculator.
//
// Calc.js imports the vendored expr-eval bundle and is a QML `.pragma library`
// file. The test loads the bundle into an isolated VM context, injects the
// ExprEval namespace, then loads Calc.js with those QML-only lines removed.

const { test } = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const vm = require('node:vm')

const launcherDir = path.join(__dirname, '..', 'config', 'launcher')
const exprEvalSource = fs.readFileSync(path.join(launcherDir, 'expr-eval.js'), 'utf8')
const calcSource = fs
  .readFileSync(path.join(launcherDir, 'Calc.js'), 'utf8')
  .replace(/^\s*\.pragma\s+library\s*$/m, '')
  .replace(/^\s*\.import\s+"expr-eval\.js"\s+as\s+ExprEval\s*$/m, '')

const sandbox = { console }
vm.createContext(sandbox)
vm.runInContext(exprEvalSource, sandbox)
sandbox.ExprEval = { Parser: sandbox.Parser, Expression: sandbox.Expression }
vm.runInContext(calcSource, sandbox)

const C = sandbox

test('evaluates arithmetic', () => {
  assert.equal(C.evaluate('2 + 2'), 4)
  assert.equal(C.evaluate('2 + 3 * 4'), 14)
  assert.equal(C.evaluate('(2 + 3) * 4'), 20)
  assert.equal(C.evaluate('2 ^ 3 ^ 2'), 512)
  assert.equal(C.evaluate('10 / 4'), 2.5)
  assert.equal(C.evaluate('7 % 4'), 3)
  assert.equal(C.evaluate('-5 + 2'), -3)
})

test('evaluates functions and constants', () => {
  assert.equal(C.evaluate('sqrt(2)').toFixed(6), '1.414214')
  assert.equal(C.evaluate('sin(pi / 4)').toFixed(6), '0.707107')
  assert.equal(C.evaluate('pi').toFixed(6), '3.141593')
})

test('rejects non-expressions and non-finite results', () => {
  assert.equal(C.evaluate('firefox'), null)
  assert.equal(C.evaluate('2 +'), null)
  assert.equal(C.evaluate('1 / 0'), null)
  assert.equal(C.evaluate('(1 + 2'), null)
  assert.equal(C.evaluate(''), null)
})

test('formats floating point results', () => {
  assert.equal(C.format(0.1 + 0.2), '0.3')
  assert.equal(C.format(4), '4')
})
