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
import WebKit

/* Third-party Frameworks */
import Firebase
import PKHUD
import SwiftyGif

class HomeController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//
    
    /* Interface Builder UI Elements */
    
    //UIButtons
    @IBOutlet weak var doneButton:    UIButton!
    @IBOutlet weak var skippedButton: UIButton!
    
    //UILabels
    @IBOutlet weak var noChallengeLabel: UILabel!
    @IBOutlet weak var noMediaLabel: UILabel!
    @IBOutlet weak var pointValueLabel:  UILabel!
    @IBOutlet weak var subtitleLabel:    UILabel!
    @IBOutlet weak var titleLabel:       UILabel!
    @IBOutlet weak var welcomeLabel:     UILabel!
    
    //UITextViews
    @IBOutlet weak var promptTextView:     UITextView!
    @IBOutlet weak var statisticsTextView: UITextView!
    
    //Other Elements
    @IBOutlet weak var challengeView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var webView: WKWebView!
    
    //==================================================//
    
    /* Class-level Variable Declarations */
    
    var buildInstance: Build!
    var currentChallenge: Challenge?
    
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
        
        NotificationCenter.default.addObserver(forName: UIWindow.didResignKeyNotification, object: view.window, queue: nil) { (notification) in
            (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .all
        }
        
        NotificationCenter.default.addObserver(forName: UIWindow.didBecomeKeyNotification, object: view.window, queue: nil) { (notification) in
            (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .portrait
        }
        
        doneButton.layer.cornerRadius = 5
        skippedButton.layer.cornerRadius = 5
        
        welcomeLabel.text = "WELCOME BACK \(currentUser.firstName!.uppercased())!"
        welcomeLabel.font = UIFont(name: "Gotham-Black", size: 32)!
        
        challengeView.alpha = 0
        
        incompleteChallengesForToday { (returnedChallenges, errorDescriptor) in
            if let challenges = returnedChallenges
            {
                if challenges.count > 0
                {
                    self.setUpChallengeView(for: challenges[0])
                }
                else
                {
                    for subview in self.challengeView.subviews
                    {
                        subview.alpha = 0
                    }
                    
                    UIView.animate(withDuration: 0.2) {
                        self.challengeView.alpha = 1
                        self.noChallengeLabel.alpha = 1
                    }
                }
            }
            else if let error = errorDescriptor
            {
                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
        }
        
        var statisticsString = "+ \(currentTeam.name!.uppercased())\n"
        
        if let tournament = currentTeam.associatedTournament
        {
            statisticsString = "+ \(tournament.name!.uppercased())\n" + statisticsString
        }
        
        let streak = currentUser.streak(on: currentTeam)
        statisticsString += "+ \(streak == 0 ? "NO" : "\(streak) DAY") STREAK"
        statisticsTextView.text = statisticsString
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
    
    @IBAction func doneButton(_ sender: Any)
    {
        if let challenge = currentChallenge
        {
            currentUser.completeChallenge(withIdentifier: challenge.associatedIdentifier, on: currentTeam) { (returnedError) in
                if let error = returnedError
                {
                    report(error.localizedDescription, errorCode: (error as NSError).code, isFatal: false, metadata: [#file, #function, #line])
                }
                else
                {
                    HUD.flash(.success, delay: 1.0) { finished in
                        for subview in self.challengeView.subviews
                        {
                            subview.alpha = 0
                        }
                        
                        self.noChallengeLabel.text = "You've completed today's challenge already.\n\nCheck back later!"
                        
                        UIView.animate(withDuration: 0.2) {
                            self.noChallengeLabel.alpha = 1
                        }
                    }
                }
            }
        }
        else { report("Couldn't get current Challenge!", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]) }
    }
    
    @IBAction func skippedButton(_ sender: Any)
    {
        if let challenge = currentChallenge
        {
            UserDefaults.standard.setValue(challenge.associatedIdentifier, forKey: "skippedChallenge")
        }
    }
    
    //==================================================//
    
    /* Other Functions */
    
    func incompleteChallengesForToday(completion: @escaping(_ returnedChallenge: [Challenge]?, _ errorDescriptor: String?) -> Void)
    {
        ChallengeSerialiser().getChallenges(forDate: Date()) { (returnedIdentifiers, errorDescriptor) in
            if let identifiers = returnedIdentifiers
            {
                if identifiers.count == 0
                {
                    completion([], nil)
                }
                else
                {
                    ChallengeSerialiser().getChallenges(withIdentifiers: identifiers) { (returnedChallenges, errorDescriptors) in
                        if let challenges = returnedChallenges
                        {
                            if let completedChallenges = currentUser.completedChallenges(on: currentTeam)
                            {
                                var filteredChallenges: [Challenge] = []
                                
                                for challenge in challenges
                                {
                                    if !completedChallenges.contains(where: {$0.challenge.associatedIdentifier == challenge.associatedIdentifier})
                                    {
                                        if let skippedIdentifier = UserDefaults.standard.value(forKey: "skippedChallenge") as? String
                                        {
                                            if challenge.associatedIdentifier == skippedIdentifier
                                            {
                                                print("User skipped this one!")
                                            }
                                            else
                                            {
                                                filteredChallenges.append(challenge)
                                            }
                                        }
                                        else
                                        {
                                            filteredChallenges.append(challenge)
                                        }
                                    }
                                }
                                
                                completion(filteredChallenges, nil)
                            }
                            else { completion(challenges, nil) }
                        }
                        else if let errors = errorDescriptors
                        {
                            completion(nil, errors.joined(separator: "\n"))
                        }
                    }
                }
            }
            else if let error = errorDescriptor
            {
                completion(nil, error)
            }
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }
    
    func setUpChallengeView(for challenge: Challenge)
    {
        currentChallenge = challenge
        
        if let tournament = currentTeam.associatedTournament
        {
            let start = tournament.startDate.comparator
            let end = tournament.endDate.comparator
            let today = Date().comparator
            
            if end > today
            {
                let components = Calendar.current.dateComponents([.day], from: start, to: today)
                let day = components.day!
                
                titleLabel.text = "DAY \(day)"
            }
            else { report("Tournament has ended!", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]) }
        }
        
        promptTextView.text = challenge.prompt!
        pointValueLabel.text = "+\(challenge.pointValue!) POINTS"
        subtitleLabel.text = "⚡️ \(challenge.title!) ⚡️"
        
        doneButton.setTitle("I did it! (+\(challenge.pointValue!))", for: .normal)
        
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.cornerRadius = 5
        imageView.clipsToBounds = true
        
        webView.layer.borderWidth = 1
        webView.layer.borderColor = UIColor.white.cgColor
        webView.layer.cornerRadius = 5
        webView.clipsToBounds = true
        
        if let media = challenge.media
        {
            switch media.type
            {
            case .gif:
                webView.alpha = 0
                imageView.setGifFromURL(media.link)
            case .staticImage:
                webView.alpha = 0
                imageView.downloadedFrom(url: media.link)
            case .video:
                imageView.alpha = 0
                webView.load(URLRequest(url: media.link))
            }
        }
        else
        {
            webView.alpha = 0
            noMediaLabel.alpha = 1
        }
        
        UIView.animate(withDuration: 0.2) { self.challengeView.alpha = 1 }
    }
}
