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
    
    /* MARK: Interface Builder UI Elements */
    
    //UILabels
    @IBOutlet weak var welcomeLabel: UILabel!
    
    //UITextViews
    @IBOutlet weak var statisticsTextView: UITextView!
    
    //Other Elements
    @IBOutlet weak var collectionView: UICollectionView!
    
    //==================================================//
    
    /* MARK: Class-level Variable Declarations */
    
    //Other Declarations
    var buildInstance: Build!
    var currentChallenge: Challenge?
    var incompleteChallenges: [Challenge] = []
    var refreshControl: UIRefreshControl?
    
    //==================================================//
    
    /* MARK: Initialiser Function */
    
    func initialiseController()
    {
        lastInitialisedController = self
        buildInstance = Build(self)
    }
    
    //==================================================//
    
    /* MARK: Overridden Functions */
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        initialiseController()
        
        view.setBackground(withImageNamed: "Gradient.png")
        
        collectionView.alwaysBounceVertical = true
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(HomeController.reloadData), for: .valueChanged)
        
        self.refreshControl = refreshControl
        collectionView.addSubview(self.refreshControl!)
        
        NotificationCenter.default.addObserver(forName: UIWindow.didResignKeyNotification, object: view.window, queue: nil) { (notification) in
            (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .all
        }
        
        NotificationCenter.default.addObserver(forName: UIWindow.didBecomeKeyNotification, object: view.window, queue: nil) { (notification) in
            (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .portrait
        }
        
        welcomeLabel.text = "WELCOME BACK \(currentUser.firstName!.uppercased())!"
        welcomeLabel.font = UIFont(name: "Gotham-Black", size: 32)!
        
        collectionView.alpha = 0
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
    
    /* MARK: Interface Builder Actions */
    
    //==================================================//
    
    /* MARK: Other Functions */
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let screenWidth = UIScreen.main.bounds.width
        let width = screenWidth == 375 ? 365 : 388
        
        return CGSize(width: width, height: 506)
    }
    
    func didCompleteChallenge(withIdentifier: String) -> Bool
    {
        if let completedChallenges = currentUser.completedChallenges(on: currentTeam),
           completedChallenges.contains(where: {$0.challenge.associatedIdentifier == withIdentifier})
        {
            return true
        }
        
        return false
    }
    
    func didSkipChallenge(withIdentifier: String) -> Bool
    {
        if let skippedIdentifiers = UserDefaults.standard.value(forKey: "skippedChallenges") as? [String],
           skippedIdentifiers.contains(withIdentifier)
        {
            return true
        }
        
        return false
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
                            var filteredChallenges: [Challenge] = []
                            
                            for challenge in challenges
                            {
                                if !self.didCompleteChallenge(withIdentifier: challenge.associatedIdentifier) && !self.didSkipChallenge(withIdentifier: challenge.associatedIdentifier)
                                {
                                    filteredChallenges.append(challenge)
                                }
                            }
                            
                            completion(filteredChallenges, nil)
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
    
    @objc func reloadData()
    {
        currentTeam.reloadData { (errorDescriptor) in
            self.refreshControl?.endRefreshing()
            
            if let error = errorDescriptor
            {
                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
            else
            {
                self.incompleteChallengesForToday { (returnedChallenges, errorDescriptor) in
                    if let challenges = returnedChallenges
                    {
                        self.incompleteChallenges = challenges.sorted(by: {$0.title < $1.title}).sorted(by: {$0.datePosted < $1.datePosted})
                        
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
        }
    }
    
    func toggleChallengeElements(hidden: Bool, onView: UIView)
    {
        UIView.animate(withDuration: 0.2) {
            for subview in onView.subviews
            {
                if hidden
                {
                    switch subview.tag
                    {
                    case aTagFor("noChallengeLabel"):
                        subview.alpha = 1
                    default:
                        subview.alpha = 0
                    }
                }
                else
                {
                    switch subview.tag
                    {
                    case aTagFor("noMediaLabel"):
                        subview.alpha = 0
                    case aTagFor("noChallengeLabel"):
                        subview.alpha = 0
                    default:
                        subview.alpha = 1
                    }
                }
            }
        } completion: { (_) in
            UIView.animate(withDuration: 0.2) { self.collectionView.alpha = 1 }
        }
    }
}

//==================================================//

/* MARK: Extensions */

/**/

/* MARK: UICollectionViewDataSource, UICollectionViewDelegate */
extension HomeController: UICollectionViewDataSource, UICollectionViewDelegate
{
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let challengeCell = collectionView.dequeueReusableCell(withReuseIdentifier: "challengeCell", for: indexPath) as! ChallengeCell
        
        roundCorners(forViews: [challengeCell], withCornerType: 0)
        
        challengeCell.doneButton.layer.cornerRadius = 5
        challengeCell.skippedButton.layer.cornerRadius = 5
        
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
                    let dayComponents = Calendar.current.dateComponents([.day], from: start, to: today)
                    let day = dayComponents.day!
                    
                    let durationComponents = Calendar.current.dateComponents([.day], from: start, to: end)
                    let duration = durationComponents.day!
                    
                    challengeCell.titleLabel.text = "DAY \(day) OF \(duration)"
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
            
            toggleChallengeElements(hidden: false, onView: challengeCell.encapsulatingView)
            
            if let media = incompleteChallenges[indexPath.row].media
            {
                challengeCell.playButton.alpha = 0
                
                switch media.type
                {
                case .gif:
                    challengeCell.webView.alpha = 0
                    challengeCell.imageView.setGifFromURL(media.link)
                case .staticImage:
                    challengeCell.webView.alpha = 0
                    challengeCell.imageView.downloadedFrom(url: media.link, contentMode: .scaleAspectFit)
                case .linkedVideo:
                    challengeCell.imageView.alpha = 0
                    challengeCell.webView.load(URLRequest(url: media.link))
                case .autoPlayVideo:
                    challengeCell.imageView.alpha = 0
                    challengeCell.playButton.alpha = challengeCell.webView.url != media.link ? 1 : 0
                    
                    challengeCell.webView.isOpaque = false
                    challengeCell.webView.isUserInteractionEnabled = false
                    
                    challengeCell.autoPlayVideoLink = media.link
                }
            }
            else
            {
                challengeCell.webView.alpha = 0
                challengeCell.imageView.alpha = 0
                challengeCell.noMediaLabel.alpha = 1
            }
        }
        else
        { toggleChallengeElements(hidden: true, onView: challengeCell.encapsulatingView) }
        
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return incompleteChallenges.count == 0 ? 1 : incompleteChallenges.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }
}

//--------------------------------------------------//

/* MARK: Array Extensions */
extension Array where Element == (challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])
{
    func users() -> [User]
    {
        var users: [User] = []
        
        for challengeTuple in self
        {
            users.append(contentsOf: challengeTuple.metadata.users())
        }
        
        return users
    }
}

extension Array where Element == (user: User, dateCompleted: Date)
{
    func users() -> [User]
    {
        var users: [User] = []
        
        for tuple in self
        {
            users.append(tuple.user)
        }
        
        return users
    }
}
