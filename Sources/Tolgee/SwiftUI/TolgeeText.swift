//
//  TolgeeTest.swift
//  Tolgee
//
//  Created by Petr Pavlik on 23.07.2025.
//

import Foundation
import SwiftUI

public struct TolgeeText: View {

    private let key: String
    private let tableName: String?
    private let arguments: [CVarArg]
    private let bundle: Bundle
    @Environment(\.locale) private var locale

    public init(
        _ key: String, _ arguments: CVarArg..., tableName: String? = nil, bundle: Bundle = .main
    ) {
        self.key = key
        self.tableName = tableName
        self.arguments = arguments
        self.bundle = bundle
    }

    public var body: some View {
        let translate = { [key, arguments, tableName, bundle, locale] in
            Tolgee.shared.translate(key, arguments, table: tableName, bundle: bundle, locale: locale)
        }
        if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
            StateObjectText(translate: translate)
        } else {
            ObservedObjectText(translate: translate)
        }
    }
}

@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
private struct StateObjectText: View {
    let translate: () -> String
    @StateObject private var updater = TolgeeSwiftUIUpdater()

    var body: some View {
        Text(translate())
    }
}

/// `@StateObject` needs iOS 14, so older systems create a new updater each time the parent view updates.
private struct ObservedObjectText: View {
    let translate: () -> String
    @ObservedObject private var updater = TolgeeSwiftUIUpdater()

    var body: some View {
        Text(translate())
    }
}
