//
//  CreateController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 23/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

class CreateController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    //UIButtons
    @IBOutlet var challengeButton:  UIButton!
    @IBOutlet var teamButton:       UIButton!
    @IBOutlet var tournamentButton: UIButton!
    @IBOutlet var userButton:       UIButton!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    override var canBecomeFirstResponder: Bool {
        return true
    }

    var buildInstance: Build!
    var filteredTeams = [Team]()

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

        becomeFirstResponder()
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        initializeController()

        currentFile = #file
        buildInfoController?.view.isHidden = !preReleaseApplication

        let screenHeight = UIScreen.main.bounds.height
        buildInfoController?.customYOffset = (screenHeight <= 736 ? 40 : 70)
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with _: UIEvent?)
    {
        if motion == .motionShake
        {
            AlertKit().confirmationAlertController(title: "Sign Out", message: "Would you like to sign out?", cancelConfirmTitles: [:], confirmationDestructive: false, confirmationPreferred: true, networkDepedent: true) { didConfirm in
                if let confirmed = didConfirm, confirmed
                {
                    signedOut = true
                    self.performSegue(withIdentifier: "MainSegue", sender: self)
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?)
    {
        if segue.identifier == "NewChallengeFromCreateSegue",
           let destination = segue.destination.children[0] as? NewChallengeController
        {
            destination.controllerReference = self
        }
        else if segue.identifier == "NewTeamFromCreateSegue",
                let destination = segue.destination.children[0] as? NewTeamController
        {
            destination.controllerReference = self
        }
        else if segue.identifier == "NewTournamentFromCreateSegue",
                let destination = segue.destination.children[0] as? NewTournamentController
        {
            destination.controllerReference = self
            destination.teamArray = filteredTeams.sorted(by: { $0.name < $1.name })
        }
        else if segue.identifier == "NewUserFromCreateSegue",
                let desintation = segue.destination.children[0] as? NewUserController
        {
            desintation.controllerReference = self
        }
        else if segue.identifier == "MainSegue",
                let desintation = segue.destination as? InitialController
        {
            desintation.goingBackFromCMS = true
        }
    }

    //==================================================//

    /* MARK: Interface Builder Actions */

    @IBAction func challengeButton(_: Any)
    {
        performSegue(withIdentifier: "NewChallengeFromCreateSegue", sender: self)
    }

    @IBAction func teamButton(_: Any)
    {
        performSegue(withIdentifier: "NewTeamFromCreateSegue", sender: self)
    }

    @IBAction func tournamentButton(_: Any)
    {
        showProgressHUD(text: "Getting teams...", delay: nil)

        TeamSerializer().getAllTeams { returnedTeams, errorDescriptor in
            if let teams = returnedTeams
            {
                for team in teams
                {
                    if team.associatedTournament == nil
                    {
                        self.filteredTeams.append(team)
                    }
                }

                hideHUD(delay: 1) {
                    guard !self.filteredTeams.isEmpty else
                    {
                        AlertKit().errorAlertController(title: "Error",
                                                        message: "There are no teams currently without a tournament.\n\nEither create a new team first or remove a team from a tournament.",
                                                        dismissButtonTitle: "OK",
                                                        additionalSelectors: nil,
                                                        preferredAdditionalSelector: nil,
                                                        canFileReport: true,
                                                        extraInfo: "Filtered teams empty.",
                                                        metadata: [#file, #function, #line],
                                                        networkDependent: true); return
                    }

                    self.performSegue(withIdentifier: "NewTournamentFromCreateSegue", sender: self)
                }
            }
            else { report(errorDescriptor!, errorCode: nil, isFatal: true, metadata: [#file, #function, #line]) }
        }
    }

    @IBAction func userButton(_: Any)
    {
        performSegue(withIdentifier: "NewUserFromCreateSegue", sender: self)
    }

    //==================================================//

    /* MARK: Other Functions */

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }
}
