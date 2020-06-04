//
//  SendingRouter.swift
//  bleTest
//
//  Created by Denis Volodchenko on 03.06.2020.
//  Copyright © 2020 DV. All rights reserved.
//

import Foundation

protocol SendingRouterInput: AnyObject {

}

class SendingRouter: SendingRouterInput {
    weak var mainController: SendingViewController?
    
    // MARK: - SendingRouterInput
    
    // MARK: - Module functions
}

