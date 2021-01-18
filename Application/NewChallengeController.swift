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
import FirebaseStorage

class NewChallengeController: UIViewController, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    //UIBarButtonItems
    @IBOutlet var backButton:   UIBarButtonItem!
    @IBOutlet var cancelButton: UIBarButtonItem!
    @IBOutlet var nextButton:   UIBarButtonItem!

    //UITextFields
    @IBOutlet var largeTextField: UITextField!
    @IBOutlet var mediaTextField: UITextField!

    //UITextViews
    @IBOutlet var promptTextView: UITextView!
    @IBOutlet var stepTextView:   UITextView!

    //Other Elements
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var mediaSegmentedControl: UISegmentedControl!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var stepTitleLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var uploadButton: UIButton!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    //Arrays
    var selectedTournaments = [String]()
    var tournamentArray: [Tournament]?

    //Booleans
    var currentlyUploading = false
    var isGoingBack        = false
    var isWorking          = false

    //Data
    var imageData: Data?
    var videoData: Data?

    //Strings
    var challengeTitle:    String?
    var stepText = "🔴 Set title, prompt, point value\n🔴 Add media\n🔴 Set appearance date\n🔴 Add to tournaments"
    var uploadedMediaPath: String?

    //Other Declarations
    let mediaPicker = UIImagePickerController()

    var buildInstance: Build!
    var controllerReference: CreateController!
    var currentStep = Step.title
    var mediaLink: URL?
    var mediaType: Challenge.MediaType?
    var pointValue: Int?
    var stepAttributes: [NSAttributedString.Key: Any]!

    //==================================================//

    /* MARK: Enumerated Type Declarations */

    enum Step
    {
        case title
        case prompt
        case pointValue
        case media
        case appearanceDate
        case tournament
    }

    //==================================================//

    /* MARK: Initializer Function */

    func initializeController()
    {
        lastInitializedController = self
        buildInstance = Build(self)
    }

    //==================================================//

    /* MARK: Overridden Functions */

    override func viewDidLoad()
    {
        super.viewDidLoad()

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

        let navigationButtonAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 17)]

        backButton.setTitleTextAttributes(navigationButtonAttributes, for: .normal)
        backButton.setTitleTextAttributes(navigationButtonAttributes, for: .highlighted)
        backButton.setTitleTextAttributes(navigationButtonAttributes, for: .disabled)

        nextButton.setTitleTextAttributes(navigationButtonAttributes, for: .normal)
        nextButton.setTitleTextAttributes(navigationButtonAttributes, for: .highlighted)
        nextButton.setTitleTextAttributes(navigationButtonAttributes, for: .disabled)

        mediaTextField.delegate = self
        largeTextField.delegate = self

        tableView.backgroundColor = .black

        forwardToTitle()

        mediaPicker.sourceType = .photoLibrary
        mediaPicker.delegate   = self
        mediaPicker.mediaTypes = ["public.image", "public.movie"]

        datePicker.minimumDate = Date()
        datePicker.maximumDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        initializeController()

        currentFile = #file
        buildInfoController?.view.isHidden = true
    }

    override func prepare(for _: UIStoryboardSegue, sender _: Any?)
    {}

    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)

        lastInitializedController = controllerReference
        buildInstance = Build(controllerReference)
        buildInfoController?.view.isHidden = !preReleaseApplication
    }

    //==================================================//

    /* MARK: Interface Builder Actions */

    @IBAction func backButton(_: Any)
    {
        switch currentStep
        {
        case .pointValue:
            goBack()
            forwardToPrompt()
        case .media:
            goBack()
            forwardToPointValue()
        case .appearanceDate:
            goBack()
            forwardToMedia()
        case .tournament:
            goBack()
            forwardToDate()
        default:
            goBack()
            forwardToTitle()
        }
    }

    @IBAction func cancelButton(_: Any)
    {
        confirmCancellation()
    }

    @IBAction func mediaSegmentedControl(_: Any)
    {
        if mediaSegmentedControl.selectedSegmentIndex == 0
        {
            UIView.animate(withDuration: 0.2) {
                self.mediaTextField.alpha = 1
                self.uploadButton.alpha = 0
            } completion: { _ in self.mediaTextField.becomeFirstResponder() }
        }
        else if mediaSegmentedControl.selectedSegmentIndex == 1
        {
            UIView.animate(withDuration: 0.2) {
                self.mediaTextField.alpha = 0
                self.uploadButton.alpha = 1
            } completion: { _ in findAndResignFirstResponder() }
        }
        else
        {
            UIView.animate(withDuration: 0.2) {
                self.mediaTextField.alpha = 0
                self.uploadButton.alpha = 0
            } completion: { _ in findAndResignFirstResponder() }
        }
    }

    @IBAction func nextButton(_: Any)
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
            if mediaSegmentedControl.selectedSegmentIndex == 2
            {
                forwardToDate()
            }
            else
            {
                findAndResignFirstResponder()

                showProgressHUD(text: "Analysing media...", delay: nil)

                var linkString = mediaTextField.text!

                if mediaSegmentedControl.selectedSegmentIndex == 1
                {
                    guard let link = mediaLink else
                    { report("No media link!", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]); return }

                    linkString = link.absoluteString
                }

                MediaAnalyser().analyseMedia(linkString: linkString) { analysisResult in
                    hideHUD(delay: 0.5)

                    DispatchQueue.main.async {
                        switch analysisResult
                        {
                        case .autoPlayVideo:
                            self.mediaType = .autoPlayVideo

                            self.forwardToDate()
                        case .gif:
                            self.mediaType = .gif
                            self.mediaLink = self.mediaLink == nil ? URL(string: self.mediaTextField.text!)! : self.mediaLink

                            self.forwardToDate()
                        case .image:
                            self.mediaType = .staticImage
                            self.mediaLink = self.mediaLink == nil ? URL(string: self.mediaTextField.text!)! : self.mediaLink

                            self.forwardToDate()
                        case .linkedVideo:
                            self.mediaType = .linkedVideo
                            self.mediaLink = MediaAnalyser().convertToEmbedded(linkString: self.mediaTextField.text!) ?? URL(string: self.mediaTextField.text!)!

                            self.forwardToDate()
                        case .tikTokVideo:
                            self.mediaType = .tikTokVideo
                            self.mediaLink = self.mediaLink == nil ? URL(string: self.mediaTextField.text!)! : self.mediaLink

                            self.forwardToDate()
                        case .other:
                            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(750)) {
                                AlertKit().successAlertController(withTitle:             "Error",
                                                                  withMessage:           "The provided link was to an unsupported media type.\n\nTry uploading the media instead.",
                                                                  withCancelButtonTitle:  "OK",
                                                                  withAlternateSelectors: nil,
                                                                  preferredActionIndex:   nil)

                                self.mediaTextField.becomeFirstResponder()

                                self.nextButton.isEnabled = true
                                self.backButton.isEnabled = true
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
        case .appearanceDate:
            forwardToTournament()
        default:
            if !selectedTournaments.isEmpty
            {
                forwardToFinish()
            }
            else
            {
                AlertKit().errorAlertController(title:                       "No Tournament Selected",
                                                message:                     "You must select at least one tournament to add this challenge to.",
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
        }
    }

    @IBAction func uploadButton(_: Any)
    {
        mediaPicker.allowsEditing = false
        mediaPicker.sourceType = .photoLibrary

        present(mediaPicker, animated: true)
    }

    //==================================================//

    /* MARK: Other Functions */

    func animateTableViewAppearance()
    {
        UIView.animate(withDuration: 0.2) {
            self.datePicker.alpha = 0
            self.stepTitleLabel.alpha = 0
        } completion: { _ in
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.reloadData()

            self.tableView.layer.cornerRadius = 10

            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.tableView.alpha = 0.6
            } completion: { _ in
                self.nextButton.isEnabled = true
                self.backButton.isEnabled = true
            }
        }

        currentStep = .tournament
        nextButton.title = "Finish"
    }

    func confirmCancellation()
    {
        AlertKit().confirmationAlertController(title:                   "Are You Sure?",
                                               message:                 "Would you really like to cancel?",
                                               cancelConfirmTitles:     ["cancel": "No", "confirm": "Yes"],
                                               confirmationDestructive: true,
                                               confirmationPreferred:   false,
                                               networkDepedent:         false) { didConfirm in
            if didConfirm!
            {
                if let path = self.uploadedMediaPath
                {
                    let mediaReference = dataStorage.child(path)

                    mediaReference.delete { returnedError in
                        if let error = returnedError
                        {
                            report(error.localizedDescription, errorCode: (error as NSError).code, isFatal: true, metadata: [#file, #function, #line])
                        }

                        self.navigationController?.dismiss(animated: true, completion: nil)
                    }
                }
                else { self.navigationController?.dismiss(animated: true, completion: nil) }
            }
        }
    }

    func createChallenge()
    {
        var media: (URL, String?, Challenge.MediaType)?

        if let type = mediaType, let link = mediaLink
        {
            media = (link, uploadedMediaPath, type)
        }

        ChallengeSerializer().createChallenge(title: challengeTitle!, prompt: promptTextView.text!, datePosted: datePicker.date.comparator, pointValue: pointValue!, media: media) { returnedIdentifier, errorDescriptor in
            if let identifier = returnedIdentifier
            {
                TournamentSerializer().addChallenges([identifier], toTournaments: self.selectedTournaments) { errorDescriptor in
                    if let error = errorDescriptor
                    {
                        AlertKit().errorAlertController(title: "Succeeded with Errors",
                                                        message: "The challenge was created successfully, but it couldn't be added to the selected tournaments. File a report for more information.",
                                                        dismissButtonTitle: nil,
                                                        additionalSelectors: nil,
                                                        preferredAdditionalSelector: nil,
                                                        canFileReport: true,
                                                        extraInfo: error,
                                                        metadata: [#file, #function, #line],
                                                        networkDependent: true) {
                            self.navigationController?.dismiss(animated: true, completion: nil)
                        }
                    }
                    else
                    {
                        flashSuccessHUD(text: "Successfully created challenge.", for: 1, delay: nil) {
                            self.navigationController?.dismiss(animated: true, completion: nil)
                        }
                    }
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
                                                networkDependent: true) {
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }
            }
        }
    }

    func forwardToTitle()
    {
        largeTextField.keyboardType = .default
        largeTextField.placeholder = "Enter a title"
        largeTextField.text = challengeTitle ?? nil

        if isGoingBack
        {
            stepProgress(forwardDirection: false)
            isGoingBack = false
        }

        stepText = "🟡 Set title, prompt, point value\n🔴 Add media\n🔴 Set appearance date\n🔴 Add to tournaments"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })

        UIView.animate(withDuration: 0.2) {
            self.largeTextField.alpha = 1
        } completion: { _ in
            self.largeTextField.becomeFirstResponder()

            self.nextButton.isEnabled = true
        }

        currentStep = .title
    }

    func forwardToPrompt()
    {
        stepTitleLabel.text = "CHALLENGE PROMPT:"
        findAndResignFirstResponder()

        stepProgress(forwardDirection: !isGoingBack)
        isGoingBack = false

        UIView.animate(withDuration: 0.2) {
            self.largeTextField.alpha = 0
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.stepTitleLabel.alpha = 1
                self.promptTextView.alpha = 1
            } completion: { _ in
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

        stepProgress(forwardDirection: !isGoingBack)
        isGoingBack = false

        stepText = "🟡 Set title, prompt, point value\n🔴 Add media\n🔴 Set appearance date\n🔴 Add to tournaments"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })

        UIView.animate(withDuration: 0.2) {
            self.promptTextView.alpha = 0
            self.stepTitleLabel.alpha = 0
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.largeTextField.alpha = 1
            } completion: { _ in
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

        stepTitleLabel.text          = "ADD MEDIA:"
        stepTitleLabel.textAlignment = .left

        findAndResignFirstResponder()

        stepProgress(forwardDirection: !isGoingBack)
        isGoingBack = false

        stepText = "🟢 Set title, prompt, point value\n🟡 Add media\n🔴 Set appearance date\n🔴 Add to tournaments"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })

        UIView.animate(withDuration: 0.2) {
            self.largeTextField.alpha = 0
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.stepTitleLabel.alpha = 1
                self.mediaSegmentedControl.alpha = 1
            } completion: { _ in
                self.mediaSegmentedControl(self.mediaSegmentedControl!)

                self.nextButton.isEnabled = true
                self.backButton.isEnabled = true
            }
        }

        currentStep = .media
        nextButton.title = "Next"
    }

    func forwardToDate()
    {
        findAndResignFirstResponder()

        stepProgress(forwardDirection: !isGoingBack)
        isGoingBack = false

        stepText = "🟢 Set title, prompt, point value\n🟢 Add media\n🟡 Set appearance date\n🔴 Add to tournaments"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })

        UIView.animate(withDuration: 0.2) {
            self.mediaSegmentedControl.alpha = 0
            self.mediaTextField.alpha = 0
            self.stepTitleLabel.alpha = 0
            self.uploadButton.alpha = 0
        } completion: { _ in
            self.stepTitleLabel.text = "SELECT APPEARANCE DATE:"
            self.stepTitleLabel.textAlignment = .left

            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.stepTitleLabel.alpha = 1
                self.datePicker.alpha = 1
            }  completion: { _ in
                self.nextButton.isEnabled = true
                self.backButton.isEnabled = true
            }
        }

        currentStep = .appearanceDate
        nextButton.title = "Next"
    }

    func forwardToTournament()
    {
        findAndResignFirstResponder()

        stepProgress(forwardDirection: !isGoingBack)
        isGoingBack = false

        stepText = "🟢 Set title, prompt, point value\n🟢 Add media\n🟢 Set appearance date\n🟡 Add to tournaments"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })

        if tournamentArray != nil
        {
            animateTableViewAppearance()
        }
        else
        {
            TournamentSerializer().getAllTournaments { returnedTournaments, errorDescriptor in
                if let tournaments = returnedTournaments
                {
                    self.tournamentArray = tournaments.sorted(by: { $0.name < $1.name })

                    self.animateTableViewAppearance()
                }
                else if let error = errorDescriptor
                {
                    report(error, errorCode: nil, isFatal: true, metadata: [#file, #function, #line])
                }
            }
        }
    }

    func forwardToFinish()
    {
        nextButton.isEnabled   = false
        backButton.isEnabled   = false
        cancelButton.isEnabled = false

        findAndResignFirstResponder()
        stepProgress(forwardDirection: true)

        stepText = "🟢 Set title, prompt, point value\n🟢 Add media\n🟢 Set appearance date\n🟢 Add to tournaments"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })

        UIView.animate(withDuration: 0.2) { self.tableView.alpha = 0 } completion: { _ in
            self.stepTitleLabel.text = "WORKING..."
            self.stepTitleLabel.textAlignment = .center

            self.isWorking = true

            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.stepTitleLabel.alpha = 1
                self.activityIndicator.alpha = 1
            } completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2500)) { self.createChallenge() }
            }
        }
    }

    func goBack()
    {
        isGoingBack = true
        isWorking = false

        nextButton.isEnabled = false
        backButton.isEnabled = false

        findAndResignFirstResponder()

        if currentStep != .prompt && currentStep != .pointValue && currentStep != .media
        {
            stepProgress(forwardDirection: false)
        }

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
        UIView.animate(withDuration: 0.2) { self.progressView.setProgress(self.progressView.progress + (forwardDirection ? 0.1666666667 : -0.1666666667), animated: true) }
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

//==================================================//

/* MARK: Extensions */

/**/

/* MARK: UIAdaptivePresentationControllerDelegate */
extension NewChallengeController: UIAdaptivePresentationControllerDelegate
{
    func presentationControllerDidAttemptToDismiss(_: UIPresentationController)
    {
        if !isWorking
        {
            confirmCancellation()
        }
    }

    func presentationControllerShouldDismiss(_: UIPresentationController) -> Bool
    {
        return false
    }
}

//--------------------------------------------------//

/* MARK: UIImagePickerControllerDelegate */
extension NewChallengeController: UIImagePickerControllerDelegate
{
    func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
    {
        if !currentlyUploading
        {
            currentlyUploading = true

            if let imageURL = info[.imageURL] as? URL
            {
                var imageExtension: String?

                if imageURL.absoluteString.lowercased().hasSuffix("gif")
                {
                    imageExtension = "gif"
                }
                else if imageURL.absoluteString.lowercased().hasSuffix("heic")
                {
                    imageExtension = "heic"
                }
                else if imageURL.absoluteString.lowercased().hasSuffix("jpeg")
                {
                    imageExtension = "jpeg"
                }
                else if imageURL.absoluteString.lowercased().hasSuffix("jpg")
                {
                    imageExtension = "jpg"
                }
                else if imageURL.absoluteString.lowercased().hasSuffix("png")
                {
                    imageExtension = "png"
                }
                else
                {
                    dismiss(animated: true) {
                        self.currentlyUploading = false

                        AlertKit().errorAlertController(title: "Unsupported Media", message: "The selected media was of an unsupported type. Please select another piece of media to upload.", dismissButtonTitle: "OK", additionalSelectors: nil, preferredAdditionalSelector: nil, canFileReport: true, extraInfo: nil, metadata: [#file, #function, #line], networkDependent: false)
                    }
                }

                guard let `extension` = imageExtension else
                { return }

                do {
                    imageData = try Data(contentsOf: URL(fileURLWithPath: imageURL.path), options: .mappedIfSafe)

                    dismiss(animated: true) {
                        self.currentlyUploading = false

                        guard let imageData = self.imageData else
                        { report("Image data was not set!", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]); return }

                        showProgressHUD(text: "Uploading image...", delay: nil)

                        GenericSerializer().upload(image: true, withData: imageData, extension: `extension`) { returnedMetadata, errorDescriptor in
                            if let metadata = returnedMetadata
                            {
                                self.mediaLink = metadata.link
                                self.uploadedMediaPath = metadata.path

                                DispatchQueue.main.async {
                                    flashSuccessHUD(text: nil, for: 1.5, delay: 0.5) {}

                                    UIView.animate(withDuration: 0.2) {
                                        self.uploadButton.setImage(nil, for: .normal)
                                        self.uploadButton.setTitle("Tap to Replace", for: .normal)
                                    }
                                }
                            }
                            else
                            {
                                hideHUD(delay: 0.5)

                                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
                                    report(errorDescriptor!, errorCode: nil, isFatal: true, metadata: [#file, #function, #line])
                                }
                            }
                        }
                    }
                } catch {
                    dismiss(animated: true) {
                        self.currentlyUploading = false

                        report(error.localizedDescription, errorCode: (error as NSError).code, isFatal: true, metadata: [#file, #function, #line])
                    }
                }
            }
            else if let videoURL = info[.mediaURL] as? URL
            {
                var videoExtension: String?

                if videoURL.absoluteString.lowercased().hasSuffix("mp4")
                {
                    videoExtension = "mp4"
                }
                else if videoURL.absoluteString.lowercased().hasSuffix("mov")
                {
                    videoExtension = "mov"
                }
                else
                {
                    dismiss(animated: true) {
                        self.currentlyUploading = false

                        AlertKit().errorAlertController(title: "Unsupported Media", message: "The selected media was of an unsupported type. Please select another piece of media to upload.", dismissButtonTitle: "OK", additionalSelectors: nil, preferredAdditionalSelector: nil, canFileReport: true, extraInfo: nil, metadata: [#file, #function, #line], networkDependent: false)
                    }
                }

                guard let `extension` = videoExtension else
                { return }

                do {
                    videoData = try Data(contentsOf: URL(fileURLWithPath: videoURL.path), options: .mappedIfSafe)

                    dismiss(animated: true) {
                        self.currentlyUploading = false

                        guard let videoData = self.videoData else
                        { report("Video data was not set!", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]); return }

                        showProgressHUD(text: "Uploading video...", delay: nil)

                        GenericSerializer().upload(image: false, withData: videoData, extension: `extension`) { returnedMetadata, errorDescriptor in
                            if let metadata = returnedMetadata
                            {
                                self.mediaLink = metadata.link
                                self.uploadedMediaPath = metadata.path

                                DispatchQueue.main.async {
                                    flashSuccessHUD(text: nil, for: 1.5, delay: 0.5) {}

                                    UIView.animate(withDuration: 0.2) {
                                        self.uploadButton.setImage(nil, for: .normal)
                                        self.uploadButton.setTitle("Tap to Replace", for: .normal)
                                    }
                                }
                            }
                            else
                            {
                                hideHUD(delay: 0.5)

                                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
                                    report(errorDescriptor!, errorCode: nil, isFatal: true, metadata: [#file, #function, #line])
                                }
                            }
                        }
                    }
                } catch {
                    dismiss(animated: true) {
                        self.currentlyUploading = false

                        report(error.localizedDescription, errorCode: (error as NSError).code, isFatal: true, metadata: [#file, #function, #line])
                    }
                }
            }
        }
    }
}

//--------------------------------------------------//

/* MARK: UITableViewDataSource, UITableViewDelegate */
extension NewChallengeController: UITableViewDataSource, UITableViewDelegate
{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let currentCell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell") as! SelectionCell

        currentCell.titleLabel.text = tournamentArray![indexPath.row].name
        currentCell.subtitleLabel.text = "\(tournamentArray![indexPath.row].teamIdentifiers.count) teams"

        if selectedTournaments.contains(tournamentArray![indexPath.row].associatedIdentifier)
        {
            currentCell.radioButton.isSelected = true
        }

        currentCell.selectionStyle = .none

        return currentCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let currentCell = tableView.cellForRow(at: indexPath) as? SelectionCell
        {
            if currentCell.radioButton.isSelected,
               let index = selectedTournaments.firstIndex(of: tournamentArray![indexPath.row].associatedIdentifier)
            {
                selectedTournaments.remove(at: index)
            }
            else if !currentCell.radioButton.isSelected
            {
                selectedTournaments.append(tournamentArray![indexPath.row].associatedIdentifier)
            }

            currentCell.radioButton.isSelected = !currentCell.radioButton.isSelected
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int
    {
        return tournamentArray!.count
    }
}

//--------------------------------------------------//

/* MARK: UITextFieldDelegate */
extension NewChallengeController: UITextFieldDelegate
{
    func textFieldShouldReturn(_: UITextField) -> Bool
    {
        nextButton(nextButton!)
        return true
    }
}
