//
//  SendingAssembly.swift
//  bleTest
//
//  Created by Denis Volodchenko on 03.06.2020.
//  Copyright © 2020 DV. All rights reserved.
//

import Foundation

enum SendingAssembly {
    static func create() -> SendingViewController {
        return SendingViewController()
    }
    
    @discardableResult
    static func configure(with reference: SendingViewController) -> SendingPresenter {
        let presenter = SendingPresenter()
        
        let interactor = SendingInteractor()
        interactor.output = presenter
        
        let router = SendingRouter()
        router.mainController = reference
        
        presenter.view = reference
        presenter.interactor = interactor
        presenter.router = router
        
        reference.output = presenter
        
        return presenter
    }
}


