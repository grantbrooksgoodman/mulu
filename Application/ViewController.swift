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
        
    }
    
    //==================================================//
    
    /* MARK: Interface Builder Actions */
    
    @IBAction func challengeButton(_ sender: Any)
    {
        performSegue(withIdentifier: "ViewChallengesFromViewSegue", sender: self)
    }
    
    @IBAction func teamButton(_ sender: Any)
    {
        #warning("For testing purposes only.")
        AlertKit().confirmationAlertController(title: nil, message: "Reformat database?", cancelConfirmTitles: ["confirm": "Reformat"], confirmationDestructive: true, confirmationPreferred: true, networkDepedent: true) { (didConfirm) in
            if let confirmed = didConfirm, confirmed
            {
                showProgressHUD(text: "Working...", delay: nil)
                
                GenericTestingSerialiser().trashDatabase()
                
                GenericTestingSerialiser().createRandomDatabase(numberOfUsers: 10, numberOfChallenges: 5, numberOfTeams: 4) { (errorDescriptor) in
                    hideHUD(delay: 1)
                    
                    if let error = errorDescriptor
                    {
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
                    else
                    {
                        if let joinCode = generatedJoinCode
                        {
                            AlertKit().optionAlertController(title: "Operation Completed Successfully", message: "Successfully reformatted database. Here's a team join code:\n\n«\(joinCode)»", cancelButtonTitle: "Dismiss", additionalButtons: nil, preferredActionIndex: nil, networkDependent: true) { (_) in
                                print("finished")
                            }
                        }
                        else
                        {
                            AlertKit().optionAlertController(title: "Succeeded with Errors", message: "Successfully reformatted database, but couldn't get a team join code.", cancelButtonTitle: "OK", additionalButtons: nil, preferredActionIndex: nil, networkDependent: true) { (_) in
                                print("finished")
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func tournamentButton(_ sender: Any)
    {
        
    }
    
    @IBAction func userButton(_ sender: Any)
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
