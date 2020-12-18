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
        
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemID: "id-\(title!)",
            AnalyticsParameterItemName: title!,
            AnalyticsParameterContentType: "cont"
        ])
        
        if let user = currentUser
        {
            welcomeLabel.text = "WELCOME BACK \(user.firstName!.uppercased())!"
            welcomeLabel.font = UIFont(name: "Gotham-Black", size: 32) ?? UIFont.systemFont(ofSize: 12)
            
            if let completedChallenges = user.completedChallenges()
            {
                subtitleLabel.text = completedChallenges[0].challenge.title
                promptTextView.text = completedChallenges[0].challenge.prompt
            }
            
            if let associatedTeams = user.DSAssociatedTeams
            {
                let teamName = associatedTeams[0].name!
                let tournamentName = associatedTeams[0].associatedTournament?.name ?? ""
                let streak = user.streak(on: associatedTeams[0])
                
                statisticsTextView.text = "+ \(tournamentName.uppercased())\n+ \(teamName.uppercased())\n+ \(streak) DAY STREAK"
            }
        }
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
