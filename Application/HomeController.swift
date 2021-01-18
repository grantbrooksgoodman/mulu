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
import SwiftyGif

class HomeController: UIViewController, MFMailComposeViewControllerDelegate, UICollectionViewDelegateFlowLayout
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    //UILabels
    @IBOutlet var welcomeLabel: UILabel!

    //UITextViews
    @IBOutlet var statisticsTextView: UITextView!

    //Other Elements
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var settingsButton: UIButton!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    //Other Declarations
    override var canBecomeFirstResponder: Bool {
        return true
    }

    var buildInstance: Build!
    var currentChallenge: Challenge?
    var incompleteChallenges = [Challenge]()
    var refreshControl: UIRefreshControl?

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

        initializeController()

        view.setBackground(withImageNamed: "Gradient.png")

        collectionView.alwaysBounceVertical = true

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(HomeController.reloadData), for: .valueChanged)

        self.refreshControl = refreshControl
        collectionView.addSubview(self.refreshControl!)

        NotificationCenter.default.addObserver(forName: UIWindow.didResignKeyNotification, object: view.window, queue: nil) { _ in
            (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .all
        }

        NotificationCenter.default.addObserver(forName: UIWindow.didBecomeKeyNotification, object: view.window, queue: nil) { _ in
            (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .portrait

            if let cells = self.collectionView.visibleCells as? [ChallengeCell]
            {
                for cell in cells
                {
                    if cell.tikTokVideoLink != nil
                    {
                        cell.webView.alpha = 0
                        cell.playButton.alpha = 1
                    }
                }
            }
        }

        welcomeLabel.text = "WELCOME BACK \(currentUser.firstName!.uppercased())!"
        welcomeLabel.font = UIFont(name: "Gotham-Black", size: 32)!

        collectionView.alpha = 0

        setVisualTeamInformation()
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        currentFile = #file
        buildInfoController?.view.isHidden = !preReleaseApplication
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with _: UIEvent?)
    {
        if motion == .motionShake
        {
            AlertKit().confirmationAlertController(title: "Sign Out", message: "Would you like to sign out?", cancelConfirmTitles: [:], confirmationDestructive: false, confirmationPreferred: true, networkDepedent: true) { didConfirm in
                if let confirmed = didConfirm, confirmed
                {
                    self.performSegue(withIdentifier: "SignInFromHomeSegue", sender: self)
                }
            }
        }
    }

    override func prepare(for _: UIStoryboardSegue, sender _: Any?)
    {}

    //==================================================//

    /* MARK: Interface Builder Actions */

    @IBAction func settingsButton(_: Any)
    {
        AlertKit().optionAlertController(title: "Preferences", message: "What would you like to do?", cancelButtonTitle: nil, additionalButtons: [("Sign Out", false), ("Sign In to Different Team", false)], preferredActionIndex: nil, networkDependent: true) { selectedIndex in
            if let index = selectedIndex
            {
                if index == 0
                {
                    self.signOut()
                }
                else if index == 1
                {
                    showProgressHUD()

                    currentUser!.deSerializeAssociatedTeams { returnedTeams, errorDescriptor in
                        if let teams = returnedTeams
                        {
                            if teams.count == 1
                            {
                                hideHUD(delay: 0.2) { self.errorAlert(title: "Error", message: "You are currently not a member of any other team.") }
                            }
                            else if teams.count > 1
                            {
                                hideHUD(delay: 0.2) { self.teamSelectionActionSheet(teams: teams) }
                            }
                        }
                        else
                        {
                            hideHUD(delay: 0.2) { AlertKit().errorAlertController(title: "Couldn't Get Teams",
                                                                                  message: errorDescriptor!,
                                                                                  dismissButtonTitle: nil,
                                                                                  additionalSelectors: nil,
                                                                                  preferredAdditionalSelector: nil,
                                                                                  canFileReport: true,
                                                                                  extraInfo: errorDescriptor!,
                                                                                  metadata: [#file, #function, #line],
                                                                                  networkDependent: true) }
                        }
                    }
                }
            }
        }
    }

    //==================================================//

    /* MARK: Other Functions */

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize
    {
        let screenWidth = UIScreen.main.bounds.width
        let width = screenWidth == 375 ? 365 : 388

        return CGSize(width: width, height: 506)
    }

    func didCompleteChallenge(withIdentifier: String) -> Bool
    {
        if let completedChallenges = currentUser.completedChallenges(on: currentTeam),
           completedChallenges.contains(where: { $0.challenge.associatedIdentifier == withIdentifier })
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

    func errorAlert(title: String, message: String)
    {
        AlertKit().errorAlertController(title:                       title,
                                        message:                     message,
                                        dismissButtonTitle:          nil,
                                        additionalSelectors:         nil,
                                        preferredAdditionalSelector: nil,
                                        canFileReport:               true,
                                        extraInfo:                   message,
                                        metadata:                    [#file, #function, #line],
                                        networkDependent:            true)
    }

    func incompleteChallengesForToday(completion: @escaping (_ returnedChallenges: [Challenge]?, _ errorDescriptor: String?) -> Void)
    {
        guard let tournament = currentTeam.associatedTournament else
        { completion(nil, "This Team is not currently participating in a Tournament."); return }

        ChallengeSerializer().getChallenges(forTournament: tournament.associatedIdentifier, forDate: Date()) { returnedChallenges, errorDescriptor in
            if let challenges = returnedChallenges
            {
                var filteredChallenges = [Challenge]()

                for challenge in challenges
                {
                    if !self.didCompleteChallenge(withIdentifier: challenge.associatedIdentifier) && !self.didSkipChallenge(withIdentifier: challenge.associatedIdentifier)
                    {
                        filteredChallenges.append(challenge)
                    }
                }

                completion(filteredChallenges, nil)
            }
            else { completion(nil, errorDescriptor!) }
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }

    @objc func reloadData()
    {
        currentTeam.reloadData { errorDescriptor in
            self.refreshControl?.endRefreshing()

            if let error = errorDescriptor
            {
                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
            else
            {
                self.incompleteChallengesForToday { returnedChallenges, errorDescriptor in
                    if let challenges = returnedChallenges
                    {
                        self.incompleteChallenges = challenges.sorted(by: { $0.title < $1.title }).sorted(by: { $0.datePosted < $1.datePosted })

                        self.collectionView.dataSource = self
                        self.collectionView.delegate = self

                        self.collectionView.reloadData()
                    }
                    else if let error = errorDescriptor
                    {
                        if error == "This Tournament has no Challenges associated with it." || error == "No Challenges for this Tournament on the specified date."
                        {
                            self.collectionView.dataSource = self
                            self.collectionView.delegate = self

                            self.collectionView.reloadData()
                        }
                        else { report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
                    }
                }
            }
        }
    }

    func setVisualTeamInformation()
    {
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

    func signOut()
    {
        AlertKit().confirmationAlertController(title: "Sign Out?", message: "Are you sure you would like to sign out?", cancelConfirmTitles: [:], confirmationDestructive: false, confirmationPreferred: true, networkDepedent: true) { didConfirm in
            if let confirmed = didConfirm,
               confirmed
            {
                do {
                    try Auth.auth().signOut()

                    currentUser = nil
                    currentTeam = nil

                    self.performSegue(withIdentifier: "SignInFromHomeSegue", sender: self)
                }
                catch {
                    report(errorInfo(error), errorCode: (error as NSError).code, isFatal: true, metadata: [#file, #function, #line])
                }
            }
        }
    }

    func switchTeam(_ team: Team)
    {
        team.deSerializeParticipants { returnedUsers, errorDescriptor in
            if returnedUsers != nil
            {
                if let tournament = team.associatedTournament
                {
                    tournament.deSerializeTeams { returnedTeams, errorDescriptor in
                        if returnedTeams != nil
                        {
                            currentTeam = team

                            self.incompleteChallenges = []
                            self.currentChallenge = nil

                            self.setVisualTeamInformation()
                            self.reloadData()
                        }
                        else { report(errorDescriptor!, errorCode: nil, isFatal: true, metadata: [#file, #function, #line]) }
                    }
                }
                else
                {
                    currentTeam = team

                    self.reloadData()
                }
            }
            else { report(errorDescriptor!, errorCode: nil, isFatal: true, metadata: [#file, #function, #line]) }
        }
    }

    func teamSelectionActionSheet(teams: [Team])
    {
        let actionSheet = UIAlertController(title: "Switch Team", message: "Select the team you would like to sign in to.", preferredStyle: .actionSheet)

        for team in teams.sorted(by: { $0.name < $1.name })
        {
            let teamAction = UIAlertAction(title: team.name!, style: .default) { _ in
                self.switchTeam(team)
            }

            actionSheet.addAction(teamAction)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // It will dismiss action sheet
        }

        actionSheet.addAction(cancelAction)

        present(actionSheet, animated: true, completion: nil)
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
        } completion: { _ in
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

        if !incompleteChallenges.isEmpty
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

                challengeCell.webView.loadHTMLString("", baseURL: nil)

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
                case .tikTokVideo:
                    challengeCell.imageView.alpha = 0
                    challengeCell.playButton.alpha = challengeCell.webView.url != media.link ? 1 : 0

                    challengeCell.webView.isOpaque = false
                    challengeCell.webView.isUserInteractionEnabled = false

                    challengeCell.tikTokVideoLink = media.link
                }
            }
            else
            {
                challengeCell.webView.alpha = 0
                challengeCell.imageView.alpha = 0
                challengeCell.playButton.alpha = 0
                challengeCell.noMediaLabel.alpha = 1
            }
        }
        else { toggleChallengeElements(hidden: true, onView: challengeCell.encapsulatingView) }

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

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int
    {
        return incompleteChallenges.isEmpty ? 1 : incompleteChallenges.count
    }

    func numberOfSections(in _: UICollectionView) -> Int
    {
        return 1
    }
}

//--------------------------------------------------//

/* MARK: Array Extensions */
extension Array where Element == (challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])
{
    func accruedPoints(for userIdentifier: String) -> Int
    {
        var total = 0

        for challengeTuple in self
        {
            for user in challengeTuple.metadata.users()
            {
                if user.associatedIdentifier == userIdentifier
                {
                    total += challengeTuple.challenge.pointValue
                }
            }
        }

        return total
    }

    func challengeIdentifiers() -> [String]
    {
        var challengeIdentifiers = [String]()

        for challengeTuple in self
        {
            challengeIdentifiers.append(challengeTuple.challenge.associatedIdentifier)
        }

        return challengeIdentifiers
    }

    func users() -> [User]
    {
        var users = [User]()

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
        var users = [User]()

        for tuple in self
        {
            users.append(tuple.user)
        }

        return users
    }
}
