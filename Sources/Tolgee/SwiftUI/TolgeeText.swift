//
//  TolgeeTest.swift
//  Tolgee
//
//  Created by Petr Pavlik on 23.07.2025.
//

import SwiftUI

public struct TolgeeText: View {

    private let key: String

    init(t key: String) {
        self.key = key
    }

    public var body: some View {
        if #available(macOS 15.4, iOS 18.4, *) {
            Text(Tolgee.shared.translate(key, locale: .current))
        } else {
            Text(Tolgee.shared.translate(key))
        }
    }
}

@MainActor
public func TolgeeLocalizedStringKey(_ key: String) -> String {
    Tolgee.shared.translate(key)
}
