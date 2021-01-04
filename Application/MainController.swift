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

class MainController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    //UIButtons
    @IBOutlet var codeNameButton:     UIButton!
    @IBOutlet var informationButton:  UIButton!
    @IBOutlet var sendFeedbackButton: UIButton!
    @IBOutlet var subtitleButton:     UIButton!

    //UILabels
    @IBOutlet var bundleVersionLabel:     UILabel!
    @IBOutlet var projectIdentifierLabel: UILabel!
    @IBOutlet var skuLabel:               UILabel!

    //UIViews
    @IBOutlet var extraneousInformationView: UIView!
    @IBOutlet var preReleaseInformationView: UIView!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    //Overridden Variables
    override var prefersStatusBarHidden:            Bool                 { return false }
    override var preferredStatusBarStyle:           UIStatusBarStyle     { return .default }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { return .slide }

    //Other Declarations
    var buildInstance: Build!

    //==================================================//

    /* MARK: Initializer Function */

    func initializeController()
    {
        /* Be sure to change the values below.
         *      The build number string when archiving.
         *      The code name of the application.
         *      The editor header file values.
         *      The first digit in the formatted version number.
         *      The value of the pre-release application boolean.
         *      The value of the prefers status bar boolean. */

        lastInitializedController = self
        buildInstance = Build(self)
    }

    //==================================================//

    /* MARK: Overridden Functions */

    override func viewDidLoad()
    {
        super.viewDidLoad()

        initializeController()

        setNeedsStatusBarAppearanceUpdate()

        //view.setBackground(withImageNamed: "Gradient.png")
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

    /* MARK: Interface Builder Actions */

    @IBAction func codeNameButton(_: AnyObject)
    {
        buildInstance.codeNameButtonAction()
    }

    @IBAction func informationButton(_: AnyObject)
    {
        buildInstance.displayBuildInformation()
    }

    @IBAction func sendFeedbackButton(_: Any)
    {
        AlertKit().feedbackController(withFileName: #file)
    }

    @IBAction func subtitleButton(_ sender: Any)
    {
        buildInstance.subtitleButtonAction(withButton: sender as! UIButton)
    }

    //==================================================//

    /* MARK: Other Functions */

    func bunchaLetters() -> String
    {
        return "abcdefghijklmnopqrstuvwxyz".stringCharacters.shuffled()[0 ... Int().random(min: 1, max: 5)].joined().capitalized
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }
}

//==================================================//

/* MARK: Extensions */

extension Array where Element == Challenge
{
    func titles() -> [String]
    {
        var titles = [String]()

        for challenge in self
        {
            titles.append(challenge.title)
        }

        return titles
    }
}

extension Array where Element == User
{
    func identifiers() -> [String]
    {
        var identifiers = [String]()

        for user in self
        {
            identifiers.append(user.associatedIdentifier)
        }

        return identifiers
    }
}
