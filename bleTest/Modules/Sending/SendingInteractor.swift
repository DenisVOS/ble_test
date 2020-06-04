//
//  SendingInteractor.swift
//  bleTest
//
//  Created by Denis Volodchenko on 03.06.2020.
//  Copyright © 2020 DV. All rights reserved.
//

import CoreBluetooth

protocol SendingInteractorInput: AnyObject {
    func sendBleData(_ data: String?)
    func startBle()
}

protocol SendingInteractorOutput: AnyObject {
    func dataReceived(_ str: String)
    func discoveredInfo(_ params: [String : Any])
    func connected()
}

open class SendingInteractor: SendingInteractorInput {
    weak var output: SendingInteractorOutput?
    
    private var centralManager: BLECentralManager?
    private var peripheralManager: BLEPeripheralManager?
    
    init() {
        
    }
    
    // MARK: - SendingInteractorInput
    func startBle() {
        self.peripheralManager = BLEPeripheralManager(delegate: self)
        self.centralManager = BLECentralManager(delegate: self)
    }
    
    func sendBleData(_ data: String?) {
        self.peripheralManager?.sendData(data ?? "")
    }
}

extension SendingInteractor: BLECentralManagerDelegate {
    func discoveredInfo(_ params: [String : Any]) {
        self.output?.discoveredInfo(params)
    }
    
    func connected(to peripheral: CBPeripheral?, with transferCharacteristic: CBCharacteristic?) {
        self.peripheralManager?.setPeripheral(peripheral, transferCharacteristic)
        self.output?.connected()
    }
    
    func disconnected(from peripheral: CBPeripheral?) {
        self.peripheralManager?.removePeripheral()
    }
    
    func dataReceived(_ str: String) {
        self.output?.dataReceived(str)
    }
}

extension SendingInteractor: BLEPeripheralManagerDelegate {
    
}
