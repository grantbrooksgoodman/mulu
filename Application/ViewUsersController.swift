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
import PKHUD

class ViewUsersController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//
    
    /* MARK: Interface Builder UI Elements */
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    //==================================================//
    
    /* MARK: Class-level Variable Declarations */
    
    var buildInstance: Build!
    var selectedIndexPath: IndexPath!
    var userArray: [User] = []
    
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
        
        tableView.backgroundColor = .black
        tableView.alpha = 0
        
        reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        currentFile = #file
        buildInfoController?.view.isHidden = false
        
        showProgressHUD(text: "Loading data...", delay: 0.5)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        roundCorners(forViews: [tableView], withCornerType: 0)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        
    }
    
    //==================================================//
    
    /* MARK: Interface Builder Actions */
    
    @IBAction func backButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    //==================================================//
    
    /* MARK: Action Sheet Functions */
    
    @objc func addToTeamAction()
    {
        let textFieldAttributes: [AlertKit.AlertControllerTextFieldAttribute:Any] =
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
                                       networkDependent: true) { (returnedString, selectedIndex) in
            if let index = selectedIndex, index == 0
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
        }
    }
    
    func displayProblematicTeams(with: [String])
    {
        TeamSerialiser().getTeams(withIdentifiers: with) { (returnedTeams, errorDescriptors) in
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
                
                hideHUD(delay: 0.5) {
                    AlertKit().errorAlertController(title: "Delete Teams First", message: "Please delete the following teams before deleting this user. Otherwise, they will be left with no participants.\n\n\(teamString)", dismissButtonTitle: nil, additionalSelectors: nil, preferredAdditionalSelector: nil, canFileReport: true, extraInfo: teamString, metadata: [#file, #function, #line], networkDependent: true)
                }
            }
            else if let errors = errorDescriptors
            {
                report(errors.joined(separator: "\n"), errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
        }
    }
    
    func deleteUserAction()
    {
        AlertKit().confirmationAlertController(title: "Are You Sure?",
                                               message: "Please confirm that you would like to delete the user account for \(self.userArray[self.selectedIndexPath.row].firstName!) \(self.userArray[self.selectedIndexPath.row].lastName!).",
                                               cancelConfirmTitles: ["confirm":"Delete User"],
                                               confirmationDestructive: true,
                                               confirmationPreferred: false,
                                               networkDepedent: true) { (didConfirm) in
            if let confirmed = didConfirm, confirmed
            {
                showProgressHUD(text: "Deleting user...", delay: nil)
                
                UserSerialiser().deleteUser(self.userArray[self.selectedIndexPath.row]) { (problematicTeams, errorDescriptor) in
                    if let teams = problematicTeams
                    {
                        self.displayProblematicTeams(with: teams)
                    }
                    else if let error = errorDescriptor
                    {
                        hideHUD(delay: 0.5) {
                            AlertKit().errorAlertController(title: nil,
                                                            message: error,
                                                            dismissButtonTitle: nil,
                                                            additionalSelectors: nil,
                                                            preferredAdditionalSelector: nil,
                                                            canFileReport: true,
                                                            extraInfo: error,
                                                            metadata: [#file, #function, #line],
                                                            networkDependent: true)
                        }
                    }
                    else
                    {
                        hideHUD(delay: 0.5) {
                            AlertKit().optionAlertController(title: "Operation Completed Successfully", message: "Succesfully deleted user.\n\nPlease manually remove the user's record from the Firebase Authentication console at your earliest convenience.", cancelButtonTitle: "OK", additionalButtons: nil, preferredActionIndex: nil, networkDependent: false) { (selectedIndex) in
                                if let index = selectedIndex, index == -1
                                {
                                    showProgressHUD(text: "Reloading data...", delay: nil)
                                    
                                    self.reloadData()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func resetPasswordAction()
    {
        Auth.auth().sendPasswordReset(withEmail: self.userArray[self.selectedIndexPath.row].emailAddress) { (returnedError) in
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
            else
            {
                HUD.flash(.success)
            }
        }
    }
    
    func viewCompletedChallengesAction()
    {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.alignment = .justified
        
        let titleAttributes: [NSAttributedString.Key:Any] = [.baselineOffset: NSNumber(value: 0),
                                                             .font: UIFont(name: "SFUIText-Semibold", size: 14)!,
                                                             .foregroundColor: UIColor.darkGray,
                                                             .paragraphStyle: paragraphStyle]
        
        let subtitleAttributes: [NSAttributedString.Key:Any] = [.baselineOffset: NSNumber(value: 0),
                                                                .font: UIFont(name: "SFUIText-Regular", size: 14)!,
                                                                .foregroundColor: UIColor.darkGray,
                                                                .paragraphStyle: paragraphStyle]
        
        let boldedString = "\(userArray[selectedIndexPath.row].firstName!) has completed:\n\n\(self.generateChallengesString())"
        
        let unboldedRange = self.challengeTitles()
        
        actionSheet.setValue(attributedString(boldedString, mainAttributes: titleAttributes, alternateAttributes: subtitleAttributes, alternateAttributeRange: unboldedRange), forKey: "attributedMessage")
        
        let backAction = UIAlertAction(title: "Back", style: .default, handler: { (_) in
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
            
            userArray[selectedIndexPath.row].deSerialiseAssociatedTeams { (returnedTeams, errorDescriptor) in
                if returnedTeams != nil
                {
                    hideHUD(delay: 1) {
                        self.viewTeamMembershipAction()
                    }
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
        
        let titleAttributes: [NSAttributedString.Key:Any] = [.baselineOffset: NSNumber(value: 0),
                                                             .font: UIFont(name: "SFUIText-Semibold", size: 14)!,
                                                             .foregroundColor: UIColor.darkGray,
                                                             .paragraphStyle: paragraphStyle]
        
        let subtitleAttributes: [NSAttributedString.Key:Any] = [.baselineOffset: NSNumber(value: 0),
                                                                .font: UIFont(name: "SFUIText-Regular", size: 14)!,
                                                                .foregroundColor: UIColor.darkGray,
                                                                .paragraphStyle: paragraphStyle]
        
        let boldedString = "\(userArray[selectedIndexPath.row].firstName!) is a member of:\n\n\(self.generateTeamsString())"
        
        let unboldedRange = [self.generateTeamsString()]
        
        actionSheet.setValue(attributedString(boldedString, mainAttributes: titleAttributes, alternateAttributes: subtitleAttributes, alternateAttributeRange: unboldedRange), forKey: "attributedMessage")
        
        let backAction = UIAlertAction(title: "Back", style: .default, handler: { (_) in
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
    
    func attributedString(_ with:                  String,
                          mainAttributes:          [NSAttributedString.Key:Any],
                          alternateAttributes:     [NSAttributedString.Key:Any],
                          alternateAttributeRange: [String]) -> NSAttributedString
    {
        let attributedString = NSMutableAttributedString(string: with, attributes: mainAttributes)
        
        for string in alternateAttributeRange
        {
            let currentRange = (with as NSString).range(of: (string as NSString) as String)
            
            attributedString.addAttributes(alternateAttributes, range: currentRange)
        }
        
        return attributedString
    }
    
    func challengeTitles() -> [String]
    {
        var titleArray: [String] = []
        
        let sortedChallenges = userArray[selectedIndexPath.row].allCompletedChallenges()!.sorted(by: {$0.challenge.title < $1.challenge.title})
        
        for challengeBundle in sortedChallenges
        {
            titleArray.append(challengeBundle.challenge.title!)
        }
        
        return titleArray
    }
    
    func generateChallengesString() -> String
    {
        var challengesString = ""
        
        let sortedChallenges = userArray[selectedIndexPath.row].allCompletedChallenges()!.sorted(by: {$0.challenge.title < $1.challenge.title})
        
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
        
        let sortedTeams = userArray[selectedIndexPath.row].DSAssociatedTeams!.sorted(by: {$0.name < $1.name})
        
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
        
        UIView.animate(withDuration: 0.2) {
            self.tableView.alpha = 0
        } completion: { (_) in
            UserSerialiser().getAllUsers { (returnedUsers, errorDescriptor) in
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
                    
                    hideHUD(delay: 1.5) {
                        UIView.animate(withDuration: 0.2) {
                            self.tableView.alpha = 0.6
                        } completion: { (_) in
                            self.tableView.isUserInteractionEnabled = true
                        }
                    }
                }
                else { report(errorDescriptor!, errorCode: nil, isFatal: true, metadata: [#file, #function, #line]) }
            }
        }
    }
    
    func tryToJoin(teamWithCode: String)
    {
        TeamSerialiser().getTeam(byJoinCode: teamWithCode) { (returnedIdentifier, errorDescriptor) in
            if let identifier = returnedIdentifier
            {
                TeamSerialiser().addUser(self.userArray[self.selectedIndexPath.row].associatedIdentifier, toTeam: identifier) { (errorDescriptor) in
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
                    else
                    {
                        PKHUD.sharedHUD.contentView = PKHUDSuccessView(title: nil, subtitle: "Successfully added to team.")
                        PKHUD.sharedHUD.show()
                        
                        hideHUD(delay: 1) {
                            showProgressHUD(text: "Reloading data...", delay: nil)
                            
                            self.reloadData()
                        }
                    }
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
        let currentCell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as! UserCell
        
        currentCell.nameLabel.text = "\(userArray[indexPath.row].firstName!) \(userArray[indexPath.row].lastName!)"
        currentCell.emailLabel.text = userArray[indexPath.row].emailAddress!
        
        return currentCell
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        if let currentCell = tableView.cellForRow(at: indexPath) as? UserCell
        {
            currentCell.nameLabel.textColor = .white
            currentCell.emailLabel.textColor = .white
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        selectedIndexPath = indexPath
        
        if let currentCell = tableView.cellForRow(at: indexPath) as? UserCell
        {
            currentCell.nameLabel.textColor = .black
            currentCell.emailLabel.textColor = .black
        }
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.alignment = .justified
        
        let titleAttributes: [NSAttributedString.Key:Any] = [.baselineOffset: NSNumber(value: -3),
                                                             .font: UIFont(name: "SFUIText-Semibold", size: 20)!,
                                                             .foregroundColor: UIColor.darkGray]
        
        let regularMessageAttributes: [NSAttributedString.Key:Any] = [.baselineOffset: NSNumber(value: 0),
                                                                      .font: UIFont(name: "SFUIText-Regular", size: 14)!,
                                                                      .foregroundColor: UIColor.darkGray,
                                                                      .paragraphStyle: paragraphStyle]
        
        let boldedMessageAttributes: [NSAttributedString.Key:Any] = [.baselineOffset: NSNumber(value: 0),
                                                                     .font: UIFont(name: "SFUIText-Semibold", size: 14)!,
                                                                     .foregroundColor: UIColor.darkGray,
                                                                     .paragraphStyle: paragraphStyle]
        
        actionSheet.setValue(NSMutableAttributedString(string: "\(userArray[indexPath.row].firstName!) \(userArray[indexPath.row].lastName!)", attributes: titleAttributes), forKey: "attributedTitle")
        
        let teamCount = userArray[indexPath.row].associatedTeams?.count ?? 0
        let challengeCount = userArray[indexPath.row].allCompletedChallenges()?.count ?? 0
        let registeredString = "Has\(userArray[indexPath.row].pushTokens == nil ? " NOT" : " ") registered for push notifications."
        
        let message = "Member of \(teamCount) team\(teamCount == 1 ? "" : "s").\n\nCompleted \(challengeCount) challenge\(challengeCount == 1 ? "" : "s").\n\n\(registeredString)"
        
        let boldedRange = ["\(teamCount) team\(teamCount == 1 ? "" : "s").",
                           "\(challengeCount) challenge\(challengeCount == 1 ? "" : "s")."]
        
        actionSheet.setValue(attributedString(message, mainAttributes: regularMessageAttributes, alternateAttributes: boldedMessageAttributes, alternateAttributeRange: boldedRange), forKey: "attributedMessage")
        
        let addToTeamAction = UIAlertAction(title: "Add to Team", style: .default) { (_) in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)
            
            self.addToTeamAction()
        }
        
        let resetPasswordAction = UIAlertAction(title: "Send Password Reset Instructions", style: .default) { (_) in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)
            
            self.resetPasswordAction()
        }
        
        let viewCompletedChallengesAction = UIAlertAction(title: "View Completed Challenges", style: .default) { (_) in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)
            
            self.viewCompletedChallengesAction()
        }
        
        let viewTeamMembershipAction = UIAlertAction(title: "View Team Membership", style: .default) { (_) in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)
            
            self.viewTeamMembershipAction()
        }
        
        let deleteUserAction = UIAlertAction(title: "Delete User", style: .destructive) { (_) in
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)
            
            self.deleteUserAction()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return userArray.count
    }
}
