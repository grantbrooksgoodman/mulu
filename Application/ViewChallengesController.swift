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
    @IBOutlet var datePickerDoneButton: ShadowButton!
    @IBOutlet var doneButton:   ShadowButton!
    @IBOutlet var cancelButton: ShadowButton!

    //Other Elements
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var textView: UITextView!
    @IBOutlet var titleLabel: UILabel!

    @IBOutlet var datePicker: UIDatePicker!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    let mediaPicker = UIImagePickerController()
    let mediumDateFormatter = DateFormatter()

    var buildInstance: Build!
    var currentlyUploading = false
    var selectedIndexPath: IndexPath!
    var challengeArray = [Challenge]()

    var filteredOtherPosts = [Challenge]()
    var postedThisWeek = [Challenge]()
    var todaysPosts = [Challenge]()
    var upcomingThisWeek = [Challenge]()

    var referenceArray = [Challenge]()

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

        datePickerDoneButton.initializeLayer(animateTouches:     true,
                                             backgroundColor:   UIColor(hex: 0x60C129),
                                             customBorderFrame:  nil,
                                             customCornerRadius: nil,
                                             shadowColor:       UIColor(hex: 0x3B9A1B).cgColor)

        doneButton.initializeLayer(animateTouches:     true,
                                   backgroundColor:   UIColor(hex: 0x60C129),
                                   customBorderFrame:  nil,
                                   customCornerRadius: nil,
                                   shadowColor:       UIColor(hex: 0x3B9A1B).cgColor)

        mediaPicker.sourceType = .photoLibrary
        mediaPicker.delegate   = self
        mediaPicker.mediaTypes = ["public.image", "public.movie"]

        mediumDateFormatter.dateStyle = .medium

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

    @IBAction func datePickerDoneButton(_: Any)
    {
        let selectedChallenge = referenceArray[selectedIndexPath.row]

        if selectedChallenge.datePosted.comparator == datePicker.date.comparator
        {
            flashSuccessHUD(text: "No changes made.", for: 1.2, delay: 0) {
                UIView.transition(with: self.titleLabel, duration: 0.35, options: .transitionCrossDissolve, animations: { self.titleLabel.text = "All Challenges" })

                UIView.animate(withDuration: 0.2) {
                    self.activityIndicator.alpha = 1
                    self.datePicker.alpha = 0
                    self.datePickerDoneButton.alpha = 0
                } completion: { _ in self.reloadData() }
            }
        }
        else
        {
            //showProgressHUD(text: "Setting appearance date...", delay: nil)

            UIView.animate(withDuration: 0.2) {
                self.activityIndicator.alpha = 1
                self.datePicker.alpha = 0
                self.datePickerDoneButton.alpha = 0
            }

            selectedChallenge.updateAppearanceDate(datePicker.date.comparator) { errorDescriptor in
                if let error = errorDescriptor
                {
                    //hideHUD(delay: 1) {
                    self.errorAlert(title: "Couldn't Set Appearance Date", message: error)
                    //}
                }
                else
                {
                    flashSuccessHUD(text: nil, for: 1, delay: 0.2) {
                        self.reloadData()
                    }
                }
            }
        }
    }

    @IBAction func doneButton(_: Any)
    {
        textView.resignFirstResponder()

        if textView.text == referenceArray[selectedIndexPath.row].prompt
        {
            cancelButton(cancelButton!)
        }
        else if textView.text!.lowercasedTrimmingWhitespace != ""
        {
            showProgressHUD(text: "Updating prompt...", delay: nil)

            referenceArray[selectedIndexPath.row].updatePrompt(textView.text!) { errorDescriptor in
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
        AlertKit().confirmationAlertController(title:                   "Deleting \(referenceArray[selectedIndexPath.row].title!.capitalized)",
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

                    ChallengeSerializer().deleteChallenge(self.referenceArray[self.selectedIndexPath.row].associatedIdentifier) { errorDescriptor in
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

    func editAppearanceDateAction()
    {
        datePicker.date = referenceArray[selectedIndexPath.row].datePosted
        datePicker.maximumDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())

        //WARN FOR DATE BEFORE TODAY

        //showProgressHUD(text: "Loading data...", delay: nil)

        UIView.animate(withDuration: 0.2) {
            self.activityIndicator.alpha = 1
            self.tableView.alpha = 0
        }

        hasBeenCompleted(referenceArray[selectedIndexPath.row]) { completed, errorDescriptor in
            if let completed = completed
            {
                if completed
                {
                    AlertKit().errorAlertController(title:                       "Cannot Edit Appearance Date",
                                                    message:                     "There are users who have already completed this challenge.\n\nEditing its appearance date at this point would cause the server data to become out of sync.",
                                                    dismissButtonTitle:          nil,
                                                    additionalSelectors:         nil,
                                                    preferredAdditionalSelector: nil,
                                                    canFileReport:               true,
                                                    extraInfo:                   "There are users who have already completed this challenge.\n\nEditing its appearance date at this point would cause the server data to become out of sync.",
                                                    metadata:                    [#file, #function, #line],
                                                    networkDependent:            true) {
                        UIView.animate(withDuration: 0.2) {
                            self.activityIndicator.alpha = 0
                            self.tableView.alpha = 0.6
                        } completion: { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) { self.reSelectRow() }
                        }
                    }
                }
                else
                {
                    UIView.transition(with: self.titleLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
                        self.titleLabel.text = self.referenceArray[self.selectedIndexPath.row].title!
                    })

                    UIView.animate(withDuration: 0.2) {
                        self.activityIndicator.alpha = 0
                        self.datePicker.alpha = 1
                        self.datePickerDoneButton.alpha = 1
                    } /*completion: { _ in }*/
                }
            }
            else { self.errorAlert(title: "Cannot Edit Appearance Date", message: errorDescriptor!) }
        }
    }

    @objc func editAppearanceDateAlert()
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"

        let selectedChallenge = referenceArray[selectedIndexPath.row]

        let textFieldAttributes: [AlertKit.AlertControllerTextFieldAttribute: Any] =
            [.capitalisationType:  UITextAutocapitalizationType.none,
             .correctionType:      UITextAutocorrectionType.no,
             .editingMode:         UITextField.ViewMode.whileEditing,
             .keyboardType:        UIKeyboardType.asciiCapableNumberPad,
             .placeholderText:     "",
             .sampleText:          dateFormatter.string(from: selectedChallenge.datePosted),
             .textAlignment:       NSTextAlignment.center]

        AlertKit().textAlertController(title: "Editing \(selectedChallenge.title!)",
                                       message: "Enter a new appearance date for \(selectedChallenge.title!) in the 'day.month.year' format.",
                                       cancelButtonTitle: nil,
                                       additionalButtons: [("Done", false)],
                                       preferredActionIndex: 0,
                                       textFieldAttributes: textFieldAttributes,
                                       networkDependent: true) { returnedString, selectedIndex in
            if let index = selectedIndex
            {
                if index == 0
                {
                    if let dateString = returnedString,
                       let newDate = dateFormatter.date(from: dateString)
                    {
                        if selectedChallenge.datePosted.comparator == newDate.comparator
                        {
                            hideHUD(delay: 0.5) {
                                flashSuccessHUD(text: "No changes made.", for: 1.2, delay: 0) {
                                    self.activityIndicator.alpha = 1
                                    self.reloadData()
                                }
                            }
                        }
                        else
                        {
                            //showProgressHUD(text: "Setting appearance date...", delay: nil)

                            selectedChallenge.updateAppearanceDate(newDate.comparator) { errorDescriptor in
                                if let error = errorDescriptor
                                {
                                    hideHUD(delay: 1) {
                                        self.errorAlert(title: "Couldn't Set Appearance Date", message: error)
                                    }
                                }
                                else { self.showSuccessAndReload() }
                            }
                        }
                    }
                    else
                    {
                        AlertKit().errorAlertController(title:                       "Invalid Date",
                                                        message:                     "The provided date was invalid. Please follow the 'day.month.year' format.",
                                                        dismissButtonTitle:          "Cancel",
                                                        additionalSelectors:         ["Try Again": #selector(ViewChallengesController.editAppearanceDateAlert)],
                                                        preferredAdditionalSelector: 0,
                                                        canFileReport:               false,
                                                        extraInfo:                   nil,
                                                        metadata:                    [#file, #function, #line],
                                                        networkDependent:            false)
                    }
                }
                else if index == -1
                {
                    self.reSelectRow()
                }
            }
        }
    }

    func editMediaAction()
    {
        AlertKit().optionAlertController(title:                "Editing \(referenceArray[selectedIndexPath.row].title!)",
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
             .placeholderText:     String(referenceArray[selectedIndexPath.row].pointValue),
             .sampleText:          String(referenceArray[selectedIndexPath.row].pointValue),
             .textAlignment:       NSTextAlignment.center]

        AlertKit().textAlertController(title:                "Editing \(referenceArray[selectedIndexPath.row].title!)",
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
                        if let pointValue = Int(string),
                           pointValue > 0
                        {
                            if pointValue != self.referenceArray[self.selectedIndexPath.row].pointValue
                            {
                                showProgressHUD(text: "Updating point value...", delay: nil)

                                self.referenceArray[self.selectedIndexPath.row].updatePointValue(pointValue) { errorDescriptor in
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
                                                            message:                     "Be sure to enter only (positive) numbers and that they do not exceed the integer ceiling.",
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
        textView.text = referenceArray[selectedIndexPath.row].prompt!

        UIView.transition(with: titleLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.titleLabel.text = self.referenceArray[self.selectedIndexPath.row].title!
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
             .placeholderText:     referenceArray[selectedIndexPath.row].title!,
             .sampleText:          referenceArray[selectedIndexPath.row].title!,
             .textAlignment:       NSTextAlignment.center]

        AlertKit().textAlertController(title:                "Editing \(referenceArray[selectedIndexPath.row].title!)",
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
                        if string != self.referenceArray[self.selectedIndexPath.row].title
                        {
                            showProgressHUD(text: "Updating title...", delay: nil)

                            self.referenceArray[self.selectedIndexPath.row].updateTitle(string) { errorDescriptor in
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
        AlertKit().optionAlertController(title:                "Editing \(referenceArray[selectedIndexPath.row].title!)",
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

                    self.referenceArray[self.selectedIndexPath.row].removeMedia { errorDescriptor in
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

    @objc func webLinkMediaAlert()
    {
        let textFieldAttributes: [AlertKit.AlertControllerTextFieldAttribute: Any] =
            [.capitalisationType: UITextAutocapitalizationType.none,
             .correctionType:      UITextAutocorrectionType.no,
             .editingMode:         UITextField.ViewMode.whileEditing,
             .keyboardType:        UIKeyboardType.URL,
             .placeholderText:     "",
             .sampleText:          "https://"]

        AlertKit().textAlertController(title:                "Editing \(referenceArray[selectedIndexPath.row].title!)",
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

    func hasBeenCompleted(_ challenge: Challenge, completion: @escaping (_ completed: Bool?, _ errorDescriptor: String?) -> Void)
    {
        TeamSerializer().getAllTeams { returnedTeams, errorDescriptor in
            if let error = errorDescriptor
            {
                completion(nil, error)
            }
            else if let teams = returnedTeams
            {
                var hasBeenCompleted = false

                for team in teams
                {
                    if let completedChallenges = team.completedChallenges,
                       completedChallenges.challengeIdentifiers().contains(challenge.associatedIdentifier)
                    {
                        hasBeenCompleted = true; break
                    }
                }

                completion(hasBeenCompleted, nil)
            }
        }
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
                    self.challengeArray = challenges.sorted(by: { $0.datePosted > $1.datePosted })

                    self.filteredOtherPosts = self.challengeArray.filter { abs($0.datePosted.comparator.days(from: Date().comparator)) > 7 && $0.datePosted.comparator != Date().comparator }

                    self.postedThisWeek = self.challengeArray.filter { abs($0.datePosted.comparator.days(from: Date().comparator)) <= 7 && $0.datePosted.comparator < Date().comparator }

                    self.todaysPosts = self.challengeArray.filter { $0.datePosted.comparator == Date().comparator }

                    self.upcomingThisWeek = self.challengeArray.filter { abs($0.datePosted.comparator.days(from: Date().comparator)) <= 7 && $0.datePosted.comparator > Date().comparator }.sorted(by: { $0.datePosted < $1.datePosted })

                    if let index = self.challengeArray.firstIndex(where: { $0.datePosted.comparator == Date().comparator })
                    {
                        self.challengeArray.swapAt(index, 0)
                    }

                    self.tableView.dataSource = self
                    self.tableView.delegate = self

                    self.tableView.reloadData()

                    self.tableView.layer.cornerRadius = 10

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
        referenceArray[selectedIndexPath.row].updateMedia(media) { errorDescriptor in
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

                                self.referenceArray[self.selectedIndexPath.row].updateMedia((metadata.link, metadata.path, mediaType)) { errorDescriptor in
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
                                self.referenceArray[self.selectedIndexPath.row].updateMedia((metadata.link, metadata.path, .autoPlayVideo)) { errorDescriptor in
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
    func numberOfSections(in _: UITableView) -> Int
    {
        //today, upcoming this week, posted this week, all time

        //        var sectionCount = 1
        //
        //        for array in [postedThisWeek, todaysPosts, upcomingThisWeek]
        //        {
        //            if array.count > 0
        //            {
        //                sectionCount += 1
        //            }
        //        }
        //
        return 4
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        switch section
        {
        case 0:
            return "Today"
        case 1:
            return "Next 7 Days"
        case 2:
            return "Past 7 Days"
        default:
            return "Other"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let currentCell = tableView.dequeueReusableCell(withIdentifier: "ChallengeCell") as! SubtitleCell

        //this is gonna cause array problems

        switch indexPath.section
        {
        case 0:
            referenceArray = todaysPosts
        case 1:
            referenceArray = upcomingThisWeek
        case 2:
            referenceArray = postedThisWeek
        default:
            referenceArray = filteredOtherPosts
        }

        currentCell.titleLabel.text = referenceArray[indexPath.row].title

        let challengePostDate = referenceArray[indexPath.row].datePosted!
        let mediumDateString = mediumDateFormatter.string(from: challengePostDate)

        if challengePostDate.comparator > Date().comparator
        {
            if challengePostDate.comparator.days(from: Date().comparator) == 1
            {
                currentCell.subtitleLabel.text = "will be posted tomorrow"
            }
            else
            {
                let dateString = indexPath.section == 3 ? mediumDateFormatter.string(from: challengePostDate) : challengePostDate.formattedString()

                currentCell.subtitleLabel.text = "will be posted on \(dateString)"
            }
        }
        else if challengePostDate.comparator == Date().comparator
        {
            currentCell.subtitleLabel.text = "posted today"
        }
        else { currentCell.subtitleLabel.text = "posted on \(mediumDateString)" }

        currentCell.titleLabel.text = referenceArray[indexPath.row].title

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

        switch indexPath.section
        {
        case 0:
            referenceArray = todaysPosts
        case 1:
            referenceArray = upcomingThisWeek
        case 2:
            referenceArray = postedThisWeek
        default:
            referenceArray = filteredOtherPosts
        }

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

        actionSheet.setValue(NSMutableAttributedString(string: referenceArray[indexPath.row].title, attributes: titleAttributes), forKey: "attributedTitle")

        let message = "Appearance Date: \(mediumDateFormatter.string(from: referenceArray[indexPath.row].datePosted))\n\nAssociated Media: \(referenceArray[indexPath.row].media?.type.userFacingString() ?? "None")\n\nPoint Value: \(String(referenceArray[indexPath.row].pointValue))\n\nPrompt:\n\(referenceArray[indexPath.row].prompt!)"

        let boldedRange = ["Appearance Date:",
                           "Associated Media:",
                           "Point Value:",
                           "Prompt:"]

        actionSheet.setValue(attributedString(message, mainAttributes: regularMessageAttributes, alternateAttributes: boldedMessageAttributes, alternateAttributeRange: boldedRange), forKey: "attributedMessage")

        let editAppearanceDateAction = UIAlertAction(title: "Edit Appearance Date", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.editAppearanceDateAction()
        }

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

        let mediaTitle = referenceArray[indexPath.row].media == nil ? "Add Media" : "Edit Media"

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

        actionSheet.addAction(editAppearanceDateAction)
        actionSheet.addAction(editTitleAction)
        actionSheet.addAction(editPromptAction)
        actionSheet.addAction(editPointValueAction)
        actionSheet.addAction(editMediaAction)

        if referenceArray[indexPath.row].media != nil
        {
            actionSheet.addAction(removeMediaAction)
        }

        actionSheet.addAction(deleteChallengeAction)
        actionSheet.addAction(cancelAction)

        present(actionSheet, animated: true, completion: nil)
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch section
        {
        case 0:
            return todaysPosts.count
        case 1:
            return upcomingThisWeek.count
        case 2:
            return postedThisWeek.count
        default:
            return filteredOtherPosts.count
        }
    }
}

extension Calendar {
    private var currentDate: Date { return Date() }

    func isDateInThisWeek(_ date: Date) -> Bool {
        return isDate(date, equalTo: currentDate, toGranularity: .weekOfYear)
    }

    func isDateInThisMonth(_ date: Date) -> Bool {
        return isDate(date, equalTo: currentDate, toGranularity: .month)
    }

    func isDateInNextWeek(_ date: Date) -> Bool {
        guard let nextWeek = self.date(byAdding: DateComponents(weekOfYear: 1), to: currentDate) else {
            return false
        }
        return isDate(date, equalTo: nextWeek, toGranularity: .weekOfYear)
    }

    func isDateInNextMonth(_ date: Date) -> Bool {
        guard let nextMonth = self.date(byAdding: DateComponents(month: 1), to: currentDate) else {
            return false
        }
        return isDate(date, equalTo: nextMonth, toGranularity: .month)
    }
}

extension Date {
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day!
    }
}
