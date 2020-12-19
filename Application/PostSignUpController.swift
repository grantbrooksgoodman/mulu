//
//  PostSignUpController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 04/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

class PostSignUpController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//
    
    /* Interface Builder UI Elements */
    
    //UIButtons
    @IBOutlet weak var contactUsButton:         UIButton!
    @IBOutlet weak var goButton:                UIButton!
    @IBOutlet weak var inviteYourFriendsButton: UIButton!
    
    //Other Elements
    @IBOutlet weak var teamCodeTextField: UITextField!
    
    //==================================================//
    
    /* Class-level Variable Declarations */
    
    var buildInstance: Build!
    
    //==================================================//
    
    /* Initialiser Function */
    
    func initialiseController()
    {
        lastInitialisedController = self
        buildInstance = Build(self)
    }
    
    //==================================================//
    
    /* Overridden Functions */
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        initialiseController()
        
        view.setBackground(withImageNamed: "Gradient.png")
        
        contactUsButton.layer.cornerRadius = 5
        inviteYourFriendsButton.layer.cornerRadius = 5
        
        for view in view.subviews
        {
            view.alpha = 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        currentFile = #file
        buildInfoController?.view.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        teamCodeTextField.addGreyUnderline()
        
        UIView.animate(withDuration: 0.15) {
            for view in self.view.subviews
            {
                view.alpha = 1
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        
    }
    
    //==================================================//
    
    /* Interface Builder Actions */
    
    @IBAction func goButton(_ sender: Any)
    {
        teamCodeTextField.resignFirstResponder()
    }
    
    @IBAction func contactUsButton(_ sender: Any)
    {
    }
    
    @IBAction func inviteYourFriendsButton(_ sender: Any)
    {
    }
    
    @IBAction func linkButton(_ sender: Any)
    {
        guard let button = sender as? UIButton else
        { report("Invalid link sender.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return }
        
        if button.titleLabel!.text == "www.getmulu.com"
        {
            let url = URL(string: "https://www.getmulu.com/")!
            
            UIApplication.shared.open(url, options: [:]) { _ in }
        }
        else
        {
            AlertKit().optionAlertController(title:                "Visit us on...",
                                             message:              "",
                                             cancelButtonTitle:    nil,
                                             additionalButtons:    [("Instagram", false), ("Twitter", false)],
                                             preferredActionIndex: nil,
                                             networkDependent:     true) { (selectedIndex) in
                if let index = selectedIndex, index != -1
                {
                    let urlString = index == 0 ? "https://www.instagram.com/mulufitness/" : "https://twitter.com/mulufitness"
                    let url = URL(string: urlString)!
                    
                    UIApplication.shared.open(url, options: [:]) { _ in }
                }
            }
        }
    }
    
    //==================================================//
    
    /* Other Functions */
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }
}
