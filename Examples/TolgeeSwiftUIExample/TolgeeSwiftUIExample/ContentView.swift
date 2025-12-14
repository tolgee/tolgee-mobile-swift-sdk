//
//  ContentView.swift
//  TolgeeSwiftUIExample
//
//  Created by Petr Pavlik on 11.08.2025.
//

import SwiftUI
import Tolgee

struct ContentView: View {
    
    // This will automatically re-render the view when
    // the localization cache is updated from a CDN.
    @StateObject private var updater = TolgeeSwiftUIUpdater()
    
    @Environment(\.locale) var locale
    
    var body: some View {
        VStack(spacing: 20) {
            
            HStack {
                TolgeeText("Language switcher:")
                LanguagePicker(onLanguageChange: { language in
                    if let language {
                        Tolgee.shared.setCustomLocale(Locale(identifier: language))
                    } else {
                        Tolgee.shared.setCustomLocale(.current)
                    }
                    
                    Task {
                        await Tolgee.shared.remoteFetch()
                    }
                })
                .pickerStyle(.menu)
            }
            
            Divider()
            
            // Use TolgeeText instead of Text for convenience
            TolgeeText("My name is %@ and I have %lld apples", "John", 3)
            
            // Use the SDK directly
            // note: the locale param is only used for SwiftUI preview purposes
            if #available(iOS 18.4, *) {
                Text(Tolgee.shared.translate("My name is %@ and I have %lld apples", "John", 3, locale: locale))
            } else {
                Text(Tolgee.shared.translate("My name is %@ and I have %lld apples", "John", 3))
            }
        }
        .padding()
    }
}

#Preview("English") {
    ContentView()
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Czech") {
    ContentView()
        .environment(\.locale, Locale(identifier: "cs"))
}
