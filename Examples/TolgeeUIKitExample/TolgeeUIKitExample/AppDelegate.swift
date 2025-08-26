//
//  AppDelegate.swift
//  TolgeeUIKitExample
//
//  Created by Petr Pavlik on 11.08.2025.
//

import Tolgee
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        Tolgee.shared.initialize(
            cdn: URL(string: "https://cdn.tolg.ee/72d7af7161b2a9f6feeb75537aa8a877")!,
            enableDebugLogs: true)

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
