//
//  NotifyController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 02/01/2021.
//  Copyright © 2013-2021 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

class NotifyController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//
    
    /* MARK: Interface Builder UI Elements */
    
    //UITextFields
    @IBOutlet weak var titleTextField:   UITextField!
    @IBOutlet weak var messageTextField: UITextField!
    
    //Other Elements
    @IBOutlet weak var sendButton: ShadowButton!
    
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
        
        sendButton.initialiseLayer(animateTouches:     true,
                                   backgroundColour:   UIColor(hex: 0x60C129),
                                   customBorderFrame:  nil,
                                   customCornerRadius: nil,
                                   shadowColour:       UIColor(hex: 0x3B9A1B).cgColor)
        
        titleTextField.tag   = aTagFor("titleTextField")
        messageTextField.tag = aTagFor("messageTextField")
        
        titleTextField.delegate   = self
        messageTextField.delegate = self
        
        setTextFieldAttributes()
        
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: titleTextField, queue: .main) { (notification) -> Void in
            self.titleTextField.text = "  \(self.titleTextField.text!.leadingWhitespaceRemoved)"
        }
        
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: messageTextField, queue: .main) { (notification) -> Void in
            self.messageTextField.text = "  \(self.messageTextField.text!.leadingWhitespaceRemoved)"
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        currentFile = #file
        buildInfoController?.view.isHidden = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        
    }
    
    //==================================================//
    
    /* MARK: Interface Builder Actions */
    
    @IBAction func sendButton(_ sender: Any)
    {
        findAndResignFirstResponder()
        
        guard titleTextField.text!.lowercasedTrimmingWhitespace != "" && messageTextField.text!.lowercasedTrimmingWhitespace != "" else
        {
            AlertKit().errorAlertController(title:                       "Evaluate All Fields",
                                            message:                     "Please evaluate both fields before sending a notification.",
                                            dismissButtonTitle:          "OK",
                                            additionalSelectors:         nil,
                                            preferredAdditionalSelector: nil,
                                            canFileReport:               false,
                                            extraInfo:                   nil,
                                            metadata:                    [#file, #function, #line],
                                            networkDependent:            false); return
        }
        
        showProgressHUD(text: "Sending notification...", delay: 0)
        
        notifyAllUsers(title: titleTextField.text!.leadingWhitespaceRemoved, body: messageTextField.text!.leadingWhitespaceRemoved) { (errorDescriptor) in
            if let error = errorDescriptor
            {
                hideHUD(delay: 0.5) {
                    AlertKit().errorAlertController(title:                       "Failed to Send Notification",
                                                    message:                     error,
                                                    dismissButtonTitle:          nil,
                                                    additionalSelectors:         nil,
                                                    preferredAdditionalSelector: nil,
                                                    canFileReport:               true,
                                                    extraInfo:                   error,
                                                    metadata:                    [#file, #function, #line],
                                                    networkDependent:            true)
                }
            }
            else
            {
                hideHUD(delay: 1) {
                    flashSuccessHUD(text: nil, for: 1.5, delay: 0.5) {
                        self.titleTextField.text = "  "
                        self.messageTextField.text = "  "
                    }
                }
            }
        }
    }
    
    //==================================================//
    
    /* MARK: Other Functions */
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }
    
    func setTextFieldAttributes()
    {
        for textField in [titleTextField, messageTextField]
        {
            textField!.layer.borderWidth   = 2
            textField!.layer.cornerRadius  = 10
            textField!.layer.borderColor   = UIColor(hex: 0xE1E0E1).cgColor
            textField!.clipsToBounds       = true
            textField!.layer.masksToBounds = true
            
            textField!.text = "  "
        }
    }
}

//==================================================//

/* MARK: Extensions */

extension NotifyController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if textField.tag == aTagFor("titleTextField")
        {
            messageTextField.becomeFirstResponder()
        }
        else { messageTextField.resignFirstResponder() }
        
        return true
    }
}
