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
        
        initialiseController()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        currentFile = #file
        buildInfoController?.view.isHidden = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        
    }
    
    //==================================================//
    
    /* MARK: Interface Builder Actions */
    
    @IBAction func challengeButton(_ sender: Any)
    {
        performSegue(withIdentifier: "NewChallengeFromCreateSegue", sender: self)
    }
    
    @IBAction func teamButton(_ sender: Any)
    {
        
    }
    
    @IBAction func tournamentButton(_ sender: Any)
    {
        
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
