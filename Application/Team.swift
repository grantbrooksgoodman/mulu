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
    var associatedTournaments:  [Tournament]?
    var completedChallenges:    [(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])]?
    var participantIdentifiers: [String]!
    
    //Strings
    var associatedIdentifier: String!
    var name:                 String!
    
    //==================================================//
    
    /* Constructor Function */
    
    init(associatedIdentifier:   String,
         associatedTournaments:  [Tournament]?,
         completedChallenges:    [(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])]?,
         name:                   String,
         participantIdentifiers: [String])
    {
        self.associatedIdentifier = associatedIdentifier
        self.associatedTournaments = associatedTournaments
        self.completedChallenges = completedChallenges
        self.name = name
        self.participantIdentifiers = participantIdentifiers
    }
    
    //==================================================//
    
    /* Public Functions */
    
    func getRank(in tournament: Tournament, completion: @escaping(_ returnedRank: Int?, _ errorDescriptor: String?) -> Void)
    {
        TeamSerialiser().getTeams(withIdentifiers: tournament.teamIdentifiers) { (returnedTeams, errorDescriptors) in
            if let teams = returnedTeams
            {
                var totalPoints: [Int] = []
                
                for team in teams
                {
                    totalPoints.append(team.getTotalPoints())
                }
                
                completion(totalPoints.sorted().firstIndex(of: self.getTotalPoints())! + 1, nil)
            }
            else { completion(nil, errorDescriptors!.joined(separator: "\n")) }
        }
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
