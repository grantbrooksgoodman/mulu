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

class SignUpController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//
    
    /* Interface Builder UI Elements */
    
    //UIButtons
    @IBOutlet weak var backButton:   UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    //UITextFields
    @IBOutlet weak var emailTextField:    UITextField!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
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
        
        fullNameTextField.addGreyUnderline()
        emailTextField.addGreyUnderline()
        passwordTextField.addGreyUnderline()
        
        UIView.animate(withDuration: 0.15) {
            for view in self.view.subviews
            {
                view.alpha = view.tag == aTagFor("signUpButton") ? 0.6 : 1
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        
    }
    
    //==================================================//
    
    /* Interface Builder Actions */
    
    @IBAction func backButton(_ sender: Any)
    {
        performSegue(withIdentifier: "signInFromSignUpSegue", sender: self)
    }
    
    @IBAction func signUpButton(_ sender: Any)
    {
        performSegue(withIdentifier: "PostSignUpFromSignUpSegue", sender: self)
    }
    
    //==================================================//
    
    /* Other Functions */
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }
}

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
        else
        {
            passwordTextField.resignFirstResponder()
        }
        
        return true
    }
}
