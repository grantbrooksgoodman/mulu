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

class TeamController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//
    
    /* Interface Builder UI Elements */
    
    @IBOutlet weak var titleLabel: UILabel!
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
