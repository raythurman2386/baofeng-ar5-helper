.pragma library

// Pure-ish helpers for Baofeng AR-5 Helper.
// File IO is driven from Panel.qml via Process / FileView; this module
// handles paths, defaults, CSV, and argv building. Never auto-uploads.

function expandHome(path) {
  if (path === undefined || path === null)
    return ""
  var s = String(path)
  if (s.indexOf("~/") === 0 || s === "~") {
    var home = ""
    try {
      if (typeof Quickshell !== "undefined" && Quickshell.env)
        home = Quickshell.env("HOME") || ""
    } catch (e) {}
    if (!home)
      home = "/tmp"
    if (s === "~")
      return home
    return home + s.slice(1)
  }
  return s
}

function dataPaths(settings) {
  var dataDir = expandHome(settingValue(settings, "dataDir", "~/.local/share/baofeng-ar5"))
  var backupDir = expandHome(settingValue(settings, "backupDir", "~/.local/share/baofeng-ar5/backups"))
  return {
    dataDir: dataDir,
    backupDir: backupDir,
    channelsFile: dataDir + "/channels.json",
    checklistFile: dataDir + "/checklist.json",
    metaFile: dataDir + "/meta.json",
    exampleChannels: "assets/example-channels.json",
    noaaAsset: "assets/noaa.json"
  }
}

function settingValue(settings, key, fallback) {
  if (!settings)
    return fallback
  try {
    if (typeof settings.setting === "function")
      return settings.setting(key, fallback)
    if (settings[key] !== undefined && settings[key] !== null)
      return settings[key]
  } catch (e) {}
  return fallback
}

function defaultNoaaChannels() {
  return [
    { Location: 1, Name: "NOAA WX1 (ref)", Frequency: "162.550", Duplex: "", Offset: "0.000000", Tone: "", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "NFM", TStep: "5.00", Skip: "", Power: "Low" },
    { Location: 2, Name: "NOAA WX2 (ref)", Frequency: "162.400", Duplex: "", Offset: "0.000000", Tone: "", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "NFM", TStep: "5.00", Skip: "", Power: "Low" },
    { Location: 3, Name: "NOAA WX3 (ref)", Frequency: "162.475", Duplex: "", Offset: "0.000000", Tone: "", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "NFM", TStep: "5.00", Skip: "", Power: "Low" },
    { Location: 4, Name: "NOAA WX4 (ref)", Frequency: "162.425", Duplex: "", Offset: "0.000000", Tone: "", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "NFM", TStep: "5.00", Skip: "", Power: "Low" },
    { Location: 5, Name: "NOAA WX5 (ref)", Frequency: "162.450", Duplex: "", Offset: "0.000000", Tone: "", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "NFM", TStep: "5.00", Skip: "", Power: "Low" },
    { Location: 6, Name: "NOAA WX6 (ref)", Frequency: "162.500", Duplex: "", Offset: "0.000000", Tone: "", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "NFM", TStep: "5.00", Skip: "", Power: "Low" },
    { Location: 7, Name: "NOAA WX7 (ref)", Frequency: "162.525", Duplex: "", Offset: "0.000000", Tone: "", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "NFM", TStep: "5.00", Skip: "", Power: "Low" }
  ]
}

function defaultSimplexChannels() {
  return [
    { Location: 1, Name: "2m National Calling (verify / license)", Frequency: "146.520", Duplex: "", Offset: "0.000000", Tone: "", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "FM", TStep: "5.00", Skip: "", Power: "High" },
    { Location: 2, Name: "70cm National Calling (verify / license)", Frequency: "446.000", Duplex: "", Offset: "0.000000", Tone: "", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "FM", TStep: "5.00", Skip: "", Power: "High" },
    { Location: 3, Name: "2m Simplex 146.550 (verify / license)", Frequency: "146.550", Duplex: "", Offset: "0.000000", Tone: "", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "FM", TStep: "5.00", Skip: "", Power: "High" },
    { Location: 4, Name: "2m Simplex 146.580 (verify / license)", Frequency: "146.580", Duplex: "", Offset: "0.000000", Tone: "", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "FM", TStep: "5.00", Skip: "", Power: "High" },
    { Location: 5, Name: "70cm Simplex 446.500 (verify / license)", Frequency: "446.500", Duplex: "", Offset: "0.000000", Tone: "", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "FM", TStep: "5.00", Skip: "", Power: "High" },
    { Location: 6, Name: "FRS/GMRS ch1 RX-only reminder (no TX without license)", Frequency: "462.5625", Duplex: "", Offset: "0.000000", Tone: "", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "NFM", TStep: "5.00", Skip: "S", Power: "Low" },
    { Location: 7, Name: "MURS ch1 RX-only reminder (verify rules)", Frequency: "151.820", Duplex: "", Offset: "0.000000", Tone: "", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "NFM", TStep: "5.00", Skip: "S", Power: "Low" }
  ]
}

function defaultExampleChannels() {
  return [
    { Location: 0, Name: "Local Rpt (example)", Frequency: "146.940", Duplex: "-", Offset: "0.600000", Tone: "Tone", rToneFreq: "100.0", cToneFreq: "100.0", DtcsCode: "023", DtcsPolarity: "NN", Mode: "FM", TStep: "5.00", Skip: "", Power: "High" },
    { Location: 1, Name: "Club Simplex (example)", Frequency: "146.520", Duplex: "", Offset: "0.000000", Tone: "", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "FM", TStep: "5.00", Skip: "", Power: "High" },
    { Location: 2, Name: "UHF Rpt (example)", Frequency: "442.100", Duplex: "+", Offset: "5.000000", Tone: "Tone", rToneFreq: "88.5", cToneFreq: "88.5", DtcsCode: "023", DtcsPolarity: "NN", Mode: "FM", TStep: "5.00", Skip: "", Power: "High" }
  ]
}

function defaultChecklist() {
  return {
    downloadFirst: false,
    antennaRemoved: false,
    volumeMax: false,
    authorizedFreqs: false,
    neverAutoUploadAck: false
  }
}

function defaultMeta() {
  return {
    lastProgrammed: "",
    lastBackup: ""
  }
}

function parseChannelsJson(text) {
  try {
    var data = JSON.parse(text)
    if (Array.isArray(data))
      return data
    if (data && Array.isArray(data.channels))
      return data.channels
  } catch (e) {}
  return []
}

function channelsToJson(channels) {
  return JSON.stringify({ channels: channels || [] }, null, 2)
}

function parseChecklistJson(text) {
  try {
    var data = JSON.parse(text)
    var base = defaultChecklist()
    if (!data || typeof data !== "object")
      return base
    Object.keys(base).forEach(function (k) {
      if (typeof data[k] === "boolean")
        base[k] = data[k]
    })
    return base
  } catch (e) {
    return defaultChecklist()
  }
}

function checklistToJson(checklist) {
  return JSON.stringify(checklist || defaultChecklist(), null, 2)
}

function parseMetaJson(text) {
  try {
    var data = JSON.parse(text)
    var base = defaultMeta()
    if (!data || typeof data !== "object")
      return base
    if (typeof data.lastProgrammed === "string")
      base.lastProgrammed = data.lastProgrammed
    if (typeof data.lastBackup === "string")
      base.lastBackup = data.lastBackup
    return base
  } catch (e) {
    return defaultMeta()
  }
}

function metaToJson(meta) {
  return JSON.stringify(meta || defaultMeta(), null, 2)
}

var CSV_COLUMNS = [
  "Location", "Name", "Frequency", "Duplex", "Offset", "Tone",
  "rToneFreq", "cToneFreq", "DtcsCode", "DtcsPolarity", "Mode",
  "TStep", "Skip", "Power"
]

function csvEscape(value) {
  var s = value === undefined || value === null ? "" : String(value)
  if (/[",\n\r]/.test(s))
    return '"' + s.replace(/"/g, '""') + '"'
  return s
}

function channelsToCsv(channels) {
  var lines = [CSV_COLUMNS.join(",")]
  var list = channels || []
  for (var i = 0; i < list.length; i++) {
    var ch = list[i] || {}
    var row = []
    for (var c = 0; c < CSV_COLUMNS.length; c++) {
      var key = CSV_COLUMNS[c]
      var v = ch[key]
      if (v === undefined || v === null)
        v = ""
      row.push(csvEscape(v))
    }
    lines.push(row.join(","))
  }
  return lines.join("\n") + "\n"
}

function parseCsvLine(line) {
  var result = []
  var cur = ""
  var inQuotes = false
  for (var i = 0; i < line.length; i++) {
    var ch = line.charAt(i)
    if (inQuotes) {
      if (ch === '"') {
        if (i + 1 < line.length && line.charAt(i + 1) === '"') {
          cur += '"'
          i++
        } else {
          inQuotes = false
        }
      } else {
        cur += ch
      }
    } else if (ch === '"') {
      inQuotes = true
    } else if (ch === ",") {
      result.push(cur)
      cur = ""
    } else {
      cur += ch
    }
  }
  result.push(cur)
  return result
}

function parseChannelsCsv(text) {
  if (!text)
    return []
  var lines = String(text).replace(/\r\n/g, "\n").replace(/\r/g, "\n").split("\n")
  while (lines.length && lines[lines.length - 1] === "")
    lines.pop()
  if (lines.length < 2)
    return []
  var headers = parseCsvLine(lines[0])
  var out = []
  for (var i = 1; i < lines.length; i++) {
    if (!lines[i].trim())
      continue
    var cols = parseCsvLine(lines[i])
    var row = {}
    for (var h = 0; h < headers.length; h++) {
      var key = headers[h]
      var val = cols[h] !== undefined ? cols[h] : ""
      if (key === "Location") {
        var n = parseInt(val, 10)
        row[key] = isNaN(n) ? val : n
      } else {
        row[key] = val
      }
    }
    out.push(normalizeChannel(row))
  }
  return out
}

function normalizeChannel(ch) {
  var base = {
    Location: 0,
    Name: "",
    Frequency: "",
    Duplex: "",
    Offset: "0.000000",
    Tone: "",
    rToneFreq: "88.5",
    cToneFreq: "88.5",
    DtcsCode: "023",
    DtcsPolarity: "NN",
    Mode: "FM",
    TStep: "5.00",
    Skip: "",
    Power: "High"
  }
  if (!ch)
    return base
  Object.keys(base).forEach(function (k) {
    if (ch[k] !== undefined && ch[k] !== null)
      base[k] = ch[k]
  })
  return base
}

function filterChannels(channels, query) {
  var q = (query || "").trim().toLowerCase()
  if (!q)
    return channels || []
  return (channels || []).filter(function (ch) {
    var hay = [
      ch.Name, ch.Frequency, ch.Tone, ch.Power, ch.Duplex,
      ch.Mode, ch.rToneFreq, ch.cToneFreq
    ].join(" ").toLowerCase()
    return hay.indexOf(q) >= 0
  })
}

function channelDisplayTone(ch) {
  if (!ch)
    return ""
  if (ch.Tone === "DTCS" || ch.Tone === "DTCS-R")
    return "DTCS " + (ch.DtcsCode || "")
  if (ch.Tone === "Tone" || ch.Tone === "TSQL" || ch.Tone === "Cross")
    return (ch.rToneFreq || ch.cToneFreq || "") + " Hz"
  if (ch.Tone)
    return String(ch.Tone)
  return "—"
}

function chirpLaunchArgv(settings) {
  var cmd = settingValue(settings, "chirpCommand", "chirp")
  var model = settingValue(settings, "chirpModel", "5RM")
  // Launch CHIRP only — never pass upload flags. User programs via CHIRP UI.
  return [cmd]
}

function chirpModelLabel(settings) {
  return settingValue(settings, "chirpModel", "5RM")
}

function formatTimestamp(isoOrEmpty) {
  if (!isoOrEmpty)
    return "Never"
  try {
    var d = new Date(isoOrEmpty)
    if (isNaN(d.getTime()))
      return String(isoOrEmpty)
    return d.toLocaleString()
  } catch (e) {
    return String(isoOrEmpty)
  }
}

function nowIso() {
  return new Date().toISOString()
}

function shellQuote(s) {
  return "'" + String(s).replace(/'/g, "'\\''") + "'"
}

function writeFileCommand(path, contents) {
  // Write via shell printf/heredoc-safe base path; Panel uses Process.
  var b64 = ""
  try {
    // Qt Quickshell may not have btoa; Panel prefers FileView when available.
    if (typeof btoa === "function")
      b64 = btoa(unescape(encodeURIComponent(contents)))
  } catch (e) {}
  if (b64) {
    return ["bash", "-lc", "mkdir -p $(dirname " + shellQuote(path) + ") && echo " + shellQuote(b64) + " | base64 -d > " + shellQuote(path)]
  }
  // Fallback: escape carefully for printf %s
  var escaped = String(contents).replace(/\\/g, "\\\\").replace(/'/g, "'\\''")
  return ["bash", "-lc", "mkdir -p $(dirname " + shellQuote(path) + ") && printf '%s' " + shellQuote(contents) + " > " + shellQuote(path)]
}

function readFileCommand(path) {
  return ["bash", "-lc", "cat " + shellQuote(path) + " 2>/dev/null || true"]
}

function openPathCommand(path) {
  return ["bash", "-lc", "mkdir -p " + shellQuote(path) + " && (xdg-open " + shellQuote(path) + " >/dev/null 2>&1 || true)"]
}

function cableDetectCommand() {
  return ["bash", "-lc", "ls -1 /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | tr '\\n' ' ' || true"]
}

function ensureDirCommand(path) {
  return ["bash", "-lc", "mkdir -p " + shellQuote(path)]
}

function clean(s) {
  if (s === undefined || s === null)
    return ""
  return String(s).replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, "").slice(0, 500)
}

function safetyOneLiner() {
  return "Download from radio first. Remove antenna while programming. Volume at maximum."
}

function legalFooter() {
  return "You are responsible for authorized frequencies and licenses. This plugin never auto-uploads to the radio. Runs unsandboxed in the Omarchy shell."
}
