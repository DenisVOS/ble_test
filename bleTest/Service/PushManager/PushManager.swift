//
//  PushManager.swift
//  bleTest
//
//  Created by Denis Volodchenko on 04.06.2020.
//  Copyright © 2020 DV. All rights reserved.
//

import UserNotifications

final class PushManager {
    static let shared: PushManager = PushManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        
    }
    
    func requestPermission() {
        let options = UNAuthorizationOptions(arrayLiteral: .alert, .badge, .sound)
        
        self.notificationCenter.requestAuthorization(options: options) { (_, error) in
            if let error = error {
                print("Error: ", error)
            }
        }
    }

    func sendNotification(with title: String, body: String) {
        let notification = UNMutableNotificationContent()
        notification.title = title
        notification.body = body
        notification.badge = NSNumber(value: 1)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: "testNotification",
                                            content: notification,
                                            trigger: trigger)
        
        self.notificationCenter.add(request) { (error) in
            if let error = error {
                print("Notification Error: ", error)
            }
        }
    }
}
