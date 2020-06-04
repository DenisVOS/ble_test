//
//  SendingPresenter.swift
//  bleTest
//
//  Created by Denis Volodchenko on 03.06.2020.
//  Copyright © 2020 DV. All rights reserved.
//

class SendingPresenter: SendingViewOutput, SendingInteractorOutput {
    weak var view: SendingViewInput?
    var interactor: SendingInteractorInput?
    var router: SendingRouterInput?
    
    init() {
       
    }
    
    // MARK: - SendingPresenterInput
    
    // MARK: - SendingViewOutput
    
    func viewIsReady(_ controller: AnyObject) {
        self.view?.setupInitialState()
        self.interactor?.startBle()
    }
    
    func sendPressed(with text: String?) {
        self.interactor?.sendBleData(text ?? "")
    }
    
    // MARK: - SendingInteractorOutput
    
    func dataReceived(_ str: String) {
        self.view?.updateInput(with: str + "\n")
    }
    
    func discoveredInfo(_ params: [String: Any]) {
        let devInfoStr = params.map({ "\($0.key) - \($0.value)" }).joined(separator: "\n")
        self.view?.updateDeviceInfo(with: devInfoStr)
    }
    
    func connected() {
        PushManager.shared.sendNotification(with: "BLE Test", body: "Устройство обнаружено и подключено")
    }
    
    // MARK: - Module functions
}
