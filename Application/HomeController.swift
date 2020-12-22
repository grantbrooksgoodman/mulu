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

class HomeController: UIViewController, MFMailComposeViewControllerDelegate, UICollectionViewDelegateFlowLayout
{
    //==================================================//
    
    /* Interface Builder UI Elements */
    
    //UILabels
    @IBOutlet weak var welcomeLabel:     UILabel!
    
    //UITextViews
    @IBOutlet weak var statisticsTextView: UITextView!
    
    //Other Elements
    @IBOutlet weak var collectionView: UICollectionView!
    
    //==================================================//
    
    /* Class-level Variable Declarations */
    
    var buildInstance: Build!
    var currentChallenge: Challenge?
    
    var incompleteChallenges: [Challenge] = []
    
    var noChallengeString = "No new challenges have been posted for today.\n\nCheck back later!"
    
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
        
        welcomeLabel.text = "WELCOME BACK \(currentUser.firstName!.uppercased())!"
        welcomeLabel.font = UIFont(name: "Gotham-Black", size: 32)!
        
        reloadData()
        
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        
    }
    
    //==================================================//
    
    /* Interface Builder Actions */
    
    @IBAction func skippedButton(_ sender: Any)
    {
        //        if let challenge = currentChallenge
        //        {
        //            UserDefaults.standard.setValue(challenge.associatedIdentifier, forKey: "skippedChallenge")
        //
        //            HUD.flash(.success, delay: 1.0) { finished in
        //                for subview in self.challengeView.subviews
        //                {
        //                    subview.alpha = 0
        //                }
        //
        //                self.noChallengeLabel.text = "You skipped today's challenge.\n\nCheck back later for more!"
        //
        //                UIView.animate(withDuration: 0.2) {
        //                    self.noChallengeLabel.alpha = 1
        //                }
        //            }
        //        }
    }
    
    //==================================================//
    
    /* Other Functions */
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let screenWidth = UIScreen.main.bounds.width
        let width = screenWidth == 375 ? 365 : 388
        
        return CGSize(width: width, height: 506)
    }
    
    func reloadData()
    {
        incompleteChallengesForToday { (returnedChallenges, errorDescriptor) in
            if let challenges = returnedChallenges
            {
                self.incompleteChallenges = challenges
                
                self.collectionView.dataSource = self
                self.collectionView.delegate = self
                
                self.collectionView.reloadData()
            }
            else if let error = errorDescriptor
            {
                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
        }
    }
    
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
                                                self.noChallengeString = "You skipped today's challenge.\n\nCheck back later for more!"
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
                            else
                            {
                                var filteredChallenges: [Challenge] = []
                                
                                for challenge in challenges
                                {
                                    if let skippedIdentifier = UserDefaults.standard.value(forKey: "skippedChallenge") as? String
                                    {
                                        if challenge.associatedIdentifier == skippedIdentifier
                                        {
                                            self.noChallengeString = "You skipped today's challenge.\n\nCheck back later for more!"
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
                                
                                completion(filteredChallenges, nil)
                            }
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
}

extension HomeController: UICollectionViewDataSource, UICollectionViewDelegate
{
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return incompleteChallenges.count == 0 ? 1 : incompleteChallenges.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let challengeCell = collectionView.dequeueReusableCell(withReuseIdentifier: "challengeCell", for: indexPath) as! ChallengeCell
        
        roundCorners(forViews: [challengeCell], withCornerType: 0)
        
        challengeCell.doneButton.layer.cornerRadius = 5
        challengeCell.skippedButton.layer.cornerRadius = 5
        
        challengeCell.noChallengeLabel.text = noChallengeString
        
        if incompleteChallenges.count > 0
        {
            challengeCell.challengeIdentifier = incompleteChallenges[indexPath.row].associatedIdentifier
            
            if let tournament = currentTeam.associatedTournament
            {
                let start = tournament.startDate.comparator
                let end = tournament.endDate.comparator
                let today = Date().comparator
                
                if end > today
                {
                    let components = Calendar.current.dateComponents([.day], from: start, to: today)
                    let day = components.day!
                    
                    challengeCell.titleLabel.text = "DAY \(day)"
                }
                else { report("Tournament has ended!", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]) }
            }
            
            challengeCell.promptTextView.text = incompleteChallenges[indexPath.row].prompt!
            challengeCell.pointValueLabel.text = "+\(incompleteChallenges[indexPath.row].pointValue!) POINTS"
            challengeCell.subtitleLabel.text = "⚡️ \(incompleteChallenges[indexPath.row].title!) ⚡️"
            
            challengeCell.doneButton.setTitle("I did it! (+\(incompleteChallenges[indexPath.row].pointValue!))", for: .normal)
            
            challengeCell.imageView.layer.borderWidth = 1
            challengeCell.imageView.layer.borderColor = UIColor.white.cgColor
            challengeCell.imageView.layer.cornerRadius = 5
            challengeCell.imageView.clipsToBounds = true
            
            challengeCell.webView.layer.borderWidth = 1
            challengeCell.webView.layer.borderColor = UIColor.white.cgColor
            challengeCell.webView.layer.cornerRadius = 5
            challengeCell.webView.clipsToBounds = true
            
            if let media = incompleteChallenges[indexPath.row].media
            {
                switch media.type
                {
                case .gif:
                    challengeCell.webView.alpha = 0
                    challengeCell.imageView.setGifFromURL(media.link)
                case .staticImage:
                    challengeCell.webView.alpha = 0
                    challengeCell.imageView.downloadedFrom(url: media.link)
                case .video:
                    challengeCell.imageView.alpha = 0
                    challengeCell.webView.load(URLRequest(url: media.link))
                }
            }
            else
            {
                challengeCell.webView.alpha = 0
                challengeCell.noMediaLabel.alpha = 1
            }
        }
        else
        {
            for subview in challengeCell.encapsulatingView.subviews
            {
                subview.alpha = 0
            }
            
            UIView.animate(withDuration: 0.2) {
                challengeCell.noChallengeLabel.alpha = 1
                challengeCell.contentView.alpha = 1
            }
        }
        
        let screenWidth = UIScreen.main.bounds.width
        
        if screenWidth == 375
        {
            challengeCell.encapsulatingView.center.x = challengeCell.center.x - 5
        }
        else if screenWidth == 390
        {
            challengeCell.encapsulatingView.center.x = challengeCell.center.x
        }
        
        challengeCell.layoutIfNeeded()
        
        return challengeCell
    }
}
