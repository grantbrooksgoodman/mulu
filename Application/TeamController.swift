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

class TeamController: UIViewController, MFMailComposeViewControllerDelegate, UICollectionViewDelegateFlowLayout
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    //UILabels
    @IBOutlet var titleLabel:  UILabel!

    //Other Elements
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var statisticsTextView: UITextView!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    var buildInstance: Build!
    var completedChallenges: [(date: Date, challenge: Challenge)]?

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

        if let tournament = currentTeam.associatedTournament
        {
            deserializeTeamsAndReload(tournament)
        }
        else { setVisualTeamInformation() }
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        initializeController()

        currentFile = #file
        buildInfoController?.view.isHidden = !preReleaseApplication

        let screenHeight = UIScreen.main.bounds.height
        buildInfoController?.customYOffset = (screenHeight <= 736 ? 35 : 70)

        if let tournament = currentTeam.associatedTournament
        {
            deserializeTeamsAndReload(tournament)
        }
        else { setVisualTeamInformation() }
    }

    override func prepare(for _: UIStoryboardSegue, sender _: Any?)
    {}

    //==================================================//

    /* MARK: Interface Builder Actions */

    //==================================================//

    /* MARK: Other Functions */

    func calculateTeamStatistics(withRankString: Bool, completion: @escaping (_ statisticsString: NSAttributedString?, _ errorDescriptor: String?) -> Void)
    {
        let mainStatisticsAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Montserrat-Bold", size: 18)!]
        let otherStatisticsAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Montserrat-SemiBold", size: 14)!]

        var rankArray = [(user: User, points: Int)]()

        currentTeam.deSerializeParticipants { returnedUsers, errorDescriptor in
            if let users = returnedUsers
            {
                for user in users
                {
                    var points = currentTeam.getAccruedPoints(for: user.associatedIdentifier)

                    points = points == -1 ? 0 : points
                    if let additionalPoints  = currentTeam.participantIdentifiers[user.associatedIdentifier] {
                        points += additionalPoints
                    }

                    rankArray.append((user, points))
                }

                rankArray = rankArray.sorted(by: { $0.points > $1.points })

                if let currentUserRank = rankArray.firstIndex(where: { $0.user.associatedIdentifier == currentUser.associatedIdentifier })
                {
                    let currentUserPoints = rankArray[currentUserRank].points

                    let rankString = "\((currentUserRank + 1).ordinalValue.uppercased()) PLACE, \(currentUserPoints) PTS"

                    var initialStatisticsString = "\(rankString)\n\n"

                    if !withRankString
                    {
                        initialStatisticsString = ""
                    }

                    let statisticsString = NSMutableAttributedString(string: initialStatisticsString, attributes: mainStatisticsAttributes)

                    //rankArray.remove(at: currentUserRank)

                    for tuple in rankArray
                    {
                        let name = tuple.user.associatedIdentifier == currentUser.associatedIdentifier ? "YOU" : "\(tuple.user.firstName!) \(tuple.user.lastName!)"

                        statisticsString.append(NSMutableAttributedString(string: "+ \(name), \(tuple.points) pts\n", attributes: otherStatisticsAttributes))
                    }

                    completion(statisticsString, nil)
                }
                else { completion(nil, "Couldn't find User in rank array.") }
            }
            else { completion(nil, errorDescriptor!) }
        }
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize
    {
        let screenWidth = UIScreen.main.bounds.width
        let width = screenWidth == 375 ? 365 : (screenWidth == 390 ? 380 : 400)

        return CGSize(width: width, height: 356)
    }

    func deserializeTeamsAndReload(_ tournament: Tournament)
    {
        tournament.deSerializeTeams { returnedTeams, errorDescriptor in
            if returnedTeams != nil
            {
                self.setVisualTeamInformation()
            }
            else { report(errorDescriptor!, errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }

    func setVisualTeamInformation()
    {
        titleLabel.text = currentTeam.name.uppercased()

        if let calendarCell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? ScrollerCell,
           let JTAppleCalendar = calendarCell.subviews[0].subviews[0] as? JTAppleCalendarView
        {
            JTAppleCalendar.ibCalendarDelegate = self
            JTAppleCalendar.ibCalendarDataSource = self

            JTAppleCalendar.reloadData()

            for cell in JTAppleCalendar.visibleCells
            {
                cell.backgroundColor = UIColor(hex: 0x818A5C)
            }
        }

        calculateTeamStatistics(withRankString: currentTeam.associatedTournament == nil) { statisticsString, errorDescriptor in
            if let string = statisticsString
            {
                if let tournament = currentTeam.associatedTournament,
                   let leaderboard = tournament.leaderboard(),
                   let index = leaderboard.firstIndex(where: { $0.team.associatedIdentifier == currentTeam.associatedIdentifier })
                {
                    let mainStatisticsAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Montserrat-Bold", size: 18)!]

                    let rankString = "\((index + 1).ordinalValue.uppercased()) PLACE, \(leaderboard[index].points) PTS\n\n"

                    let statisticsString = NSMutableAttributedString(string: rankString, attributes: mainStatisticsAttributes)

                    statisticsString.append(string)

                    self.statisticsTextView.attributedText = statisticsString
                }
                else { self.statisticsTextView.attributedText = string }
            }
            else if let error = errorDescriptor
            {
                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
        }

        completedChallenges = currentUser.completedChallenges(on: currentTeam)

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.reloadItems(at: [IndexPath(row: 1, section: 0)])
    }
}

//==================================================//

/* MARK: Extensions */

/**/

/* MARK: JTAppleCalendarViewDataSource */
extension TeamController: JTAppleCalendarViewDataSource
{
    func configureCalendar(_: JTAppleCalendarView) -> ConfigurationParameters
    {
        let components = Calendar.current.dateComponents([.year, .month], from: Date())

        let startDate = Calendar.current.date(from: components)!
        let endDate = Date()

        return ConfigurationParameters(startDate: startDate, endDate: endDate, numberOfRows: 7, calendar: Calendar.current, generateInDates: .off, generateOutDates: .off, firstDayOfWeek: nil, hasStrictBoundaries: true)
    }
}

//--------------------------------------------------//

/* MARK: JTAppleCalendarViewDelegate */
extension TeamController: JTAppleCalendarViewDelegate
{
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell
    {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "dateCell", for: indexPath) as! DateCell

        if let challenges = completedChallenges, challenges.dates().contains(currentCalendar.startOfDay(for: date).comparator)
        {
            cell.titleLabel.text = "🔥"
        }
        else { cell.titleLabel.text = cellState.text }

        cell.layer.cornerRadius = cell.frame.width / 2

        if let tournament = currentTeam.associatedTournament
        {
            let tournamentRange = tournament.startDate.comparator ... tournament.endDate.comparator

            if tournamentRange.contains(cellState.date.comparator)
            {
                cell.backgroundColor = UIColor(hex: 0x818A5C)
            }
            else
            {
                cell.backgroundColor = .black
                cell.tintColor = .black
            }
        }

        return cell
    }

    func calendar(_: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt _: Date, cellState: CellState, indexPath _: IndexPath)
    {
        let cell = cell as! DateCell
        cell.titleLabel.text = cellState.text
    }

    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo)
    {
        calendar.reloadData(withanchor: visibleDates.monthDates.first!.date, completionHandler: nil)
    }
}

//--------------------------------------------------//

/* MARK: UICollectionViewDataSource, UICollectionViewDelegate */
extension TeamController: UICollectionViewDataSource, UICollectionViewDelegate
{
    func numberOfSections(in _: UICollectionView) -> Int
    {
        return 1
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int
    {
        return currentTeam.associatedTournament != nil ? 2 : 1
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

            leaderboardLabel.text = "TEAMS TO BEAT"
            leaderboardLabel.textAlignment = .center
            leaderboardLabel.textColor = .white

            encapsulatingView.addSubview(leaderboardLabel)
            leaderboardLabel.center.x = encapsulatingView.center.x

            let scoreLabel = UILabel(frame: CGRect(x: 0, y: 30, width: scrollerCell.frame.width, height: scrollerCell.frame.height - 30))

            scoreLabel.font = UIFont(name: "Montserrat-Bold", size: 17)
            scoreLabel.numberOfLines = 10

            scoreLabel.textAlignment = .center
            scoreLabel.textColor = .white

            if let tournament = currentTeam.associatedTournament,
               let leaderboard = tournament.leaderboard()
            {
                var leaderboardString = ""
                var truncatedLength = Float(leaderboard.count) / Float(4);
                truncatedLength.round(.up);
                let trueLeaderboard = leaderboard.count > 8 ? Array(leaderboard[0 ..< Int(truncatedLength)]) : leaderboard

                for (index, metadata) in trueLeaderboard.enumerated()
                {
                    leaderboardString.append("\(index + 1). \(metadata.team.name!.uppercased())     \(metadata.points) PTS\n")
                }

                scoreLabel.text = leaderboardString
            }

            encapsulatingView.addSubview(scoreLabel)
            scoreLabel.center.x = encapsulatingView.center.x

            scrollerCell.addSubview(encapsulatingView)
            scrollerCell.bringSubviewToFront(encapsulatingView)
        }
        else
        {
            roundCorners(forViews: [scrollerCell], withCornerType: 0)
            roundCorners(forViews: [scrollerCell.subviews[0]], withCornerType: 4)

            if let streakLabel = scrollerCell.subviews[0].subview(aTagFor("streakLabel"))
            {
                roundCorners(forViews: [streakLabel], withCornerType: 3)
            }
        }

        scrollerCell.layoutIfNeeded()

        return scrollerCell
    }
}

//--------------------------------------------------//

/* MARK: Array Extensions */

extension Array where Element == (Challenge, [(User, Date)])
{
    func dates() -> [Date]
    {
        var dates = [Date]()

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
        var dates = [Date]()

        for tuple in self
        {
            dates.append(currentCalendar.startOfDay(for: tuple.date.comparator).comparator)
        }

        return dates
    }
}
