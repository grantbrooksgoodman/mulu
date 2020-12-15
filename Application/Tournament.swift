//
//  Tournament.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 14/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class Tournament
{
    //==================================================//
    
    /* Class-Level Variable Declarations */
    
    //Dates
    var startDate: Date!
    var endDate:   Date!
    
    //Strings
    var associatedIdentifier: String!
    var name: String!
    
    //Other Declarations
    var teamIdentifiers: [String]!
    
    //==================================================//
    
    /* Constructor Function */
    
    init(associatedIdentifier: String, name: String, startDate: Date, endDate: Date, teamIdentifiers: [String])
    {
        self.associatedIdentifier = associatedIdentifier
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.teamIdentifiers = teamIdentifiers
    }
}
