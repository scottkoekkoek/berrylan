import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import BerryLan 1.0
import "components"

ApplicationWindow {
    id: app
    visible: true
    width: 320
    height: 480
    title: qsTr("BerryLan")

    Material.foreground: "#011627"
    Material.background: "#fdfffc"
    Material.accent: colorTint

    property int iconSize: 32
    property int margins: 6
    property int largeFont: 20
    property int smallFont: 12
    property int index
    property int selectedCount: 0
    property int currentCount: 0
    property int count: 0
    property int tryed: 0
    property string sidd
    property string password
    property bool busy: false
    property bool addNetwork: false
    property string colorTint: "#87ceff"
    property string colorGray: "#D8D8D8"

    property bool test: true
    property int teller: 0

    BluetoothDiscovery {
        id: discovery
        discoveryEnabled: swipeView.currentIndex <= 1
        onBluetoothEnabledChanged: {
            if (!bluetoothEnabled) {
                swipeView.currentIndex = 0;
            }
        }
    }

    NetworkManagerController {
        id: networkManager
    }

    QtObject {
        id: d
        property var currentAP: null
        readonly property bool accessPointMode: networkManager.manager && networkManager.manager.wirelessDeviceMode == WirelessSetupManager.WirelessDeviceModeAccessPoint
    }

    Connections {
        target: discovery.deviceInfos
        onCountChanged: {
            if (swipeView.currentItem === discoveringView && discovery.deviceInfos.count > 0) {
                print("++1")
                swipeView.currentIndex++
            }
        }
        onDataChanged: {
            print("Changed data")
        }
    }

    Connections {
        target: networkManager.manager
        onInitializedChanged: {
            print("Start onInitializedChanged");
            print("initialized changed", networkManager.manager.initialized)
            print("Busy: ", busy);
            if (networkManager.manager.initialized) {
                if(busy) {
                    print("Verbonden!");
                    print("AccesPoint Avaiable: ", networkManager.manager.accessPointModeAvailable);
                    print("SSID: ", ssidTextField.text);
                    print("Password: ", passwordTextField.text);
                    networkManager.manager.connectWirelessNetwork(ssidTextField.text, passwordTextField.text);
                    print("Ingevoerd ssid");
                    if (networkManager.manager.currentConnection.hostAddress.length != 0){
                        networkManager.bluetoothDeviceInfo.ipAddress = networkManager.manager.currentConnection.hostAddress;
                        networkManager.bluetoothDeviceInfo = discovery.deviceInfos.get(networkManager.deviceIndex);
                        print("Ultieme test", networkManager.bluetoothDeviceInfo.ipAddress)
                    }
                    else{
                        print("Counter go one back")
                        selectedCount--;
                    }
                }
                else {
                    print("++swipeview ", swipeView.currentIndex)
                    if(swipeView.currentIndex == 2 || connectingToWiFiView.running){
                        discovery.deviceInfos.removeBluetoothDeviceInfo(networkManager.deviceIndex);
                        print("++2")
                        swipeView.currentIndex++;
                    }
                }
            } else {
                //if (busy){
                    print("Connectie is closed");
                    discovery.deviceInfos.removeBluetoothDeviceInfo(networkManager.deviceIndex)
                    print("Index before: ",networkManager.deviceIndex);
                    networkManager.deviceIndex = networkManager.deviceIndex + 1;
                    print("Count: ", discovery.deviceInfos.count);
                    print("Index: ", networkManager.deviceIndex)
                    if (discovery.deviceInfos.count <= networkManager.deviceIndex){
                        print("finished! out init");
                        busy = false
                        if(connectingToWiFiView.running){
                            print("++3")
                            swipeView.currentIndex++;
                        }
                    }
                    print("Index after: ",networkManager.deviceIndex);
                    networkManager.bluetoothDeviceInfo = discovery.deviceInfos.get(networkManager.deviceIndex);
                    networkManager.connectDevice();
                    currentCount++;

                //}
                /*else{
                    swipeView.currentIndex = 0;
                }*/
            }
        }
        onConnectedChanged: {
            print("Start onConnectedChanged")
            print("connectedChanged", networkManager.manager.connected)
            if (!networkManager.manager.connected) {
                if (swipeView.currentIndex == 5){
                    busy = true;
                }
                else{
                    //swipeView.currentIndex = 0;
                }
            }
        }

        onNetworkStatusChanged: {
            print("Network status changed:", networkManager.manager.networkStatus)
            if (swipeView.currentItem === connectingToWiFiView) {
                if (networkManager.manager.networkStatus === WirelessSetupManager.NetworkStatusGlobal) {
                    print("Volgende 3");
                    print("++4")
                    swipeView.currentIndex++;
                } else {
                    print("UNHANDLED Network status change:", networkManager.manager.networkStatus  )
                }

            }
        }
        onWirelessStatusChanged: {
            print("Wireless status changed:", networkManager.manager.networkStatus)
            print("CurrentItem : ", swipeView.currentItem)
            print("ConnectingToWifiView: ", connectingToWiFiView)
            print("Vanaf nu ++")
            if (swipeView.currentItem === connectingToWiFiView) {
                print("network status: ", networkManager.manager.wirelessStatus)
                if (networkManager.manager.wirelessStatus === WirelessSetupManager.WirelessStatusActivated) {
                    print("Volgende 4");
                    print("++5")
                    swipeView.currentIndex++;
                }

                if(networkManager.manager.wirelessStatus === 12) {
                    print("Hij komt hier3")
                    connectingToWiFiView.running = false
                    connectingToWiFiView.text = qsTr("Invalid password.")
                    connectingToWiFiView.buttonText = qsTr("Try again")
                }
            }
        }

        onErrorOccurred: {
            if (swipeView.currentItem === connectingToWiFiView) {
                connectingToWiFiView.running = false
                connectingToWiFiView.text = qsTr("Sorry, an unexpected error happened.")
                connectingToWiFiView.buttonText = qsTr("Try again")
            }
        }
    }

    StackView {
        id: pageStack
        anchors.fill: parent
        initialItem: BerryLanPage {
            title: {
                switch (swipeView.currentIndex) {
                case 0:
                case 1:
                case 2:
                    return qsTr("Modules")
                case 3:
                    return qsTr("Network")
                case 4:
                    return qsTr("Login")
                case 5:
                    return qsTr("Connecting")
                case 6:
                    return qsTr("Connected")
                }
            }

            backButtonVisible: swipeView.currentIndex === 4

            nextButtonVisible: swipeView.currentIndex === 1

            selectAllButtonVisible: swipeView.currentIndex === 1

            onHelpClicked: pageStack.push(Qt.resolvedUrl("components/HelpPage.qml"))

            step: {
                switch (swipeView.currentIndex) {
                case 0:
                    ActivityCompat.shouldShowRequestPermissionRationale(context, Manifest.permission.ACCESS_COARSE_LOCATION);
                    return 1;
                case 1:
                    return 0;
                case 2:
                    return 3;
                case 3:
                    if (!networkManager.manager) {
                        return 2;
                    }
                    if (networkManager.manager.accessPoints.count == 0) {
                        return 3;
                    }
                    return 4;
                case 4:
                    for(index = 0 ; index < discovery.deviceInfos.count ; index++){
                        if(discovery.deviceInfos.get(index).selected){
                            selectedCount++;
                        }
                    }
                    return 4;
                case 5:
                    if (networkManager.manager.wirelessStatus < WirelessSetupManager.WirelessStatusConfig) {
                        return 5;
                    }
                    print("Connectie is closing");
                    busy = true;
                    if(connectingToWiFiView.running && networkManager.manager.wirelessStatus === WirelessSetupManager.WirelessStatusActivated){
                        networkManager.manager.disconnectDevice();
                    }
                    while(discovery.deviceInfos.count > count){
                        if(!discovery.deviceInfos.get(count).selected){

                            print("remove item ", count)
                            discovery.deviceInfos.removeBluetoothDeviceInfo(count)
                            print("end removing")
                        }
                        count++
                    }
                    return 5;
                case 6:
                    for(teller = 0; teller < 2 ; teller++){
                        networkManager.bluetoothDeviceInfo = discovery.deviceInfos.get(teller)
                        print("IP address test: ", networkManager.bluetoothDeviceInfo.ipAddress)
                    }
                    return 8;
                }
            }

            content: SwipeView {
                id: swipeView
                anchors.fill: parent
                interactive: false

                // 0
                WaitView {
                    id: discoveringView
                    height: swipeView.height
                    width: swipeView.width
                    text: !discovery.bluetoothAvailable
                          ? qsTr("Bluetooth is not available on this device. This application requires a Bluetooth connection to function properly.")
                          : !discovery.bluetoothEnabled
                            ? qsTr("Bluetooth is disabled. Please enable Bluetooth on the device on order to use this application. ")
                            : qsTr("Searching for modules")
                }

                // 1
                ListView {
                    id: discoveryListView
                    height: swipeView.height
                    width: swipeView.width
                    model: discovery.deviceInfos
                    clip: true
                    ColorIcon {
                        Layout.preferredHeight: app.iconSize
                        Layout.preferredWidth: app.iconSize
                        name: "../images/next.svg"
                    }
                    delegate: BerryLanItemDelegate {
                        width: parent.width
                        text: name
                        iconSource: "../images/bluetooth.svg"
                    }

                }

                // 2
                WaitView {
                    id: connectingToPiView
                    height: swipeView.height
                    width: swipeView.width
                    text: qsTr("Connecting to the W160x module")
                }

                // 3
                ColumnLayout {
                    height: swipeView.height
                    width: swipeView.width

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        id: apSelectionListView
                        model: WirelessAccessPointsProxy {
                            id: accessPointsProxy
                            accessPoints: networkManager.manager ? networkManager.manager.accessPoints : null
                        }
                        clip: true

                        delegate: BerryLanItemDelegate {
                            width: parent.width
                            text: model.ssid
                            iconSource: model.signalStrength > 66
                                        ? "../images/wifi-100.svg"
                                        : model.signalStrength > 33
                                          ? "../images/wifi-66.svg"
                                          : model.signalStrength > 0
                                            ? "../images/wifi-33.svg"
                                            : "../images/wifi-0.svg"

                            onClicked: {
                                ssidTextField.text = ""
                                passwordTextField.text = ""
                                addNetwork = false
                                currentCount++;
                                print("Connect to ", model.ssid, " --> ", model.macAddress)
                                d.currentAP = accessPointsProxy.get(index);
                                ssidTextField.text = d.currentAP.ssid;
                                if (!d.currentAP.isProtected) {
                                    networkManager.manager.connectWirelessNetwork(d.currentAP.ssid)
                                    print("++6")
                                    swipeView.currentIndex++;
                                }
                                print("++7")
                                swipeView.currentIndex++;
                            }
                        }
                    }

                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        visible: networkManager.manager.accessPointModeAvailable
                        text: qsTr("Add Network")
                        onClicked: {
                            print("++8")
                            addNetwork = true
                            ssidTextField.text = ""
                            swipeView.currentIndex++
                        }
                    }
                }


                // 4
                Item {
                    id: authenticationView
                    width: swipeView.width
                    height: swipeView.height
                    ColumnLayout {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: - swipeView.height / 4
                        width: app.iconSize * 8
                        spacing: app.margins
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Name")
                            visible: !d.currentAP || addNetwork
                        }

                        TextField {
                            id: ssidTextField
                            Layout.fillWidth: true
                            visible: !d.currentAP || addNetwork
                            maximumLength: 32
                            onAccepted: {
                                passwordTextField.focus = true
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Password")
                        }

                        RowLayout {
                            TextField {
                                id: passwordTextField
                                Layout.fillWidth: true
                                maximumLength: 64
                                property bool showPassword: false
                                echoMode: showPassword ? TextInput.Normal : TextInput.Password
                                onAccepted: {
                                    okButton.clicked()
                                }
                            }

                            ColorIcon {
                                Layout.preferredHeight: app.iconSize
                                Layout.preferredWidth: app.iconSize
                                name: "../images/eye.svg"
                                color: passwordTextField.showPassword ? colorTint : keyColor
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: passwordTextField.showPassword = !passwordTextField.showPassword
                                }
                            }
                        }

                        Button {
                            id: okButton
                            Layout.fillWidth: true
                            text: qsTr("OK")
                            enabled: passwordTextField.displayText.length >= 8
                            onClicked: {
                                if (d.currentAP) {
                                    connectingToWiFiView.text = qsTr("Connecting the W160x module to %1").arg(d.currentAP.ssid);
                                    networkManager.manager.connectWirelessNetwork(d.currentAP.ssid, passwordTextField.text)
                                    sidd = d.currentAP.ssid;
                                    password = passwordTextField.text;

                                } else {
                                    connectingToWiFiView.text = qsTr("Opening access point \"%1\" on the W160x module.").arg(ssidTextField.text);
                                    networkManager.manager.connectWirelessNetwork(ssidTextField.text, passwordTextField.text)
                                    sidd = ssidTextField.text;
                                    password = passwordTextField.text;
                                }

                                connectingToWiFiView.buttonText = "";
                                connectingToWiFiView.running = true

                                print("++9")
                                swipeView.currentIndex++
                            }
                        }
                    }
                }

                // 5
                WaitView {
                    id: connectingToWiFiView
                    height: swipeView.height
                    width: swipeView.width

                    onButtonClicked: {
                        print("protected: ", d.currentAP.isProtected)
                        swipeView.currentIndex--;
                        if (!d.currentAP.isProtected) {
                            swipeView.currentIndex--;
                        }
                    }
                }

                // 6
                Item {
                    id: resultsView
                    height: swipeView.height
                    width: swipeView.width

                    ColumnLayout {
                        anchors.fill: parent


                        ListView {
                            id: connectView
                            height: swipeView.height
                            width: swipeView.width
                            model: discovery.deviceInfos
                            clip: true
                            ColorIcon {
                                Layout.preferredHeight: app.iconSize
                                Layout.preferredWidth: app.iconSize
                            }
                            delegate: BerryLanItemDelegate {
                                width: parent.width
                                text: name
                                iconSource: "../images/bluetooth.svg"
                            }
                        }                    
                    }
                }
            }
        }
    }
}
