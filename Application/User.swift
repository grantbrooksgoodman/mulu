//
//  User.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 05/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class User
{
    //==================================================//
    
    /* Class-Level Variable Declarations */
    
    //Arrays
    var associatedTeams: [String]? //String = team ID
    var pushTokens:      [String]?
    
    //Strings
    var associatedIdentifier: String!
    var emailAddress:         String!
    var firstName:            String!
    var lastName:             String!
    var profileImageData:     String?
    
    private(set) var DSAssociatedTeams: [Team]?
    
    //==================================================//
    
    /* Constructor Function */
    
    init(associatedIdentifier: String,
         associatedTeams:      [String]?,
         emailAddress:         String,
         firstName:            String,
         lastName:             String,
         profileImageData:     String?,
         pushTokens:           [String]?)
    {
        self.associatedIdentifier = associatedIdentifier
        self.associatedTeams = associatedTeams
        self.emailAddress = emailAddress
        self.firstName = firstName
        self.lastName = lastName
        self.profileImageData = profileImageData
        self.pushTokens = pushTokens
    }
    
    //==================================================//
    
    /* Public Functions */
    
    /**
     If *DSAssociatedTeams* has been set, returns the **User's** completed **Challenges**.
     */
    func completedChallenges() -> [(date: Date, challenge: Challenge)]?
    {
        guard let DSAssociatedTeams = DSAssociatedTeams else { report("Teams haven't been deserialised.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return nil }
        
        var matchingChallenges: [(date: Date, challenge: Challenge)] = []
        
        for team in DSAssociatedTeams
        {
            if let challenges = team.completedChallenges
            {
                for challenge in challenges
                {
                    if challenge.metadata.filter({$0.user.associatedIdentifier == associatedIdentifier}).count > 0
                    {
                        matchingChallenges.append((challenge.metadata.first(where: {$0.user.associatedIdentifier == associatedIdentifier})!.dateCompleted, challenge.challenge))
                    }
                }
            }
        }
        
        return matchingChallenges
    }
    
    /**
     Gets and deserialises all of the **Teams** the **User** is a member of using the *associatedTeams* array.
     
     - Parameter completion: Returns an array of deserialised **Team** objects if successful. If unsuccessful, a string describing the error(s) encountered. *Mutually exclusive.*
     */
    func deSerialiseAssociatedTeams(completion: @escaping(_ returnedTeams: [Team]?, _ errorDescriptor: String?) -> Void)
    {
        if let DSAssociatedTeams = DSAssociatedTeams
        {
            completion(DSAssociatedTeams, nil)
        }
        else if let associatedTeams = associatedTeams
        {
            TeamSerialiser().getTeams(withIdentifiers: associatedTeams) { (returnedTeams, errorDescriptors) in
                if let errors = errorDescriptors
                {
                    completion(nil, errors.joined(separator: "\n"))
                }
                else if let teams = returnedTeams
                {
                    self.DSAssociatedTeams = teams
                    
                    completion(teams, nil)
                }
                else
                {
                    completion(nil, "No returned Teams, but no error either.")
                }
            }
        }
        else
        {
            report("This User is not a member of any Team.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
        }
    }
    
    /**
     Sets the *DSAssociatedTeams* value on the **User** without closures. *Dumps errors to console.*
     */
    func setDSAssociatedTeams()
    {
        if DSAssociatedTeams != nil
        {
            report("«DSAssociatedTeams» already set.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
        }
        else if let associatedTeams = associatedTeams
        {
            TeamSerialiser().getTeams(withIdentifiers: associatedTeams) { (returnedTeams, errorDescriptors) in
                if let errors = errorDescriptors
                {
                    report(errors.joined(separator: "\n"), errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                }
                else if let teams = returnedTeams
                {
                    self.DSAssociatedTeams = teams
                    
                    report("Successfully set «DSAssociatedTeams».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                }
            }
        }
        else
        {
            report("This User is not a member of any Team.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
        }
    }
}
