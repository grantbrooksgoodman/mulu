//
//  ChallengeCell.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 21/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit
import WebKit

/* Third-party Frameworks */
import PKHUD

class ChallengeCell: UICollectionViewCell
{
    //==================================================//
    
    /* Interface Builder UI Elements */
    
    //UIButtons
    @IBOutlet weak var doneButton:    UIButton!
    @IBOutlet weak var skippedButton: UIButton!
    
    //UILabels
    @IBOutlet weak var titleLabel:       UILabel!
    @IBOutlet weak var subtitleLabel:    UILabel!
    @IBOutlet weak var pointValueLabel:  UILabel!
    @IBOutlet weak var noMediaLabel:     UILabel!
    @IBOutlet weak var noChallengeLabel: UILabel!
    
    //Other Elements
    @IBOutlet weak var encapsulatingView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var promptTextView: UITextView!
    @IBOutlet weak var webView: WKWebView!
    
    //==================================================//
    
    /* Class-level Variable Declarations */
    
    var challengeIdentifier: String!
    
    //==================================================//
    
    /* Interface Builder Actions */
    
    @IBAction func doneButton(_ sender: Any)
    {
        currentUser.completeChallenge(withIdentifier: challengeIdentifier, on: currentTeam) { (errorDescriptor) in
            if let error = errorDescriptor
            {
                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
            else
            {
                HUD.flash(.success, delay: 1.0) { finished in
                    let parent = self.parentViewController as! HomeController
                    parent.reloadData()
                }
            }
        }
    }
    
    @IBAction func skippedButton(_ sender: Any)
    {
        if var skippedChallenges = UserDefaults.standard.value(forKey: "skippedChallenges") as? [String]
        {
            skippedChallenges.append(challengeIdentifier)
            UserDefaults.standard.setValue(skippedChallenges, forKey: "skippedChallenges")
        }
        else { UserDefaults.standard.setValue([challengeIdentifier], forKey: "skippedChallenges") }
        
        HUD.flash(.success, delay: 1.0) { finished in
            let parent = self.parentViewController as! HomeController
            parent.reloadData()
        }
    }
}
