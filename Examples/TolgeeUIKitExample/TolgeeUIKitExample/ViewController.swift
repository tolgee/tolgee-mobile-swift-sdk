//
//  ViewController.swift
//  TolgeeUIKitExample
//
//  Created by Petr Pavlik on 11.08.2025.
//

import Tolgee
import UIKit

class ViewController: UIViewController {

    private let label = UILabel()
    private let label2 = UILabel()
    private let languageSwitcherLabel = UILabel()
    private var updateTask: Task<Void, Never>?
    private var languageOptions: [String?] = []
    private let languageSegmentedControl = UISegmentedControl()

    deinit {
        updateTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        updateTask = Task { [weak self] in
            for await _ in Tolgee.shared.onTranslationsUpdated() {
                self?.updateLabels()
            }
        }

        label.textAlignment = .center
        label.numberOfLines = 0

        // You need to set TOLGEE_ENABLE_SWIZZLING=true in env variables to opt in for swizzling of NSLocalizedString
        // Please note that pluralized strings are currently not supported and the logic will fall back to the data bundled with the app.
        // Regular parameters are supported, such as the example bellow.
        label2.textAlignment = .center
        label2.numberOfLines = 0

        // Setup language picker
        setupLanguagePicker()

        let languagePickerContainer = UIStackView(arrangedSubviews: [
            createLanguagePickerLabel(),
            languageSegmentedControl,
        ])
        languagePickerContainer.axis = .vertical
        languagePickerContainer.spacing = 10
        languagePickerContainer.alignment = .center

        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        // This is just a boilerplate layout code
        let stackView = UIStackView(arrangedSubviews: [
            languagePickerContainer,
            divider,
            label,
            label2,
        ])
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

        // Load initial text
        updateLabels()
    }

    private func updateLabels() {
        // Use the SDK directly
        label.text = Tolgee.shared.translate("My name is %@ and I have %lld apples", "John", 3)
        // Or use NSLocalizedString with swizzling enabled
        label2.text = String(format: NSLocalizedString("My name is %@", comment: ""), "John")
        languageSwitcherLabel.text = NSLocalizedString("Language switcher:", comment: "")
    }

    private func setupLanguagePicker() {
        // Build language options: System Default + available localizations (excluding "Base")
        let localizations = Bundle.main.localizations.filter { $0 != "Base" }
        languageOptions = [nil] + localizations

        // Add segments
        for (index, languageCode) in languageOptions.enumerated() {
            let title = languageCode == nil ? "System" : languageCode!.uppercased()
            languageSegmentedControl.insertSegment(withTitle: title, at: index, animated: false)
        }

        // Select the first option (System Default)
        languageSegmentedControl.selectedSegmentIndex = 0

        // Add action
        languageSegmentedControl.addTarget(
            self,
            action: #selector(languageChanged),
            for: .valueChanged
        )
    }

    private func createLanguagePickerLabel() -> UILabel {
        languageSwitcherLabel.font = .systemFont(ofSize: 17)
        return languageSwitcherLabel
    }

    @objc private func languageChanged() {
        let selectedIndex = languageSegmentedControl.selectedSegmentIndex
        guard selectedIndex >= 0, selectedIndex < languageOptions.count else { return }

        let selectedLanguage = languageOptions[selectedIndex]

        Task {
            if let language = selectedLanguage {
                try Tolgee.shared.setCustomLocale(Locale(identifier: language))
            } else {
                try Tolgee.shared.setCustomLocale(.current)
            }
            
            await Tolgee.shared.remoteFetch()
        }
    }

}
