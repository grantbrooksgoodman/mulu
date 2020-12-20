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

/* Third-party Frameworks */
import FirebaseAuth
import PKHUD

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
        
        if let email = UserDefaults.standard.value(forKey: "email") as? String,
           let password = UserDefaults.standard.value(forKey: "password") as? String
        {
            usernameTextField.text = email
            passwordTextField.text = password
        }
        
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
        buildInfoController?.view.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        usernameTextField.addGreyUnderline()
        passwordTextField.addGreyUnderline()
        
        UIView.animate(withDuration: 0.15) {
            for view in self.view.subviews
            {
                view.alpha = view.tag == aTagFor("signInButton") ? 0.6 : 1
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        
    }
    
    //==================================================//
    
    /* Interface Builder Actions */
    
    @IBAction func forgotPasswordButton(_ sender: Any)
    {
        performSegue(withIdentifier: "ForgotPasswordFromSignInSegue", sender: self)
    }
    
    @IBAction func signUpButton(_ sender: Any)
    {
        performSegue(withIdentifier: "SignUpFromSignInSegue", sender: self)
    }
    
    @IBAction func signInButton(_ sender: Any)
    {
        guard usernameTextField.text!.lowercasedTrimmingWhitespace != "" && passwordTextField.text!.lowercasedTrimmingWhitespace != "" else
        {
            let message = "Please evaluate all fields before signing in."
            
            AlertKit().errorAlertController(title:                       "Enter Full Credentials",
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
        
        guard usernameTextField.text!.isValidEmail else
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
        
        showProgressHud()
        
        Auth.auth().signIn(withEmail: usernameTextField.text!, password: passwordTextField.text!) { (returnedResult, returnedError) in
            if let result = returnedResult
            {
                UserSerialiser().getUser(withIdentifier: result.user.uid /*"-MOxMp0oexJ8yCIJilf3"*/) { (returnedUser, errorDescriptor) in
                    if let user = returnedUser
                    {
                        currentUser = user
                        
                        currentUser!.deSerialiseAssociatedTeams { (returnedTeams, errorDescriptor) in
                            if let teams = returnedTeams
                            {
                                hideHud()
                                
                                if let deSerialisedTeams = user.DSAssociatedTeams
                                {
                                    for team in deSerialisedTeams
                                    {
                                        team.setDSParticipants()
                                        
                                        if let associatedTournament = team.associatedTournament
                                        {
                                            associatedTournament.setDSTeams()
                                        }
                                    }
                                }
                                
                                UserDefaults.standard.setValue(self.usernameTextField.text!, forKey: "email")
                                UserDefaults.standard.setValue(self.passwordTextField.text!, forKey: "password")
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                                    if teams.count > 1
                                    {
                                        let actionSheet = UIAlertController(title: "Select Team", message: "Select the team you would like to sign in to.", preferredStyle: .actionSheet)
                                        
                                        for team in teams
                                        {
                                            let teamAction = UIAlertAction(title: team.name!, style: .default) { (action) in
                                                
                                                currentTeam = team
                                                
                                                self.performSegue(withIdentifier: "TabBarFromSignInSegue", sender: self)
                                            }
                                            
                                            actionSheet.addAction(teamAction)
                                        }
                                        
                                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                                            // It will dismiss action sheet
                                        }
                                        
                                        actionSheet.addAction(cancelAction)
                                        
                                        self.present(actionSheet, animated: true, completion: nil)
                                    }
                                    else
                                    {
                                        currentTeam = teams[0]
                                        
                                        self.performSegue(withIdentifier: "TabBarFromSignInSegue", sender: self)
                                    }
                                }
                            }
                            else if let error = errorDescriptor
                            {
                                AlertKit().errorAlertController(title:                       nil,
                                                                message:                     error,
                                                                dismissButtonTitle:          "OK",
                                                                additionalSelectors:         nil,
                                                                preferredAdditionalSelector: nil,
                                                                canFileReport:               true,
                                                                extraInfo:                   nil,
                                                                metadata:                    [#file, #function, #line],
                                                                networkDependent:            false)
                                
                                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                            }
                        }
                    }
                    else if let error = errorDescriptor
                    {
                        AlertKit().errorAlertController(title:                       nil,
                                                        message:                     error,
                                                        dismissButtonTitle:          "OK",
                                                        additionalSelectors:         nil,
                                                        preferredAdditionalSelector: nil,
                                                        canFileReport:               true,
                                                        extraInfo:                   nil,
                                                        metadata:                    [#file, #function, #line],
                                                        networkDependent:            false)
                        
                        report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                    }
                }
            }
            else if let error = returnedError
            {
                let message = errorInformation(forError: (error as NSError))
                
                var alertMessage = errorInformation(forError: (error as NSError))
                
                if alertMessage.hasPrefix("There is no user")
                {
                    alertMessage = "There doesn't seem to be a user with those credentials. Please verify your entries and try again."
                }
                else if alertMessage.hasPrefix("The password is invalid")
                {
                    alertMessage = "The password was incorrect. Please try again."
                }
                
                AlertKit().errorAlertController(title:                       "Sign In Failed",
                                                message:                     alertMessage,
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport:               true,
                                                extraInfo:                   message,
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            true)
                
                report(message, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
            else
            {
                AlertKit().errorAlertController(title:                       nil,
                                                message:                     nil,
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport:               false,
                                                extraInfo:                   nil,
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            false)
                
                report("An unknown error occurred.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
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