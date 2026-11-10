pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Networking as NM
import qs.theme
import qs.components
import qs.services

Column {
  id: root

  property string askingFor: ""
  readonly property bool keepOpen: askingFor !== ""

  spacing: Theme.menuGap

  property bool scanning: true
  property int scanBaseline: 0
  property var networks: []

  function startScan() {
    scanBaseline = networks.length;
    scanning = true;
    scanTimeout.restart();
  }

  function refreshNetworks() {
    const next = Network.listNetworks();
    if (!Utility.sameItems(networks, next))
      networks = next;
  }

  onNetworksChanged: {
    if (scanning && networks.length > scanBaseline)
      scanning = false;
  }

  Component.onCompleted: {
    Network.setScanning(true);
    refreshNetworks();
    startScan();
  }
  Component.onDestruction: Network.setScanning(false)

  Timer {
    id: refreshSoon
    interval: 250
    onTriggered: root.refreshNetworks()
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.refreshNetworks()
  }

  Connections {
    target: Network
    function onWifiNetworksChanged() {
      refreshSoon.start();
    }
    function onWifiEnabledChanged() {
      if (Network.wifiEnabled)
        root.startScan();
    }
  }

  Timer {
    id: scanTimeout
    interval: 6000
    onTriggered: root.scanning = false
  }

  Item {
    width: parent.width
    height: 44

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      text: "Wi-Fi"
      color: Theme.text
      font.family: Theme.labelFont
      font.pixelSize: Theme.menuHeaderSize
    }

    Spinner {
      anchors.right: wifiSwitch.left
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      visible: Network.wifiEnabled && (root.scanning || root.networks.length === 0)
    }

    Switch {
      id: wifiSwitch
      anchors.right: parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      checked: Network.wifiEnabled
      onToggled: Network.setWifiEnabled(!Network.wifiEnabled)
    }
  }

  MenuItem {
    width: parent.width
    visible: Network.wiredDevice !== null
    icon: "settings_ethernet"
    title: "Ethernet"
    subtitle: {
      const device = Network.wiredDevice;
      if (!device)
        return "";
      if (device.connected)
        return "Connected";
      if (device.state === NM.ConnectionState.Connecting)
        return "Connecting…";
      return device.hasLink ? "Cable plugged in" : "Cable unplugged";
    }
    active: Network.ethernet
    onClicked: Network.toggleWired()
  }

  Rectangle {
    width: parent.width - 24
    x: 12
    height: 1
    visible: Network.wiredDevice !== null && Network.wifiEnabled
    color: Theme.divider
  }

  EmptyState {
    visible: !Network.wifiEnabled
    text: "Wi-Fi is off"
  }

  MenuList {
    id: list
    visible: Network.wifiEnabled

    model: ScriptModel {
      values: root.networks
    }

    displaced: Transition {
      NumberAnimation {
        properties: "y"
        duration: Theme.animMove
        easing.type: Theme.easeOut
      }
    }
    move: Transition {
      NumberAnimation {
        properties: "y"
        duration: Theme.animMove
        easing.type: Theme.easeOut
      }
    }

    delegate: Column {
      id: entry

      required property var modelData
      readonly property bool secured: !Network.isOpen(modelData)
      readonly property bool asking: root.askingFor === modelData.name
      property string error: ""

      width: list.width

      Connections {
        target: entry.modelData
        function onConnectionFailed(reason) {
          entry.error = reason === NM.ConnectionFailReason.NoSecrets ? "Wrong password" : "Couldn't connect";
          if (entry.secured)
            root.askingFor = entry.modelData.name;
        }
        function onConnectedChanged() {
          if (entry.modelData.connected)
            entry.error = "";
        }
      }

      MenuItem {
        width: parent.width
        icon: Network.signalIcon(Network.percentOf(entry.modelData.signalStrength))
        title: entry.modelData.name
        active: entry.modelData.connected
        subtitle: {
          const n = entry.modelData;
          if (n.connected)
            return "Connected";
          if (n.state === NM.ConnectionState.Connecting)
            return "Connecting…";
          if (n.state === NM.ConnectionState.Disconnecting)
            return "Disconnecting…";
          if (entry.error !== "")
            return entry.error;
          if (n.known)
            return "Saved";
          return entry.secured ? "Secured" : "Open";
        }
        onClicked: {
          const n = entry.modelData;
          entry.error = "";
          if (n.connected)
            n.disconnect();
          else if (n.known || !entry.secured)
            n.connect();
          else
            root.askingFor = entry.asking ? "" : n.name;
        }

        Spinner {
          anchors.verticalCenter: parent.verticalCenter
          visible: entry.modelData.stateChanging
          tint: entry.modelData.connected ? Theme.textOnPrimary : Theme.primary
        }

        Icon {
          anchors.verticalCenter: parent.verticalCenter
          visible: entry.secured && !entry.modelData.known && !entry.modelData.stateChanging
          text: "lock"
          width: 32
          height: 32
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          color: Theme.textVariant
        }

        IconButton {
          visible: entry.modelData.known && !entry.modelData.stateChanging
          icon: "delete"
          iconColor: entry.modelData.connected ? Theme.textOnPrimary : Theme.textVariant
          onClicked: entry.modelData.forget()
        }
      }

      Collapse {
        id: collapse
        width: parent.width
        leading: Theme.menuGap
        shown: entry.asking
        onShownChanged: {
          if (shown && password.item) {
            password.item.text = "";
            password.item.focusInput();
          }
        }

        Loader {
          id: password
          width: parent.width
          active: collapse.visible
          onLoaded: item.focusInput()

          sourceComponent: PasswordField {
            navigable: true
            onAccepted: psk => {
              entry.error = "";
              entry.modelData.connectWithPsk(psk);
              root.askingFor = "";
            }
            onCanceled: root.askingFor = ""
          }
        }
      }
    }
  }
}
