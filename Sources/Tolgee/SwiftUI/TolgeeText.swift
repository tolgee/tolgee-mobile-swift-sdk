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
    @StateObject private var updater = TolgeeSwiftUIUpdater()

    public init(
        _ key: String, _ arguments: CVarArg..., tableName: String? = nil, bundle: Bundle = .main
    ) {
        self.key = key
        self.tableName = tableName
        self.arguments = arguments
        self.bundle = bundle
    }

    public var body: some View {
        Text(
            Tolgee.shared.translate(
                key, arguments, table: tableName, bundle: bundle, locale: locale))
    }
}
