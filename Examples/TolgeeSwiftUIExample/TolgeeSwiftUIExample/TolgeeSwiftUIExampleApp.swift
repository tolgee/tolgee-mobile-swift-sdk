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
        Tolgee.shared.initialize(cdn: URL(string: "https://cdntest.tolg.ee/47b95b14388ff538b9f7159d0daf92d2")!, enableDebugLogs: true)
        
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
