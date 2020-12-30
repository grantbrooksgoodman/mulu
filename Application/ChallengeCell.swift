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
import FirebaseAnalytics
import PKHUD

class ChallengeCell: UICollectionViewCell
{
    //==================================================//
    
    /* MARK: Interface Builder UI Elements */
    
    //UIButtons
    @IBOutlet weak var doneButton:    UIButton!
    @IBOutlet weak var playButton:    UIButton!
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
    
    /* MARK: Class-level Variable Declarations */
    
    //Other Declarations
    var autoPlayVideoLink: URL!
    var challengeIdentifier: String!
    
    //==================================================//
    
    /* MARK: Overridden Functions */
    
    override func draw(_ rect: CGRect)
    {
        super.draw(rect)
        
        let configuration = UIImage.SymbolConfiguration(pointSize: 60, weight: .regular, scale: .large)
        let normalImage = UIImage(systemName: "play.circle", withConfiguration: configuration)
        
        playButton.setImage(normalImage, for: .normal)
    }
    
    //==================================================//
    
    /* MARK: Interface Builder Actions */
    
    @IBAction func doneButton(_ sender: Any)
    {
        Analytics.logEvent("completed_challenge", parameters: ["challengeName": titleLabel.text!])
        
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
    
    @IBAction func playButton(_ sender: Any)
    {
        UIView.animate(withDuration: 0.2) {
            self.playButton.alpha = 0
        } completion: { (_) in
            self.webView.isUserInteractionEnabled = true
            self.webView.load(URLRequest(url: self.autoPlayVideoLink))
        }
    }
    
    @IBAction func skippedButton(_ sender: Any)
    {
        Analytics.logEvent("skipped_challenge", parameters: ["challengeName": titleLabel.text!])
        
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
