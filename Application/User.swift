//
//  User.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 05/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

/* Third-party Frameworks */
import Firebase

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
    
    #warning("Tagged for deletion pending investigation of future use cases.")
    func reloadData()
    {
        UserSerialiser().getUser(withIdentifier: associatedIdentifier) { (returnedUser, errorDescriptor) in
            if let user = returnedUser
            {
                self.associatedTeams = user.associatedTeams
                self.emailAddress = user.emailAddress
                self.firstName = user.firstName
                self.lastName = user.lastName
                self.profileImageData = user.profileImageData
                self.pushTokens = user.pushTokens
            }
            else { report(errorDescriptor!, errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
        }
    }
    
    /**
     If *DSAssociatedTeams* has been set, returns the **User's** completed **Challenges**.
     */
    func allCompletedChallenges() -> [(date: Date, challenge: Challenge)]?
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
        
        return matchingChallenges.count == 0 ? nil : matchingChallenges
    }
    
    func challengesToComplete(on team: Team, completion: @escaping(_ returnedIdentifiers: [String]?, _ errorDescriptor: String?) -> Void)
    {
        let previouslyCompleted = completedChallenges(on: team) ?? []
        var incompleteChallenges: [(identifier: String, datePosted: Date)] = []
        
        Database.database().reference().child("allChallenges").observeSingleEvent(of: .value) { (returnedSnapshot) in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary,
               let asDataBundle = returnedSnapshotAsDictionary as? [String:Any]
            {
                for (index, identifier) in Array(asDataBundle.keys).enumerated()
                {
                    if !previouslyCompleted.contains(where: {$0.challenge.associatedIdentifier == identifier})
                    {
                        if let data = asDataBundle[identifier] as? [String:Any],
                           let datePostedString = data["datePosted"] as? String,
                           let datePosted = secondaryDateFormatter.date(from: datePostedString)
                        {
                            incompleteChallenges.append((identifier, datePosted))
                        }
                    }
                    
                    if index == asDataBundle.keys.count - 1
                    {
                        if incompleteChallenges.count == 0
                        {
                            completion(nil, "User has completed all Challenges.")
                        }
                        else
                        {
                            incompleteChallenges.sort(by: {$0.datePosted < $1.datePosted})
                            
                            var identifiers: [String] = []
                            
                            for challenge in incompleteChallenges
                            {
                                identifiers.append(challenge.identifier)
                            }
                            
                            completion(identifiers, nil)
                        }
                    }
                }
            }
            else
            {
                completion(nil, "Unable to deserialise snapshot.")
            }
        }
    }
    
    func completeChallenge(withIdentifier: String, on team: Team, completion: @escaping(_ errorDescriptor: String?) -> Void)
    {
        let serialisedData = "\(associatedIdentifier!) – \(secondaryDateFormatter.string(from: Date()))"
        
        ChallengeSerialiser().getChallenge(withIdentifier: withIdentifier) { (returnedChallenge, errorDescriptor) in
            if let challenge = returnedChallenge
            {
                var newCompletedChallenges = team.serialiseCompletedChallenges()
                
                if let completedChallenges = team.completedChallenges
                {
                    if let index = completedChallenges.challenges().firstIndex(where: {$0.associatedIdentifier == withIdentifier})
                    {
                        team.completedChallenges![index].metadata.append((self, Date()))
                    }
                    else
                    {
                        team.completedChallenges!.append((challenge, [(self, Date())]))
                    }
                }
                else { team.completedChallenges = [(challenge, [(self, Date())])] }
                
                if newCompletedChallenges[withIdentifier] != nil
                {
                    newCompletedChallenges[withIdentifier]!.append(serialisedData)
                }
                else
                {
                    newCompletedChallenges[withIdentifier] = [serialisedData]
                }
                
                GenericSerialiser().updateValue(onKey: "/allTeams/\(team.associatedIdentifier!)/", withData: ["completedChallenges": newCompletedChallenges]) { (returnedError) in
                    if let error = returnedError
                    {
                        completion(errorInformation(forError: (error as NSError)))
                    }
                    else { completion(nil) }
                }
            }
            else { completion("Couldn't get Challenge.") }
        }
    }
    
    /**
     Returns the **User's** completed **Challenges** on the specified **Team**.
     */
    func completedChallenges(on team: Team) -> [(date: Date, challenge: Challenge)]?
    {
        var matchingChallenges: [(date: Date, challenge: Challenge)] = []
        
        if let challenges = team.completedChallenges
        {
            for challenge in challenges
            {
                if challenge.metadata.filter({$0.user.associatedIdentifier == associatedIdentifier}).count > 0
                {
                    if verboseFunctionExposure { print("\(firstName!) completed '\(challenge.challenge.title!)' for \(challenge.challenge.pointValue!)pts.") }
                    
                    matchingChallenges.append((challenge.metadata.first(where: {$0.user.associatedIdentifier == associatedIdentifier})!.dateCompleted, challenge.challenge))
                }
            }
        }
        
        return matchingChallenges.count == 0 ? nil : matchingChallenges
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
            completion(nil, "This User is not a member of any Team.")
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
                    
                    if verboseFunctionExposure { report("Successfully set «DSAssociatedTeams».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
                }
            }
        }
        else
        {
            report("This User is not a member of any Team.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
        }
    }
    
    func streak(on team: Team) -> Int
    {
        var total = 0
        
        if let challenges = completedChallenges(on: team)
        {
            let enumeratedDates = challenges.dates().sorted()
            
            guard enumeratedDates.last!.comparator >= Calendar.current.date(byAdding: .day, value: -1, to: Date())!.comparator else
            { return 0 }
            
            for (index, date) in enumeratedDates.enumerated()
            {
                let nextIndex = index + 1
                
                if nextIndex < enumeratedDates.count
                {
                    if date == enumeratedDates[index + 1]
                    {
                        total += 1
                    }
                }
            }
        }
        
        return total
    }
}

extension Array where Element == (challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])
{
    func challenges() -> [Challenge]
    {
        var challenges: [Challenge] = []
        
        for challengeTuple in self
        {
            challenges.append(challengeTuple.challenge)
        }
        
        return challenges
    }
}
