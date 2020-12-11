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
    @IBOutlet weak var streakLabel: UILabel!
    @IBOutlet weak var titleLabel:  UILabel!
    
    //Other Elements
    @IBOutlet weak var calendarCollectionView: JTAppleCalendarView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    //==================================================//
    
    /* Class-level Variable Declarations */
    
    var buildInstance: Build!
    
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
        
        if let subviews = view.subviews(aTagFor("view"))
        {
            for subview in subviews
            {
                subview.frame.size.height = titleLabel.frame.height
            }
        }
        
        roundCorners(forViews: [calendarCollectionView], withCornerType: 4)
        roundCorners(forViews: [streakLabel], withCornerType: 3)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        //        if let user = currentUser, let completedChallenges = user.completedChallenges()
        //        {
        //            var dates: [Date] = []
        //
        //            for challenge in completedChallenges
        //            {
        //
        //            }
        //        }
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
        
        if Int(cellState.text)! % 2 == 0
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
