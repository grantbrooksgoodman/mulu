//
//  HomeController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 08/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

/* Third-party Frameworks */
import Firebase

class HomeController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//
    
    /* Interface Builder UI Elements */
    
    //UIButtons
    @IBOutlet weak var doneButton:    UIButton!
    @IBOutlet weak var skippedButton: UIButton!
    
    //UILabels
    @IBOutlet weak var pointValueLabel: UILabel!
    @IBOutlet weak var subtitleLabel:   UILabel!
    @IBOutlet weak var titleLabel:      UILabel!
    @IBOutlet weak var welcomeLabel:    UILabel!
    
    //UITextViews
    @IBOutlet weak var promptTextView:     UITextView!
    @IBOutlet weak var statisticsTextView: UITextView!
    
    //Other Elements
    @IBOutlet weak var challengeView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    //==================================================//
    
    /* Class-level Variable Declarations */
    
    var buildInstance: Build!
    
    //==================================================//
    
    /* Initialiser Function */
    
    func initialiseController()
    {
        lastInitialisedController = self
        buildInstance = Build(self)
    }
    
    //==================================================//
    
    /* Overridden Functions */
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        initialiseController()
        
        view.setBackground(withImageNamed: "Gradient.png")
        
        doneButton.layer.cornerRadius = 5
        skippedButton.layer.cornerRadius = 5
        
        welcomeLabel.text = "WELCOME BACK \(currentUser.firstName!.uppercased())!"
        welcomeLabel.font = UIFont(name: "Gotham-Black", size: 32)!
        
        currentUser.challengesToComplete(on: currentTeam, completion: { (returnedIdentifiers, errorDescriptor) in
            if let identifiers = returnedIdentifiers
            {
                ChallengeSerialiser().getChallenge(withIdentifier: identifiers[0]) { (returnedChallenge, errorDescriptor) in
                    if let challenge = returnedChallenge
                    {
                        self.subtitleLabel.text = challenge.title
                        self.promptTextView.text = challenge.prompt
                    }
                    else if let error = errorDescriptor
                    {
                        report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                    }
                }
            }
            else if let error = errorDescriptor
            {
                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
        })
        
        var statisticsString = "+ \(currentTeam.name!.uppercased())\n"
        
        if let tournament = currentTeam.associatedTournament
        {
            statisticsString = "+ \(tournament.name!.uppercased())\n" + statisticsString
        }
        
        let streak = currentUser.streak(on: currentTeam)
        
        statisticsString += "+ \(streak == 0 ? "NO" : "\(streak) DAY") STREAK"
        
        statisticsTextView.text = statisticsString
    }
    
    func setUpButton(with button: UIButton)
    {
        button.layer.cornerRadius = 5
        
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        currentFile = #file
        buildInfoController?.view.isHidden = false
        
        challengeView.layer.cornerRadius = 10
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        
    }
    
    //==================================================//
    
    /* Interface Builder Actions */
    
    //==================================================//
    
    /* Other Functions */
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }
}
