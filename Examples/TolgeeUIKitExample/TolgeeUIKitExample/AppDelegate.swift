//
//  AppDelegate.swift
//  TolgeeUIKitExample
//
//  Created by Petr Pavlik on 11.08.2025.
//

import UIKit
import Tolgee

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Tolgee.shared.initialize(cdn: URL(string: "https://cdntest.tolg.ee/47b95b14388ff538b9f7159d0daf92d2")!, enableDebugLogs: true)
                
        Task {
            for await _ in Tolgee.shared.onTranslationsUpdated() {
                // Gets triggered when the translation cache is updated
            }
            
            for await logMessage in Tolgee.shared.onLogMessage() {
                // Here you can forward logs from Tolgee SDK to your analytics SDK.
            }
        }
        
        return true
    }
}

