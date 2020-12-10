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
    var completedChallenges:    [(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])]?
    var participantIdentifiers: [String]!
    
    //Strings
    var associatedIdentifier: String!
    var name:                 String!
    
    //==================================================//
    
    /* Constructor Function */
    
    init(associatedIdentifier:   String,
         completedChallenges:    [(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])]?,
         name:                   String,
         participantIdentifiers: [String])
    {
        self.associatedIdentifier = associatedIdentifier
        self.completedChallenges = completedChallenges
        self.name = name
        self.participantIdentifiers = participantIdentifiers
    }
    
    //==================================================//
    
    /* Public Functions */
    
    func completedChallenges(for user: User) -> [Challenge]?
    {
        var matchingChallenges: [Challenge] = []
        
        if let challenges = completedChallenges
        {
            for challenge in challenges
            {
                if challenge.metadata.filter({$0.user.associatedIdentifier == "-MNuzhwBe-c3yz_qtaAu"}).count > 0
                {
                    matchingChallenges.append(challenge.challenge)
                }
            }
        }
        
        return matchingChallenges
    }
    
    func getTotalPoints() -> Int
    {
        var total = 0
        
        if let challenges = completedChallenges
        {
            for challenge in challenges
            {
                total += challenge.challenge.pointValue
            }
        }
        
        return total
    }
}
