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
    var joinCode: Int!
    
    //==================================================//
    
    /* Constructor Function */
    
    init(associatedIdentifier:   String,
         associatedTournament:   Tournament?,
         completedChallenges:    [(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])]?,
         joinCode:               Int,
         name:                   String,
         participantIdentifiers: [String])
    {
        self.associatedIdentifier = associatedIdentifier
        self.associatedTournament = associatedTournament
        self.completedChallenges = completedChallenges
        self.joinCode = joinCode
        self.name = name
        self.participantIdentifiers = participantIdentifiers
    }
    
    //==================================================//
    
    /* Public Functions */
    
    /**
     Gets the total accrued points of a specific **User** on the **Team.**
     
     - Parameter userIdentifier: The identifier of the **User** to get accrued points for.
     
     - Returns: An integer describing the specified **User's** total accrued points on the **Team.**
     */
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
            
            #warning("Or maybe return 0?")
            return -1
        }
        
        var totalValue = 0
        
        for challenge in challenges
        {
            for user in challenge.metadata.users()
            {
                if user.associatedIdentifier == userIdentifier
                {
                    totalValue += challenge.challenge.pointValue
                }
            }
        }
        
        return totalValue
    }
    
    /**
     Gets and deserialises all of the **Users** in the **Team's** *participantIdentifiers* array.
     
     - Parameter completion: Upon success, returns an an array of deserialised **User** objects. Upon failure, returns a string describing the error(s) encountered.
     
     - Note: Completion is *mutually exclusive.*
     
     ~~~
     completion(returnedUsers, errorDescriptor)
     ~~~
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
     Gets the **Team's** rank in its associated **Tournament.**
     
     - Parameter completion: Upon success, returns an integer describing **Team's** rank. Upon failure, returns a string describing the error(s) encountered.
     
     - Note: Completion is *mutually exclusive.*
     - Requires: The **Team** to be participating in a **Tournament.**
     
     ~~~
     completion(returnedRank, errorDescriptor)
     ~~~
     */
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
    
    /**
     Gets the **Team's** total accrued points.
     
     - Returns: An integer describing the **Team's** total accrued points.
     */
    func getTotalPoints() -> Int
    {
        var total = 0
        
        if let challenges = completedChallenges
        {
            for challenge in challenges
            {
                total += (challenge.challenge.pointValue * challenge.metadata.count)
            }
        }
        
        return total
    }
    
    /**
     Updates the **Team's** metadata from the server.
     
     - Parameter completion: Upon failure, returns a string describing the error(s) encountered.
     
     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func reloadData(completion: @escaping(_ errorDescriptor: String?) -> Void)
    {
        TeamSerialiser().getTeam(withIdentifier: associatedIdentifier) { (returnedTeam, errorDescriptor) in
            if let team = returnedTeam
            {
                self.associatedIdentifier = team.associatedIdentifier
                self.associatedTournament = team.associatedTournament
                self.completedChallenges = team.completedChallenges
                self.joinCode = team.joinCode
                self.name = team.name
                self.participantIdentifiers = team.participantIdentifiers
                
                team.deSerialiseParticipants { (returnedUsers, errorDescriptor) in
                    if let users = returnedUsers
                    {
                        self.DSParticipants = users
                        
                        completion(nil)
                    }
                    else { completion(errorDescriptor!) }
                }
            }
            else { completion(errorDescriptor!) }
        }
    }
    
    /**
     Serialises the **Team's** completed **Challenges.**
     
     - Returns: A dictionary describing the **Team's** completed **Challenges.**
     */
    func serialiseCompletedChallenges() -> [String:[String]]
    {
        guard let challenges = completedChallenges else
        { return [:] }
        
        var dataBundle: [String:[String]] = [:]
        
        for bundle in challenges
        {
            //["challengeId":["userId – dateString"]]
            var serialisedMetadata: [String] = []
            
            for datum in bundle.metadata
            {
                let metadataString = "\(datum.user.associatedIdentifier!) – \(secondaryDateFormatter.string(from: datum.dateCompleted))"
                serialisedMetadata.append(metadataString)
            }
            
            dataBundle["\(bundle.challenge.associatedIdentifier!)"] = serialisedMetadata
        }
        
        return dataBundle
    }
    
    /**
     Sets the *DSParticipants* value on the **Team.**
     
     - Warning: Dumps errors to console.
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
                    
                    if verboseFunctionExposure { report("Successfully set «DSParticipants».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
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
}
