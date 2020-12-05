//
//  Team.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 05/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class Team
{
    //==================================================//
    
    /* Class-Level Variable Declarations */
    
    //Arrays
    var completedChallenges:    [Challenge]?
    var participantIdentifiers: [String]!
    
    //Dictionaries
    var participationDates: [String:[Date]]? //String = user ID
    var pointDistribution:  [String:Int]! //String = user ID
    
    //Strings
    var associatedIdentifier: String!
    var name:                 String!
    
    //==================================================//
    
    /* Constructor Function */
    
    init(associatedIdentifier:   String,
         completedChallenges:    [Challenge]?,
         name:                   String,
         participantIdentifiers: [String],
         participationDates:     [String:[Date]]?,
         pointDistribution:      [String:Int])
    {
        self.associatedIdentifier = associatedIdentifier
        self.completedChallenges = completedChallenges
        self.name = name
        self.participantIdentifiers = participantIdentifiers
        self.participationDates = participationDates
        self.pointDistribution = pointDistribution
    }
    
    //==================================================//
    
    /* Public Functions */
    
    func getTotalPoints() -> Int
    {
        var total = 0
        
        for value in Array(pointDistribution.values)
        {
            total += value
        }
        
        return total
    }
}
