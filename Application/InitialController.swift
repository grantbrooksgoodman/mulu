//
//  InitialController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 04/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import AVFoundation
import MessageUI
import UIKit

class InitialController: UIViewController
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    @IBOutlet var imageView: UIImageView!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    //Other Declarations
    let applicationDelegate = UIApplication.shared.delegate! as! AppDelegate
    override var prefersStatusBarHidden: Bool
    {
        return true
    }

    var goingBackFromCMS = false

    //==================================================//

    /* MARK: Overridden Functions */

    override func viewDidLoad()
    {
        super.viewDidLoad()

        setNeedsStatusBarAppearanceUpdate()

        imageView.alpha = 0

        UIView.animate(withDuration: 0.5 /*2*/, delay: 0.3, options: UIView.AnimationOptions(), animations: { () -> Void in
            self.applicationDelegate.currentlyAnimating = true
            self.imageView.alpha = 1
        }, completion: { (finishedAnimating: Bool) -> Void in
            if finishedAnimating
            {
                self.applicationDelegate.currentlyAnimating = false

                //                                GenericTestingSerializer().trashDatabase()
                //
                //                                GenericTestingSerializer().createRandomDatabase(numberOfUsers: 4, numberOfChallenges: 5, numberOfTeams: 2) { (errorDescriptor) in
                //                                    if let error = errorDescriptor
                //                                    {
                //                                        report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                //                                    }
                //                                    else { report("Successfully created database.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
                //                                }

                self.performSegue(withIdentifier: "SignInSegue" /*"initialSegue"*/, sender: self)
            }
        })
    }

    override func viewDidAppear(_: Bool)
    {
        if goingBackFromCMS
        {
            performSegue(withIdentifier: "SignInSegue", sender: self)
            goingBackFromCMS = false
        }
    }

    //==================================================//

    /* MARK: Interface Builder Actions */

    @IBAction func skipButton(_: Any)
    {
        //applicationDelegate.currentlyAnimating = false

        //self.performSegue(withIdentifier: "initialSegue", sender: self)
    }
}
