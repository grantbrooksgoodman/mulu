//
//  AnnouncementsController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 21/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

class AnnouncementsController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    @IBOutlet var textView: UITextView!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    var buildInstance: Build!

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

        //        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Gotham-Black", size: 19)!]
        //        let announcementAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Montserrat-SemiBold", size: 18)!]
        //        let noAnnouncementAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Montserrat-SemiBoldItalic", size: 18)!]
        //
        //        let schedule = NSMutableAttributedString(string: "SCHEDULE\n\n", attributes: titleAttributes)
        //        let scheduleSubtitle = NSAttributedString(string: "– THURSDAY 1/7 12PM PT\n– THURSDAY 1/14 12PM PT\n– THURSDAY 1/21 12PM PT\n– THURSDAY 1/28 12PM PT\n\n", attributes: suibtitleAttributes)
        //
        //        let howItWorks = NSAttributedString(string: "HOW IT WORKS\n\n", attributes: titleAttributes)
        //        let howItWorksSubtitle = NSAttributedString(string: "– INSERT HOW IT WORKS\n– INSERT HOW IT WORKS\n– INSERT HOW IT WORKS\n\nQUESTIONS?\nHELLO@GETMULU.COM", attributes: suibtitleAttributes)

        //        schedule.append(scheduleSubtitle)
        //        schedule.append(howItWorks)
        //        schedule.append(howItWorksSubtitle)
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        currentFile = #file
        buildInfoController?.view.isHidden = !preReleaseApplication

        setVisualTeamInformation()
    }

    override func prepare(for _: UIStoryboardSegue, sender _: Any?)
    {}

    //==================================================//

    /* MARK: Interface Builder Actions */

    //==================================================//

    /* MARK: Other Functions */

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }

    func setVisualTeamInformation()
    {
        let announcementAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Montserrat-SemiBold", size: 18)!]
        let noAnnouncementAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Montserrat-SemiBoldItalic", size: 18)!]

        if let tournament = currentTeam.associatedTournament
        {
            if let announcement = tournament.announcement
            {
                textView.attributedText = NSAttributedString(string: announcement, attributes: announcementAttributes)
            }
            else { textView.attributedText = NSAttributedString(string: "No announcements to display!", attributes: noAnnouncementAttributes) }
        }
        else { textView.attributedText = NSAttributedString(string: "No announcements to display!", attributes: noAnnouncementAttributes) }
    }
}
