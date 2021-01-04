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

    var buildInstance: Build!

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
        else if segue.identifier == "NewUserFromCreateSegue",
                let desintation = segue.destination.children[0] as? NewUserController
        {
            desintation.controllerReference = self
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
        #warning("For testing purposes only.")
        AlertKit().optionAlertController(title: "Choose", message: nil, cancelButtonTitle: nil, additionalButtons: [("Delete Tournament", false), ("Delete Team", false), ("Remove Team from Tournament", false)], preferredActionIndex: nil, networkDependent: true) { selectedIndex in
            if let index = selectedIndex
            {
                if index == 0
                {
                    TournamentSerializer().deleteTournament("-MPr2-_Lc72yX-r0SIkW") { errorDescriptor in
                        if let error = errorDescriptor
                        {
                            report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                        }
                        else { print("SUCCESS!!!") }
                    }
                }
                else if index == 1
                {
                    TeamSerializer().deleteTeam("-MPr2-Wzrbk17mJUvWEE") { errorDescriptor in
                        if let error = errorDescriptor
                        {
                            report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                        }
                        else { print("SUCCESS!!") }
                    }
                }
                else if index == 2
                {
                    TournamentSerializer().removeTeam("-MPr2-Wzrbk17mJUvWEE", fromTournament: "-MPr2-_Lc72yX-r0SIkW", deleting: false) { errorDescriptor in
                        if let error = errorDescriptor
                        {
                            report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                        }
                        else { print("SUCCESS!") }
                    }
                }
            }
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
