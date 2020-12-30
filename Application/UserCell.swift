//
//  UserCell.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 28/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class UserCell: UITableViewCell
{
    //==================================================//
    
    /* MARK: Interface Builder UI Elements */
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var nameLabel:  UILabel!
    
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
