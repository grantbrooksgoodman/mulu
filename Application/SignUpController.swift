//
//  SignUpController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 18/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

class SignUpController: UIViewController, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate
{
    //==================================================//
    
    /* MARK: Interface Builder UI Elements */
    
    //UIButtons
    @IBOutlet weak var backButton:   UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    //UITextFields
    @IBOutlet weak var emailTextField:    UITextField!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    //==================================================//
    
    /* MARK: Class-level Variable Declarations */
    
    var buildInstance: Build!
    var userIdentifier: String!
    
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
        
        fullNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        fullNameTextField.tag = aTagFor("fullNameTextField")
        emailTextField.tag = aTagFor("emailTextField")
        passwordTextField.tag = aTagFor("passwordTextField")
        signUpButton.tag = aTagFor("signUpButton")
        
        signUpButton.layer.cornerRadius = 5
        
        for view in view.subviews
        {
            view.alpha = 0
        }
        
        let tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(SignUpController.dismissKeyboard))
        tapRecogniser.delegate = self
        tapRecogniser.numberOfTapsRequired = 1
        
        view.addGestureRecognizer(tapRecogniser)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        currentFile = #file
        buildInfoController?.view.isHidden = !preReleaseApplication
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        fullNameTextField.addGreyUnderline()
        emailTextField.addGreyUnderline()
        passwordTextField.addGreyUnderline()
        
        UIView.animate(withDuration: 0.15) {
            for view in self.view.subviews
            {
                view.alpha = view.tag == aTagFor("signUpButton") ? 0.6 : 1
            }
        } completion: { (_) in self.fullNameTextField.becomeFirstResponder() }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "PostSignUpFromSignUpSegue"
        {
            let destination = segue.destination as! PostSignUpController
            
            destination.userIdentifier = userIdentifier
        }
    }
    
    //==================================================//
    
    /* MARK: Interface Builder Actions */
    
    @IBAction func backButton(_ sender: Any)
    {
        performSegue(withIdentifier: "SignInFromSignUpSegue", sender: self)
    }
    
    @IBAction func signUpButton(_ sender: Any)
    {
        guard fullNameTextField.text!.lowercasedTrimmingWhitespace != "" && emailTextField.text!.lowercasedTrimmingWhitespace != "" && passwordTextField.text!.lowercasedTrimmingWhitespace != "" else
        {
            let message = "You must evaluate all fields before creating an account."
            
            AlertKit().errorAlertController(title:                       "Fill Out All Fields",
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
        
        guard fullNameTextField.text!.components(separatedBy: " ").count > 1 else
        {
            let message = "Please be sure to enter both your first and last name."
            
            AlertKit().errorAlertController(title:                       "Improper Name Format",
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
        
        guard passwordTextField.text!.count > 5 else
        {
            let message = "Passwords must be 6 or more characters. Please try again."
            
            AlertKit().errorAlertController(title:                       "Invalid Password Length",
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
        
        let nameComponents = fullNameTextField.text!.components(separatedBy: " ")
        let firstName = String(nameComponents[0])
        let lastName = String(nameComponents[1...nameComponents.count - 1].joined(separator: " "))
        
        UserSerialiser().createAccount(associatedTeams: nil,
                                       emailAddress: emailTextField.text!,
                                       firstName: firstName,
                                       lastName: lastName,
                                       password: passwordTextField.text!,
                                       profileImageData: nil,
                                       pushTokens: nil) { (returnedUser, errorDescriptor) in
            
            if let user = returnedUser
            {
                report("SUCCESSFULLY CREATED USER \(user.firstName!) \(user.lastName!)!", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                
                UserDefaults.standard.setValue(self.emailTextField.text!, forKey: "email")
                UserDefaults.standard.setValue(self.passwordTextField.text!, forKey: "password")
                
                self.userIdentifier = user.associatedIdentifier
                self.performSegue(withIdentifier: "PostSignUpFromSignUpSegue", sender: self)
            }
            else if let error = errorDescriptor
            {
                let message = error.components(separatedBy: " (")[0]
                
                AlertKit().errorAlertController(title:                       "Couldn't Create Account",
                                                message:                     message,
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport:               true,
                                                extraInfo:                   error,
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            true)
                
                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
        }
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
extension SignUpController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if textField.tag == aTagFor("fullNameTextField")
        {
            emailTextField.becomeFirstResponder()
        }
        else if textField.tag == aTagFor("emailTextField")
        {
            passwordTextField.becomeFirstResponder()
        }
        else { passwordTextField.resignFirstResponder() }
        
        return true
    }
}
