// Unit tests for the pure helpers in config/Utils.js.
//
// Utils.js is a QML `.pragma library` file, so it can't be `require`d directly.
// We strip the pragma, run it in an isolated VM context, and provide a minimal
// Qt stub. Only pure functions (no Quickshell/Config access) are exercised.
//
// Run with:  node --test modules/features/desktop-env/quickshell/tests/

const { test } = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const vm = require('node:vm')

const utilsPath = path.join(__dirname, '..', 'config', 'Utils.js')
const source = fs
  .readFileSync(utilsPath, 'utf8')
  .replace(/^\s*\.pragma\s+library\s*$/m, '')

const exported = [
  'findFirst',
  'cleanTrackTitle',
  'cleanUrl',
  'pad2',
  'formatTime',
  'prettifyAppName',
  'formatActiveTitle',
  'volumeIcon',
  'batteryIcon',
  'findActivePlayer',
  'findBatteryDevice',
  'screenAt',
  'screenByName',
  'getOrdinalDate'
]

const sandbox = {
  // Minimal Qt stub: date formatting is exercised indirectly by getOrdinalDate.
  Qt: { formatDate: () => 'X' },
  console
}
vm.createContext(sandbox)
vm.runInContext(source, sandbox)

const U = {}
for (const name of exported) {
  assert.equal(typeof sandbox[name], 'function', `${name} should be defined in Utils.js`)
  U[name] = sandbox[name]
}

test('pad2 always yields two digits', () => {
  assert.equal(U.pad2(0), '00')
  assert.equal(U.pad2(7), '07')
  assert.equal(U.pad2(12), '12')
})

test('formatTime renders m:ss and clamps negatives', () => {
  assert.equal(U.formatTime(0), '0:00')
  assert.equal(U.formatTime(5), '0:05')
  assert.equal(U.formatTime(65), '1:05')
  assert.equal(U.formatTime(3599), '59:59')
  assert.equal(U.formatTime(-10), '0:00')
})

test('cleanTrackTitle strips counters and site suffixes', () => {
  assert.equal(U.cleanTrackTitle('(12) Never Gonna Give You Up - YouTube'), 'Never Gonna Give You Up')
  assert.equal(U.cleanTrackTitle('Song - SoundCloud'), 'Song')
  assert.equal(U.cleanTrackTitle('Song - Spotify'), 'Song')
  assert.equal(U.cleanTrackTitle('  spaced  '), 'spaced')
  assert.equal(U.cleanTrackTitle(''), '')
  assert.equal(U.cleanTrackTitle(null), '')
})

test('cleanUrl unwraps DBus-style quotes', () => {
  assert.equal(U.cleanUrl('"file:///tmp/x.png"'), 'file:///tmp/x.png')
  assert.equal(U.cleanUrl('  https://x/y  '), 'https://x/y')
  assert.equal(U.cleanUrl(''), '')
})

test('prettifyAppName maps known ids and title-cases unknown ids', () => {
  assert.equal(U.prettifyAppName('firefox'), 'Firefox')
  assert.equal(U.prettifyAppName('org.mozilla.firefox'), 'Firefox')
  assert.equal(U.prettifyAppName('vesktop'), 'Vesktop')
  assert.equal(U.prettifyAppName('discord.desktop'), 'Discord')
  assert.equal(U.prettifyAppName('some-random_app'), 'Some Random App')
  assert.equal(U.prettifyAppName(''), '')
})

test('formatActiveTitle normalises common window titles', () => {
  assert.equal(U.formatActiveTitle('file.txt - nvim', 'nvim'), 'Neovim: file.txt')
  assert.equal(U.formatActiveTitle('', 'firefox'), 'Firefox')
  assert.equal(U.formatActiveTitle('Firefox Developer Edition', 'firefox'), 'Firefox')
  // "Program: Title" is preserved as-is.
  assert.equal(U.formatActiveTitle('Terminal: htop', 'kitty'), 'Terminal: htop')
})

test('volumeIcon reflects mute and level', () => {
  assert.equal(U.volumeIcon(0.5, true), '\u{F075F}') // muted
  assert.equal(U.volumeIcon(0, false), '\u{F075F}') // silent
  assert.equal(U.volumeIcon(0.2, false), '\u{F057F}') // low
  assert.equal(U.volumeIcon(0.5, false), '\u{F0580}') // medium
  assert.equal(U.volumeIcon(0.9, false), '\u{F057E}') // high
})

test('batteryIcon handles absent / charging / plugged / level', () => {
  assert.equal(U.batteryIcon(50, false, false, false), '')
  assert.equal(U.batteryIcon(50, true, false, true), '\u{F0084}')
  assert.equal(U.batteryIcon(50, false, true, true), '\u{F06A5}')
  assert.equal(U.batteryIcon(0, false, false, true), '\u{F007A}')
  assert.equal(U.batteryIcon(50, false, false, true), '\u{F007E}')
  assert.equal(U.batteryIcon(100, false, false, true), '\u{F0079}')
})

test('findFirst returns the first match or null', () => {
  assert.equal(U.findFirst([1, 2, 3], (x) => x > 1), 2)
  assert.equal(U.findFirst([1, 2, 3], (x) => x > 9), null)
  assert.equal(U.findFirst([], () => true), null)
})

test('findActivePlayer prefers playing players with metadata', () => {
  const paused = { isPlaying: false, playbackState: 1, trackTitle: 'Paused' }
  const playingBare = { isPlaying: true, playbackState: 0 }
  const playingMeta = { isPlaying: true, playbackState: 0, trackTitle: 'Live' }
  assert.equal(U.findActivePlayer([paused], 1), paused)
  assert.equal(U.findActivePlayer([playingBare, paused], 1), playingBare)
  assert.equal(U.findActivePlayer([playingBare, playingMeta], 1), playingMeta)
  assert.equal(U.findActivePlayer([], 1), null)
})

test('findBatteryDevice reads the ObjectModel values list', () => {
  const good = { isLaptopBattery: true, ready: true }
  const devices = { values: [{ isLaptopBattery: false, ready: true }, good] }
  assert.equal(U.findBatteryDevice(devices, null), good)
})

test('findBatteryDevice falls back to the display device', () => {
  const display = { ready: true }
  assert.equal(U.findBatteryDevice({ values: [] }, display), display)
  assert.equal(U.findBatteryDevice(null, display), display)
  assert.equal(U.findBatteryDevice(null, null), null)
})

test('screenAt / screenByName resolve against a screen list', () => {
  const screens = [
    { name: 'eDP-1', x: 0, y: 0, width: 1920, height: 1080 },
    { name: 'HDMI-1', x: 1920, y: 0, width: 2560, height: 1440 }
  ]
  assert.equal(U.screenAt(10, 10, screens), screens[0])
  assert.equal(U.screenAt(2000, 100, screens), screens[1])
  assert.equal(U.screenAt(9999, 9999, screens), null)
  assert.equal(U.screenByName('HDMI-1', screens), screens[1])
  assert.equal(U.screenByName('DP-1', screens), null)
})

test('getOrdinalDate picks the correct ordinal suffix', () => {
  assert.equal(U.getOrdinalDate(new Date(2025, 9, 1)), '1st X')
  assert.equal(U.getOrdinalDate(new Date(2025, 9, 2)), '2nd X')
  assert.equal(U.getOrdinalDate(new Date(2025, 9, 3)), '3rd X')
  assert.equal(U.getOrdinalDate(new Date(2025, 9, 4)), '4th X')
  assert.equal(U.getOrdinalDate(new Date(2025, 9, 11)), '11th X')
  assert.equal(U.getOrdinalDate(new Date(2025, 9, 12)), '12th X')
  assert.equal(U.getOrdinalDate(new Date(2025, 9, 13)), '13th X')
  assert.equal(U.getOrdinalDate(new Date(2025, 9, 21)), '21st X')
  assert.equal(U.getOrdinalDate(new Date(2025, 9, 22)), '22nd X')
  assert.equal(U.getOrdinalDate(new Date(2025, 9, 23)), '23rd X')
})
