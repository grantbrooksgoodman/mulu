//
//  SignInController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 18/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

class SignInController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//
    
    /* Interface Builder UI Elements */
    
    //UIButtons
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var signInButton:         UIButton!
    @IBOutlet weak var signUpButton:         UIButton!
    
    //UITextFields
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    
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
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        usernameTextField.tag = aTagFor("usernameTextField")
        passwordTextField.tag = aTagFor("passwordTextField")
        signInButton.tag = aTagFor("signInButton")
        
        let bottomButtonAttributes: [NSAttributedString.Key: Any] = [.underlineStyle: NSUnderlineStyle.single.rawValue]
        
        let signUpString = NSAttributedString(string: "Sign up", attributes: bottomButtonAttributes)
        let forgotPasswordString = NSAttributedString(string: "Forgot password?", attributes: bottomButtonAttributes)
        
        signUpButton.setAttributedTitle(signUpString, for: .normal)
        forgotPasswordButton.setAttributedTitle(forgotPasswordString, for: .normal)
        
        signInButton.layer.cornerRadius = 5
        
        for view in view.subviews
        {
            view.alpha = 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        currentFile = #file
        buildInfoController?.view.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        usernameTextField.addGreyUnderline()
        passwordTextField.addGreyUnderline()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            UIView.animate(withDuration: 0.2) {
                for view in self.view.subviews
                {
                    view.alpha = view.tag == aTagFor("signInButton") ? 0.6 : 1
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        
    }
    
    //==================================================//
    
    /* Interface Builder Actions */
    
    //==================================================//
    
    /* Other Functions */
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }
}

extension SignInController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if textField.tag == aTagFor("usernameTextField")
        {
            passwordTextField.becomeFirstResponder()
        }
        else
        {
            passwordTextField.resignFirstResponder()
        }
        
        return true
    }
}

extension UITextField
{
    func addGreyUnderline()
    {
        let bottomLine = CALayer()
        
        bottomLine.frame = CGRect(x: 0, y: frame.size.height - 1, width: frame.size.width, height: 2)
        bottomLine.backgroundColor = UIColor(hex: 0xB0B0B0).cgColor
        
        borderStyle = .none
        
        layer.addSublayer(bottomLine)
    }
}
