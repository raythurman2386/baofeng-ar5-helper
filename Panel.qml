import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.raythurman.baofeng-ar5"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var settings: null

  readonly property var barIdentity: hostWidget || root
  readonly property var paths: Model.dataPaths(root.settings)
  readonly property bool showNoaa: Model.settingValue(root.settings, "showNoaa", true) !== false

  property string activeTab: "my" // my | noaa | simplex
  property string searchQuery: ""
  property int selectedIndex: -1
  property var myChannels: []
  property var checklist: Model.defaultChecklist()
  property var meta: Model.defaultMeta()
  property string cableStatus: "Checking cable…"
  property string statusMessage: ""
  property bool dataLoaded: false

  readonly property var tabChannels: {
    if (root.activeTab === "noaa")
      return Model.defaultNoaaChannels()
    if (root.activeTab === "simplex")
      return Model.defaultSimplexChannels()
    return root.myChannels
  }

  readonly property var filteredChannels: Model.filterChannels(root.tabChannels, root.searchQuery)

  readonly property var selectedChannel: {
    if (root.selectedIndex < 0 || root.selectedIndex >= root.filteredChannels.length)
      return null
    return root.filteredChannels[root.selectedIndex]
  }

  function open() {
    root.controller.show()
    root.reloadAll()
    root.checkCable()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened)
      root.close()
    else
      root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function setting(key, fallback) {
    return Model.settingValue(root.settings, key, fallback)
  }

  function reloadAll() {
    ensureDirsProc.running = true
    readChannelsProc.running = true
    readChecklistProc.running = true
    readMetaProc.running = true
  }

  function persistChannels() {
    writeChannelsProc.command = Model.writeFileCommand(root.paths.channelsFile, Model.channelsToJson(root.myChannels))
    writeChannelsProc.running = true
  }

  function persistChecklist() {
    writeChecklistProc.command = Model.writeFileCommand(root.paths.checklistFile, Model.checklistToJson(root.checklist))
    writeChecklistProc.running = true
  }

  function persistMeta() {
    writeMetaProc.command = Model.writeFileCommand(root.paths.metaFile, Model.metaToJson(root.meta))
    writeMetaProc.running = true
  }

  function checkCable() {
    cableDetectProc.running = true
  }

  function launchChirp() {
    var argv = Model.chirpLaunchArgv(root.settings)
    chirpProc.command = argv
    chirpProc.running = true
    root.statusMessage = "Launching CHIRP (model hint: " + Model.chirpModelLabel(root.settings) + "). Never auto-upload."
  }

  function openBackups() {
    openBackupProc.command = Model.openPathCommand(root.paths.backupDir)
    openBackupProc.running = true
    root.meta.lastBackup = root.meta.lastBackup || ""
    root.statusMessage = "Opened backups folder."
  }

  function exportCsv() {
    var stamp = Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss")
    var outPath = root.paths.backupDir + "/export-" + stamp + ".csv"
    exportCsvProc.command = Model.writeFileCommand(outPath, Model.channelsToCsv(root.myChannels))
    exportCsvProc.running = true
    root.meta.lastBackup = Model.nowIso()
    root.persistMeta()
    root.statusMessage = "Exported CSV to " + outPath
  }

  function importCsv() {
    // Imports newest *.csv from backupDir if present; otherwise seeds examples.
    importCsvProc.command = [
      "bash", "-lc",
      "f=$(ls -1t " + Model.shellQuote(root.paths.backupDir) + "/*.csv 2>/dev/null | head -n1); "
        + "if [ -n \"$f\" ]; then echo \"FILE:$f\"; cat \"$f\"; else echo \"NONE\"; fi"
    ]
    importCsvProc.running = true
  }

  function copySelectedFrequency() {
    if (!root.selectedChannel)
      return
    var freq = Model.clean(root.selectedChannel.Frequency)
    copyProc.command = ["bash", "-lc", "printf '%s' " + Model.shellQuote(freq) + " | wl-copy 2>/dev/null || printf '%s' " + Model.shellQuote(freq) + " | xclip -selection clipboard 2>/dev/null || true"]
    copyProc.running = true
    root.statusMessage = "Copied frequency " + freq
  }

  function selectTab(tabId) {
    root.activeTab = tabId
    root.selectedIndex = root.filteredChannels.length ? 0 : -1
  }

  function fg() {
    return root.bar ? root.bar.foreground : Color.foreground
  }

  function muted() {
    return root.bar ? Qt.darker(root.bar.foreground, 1.35) : Color.muted
  }

  function fontFam() {
    return root.bar ? root.bar.fontFamily : Style.font.family
  }

  Component.onCompleted: {
    ensureDirsProc.command = [
      "bash", "-lc",
      "mkdir -p " + Model.shellQuote(root.paths.dataDir) + " " + Model.shellQuote(root.paths.backupDir)
    ]
  }

  Process {
    id: ensureDirsProc
    running: false
  }

  Process {
    id: readChannelsProc
    command: Model.readFileCommand(root.paths.channelsFile)
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parsed = Model.parseChannelsJson(text)
        if (parsed.length)
          root.myChannels = parsed
        else
          root.myChannels = Model.defaultExampleChannels()
        root.dataLoaded = true
        if (root.selectedIndex < 0 && root.filteredChannels.length)
          root.selectedIndex = 0
      }
    }
  }

  Process {
    id: readChecklistProc
    command: Model.readFileCommand(root.paths.checklistFile)
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.checklist = Model.parseChecklistJson(text)
      }
    }
  }

  Process {
    id: readMetaProc
    command: Model.readFileCommand(root.paths.metaFile)
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.meta = Model.parseMetaJson(text)
      }
    }
  }

  Process {
    id: writeChannelsProc
    running: false
  }

  Process {
    id: writeChecklistProc
    running: false
  }

  Process {
    id: writeMetaProc
    running: false
  }

  Process {
    id: cableDetectProc
    command: Model.cableDetectCommand()
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var t = (text || "").trim()
        if (t.length)
          root.cableStatus = "Cable/serial: " + t
        else
          root.cableStatus = "Cable/serial: none detected (/dev/ttyUSB* /dev/ttyACM*)"
      }
    }
  }

  Process {
    id: chirpProc
    running: false
  }

  Process {
    id: openBackupProc
    running: false
  }

  Process {
    id: exportCsvProc
    running: false
  }

  Process {
    id: importCsvProc
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = text || ""
        if (raw.indexOf("NONE") === 0) {
          root.myChannels = Model.defaultExampleChannels()
          root.persistChannels()
          root.statusMessage = "No CSV in backups; loaded example channels."
          return
        }
        var nl = raw.indexOf("\n")
        var body = nl >= 0 ? raw.slice(nl + 1) : ""
        var parsed = Model.parseChannelsCsv(body)
        if (parsed.length) {
          root.myChannels = parsed
          root.persistChannels()
          root.statusMessage = "Imported " + parsed.length + " channels from CSV."
          root.selectedIndex = 0
        } else {
          root.statusMessage = "CSV import failed or empty."
        }
      }
    }
  }

  Process {
    id: copyProc
    running: false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(Math.min(contentColumn.implicitHeight, Style.space(560)))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function (direction) {
        root.switchPanel(direction)
      }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: contentColumn
          width: parent.width
          spacing: Style.space(10)

          // Header
          Column {
            width: parent.width
            leftPadding: Style.space(16)
            rightPadding: Style.space(16)
            spacing: Style.space(4)

            Text {
              width: parent.width - Style.space(32)
              text: "Baofeng AR-5 Helper"
              textFormat: Text.PlainText
              color: root.fg()
              font.family: root.fontFam()
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Text {
              width: parent.width - Style.space(32)
              text: Model.safetyOneLiner()
              textFormat: Text.PlainText
              wrapMode: Text.WordWrap
              color: root.muted()
              font.family: root.fontFam()
              font.pixelSize: Style.font.bodySmall
            }
          }

          // Tabs
          Row {
            width: parent.width
            leftPadding: Style.space(16)
            spacing: Style.space(8)

            Repeater {
              model: {
                var tabs = [{ id: "my", label: "My Channels" }]
                if (root.showNoaa)
                  tabs.push({ id: "noaa", label: "NOAA" })
                tabs.push({ id: "simplex", label: "Simplex / Calling" })
                return tabs
              }

              delegate: Rectangle {
                required property var modelData
                width: tabLabel.implicitWidth + Style.space(16)
                height: Style.space(28)
                radius: Style.space(6)
                color: root.activeTab === modelData.id
                  ? (root.bar ? root.bar.activeColor : Color.accent)
                  : "transparent"
                border.width: 1
                border.color: root.muted()

                Text {
                  id: tabLabel
                  anchors.centerIn: parent
                  text: modelData.label
                  textFormat: Text.PlainText
                  color: root.fg()
                  font.family: root.fontFam()
                  font.pixelSize: Style.font.bodySmall
                  font.bold: root.activeTab === modelData.id
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.selectTab(modelData.id)
                }
              }
            }
          }

          // Search
          Rectangle {
            width: parent.width - Style.space(32)
            height: Style.space(32)
            x: Style.space(16)
            radius: Style.space(6)
            color: "transparent"
            border.width: 1
            border.color: root.muted()

            TextInput {
              id: searchInput
              anchors.fill: parent
              anchors.margins: Style.space(8)
              color: root.fg()
              font.family: root.fontFam()
              font.pixelSize: Style.font.body
              clip: true
              selectByMouse: true
              text: root.searchQuery
              onTextChanged: {
                root.searchQuery = text
                root.selectedIndex = root.filteredChannels.length ? 0 : -1
              }

              Text {
                anchors.fill: parent
                visible: !searchInput.text.length && !searchInput.activeFocus
                text: "Search name, frequency, tone…"
                textFormat: Text.PlainText
                color: root.muted()
                font.family: root.fontFam()
                font.pixelSize: Style.font.body
              }
            }
          }

          // Channel list header
          Row {
            width: parent.width - Style.space(32)
            x: Style.space(16)
            spacing: Style.space(8)

            Text {
              width: parent.width * 0.34
              text: "Name"
              textFormat: Text.PlainText
              color: root.muted()
              font.family: root.fontFam()
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
            Text {
              width: parent.width * 0.18
              text: "Freq"
              textFormat: Text.PlainText
              color: root.muted()
              font.family: root.fontFam()
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
            Text {
              width: parent.width * 0.16
              text: "Tone"
              textFormat: Text.PlainText
              color: root.muted()
              font.family: root.fontFam()
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
            Text {
              width: parent.width * 0.14
              text: "Power"
              textFormat: Text.PlainText
              color: root.muted()
              font.family: root.fontFam()
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
            Text {
              width: parent.width * 0.12
              text: "Dup"
              textFormat: Text.PlainText
              color: root.muted()
              font.family: root.fontFam()
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
          }

          // Channel list
          Column {
            width: parent.width
            spacing: 0

            Repeater {
              model: root.filteredChannels

              delegate: Rectangle {
                required property var modelData
                required property int index
                width: contentColumn.width
                height: Style.space(28)
                color: root.selectedIndex === index
                  ? (root.bar ? Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.12) : "#20ffffff")
                  : "transparent"

                Row {
                  anchors.fill: parent
                  anchors.leftMargin: Style.space(16)
                  anchors.rightMargin: Style.space(16)
                  spacing: Style.space(8)

                  Text {
                    width: parent.width * 0.34
                    anchors.verticalCenter: parent.verticalCenter
                    text: Model.clean(modelData.Name)
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: root.fg()
                    font.family: root.fontFam()
                    font.pixelSize: Style.font.bodySmall
                  }
                  Text {
                    width: parent.width * 0.18
                    anchors.verticalCenter: parent.verticalCenter
                    text: Model.clean(modelData.Frequency)
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: root.fg()
                    font.family: root.fontFam()
                    font.pixelSize: Style.font.bodySmall
                  }
                  Text {
                    width: parent.width * 0.16
                    anchors.verticalCenter: parent.verticalCenter
                    text: Model.clean(Model.channelDisplayTone(modelData))
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: root.muted()
                    font.family: root.fontFam()
                    font.pixelSize: Style.font.bodySmall
                  }
                  Text {
                    width: parent.width * 0.14
                    anchors.verticalCenter: parent.verticalCenter
                    text: Model.clean(modelData.Power || "—")
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: root.muted()
                    font.family: root.fontFam()
                    font.pixelSize: Style.font.bodySmall
                  }
                  Text {
                    width: parent.width * 0.12
                    anchors.verticalCenter: parent.verticalCenter
                    text: Model.clean(modelData.Duplex || "—")
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: root.muted()
                    font.family: root.fontFam()
                    font.pixelSize: Style.font.bodySmall
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.selectedIndex = index
                }
              }
            }

            Text {
              visible: root.filteredChannels.length === 0
              width: parent.width - Style.space(32)
              x: Style.space(16)
              text: "No channels match."
              textFormat: Text.PlainText
              color: root.muted()
              font.family: root.fontFam()
              font.pixelSize: Style.font.bodySmall
            }
          }

          // Selection + copy
          Row {
            width: parent.width
            leftPadding: Style.space(16)
            spacing: Style.space(8)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(220)
              text: root.selectedChannel
                ? ("Selected: " + Model.clean(root.selectedChannel.Name) + " @ " + Model.clean(root.selectedChannel.Frequency))
                : "No selection"
              textFormat: Text.PlainText
              elide: Text.ElideRight
              color: root.fg()
              font.family: root.fontFam()
              font.pixelSize: Style.font.bodySmall
            }

            Rectangle {
              width: copyLabel.implicitWidth + Style.space(16)
              height: Style.space(28)
              radius: Style.space(6)
              border.width: 1
              border.color: root.muted()
              color: "transparent"
              enabled: !!root.selectedChannel
              opacity: enabled ? 1 : 0.4

              Text {
                id: copyLabel
                anchors.centerIn: parent
                text: "Copy frequency"
                textFormat: Text.PlainText
                color: root.fg()
                font.family: root.fontFam()
                font.pixelSize: Style.font.bodySmall
              }

              MouseArea {
                anchors.fill: parent
                enabled: parent.enabled
                cursorShape: Qt.PointingHandCursor
                onClicked: root.copySelectedFrequency()
              }
            }
          }

          // Actions
          Flow {
            width: parent.width - Style.space(32)
            x: Style.space(16)
            spacing: Style.space(8)

            Repeater {
              model: [
                { id: "chirp", label: "Launch CHIRP" },
                { id: "backups", label: "Open backups" },
                { id: "import", label: "Import CSV" },
                { id: "export", label: "Export CSV" }
              ]

              delegate: Rectangle {
                required property var modelData
                width: actionLabel.implicitWidth + Style.space(16)
                height: Style.space(30)
                radius: Style.space(6)
                border.width: 1
                border.color: root.muted()
                color: "transparent"

                Text {
                  id: actionLabel
                  anchors.centerIn: parent
                  text: modelData.label
                  textFormat: Text.PlainText
                  color: root.fg()
                  font.family: root.fontFam()
                  font.pixelSize: Style.font.bodySmall
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (modelData.id === "chirp")
                      root.launchChirp()
                    else if (modelData.id === "backups")
                      root.openBackups()
                    else if (modelData.id === "import")
                      root.importCsv()
                    else if (modelData.id === "export")
                      root.exportCsv()
                  }
                }
              }
            }
          }

          Text {
            visible: root.statusMessage.length > 0
            width: parent.width - Style.space(32)
            x: Style.space(16)
            text: Model.clean(root.statusMessage)
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            color: root.muted()
            font.family: root.fontFam()
            font.pixelSize: Style.font.bodySmall
          }

          // Safety checklist
          Column {
            width: parent.width
            leftPadding: Style.space(16)
            rightPadding: Style.space(16)
            spacing: Style.space(4)

            Text {
              text: "Safety checklist"
              textFormat: Text.PlainText
              color: root.fg()
              font.family: root.fontFam()
              font.pixelSize: Style.font.subtitle
              font.bold: true
            }

            Repeater {
              model: [
                { key: "downloadFirst", label: "Download from radio first" },
                { key: "antennaRemoved", label: "Remove antenna while programming" },
                { key: "volumeMax", label: "Volume at maximum" },
                { key: "authorizedFreqs", label: "Only authorized frequencies / licenses" },
                { key: "neverAutoUploadAck", label: "Never auto-upload to the radio (ack)" }
              ]

              delegate: Row {
                required property var modelData
                spacing: Style.space(8)
                width: contentColumn.width - Style.space(32)

                Rectangle {
                  width: Style.space(16)
                  height: Style.space(16)
                  anchors.verticalCenter: parent.verticalCenter
                  radius: 3
                  border.width: 1
                  border.color: root.muted()
                  color: root.checklist[modelData.key] ? (root.bar ? root.bar.activeColor : Color.accent) : "transparent"

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      var next = JSON.parse(JSON.stringify(root.checklist))
                      next[modelData.key] = !next[modelData.key]
                      root.checklist = next
                      root.persistChecklist()
                    }
                  }
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width - Style.space(28)
                  text: modelData.label
                  textFormat: Text.PlainText
                  wrapMode: Text.WordWrap
                  color: root.fg()
                  font.family: root.fontFam()
                  font.pixelSize: Style.font.bodySmall
                }
              }
            }
          }

          // Timestamps + cable
          Column {
            width: parent.width
            leftPadding: Style.space(16)
            rightPadding: Style.space(16)
            spacing: Style.space(2)

            Text {
              width: parent.width - Style.space(32)
              text: "Last programmed: " + Model.formatTimestamp(root.meta.lastProgrammed)
              textFormat: Text.PlainText
              color: root.muted()
              font.family: root.fontFam()
              font.pixelSize: Style.font.bodySmall
            }
            Text {
              width: parent.width - Style.space(32)
              text: "Last backup: " + Model.formatTimestamp(root.meta.lastBackup)
              textFormat: Text.PlainText
              color: root.muted()
              font.family: root.fontFam()
              font.pixelSize: Style.font.bodySmall
            }
            Text {
              width: parent.width - Style.space(32)
              text: Model.clean(root.cableStatus)
              textFormat: Text.PlainText
              wrapMode: Text.WordWrap
              color: root.muted()
              font.family: root.fontFam()
              font.pixelSize: Style.font.bodySmall
            }
          }

          // Legal footer
          Text {
            width: parent.width - Style.space(32)
            x: Style.space(16)
            text: Model.legalFooter()
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            color: root.muted()
            font.family: root.fontFam()
            font.pixelSize: Style.font.bodySmall
          }

          Item {
            width: 1
            height: Style.space(8)
          }
        }
      }
    }
  }
}
