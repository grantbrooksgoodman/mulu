//
//  ForgotPasswordController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 19/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

/* Third-party Frameworks */
import FirebaseAuth

class ForgotPasswordController: UIViewController, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate
{
    //==================================================//
    
    /* MARK: Interface Builder UI Elements */
    
    //UIButtons
    @IBOutlet weak var backButton:          UIButton!
    @IBOutlet weak var resetPasswordButton: UIButton!
    
    //Other Elements
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var noticeLabel: UILabel!
    
    //==================================================//
    
    /* MARK: Class-level Variable Declarations */
    
    var buildInstance: Build!
    
    //==================================================//
    
    /* MARK: Initialiser Function */
    
    func initialiseController()
    {
        lastInitialisedController = self
        buildInstance = Build(self)
    }
    
    //==================================================//
    
    /* MARK: Overridden Functions */
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        initialiseController()
        
        view.setBackground(withImageNamed: "Gradient.png")
        
        emailTextField.delegate = self
        
        noticeLabel.tag = aTagFor("noticeLabel")
        resetPasswordButton.tag = aTagFor("resetPasswordButton")
        
        resetPasswordButton.layer.cornerRadius = 5
        
        for view in view.subviews
        {
            view.alpha = 0
        }
        
        let tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(ForgotPasswordController.dismissKeyboard))
        tapRecogniser.delegate = self
        tapRecogniser.numberOfTapsRequired = 1
        
        view.addGestureRecognizer(tapRecogniser)
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
        
        emailTextField.addGreyUnderline()
        
        UIView.animate(withDuration: 0.15) {
            for view in self.view.subviews
            {
                if view.tag == aTagFor("resetPasswordButton")
                {
                    view.alpha = 0.6
                }
                else if view.tag != aTagFor("noticeLabel")
                {
                    view.alpha = 1
                }
            }
        } completion: { (_) in self.emailTextField.becomeFirstResponder() }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        
    }
    
    //==================================================//
    
    /* MARK: Interface Builder Actions */
    
    @IBAction func resetPasswordButton(_ sender: Any)
    {
        guard emailTextField.text!.isValidEmail else
        {
            let message = "The e-mail address is improperly formatted. Please try again."
            
            AlertKit().errorAlertController(title:                       "Invalid E-mail",
                                            message:                     message,
                                            dismissButtonTitle:          "OK",
                                            additionalSelectors:         nil,
                                            preferredAdditionalSelector: nil,
                                            canFileReport:               false,
                                            extraInfo:                   nil,
                                            metadata:                    [#file, #function, #line],
                                            networkDependent:            false)
            
            report(message, errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return
        }
        
        Auth.auth().sendPasswordReset(withEmail: emailTextField.text!) { (returnedError) in
            if let error = returnedError
            {
                var alertMessage = error.localizedDescription
                
                if alertMessage.hasPrefix("There is no user")
                {
                    alertMessage = "There doesn't seem to be a user with that e-mail address. Please verify your entry and try again."
                }
                
                AlertKit().errorAlertController(title:                       "Couldn't Reset Password",
                                                message:                     alertMessage,
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport:               true,
                                                extraInfo:                   errorInfo(error),
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            true)
                
                report(error.localizedDescription, errorCode: (error as NSError).code, isFatal: false, metadata: [#file, #function, #line])
            }
            else
            {
                self.emailTextField.resignFirstResponder()
                
                UIView.animate(withDuration: 0.3, delay: 1, options: []) {
                    self.emailTextField.alpha = 0
                    self.resetPasswordButton.alpha = 0
                    
                    self.noticeLabel.alpha = 1
                }
            }
        }
    }
    
    @IBAction func backButton(_ sender: Any)
    {
        performSegue(withIdentifier: "SignInFromForgotPasswordSegue", sender: self)
    }
    
    //==================================================//
    
    /* MARK: Other Functions */
    
    @objc func dismissKeyboard()
    {
        findAndResignFirstResponder()
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }
}

//==================================================//

/* MARK: Extensions */

/**/

/* MARK: UITextFieldDelegate */
extension ForgotPasswordController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        emailTextField.resignFirstResponder()
        
        return true
    }
}
