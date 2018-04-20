//
//  SettingsTableViewController.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 4/19/18.
//  Copyright © 2018 Mitchell Lombardi. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController, UITextFieldDelegate {
    
    //MARK: Properties
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var changeEmailTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeEmailTextField.delegate = self
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        email.text = changeEmailTextField.text
        changeEmailTextField.isHidden = true
        email.isHidden = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        changeEmailTextField.resignFirstResponder()
        return true
    }
    
    //MARK: Action Methods
    @IBAction func changeEmail(_ sender: UIButton) {
        email.isHidden = true
        changeEmailTextField.isHidden = false
    }
    

}
