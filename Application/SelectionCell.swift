//
//  SelectionCell.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 28/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class SelectionCell: UITableViewCell, SSRadioButtonControllerDelegate
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    //UILabels
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var titleLabel:   UILabel!

    //Other Elements
    @IBOutlet var radioButton: SSRadioButton!

    //==================================================//

    /* MARK: Overridden Functions */

    override func draw(_ rect: CGRect)
    {
        super.draw(rect)

        radioButton.isSelected = false
    }

    override func awakeFromNib()
    {
        super.awakeFromNib()

        //Set up the «RadioButtonController».
        let radioButtonsController: SSRadioButtonsController?
        radioButtonsController = SSRadioButtonsController(buttons: radioButton)
        radioButtonsController!.delegate = self

        radioButton.isSelected = false
    }
}
