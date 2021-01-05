//
//  ViewUsersController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 28/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

/* Third-party Frameworks */
import FirebaseAuth

class ViewUsersController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var titleLabel: UILabel!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    var buildInstance: Build!
    var selectedIndexPath: IndexPath!
    var userArray = [User]()

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

        tableView.backgroundColor = .black
        tableView.alpha = 0

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

    //==================================================//

    /* MARK: Action Sheet Functions */

    @objc func addToTeamAction()
    {
        let textFieldAttributes: [AlertKit.AlertControllerTextFieldAttribute: Any] =
            [.capitalisationType:  UITextAutocapitalizationType.none,
             .correctionType:      UITextAutocorrectionType.no,
             .editingMode:         UITextField.ViewMode.never,
             .keyboardAppearance:  UIKeyboardAppearance.default,
             .keyboardType:        UIKeyboardType.default,
             .placeholderText:     "",
             .sampleText:          "",
             .textAlignment:       NSTextAlignment.center]

        AlertKit().textAlertController(title: "Join Code",
                                       message: "Enter the 2-word join code of the team you'd like to add \(userArray[selectedIndexPath.row].firstName!) \(userArray[selectedIndexPath.row].lastName!) to.",
                                       cancelButtonTitle: nil,
                                       additionalButtons: [("Add to Team", false)],
                                       preferredActionIndex: 0,
                                       textFieldAttributes: textFieldAttributes,
                                       networkDependent: true) { returnedString, selectedIndex in
            if let index = selectedIndex
            {
                if index == 0
                {
                    if let string = returnedString, string.lowercasedTrimmingWhitespace != ""
                    {
                        guard string.trimmingBorderedWhitespace.components(separatedBy: " ").count == 2 else
                        { AlertKit().errorAlertController(title: "Invalid Format",
                                                          message: "Join codes consist of 2 words only. Please try again.",
                                                          dismissButtonTitle: "Cancel",
                                                          additionalSelectors: ["Try Again": #selector(ViewUsersController.addToTeamAction)],
                                                          preferredAdditionalSelector: 0,
                                                          canFileReport: false,
                                                          extraInfo: nil,
                                                          metadata: [#file, #function, #line],
                                                          networkDependent: true); return }

                        self.tryToJoin(teamWithCode: string.trimmingBorderedWhitespace)
                    }
                    else
                    {
                        AlertKit().errorAlertController(title: "Nothing Entered",
                                                        message: "No text was entered. Please try again.",
                                                        dismissButtonTitle: "Cancel",
                                                        additionalSelectors: ["Try Again": #selector(ViewUsersController.addToTeamAction)],
                                                        preferredAdditionalSelector: 0,
                                                        canFileReport: false,
                                                        extraInfo: nil,
                                                        metadata: [#file, #function, #line],
                                                        networkDependent: true)
                    }
                }
                else if index == -1
                {
                    self.reSelectRow()
                }
            }
        }
    }

    func deleteUserAction()
    {
        AlertKit().confirmationAlertController(title: "Are You Sure?",
                                               message: "Please confirm that you would like to delete the user account for \(userArray[selectedIndexPath.row].firstName!) \(userArray[selectedIndexPath.row].lastName!).",
                                               cancelConfirmTitles: ["confirm": "Delete User"],
                                               confirmationDestructive: true,
                                               confirmationPreferred: false,
                                               networkDepedent: true) { didConfirm in
            if let confirmed = didConfirm
            {
                if confirmed
                {
                    showProgressHUD(text: "Deleting user...", delay: nil)

                    UserSerializer().deleteUser(self.userArray[self.selectedIndexPath.row]) { problematicTeams, errorDescriptor in
                        if let teams = problematicTeams
                        {
                            self.displayProblematicTeams(with: teams)
                        }
                        else if let error = errorDescriptor
                        {
                            hideHUD(delay: 0.5) { AlertKit().errorAlertController(title: nil,
                                                                                  message: error,
                                                                                  dismissButtonTitle: nil,
                                                                                  additionalSelectors: nil,
                                                                                  preferredAdditionalSelector: nil,
                                                                                  canFileReport: true,
                                                                                  extraInfo: error,
                                                                                  metadata: [#file, #function, #line],
                                                                                  networkDependent: true) }
                        }
                        else
                        {
                            hideHUD(delay: 0.5) {
                                AlertKit().optionAlertController(title: "Operation Completed Successfully", message: "Succesfully deleted user.\n\nPlease manually remove the user's record from the Firebase Authentication console at your earliest convenience.", cancelButtonTitle: "OK", additionalButtons: nil, preferredActionIndex: nil, networkDependent: false) { selectedIndex in
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

    func displayProblematicTeams(with: [String])
    {
        TeamSerializer().getTeams(withIdentifiers: with) { returnedTeams, errorDescriptors in
            if let teams = returnedTeams
            {
                var teamString = ""

                for team in teams
                {
                    if teamString == ""
                    {
                        teamString = team.name!
                    }
                    else { teamString = teamString + "\n\(team.name!)" }
                }

                hideHUD(delay: 0.5) { AlertKit().errorAlertController(title: "Delete Teams First", message: "Please delete the following teams before deleting this user. Otherwise, they will be left with no participants.\n\n\(teamString)", dismissButtonTitle: nil, additionalSelectors: nil, preferredAdditionalSelector: nil, canFileReport: true, extraInfo: teamString, metadata: [#file, #function, #line], networkDependent: true) }
            }
            else if let errors = errorDescriptors
            {
                report(errors.joined(separator: "\n"), errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
        }
    }

    func resetPasswordAction()
    {
        Auth.auth().sendPasswordReset(withEmail: userArray[selectedIndexPath.row].emailAddress) { returnedError in
            if let error = returnedError
            {
                AlertKit().errorAlertController(title: "Unable to Send",
                                                message: error.localizedDescription,
                                                dismissButtonTitle: nil,
                                                additionalSelectors: nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport: true,
                                                extraInfo: errorInfo(error),
                                                metadata: [#file, #function, #line],
                                                networkDependent: true)
            }
            else { self.showSuccessAndReload() }
        }
    }

    func viewCompletedChallengesAction()
    {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.alignment = .justified

        let titleAttributes: [NSAttributedString.Key: Any] = [.baselineOffset: NSNumber(value: 0),
                                                              .font: UIFont(name: "SFUIText-Semibold", size: 14)!,
                                                              .foregroundColor: UIColor.darkGray,
                                                              .paragraphStyle: paragraphStyle]

        let subtitleAttributes: [NSAttributedString.Key: Any] = [.baselineOffset: NSNumber(value: 0),
                                                                 .font: UIFont(name: "SFUIText-Regular", size: 14)!,
                                                                 .foregroundColor: UIColor.darkGray,
                                                                 .paragraphStyle: paragraphStyle]

        let boldedString = "\(userArray[selectedIndexPath.row].firstName!) has completed:\n\n\(generateChallengesString())"

        let unboldedRange = challengeTitles()

        actionSheet.setValue(attributedString(boldedString, mainAttributes: titleAttributes, alternateAttributes: subtitleAttributes, alternateAttributeRange: unboldedRange), forKey: "attributedMessage")

        let backAction = UIAlertAction(title: "Back", style: .default, handler: { _ in
            self.tableView.selectRow(at: self.selectedIndexPath, animated: true, scrollPosition: .none)
            self.tableView.delegate?.tableView!(self.tableView, didSelectRowAt: self.selectedIndexPath)
        })

        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)

        actionSheet.addAction(backAction)
        actionSheet.addAction(dismissAction)

        present(actionSheet, animated: true)
    }

    func viewTeamMembershipAction()
    {
        guard userArray[selectedIndexPath.row].DSAssociatedTeams != nil else
        {
            showProgressHUD(text: "Gathering user information...", delay: nil)

            userArray[selectedIndexPath.row].deSerialiseAssociatedTeams { returnedTeams, errorDescriptor in
                if returnedTeams != nil
                {
                    hideHUD(delay: 1) { self.viewTeamMembershipAction() }
                }
                else
                {
                    report(errorDescriptor!, errorCode: nil, isFatal: true, metadata: [#file, #function, #line])
                }
            }; return
        }

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.alignment = .justified

        let titleAttributes: [NSAttributedString.Key: Any] = [.baselineOffset: NSNumber(value: 0),
                                                              .font: UIFont(name: "SFUIText-Semibold", size: 14)!,
                                                              .foregroundColor: UIColor.darkGray,
                                                              .paragraphStyle: paragraphStyle]

        let subtitleAttributes: [NSAttributedString.Key: Any] = [.baselineOffset: NSNumber(value: 0),
                                                                 .font: UIFont(name: "SFUIText-Regular", size: 14)!,
                                                                 .foregroundColor: UIColor.darkGray,
                                                                 .paragraphStyle: paragraphStyle]

        let boldedString = "\(userArray[selectedIndexPath.row].firstName!) is a member of:\n\n\(generateTeamsString())"

        let unboldedRange = [generateTeamsString()]

        actionSheet.setValue(attributedString(boldedString, mainAttributes: titleAttributes, alternateAttributes: subtitleAttributes, alternateAttributeRange: unboldedRange), forKey: "attributedMessage")

        let backAction = UIAlertAction(title: "Back", style: .default, handler: { _ in
            self.tableView.selectRow(at: self.selectedIndexPath, animated: true, scrollPosition: .none)
            self.tableView.delegate?.tableView!(self.tableView, didSelectRowAt: self.selectedIndexPath)
        })

        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)

        actionSheet.addAction(backAction)
        actionSheet.addAction(dismissAction)

        present(actionSheet, animated: true)
    }

    //==================================================//

    /* MARK: Other Functions */

    func challengeTitles() -> [String]
    {
        var titleArray: [String] = []

        let sortedChallenges = userArray[selectedIndexPath.row].allCompletedChallenges()!.sorted(by: { $0.challenge.title < $1.challenge.title })

        for challengeTuple in sortedChallenges
        {
            titleArray.append(challengeTuple.challenge.title!)
        }

        return titleArray
    }

    func generateChallengesString() -> String
    {
        var challengesString = ""

        let sortedChallenges = userArray[selectedIndexPath.row].allCompletedChallenges()!.sorted(by: { $0.challenge.title < $1.challenge.title })

        for challenge in sortedChallenges
        {
            var dateString = challenge.date.formattedString()

            if dateString == "Today" || dateString == "Yesterday"
            {
                dateString = "– \(dateString)"
            }
            else if dateString.contains(":")
            {
                dateString = "at \(dateString)"
            }
            else { dateString = "on \(dateString)" }

            if challengesString == ""
            {
                challengesString.append("• \(challenge.challenge.title!) \(dateString)")
            }
            else { challengesString.append("\n• \(challenge.challenge.title!) \(dateString)") }
        }

        return challengesString
    }

    func generateTeamsString() -> String
    {
        var teamsString = ""

        let sortedTeams = userArray[selectedIndexPath.row].DSAssociatedTeams!.sorted(by: { $0.name < $1.name })

        for team in sortedTeams
        {
            if teamsString == ""
            {
                teamsString.append("• \(team.name!)")
            }
            else { teamsString.append("\n• \(team.name!)") }
        }

        return teamsString
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }

    @objc func reloadData()
    {
        tableView.isUserInteractionEnabled = false

        UIView.animate(withDuration: 0.2) { self.tableView.alpha = 0 } completion: { _ in
            UserSerializer().getAllUsers { returnedUsers, errorDescriptor in
                if let users = returnedUsers
                {
                    self.userArray = users

                    for user in users
                    {
                        user.setDSAssociatedTeams()
                    }

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

    func showSuccessAndReload()
    {
        hideHUD(delay: 0.5) {
            flashSuccessHUD(text: nil, for: 1.2, delay: 0) {
                self.activityIndicator.alpha = 1
                self.reloadData()
            }
        }
    }

    func tryToJoin(teamWithCode: String)
    {
        TeamSerializer().getTeam(byJoinCode: teamWithCode) { returnedIdentifier, errorDescriptor in
            if let identifier = returnedIdentifier
            {
                TeamSerializer().addUser(self.userArray[self.selectedIndexPath.row].associatedIdentifier, toTeam: identifier) { errorDescriptor in
                    if let error = errorDescriptor
                    {
                        AlertKit().errorAlertController(title:                       nil,
                                                        message:                     error,
                                                        dismissButtonTitle:          "OK",
                                                        additionalSelectors:         ["Try Again": #selector(ViewUsersController.addToTeamAction)],
                                                        preferredAdditionalSelector: 0,
                                                        canFileReport:               true,
                                                        extraInfo:                   nil,
                                                        metadata:                    [#file, #function, #line],
                                                        networkDependent:            false)

                        report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                    }
                    else { self.showSuccessAndReload() }
                }
            }
            else if let error = errorDescriptor
            {
                AlertKit().errorAlertController(title:                       nil,
                                                message:                     error,
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         ["Try Again": #selector(ViewUsersController.addToTeamAction)],
                                                preferredAdditionalSelector: 0,
                                                canFileReport:               true,
                                                extraInfo:                   nil,
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            false)

                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
        }
    }
}

//==================================================//

/* MARK: Extensions */

/**/

/* MARK: UITableViewDataSource, UITableViewDelegate */
extension ViewUsersController: UITableViewDataSource, UITableViewDelegate
{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let currentCell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as! SubtitleCell

        currentCell.titleLabel.text = "\(userArray[indexPath.row].firstName!) \(userArray[indexPath.row].lastName!)"
        currentCell.subtitleLabel.text = userArray[indexPath.row].emailAddress!

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

        actionSheet.setValue(NSMutableAttributedString(string: "\(userArray[indexPath.row].firstName!) \(userArray[indexPath.row].lastName!)", attributes: titleAttributes), forKey: "attributedTitle")

        let teamCount = userArray[indexPath.row].associatedTeams?.count ?? 0
        let challengeCount = userArray[indexPath.row].allCompletedChallenges()?.count ?? 0
        let registeredString = "Has\(userArray[indexPath.row].pushTokens == nil ? " NOT" : "") registered for push notifications."

        let message = "Member of \(teamCount) team\(teamCount == 1 ? "" : "s").\n\nCompleted \(challengeCount) challenge\(challengeCount == 1 ? "" : "s").\n\n\(registeredString)"

        let boldedRange = ["\(teamCount) team\(teamCount == 1 ? "" : "s").",
                           "\(challengeCount) challenge\(challengeCount == 1 ? "" : "s")."]

        actionSheet.setValue(attributedString(message, mainAttributes: regularMessageAttributes, alternateAttributes: boldedMessageAttributes, alternateAttributeRange: boldedRange), forKey: "attributedMessage")

        let addToTeamAction = UIAlertAction(title: "Add to Team", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.addToTeamAction()
        }

        let resetPasswordAction = UIAlertAction(title: "Send Password Reset Instructions", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.resetPasswordAction()
        }

        let viewCompletedChallengesAction = UIAlertAction(title: "View Completed Challenges", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.viewCompletedChallengesAction()
        }

        let viewTeamMembershipAction = UIAlertAction(title: "View Team Membership", style: .default) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.viewTeamMembershipAction()
        }

        let deleteUserAction = UIAlertAction(title: "Delete User", style: .destructive) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)

            self.deleteUserAction()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)
        }

        actionSheet.addAction(addToTeamAction)
        actionSheet.addAction(resetPasswordAction)

        if userArray[indexPath.row].allCompletedChallenges() != nil
        {
            actionSheet.addAction(viewCompletedChallengesAction)
        }

        if userArray[indexPath.row].associatedTeams != nil
        {
            actionSheet.addAction(viewTeamMembershipAction)
        }

        actionSheet.addAction(deleteUserAction)
        actionSheet.addAction(cancelAction)

        present(actionSheet, animated: true, completion: nil)
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int
    {
        return userArray.count
    }
}
