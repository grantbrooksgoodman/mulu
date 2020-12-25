//
//  NewChallengeController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 23/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

/* Third-party Frameworks */
import PKHUD

class NewChallengeController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//
    
    /* Interface Builder UI Elements */
    
    //UIBarButtonItems
    @IBOutlet weak var backButton:   UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var nextButton:   UIBarButtonItem!
    
    //UITextFields
    @IBOutlet weak var largeTextField: UITextField!
    @IBOutlet weak var mediaTextField: UITextField!
    
    //UITextViews
    @IBOutlet weak var promptTextView: UITextView!
    @IBOutlet weak var stepTextView:   UITextView!
    
    //Other Elements
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var alertSwitch: UISwitch!
    @IBOutlet weak var mediaSegmentedControl: UISegmentedControl!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var stepTitleLabel: UILabel!
    
    //==================================================//
    
    /* Class-level Variable Declarations */
    
    //Booleans
    var hasShownWarning = false
    var isWorking       = false
    
    //Strings
    var challengeTitle: String?
    var stepText = "🔴 Set title\n🔴 Set prompt\n🔴 Set point value\n🔴 Add media\n🔴 Toggle alerts"
    
    //Other Declarations
    var buildInstance: Build!
    var currentStep = Step.title
    var mediaLink: URL?
    var mediaType: Challenge.MediaType?
    var pointValue: Int?
    var stepAttributes: [NSAttributedString.Key:Any]!
    
    //==================================================//
    
    /* Enumerated Type Declarations */
    
    enum Step
    {
        case title
        case prompt
        case pointValue
        case media
        case alert
    }
    
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
        
        navigationController?.presentationController?.delegate = self
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        
        stepAttributes = [.font: UIFont(name: "SFUIText-Medium", size: 11)!,
                          .paragraphStyle: paragraphStyle]
        
        stepTextView.attributedText = NSAttributedString(string: stepText, attributes: stepAttributes)
        
        promptTextView.layer.borderWidth   = 2
        promptTextView.layer.cornerRadius  = 10
        promptTextView.layer.borderColor   = UIColor(hex: 0xE1E0E1).cgColor
        promptTextView.clipsToBounds       = true
        promptTextView.layer.masksToBounds = true
        
        let navigationButtonAttributes: [NSAttributedString.Key:Any] = [.font: UIFont.boldSystemFont(ofSize: 17)]
        
        backButton.setTitleTextAttributes(navigationButtonAttributes, for: .normal)
        backButton.setTitleTextAttributes(navigationButtonAttributes, for: .highlighted)
        backButton.setTitleTextAttributes(navigationButtonAttributes, for: .disabled)
        
        nextButton.setTitleTextAttributes(navigationButtonAttributes, for: .normal)
        nextButton.setTitleTextAttributes(navigationButtonAttributes, for: .highlighted)
        nextButton.setTitleTextAttributes(navigationButtonAttributes, for: .disabled)
        
        mediaTextField.delegate = self
        largeTextField.delegate = self
        
        forwardToTitle()
        mediaTextField.text = "https://s3.amazonaws.com/dl.getforma.com/.attachments/f51216153e8473b38031c6e0a0b1dff5/18864464/tiktokcupidshuffle.mp4?AWSAccessKeyId=AKIAR7KB7OYSMPA2CKCB&Expires=1608938024&Signature=wZmXCyYvCKKUsDRmHPOHLzIRIsM%3D&response-content-disposition=attachment%3Bfilename%2A%3DUTF-8%27%27tiktokcupidshuffle.mp4&response-content-type=video%2Fmp4"
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
    
    /* Interface Builder Actions */
    
    @IBAction func backButton(_ sender: Any)
    {
        switch currentStep
        {
        case .pointValue:
            goBack()
            forwardToPrompt()
        case .media:
            goBack()
            hasShownWarning = false
            forwardToPointValue()
        case .alert:
            goBack()
            hasShownWarning = false
            forwardToMedia()
        default:
            goBack()
            forwardToTitle()
        }
    }
    
    @IBAction func cancelButton(_ sender: Any)
    {
        confirmCancellation()
    }
    
    @IBAction func mediaSegmentedControl(_ sender: Any)
    {
        if mediaSegmentedControl.selectedSegmentIndex == 0
        {
            UIView.animate(withDuration: 0.2) {
                self.mediaTextField.alpha = 1
            } completion: { (_) in
                self.mediaTextField.becomeFirstResponder()
            }
        }
        else
        {
            UIView.animate(withDuration: 0.2) {
                self.mediaTextField.alpha = 0
            } completion: { (_) in
                findAndResignFirstResponder()
            }
        }
    }
    
    @IBAction func nextButton(_ sender: Any)
    {
        nextButton.isEnabled = false
        backButton.isEnabled = false
        
        switch currentStep
        {
        case .title:
            if verifyTitle()
            {
                forwardToPrompt()
            }
            else
            {
                AlertKit().errorAlertController(title:                       "Invalid Title",
                                                message:                     "Please try again.",
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport:               false,
                                                extraInfo:                   nil,
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            false)
                nextButton.isEnabled = true
            }
        case .prompt:
            if verifyPrompt()
            {
                forwardToPointValue()
            }
            else
            {
                AlertKit().errorAlertController(title:                       "Invalid Prompt",
                                                message:                     "Please try again.",
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport:               false,
                                                extraInfo:                   nil,
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            false)
                nextButton.isEnabled = true
                backButton.isEnabled = true
            }
        case .pointValue:
            if verifyPointValue()
            {
                forwardToMedia()
            }
            else
            {
                AlertKit().errorAlertController(title:                       "Invalid Point Value",
                                                message:                     "Please try again.",
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport:               false,
                                                extraInfo:                   nil,
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            false)
                nextButton.isEnabled = true
                backButton.isEnabled = true
            }
        case .media:
            if mediaSegmentedControl.selectedSegmentIndex == 1
            {
                forwardToAlert()
            }
            else
            {
                findAndResignFirstResponder()
                
                if !hasShownWarning
                {
                    PKHUD.sharedHUD.contentView = PKHUDProgressView(title: nil, subtitle: "Analysing media...")
                    PKHUD.sharedHUD.show()
                }
                
                MediaAnalyser().analyseMedia(linkString: mediaTextField.text!) { (analysisResult) in
                    if !self.hasShownWarning
                    {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                            hideHud()
                        }
                    }
                    
                    DispatchQueue.main.async {
                        switch analysisResult
                        {
                        case .gif:
                            self.mediaType = .gif
                            self.mediaLink = URL(string: self.mediaTextField.text!)!
                            
                            self.forwardToAlert()
                        case .image:
                            self.mediaType = .staticImage
                            self.mediaLink = URL(string: self.mediaTextField.text!)!
                            
                            self.forwardToAlert()
                        case .video:
                            self.mediaType = .video
                            self.mediaLink = MediaAnalyser().convertToEmbedded(linkString: self.mediaTextField.text!) ?? URL(string: self.mediaTextField.text!)!
                            
                            self.forwardToAlert()
                        case .other:
                            if !self.hasShownWarning
                            {
                                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(750)) {
                                    AlertKit().successAlertController(withTitle:             "Warning!",
                                                                      withMessage:           "The provided link appears to be valid but its media content could not be fully verified.\n\nPlease verify your entry before continuing.",
                                                                      withCancelButtonTitle:  "OK",
                                                                      withAlternateSelectors: nil,
                                                                      preferredActionIndex:   nil)
                                    
                                    self.mediaTextField.becomeFirstResponder()
                                    
                                    self.nextButton.isEnabled = true
                                    self.backButton.isEnabled = true
                                    
                                    self.hasShownWarning = true
                                }
                            }
                            else
                            {
                                self.forwardToAlert()
                            }
                        case .error:
                            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(750)) {
                                AlertKit().errorAlertController(title:                       "Invalid Link",
                                                                message:                     "The provided link was not valid. Please try again.",
                                                                dismissButtonTitle:          "OK",
                                                                additionalSelectors:         nil,
                                                                preferredAdditionalSelector: nil,
                                                                canFileReport:               false,
                                                                extraInfo:                   nil,
                                                                metadata:                    [#file, #function, #line],
                                                                networkDependent:            false)
                                
                                self.mediaTextField.becomeFirstResponder()
                                
                                self.nextButton.isEnabled = true
                                self.backButton.isEnabled = true
                            }
                        }
                    }
                }
            }
        default:
            forwardToFinish()
        }
    }
    
    //==================================================//
    
    /* Other Functions */
    
    func confirmCancellation()
    {
        AlertKit().confirmationAlertController(title: "Are You Sure?",
                                               message: "Would you really like to cancel?",
                                               cancelConfirmTitles: ["cancel": "No", "confirm": "Yes"],
                                               confirmationDestructive: true,
                                               confirmationPreferred: false,
                                               networkDepedent: false) { (didConfirm) in
            if didConfirm!
            {
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func createChallenge()
    {
        var media: (URL, Challenge.MediaType)?
        
        if let type = mediaType, let link = mediaLink
        {
            media = (link, type)
        }
        
        ChallengeSerialiser().createChallenge(title: challengeTitle!, prompt: promptTextView.text!, datePosted: Date(), pointValue: pointValue!, media: media) { (returnedIdentifier, errorDescriptor) in
            if returnedIdentifier != nil
            {
                PKHUD.sharedHUD.contentView = PKHUDSuccessView(title: nil, subtitle: "Successfully created challenge.")
                PKHUD.sharedHUD.show()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    hideHud()
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }
            }
            else
            {
                AlertKit().errorAlertController(title: "Couldn't Create Challenge",
                                                message: errorDescriptor!,
                                                dismissButtonTitle: nil,
                                                additionalSelectors: nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport: true,
                                                extraInfo: errorDescriptor!,
                                                metadata: [#file, #function, #line],
                                                networkDependent: true)
                
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func forwardToTitle()
    {
        largeTextField.keyboardType = .default
        largeTextField.placeholder = "Enter a title"
        largeTextField.text = challengeTitle ?? nil
        
        stepText = "🟡 Set title\n🔴 Set prompt\n🔴 Set point value\n🔴 Add media\n🔴 Toggle alerts"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })
        
        UIView.animate(withDuration: 0.2) {
            self.largeTextField.alpha = 1
        } completion: { (_) in
            self.largeTextField.becomeFirstResponder()
            
            self.nextButton.isEnabled = true
        }
        
        currentStep = .title
    }
    
    func forwardToPrompt()
    {
        stepTitleLabel.text = "CHALLENGE PROMPT"
        findAndResignFirstResponder()
        stepProgress(forwardDirection: true)
        
        stepText = "🟢 Set title\n🟡 Set prompt\n🔴 Set point value\n🔴 Add media\n🔴 Toggle alerts"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })
        
        UIView.animate(withDuration: 0.2) {
            self.largeTextField.alpha = 0
        } completion: { (_) in
            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.stepTitleLabel.alpha = 1
                self.promptTextView.alpha = 1
            } completion: { (_) in
                self.promptTextView.becomeFirstResponder()
                
                self.nextButton.isEnabled = true
                self.backButton.isEnabled = true
            }
        }
        
        currentStep = .prompt
    }
    
    func forwardToPointValue()
    {
        largeTextField.keyboardType = .numberPad
        largeTextField.placeholder = "Enter a point value"
        
        if let pointValue = pointValue
        {
            largeTextField.text = String(pointValue)
        }
        else { largeTextField.text = nil }
        
        findAndResignFirstResponder()
        stepProgress(forwardDirection: true)
        
        stepText = "🟢 Set title\n🟢 Set prompt\n🟡 Set point value\n🔴 Add media\n🔴 Toggle alerts"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })
        
        UIView.animate(withDuration: 0.2) {
            self.promptTextView.alpha = 0
            self.stepTitleLabel.alpha = 0
        } completion: { (_) in
            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.largeTextField.alpha = 1
            } completion: { (_) in
                self.largeTextField.becomeFirstResponder()
                
                self.nextButton.isEnabled = true
                self.backButton.isEnabled = true
            }
        }
        
        currentStep = .pointValue
    }
    
    func forwardToMedia()
    {
        if mediaTextField.text!.lowercasedTrimmingWhitespace == ""
        {
            mediaTextField.text = "https://"
        }
        
        stepTitleLabel.text = "ADD MEDIA?"
        stepTitleLabel.textAlignment = .left
        
        findAndResignFirstResponder()
        stepProgress(forwardDirection: true)
        
        stepText = "🟢 Set title\n🟢 Set prompt\n🟢 Set point value\n🟡 Add media\n🔴 Toggle alerts"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })
        
        UIView.animate(withDuration: 0.2) {
            self.largeTextField.alpha = 0
        } completion: { (_) in
            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.stepTitleLabel.alpha = 1
                self.mediaSegmentedControl.alpha = 1
            } completion: { (_) in
                self.mediaSegmentedControl(self.mediaSegmentedControl!)
                
                self.nextButton.isEnabled = true
                self.backButton.isEnabled = true
            }
        }
        
        currentStep = .media
        nextButton.title = "Next"
    }
    
    func forwardToAlert()
    {
        findAndResignFirstResponder()
        stepProgress(forwardDirection: true)
        
        stepText = "🟢 Set title\n🟢 Set prompt\n🟢 Set point value\n🟢 Add media\n🟡 Toggle alerts"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })
        
        UIView.animate(withDuration: 0.2) {
            self.mediaSegmentedControl.alpha = 0
            self.mediaTextField.alpha = 0
            self.stepTitleLabel.alpha = 0
        } completion: { (_) in
            self.stepTitleLabel.text = "ALERT USERS?"
            self.stepTitleLabel.textAlignment = .center
            
            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.stepTitleLabel.alpha = 1
                self.alertSwitch.alpha = 1
            }  completion: { (_) in
                self.nextButton.isEnabled = true
                self.backButton.isEnabled = true
            }
        }
        
        currentStep = .alert
        nextButton.title = "Finish"
    }
    
    func forwardToFinish()
    {
        nextButton.isEnabled = false
        backButton.isEnabled = false
        cancelButton.isEnabled = false
        
        findAndResignFirstResponder()
        stepProgress(forwardDirection: true)
        
        stepText = "🟢 Set title\n🟢 Set prompt\n🟢 Set point value\n🟢 Add media\n🟢 Toggle alerts"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })
        
        UIView.animate(withDuration: 0.2) {
            self.alertSwitch.alpha = 0
            self.stepTitleLabel.alpha = 0
        } completion: { (_) in
            self.stepTitleLabel.text = "WORKING..."
            self.isWorking = true
            
            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.stepTitleLabel.alpha = 1
                self.activityIndicator.alpha = 1
            } completion: { (_) in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2500)) {
                    self.createChallenge()
                }
            }
        }
    }
    
    func goBack()
    {
        isWorking = false
        
        nextButton.isEnabled = false
        backButton.isEnabled = false
        
        findAndResignFirstResponder()
        stepProgress(forwardDirection: false)
        
        UIView.animate(withDuration: 0.2) {
            for subview in self.view.subviews
            {
                if subview.tag != aTagFor("titleLabel") && subview.tag != aTagFor("progressView") && subview.tag != aTagFor("stepTextView")
                {
                    subview.alpha = 0
                }
            }
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }
    
    func stepProgress(forwardDirection: Bool)
    {
        UIView.animate(withDuration: 0.2) {
            self.progressView.setProgress(self.progressView.progress + (forwardDirection ? 0.2 : -0.2), animated: true)
        }
    }
    
    func verifyTitle() -> Bool
    {
        if largeTextField.text!.lowercasedTrimmingWhitespace != ""
        {
            challengeTitle = largeTextField.text!
            return true
        }
        
        return false
    }
    
    func verifyPrompt() -> Bool
    {
        if promptTextView.text!.lowercasedTrimmingWhitespace != ""
        {
            return true
        }
        
        return false
    }
    
    func verifyPointValue() -> Bool
    {
        if let points = Int(largeTextField.text!.lowercasedTrimmingWhitespace)
        {
            pointValue = points
            return true
        }
        
        return false
    }
}

extension NewChallengeController: UIAdaptivePresentationControllerDelegate
{
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController)
    {
        if !isWorking
        {
            confirmCancellation()
        }
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool
    {
        return false
    }
}
extension NewChallengeController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        nextButton(nextButton!)
        return true
    }
}
