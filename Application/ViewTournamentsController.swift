//
//  ViewTournamentsController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 13/01/2021.
//  Copyright © 2013-2021 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

class ViewTournamentsController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    //ShadowButtons
    @IBOutlet var announceCancelButton: ShadowButton!
    @IBOutlet var announceDoneButton:   ShadowButton!
    @IBOutlet var doneButton:           ShadowButton!

    //UILabels
    @IBOutlet var promptLabel: UILabel!
    @IBOutlet var titleLabel:  UILabel!

    //UITableViews
    @IBOutlet var selectionTableView:  UITableView!
    @IBOutlet var tournamentTableView: UITableView!

    //Other Elements
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var textView: UITextView!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    //Arrays
    var challengeArray     = [Challenge]()
    var selectedChallenges = [String]()
    var selectedTeams      = [String]()
    var teamArray          = [Team]()
    var tournamentArray    = [Tournament]()

    //Dictionaries
    var subtitleAttributes: [NSAttributedString.Key: Any]!
    var titleAttributes:    [NSAttributedString.Key: Any]!

    //Other Declarations
    let paragraphStyle = NSMutableParagraphStyle()

    var buildInstance: Build!
    var editingStartDate = true
    var previousAnnouncement: String!
    var selectedIndexPath: IndexPath!

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

        paragraphStyle.lineSpacing = 0
        paragraphStyle.alignment = .justified

        titleAttributes = [.baselineOffset: NSNumber(value: 0),
                           .font: UIFont(name: "SFUIText-Semibold", size: 14)!,
                           .foregroundColor: UIColor.darkGray,
                           .paragraphStyle: paragraphStyle]

        subtitleAttributes = [.baselineOffset: NSNumber(value: 0),
                              .font: UIFont(name: "SFUIText-Regular", size: 14)!,
                              .foregroundColor: UIColor.darkGray,
                              .paragraphStyle: paragraphStyle]

        announceCancelButton.initializeLayer(animateTouches:     true,
                                             backgroundColor:    UIColor(hex: 0xE95A53),
                                             customBorderFrame:  nil,
                                             customCornerRadius: nil,
                                             shadowColor:        UIColor(hex: 0xD5443B).cgColor)

        announceDoneButton.initializeLayer(animateTouches:     true,
                                           backgroundColor:    UIColor(hex: 0x60C129),
                                           customBorderFrame:  nil,
                                           customCornerRadius: nil,
                                           shadowColor:        UIColor(hex: 0x3B9A1B).cgColor)

        textView.delegate = self

        textView.layer.borderWidth   = 2
        textView.layer.cornerRadius  = 10
        textView.layer.borderColor   = UIColor(hex: 0xE1E0E1).cgColor
        textView.clipsToBounds       = true
        textView.layer.masksToBounds = true

        selectionTableView.alpha           = 0
        selectionTableView.backgroundColor = .black
        selectionTableView.tag             = aTagFor("selectionTableView")

        tournamentTableView.alpha           = 0
        tournamentTableView.backgroundColor = .black
        tournamentTableView.tag             = aTagFor("tournamentTableView")

        reloadData()
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        initializeController()

        currentFile = #file
        buildInfoController?.view.isHidden = !preReleaseApplication

        buildInfoController?.customYOffset = 0

        doneButton.initializeLayer(animateTouches:     true,
                                   backgroundColor:    UIColor(hex: 0x60C129),
                                   customBorderFrame:  nil,
                                   customCornerRadius: nil,
                                   shadowColor:        UIColor(hex: 0x3B9A1B).cgColor)
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
    }

    override func prepare(for _: UIStoryboardSegue, sender _: Any?)
    {}

    //==================================================//

    /* MARK: Interface Builder Actions */

    @IBAction func announceCancelButton(_: Any)
    {
        textView.resignFirstResponder()

        UIView.transition(with: titleLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.titleLabel.text = "All Tournaments"
        })

        UIView.animate(withDuration: 0.2) {
            self.textView.alpha = 0
            self.announceDoneButton.alpha = 0
            self.announceCancelButton.alpha = 0
        } completion: { _ in
            UIView.animate(withDuration: 0.2) { self.tournamentTableView.alpha = 0.6 }
        }
    }

    @IBAction func announceDoneButton(_: Any)
    {
        guard textView.text! != previousAnnouncement else
        {
            textView.resignFirstResponder()

            flashSuccessHUD(text: nil, for: 1.5, delay: 0.5) { self.announceCancelButton(self.announceCancelButton!) }; return
        }

        if textView.text!.lowercasedTrimmingWhitespace == ""
        {
            AlertKit().confirmationAlertController(title: "Clear Announcement", message: "You have not entered any text.\n\nWould you like to remove this tournament's announcement?", cancelConfirmTitles: [:], confirmationDestructive: false, confirmationPreferred: true, networkDepedent: true) { didConfirm in
                if let confirmed = didConfirm,
                   confirmed
                {
                    showProgressHUD(text: "Clearing announcement...", delay: nil)

                    self.setAnnouncement("")
                }
                else { self.textView.becomeFirstResponder() }
            }
        }
        else
        {
            showProgressHUD(text: "Updating announcement...", delay: nil)

            setAnnouncement(textView.text!)
        }
    }

    @IBAction func backButton(_: Any)
    {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func doneButton(_: Any)
    {
        guard !challengeArray.isEmpty else
        {
            if selectedTeams.isEmpty
            {
                AlertKit().confirmationAlertController(title:                   "Nothing Selected",
                                                       message:                 "You have not selected any teams. Tournaments must be associated with at least one team. \n\nWould you like to cancel?",
                                                       cancelConfirmTitles:     ["cancel": "No", "confirm": "Yes, cancel"],
                                                       confirmationDestructive: true,
                                                       confirmationPreferred:   true,
                                                       networkDepedent:         false) { didConfirm in
                    if didConfirm!
                    {
                        self.hideSelectionTableView()
                    }
                }
            }
            else { addSelectedTeamsToTournament() }; return
        }

        addSelectedChallengesToTournament()
    }

    //==================================================//

    /* MARK: Action Sheet Functions */

    func addRemoveChallengesAction()
    {
        deselectAllCells()

        selectionTableView.tag = aTagFor("challengeTableView")
        tournamentTableView.isUserInteractionEnabled = false

        UIView.transition(with: titleLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.titleLabel.text = self.tournamentArray[self.selectedIndexPath.row].name!
        })

        UIView.animate(withDuration: 0.2) {
            self.activityIndicator.alpha = 1
            self.tournamentTableView.alpha = 0
        } completion: { _ in
            self.setChallengeArray { errorDescriptor in
                if let error = errorDescriptor
                {
                    AlertKit().errorAlertController(title:                       "Couldn't Get Challenges",
                                                    message:                     error,
                                                    dismissButtonTitle:          nil,
                                                    additionalSelectors:         nil,
                                                    preferredAdditionalSelector: nil,
                                                    canFileReport:               true,
                                                    extraInfo:                   error,
                                                    metadata:                    [#file, #function, #line],
                                                    networkDependent:            true) {
                        self.reloadData()
                    }
                }
                else
                {
                    self.promptLabel.text = "SELECT CHALLENGES TO ASSOCIATE WITH THIS TOURNAMENT:"

                    self.selectionTableView.dataSource = self
                    self.selectionTableView.delegate = self

                    self.selectionTableView.reloadData()

                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                        self.selectionTableView.scrollToRow(at: IndexPath(row: self.challengeArray.count - 1, section: 0), at: .bottom, animated: false)

                        self.finishSelectionTableViewSetup()
                    }
                }
            }
        }
    }

    func addRemoveTeamsAction()
    {
        deselectAllCells()

        selectionTableView.tag = aTagFor("teamTableView")
        tournamentTableView.isUserInteractionEnabled = false

        UIView.transition(with: titleLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.titleLabel.text = self.tournamentArray[self.selectedIndexPath.row].name!
        })

        UIView.animate(withDuration: 0.2) {
            self.activityIndicator.alpha = 1
            self.tournamentTableView.alpha = 0
        } completion: { _ in
            self.setTeamArray { errorDescriptor in
                if let error = errorDescriptor
                {
                    AlertKit().errorAlertController(title:                       "Couldn't Get Teams",
                                                    message:                     error,
                                                    dismissButtonTitle:          nil,
                                                    additionalSelectors:         nil,
                                                    preferredAdditionalSelector: nil,
                                                    canFileReport:               true,
                                                    extraInfo:                   error,
                                                    metadata:                    [#file, #function, #line],
                                                    networkDependent:            true) {
                        self.reloadData()
                    }
                }
                else
                {
                    self.promptLabel.text = "SELECT TEAMS FOR THIS TOURNAMENT:"

                    self.selectionTableView.dataSource = self
                    self.selectionTableView.delegate = self

                    self.selectionTableView.reloadData()

                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                        self.selectionTableView.scrollToRow(at: IndexPath(row: self.teamArray.count - 1, section: 0), at: .bottom, animated: false)

                        self.finishSelectionTableViewSetup()
                    }
                }
            }
        }
    }

    func deleteTournamentAction()
    {
        AlertKit().confirmationAlertController(title:                   "Are You Sure?",
                                               message:                 "Please confirm that you would like to delete \(tournamentArray[selectedIndexPath.row].name!).",
                                               cancelConfirmTitles:     ["confirm": "Delete Tournament"],
                                               confirmationDestructive: true,
                                               confirmationPreferred:   false,
                                               networkDepedent:         true) { didConfirm in
            if let confirmed = didConfirm
            {
                if confirmed
                {
                    showProgressHUD(text: "Deleting tournament...", delay: nil)

                    TournamentSerializer().deleteTournament(self.tournamentArray[self.selectedIndexPath.row].associatedIdentifier) { errorDescriptor in
                        if let error = errorDescriptor
                        {
                            hideHUD(delay: 0.5) { AlertKit().errorAlertController(title:                       nil,
                                                                                  message:                     error,
                                                                                  dismissButtonTitle:          nil,
                                                                                  additionalSelectors:         nil,
                                                                                  preferredAdditionalSelector: nil,
                                                                                  canFileReport:               true,
                                                                                  extraInfo:                   error,
                                                                                  metadata:                    [#file, #function, #line],
                                                                                  networkDependent:            true) }
                        }
                        else
                        {
                            hideHUD(delay: 0.5) {
                                AlertKit().optionAlertController(title:               "Operation Completed Successfully",
                                                                 message: "\(self.tournamentArray[self.selectedIndexPath.row].name!.capitalized) was successfully deleted.",
                                                                 cancelButtonTitle:    "OK",
                                                                 additionalButtons:    nil,
                                                                 preferredActionIndex: nil,
                                                                 networkDependent:     false) { selectedIndex in
                                    if let index = selectedIndex, index == -1
                                    {
                                        self.activityIndicator.alpha = 1
                                        self.reloadData()
                                    }
                                }
                            }
                        }
                    }
                }
                else { self.reSelectRow() }
            }
        }
    }

    @objc func editAnnouncementAction()
    {
        announceDoneButton.isEnabled = false
        previousAnnouncement = tournamentArray[selectedIndexPath.row].announcement ?? ""
        textView.text = previousAnnouncement

        UIView.transition(with: titleLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.titleLabel.text = self.tournamentArray[self.selectedIndexPath.row].name!
        })

        UIView.animate(withDuration: 0.2) {
            self.tournamentTableView.alpha = 0
            self.textView.alpha = 1
            self.announceDoneButton.alpha = 1
            self.announceCancelButton.alpha = 1
        } completion: { _ in self.textView.becomeFirstResponder() }
    }

    func editDateActionAlert()
    {
        AlertKit().optionAlertController(title: "Select Date",
                                         message: "Select the date you would like to edit.",
                                         cancelButtonTitle: nil,
                                         additionalButtons: [("Start Date", false), ("End Date", false)],
                                         preferredActionIndex: nil,
                                         networkDependent: true) { selectedIndex in
            if let index = selectedIndex
            {
                if index == 0
                {
                    guard self.tournamentArray[self.selectedIndexPath.row].startDate.comparator > Date().comparator else
                    {
                        AlertKit().optionAlertController(title: "Cannot Edit Start Date",
                                                         message: "This tournament has already started.",
                                                         cancelButtonTitle: nil,
                                                         additionalButtons: [("Try Again", false)],
                                                         preferredActionIndex: 0,
                                                         networkDependent: true) { selectedIndex in
                            if let index = selectedIndex
                            {
                                if index == 0
                                {
                                    self.editDateActionAlert()
                                }
                                else if index == -1
                                {
                                    self.reSelectRow()
                                }
                            }
                        }; return
                    }

                    self.editingStartDate = true
                    self.editDateAction()
                }
                else if index == 1
                {
                    self.editingStartDate = false
                    self.editDateAction()
                }
                else if index == -1
                {
                    self.reSelectRow()
                }
            }
        }
    }

    @objc func editDateAction()
    {
        //be sure start date hasn't already past
        //get start date as localised short date, e.g. DD-MM-YYYY

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"

        let selectedTournament = tournamentArray[selectedIndexPath.row]
        let dateReferenceString = editingStartDate ? "start" : "end"
        let sampleDateString = dateFormatter.string(from: editingStartDate ? selectedTournament.startDate : selectedTournament.endDate)

        let textFieldAttributes: [AlertKit.AlertControllerTextFieldAttribute: Any] =
            [.capitalisationType:  UITextAutocapitalizationType.none,
             .correctionType:      UITextAutocorrectionType.no,
             .editingMode:         UITextField.ViewMode.whileEditing,
             .keyboardType:        UIKeyboardType.numbersAndPunctuation,
             .placeholderText:     "",
             .sampleText:          sampleDateString,
             .textAlignment:       NSTextAlignment.center]

        AlertKit().textAlertController(title: "Editing \(dateReferenceString.capitalized) Date",
                                       message: "Enter a new \(dateReferenceString) date for \(selectedTournament.name!) in the DD.MM.YYYY format.",
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
                        let comparisonDate: Date! = self.editingStartDate ? selectedTournament.startDate : selectedTournament.endDate

                        if comparisonDate.comparator == newDate.comparator
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
                            showProgressHUD(text: "Setting \(dateReferenceString) date...", delay: nil)

                            selectedTournament.update(startDate: self.editingStartDate, to: newDate) { errorDescriptor in
                                if let error = errorDescriptor
                                {
                                    hideHUD(delay: 1) {
                                        self.errorAlert(title: "Couldn't Set \(dateReferenceString.capitalized) Date", message: error)
                                    }
                                }
                                else { self.showSuccessAndReload() }
                            }
                        }
                    }
                    else
                    {
                        AlertKit().errorAlertController(title:                       "Invalid Date",
                                                        message:                     "The provided date was invalid. Please follow the DD.MM.YYYY format.",
                                                        dismissButtonTitle:          "Cancel",
                                                        additionalSelectors:         ["Try Again": #selector(ViewTournamentsController.editDateAction)],
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

    func viewChallengesAction()
    {
        let actionSheet = UIAlertController(title: "\(tournamentArray[selectedIndexPath.row].name!) is associated with the following challenges:", message: nil, preferredStyle: .actionSheet)

        let messageString = NSAttributedString(string: generateChallengesString(), attributes: titleAttributes)

        actionSheet.setValue(messageString, forKey: "attributedMessage")

        let backAction = UIAlertAction(title: "Back", style: .default, handler: { _ in
            self.tournamentTableView.selectRow(at: self.selectedIndexPath, animated: true, scrollPosition: .none)
            self.tournamentTableView.delegate?.tableView!(self.tournamentTableView, didSelectRowAt: self.selectedIndexPath)
        })

        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)

        actionSheet.addAction(backAction)
        actionSheet.addAction(dismissAction)

        present(actionSheet, animated: true)
    }

    func viewRankingsAction()
    {
        hideHUD(delay: 1)

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let boldedString = "\(tournamentArray[selectedIndexPath.row].name!) information:\n\n\(generateTournamentStrings().tournamentsString)"

        let unboldedRange = generateTournamentStrings().pointStrings

        actionSheet.setValue(attributedString(boldedString, mainAttributes: titleAttributes, alternateAttributes: subtitleAttributes, alternateAttributeRange: unboldedRange), forKey: "attributedMessage")

        let backAction = UIAlertAction(title: "Back", style: .default, handler: { _ in
            self.tournamentTableView.selectRow(at: self.selectedIndexPath, animated: true, scrollPosition: .none)
            self.tournamentTableView.delegate?.tableView!(self.tournamentTableView, didSelectRowAt: self.selectedIndexPath)
        })

        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)

        actionSheet.addAction(backAction)
        actionSheet.addAction(dismissAction)

        present(actionSheet, animated: true)
    }

    //==================================================//

    /* MARK: Other Functions */

    func addSelectedChallengesToTournament()
    {
        if let associatedChallenges = tournamentArray[selectedIndexPath.row].associatedChallenges,
           associatedChallenges.identifiers().sorted() == selectedChallenges.sorted()
        {
            hideSelectionTableView()
        }
        else
        {
            showProgressHUD(text: "Setting associated challenges...", delay: nil)

            tournamentArray[selectedIndexPath.row].updateAssociatedChallenges(selectedChallenges) { errorDescriptor in
                if let error = errorDescriptor
                {
                    hideHUD(delay: 1) {
                        AlertKit().errorAlertController(title:                       "Couldn't Add Challenge\(self.selectedChallenges.count == 1 ? "" : "s")",
                                                        message:                     error,
                                                        dismissButtonTitle:          nil,
                                                        additionalSelectors:         nil,
                                                        preferredAdditionalSelector: nil,
                                                        canFileReport:               true,
                                                        extraInfo:                   error,
                                                        metadata:                    [#file, #function, #line],
                                                        networkDependent:            true) {
                            self.hideSelectionTableView()
                        }
                    }
                }
                else
                {
                    hideHUD(delay: 1) {
                        flashSuccessHUD(text: nil, for: 1.5, delay: 0) {
                            self.hideSelectionTableView()
                        }
                    }
                }
            }
        }
    }

    func addSelectedTeamsToTournament()
    {
        guard !selectedTeams.isEmpty else
        { report("Selected teams was not set!", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]); return }

        if tournamentArray[selectedIndexPath.row].teamIdentifiers.sorted() == selectedTeams.sorted()
        {
            hideSelectionTableView()
        }
        else
        {
            showProgressHUD(text: "Setting associated teams...", delay: nil)

            tournamentArray[selectedIndexPath.row].updateTeamIdentifiers(selectedTeams) { errorDescriptor in
                if let error = errorDescriptor
                {
                    hideHUD(delay: 1) {
                        AlertKit().errorAlertController(title:                       "Couldn't Set Teams",
                                                        message:                     error,
                                                        dismissButtonTitle:          nil,
                                                        additionalSelectors:         nil,
                                                        preferredAdditionalSelector: nil,
                                                        canFileReport:               true,
                                                        extraInfo:                   error,
                                                        metadata:                    [#file, #function, #line],
                                                        networkDependent:            true) {
                            self.hideSelectionTableView()
                        }
                    }
                }
                else
                {
                    hideHUD(delay: 1) {
                        flashSuccessHUD(text: nil, for: 1.5, delay: 0) {
                            self.hideSelectionTableView()
                        }
                    }
                }
            }
        }
    }

    func clearSelection()
    {
        challengeArray     = []
        teamArray          = []

        selectedChallenges = []
        selectedTeams      = []

        tournamentTableView.tag = aTagFor("tournamentTableView")
    }

    func deselectAllCells()
    {
        for cell in selectionTableView.visibleCells
        {
            if let cell = cell as? SelectionCell
            {
                cell.radioButton.isSelected = false
            }
        }
    }

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

    func finishSelectionTableViewSetup()
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
            self.selectionTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.selectionTableView.layer.cornerRadius = 10

                if self.selectionTableView.tag == aTagFor("challengeTableView")
                {
                    for challenge in self.selectedChallenges
                    {
                        if let index = self.challengeArray.firstIndex(where: { $0.associatedIdentifier == challenge }),
                           let cell = self.selectionTableView.cellForRow(at: IndexPath(row: index, section: 0)) as? SelectionCell
                        {
                            cell.radioButton.isSelected = true
                        }
                    }
                }
                else if self.selectionTableView.tag == aTagFor("teamTableView")
                {
                    for team in self.selectedTeams
                    {
                        if let index = self.teamArray.firstIndex(where: { $0.associatedIdentifier == team }),
                           let cell = self.selectionTableView.cellForRow(at: IndexPath(row: index, section: 0)) as? SelectionCell
                        {
                            cell.radioButton.isSelected = true
                        }
                    }
                }

                UIView.animate(withDuration: 0.2) {
                    self.activityIndicator.alpha  = 0
                    self.doneButton.alpha         = 1
                    self.promptLabel.alpha        = 1
                    self.selectionTableView.alpha = 0.6
                }
            }
        }
    }

    func generateChallengesString() -> String
    {
        var challengesString = ""

        let sortedChallenges = tournamentArray[selectedIndexPath.row].associatedChallenges!.sorted(by: { $0.title < $1.title })

        for challenge in sortedChallenges
        {
            if challengesString == ""
            {
                challengesString = "• \(challenge.title!)"
            }
            else { challengesString = "\(challengesString)\n• \(challenge.title!)" }
        }

        return challengesString
    }

    func generateTournamentStrings() -> (tournamentsString: String, pointStrings: [String])
    {
        var pointStrings = [String]()
        var tournamentsString = ""

        let selectedTournament = tournamentArray[selectedIndexPath.row]

        guard let teams = selectedTournament.DSTeams?.sorted(by: { $0.name < $1.name }) else
        {
            showProgressHUD(text: "Getting tournament information...", delay: nil)

            selectedTournament.deSerializeTeams { returnedTeams, errorDescriptor in
                if returnedTeams != nil
                {
                    hideHUD(delay: 1) {
                        self.viewRankingsAction()
                    }
                }
                else
                {
                    hideHUD(delay: 1) {
                        AlertKit().errorAlertController(title:                       "Couldn't Get Tournament Information",
                                                        message:                     errorDescriptor!,
                                                        dismissButtonTitle:          nil,
                                                        additionalSelectors:         nil,
                                                        preferredAdditionalSelector: nil,
                                                        canFileReport:               true,
                                                        extraInfo:                   errorDescriptor!,
                                                        metadata:                    [#file, #function, #line],
                                                        networkDependent:            true)
                    }
                }
            }; return ("NULL", [])
        }

        for team in teams.sorted(by: { $0.getTotalPoints() > $1.getTotalPoints() })
        {
            if tournamentsString == ""
            {
                tournamentsString = "1. \(team.name!), \(team.getTotalPoints()) pts."
                pointStrings.append("\(team.getTotalPoints()) pts.")
            }
            else
            {
                let components = tournamentsString.components(separatedBy: "\n")

                tournamentsString = "\(tournamentsString)\n\(components.isEmpty ? "2." : "\(components.count + 1).") \(team.name!), \(team.getTotalPoints()) pts."
                pointStrings.append("\(team.getTotalPoints()) pts.")
            }
        }

        return (tournamentsString, pointStrings)
    }

    func hideSelectionTableView()
    {
        clearSelection()

        UIView.animate(withDuration: 0.2) {
            self.activityIndicator.alpha  = 1
            self.doneButton.alpha         = 0
            self.promptLabel.alpha        = 0
            self.selectionTableView.alpha = 0
        } completion: { _ in
            self.reloadData()
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }

    @objc func reloadData()
    {
        tournamentTableView.isUserInteractionEnabled = false

        UIView.transition(with: titleLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.titleLabel.text = "All Tournaments"
        })

        UIView.animate(withDuration: 0.2) { self.tournamentTableView.alpha = 0 } completion: { _ in
            TournamentSerializer().getAllTournaments { returnedTournaments, errorDescriptor in
                if let tournaments = returnedTournaments
                {
                    self.tournamentArray = tournaments.sorted(by: { $0.name < $1.name })

                    for tournament in tournaments
                    {
                        tournament.setDSTeams()
                    }

                    self.tournamentTableView.dataSource = self
                    self.tournamentTableView.delegate = self

                    self.tournamentTableView.reloadData()

                    self.tournamentTableView.layer.cornerRadius = 10

                    UIView.animate(withDuration: 0.2, delay: 1) {
                        self.activityIndicator.alpha = 0
                        self.tournamentTableView.alpha = 0.6
                    } completion: { _ in self.tournamentTableView.isUserInteractionEnabled = true }
                }
                else { report(errorDescriptor!, errorCode: nil, isFatal: true, metadata: [#file, #function, #line]) }
            }
        }
    }

    func reSelectRow()
    {
        tournamentTableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
        tournamentTableView.delegate?.tableView!(tournamentTableView, didSelectRowAt: selectedIndexPath)
    }

    func setAnnouncement(_ announcement: String)
    {
        tournamentArray[selectedIndexPath.row].updateAnnouncement(announcement) { errorDescriptor in
            if let error = errorDescriptor
            {
                hideHUD(delay: 1) {
                    AlertKit().errorAlertController(title:                       "Couldn't Set Announcement",
                                                    message:                     error,
                                                    dismissButtonTitle:          nil,
                                                    additionalSelectors:         nil,
                                                    preferredAdditionalSelector: nil,
                                                    canFileReport:               true,
                                                    extraInfo:                   error,
                                                    metadata:                    [#file, #function, #line],
                                                    networkDependent:            true) {
                        self.announceCancelButton(self.announceCancelButton!)
                    }
                }
            }
            else
            {
                hideHUD(delay: 1) {
                    UIView.transition(with: self.titleLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
                        self.titleLabel.text = "All Tournaments"
                    })

                    UIView.animate(withDuration: 0.2) {
                        self.textView.alpha = 0
                        self.announceDoneButton.alpha = 0
                        self.announceCancelButton.alpha = 0
                    } completion: { _ in self.showSuccessAndReload() }
                }
            }
        }
    }

    func setChallengeArray(completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        clearSelection()

        ChallengeSerializer().getAllChallenges { returnedChallenges, errorDescriptor in
            if let challenges = returnedChallenges
            {
                if let associatedChallenges = self.tournamentArray[self.selectedIndexPath.row].associatedChallenges
                {
                    var filteredChallenges = [Challenge]()

                    for challenge in challenges
                    {
                        if associatedChallenges.contains(where: { $0.associatedIdentifier == challenge.associatedIdentifier })
                        {
                            filteredChallenges.append(challenge)
                        }
                    }

                    filteredChallenges.sort(by: { $0.title < $1.title })
                    self.selectedChallenges = filteredChallenges.identifiers()

                    var sortedUnselectedChallenges = [Challenge]()

                    for challenge in challenges
                    {
                        if !associatedChallenges.contains(where: { $0.associatedIdentifier == challenge.associatedIdentifier })
                        {
                            sortedUnselectedChallenges.append(challenge)
                        }
                    }

                    filteredChallenges.append(contentsOf: sortedUnselectedChallenges.sorted(by: { $0.title < $1.title }))

                    self.challengeArray = filteredChallenges
                    completion(nil)
                }
                else
                {
                    self.challengeArray = challenges
                    completion(nil)
                }
            }
            else { completion(errorDescriptor!) }
        }
    }

    func setTeamArray(completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        clearSelection()

        TeamSerializer().getAllTeams { returnedTeams, errorDescriptor in
            if let teams = returnedTeams
            {
                var filteredTeams = [Team]()

                for team in teams
                {
                    if let tournament = team.associatedTournament,
                       tournament.associatedIdentifier == self.tournamentArray[self.selectedIndexPath.row].associatedIdentifier
                    {
                        filteredTeams.append(team)
                    }
                }

                filteredTeams.sort(by: { $0.name < $1.name })
                self.selectedTeams = filteredTeams.identifiers()

                var sortedUnselectedTeams = [Team]()

                for team in teams
                {
                    if team.associatedTournament == nil
                    {
                        sortedUnselectedTeams.append(team)
                    }
                }

                filteredTeams.append(contentsOf: sortedUnselectedTeams.sorted(by: { $0.name < $1.name }))

                self.teamArray = filteredTeams
                completion(nil)
            }
            else { completion(errorDescriptor!) }
        }
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
}

//==================================================//

/* MARK: Extensions */

/**/

/* MARK: UITableViewDataSource, UITableViewDelegate */
extension ViewTournamentsController: UITableViewDataSource, UITableViewDelegate
{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard tableView.tag == aTagFor("challengeTableView") || tableView.tag == aTagFor("teamTableView") else
        {
            let tournamentCell = tableView.dequeueReusableCell(withIdentifier: "TournamentCell") as! SubtitleCell

            tournamentCell.titleLabel.text = "\(tournamentArray[indexPath.row].name!)"
            tournamentCell.subtitleLabel.text = "\(tournamentArray[indexPath.row].teamIdentifiers.count) participants"

            return tournamentCell
        }

        let selectionCell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell") as! SelectionCell

        guard !challengeArray.isEmpty else
        {
            selectionCell.titleLabel.text = teamArray[indexPath.row].name!
            selectionCell.subtitleLabel.text = "\(teamArray[indexPath.row].participantIdentifiers.count) members"

            for identifier in selectedTeams
            {
                if teamArray[indexPath.row].associatedIdentifier == identifier
                {
                    selectionCell.radioButton.isSelected = true
                }
            }

            selectionCell.selectionStyle = .none
            /*selectionCell.tag = indexPath.row;*/ return selectionCell
        }

        selectionCell.titleLabel.text = challengeArray[indexPath.row].title!
        selectionCell.subtitleLabel.text = ""

        if let challenges = tournamentArray[selectedIndexPath.row].associatedChallenges
        {
            if challenges.contains(where: { $0.associatedIdentifier == challengeArray[indexPath.row].associatedIdentifier })
            {
                selectionCell.radioButton.isSelected = true
            }
            else
            {
                selectionCell.radioButton.isSelected = false
            }
        }

        for identifier in selectedChallenges
        {
            if challengeArray[indexPath.row].associatedIdentifier == identifier
            {
                selectionCell.radioButton.isSelected = true
            }
        }

        selectionCell.selectionStyle = .none
        /*selectionCell.tag = 0*/

        return selectionCell
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
        if let currentCell = tableView.cellForRow(at: indexPath) as? SubtitleCell
        {
            currentCell.titleLabel.textColor = .black
            currentCell.subtitleLabel.textColor = .black
        }

        guard tableView.tag == aTagFor("tournamentTableView") else
        {
            if let currentCell = tableView.cellForRow(at: indexPath) as? SelectionCell
            {
                if !challengeArray.isEmpty
                {
                    if currentCell.radioButton.isSelected,
                       let index = selectedChallenges.firstIndex(where: { $0 == challengeArray[indexPath.row].associatedIdentifier })
                    {
                        selectedChallenges.remove(at: index)
                    }
                    else if !currentCell.radioButton.isSelected
                    {
                        selectedChallenges.append(challengeArray[indexPath.row].associatedIdentifier)
                    }

                    currentCell.radioButton.isSelected = !currentCell.radioButton.isSelected
                }
                else
                {
                    if currentCell.radioButton.isSelected,
                       let index = selectedTeams.firstIndex(where: { $0 == teamArray[indexPath.row].associatedIdentifier })
                    {
                        selectedTeams.remove(at: index)
                    }
                    else if !currentCell.radioButton.isSelected
                    {
                        selectedTeams.append(teamArray[indexPath.row].associatedIdentifier)
                    }

                    currentCell.radioButton.isSelected = !currentCell.radioButton.isSelected
                }
            }; return
        }

        selectedIndexPath = indexPath

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

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

        actionSheet.setValue(NSMutableAttributedString(string: "\(tournamentArray[indexPath.row].name!)", attributes: titleAttributes), forKey: "attributedTitle")

        let tournament = tournamentArray[indexPath.row]

        var associatedChallengesString = "0"

        if let challenges = tournament.associatedChallenges
        {
            associatedChallengesString = String(challenges.count)
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        let message = "Associated Challenges: \(associatedChallengesString)\n\nParticipants: \(tournament.teamIdentifiers.count) teams\n\nStart Date: \(formatter.string(from: tournament.startDate))\n\nEnd Date: \(formatter.string(from: tournament.endDate))"

        let boldedRange = ["Associated Challenges:",
                           "Participants:",
                           "Start Date:",
                           "End Date:"]

        actionSheet.setValue(attributedString(message, mainAttributes: regularMessageAttributes, alternateAttributes: boldedMessageAttributes, alternateAttributeRange: boldedRange), forKey: "attributedMessage")

        let addRemoveTeamsAction = UIAlertAction(title: "Add/Remove Teams", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.addRemoveTeamsAction()
        }

        let addRemoveChallengesAction = UIAlertAction(title: "Add/Remove Challenges", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.addRemoveChallengesAction()
        }

        let editAnnouncementAction = UIAlertAction(title: "Edit Announcement", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.editAnnouncementAction()
        }

        let editStartEndDateAction = UIAlertAction(title: "Edit Start/End Date", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            //handle ending of tournaments

            self.editDateActionAlert()
        }

        let viewChallengesAction = UIAlertAction(title: "View Associated Challenges", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.viewChallengesAction()
        }

        let viewRankingsAction = UIAlertAction(title: "View Rankings", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.viewRankingsAction()
        }

        let deleteTournamentAction = UIAlertAction(title: "Delete Tournament", style: .destructive) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.deleteTournamentAction()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)
        }

        actionSheet.addAction(addRemoveTeamsAction)
        actionSheet.addAction(addRemoveChallengesAction)

        actionSheet.addAction(editAnnouncementAction)
        actionSheet.addAction(editStartEndDateAction)

        actionSheet.addAction(viewChallengesAction)
        actionSheet.addAction(viewRankingsAction)

        actionSheet.addAction(deleteTournamentAction)
        actionSheet.addAction(cancelAction)

        present(actionSheet, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection _: Int) -> Int
    {
        guard tableView.tag == aTagFor("tournamentTableView") else
        {
            if !challengeArray.isEmpty
            {
                return challengeArray.count
            }
            else { return teamArray.count }
        }

        return tournamentArray.count
    }
}

//--------------------------------------------------//

/* MARK: UITextViewDelegate */
extension ViewTournamentsController: UITextViewDelegate
{
    func textViewDidBeginEditing(_: UITextView)
    {
        UIView.animate(withDuration: 0.2) {
            self.announceCancelButton.alpha = 1
        }
    }

    func textViewDidChange(_ textView: UITextView)
    {
        announceDoneButton.isEnabled = textView.text! != previousAnnouncement
    }
}
