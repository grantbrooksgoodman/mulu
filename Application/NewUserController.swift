//
//  NewUserController.swift
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

class NewUserController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    //UIBarButtonItems
    @IBOutlet var backButton:   UIBarButtonItem!
    @IBOutlet var cancelButton: UIBarButtonItem!
    @IBOutlet var nextButton:   UIBarButtonItem!

    //UILabels
    @IBOutlet var promptLabel: UILabel!
    @IBOutlet var titleLabel:  UILabel!

    //Other Elements
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var largeTextField: UITextField!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var stepTextView: UITextView!
    @IBOutlet var tableView: UITableView!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    //Arrays
    var selectedTeams = [String]()
    var teamArray:     [Team]?

    //Booleans
    var isGoingBack = false
    var isWorking   = false

    //Strings
    var fullName:     String?
    var emailAddress: String?
    var stepText = "🔴 Set name\n🔴 Set e-mail address\n🔴 Add to teams"

    //Other Declarations
    var buildInstance: Build!
    var controllerReference: CreateController!
    var currentStep = Step.name
    var stepAttributes: [NSAttributedString.Key: Any]!

    //==================================================//

    /* MARK: Enumerated Type Declarations */

    enum Step
    {
        case name
        case email
        case teams
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

        let navigationButtonAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 17)]

        backButton.setTitleTextAttributes(navigationButtonAttributes, for: .normal)
        backButton.setTitleTextAttributes(navigationButtonAttributes, for: .highlighted)
        backButton.setTitleTextAttributes(navigationButtonAttributes, for: .disabled)

        nextButton.setTitleTextAttributes(navigationButtonAttributes, for: .normal)
        nextButton.setTitleTextAttributes(navigationButtonAttributes, for: .highlighted)
        nextButton.setTitleTextAttributes(navigationButtonAttributes, for: .disabled)

        largeTextField.delegate = self
        tableView.backgroundColor = .black

        forwardToName()
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
        case .email:
            goBack()
            forwardToName()
        case .teams:
            goBack()
            forwardToEmail()
        default:
            goBack()
            forwardToTeams()
        }
    }

    @IBAction func cancelButton(_: Any)
    {
        confirmCancellation()
    }

    @IBAction func nextButton(_: Any)
    {
        nextButton.isEnabled = false
        backButton.isEnabled = false

        switch currentStep
        {
        case .name:
            if verifyName()
            {
                fullName = largeTextField.text!
                forwardToEmail()
            }
            else
            {
                AlertKit().errorAlertController(title:                       "Improper Name Format",
                                                message:                     "Please be sure to enter both the user's first and last name.",
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport:               false,
                                                extraInfo:                   nil,
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            false)
                nextButton.isEnabled = true
            }
        case .email:
            if largeTextField.text!.isValidEmail
            {
                emailAddress = largeTextField.text!
                forwardToTeams()
            }
            else
            {
                AlertKit().errorAlertController(title:                       "Invalid E-mail Address",
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
        default:
            forwardToFinish()
        }
    }

    //==================================================//

    /* MARK: Other Functions */

    func animateTeamTableViewAppearance()
    {
        UIView.animate(withDuration: 0.2) { self.largeTextField.alpha = 0 } completion: { _ in
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.reloadData()

            self.tableView.layer.cornerRadius = 10

            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.tableView.alpha = 0.6
                self.promptLabel.alpha = 1
            } completion: { _ in
                self.nextButton.isEnabled = true
                self.backButton.isEnabled = true
            }
        }

        currentStep = .teams
        nextButton.title = "Finish"
    }

    func confirmCancellation()
    {
        AlertKit().confirmationAlertController(title: "Are You Sure?",
                                               message: "Would you really like to cancel?",
                                               cancelConfirmTitles: ["cancel": "No", "confirm": "Yes"],
                                               confirmationDestructive: true,
                                               confirmationPreferred: false,
                                               networkDepedent: false) { didConfirm in
            if didConfirm!
            {
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }

    func createUser()
    {
        guard let fullName = fullName else
        { report("Name was not set!", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]); return }

        let nameComponents = fullName.components(separatedBy: " ")
        let firstName = String(nameComponents[0])
        let lastName = String(nameComponents[1 ... nameComponents.count - 1].joined(separator: " "))

        guard let emailAddress = emailAddress else
        { report("E-mail address was not set!", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]); return }

        UserSerializer().createAccount(associatedTeams: selectedTeams.isEmpty ? nil : selectedTeams, emailAddress: emailAddress, firstName: firstName, lastName: lastName, password: "123456", profileImageData: nil, pushTokens: nil) { returnedUser, errorDescriptor in
            if returnedUser != nil
            {
                Auth.auth().sendPasswordReset(withEmail: emailAddress) { returnedError in
                    if let error = returnedError
                    {
                        AlertKit().errorAlertController(title: "Succeeded with Errors",
                                                        message: "The user was successfully created, but the password reset e-mail could not be sent.",
                                                        dismissButtonTitle: nil,
                                                        additionalSelectors: nil,
                                                        preferredAdditionalSelector: nil,
                                                        canFileReport: true,
                                                        extraInfo: errorInfo(error),
                                                        metadata: [#file, #function, #line],
                                                        networkDependent: true) {
                            self.navigationController?.dismiss(animated: true, completion: nil)
                        }
                    }
                    else
                    {
                        flashSuccessHUD(text: "Successfully created user.", for: 1, delay: nil) { self.navigationController?.dismiss(animated: true, completion: nil) }
                    }
                }
            }
            else
            {
                AlertKit().errorAlertController(title: "Couldn't Create User",
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

    func forwardToName()
    {
        findAndResignFirstResponder()
        largeTextField.autocapitalizationType = .words
        largeTextField.keyboardType = .default
        largeTextField.textContentType = .name

        if isGoingBack
        {
            stepProgress(forwardDirection: false)
            isGoingBack = false
        }

        stepText = "🟡 Set name\n🔴 Set e-mail address\n🔴 Add to teams"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })

        UIView.transition(with: largeTextField, duration: 0.35, options: .transitionCrossDissolve) {
            self.largeTextField.placeholder = "Enter the user's full name"
            self.largeTextField.text = self.fullName ?? nil
        } completion: { _ in
            UIView.animate(withDuration: 0.2) { self.largeTextField.alpha = 1 } completion: { _ in
                self.largeTextField.becomeFirstResponder()

                self.nextButton.isEnabled = true
            }
        }

        currentStep = .name
    }

    func forwardToEmail()
    {
        findAndResignFirstResponder()
        largeTextField.autocapitalizationType = .none
        largeTextField.keyboardType = .emailAddress
        largeTextField.textContentType = .emailAddress

        stepProgress(forwardDirection: !isGoingBack)
        isGoingBack = false

        stepText = "🟢 Set name\n🟡 Set e-mail address\n🔴 Add to teams"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })

        UIView.transition(with: largeTextField, duration: 0.35, options: .transitionCrossDissolve) {
            self.largeTextField.placeholder = "Enter the user's e-mail address"
            self.largeTextField.text = self.emailAddress ?? nil
        } completion: { _ in
            UIView.animate(withDuration: 0.2) { self.largeTextField.alpha = 1 } completion: { _ in
                self.largeTextField.becomeFirstResponder()

                self.backButton.isEnabled = true
                self.nextButton.isEnabled = true
            }
        }

        currentStep = .email
        nextButton.title = "Next"
    }

    func forwardToTeams()
    {
        findAndResignFirstResponder()

        stepProgress(forwardDirection: !isGoingBack)
        isGoingBack = false

        stepText = "🟢 Set name\n🟢 Set e-mail address\n🟡 Add to teams"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })

        promptLabel.textAlignment = .left
        promptLabel.text = "SELECT TEAMS TO ADD THIS USER TO:"

        if teamArray != nil
        {
            animateTeamTableViewAppearance()
        }
        else
        {
            TeamSerializer().getAllTeams { returnedTeams, errorDescriptor in
                if let teams = returnedTeams
                {
                    self.teamArray = teams.sorted(by: { $0.name < $1.name })

                    self.animateTeamTableViewAppearance()
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
        nextButton.isEnabled = false
        backButton.isEnabled = false
        cancelButton.isEnabled = false

        stepProgress(forwardDirection: true)

        stepText = "🟢 Set name\n🟢 Set e-mail address\n🟢 Add to teams"
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })

        UIView.animate(withDuration: 0.2) {
            self.tableView.alpha = 0
            self.promptLabel.alpha = 0
        } completion: { _ in
            self.promptLabel.textAlignment = .center
            self.promptLabel.text = "WORKING..."
            self.isWorking = true

            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.promptLabel.alpha = 1
                self.activityIndicator.alpha = 1
            } completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2500)) { self.createUser() }
            }
        }
    }

    func goBack()
    {
        isWorking = false
        isGoingBack = true

        nextButton.isEnabled = false
        backButton.isEnabled = false

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
        UIView.animate(withDuration: 0.2) { self.progressView.setProgress(self.progressView.progress + (forwardDirection ? 1 / 3 : -(1 / 3)), animated: true) }
    }

    func verifyName() -> Bool
    {
        if largeTextField.text!.components(separatedBy: " ").count > 1
        {
            return true
        }

        return false
    }
}

//==================================================//

/* MARK: Extensions */

/**/

/* MARK: UIAdaptivePresentationControllerDelegate */
extension NewUserController: UIAdaptivePresentationControllerDelegate
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

/* MARK: UITableViewDataSource, UITableViewDelegate */
extension NewUserController: UITableViewDataSource, UITableViewDelegate
{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let currentCell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell") as! SelectionCell

        currentCell.titleLabel.text = teamArray![indexPath.row].name
        currentCell.subtitleLabel.text = "\(teamArray![indexPath.row].participantIdentifiers.count) members"

        if selectedTeams.contains(teamArray![indexPath.row].associatedIdentifier)
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
               let index = selectedTeams.firstIndex(of: teamArray![indexPath.row].associatedIdentifier)
            {
                selectedTeams.remove(at: index)
            }
            else if !currentCell.radioButton.isSelected
            {
                selectedTeams.append(teamArray![indexPath.row].associatedIdentifier)
            }

            currentCell.radioButton.isSelected = !currentCell.radioButton.isSelected
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int
    {
        return teamArray!.count
    }
}

//--------------------------------------------------//

/* MARK: UITextFieldDelegate */
extension NewUserController: UITextFieldDelegate
{
    func textFieldShouldReturn(_: UITextField) -> Bool
    {
        nextButton(nextButton!)
        return true
    }
}
