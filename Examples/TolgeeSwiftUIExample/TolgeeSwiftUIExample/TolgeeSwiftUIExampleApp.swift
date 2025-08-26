//
//  TolgeeSwiftUIExampleApp.swift
//  TolgeeSwiftUIExample
//
//  Created by Petr Pavlik on 11.08.2025.
//

import SwiftUI
import Tolgee

@main
struct TolgeeSwiftUIExampleApp: App {

    init() {
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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await Tolgee.shared.remoteFetch()
                }
        }
    }
}
