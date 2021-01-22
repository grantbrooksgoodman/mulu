//
//  LicenseController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 22/01/2021.
//  Copyright © 2013-2021 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

class LicenseController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var textView: UITextView!
    @IBOutlet var agreeButton: ShadowButton!
    @IBOutlet var disagreeButton: ShadowButton!

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

        view.setBackground(withImageNamed: "Gradient.png")

        agreeButton.initializeLayer(animateTouches:     true,
                                    backgroundColor:    UIColor(hex: 0x60C129),
                                    customBorderFrame:  nil,
                                    customCornerRadius: nil,
                                    shadowColor:        UIColor(hex: 0x3B9A1B).cgColor)

        disagreeButton.initializeLayer(animateTouches:     true,
                                       backgroundColor:    UIColor(hex: 0xE95A53),
                                       customBorderFrame:  nil,
                                       customCornerRadius: nil,
                                       shadowColor:        UIColor(hex: 0xD5443B).cgColor)
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        initializeController()

        currentFile = #file
        buildInfoController?.view.isHidden = !preReleaseApplication

        buildInfoController?.customYOffset = 80
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?)
    {
        if segue.identifier == "TabBarFromLicenseSegue"
        {
            signedOut = false
        }
    }

    //==================================================//

    /* MARK: Interface Builder Actions */

    @IBAction func agreeButton(_: Any)
    {
        UserDefaults.standard.setValue(true, forKey: "agreedToLicense")
        agreedToLicense = true

        performSegue(withIdentifier: "TabBarFromLicenseSegue", sender: self)
    }

    @IBAction func disagreeButton(_: Any)
    {
        signedOut = true

        performSegue(withIdentifier: "SignInFromLicenseSegue", sender: self)
    }

    //==================================================//

    /* MARK: Other Functions */

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }
}
