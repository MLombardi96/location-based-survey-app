//
//  SurveyQuestionsViewController.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 12/28/17.
//  Copyright © 2017 Mitchell Lombardi. All rights reserved.
//

import UIKit
import WebKit
import CoreData

class SurveyQuestionsViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    
    @IBOutlet weak var surveyLabel: UILabel!
    @IBOutlet weak var webView: WKWebView!
    
    var survey: Survey?
    
    func setupWebView() {
        let source = """
                        document.addEventListener('DOMSubtreeModified', function(e) {
                            let el = document.getElementById('EndOfSurvey');
                            
                            if (el) {
                                document.removeEventListener(e.type, arguments.callee);
                                webkit.messageHandlers.surveyEnd.postMessage('Survey Complete!');
                            }
                        });
                        """
        
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        
        self.webView.configuration.userContentController.addUserScript(script)
        self.webView.configuration.userContentController.add(self, name: "surveyEnd")
        self.webView.navigationDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupWebView()
        
        
        let url = URL(string: (survey?.url)!)
        let request = URLRequest(url: url!)
        
        webView.load(request)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("Message:", message.body)
        survey?.isComplete = true                                           // doesn't save until the user exits the area
        _ = navigationController?.popViewController(animated: true)
    }
}
