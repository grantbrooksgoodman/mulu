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
        
        UserSerialiser().getUser(withIdentifier: "-MNuzhwBe-c3yz_qtaAu") { (returnedUser, errorDescriptor) in
            if let error = errorDescriptor
            {
                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
            else if let user = returnedUser
            {
                print("It worked! \(user.firstName!)")
                
                self.welcomeLabel.text = "WELCOME BACK \(user.firstName.uppercased())!"
                
                user.deSerialiseAssociatedTeams { (returnedTeams, errorDescriptor) in
                    if let error = errorDescriptor
                    {
                        report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                    }
                    else if let teams = returnedTeams
                    {
                        print("Successfully deserialised Teams! \(teams[0].name!)")
                        self.statisticsTextView.text = "= UCHICAGO TOURNAMENT\n= \(teams[0].name!.uppercased())\n= 11 DAY STREAK"
                        
                        //print(teams[0].completedChallenges(for: user))
                    }
                }
            }
        }
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
