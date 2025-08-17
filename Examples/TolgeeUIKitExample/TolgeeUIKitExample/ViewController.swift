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
        label2.text = String(
            format: NSLocalizedString("My name is %@ and I have %lld apples", comment: ""), "John",
            3)
        label2.textAlignment = .center
        label2.numberOfLines = 0

        // Create a vertical stack view
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
