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
    }

    @IBAction func tournamentButton(_: Any)
    {
        performSegue(withIdentifier: "ViewTournamentsFromViewSegue", sender: self)
    }

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
