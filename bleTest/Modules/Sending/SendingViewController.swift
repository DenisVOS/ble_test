//
//  SendingViewController.swift
//  bleTest
//
//  Created by Denis Volodchenko on 03.06.2020.
//  Copyright © 2020 DV. All rights reserved.
//

import UIKit

protocol SendingViewInput: AnyObject {
    func setupInitialState()
    func updateInput(with str: String)
    func updateDeviceInfo(with str: String)
}

protocol SendingViewOutput {
    func viewIsReady(_ controller: AnyObject)
    func sendPressed(with text: String?)
}

class SendingViewController: UIViewController, SendingViewInput {
    @IBOutlet private weak var inputTitle: UILabel!
    @IBOutlet private weak var inputField: UITextView!
    @IBOutlet private weak var outputTitle: UILabel!
    @IBOutlet private weak var outputField: UITextView!
    @IBOutlet private weak var infoTitle: UILabel!
    @IBOutlet private weak var infoField: UITextView!
    @IBOutlet private weak var sendButton: UIButton!
    
    var output: SendingViewOutput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.output?.viewIsReady(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.applyStyles()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    // MARK: - Setup
    private func setupComponents() {
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.closeKB)))
        [self.outputField, self.inputField, self.infoField].forEach({
            $0?.backgroundColor = .lightGray
            $0?.textColor = .black
        })
        [self.inputTitle, self.outputTitle, self.infoTitle].forEach({
            $0?.textColor = .black
        })
    }
    
    private func setupActions() {
        
    }
    
    private func applyStyles() {
        
    }
    
    // MARK: - SendingViewInput
    func setupInitialState() {
        self.setupComponents()
        self.setupActions()
        PushManager.shared.requestPermission()
    }
    
    func updateInput(with str: String) {
        DispatchQueue.main.async {
            self.inputField.text += str
        }        
    }
    
    func updateDeviceInfo(with str: String) {
        DispatchQueue.main.async {
            self.infoField.text = str
        }
    }
}

// MARK: - Actions
extension SendingViewController {
    @IBAction private func sendPressed() {
        self.output?.sendPressed(with: self.outputField.text)
    }
    
    @objc
    private func closeKB() {
        self.view.endEditing(true)
    }
}

// MARK: - Module functions
extension SendingViewController {
    
}
