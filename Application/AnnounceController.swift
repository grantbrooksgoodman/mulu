//
//  AnnounceController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 02/01/2021.
//  Copyright © 2013-2021 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

class AnnounceController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//
    
    /* MARK: Interface Builder UI Elements */
    
    //ShadowButtons
    @IBOutlet weak var cancelButton: ShadowButton!
    @IBOutlet weak var doneButton:   ShadowButton!
    
    //Other Elements
    @IBOutlet weak var textView: UITextView!
    
    //==================================================//
    
    /* MARK: Class-level Variable Declarations */
    
    var buildInstance: Build!
    
    var previousAnnouncement: String!
    
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
        
        cancelButton.alpha = 0
        doneButton.alpha   = 0
        textView.alpha     = 0
        
        doneButton.isEnabled = false
        
        cancelButton.initialiseLayer(animateTouches:     true,
                                     backgroundColour:   UIColor(hex: 0xE95A53),
                                     customBorderFrame:  nil,
                                     customCornerRadius: nil,
                                     shadowColour:       UIColor(hex: 0xD5443B).cgColor)
        
        doneButton.initialiseLayer(animateTouches:     true,
                                   backgroundColour:   UIColor(hex: 0x60C129),
                                   customBorderFrame:  nil,
                                   customCornerRadius: nil,
                                   shadowColour:       UIColor(hex: 0x3B9A1B).cgColor)
        
        textView.delegate = self
        
        textView.layer.borderWidth   = 2
        textView.layer.cornerRadius  = 10
        textView.layer.borderColor   = UIColor(hex: 0xE1E0E1).cgColor
        textView.clipsToBounds       = true
        textView.layer.masksToBounds = true
        
        GenericSerialiser().getValues(atPath: "/globalAnnouncement") { (returnedString) in
            if let string = returnedString as? String
            {
                self.previousAnnouncement = string
                
                self.textView.text = string
                self.showView()
            }
            else
            {
                AlertKit().errorAlertController(title: "Error",
                                                message: "Unable to retrieve the current announcement.",
                                                dismissButtonTitle: nil,
                                                additionalSelectors: nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport: true,
                                                extraInfo: nil,
                                                metadata: [#file, #function, #line],
                                                networkDependent: true) {
                    self.previousAnnouncement = ""
                    self.showView()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        initialiseController()
        
        currentFile = #file
        buildInfoController?.view.isHidden = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        
    }
    
    //==================================================//
    
    /* MARK: Interface Builder Actions */
    
    @IBAction func cancelButton(_ sender: Any)
    {
        textView.resignFirstResponder()
        
        UIView.animate(withDuration: 0.2) {
            self.cancelButton.alpha = 0
            self.textView.text = self.previousAnnouncement
            self.doneButton.isEnabled = false
        }
    }
    
    @IBAction func doneButton(_ sender: Any)
    {
        guard textView.text!.lowercasedTrimmingWhitespace != "" else
        {
            AlertKit().errorAlertController(title:                       "Nothing Entered",
                                            message:                     "No text was entered. Please try again.",
                                            dismissButtonTitle:          "OK",
                                            additionalSelectors:         nil,
                                            preferredAdditionalSelector: nil,
                                            canFileReport:               false,
                                            extraInfo:                   nil,
                                            metadata:                    [#file, #function, #line],
                                            networkDependent:            false); return
        }
        
        guard textView.text! != previousAnnouncement else
        {
            self.textView.resignFirstResponder()
            
            flashSuccessHUD(text: nil, for: 1.5, delay: 0.5) {
                self.cancelButton(self.cancelButton!)
            }; return
        }
        
        textView.resignFirstResponder()
        
        UIView.animate(withDuration: 0.2) {
            self.cancelButton.alpha = 0
        } completion: { (_) in
            showProgressHUD(text: "Setting announcement...", delay: 0)
            
            GenericSerialiser().setValue(onKey: "/globalAnnouncement", withData: self.textView.text!) { (returnedError) in
                if let error = returnedError
                {
                    hideHUD(delay: 1) {
                        AlertKit().errorAlertController(title:                       "Failed to Set Announcement",
                                                        message:                     error.localizedDescription,
                                                        dismissButtonTitle:          nil,
                                                        additionalSelectors:         nil,
                                                        preferredAdditionalSelector: nil,
                                                        canFileReport:               true,
                                                        extraInfo:                   errorInfo(error),
                                                        metadata:                    [#file, #function, #line],
                                                        networkDependent:            true)
                    }
                }
                else
                {
                    hideHUD(delay: 1) {
                        flashSuccessHUD(text: nil, for: 1, delay: nil) {
                            self.previousAnnouncement = self.textView.text!
                            self.doneButton.isEnabled = false
                        }
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
    
    func showView()
    {
        UIView.animate(withDuration: 0.2) {
            self.doneButton.alpha = 1
            self.textView.alpha = 1
        }
    }
}

//==================================================//

/* MARK: Extensions */

extension AnnounceController: UITextViewDelegate
{
    func textViewDidBeginEditing(_ textView: UITextView)
    {
        UIView.animate(withDuration: 0.2) {
            self.cancelButton.alpha = 1
        }
    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        doneButton.isEnabled = textView.text! != previousAnnouncement
    }
}
