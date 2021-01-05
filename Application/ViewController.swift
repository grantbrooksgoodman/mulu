//
//  ViewController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 28/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

class ViewController: UIViewController, MFMailComposeViewControllerDelegate
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

    override func prepare(for _: UIStoryboardSegue, sender _: Any?)
    {}

    //==================================================//

    /* MARK: Interface Builder Actions */

    @IBAction func challengeButton(_: Any)
    {
        performSegue(withIdentifier: "ViewChallengesFromViewSegue", sender: self)
    }

    @IBAction func teamButton(_: Any)
    {
        performSegue(withIdentifier: "ViewTeamsFromViewSegue", sender: self)

        //        #warning("For testing purposes only.")
        //        AlertKit().confirmationAlertController(title: nil, message: "Reformat database?", cancelConfirmTitles: ["confirm": "Reformat"], confirmationDestructive: true, confirmationPreferred: true, networkDepedent: true) { didConfirm in
        //            if let confirmed = didConfirm, confirmed
        //            {
        //                showProgressHUD(text: "Working...", delay: nil)
        //
        //                GenericTestingSerializer().trashDatabase()
        //
        //                GenericTestingSerializer().createRandomDatabase(numberOfUsers: 10, numberOfChallenges: 5, numberOfTeams: 4) { errorDescriptor in
        //                    hideHUD(delay: 1)
        //
        //                    if let error = errorDescriptor
        //                    {
        //                        AlertKit().errorAlertController(title: nil,
        //                                                        message: error,
        //                                                        dismissButtonTitle: nil,
        //                                                        additionalSelectors: nil,
        //                                                        preferredAdditionalSelector: nil,
        //                                                        canFileReport: true,
        //                                                        extraInfo: error,
        //                                                        metadata: [#file, #function, #line],
        //                                                        networkDependent: true)
        //                    }
        //                    else
        //                    {
        //                        if let joinCode = generatedJoinCode
        //                        {
        //                            AlertKit().optionAlertController(title: "Operation Completed Successfully", message: "Successfully reformatted database. Here's a team join code:\n\n«\(joinCode)»", cancelButtonTitle: "Dismiss", additionalButtons: nil, preferredActionIndex: nil, networkDependent: true) { _ in
        //                                print("finished")
        //                            }
        //                        }
        //                        else
        //                        {
        //                            AlertKit().optionAlertController(title: "Succeeded with Errors", message: "Successfully reformatted database, but couldn't get a team join code.", cancelButtonTitle: "OK", additionalButtons: nil, preferredActionIndex: nil, networkDependent: true) { _ in
        //                                print("finished")
        //                            }
        //                        }
        //                    }
        //                }
        //            }
        //        }
    }

    @IBAction func tournamentButton(_: Any)
    {}

    @IBAction func userButton(_: Any)
    {
        performSegue(withIdentifier: "ViewUsersFromViewSegue", sender: self)
    }

    //==================================================//

    /* MARK: Other Functions */

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }
}
