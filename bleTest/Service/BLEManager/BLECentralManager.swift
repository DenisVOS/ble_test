//
//  BLECentralManager.swift
//  bleTest
//
//  Created by Denis Volodchenko on 03.06.2020.
//  Copyright © 2020 DV. All rights reserved.
//

import Foundation
import CoreBluetooth
import os

protocol BLECentralManagerDelegate {
    func dataReceived(_ str: String)
    func connected(to peripheral: CBPeripheral?, with transferCharacteristic: CBCharacteristic?)
    func discoveredInfo(_ params: [String: Any])
    func disconnected(from peripheral: CBPeripheral?)
}

final class BLECentralManager: NSObject {
    private var central: CBCentralManager!
    private var discoveredPeripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
    private var receivedData: Data
    
    private var delegate: BLECentralManagerDelegate
    
    init(delegate: BLECentralManagerDelegate) {
        self.delegate = delegate
        self.receivedData = Data()
        super.init()
        self.central = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }

    private func setupPeripheral() {
        let connectedPeripherals: [CBPeripheral] = (central.retrieveConnectedPeripherals(withServices: [BLEDefaults.serviceUUID]))
        if let connectedPeripheral = connectedPeripherals.last {
            self.discoveredPeripheral = connectedPeripheral
            self.central.connect(connectedPeripheral, options: nil)
        } else {
            self.central.scanForPeripherals(withServices: [BLEDefaults.serviceUUID],
                                               options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    private func cleanManager() {
        guard let discoveredPeripheral = self.discoveredPeripheral,
              case .connected = discoveredPeripheral.state else { return }

        for service in (discoveredPeripheral.services ?? [] as [CBService]) {
            for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                if characteristic.uuid == BLEDefaults.characteristicUUID && characteristic.isNotifying {
                    self.discoveredPeripheral?.setNotifyValue(false, for: characteristic)
                }
            }
        }

        self.central.cancelPeripheralConnection(discoveredPeripheral)
    }
    
    private func prepareDevInfo(_ info: [String: Any], rssi: NSNumber, device: CBPeripheral) {
        var params = info
        let numberFormat = NumberFormatter()
        numberFormat.maximumFractionDigits = 2
        
        params["rssi"] = rssi.intValue
        params["distance"] = "\(numberFormat.string(from: NSNumber(value: pow(10,((-69 - (rssi.doubleValue))/(10 * 2))))) ?? "") m."
        params["name"] = device.name
        params["beacon_id"] = device.identifier
        
        self.delegate.discoveredInfo(params)
    }
}

extension BLECentralManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            self.setupPeripheral()
        case .poweredOff:
            break
        case .resetting:
            break
        case .unauthorized:
            break
        case .unknown:
            break
        case .unsupported:
            break
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        self.prepareDevInfo(advertisementData, rssi: RSSI, device: peripheral)
        guard RSSI.intValue >= -100,
              self.discoveredPeripheral != peripheral else {
            return
        }
        
        self.discoveredPeripheral = peripheral
        
        self.central.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.cleanManager()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.central.stopScan()
        self.receivedData.removeAll()
        
        peripheral.delegate = self
        peripheral.discoverServices([BLEDefaults.serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.delegate.disconnected(from: self.discoveredPeripheral)
        self.discoveredPeripheral = nil
    }
}

extension BLECentralManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        for service in invalidatedServices where service.uuid == BLEDefaults.serviceUUID {
            peripheral.discoverServices([BLEDefaults.serviceUUID])
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices {
            peripheral.discoverCharacteristics([BLEDefaults.characteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let serviceCharacteristics = service.characteristics else {
            return
        }
        
        for characteristic in serviceCharacteristics where characteristic.uuid == BLEDefaults.characteristicUUID {
            self.characteristic = characteristic
            self.delegate.connected(to: self.discoveredPeripheral, with: self.characteristic)
            
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let characteristicData = characteristic.value,
              let stringFromData = String(data: characteristicData, encoding: .utf8) else { return }

        if stringFromData == BLEDefaults.EOM {
            self.delegate.dataReceived(String(data: self.receivedData, encoding: .utf8) ?? "")
            self.receivedData.removeAll()
        } else {
            self.receivedData.append(characteristicData)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == BLEDefaults.characteristicUUID else { return }
        if !characteristic.isNotifying {
            self.cleanManager()
        }
    }
}
