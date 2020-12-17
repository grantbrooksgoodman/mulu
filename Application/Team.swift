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
    private(set) var DSParticipants: [User]?
    
    var completedChallenges:         [(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])]?
    var participantIdentifiers:      [String]!
    
    //Strings
    var associatedIdentifier: String!
    var name:                 String!
    
    //Other Declarations
    var associatedTournament:  Tournament?
    
    //==================================================//
    
    /* Constructor Function */
    
    init(associatedIdentifier:   String,
         associatedTournament:   Tournament?,
         completedChallenges:    [(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])]?,
         name:                   String,
         participantIdentifiers: [String])
    {
        self.associatedIdentifier = associatedIdentifier
        self.associatedTournament = associatedTournament
        self.completedChallenges = completedChallenges
        self.name = name
        self.participantIdentifiers = participantIdentifiers
    }
    
    //==================================================//
    
    /* Public Functions */
    
    func accruedPoints(for userIdentifier: String) -> Int
    {
        guard participantIdentifiers.contains(userIdentifier) else
        {
            if verboseFunctionExposure { report("This User isn't on that Team.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
            
            return -1
        }
        
        guard let challenges = completedChallenges,
              challenges.first(where: {$0.metadata.first(where: {$0.user.associatedIdentifier == userIdentifier}) != nil}) != nil else
        {
            if verboseFunctionExposure { report("This User hasn't completed any Challenges for this Team.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
            
            return -1
        }
        
        var totalValue = 0
        
        for challenge in challenges
        {
            for datum in challenge.metadata
            {
                if datum.user.associatedIdentifier == userIdentifier
                {
                    totalValue += challenge.challenge.pointValue
                }
            }
        }
        
        return totalValue
    }
    
    /**
     Gets and deserialises all of the **Users** on the **Team** *participantIdentifiers* array.
     
     - Parameter completion: Returns an array of deserialised **User** objects if successful. If unsuccessful, a string describing the error(s) encountered. *Mutually exclusive.*
     */
    func deSerialiseParticipants(completion: @escaping(_ returnedUsers: [User]?, _ errorDescriptor: String?) -> Void)
    {
        if let DSParticipants = DSParticipants
        {
            completion(DSParticipants, nil)
        }
        else if let participantIdentifiers = participantIdentifiers
        {
            UserSerialiser().getUsers(withIdentifiers: participantIdentifiers) { (returnedUsers, errorDescriptors) in
                if let errors = errorDescriptors
                {
                    completion(nil, errors.joined(separator: "\n"))
                }
                else if let users = returnedUsers
                {
                    self.DSParticipants = users
                    
                    completion(users, nil)
                }
                else
                {
                    completion(nil, "No returned Users, but no error either.")
                }
            }
        }
        else
        {
            report("This Team does not have any Users.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
        }
    }
    
    /**
     Sets the *DSParticipants* value on the **Team** without closures. *Dumps errors to console.*
     */
    func setDSParticipants()
    {
        if DSParticipants != nil
        {
            report("«DSParticipants» already set.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
        }
        else if let participantIdentifiers = participantIdentifiers
        {
            UserSerialiser().getUsers(withIdentifiers: participantIdentifiers) { (returnedUsers, errorDescriptors) in
                if let errors = errorDescriptors
                {
                    report(errors.joined(separator: "\n"), errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                }
                else if let users = returnedUsers
                {
                    self.DSParticipants = users
                    
                    report("Successfully set «DSParticipants».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                }
                else
                {
                    report("No returned Users, but no error either.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                }
            }
        }
        else
        {
            report("This User is not a member of any Team.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
        }
    }
    
    func getRank(completion: @escaping(_ returnedRank: Int?, _ errorDescriptor: String?) -> Void)
    {
        guard let tournament = associatedTournament else
        { completion(nil, "This Team is not participating in any Tournament."); return }
        
        TeamSerialiser().getTeams(withIdentifiers: tournament.teamIdentifiers) { (returnedTeams, errorDescriptors) in
            if let teams = returnedTeams
            {
                var totalPoints: [Int] = []
                
                for team in teams
                {
                    totalPoints.append(team.getTotalPoints())
                }
                
                completion(totalPoints.sorted(by: {$0 > $1}).firstIndex(of: self.getTotalPoints())! + 1, nil)
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
