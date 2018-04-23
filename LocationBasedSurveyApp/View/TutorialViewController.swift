//
//  TutorialViewController.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 4/20/18.
//  Copyright © 2018 Mitchell Lombardi. All rights reserved.
//

import UIKit

// View Controller for the tutorial
class TutorialViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var topTextView: UITextView!
    @IBOutlet weak var bottomTextView: UITextView!
    @IBOutlet weak var headerTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topTextView.isEditable = false
        bottomTextView.isEditable = false
        headerTextView.isEditable = false
    }
    
    // Sets the user's email in the settings bundle
    @IBAction func finishTutorial(_ sender: UIButton) {
        UserDefaults.standard.set(emailTextField.text, forKey: "userEmail")
    }
    
    // for email validation, the tutorial will not continue until a valid email is entered.
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        
        let alertController = UIAlertController(
            title: "Invalid Email Address",
            message: "The email you entered is invalid or the text field is empty.",
            preferredStyle: .alert)
        alertController.addAction(UIAlertAction(
            title: "OK",
            style: .default,
            handler: nil))
        
        if identifier == "tutorialValidation" {
            if let userEmail = emailTextField.text, emailTest.evaluate(with: userEmail) {    // wont run if empty or nil
                SurveyHandler.shared.requestSurveys()
                return true
            }
            
        }
        
        self.present(alertController, animated: true, completion: nil)
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
}
