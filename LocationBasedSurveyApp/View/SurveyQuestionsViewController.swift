//
//  SurveyQuestionsViewController.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 12/28/17.
//  Copyright © 2017 Mitchell Lombardi. All rights reserved.
//

import UIKit
import WebKit

class SurveyQuestionsViewController: UIViewController {
    
    @IBOutlet weak var surveyLabel: UILabel!
    var survey: Survey?
    let surveyHandler = SurveyHandler.shared
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: (survey?.url)!)
        let request = URLRequest(url: url!)
        
        webView.load(request)
    }

}
