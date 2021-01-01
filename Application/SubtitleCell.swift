//
//  SubtitleCell.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 28/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class SubtitleCell: UITableViewCell
{
    //==================================================//
    
    /* MARK: Interface Builder UI Elements */
    
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var titleLabel:  UILabel!
    
    //==================================================//
    
    /* MARK: Overridden Functions */
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
