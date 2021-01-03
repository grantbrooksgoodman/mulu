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
    @IBOutlet weak var challengeButton:  UIButton!
    @IBOutlet weak var teamButton:       UIButton!
    @IBOutlet weak var tournamentButton: UIButton!
    @IBOutlet weak var userButton:       UIButton!
    
    //==================================================//
    
    /* MARK: Class-level Variable Declarations */
    
    var buildInstance: Build!
    
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
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        initialiseController()
        
        currentFile = #file
        buildInfoController?.view.isHidden = !preReleaseApplication
        
        let screenHeight = UIScreen.main.bounds.height
        buildInfoController?.customYOffset = (screenHeight <= 736 ? 40 : 70)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
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
    
    @IBAction func challengeButton(_ sender: Any)
    {
        performSegue(withIdentifier: "NewChallengeFromCreateSegue", sender: self)
    }
    
    @IBAction func teamButton(_ sender: Any)
    {
        performSegue(withIdentifier: "NewTeamFromCreateSegue", sender: self)
    }
    
    @IBAction func tournamentButton(_ sender: Any)
    {
        #warning("For testing purposes only.")
        AlertKit().optionAlertController(title: "Choose", message: nil, cancelButtonTitle: nil, additionalButtons: [("Delete Tournament", false), ("Delete Team", false), ("Remove Team from Tournament", false)], preferredActionIndex: nil, networkDependent: true) { (selectedIndex) in
            if let index = selectedIndex
            {
                if index == 0
                {
                    TournamentSerialiser().deleteTournament("-MPr2-_Lc72yX-r0SIkW") { (errorDescriptor) in
                        if let error = errorDescriptor
                        {
                            report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                        }
                        else { print("SUCCESS!!!") }
                    }
                }
                else if index == 1
                {
                    TeamSerialiser().deleteTeam("-MPr2-Wzrbk17mJUvWEE") { (errorDescriptor) in
                        if let error = errorDescriptor
                        {
                            report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                        }
                        else { print("SUCCESS!!") }
                    }
                }
                else if index == 2
                {
                    TournamentSerialiser().removeTeam("-MPr2-Wzrbk17mJUvWEE", fromTournament: "-MPr2-_Lc72yX-r0SIkW", deleting: false) { (errorDescriptor) in
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
    
    @IBAction func userButton(_ sender: Any)
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
