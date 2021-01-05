//
//  ViewChallengesController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 31/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

/* Third-party Frameworks */
import FirebaseAuth

class ViewChallengesController: UIViewController, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    //ShadowButtons
    @IBOutlet var doneButton: ShadowButton!
    @IBOutlet var cancelButton: ShadowButton!

    //Other Elements
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var textView: UITextView!
    @IBOutlet var titleLabel: UILabel!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    let mediaPicker = UIImagePickerController()

    var buildInstance: Build!
    var currentlyUploading = false
    var selectedIndexPath: IndexPath!
    var challengeArray = [Challenge]()

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

        cancelButton.initializeLayer(animateTouches:     true,
                                     backgroundColor:   UIColor(hex: 0xE95A53),
                                     customBorderFrame:  nil,
                                     customCornerRadius: nil,
                                     shadowColor:       UIColor(hex: 0xD5443B).cgColor)

        doneButton.initializeLayer(animateTouches:     true,
                                   backgroundColor:   UIColor(hex: 0x60C129),
                                   customBorderFrame:  nil,
                                   customCornerRadius: nil,
                                   shadowColor:       UIColor(hex: 0x3B9A1B).cgColor)

        mediaPicker.sourceType = .photoLibrary
        mediaPicker.delegate   = self
        mediaPicker.mediaTypes = ["public.image", "public.movie"]

        tableView.backgroundColor = .black
        tableView.alpha = 0

        textView.layer.borderWidth   = 2
        textView.layer.cornerRadius  = 10
        textView.layer.borderColor   = UIColor(hex: 0xE1E0E1).cgColor
        textView.clipsToBounds       = true
        textView.layer.masksToBounds = true

        reloadData()
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        initializeController()

        currentFile = #file
        buildInfoController?.view.isHidden = !preReleaseApplication

        buildInfoController?.customYOffset = 0
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        roundCorners(forViews: [tableView], withCornerType: 0)
    }

    override func prepare(for _: UIStoryboardSegue, sender _: Any?)
    {}

    //==================================================//

    /* MARK: Interface Builder Actions */

    @IBAction func backButton(_: Any)
    {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func cancelButton(_: Any)
    {
        textView.resignFirstResponder()

        UIView.transition(with: titleLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.titleLabel.text = "All Challenges"
        })

        UIView.animate(withDuration: 0.2) {
            self.textView.alpha = 0
            self.doneButton.alpha = 0
            self.cancelButton.alpha = 0
        } completion: { _ in
            UIView.animate(withDuration: 0.2) { self.tableView.alpha = 0.6 }
        }
    }

    @IBAction func doneButton(_: Any)
    {
        textView.resignFirstResponder()

        if textView.text == challengeArray[selectedIndexPath.row].prompt
        {
            cancelButton(cancelButton!)
        }
        else if textView.text!.lowercasedTrimmingWhitespace != ""
        {
            showProgressHUD(text: "Updating prompt...", delay: nil)

            challengeArray[selectedIndexPath.row].updatePrompt(textView.text!) { errorDescriptor in
                if let error = errorDescriptor
                {
                    hideHUD(delay: 1) {
                        AlertKit().errorAlertController(title:                       nil,
                                                        message:                     error,
                                                        dismissButtonTitle:          nil,
                                                        additionalSelectors:         nil,
                                                        preferredAdditionalSelector: nil,
                                                        canFileReport:               true,
                                                        extraInfo:                   error,
                                                        metadata:                    [#file, #function, #line],
                                                        networkDependent:            true) {
                            self.cancelButton(self.cancelButton!)
                        }
                    }
                }
                else
                {
                    UIView.transition(with: self.titleLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
                        self.titleLabel.text = "All Challenges"
                    })

                    UIView.animate(withDuration: 0.2) {
                        self.textView.alpha = 0
                        self.doneButton.alpha = 0
                        self.cancelButton.alpha = 0
                    } completion: { _ in self.showSuccessAndReload() }
                }
            }
        }
        else
        {
            AlertKit().errorAlertController(title:                       "Nothing Entered",
                                            message:                     "No text was entered. Please try again.",
                                            dismissButtonTitle:          "OK",
                                            additionalSelectors:         nil,
                                            preferredAdditionalSelector: nil,
                                            canFileReport:               false,
                                            extraInfo:                   nil,
                                            metadata:                    [#file, #function, #line],
                                            networkDependent:            false) {
                self.textView.becomeFirstResponder()
            }
        }
    }

    //==================================================//

    /* MARK: Action Sheet Functions */

    func deleteChallengeAction()
    {
        AlertKit().confirmationAlertController(title:                   "Deleting \(challengeArray[selectedIndexPath.row].title!.capitalized)",
                                               message:                 "If this challenge has already been completed by some users, their total accrued points will decrease.\n\nPlease confirm you would like to delete this challenge.",
                                               cancelConfirmTitles:     ["confirm": "Delete Challenge"],
                                               confirmationDestructive: true,
                                               confirmationPreferred:   false,
                                               networkDepedent:         true) { didConfirm in
            if let confirmed = didConfirm
            {
                if confirmed
                {
                    showProgressHUD(text: "Deleting challenge...", delay: nil)

                    ChallengeSerializer().deleteChallenge(self.challengeArray[self.selectedIndexPath.row].associatedIdentifier) { errorDescriptor in
                        if let error = errorDescriptor
                        {
                            hideHUD(delay: 0.5) { self.errorAlert(title: "Failed to Delete Challenge", message: error) }
                        }
                        else { self.showSuccessAndReload() }
                    }
                }
                else { self.reSelectRow() }
            }
        }
    }

    func editMediaAction()
    {
        AlertKit().optionAlertController(title:                "Editing \(challengeArray[selectedIndexPath.row].title!)",
                                         message:              "Choose the method of upload for this media.",
                                         cancelButtonTitle:    nil,
                                         additionalButtons:    [("Web Link", false), ("Direct Upload", false)],
                                         preferredActionIndex: nil,
                                         networkDependent:     true) { selectedIndex in
            if let index = selectedIndex
            {
                if index == 0
                {
                    self.webLinkMediaAlert()
                }
                else if index == 1
                {
                    self.mediaPicker.allowsEditing = false
                    self.mediaPicker.sourceType = .photoLibrary

                    self.present(self.mediaPicker, animated: true)
                }
                else if index == -1
                {
                    self.reSelectRow()
                }
            }
        }
    }

    @objc func editPointValueAction()
    {
        let textFieldAttributes: [AlertKit.AlertControllerTextFieldAttribute: Any] =
            [.editingMode:         UITextField.ViewMode.whileEditing,
             .keyboardType:        UIKeyboardType.numberPad,
             .placeholderText:     String(challengeArray[selectedIndexPath.row].pointValue),
             .sampleText:          String(challengeArray[selectedIndexPath.row].pointValue),
             .textAlignment:       NSTextAlignment.center]

        AlertKit().textAlertController(title:                "Editing \(challengeArray[selectedIndexPath.row].title!)",
                                       message:              "Enter a new point value for this challenge.",
                                       cancelButtonTitle:    nil,
                                       additionalButtons:    [("Done", false)],
                                       preferredActionIndex: 0,
                                       textFieldAttributes:  textFieldAttributes,
                                       networkDependent:     true) { returnedString, selectedIndex in
            if let index = selectedIndex
            {
                if index == 0
                {
                    if let string = returnedString, string.lowercasedTrimmingWhitespace != ""
                    {
                        if let pointValue = Int(string)
                        {
                            if pointValue != self.challengeArray[self.selectedIndexPath.row].pointValue
                            {
                                showProgressHUD(text: "Updating point value...", delay: nil)

                                self.challengeArray[self.selectedIndexPath.row].updatePointValue(pointValue) { errorDescriptor in
                                    if let error = errorDescriptor
                                    {
                                        hideHUD(delay: 0.5) { self.errorAlert(title: "Failed to Update Challenge", message: error) }
                                    }
                                    else { self.showSuccessAndReload() }
                                }
                            }
                            else { self.sameInputAlert(#selector(self.editPointValueAction)) }
                        }
                        else
                        {
                            AlertKit().errorAlertController(title:                       "Invalid Point Value",
                                                            message:                     "Be sure to enter only numbers and that they do not exceed the integer ceiling.",
                                                            dismissButtonTitle:          "Cancel",
                                                            additionalSelectors:         ["Try Again": #selector(ViewChallengesController.editPointValueAction)],
                                                            preferredAdditionalSelector: 0,
                                                            canFileReport:               false,
                                                            extraInfo:                   nil,
                                                            metadata:                    [#file, #function, #line],
                                                            networkDependent:            false)
                        }
                    }
                    else { self.noTextAlert(#selector(self.editPointValueAction)) }
                }
                else if index == -1
                {
                    self.reSelectRow()
                }
            }
        }
    }

    @objc func editPromptAction()
    {
        textView.text = challengeArray[selectedIndexPath.row].prompt!

        UIView.transition(with: titleLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.titleLabel.text = self.challengeArray[self.selectedIndexPath.row].title!
        })

        UIView.animate(withDuration: 0.2) {
            self.tableView.alpha = 0
            self.textView.alpha = 1
            self.doneButton.alpha = 1
            self.cancelButton.alpha = 1
        } completion: { _ in self.textView.becomeFirstResponder() }
    }

    @objc func editTitleAction()
    {
        let textFieldAttributes: [AlertKit.AlertControllerTextFieldAttribute: Any] =
            [.editingMode:         UITextField.ViewMode.whileEditing,
             .placeholderText:     challengeArray[selectedIndexPath.row].title!,
             .sampleText:          challengeArray[selectedIndexPath.row].title!,
             .textAlignment:       NSTextAlignment.center]

        AlertKit().textAlertController(title:                "Editing \(challengeArray[selectedIndexPath.row].title!)",
                                       message:              "Enter a new title for this challenge.",
                                       cancelButtonTitle:    nil,
                                       additionalButtons:    [("Done", false)],
                                       preferredActionIndex: 0,
                                       textFieldAttributes:  textFieldAttributes,
                                       networkDependent:     true) { returnedString, selectedIndex in
            if let index = selectedIndex
            {
                if index == 0
                {
                    if let string = returnedString, string.lowercasedTrimmingWhitespace != ""
                    {
                        if string != self.challengeArray[self.selectedIndexPath.row].title
                        {
                            showProgressHUD(text: "Updating title...", delay: nil)

                            self.challengeArray[self.selectedIndexPath.row].updateTitle(string) { errorDescriptor in
                                if let error = errorDescriptor
                                {
                                    hideHUD(delay: 0.5) { self.errorAlert(title: "Failed to Update Title", message: error) }
                                }
                                else { self.showSuccessAndReload() }
                            }
                        }
                        else { self.sameInputAlert(#selector(self.editTitleAction)) }
                    }
                    else { self.noTextAlert(#selector(self.editTitleAction)) }
                }
                else if index == -1
                {
                    self.reSelectRow()
                }
            }
        }
    }

    func removeMediaAction()
    {
        AlertKit().optionAlertController(title:                "Editing \(challengeArray[selectedIndexPath.row].title!)",
                                         message:              "Are you sure you would like to remove the media associated with this challenge?",
                                         cancelButtonTitle:    nil,
                                         additionalButtons:    [("Remove Media", true)],
                                         preferredActionIndex: nil,
                                         networkDependent:     true) { selectedIndex in
            if let index = selectedIndex
            {
                if index == 0
                {
                    showProgressHUD(text: "Removing media...", delay: nil)

                    self.challengeArray[self.selectedIndexPath.row].removeMedia { errorDescriptor in
                        if let error = errorDescriptor
                        {
                            hideHUD(delay: 0.5) { self.errorAlert(title: "Failed to Remove Media", message: error) }
                        }
                        else { self.showSuccessAndReload() }
                    }
                }
                else if index == -1
                {
                    self.reSelectRow()
                }
            }
        }
    }

    //==================================================//

    /* MARK: Status Functions */

    func errorAlert(title: String, message: String)
    {
        AlertKit().errorAlertController(title:                       title,
                                        message:                     message,
                                        dismissButtonTitle:          nil,
                                        additionalSelectors:         nil,
                                        preferredAdditionalSelector: nil,
                                        canFileReport:               true,
                                        extraInfo:                   message,
                                        metadata:                    [#file, #function, #line],
                                        networkDependent:            true)
    }

    func noTextAlert(_ selector: Selector)
    {
        AlertKit().errorAlertController(title:                       "Nothing Entered",
                                        message:                     "No text was entered. Please try again.",
                                        dismissButtonTitle:          "Cancel",
                                        additionalSelectors:         ["Try Again": selector],
                                        preferredAdditionalSelector: 0,
                                        canFileReport:               false,
                                        extraInfo:                   nil,
                                        metadata:                    [#file, #function, #line],
                                        networkDependent:            false)
    }

    func sameInputAlert(_ selector: Selector)
    {
        AlertKit().errorAlertController(title:                       "Same Value",
                                        message:                     "The value entered was unchanged.",
                                        dismissButtonTitle:          "Cancel",
                                        additionalSelectors:         ["Try Again": selector],
                                        preferredAdditionalSelector: 0,
                                        canFileReport:               false,
                                        extraInfo:                   nil,
                                        metadata:                    [#file, #function, #line],
                                        networkDependent:            false)
    }

    func showSuccessAndReload()
    {
        hideHUD(delay: 0.5) {
            flashSuccessHUD(text: nil, for: 1.2, delay: 0) {
                self.activityIndicator.alpha = 1
                self.reloadData()
            }
        }
    }

    //==================================================//

    /* MARK: Other Functions */

    func formatDateString(_ string: String) -> String
    {
        if string.contains(":")
        {
            return "Today at \(string)"
        }
        else if string.hasPrefix("mon") || string.hasPrefix("tue") || string.hasPrefix("wed") || string.hasPrefix("thu") || string.hasPrefix("fri") || string.hasPrefix("sat") || string.hasPrefix("sun")
        {
            return string.capitalized
        }

        return string
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }

    @objc func reloadData()
    {
        tableView.isUserInteractionEnabled = false

        UIView.animate(withDuration: 0.2) { self.tableView.alpha = 0 } completion: { _ in
            ChallengeSerializer().getAllChallenges { returnedChallenges, errorDescriptor in
                if let challenges = returnedChallenges
                {
                    self.challengeArray = challenges

                    self.tableView.dataSource = self
                    self.tableView.delegate = self

                    self.tableView.reloadData()

                    UIView.animate(withDuration: 0.2, delay: 1) {
                        self.activityIndicator.alpha = 0
                        self.tableView.alpha = 0.6
                    } completion: { _ in self.tableView.isUserInteractionEnabled = true }
                }
                else { report(errorDescriptor!, errorCode: nil, isFatal: true, metadata: [#file, #function, #line]) }
            }
        }
    }

    func reSelectRow()
    {
        tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
        tableView.delegate?.tableView!(tableView, didSelectRowAt: selectedIndexPath)
    }

    func updateChallengeMedia(_ media: (link: URL, path: String?, type: Challenge.MediaType))
    {
        challengeArray[selectedIndexPath.row].updateMedia(media) { errorDescriptor in
            if let error = errorDescriptor
            {
                self.errorAlert(title: "Failed to Update Media", message: error)
            }
            else
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { self.showSuccessAndReload() }
            }
        }
    }

    @objc func webLinkMediaAlert()
    {
        let textFieldAttributes: [AlertKit.AlertControllerTextFieldAttribute: Any] =
            [.capitalisationType: UITextAutocapitalizationType.none,
             .correctionType:      UITextAutocorrectionType.no,
             .editingMode:         UITextField.ViewMode.whileEditing,
             .keyboardType:        UIKeyboardType.URL,
             .placeholderText:     "",
             .sampleText:          "https://"]

        AlertKit().textAlertController(title:                "Editing \(challengeArray[selectedIndexPath.row].title!)",
                                       message:              "Enter the link to the media you would like to upload.",
                                       cancelButtonTitle:    nil,
                                       additionalButtons:    [("Done", false)],
                                       preferredActionIndex: 0,
                                       textFieldAttributes:  textFieldAttributes,
                                       networkDependent:     true) { returnedString, selectedIndex in
            if let index = selectedIndex
            {
                if index == 0
                {
                    if let string = returnedString, string.lowercasedTrimmingWhitespace != ""
                    {
                        showProgressHUD(text: "Updating media...", delay: nil)

                        MediaAnalyser().analyseMedia(linkString: string) { analysisResult in
                            DispatchQueue.main.async {
                                switch analysisResult
                                {
                                case .autoPlayVideo:
                                    self.updateChallengeMedia((URL(string: string)!, nil, .autoPlayVideo))
                                case .gif:
                                    self.updateChallengeMedia((URL(string: string)!, nil, .gif))
                                case .image:
                                    self.updateChallengeMedia((URL(string: string)!, nil, .staticImage))
                                case .linkedVideo:
                                    self.updateChallengeMedia((MediaAnalyser().convertToEmbedded(linkString: string) ?? URL(string: string)!, nil, .linkedVideo))
                                case .other:
                                    hideHUD(delay: 0.5) {
                                        AlertKit().errorAlertController(title:                       "Error",
                                                                        message:                     "The provided link was to an unsupported media type.\n\nTry uploading the media instead.",
                                                                        dismissButtonTitle:          "Cancel",
                                                                        additionalSelectors:         ["Try Again": #selector(self.webLinkMediaAlert)],
                                                                        preferredAdditionalSelector: nil,
                                                                        canFileReport:               false,
                                                                        extraInfo:                   nil,
                                                                        metadata:                    [#file, #function, #line],
                                                                        networkDependent:            false)
                                    }
                                case .error:
                                    hideHUD(delay: 0.5) {
                                        AlertKit().errorAlertController(title:                       "Invalid Link",
                                                                        message:                     "The provided link was not valid.",
                                                                        dismissButtonTitle:          "Cancel",
                                                                        additionalSelectors:         ["Try Again": #selector(self.webLinkMediaAlert)],
                                                                        preferredAdditionalSelector: nil,
                                                                        canFileReport:               false,
                                                                        extraInfo:                   nil,
                                                                        metadata:                    [#file, #function, #line],
                                                                        networkDependent:            false)
                                    }
                                }
                            }
                        }
                    }
                    else { self.noTextAlert(#selector(self.webLinkMediaAlert)) }
                }
                else if index == -1
                {
                    self.reSelectRow()
                }
            }
        }
    }
}

//==================================================//

/* MARK: Extensions */

/**/

/* MARK: UIImagePickerControllerDelegate */
extension ViewChallengesController: UIImagePickerControllerDelegate
{
    func imagePickerControllerDidCancel(_: UIImagePickerController)
    {
        dismiss(animated: true) { self.reSelectRow() }
    }

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

                        AlertKit().errorAlertController(title:                       "Unsupported Media",
                                                        message:                     "The selected media was of an unsupported type. Please select another piece of media to upload.",
                                                        dismissButtonTitle:          "OK",
                                                        additionalSelectors:         nil,
                                                        preferredAdditionalSelector: nil,
                                                        canFileReport:               true,
                                                        extraInfo:                   nil,
                                                        metadata:                    [#file, #function, #line],
                                                        networkDependent:            false)
                    }
                }

                guard let `extension` = imageExtension else
                { return }

                do {
                    let imageData = try Data(contentsOf: URL(fileURLWithPath: imageURL.path), options: .mappedIfSafe)

                    dismiss(animated: true) {
                        self.currentlyUploading = false

                        showProgressHUD(text: "Uploading image...", delay: nil)

                        GenericSerializer().upload(image: true, withData: imageData, extension: `extension`) { returnedMetadata, errorDescriptor in
                            if let metadata = returnedMetadata
                            {
                                let mediaType: Challenge.MediaType = imageExtension == "gif" ? .gif : .staticImage

                                self.challengeArray[self.selectedIndexPath.row].updateMedia((metadata.link, metadata.path, mediaType)) { errorDescriptor in
                                    if let error = errorDescriptor
                                    {
                                        self.errorAlert(title: "Failed to Upload Media", message: error)
                                    }
                                    else
                                    {
                                        DispatchQueue.main.async { self.showSuccessAndReload() }
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

                        AlertKit().errorAlertController(title:                       "Unsupported Media",
                                                        message:                     "The selected media was of an unsupported type. Please select another piece of media to upload.",
                                                        dismissButtonTitle:          "OK",
                                                        additionalSelectors:         nil,
                                                        preferredAdditionalSelector: nil,
                                                        canFileReport:               true,
                                                        extraInfo:                   nil,
                                                        metadata:                    [#file, #function, #line],
                                                        networkDependent:            false)
                    }
                }

                guard let `extension` = videoExtension else
                { return }

                do {
                    let videoData = try Data(contentsOf: URL(fileURLWithPath: videoURL.path), options: .mappedIfSafe)

                    dismiss(animated: true) {
                        self.currentlyUploading = false

                        showProgressHUD(text: "Uploading video...", delay: nil)

                        GenericSerializer().upload(image: false, withData: videoData, extension: `extension`) { returnedMetadata, errorDescriptor in
                            if let metadata = returnedMetadata
                            {
                                self.challengeArray[self.selectedIndexPath.row].updateMedia((metadata.link, metadata.path, .autoPlayVideo)) { errorDescriptor in
                                    if let error = errorDescriptor
                                    {
                                        self.errorAlert(title: "Failed to Upload Media", message: error)
                                    }
                                    else
                                    {
                                        DispatchQueue.main.async { self.showSuccessAndReload() }
                                    }
                                }
                            }
                            else
                            {
                                hideHUD(delay: 0.5)

                                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) { report(errorDescriptor!, errorCode: nil, isFatal: true, metadata: [#file, #function, #line]) }
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
extension ViewChallengesController: UITableViewDataSource, UITableViewDelegate
{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let currentCell = tableView.dequeueReusableCell(withIdentifier: "ChallengeCell") as! SubtitleCell

        currentCell.titleLabel.text = challengeArray[indexPath.row].title
        currentCell.subtitleLabel.text = "posted \(formatDateString(challengeArray[indexPath.row].datePosted.formattedString().lowercased()).lowercased())"

        return currentCell
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        if let currentCell = tableView.cellForRow(at: indexPath) as? SubtitleCell
        {
            currentCell.titleLabel.textColor = .white
            currentCell.subtitleLabel.textColor = .white
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        selectedIndexPath = indexPath

        if let currentCell = tableView.cellForRow(at: indexPath) as? SubtitleCell
        {
            currentCell.titleLabel.textColor = .black
            currentCell.subtitleLabel.textColor = .black
        }

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.alignment = .justified

        let titleAttributes: [NSAttributedString.Key: Any] = [.baselineOffset: NSNumber(value: -3),
                                                              .font: UIFont(name: "SFUIText-Semibold", size: 20)!,
                                                              .foregroundColor: UIColor.darkGray]

        let regularMessageAttributes: [NSAttributedString.Key: Any] = [.baselineOffset: NSNumber(value: 0),
                                                                       .font: UIFont(name: "SFUIText-Regular", size: 14)!,
                                                                       .foregroundColor: UIColor.darkGray,
                                                                       .paragraphStyle: paragraphStyle]

        let boldedMessageAttributes: [NSAttributedString.Key: Any] = [.baselineOffset: NSNumber(value: 0),
                                                                      .font: UIFont(name: "SFUIText-Semibold", size: 14)!,
                                                                      .foregroundColor: UIColor.darkGray,
                                                                      .paragraphStyle: paragraphStyle]

        actionSheet.setValue(NSMutableAttributedString(string: challengeArray[indexPath.row].title, attributes: titleAttributes), forKey: "attributedTitle")

        let message = "Point Value: \(String(challengeArray[indexPath.row].pointValue))\n\nPrompt:\n\(challengeArray[indexPath.row].prompt!)\n\nDate Posted: \(formatDateString(challengeArray[indexPath.row].datePosted.formattedString().lowercased()))\n\nAssociated Media: \(challengeArray[indexPath.row].media?.type.userFacingString() ?? "None")"

        let boldedRange = ["Point Value:",
                           "Prompt:",
                           "Date Posted:",
                           "Associated Media:"]

        actionSheet.setValue(attributedString(message, mainAttributes: regularMessageAttributes, alternateAttributes: boldedMessageAttributes, alternateAttributeRange: boldedRange), forKey: "attributedMessage")

        let editTitleAction = UIAlertAction(title: "Edit Title", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.editTitleAction()
        }

        let editPromptAction = UIAlertAction(title: "Edit Prompt", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.editPromptAction()
        }

        let editPointValueAction = UIAlertAction(title: "Edit Point Value", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.editPointValueAction()
        }

        let mediaTitle = challengeArray[indexPath.row].media == nil ? "Add Media" : "Edit Media"

        let editMediaAction = UIAlertAction(title: mediaTitle, style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.editMediaAction()
        }

        let removeMediaAction = UIAlertAction(title: "Remove Media", style: .destructive) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.removeMediaAction()
        }

        let deleteChallengeAction = UIAlertAction(title: "Delete Challenge", style: .destructive) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.deleteChallengeAction()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)
        }

        actionSheet.addAction(editTitleAction)
        actionSheet.addAction(editPromptAction)
        actionSheet.addAction(editPointValueAction)
        actionSheet.addAction(editMediaAction)

        if challengeArray[indexPath.row].media != nil
        {
            actionSheet.addAction(removeMediaAction)
        }

        actionSheet.addAction(deleteChallengeAction)
        actionSheet.addAction(cancelAction)

        present(actionSheet, animated: true, completion: nil)
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int
    {
        return challengeArray.count
    }
}
