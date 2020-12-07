//
//  MainController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 04/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

/* Third-party Frameworks */
import PKHUD

class MainController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//
    
    /* Interface Builder UI Elements */
    
    //UIButtons
    @IBOutlet weak var codeNameButton:     UIButton!
    @IBOutlet weak var informationButton:  UIButton!
    @IBOutlet weak var sendFeedbackButton: UIButton!
    @IBOutlet weak var subtitleButton:     UIButton!
    
    //UILabels
    @IBOutlet weak var bundleVersionLabel:     UILabel!
    @IBOutlet weak var projectIdentifierLabel: UILabel!
    @IBOutlet weak var skuLabel:               UILabel!
    
    //UIViews
    @IBOutlet weak var extraneousInformationView: UIView!
    @IBOutlet weak var preReleaseInformationView: UIView!
    
    //==================================================//
    
    /* Class-level Variable Declarations */
    
    //Overridden Variables
    override var prefersStatusBarHidden:            Bool                 { return false }
    override var preferredStatusBarStyle:           UIStatusBarStyle     { return .lightContent }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { return .slide }
    
    //Other Declarations
    var buildInstance: Build!
    
    //==================================================//
    
    /* Initialiser Function */
    
    func initialiseController()
    {
        /* Be sure to change the values below.
         *      The build number string when archiving.
         *      The code name of the application.
         *      The editor header file values.
         *      The first digit in the formatted version number.
         *      The value of the pre-release application boolean.
         *      The value of the prefers status bar boolean. */
        
        lastInitialisedController = self
        buildInstance = Build(self)
    }
    
    //==================================================//
    
    /* Overridden Functions */
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        initialiseController()
        
        view.setBackground(withImageNamed: "Background Image")
        
        //        UserSerialiser().createUser(associatedTeams: ["!"], emailAddress: "me@grantbrooks.io", firstName: "Grant", lastName: "Brooks Goodman", profileImageData: nil, pushTokens: nil) { (returnedIdentifier, errorDescriptor) in
        //            if let error = errorDescriptor
        //            {
        //                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
        //            }
        //            else if let identifier = returnedIdentifier
        //            {
        //                print("It worked! \(identifier)")
        //            }
        //        }
        
        //        TeamSerialiser().createTeam(name: "Team Berkeley", participantIdentifiers: ["-MNuzhwBe-c3yz_qtaAu"]) { (returnedIdentifier, errorDescriptor) in
        //            if let error = errorDescriptor
        //            {
        //                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
        //            }
        //            else if let identifier = returnedIdentifier
        //            {
        //                print("It worked! \(identifier)")
        //            }
        //        }
        
        //        TeamSerialiser().getTeam(withIdentifier: "-MNuzz05xikHmAIbUDnH") { (returnedTeam, errorDescriptor) in
        //            if let error = errorDescriptor
        //            {
        //                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
        //            }
        //            else if let team = returnedTeam
        //            {
        //                if let completedChallenges = team.completedChallenges
        //                {
        //                    print("It worked! \(completedChallenges[0].metadata[0].user.firstName!)")
        //                }
        //                else { print("It worked! \(team.name!)") }
        //            }
        //        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if informationDictionary["subtitleExpiryString"] == "Evaluation period ended." && preReleaseApplication
        {
            view.addBlur(withActivityIndicator: false, withStyle: .light, withTag: 1, alpha: 1)
            view.isUserInteractionEnabled = false
        }
        
        currentFile = #file
        buildInfoController?.view.isHidden = true
    }
    
    //==================================================//
    
    /* Interface Builder Actions */
    
    @IBAction func codeNameButton(_ sender: AnyObject)
    {
        buildInstance.codeNameButtonAction()
    }
    
    @IBAction func informationButton(_ sender: AnyObject)
    {
        buildInstance.displayBuildInformation()
    }
    
    @IBAction func sendFeedbackButton(_ sender: Any)
    {
        AlertKit().feedbackController(withFileName: #file)
    }
    
    @IBAction func subtitleButton(_ sender: Any)
    {
        buildInstance.subtitleButtonAction(withButton: sender as! UIButton)
    }
    
    //==================================================//
    
    /* Other Functions */
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }
}
