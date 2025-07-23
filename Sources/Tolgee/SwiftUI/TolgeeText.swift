//
//  TolgeeTest.swift
//  Tolgee
//
//  Created by Petr Pavlik on 23.07.2025.
//

import SwiftUI

public struct TolgeeText: View {

    private let key: String
    private let tableName: String?
    private let arguments: [CVarArg]
    @Environment(\.locale) private var locale

    public init(_ key: String, _ arguments: CVarArg..., tableName: String? = nil) {
        self.key = key
        self.tableName = tableName
        self.arguments = arguments
    }

    public var body: some View {
        if #available(macOS 15.4, iOS 18.4, *) {
            if arguments.isEmpty {
                Text(Tolgee.shared.translate(key, table: tableName, locale: locale))
            } else {
                Text(
                    Tolgee.shared.translate(
                        key, arguments.first!, table: tableName, locale: locale))
            }
        } else {
            if arguments.isEmpty {
                Text(Tolgee.shared.translate(key, table: tableName))
            } else {
                Text(Tolgee.shared.translate(key, arguments.first!, table: tableName))
            }
        }
    }
}

@MainActor
public func TolgeeLocalizedStringKey(_ key: String) -> String {
    Tolgee.shared.translate(key)
}
