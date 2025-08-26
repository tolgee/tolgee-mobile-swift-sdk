//
//  ViewController.swift
//  TolgeeUIKitExample
//
//  Created by Petr Pavlik on 11.08.2025.
//

import Tolgee
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let label = UILabel()
        label.text = Tolgee.shared.translate("My name is %@ and I have %lld apples", "John", 3)
        label.textAlignment = .center
        label.numberOfLines = 0

        let label2 = UILabel()
        // You need to set TOLGEE_ENABLE_SWIZZLING=true in env variables to opt in for swizzling of NSLocalizedString
        // Please note that pluralized strings are currently not supported and the logic will fall back to the data bundled with the app.
        // Regular parameters are supported, such as the example bellow.
        label2.text = String(format: NSLocalizedString("My name is %@", comment: ""), "John")
        label2.textAlignment = .center
        label2.numberOfLines = 0

        // This is just a boilerplate layout code
        let stackView = UIStackView(arrangedSubviews: [label, label2])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 20

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Center the stack view in the view
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor, constant: -20),
        ])
    }

}
