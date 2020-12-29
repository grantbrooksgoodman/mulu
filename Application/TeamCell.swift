//
//  TeamCell.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 28/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class TeamCell: UITableViewCell, SSRadioButtonControllerDelegate
{
    //==================================================//
    
    /* Interface Builder UI Elements */
    
    //UILabels
    @IBOutlet weak var memberLabel: UILabel!
    @IBOutlet weak var teamLabel:   UILabel!
    
    //Other Elements
    @IBOutlet weak var radioButton: SSRadioButton!
    
    //==================================================//
    
    /* Overridden Functions */
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        //Set up the «RadioButtonController».
        let radioButtonsController: SSRadioButtonsController?
        radioButtonsController = SSRadioButtonsController(buttons: radioButton)
        radioButtonsController!.delegate = self
    }
}
