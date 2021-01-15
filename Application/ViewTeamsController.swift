//
//  ViewTeamsController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 04/01/2021.
//  Copyright © 2013-2021 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

class ViewTeamsController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    //UILabels
    @IBOutlet var promptLabel: UILabel!
    @IBOutlet var titleLabel:  UILabel!

    //UITableViews
    @IBOutlet var selectionTableView: UITableView!
    @IBOutlet var teamTableView:      UITableView!

    //Other Elements
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var doneButton: ShadowButton!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    //Arrays
    var selectedUsers   = [User]()
    var teamArray       = [Team]()
    var tournamentArray = [Tournament]()
    var userArray       = [User]()

    //Dictionaries
    var subtitleAttributes: [NSAttributedString.Key: Any]!
    var titleAttributes:    [NSAttributedString.Key: Any]!

    //Other Declarations
    let paragraphStyle = NSMutableParagraphStyle()

    var buildInstance: Build!
    var selectedIndexPath: IndexPath!
    var selectedTournament: String?

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

        selectionTableView.alpha           = 0
        selectionTableView.backgroundColor = .black
        selectionTableView.tag             = aTagFor("selectionTableView")

        teamTableView.alpha           = 0
        teamTableView.backgroundColor = .black
        teamTableView.tag             = aTagFor("teamTableView")

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

    @IBAction func backButton(_: Any)
    {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func doneButton(_: Any)
    {
        guard !tournamentArray.isEmpty else
        {
            if selectedUsers.isEmpty
            {
                AlertKit().confirmationAlertController(title:                   "Nothing Selected",
                                                       message:                 "You have not selected any users. Teams must be associated with at least one user.\n\nWould you like to cancel?",
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
            else
            {
                let selectedTeam = teamArray[selectedIndexPath.row]

                let usersToRemove = Array(teamArray[selectedIndexPath.row].participantIdentifiers.keys).filter { !selectedUsers.identifiers().contains($0) }

                var userList = ""

                for identifier in usersToRemove
                {
                    let matchingUser = selectedTeam.DSParticipants!.filter { $0.associatedIdentifier == identifier }[0]

                    if userList == ""
                    {
                        userList = "– \(matchingUser.firstName!) \(matchingUser.lastName!)"
                    }
                    else
                    {
                        userList = "\(userList)\n– \(matchingUser.firstName!) \(matchingUser.lastName!)"
                    }
                }

                if !usersToRemove.isEmpty
                {
                    AlertKit().confirmationAlertController(title:                   "Will Remove Users",
                                                           message:                 "The following users will be removed from \(selectedTeam.name!):\n\n\(userList)\n\nPlease confirm this operation.",
                                                           cancelConfirmTitles:     [:],
                                                           confirmationDestructive: true,
                                                           confirmationPreferred:   true,
                                                           networkDepedent:         false) { didConfirm in
                        if didConfirm!
                        {
                            self.updateTeamParticipants()
                        }
                    }
                }
                else { updateTeamParticipants() }

            }; return
        }

        if selectedTournament != nil
        {
            addSelectedTeamToTournament()
        }
        else
        {
            AlertKit().confirmationAlertController(title:                   "Nothing Selected",
                                                   message:                 "You have not selected any tournaments. Would you like to cancel?",
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
    }

    //==================================================//

    /* MARK: Action Sheet Functions */

    func addRemoveUsersAction()
    {
        deselectAllCells()

        teamTableView.isUserInteractionEnabled = false

        UIView.transition(with: titleLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.titleLabel.text = self.teamArray[self.selectedIndexPath.row].name!
        })

        UIView.animate(withDuration: 0.2) {
            self.activityIndicator.alpha = 1
            self.teamTableView.alpha = 0
        } completion: { _ in
            self.setUserArray { errorDescriptor in
                if let error = errorDescriptor
                {
                    AlertKit().errorAlertController(title:                       "Couldn't Get Users",
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
                    guard !self.userArray.isEmpty else
                    {
                        AlertKit().errorAlertController(title:                       "No Users to Add",
                                                        message:                     "This team already has all users on it.",
                                                        dismissButtonTitle:          "OK",
                                                        additionalSelectors:         nil,
                                                        preferredAdditionalSelector: nil,
                                                        canFileReport:               true,
                                                        extraInfo:                   "User array was empty.",
                                                        metadata:                    [#file, #function, #line],
                                                        networkDependent:            false) {
                            self.reloadData()
                        }; return
                    }

                    self.promptLabel.text = "SELECT USERS FOR THIS TEAM:"

                    self.selectionTableView.dataSource = self
                    self.selectionTableView.delegate = self

                    self.selectionTableView.reloadData()

                    self.selectionTableView.layer.cornerRadius = 10

                    self.deselectAllCells()

                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                        self.selectionTableView.scrollToRow(at: IndexPath(row: self.userArray.count - 1, section: 0), at: .bottom, animated: false)

                        self.finishSelectionTableViewSetup()
                    }
                }
            }
        }
    }

    func addToTournamentAction()
    {
        deselectAllCells()

        teamTableView.isUserInteractionEnabled = false

        UIView.animate(withDuration: 0.2) {
            self.activityIndicator.alpha = 1
            self.teamTableView.alpha = 0
        } completion: { _ in
            self.setTournamentArray { errorDescriptor in
                if let error = errorDescriptor
                {
                    AlertKit().errorAlertController(title:                       "Couldn't Get Tournaments",
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
                    guard !self.tournamentArray.isEmpty else
                    { report("Tournament array was not set!", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]); return }

                    self.promptLabel.text = "SELECT A TOURNAMENT:"

                    self.selectionTableView.dataSource = self
                    self.selectionTableView.delegate = self

                    self.selectionTableView.reloadData()

                    self.selectionTableView.layer.cornerRadius = 10

                    UIView.animate(withDuration: 0.2) {
                        self.activityIndicator.alpha  = 0
                        self.doneButton.alpha         = 1
                        self.promptLabel.alpha        = 1
                        self.selectionTableView.alpha = 0.6
                    }
                }
            }
        }
    }

    func copyJoinCodeAction()
    {
        flashSuccessHUD(text: nil, for: 1.5, delay: nil) {
            UIPasteboard.general.string = self.teamArray[self.selectedIndexPath.row].joinCode
        }
    }

    func deleteTeamAction()
    {
        AlertKit().confirmationAlertController(title:                   "Are You Sure?",
                                               message:                 "Please confirm that you would like to delete \(teamArray[selectedIndexPath.row].name!).",
                                               cancelConfirmTitles:     ["confirm": "Delete Team"],
                                               confirmationDestructive: true,
                                               confirmationPreferred:   false,
                                               networkDepedent:         true) { didConfirm in
            if let confirmed = didConfirm
            {
                if confirmed
                {
                    showProgressHUD(text: "Deleting team...", delay: nil)

                    TeamSerializer().deleteTeam(self.teamArray[self.selectedIndexPath.row].associatedIdentifier) { errorDescriptor in
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
                                                                 message: "\(self.teamArray[self.selectedIndexPath.row].name!.capitalized) was successfully deleted.",
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

    @objc func editAdditionalPointsAction()
    {
        let textFieldAttributes: [AlertKit.AlertControllerTextFieldAttribute: Any] =
            [.capitalisationType: UITextAutocapitalizationType.none,
             .correctionType:      UITextAutocorrectionType.no,
             .editingMode:         UITextField.ViewMode.whileEditing,
             .keyboardType:        UIKeyboardType.numberPad,
             .placeholderText:     "",
             .sampleText:          "\(teamArray[selectedIndexPath.row].additionalPoints!)",
             .textAlignment:       NSTextAlignment.center]

        AlertKit().textAlertController(title: "Editing Points",
                                       message: "Enter the amount of additional points you would like to set for \(teamArray[selectedIndexPath.row].name!).",
                                       cancelButtonTitle: nil,
                                       additionalButtons: [("Done", false)],
                                       preferredActionIndex: 0,
                                       textFieldAttributes: textFieldAttributes,
                                       networkDependent: true) { returnedString, selectedIndex in
            if let index = selectedIndex
            {
                if index == 0
                {
                    if let string = returnedString,
                       let points = Int(string),
                       points > -1
                    {
                        showProgressHUD(text: "Setting points...", delay: nil)

                        self.teamArray[self.selectedIndexPath.row].updateAdditionalPoints(points) { errorDescriptor in
                            if let error = errorDescriptor
                            {
                                hideHUD(delay: 1) {
                                    self.errorAlert(title: "Couldn't Set Points", message: error)
                                }
                            }
                            else { self.showSuccessAndReload() }
                        }
                    }
                    else
                    {
                        AlertKit().errorAlertController(title:                       "Invalid Point Value",
                                                        message:                     "Be sure to enter only (positive) numbers and that they do not exceed the integer ceiling.",
                                                        dismissButtonTitle:          "Cancel",
                                                        additionalSelectors:         ["Try Again": #selector(ViewTeamsController.editAdditionalPointsAction)],
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

    @objc func editNameAction()
    {
        let selectedTeam = teamArray[selectedIndexPath.row]

        let textFieldAttributes: [AlertKit.AlertControllerTextFieldAttribute: Any] =
            [.capitalisationType: UITextAutocapitalizationType.words,
             .correctionType:      UITextAutocorrectionType.default,
             .editingMode:         UITextField.ViewMode.whileEditing,
             .keyboardType:        UIKeyboardType.default,
             .placeholderText:     "",
             .sampleText:          "\(selectedTeam.name!)",
             .textAlignment:       NSTextAlignment.center]

        AlertKit().textAlertController(title: "Editing Name",
                                       message: "Enter a new name for this team.",
                                       cancelButtonTitle: nil,
                                       additionalButtons: [("Done", false)],
                                       preferredActionIndex: 0,
                                       textFieldAttributes: textFieldAttributes,
                                       networkDependent: true) { returnedString, selectedIndex in
            if let index = selectedIndex
            {
                if index == 0
                {
                    if let newName = returnedString,
                       newName.lowercasedTrimmingWhitespace != ""
                    {
                        showProgressHUD(text: "Setting name...", delay: nil)

                        selectedTeam.updateName(newName) { errorDescriptor in
                            if let error = errorDescriptor
                            {
                                hideHUD(delay: 1) {
                                    self.errorAlert(title: "Couldn't Set Name", message: error)
                                }
                            }
                            else { self.showSuccessAndReload() }
                        }
                    }
                    else { self.sameInputAlert(#selector(self.editNameAction)) }
                }
                else if selectedIndex == 1
                {
                    self.reSelectRow()
                }
            }
        }
    }

    func viewMembersAction()
    {
        hideHUD(delay: 1)

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let boldedString = "\(teamArray[selectedIndexPath.row].name!) consists of:\n\n\(generateUsersString())"

        let unboldedRange = [generateUsersString()]

        actionSheet.setValue(attributedString(boldedString, mainAttributes: titleAttributes, alternateAttributes: subtitleAttributes, alternateAttributeRange: unboldedRange), forKey: "attributedMessage")

        let backAction = UIAlertAction(title: "Back", style: .default, handler: { _ in
            self.teamTableView.selectRow(at: self.selectedIndexPath, animated: true, scrollPosition: .none)
            self.teamTableView.delegate?.tableView!(self.teamTableView, didSelectRowAt: self.selectedIndexPath)
        })

        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)

        actionSheet.addAction(backAction)
        actionSheet.addAction(dismissAction)

        present(actionSheet, animated: true)
    }

    func viewCompletedChallengesAction()
    {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let challengeMetadataTuple = generateChallengeStrings()

        let boldedString = "\(teamArray[selectedIndexPath.row].name!) has completed:\n\n\(challengeMetadataTuple.challengesString)"

        let unboldedRange = challengeMetadataTuple.titles

        actionSheet.setValue(attributedString(boldedString, mainAttributes: titleAttributes, alternateAttributes: subtitleAttributes, alternateAttributeRange: unboldedRange), forKey: "attributedMessage")

        let backAction = UIAlertAction(title: "Back", style: .default, handler: { _ in
            self.teamTableView.selectRow(at: self.selectedIndexPath, animated: true, scrollPosition: .none)
            self.teamTableView.delegate?.tableView!(self.teamTableView, didSelectRowAt: self.selectedIndexPath)
        })

        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)

        actionSheet.addAction(backAction)
        actionSheet.addAction(dismissAction)

        present(actionSheet, animated: true)
    }

    func viewTournamentAction()
    {
        hideHUD(delay: 1)

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let boldedString = "\(teamArray[selectedIndexPath.row].associatedTournament!.name!) information:\n\n\(generateTournamentStrings().tournamentsString)"

        let unboldedRange = generateTournamentStrings().pointStrings

        actionSheet.setValue(attributedString(boldedString, mainAttributes: titleAttributes, alternateAttributes: subtitleAttributes, alternateAttributeRange: unboldedRange), forKey: "attributedMessage")

        let backAction = UIAlertAction(title: "Back", style: .default, handler: { _ in
            self.teamTableView.selectRow(at: self.selectedIndexPath, animated: true, scrollPosition: .none)
            self.teamTableView.delegate?.tableView!(self.teamTableView, didSelectRowAt: self.selectedIndexPath)
        })

        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)

        actionSheet.addAction(backAction)
        actionSheet.addAction(dismissAction)

        present(actionSheet, animated: true)
    }

    //==================================================//

    /* MARK: Status Alert Functions */

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

    //==================================================//

    /* MARK: Other Functions */

    func addSelectedTeamToTournament()
    {
        showProgressHUD(text: "Adding team to tournament...", delay: nil)

        guard let tournamentIdentifier = selectedTournament else
        { report("Selected tournament was not set!", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]); return }

        TeamSerializer().addTeam(teamArray[selectedIndexPath.row].associatedIdentifier, toTournament: tournamentIdentifier) { errorDescriptor in
            if let error = errorDescriptor
            {
                hideHUD(delay: 1) {
                    AlertKit().errorAlertController(title:                       "Couldn't Add Team",
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

    func updateTeamParticipants()
    {
        var newIdentifiers = selectedUsers.instantiateIdentifierDictionary()

        for identifier in Array(teamArray[selectedIndexPath.row].participantIdentifiers.keys)
        {
            if Array(newIdentifiers.keys).contains(identifier)
            {
                newIdentifiers[identifier] = teamArray[selectedIndexPath.row].participantIdentifiers[identifier]
            }
        }

        if teamArray[selectedIndexPath.row].participantIdentifiers.keys.sorted() == newIdentifiers.keys.sorted()
        {
            flashSuccessHUD(text: "No changes made.", for: 1.5, delay: 0) {
                self.hideSelectionTableView()
            }
        }
        else
        {
            showProgressHUD(text: "Setting users...", delay: nil)

            teamArray[selectedIndexPath.row].updateParticipantIdentifiers(newIdentifiers) { errorDescriptor in
                if let error = errorDescriptor
                {
                    if error != "No changes made."
                    {
                        hideHUD(delay: 1) {
                            AlertKit().errorAlertController(title:                       "Couldn't Set Users",
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
                            flashSuccessHUD(text: error, for: 1.5, delay: 0) {
                                self.hideSelectionTableView()
                            }
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
        tournamentArray = []
        userArray = []

        selectedTournament = ""
        selectedUsers = []
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

    func generateChallengeStrings() -> (challengesString: String, titles: [String])
    {
        var challengesString = ""
        var titleArray = [String]()

        let sortedChallenges = teamArray[selectedIndexPath.row].completedChallenges!.sorted(by: { $0.challenge.title < $1.challenge.title })

        for challengeTuple in sortedChallenges
        {
            var memberString = String(challengeTuple.metadata.count)

            titleArray.append(challengeTuple.challenge.title!)

            if challengeTuple.metadata.count == teamArray[selectedIndexPath.row].participantIdentifiers.count
            {
                memberString = "all"
            }

            if challengesString == ""
            {
                challengesString = "• \(challengeTuple.challenge.title!) – completed by \(memberString) member\(memberString == "1" ? "" : "s")"
            }
            else { challengesString = "\(challengesString)\n• \(challengeTuple.challenge.title!) – completed by \(memberString) member\(memberString == "1" ? "" : "s")" }
        }

        return (challengesString, titleArray)
    }

    func generateTournamentStrings() -> (tournamentsString: String, pointStrings: [String])
    {
        var pointStrings = [String]()
        var tournamentsString = ""

        let tournament = teamArray[selectedIndexPath.row].associatedTournament!

        guard let teams = tournament.DSTeams?.sorted(by: { $0.name < $1.name }) else
        {
            showProgressHUD(text: "Getting tournament information...", delay: nil)

            tournament.deSerializeTeams { returnedTeams, errorDescriptor in
                if returnedTeams != nil
                {
                    hideHUD(delay: 1) {
                        self.viewTournamentAction()
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

    func generateUsersString() -> String
    {
        var usersString = ""

        guard let participants = teamArray[selectedIndexPath.row].DSParticipants?.sorted(by: { $0.firstName < $1.firstName }) else
        {
            showProgressHUD(text: "Getting users...", delay: nil)

            teamArray[selectedIndexPath.row].deSerializeParticipants { returnedUsers, errorDescriptor in
                if returnedUsers != nil
                {
                    hideHUD(delay: 1) {
                        self.viewMembersAction()
                    }
                }
                else
                {
                    hideHUD(delay: 1) {
                        AlertKit().errorAlertController(title:                       "Couldn't Get Users",
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
            }; return "NULL"
        }

        for user in participants
        {
            if usersString == ""
            {
                usersString = "• \(user.firstName!) \(user.lastName!)"
            }
            else { usersString = "\(usersString)\n• \(user.firstName!) \(user.lastName!)" }
        }

        return usersString
    }

    func hideSelectionTableView()
    {
        clearSelection()

        UIView.transition(with: titleLabel, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.titleLabel.text = "All Teams"
        })

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
        teamTableView.isUserInteractionEnabled = false

        UIView.animate(withDuration: 0.2) { self.teamTableView.alpha = 0 } completion: { _ in
            TeamSerializer().getAllTeams { returnedTeams, errorDescriptor in
                if let teams = returnedTeams
                {
                    self.teamArray = teams.sorted(by: { $0.name < $1.name })

                    for team in teams
                    {
                        team.setDSParticipants()

                        if let tournament = team.associatedTournament
                        {
                            tournament.setDSTeams()
                        }
                    }

                    self.teamTableView.dataSource = self
                    self.teamTableView.delegate = self

                    self.teamTableView.reloadData()

                    self.teamTableView.layer.cornerRadius = 10

                    UIView.animate(withDuration: 0.2, delay: 1) {
                        self.activityIndicator.alpha = 0
                        self.teamTableView.alpha = 0.6
                    } completion: { _ in self.teamTableView.isUserInteractionEnabled = true }
                }
                else { report(errorDescriptor!, errorCode: nil, isFatal: true, metadata: [#file, #function, #line]) }
            }
        }
    }

    func finishSelectionTableViewSetup()
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
            self.selectionTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.selectionTableView.layer.cornerRadius = 10

                if self.selectionTableView.tag == aTagFor("selectionTableView") && self.tournamentArray.isEmpty
                {
                    for user in self.selectedUsers
                    {
                        if let index = self.userArray.firstIndex(where: { $0.associatedIdentifier == user.associatedIdentifier }),
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

    func reSelectRow()
    {
        teamTableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
        teamTableView.delegate?.tableView!(teamTableView, didSelectRowAt: selectedIndexPath)
    }

    func setTournamentArray(completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        clearSelection()

        TournamentSerializer().getAllTournaments { returnedTournaments, errorDescriptor in
            if let tournaments = returnedTournaments
            {
                self.tournamentArray = tournaments.sorted(by: { $0.name < $1.name })
                completion(nil)
            }
            else { completion(errorDescriptor!) }
        }
    }

    func setUserArray(completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        clearSelection()

        UserSerializer().getAllUsers { returnedUsers, errorDescriptor in
            if let users = returnedUsers
            {
                var filteredUsers = [User]()

                for user in users
                {
                    if let teamIdentifiers = user.associatedTeams
                    {
                        if teamIdentifiers.contains(self.teamArray[self.selectedIndexPath.row].associatedIdentifier)
                        {
                            filteredUsers.append(user)
                        }
                    }
                    //else { filteredUsers.append(user) }
                }

                self.selectedUsers = filteredUsers
                self.selectedUsers.sort(by: { $0.firstName < $1.firstName })

                var sortedUnselectedUsers = [User]()

                for user in users
                {
                    if let teamIdentifiers = user.associatedTeams
                    {
                        if !teamIdentifiers.contains(self.teamArray[self.selectedIndexPath.row].associatedIdentifier)
                        {
                            sortedUnselectedUsers.append(user)
                        }
                    }
                    else { sortedUnselectedUsers.append(user) }
                }

                filteredUsers.append(contentsOf: sortedUnselectedUsers.sorted(by: { $0.firstName < $1.firstName }))

                self.userArray = filteredUsers
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
extension ViewTeamsController: UITableViewDataSource, UITableViewDelegate
{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard tableView.tag == aTagFor("selectionTableView") else
        {
            let teamCell = tableView.dequeueReusableCell(withIdentifier: "TeamCell") as! SubtitleCell

            teamCell.titleLabel.text = "\(teamArray[indexPath.row].name!)"
            teamCell.subtitleLabel.text = "\(teamArray[indexPath.row].participantIdentifiers.count) members"

            return teamCell
        }

        let selectionCell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell") as! SelectionCell

        guard !tournamentArray.isEmpty else
        {
            selectionCell.titleLabel.text = "\(userArray[indexPath.row].firstName!) \(userArray[indexPath.row].lastName!)"

            if let teams = userArray[indexPath.row].associatedTeams
            {
                selectionCell.subtitleLabel.text = "on \(teams.count) team\(teams.count == 1 ? "" : "s")"
            }
            else { selectionCell.subtitleLabel.text = "on 0 teams" }

            //            for identifier in selectedUsers.identifiers()
            //            {
            //                let index = selectedUsers.firstIndex(where: {$0.associatedIdentifier == identifier})!
            //
            //                if userArray[indexPath.row].associatedIdentifier == identifier
            //                {
            //                    print("Selecting \(selectedUsers[index].firstName!) \(selectedUsers[index].lastName!)")
            //                    selectionCell.radioButton.isSelected = true
            //                }
            //                else
            //                {
            //                    print("NOT Selecting \(selectedUsers[index].firstName!) \(selectedUsers[index].lastName!)")
            //                    selectionCell.radioButton.isSelected = false
            //                }
            //            }

            selectionCell.selectionStyle = .none
            selectionCell.tag = 0; return selectionCell
        }

        selectionCell.titleLabel.text = tournamentArray[indexPath.row].name!
        selectionCell.subtitleLabel.text = "ends \(tournamentArray[indexPath.row].endDate.formattedString())"

        selectionCell.selectionStyle = .none
        selectionCell.tag = indexPath.row

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

        guard tableView.tag == aTagFor("teamTableView") else
        {
            if let currentCell = tableView.cellForRow(at: indexPath) as? SelectionCell
            {
                if !tournamentArray.isEmpty
                {
                    if currentCell.radioButton.isSelected,
                       let tournament = selectedTournament,
                       tournament == tournamentArray[indexPath.row].associatedIdentifier
                    {
                        selectedTournament = nil
                        currentCell.radioButton.isSelected = false
                    }
                    else if !currentCell.radioButton.isSelected
                    {
                        selectedTournament = tournamentArray[indexPath.row].associatedIdentifier
                        currentCell.radioButton.isSelected = true
                    }

                    for cell in tableView.visibleCells
                    {
                        if let cell = cell as? SelectionCell, cell.tag != indexPath.row
                        {
                            cell.radioButton.isSelected = false
                        }
                    }
                }
                else
                {
                    if currentCell.radioButton.isSelected,
                       let index = selectedUsers.firstIndex(where: { $0.associatedIdentifier == userArray[indexPath.row].associatedIdentifier })
                    {
                        selectedUsers.remove(at: index)
                    }
                    else if !currentCell.radioButton.isSelected
                    {
                        selectedUsers.append(userArray[indexPath.row])
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

        actionSheet.setValue(NSMutableAttributedString(string: "\(teamArray[indexPath.row].name!)", attributes: titleAttributes), forKey: "attributedTitle")

        let membersString = String(teamArray[indexPath.row].participantIdentifiers.count)
        var completedChallengesString = "0"

        if let challenges = teamArray[indexPath.row].completedChallenges
        {
            completedChallengesString = String(challenges.count)
        }

        let message = "Associated Tournament: \(teamArray[indexPath.row].associatedTournament?.name! ?? "None")\n\nCompleted Challenges: \(completedChallengesString)\n\nMembers: \(membersString)\n\nTotal Accrued Points: \(teamArray[indexPath.row].getTotalPoints()) (\(teamArray[indexPath.row].additionalPoints!) added manually)\n\nJoin Code: «\(teamArray[indexPath.row].joinCode!)»"

        let boldedRange = ["Associated Tournament:",
                           "Completed Challenges:",
                           "Members:",
                           "Total Accrued Points:",
                           "Join Code:"]

        actionSheet.setValue(attributedString(message, mainAttributes: regularMessageAttributes, alternateAttributes: boldedMessageAttributes, alternateAttributeRange: boldedRange), forKey: "attributedMessage")

        let addRemoveUsersAction = UIAlertAction(title: "Add/Remove Users", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.addRemoveUsersAction()
        }

        let addToTournamentAction = UIAlertAction(title: "Add to Tournament", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.addToTournamentAction()
        }

        let copyJoinCodeAction = UIAlertAction(title: "Copy Join Code", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.copyJoinCodeAction()
        }

        let editAdditionalPointsAction = UIAlertAction(title: "Edit Additional Points", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.editAdditionalPointsAction()
        }

        let editNameAction = UIAlertAction(title: "Edit Name", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.editNameAction()
        }

        let viewCompletedChallengesAction = UIAlertAction(title: "View Completed Challenges", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.viewCompletedChallengesAction()
        }

        let viewMembersAction = UIAlertAction(title: "View Members", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.viewMembersAction()
        }

        let viewTournamentAction = UIAlertAction(title: "View Tournament", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.viewTournamentAction()
        }

        let deleteTeamAction = UIAlertAction(title: "Delete Team", style: .destructive) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.deleteTeamAction()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)
        }

        actionSheet.addAction(addRemoveUsersAction)

        if teamArray[indexPath.row].associatedTournament == nil
        {
            actionSheet.addAction(addToTournamentAction)
        }

        actionSheet.addAction(copyJoinCodeAction)
        actionSheet.addAction(editAdditionalPointsAction)
        actionSheet.addAction(editNameAction)

        if let completedChallenges = teamArray[indexPath.row].completedChallenges,
           !completedChallenges.isEmpty
        {
            actionSheet.addAction(viewCompletedChallengesAction)
        }

        actionSheet.addAction(viewMembersAction)

        if teamArray[indexPath.row].associatedTournament != nil
        {
            actionSheet.addAction(viewTournamentAction)
        }

        actionSheet.addAction(deleteTeamAction)
        actionSheet.addAction(cancelAction)

        present(actionSheet, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection _: Int) -> Int
    {
        guard tableView.tag == aTagFor("selectionTableView") else
        { return teamArray.count }

        guard !tournamentArray.isEmpty else
        { return userArray.count }

        return tournamentArray.count
    }
}
