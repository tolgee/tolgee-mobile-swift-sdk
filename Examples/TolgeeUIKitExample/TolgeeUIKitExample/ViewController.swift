//
//  ViewController.swift
//  TolgeeUIKitExample
//
//  Created by Petr Pavlik on 11.08.2025.
//

import UIKit
import Tolgee

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        let label = UILabel()
//        
//        label.text = Tolgee.shared.translate("My name is %@ and I have %lld apples", "John", 3)
//        
//        view.addSubview(label)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        
//        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        
        let label2 = UILabel()
        
        label2.text = String(format: NSLocalizedString("My name is %@ and I have %lld apples", comment: ""), "John", 3)
        
        view.addSubview(label2)
        label2.translatesAutoresizingMaskIntoConstraints = false
        
        label2.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label2.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }


}

