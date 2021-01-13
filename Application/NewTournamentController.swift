//
//  NewTournamentController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 12/01/2021.
//  Copyright © 2013-2021 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

/* Third-party Frameworks */
import FirebaseStorage

class NewTournamentController: UIViewController, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    //UIBarButtonItems
    @IBOutlet var backButton:   UIBarButtonItem!
    @IBOutlet var cancelButton: UIBarButtonItem!
    @IBOutlet var nextButton:   UIBarButtonItem!

    //UILabels
    @IBOutlet var stepTitleLabel:       UILabel!
    @IBOutlet var tableViewPromptLabel: UILabel!

    //Other Elements
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var largeTextField: UITextField!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var stepTextView: UITextView!
    @IBOutlet var tableView: UITableView!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    //Arrays
    var challengeArray: [Challenge]?
    var teamArray:      [Team]!
    var selectedChallenges = [String]()
    var selectedTeams      = [String]()

    //Booleans
    var isGoingBack = false
    var isWorking   = false

    //Dates
    var endDate:   Date?
    var startDate: Date?

    //Strings
    var tournamentName: String?
    var stepText = "🔴 Set name\n🔴 Set start & end date\n🔴 Add teams\n🔴 Add challenges"

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
        case startDate
        case endDate
        case teams
        case challenges
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
        tableView.tag = aTagFor("teamTableView")

        forwardToName()

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
        case .endDate:
            goBack()
            forwardToStartDate()
        case .teams:
            goBack()
            forwardToEndDate()
        case .challenges:
            goBack()
            forwardToTeams()
        default:
            goBack()
            forwardToName()
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
                forwardToStartDate()
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
        case .startDate:
            startDate = datePicker.date
            forwardToEndDate()
        case .endDate:
            endDate = datePicker.date

            guard datePicker.date > startDate! else
            {
                AlertKit().errorAlertController(title:                       "Invalid End Date",
                                                message:                     "The end date of the tournament must be greater than the start date.",
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport:               false,
                                                extraInfo:                   nil,
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            false)
                nextButton.isEnabled = true; return
            }

            forwardToTeams()
        case .teams:
            if !selectedTeams.isEmpty
            {
                forwardToChallenges()
            }
            else
            {
                AlertKit().errorAlertController(title:                       "No Teams Selected",
                                                message:                     "You must select at least one team to add to this tournament.",
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
        default:
            forwardToFinish()
        }
    }

    //==================================================//

    /* MARK: Other Functions */

    func deselectAllCells()
    {
        for cell in tableView.visibleCells
        {
            if let cell = cell as? SelectionCell
            {
                cell.radioButton.isSelected = false
            }
        }
    }

    func animateStepChange()
    {
        UIView.transition(with: stepTextView, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.stepTextView.attributedText = NSAttributedString(string: self.stepText, attributes: self.stepAttributes)
        })
    }

    func animateTableViewAppearance()
    {
        deselectAllCells()

        UIView.animate(withDuration: 0.2) {
            self.datePicker.alpha           = 0
            self.stepTitleLabel.alpha       = 0
            self.tableViewPromptLabel.alpha = 0
        } completion: { _ in
            self.tableViewPromptLabel.text = self.tableView.tag == aTagFor("teamTableView") ? "SELECT TEAMS TO ADD:" : "SELECT CHALLENGES TO ASSOCIATE:"

            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.reloadData()

            self.tableView.layer.cornerRadius = 10

            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.tableViewPromptLabel.alpha = 1
                self.tableView.alpha = 0.6
            } completion: { _ in
                self.nextButton.isEnabled = true
                self.backButton.isEnabled = true
            }
        }
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
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }

    func createTournament()
    {
        guard let tournamentName = tournamentName,
              let startDate = startDate,
              let endDate = endDate,
              !selectedTeams.isEmpty else
        { report("Required metadata not set!", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]); return }

        TournamentSerializer().createTournament(name: tournamentName,
                                                startDate: startDate,
                                                endDate: endDate,
                                                associatedChallenges: selectedChallenges.isEmpty ? nil : selectedChallenges,
                                                teamIdentifiers: selectedTeams) { returnedIdentifier, errorDescriptor in
            if returnedIdentifier != nil
            {
                flashSuccessHUD(text: "Successfully created tournament.", for: 1, delay: nil) {
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }
            }
            else
            {
                AlertKit().errorAlertController(title: "Couldn't Create Tournament",
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
        largeTextField.keyboardType = .default
        largeTextField.text = tournamentName ?? nil

        if isGoingBack
        {
            stepProgress(forwardDirection: false)
            isGoingBack = false
        }

        stepText = "🟡 Set name\n🔴 Set start & end date\n🔴 Add teams\n🔴 Add challenges"
        animateStepChange()

        UIView.animate(withDuration: 0.2) {
            self.largeTextField.alpha = 1
        } completion: { _ in
            self.largeTextField.becomeFirstResponder()

            self.nextButton.isEnabled = true
        }

        currentStep = .name
    }

    func forwardToStartDate()
    {
        findAndResignFirstResponder()

        stepProgress(forwardDirection: !isGoingBack)
        isGoingBack = false

        stepText = "🟢 Set name\n🟡 Set start & end date\n🔴 Add teams\n🔴 Add challenges"
        animateStepChange()

        UIView.animate(withDuration: 0.2) {
            self.largeTextField.alpha = 0
            self.stepTitleLabel.alpha = 0
        } completion: { _ in
            self.datePicker.date = self.startDate ?? Date()

            self.stepTitleLabel.text = "SELECT START DATE:"
            self.stepTitleLabel.textAlignment = .left

            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.stepTitleLabel.alpha = 1
                self.datePicker.alpha = 1
            }  completion: { _ in
                self.nextButton.isEnabled = true
                self.backButton.isEnabled = true
            }
        }

        currentStep = .startDate
        nextButton.title = "Next"
    }

    func forwardToEndDate()
    {
        stepProgress(forwardDirection: !isGoingBack)
        isGoingBack = false

        stepText = "🟢 Set name\n🟡 Set start & end date\n🔴 Add teams\n🔴 Add challenges"
        animateStepChange()

        UIView.animate(withDuration: 0.2) {
            self.datePicker.alpha = 0
            self.stepTitleLabel.alpha = 0
            self.tableViewPromptLabel.alpha = 0
        } completion: { _ in
            self.datePicker.date = self.endDate ?? Date()

            self.stepTitleLabel.text = "SELECT END DATE:"
            self.stepTitleLabel.textAlignment = .left

            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.stepTitleLabel.alpha = 1
                self.datePicker.alpha = 1
            }  completion: { _ in
                self.nextButton.isEnabled = true
                self.backButton.isEnabled = true
            }
        }

        currentStep = .endDate
        nextButton.title = "Next"
    }

    func forwardToTeams()
    {
        findAndResignFirstResponder()

        stepProgress(forwardDirection: !isGoingBack)
        isGoingBack = false

        stepText = "🟢 Set name\n🟢 Set start & end date\n🟡 Add teams\n🔴 Add challenges"
        animateStepChange()

        currentStep = .teams
        nextButton.title = "Next"
        tableView.tag = aTagFor("teamTableView")

        animateTableViewAppearance()
    }

    func forwardToChallenges()
    {
        stepProgress(forwardDirection: !isGoingBack)
        isGoingBack = false

        stepText = "🟢 Set name\n🟢 Set start & end date\n🟢 Add teams\n🟡 Add challenges"
        animateStepChange()

        currentStep = .challenges
        nextButton.title = "Finish"
        tableView.tag = aTagFor("challengeTableView")

        if challengeArray != nil
        {
            animateTableViewAppearance()
        }
        else
        {
            ChallengeSerializer().getAllChallenges { returnedChallenges, errorDescriptor in
                if let challenges = returnedChallenges
                {
                    self.challengeArray = challenges.sorted(by: { $0.title < $1.title })

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

        stepProgress(forwardDirection: true)

        stepText = "🟢 Set name\n🟢 Set start & end date\n🟢 Add teams\n🟢 Add challenges"
        animateStepChange()

        UIView.animate(withDuration: 0.2) {
            self.tableViewPromptLabel.alpha = 0
            self.tableView.alpha = 0
        } completion: { _ in
            self.stepTitleLabel.text = "WORKING..."
            self.stepTitleLabel.textAlignment = .center

            self.isWorking = true

            UIView.animate(withDuration: 0.2, delay: 0.5) {
                self.stepTitleLabel.alpha = 1
                self.activityIndicator.alpha = 1
            } completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2500)) { self.createTournament() }
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

        if currentStep != .startDate
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
        UIView.animate(withDuration: 0.2) { self.progressView.setProgress(self.progressView.progress + (forwardDirection ? 0.2 : -0.2), animated: true) }
    }

    func verifyName() -> Bool
    {
        if largeTextField.text!.lowercasedTrimmingWhitespace != ""
        {
            tournamentName = largeTextField.text!
            return true
        }

        return false
    }
}

//==================================================//

/* MARK: Extensions */

/**/

/* MARK: UIAdaptivePresentationControllerDelegate */
extension NewTournamentController: UIAdaptivePresentationControllerDelegate
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
extension NewTournamentController: UITableViewDataSource, UITableViewDelegate
{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let currentCell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell") as! SelectionCell

        currentCell.selectionStyle = .none

        guard tableView.tag == aTagFor("challengeTableView") else
        {
            currentCell.titleLabel.text = teamArray[indexPath.row].name
            currentCell.subtitleLabel.text = "\(teamArray[indexPath.row].participantIdentifiers.count) members"

            if selectedTeams.contains(teamArray[indexPath.row].associatedIdentifier)
            {
                currentCell.radioButton.isSelected = true
            }; return currentCell
        }

        currentCell.titleLabel.text = challengeArray![indexPath.row].title
        currentCell.subtitleLabel.text = ""

        if selectedChallenges.contains(challengeArray![indexPath.row].associatedIdentifier)
        {
            currentCell.radioButton.isSelected = true
        }

        return currentCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let currentCell = tableView.cellForRow(at: indexPath) as? SelectionCell
        {
            guard tableView.tag == aTagFor("challengeTableView") else
            {
                if currentCell.radioButton.isSelected,
                   let index = selectedTeams.firstIndex(of: teamArray[indexPath.row].associatedIdentifier)
                {
                    selectedTeams.remove(at: index)
                }
                else if !currentCell.radioButton.isSelected
                {
                    selectedTeams.append(teamArray[indexPath.row].associatedIdentifier)
                }

                currentCell.radioButton.isSelected = !currentCell.radioButton.isSelected; return
            }

            if currentCell.radioButton.isSelected,
               let index = selectedChallenges.firstIndex(of: challengeArray![indexPath.row].associatedIdentifier)
            {
                selectedChallenges.remove(at: index)
            }
            else if !currentCell.radioButton.isSelected
            {
                selectedChallenges.append(challengeArray![indexPath.row].associatedIdentifier)
            }

            currentCell.radioButton.isSelected = !currentCell.radioButton.isSelected
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int
    {
        guard tableView.tag == aTagFor("challengeTableView") else
        { return teamArray.count }

        return challengeArray!.count
    }
}

//--------------------------------------------------//

/* MARK: UITextFieldDelegate */
extension NewTournamentController: UITextFieldDelegate
{
    func textFieldShouldReturn(_: UITextField) -> Bool
    {
        nextButton(nextButton!)
        return true
    }
}
