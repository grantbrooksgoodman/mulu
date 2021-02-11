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

class ChallengeCell: UICollectionViewCell
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    //UIButtons
    @IBOutlet var doneButton:    UIButton!
    @IBOutlet var playButton:    UIButton!
    @IBOutlet var skippedButton: UIButton!

    //UILabels
    @IBOutlet var titleLabel:       UILabel!
    @IBOutlet var subtitleLabel:    UILabel!
    @IBOutlet var pointValueLabel:  UILabel!
    @IBOutlet var noMediaLabel:     UILabel!
    @IBOutlet var noChallengeLabel: UILabel!

    //Other Elements
    @IBOutlet var encapsulatingView: UIView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var promptTextView: UITextView!
    @IBOutlet var webView: WKWebView!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    //URLs
    var autoPlayVideoLink: URL?
    var tikTokVideoLink:   URL?

    //Other Declarations
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

    @IBAction func doneButton(_: Any)
    {
        Analytics.logEvent("completed_challenge", parameters: ["challengeName": titleLabel.text!])

        self.isUserInteractionEnabled = false
        self.doneButton.isUserInteractionEnabled = false
        self.skippedButton.isUserInteractionEnabled = false
        showProgressHUD(viewController: self.parentViewController!)
        currentUser.completeChallenge(withIdentifier: challengeIdentifier, on: currentTeam) { errorDescriptor in
            if let error = errorDescriptor
            {
                hideHUD(delay: 0.5) {
                    AlertKit().errorAlertController(title: "Couldn't Complete Challenge", message: error, dismissButtonTitle: nil, additionalSelectors: nil, preferredAdditionalSelector: nil, canFileReport: true, extraInfo: error, metadata: [#file, #function, #line], networkDependent: true)

                    report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])

                    self.isUserInteractionEnabled = true
                    self.doneButton.isUserInteractionEnabled = true
                    self.skippedButton.isUserInteractionEnabled = true
                }
            }
            else
            {
                let parent = self.parentViewController as! HomeController
                parent.setVisualTeamInformation(cell: self)
//                hideHUD(delay: nil) {
//                    flashSuccessHUD(text: nil, for: 1.25, delay: nil) {
//                        self.isUserInteractionEnabled = true
//                        self.doneButton.isUserInteractionEnabled = true
//                        self.skippedButton.isUserInteractionEnabled = true
//
//                    }
//                }
            }
        }
    }

    @IBAction func playButton(_: Any)
    {
        UIView.animate(withDuration: 0.2) {
            self.playButton.alpha = 0
        } completion: { _ in
            guard let autoPlayVideoLink = self.autoPlayVideoLink else
            {
                guard let tikTokVideoLink = self.tikTokVideoLink else
                { report("No link provided!", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]); return }

                self.webView.alpha = 0
                self.webView.navigationDelegate = self

                if let currentURL = self.webView.url,
                   currentURL.absoluteString.contains("tiktok")
                {
                    self.webView.evaluateJavaScript("document.elementFromPoint(0, 0).click();", completionHandler: nil)
                }
                else {
                    self.webView.load(URLRequest(url: tikTokVideoLink))
                    
                }; return
            }

            self.webView.isUserInteractionEnabled = true
            self.webView.load(URLRequest(url: autoPlayVideoLink))
        }
    }

    @IBAction func skippedButton(_: Any)
    {
        Analytics.logEvent("skipped_challenge", parameters: ["challengeName": titleLabel.text!])

        if var skippedChallenges = UserDefaults.standard.value(forKey: "skippedChallenges") as? [String]
        {
            skippedChallenges.append(challengeIdentifier)
            UserDefaults.standard.setValue(skippedChallenges, forKey: "skippedChallenges")
        }
        else { UserDefaults.standard.setValue([challengeIdentifier], forKey: "skippedChallenges") }

        flashSuccessHUD(text: nil, for: 1.25, delay: nil) {
            let parent = self.parentViewController as! HomeController
            parent.reloadData()
        }
    }

    func removeElements(_ divClasses: [String])
    {
        for element in divClasses
        {
            webView.evaluateJavaScript("document.querySelectorAll('\(element)').forEach(function(a){ a.remove() })")
        }
    }
}

extension ChallengeCell: WKNavigationDelegate
{
    func webView(_ webView: WKWebView, didFinish _: WKNavigation!)
    {
        if tikTokVideoLink != nil
        {
            let divClasses = [".jsx-966597281", ".jsx-3565214464", ".jsx-4174542791", ".jsx-4137551713", ".player-back", ".jsx-3565214464"]

            removeElements(divClasses)

            webView.evaluateJavaScript("document.elementFromPoint(0, 0).click();")
        }
    }
}
