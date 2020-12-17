//
//  TeamController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 09/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

/* Third-party Frameworks */
import JTAppleCalendar

class TeamController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//
    
    /* Interface Builder UI Elements */
    
    //UILabels
    @IBOutlet weak var titleLabel:  UILabel!
    
    //Other Elements
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var statisticsTextView: UITextView!
    
    //==================================================//
    
    /* Class-level Variable Declarations */
    
    var buildInstance: Build!
    var completedChallenges: [(date: Date, challenge: Challenge)]?
    
    var user: User!
    
    var currentTournament: Tournament?
    
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
        
        //        GenericTestingSerialiser().trashDatabase()
        //
        //        GenericTestingSerialiser().createRandomDatabase(numberOfUsers: 5, numberOfChallenges: 8, numberOfTeams: 6) { (errorDescriptor) in
        //            if let error = errorDescriptor
        //            {
        //                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
        //            }
        //            else { report("Successfully created database.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
        //        }
        
        //                TeamSerialiser().addTeam("-MOgVb7GotNCpATLyt05", toTournament: "-MOgVbAkCt8BQpqdLM4Y") { (errorDescriptor) in
        //                    if let error = errorDescriptor
        //                    {
        //                        report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
        //                    }
        //                }
        
        guard currentUser != nil else
        { report("No current User!", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]); return }
        
        user = currentUser
        
        guard user.DSAssociatedTeams != nil else
        { user.setDSAssociatedTeams(); return }
        
        titleLabel.text = user.DSAssociatedTeams![0].name.uppercased()
        
        var rankString: String?
        
        if let teams = user.DSAssociatedTeams,
           let havingAssociatedTournament = teams.first(where: {$0.associatedTournament != nil}),
           let tournament = havingAssociatedTournament.associatedTournament
        {
            currentTournament = tournament
            
            currentTournament!.setDSTeams()
            
            havingAssociatedTournament.getRank() { (returnedRank, errorDescriptor) in
                if let rank = returnedRank
                {
                    rankString = "\(rank.ordinalValue.uppercased()) PLACE in \(tournament.name!.uppercased())"
                    
                    let mainStatAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Montserrat-Bold", size: 18)!]
                    let otherStatAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Montserrat-SemiBold", size: 14)!]
                    
                    let statisticString = NSMutableAttributedString(string: "\(rankString == nil ? "4TH PLACE, 12500 PTS" : rankString!)\n\n", attributes: mainStatAttributes)
                    
                    havingAssociatedTournament.deSerialiseParticipants { (returnedUsers, errorDescriptor) in
                        if let users = returnedUsers
                        {
                            for user in users
                            {
                                var points = havingAssociatedTournament.accruedPoints(for: user.associatedIdentifier)
                                
                                points = points == -1 ? 0 : points
                                
                                statisticString.append(NSMutableAttributedString(string: "+ \(user.firstName!) \(user.lastName!), \(points) pts\n", attributes: otherStatAttributes))
                            }
                            
                            self.statisticsTextView.attributedText = statisticString
                        }
                        else { report(errorDescriptor!, errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
                    }
                }
                else { report(errorDescriptor!, errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if let user = currentUser
        {
            user.deSerialiseAssociatedTeams { (returnedTeams, errorDescriptor) in
                if let error = errorDescriptor
                {
                    report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                }
                else
                {
                    if let challenges = user.completedChallenges()
                    {
                        self.completedChallenges = challenges
                        
                        self.collectionView.dataSource = self
                        self.collectionView.delegate = self
                    }
                    else { report("Couldn't get completed Challenges.", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]) }
                }
            }
        }
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
    
    //==================================================//
    
    /* Other Functions */
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }
}

extension TeamController: JTAppleCalendarViewDataSource
{
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MM dd"
        
        let startDate = formatter.date(from: "2020 12 01")!
        let endDate = Date()
        
        return ConfigurationParameters(startDate: startDate, endDate: endDate, numberOfRows: 7, calendar: Calendar.current, generateInDates: .off, generateOutDates: .off, firstDayOfWeek: nil, hasStrictBoundaries: true)
    }
}

extension TeamController: JTAppleCalendarViewDelegate
{
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell
    {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "dateCell", for: indexPath) as! DateCell
        
        if let challenges = completedChallenges, challenges.dates().contains(Calendar.current.startOfDay(for: date))
        {
            cell.titleLabel.text = "🔥"
        }
        else
        {
            cell.titleLabel.text = cellState.text
        }
        
        cell.layer.cornerRadius = cell.frame.width / 2
        
        if cellState.date > Date()
        {
            cell.backgroundColor = .black
            cell.tintColor = .black
        }
        
        return cell
    }
    
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath)
    {
        let cell = cell as! DateCell
        cell.titleLabel.text = cellState.text
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo)
    {
        calendar.reloadData(withanchor: visibleDates.monthDates.first!.date, completionHandler: nil)
    }
}

extension TeamController: UICollectionViewDataSource, UICollectionViewDelegate
{
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let scrollerCell = collectionView.dequeueReusableCell(withReuseIdentifier: "scrollCell", for: indexPath) as! ScrollerCell
        
        if indexPath.row == 1
        {
            for view in scrollerCell.subviews
            {
                view.removeFromSuperview()
            }
            
            let encapsulatingView = UIView(frame: scrollerCell.bounds)
            encapsulatingView.alpha = 0.75
            encapsulatingView.backgroundColor = UIColor(hex: 0x353635)
            roundCorners(forViews: [encapsulatingView], withCornerType: 0)
            
            let leaderboardLabel = UILabel(frame: CGRect(x: scrollerCell.center.x, y: 20, width: scrollerCell.frame.width, height: 30))
            leaderboardLabel.font = UIFont(name: "SFUIText-Bold", size: 30)
            
            leaderboardLabel.text = "LEADERBOARD"
            leaderboardLabel.textAlignment = .center
            leaderboardLabel.textColor = .white
            
            encapsulatingView.addSubview(leaderboardLabel)
            leaderboardLabel.center.x = encapsulatingView.center.x
            
            let scoreLabel = UILabel(frame: CGRect(x: 0, y: 30, width: scrollerCell.frame.width, height: scrollerCell.frame.height - 30))
            
            scoreLabel.font = UIFont(name: "Montserrat-Bold", size: 17)
            scoreLabel.numberOfLines = 10
            
            scoreLabel.textAlignment = .center
            scoreLabel.textColor = .white
            
            if let tournament = currentTournament,
               let leaderboard = tournament.leaderboard()
            {
                var leaderboardString = ""
                
                for (index, metadata) in leaderboard.enumerated()
                {
                    leaderboardString.append("\(index + 1). \(metadata.team.name!.uppercased())     \(metadata.points) PTS\n")
                }
                
                scoreLabel.text = leaderboardString
            }
            else
            {
                scoreLabel.text = "1. TEAM PIERCE                               15500 PTS\n2. TEAM TILE                                     13400 PTS"
            }
            
            encapsulatingView.addSubview(scoreLabel)
            scoreLabel.center.x = encapsulatingView.center.x
            
            scrollerCell.addSubview(encapsulatingView)
            scrollerCell.bringSubviewToFront(encapsulatingView)
        }
        else
        {
            roundCorners(forViews: [scrollerCell], withCornerType: 0)
            
            //            scrollerCell.subviews[0].backgroundColor = UIColor(hex: 0x353635)
            //            scrollerCell.subviews[0].alpha = 0.79
            roundCorners(forViews: [scrollerCell.subviews[0]], withCornerType: 4)
            
            if let streakLabel = scrollerCell.subviews[0].subview(aTagFor("streakLabel"))
            {
                //streakLabel.backgroundColor = UIColor(hex: 0x353635)
                roundCorners(forViews: [streakLabel], withCornerType: 3)
            }
        }
        
        scrollerCell.layoutIfNeeded()
        
        return scrollerCell
    }
}

extension Array where Element == (Challenge, [(User, Date)])
{
    func dates() -> [Date]
    {
        var dates: [Date] = []
        
        for challengeTuple in self
        {
            for datum in challengeTuple.1
            {
                dates.append(datum.1)
            }
        }
        
        return dates
    }
}

extension Array where Element == (date: Date, challenge: Challenge)
{
    func dates() -> [Date]
    {
        var dates: [Date] = []
        
        for tuple in self
        {
            dates.append(Calendar.current.startOfDay(for: tuple.date))
        }
        
        return dates
    }
}
