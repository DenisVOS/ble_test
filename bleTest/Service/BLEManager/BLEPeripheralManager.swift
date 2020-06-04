//
//  BLEManager.swift
//  bleTest
//
//  Created by Denis Volodchenko on 03.06.2020.
//  Copyright © 2020 DV. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BLEPeripheralManagerDelegate {
   func dataReceived(_ str: String)
}

final class BLEPeripheralManager: NSObject {
    private var peripheralManager: CBPeripheralManager!
    private var characteristic: CBMutableCharacteristic?
    private var central: CBCentral?
    
    private var peripheralCharacteristic: CBCharacteristic?
    private var discoveredPeripheral: CBPeripheral?
    
    private var sendingData: Data
    private var sendingDataIndex: Int
    private var sendingEOM: Bool = false
    
    private var delegate: BLECentralManagerDelegate
    
    init(delegate: BLECentralManagerDelegate) {
        self.sendingData = Data()
        self.sendingDataIndex = 0
        self.delegate = delegate
        super.init()
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
    }
    
    func sendData(_ str: String) {
        if let data = str.data(using: .utf8) {
            self.sendingData = data
            self.sendingDataIndex = 0
            self.send()
        }
    }
    
    func setPeripheral(_ peripheral: CBPeripheral?, _ transferCharacteristic: CBCharacteristic?) {
        self.discoveredPeripheral = peripheral
        self.peripheralCharacteristic = transferCharacteristic
    }
    
    func removePeripheral() {
        self.discoveredPeripheral = nil
        self.peripheralCharacteristic = nil
    }
    
    private func setupPeripheral() {
        let transferCharacteristic = CBMutableCharacteristic(type: BLEDefaults.characteristicUUID,
                                                         properties: [.notify, .writeWithoutResponse],
                                                         value: nil,
                                                         permissions: [.readable, .writeable])
        let transferService = CBMutableService(type: BLEDefaults.serviceUUID, primary: true)
        transferService.characteristics = [transferCharacteristic]
        self.peripheralManager.add(transferService)
        self.characteristic = transferCharacteristic
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [BLEDefaults.serviceUUID]])

    }
}

extension BLEPeripheralManager {
    private func send() {
        guard let characteristic = characteristic else {
            return
        }
        guard !self.sendingEOM else {
            if self.peripheralManager.updateValue(BLEDefaults.EOM.data(using: .utf8)!, for: characteristic, onSubscribedCentrals: nil) {
                self.sendingEOM = false
            }
            return
        }
        guard self.sendingDataIndex < self.sendingData.count else {
            return
        }
        
        while true {
            var amountToSend = self.sendingData.count - self.sendingDataIndex
            
            if let mtu = self.central?.maximumUpdateValueLength {
                amountToSend = min(amountToSend, mtu)
            }
            
            let chunk = self.sendingData.subdata(in: self.sendingDataIndex..<(self.sendingDataIndex + amountToSend))
            
            if self.central != nil {
                if !self.peripheralManager.updateValue(chunk, for: characteristic, onSubscribedCentrals: nil) {
                    return
                }
            } else if let characteristics = self.peripheralCharacteristic {
                self.discoveredPeripheral?.writeValue(chunk, for: characteristics, type: .withoutResponse)
            }
            
            self.sendingDataIndex += amountToSend
    
            if self.sendingDataIndex >= self.sendingData.count {
                self.sendingEOM = true

                if peripheralManager.updateValue(BLEDefaults.EOM.data(using: .utf8)!, for: characteristic, onSubscribedCentrals: nil) {
                    self.sendingEOM = false
                }
                
                return
            }
        }
    }
}

extension BLEPeripheralManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
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

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        self.central = central
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        self.central = nil
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        self.send()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if let requestValue = request.value,
               let strValue = String(data: requestValue, encoding: .utf8) {
                self.delegate.dataReceived(strValue)
            }
        }
    }
}
