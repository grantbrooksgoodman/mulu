//
//  TeamSerialiser.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 06/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

/* Third-party Frameworks */
import FirebaseDatabase

class TeamSerialiser
{
    //==================================================//
    
    /* Public Functions */
    
    func addCompletedChallenges(_ withBundle: [(Challenge, [(User, Date)])], toTeam: String, overwrite: Bool, completion: @escaping(_ errorDescriptor: String?) -> Void)
    {
        let serialisedChallenges = serialiseCompletedChallenges(withBundle)
        
        let key = overwrite ? "/allTeams/\(toTeam)" : "/allTeams/\(toTeam)/completedChallenges"
        let data: [String:Any] = overwrite ? ["completedChallenges": serialisedChallenges] : serialisedChallenges
        
        GenericSerialiser().updateValue(onKey: key, withData: data) { (returnedError) in
            if let error = returnedError
            {
                completion(errorInformation(forError: (error as NSError)))
            }
            else
            {
                completion(nil)
            }
        }
    }
    
    func addUsers(_ users: [User], toTeam: Team, completion: @escaping(_ errorDescriptor: String?) -> Void)
    {
        let group = DispatchGroup()
        
        var errors: [String] = []
        
        for user in users
        {
            group.enter()
            
            var newAssociatedTeams = user.associatedTeams ?? []
            newAssociatedTeams.append(toTeam.associatedIdentifier)
            
            GenericSerialiser().updateValue(onKey: "/allUsers/\(user.associatedIdentifier!)", withData: ["associatedTeams": newAssociatedTeams]) { (returnedError) in
                if let error = returnedError
                {
                    errors.append(errorInformation(forError: (error as NSError)))
                    group.leave()
                }
                else { group.leave() }
            }
        }
        
        group.notify(queue: .main) {
            var newParticipantIdentifiers = toTeam.participantIdentifiers!
            newParticipantIdentifiers.append(contentsOf: users.identifiers())
            
            GenericSerialiser().updateValue(onKey: "/allTeams/\(toTeam.associatedIdentifier!)", withData: ["participantIdentifiers": newParticipantIdentifiers]) { (returnedError) in
                if let error = returnedError
                {
                    completion(errors.count > 0 ? "\(errors.joined(separator: "\n"))\n\(errorInformation(forError: (error as NSError)))" : nil)
                }
                else
                { completion(errors.count > 0 ? errors.joined(separator: "\n") : nil) }
            }
        }
    }
    
    func serialiseCompletedChallenges(_ with: [(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])]) -> [String:[String]]
    {
        var dataBundle: [String:[String]] = [:]
        
        for bundle in with
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
    
    func addUser(_ withIdentifier: String, toTeam: String, completion: @escaping(_ errorDescriptor: String?) -> Void)
    {
        Database.database().reference().child("allTeams").child(toTeam).observeSingleEvent(of: .value, with: { (returnedSnapshot) in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary,
               let asDataBundle =                 returnedSnapshotAsDictionary as? [String:Any]
            {
                var mutableDataBundle = asDataBundle
                mutableDataBundle["associatedIdentifier"] = withIdentifier
                
                guard self.validateTeamMetadata(mutableDataBundle) == true else
                { completion("Improperly formatted metadata."); return }
                
                var newUserList = mutableDataBundle["participantIdentifiers"] as! [String]
                newUserList.append(withIdentifier)
                
                GenericSerialiser().updateValue(onKey: "/allTeams/\(toTeam)", withData: ["participantIdentifiers": newUserList]) { (returnedError) in
                    if let error = returnedError
                    {
                        completion(errorInformation(forError: (error as NSError)))
                    }
                    else
                    {
                        GenericSerialiser().updateValue(onKey: "/allUsers/\(withIdentifier)", withData: ["associatedTeams": toTeam]) { (returnedError) in
                            if let error = returnedError
                            {
                                completion(errorInformation(forError: (error as NSError)))
                            }
                            else
                            {
                                report("Successfully added User to Team.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                                
                                completion(nil)
                            }
                        }
                    }
                }
                
            }
            else { completion("No Team exists with the identifier \"\(toTeam)\".") }
        })
        { (returnedError) in
            
            completion("Unable to retrieve the specified data. (\(returnedError.localizedDescription))")
        }
    }
    
    /**
     Creates a **Team** on the server.
     
     - Parameter name: The name of this **Team.**
     - Parameter participantIdentifiers: An array containing the identifiers of the **Users** on this **Team.**
     
     - Parameter completion: Returns with the identifier of the newly created **Team** if successful. If unsuccessful, a string describing the error encountered. *Mutually exclusive.*
     */
    func createTeam(name: String, participantIdentifiers: [String], completion: @escaping(_ returnedIdentifier: String?, _ errorDescriptor: String?) -> Void)
    {
        var dataBundle: [String:Any] = [:]
        
        dataBundle["completedChallenges"] = ["!":["!"]]
        dataBundle["name"] = name
        dataBundle["participantIdentifiers"] = participantIdentifiers
        
        //Generate a key for the new Team.
        if let generatedKey = Database.database().reference().child("/allTeams/").childByAutoId().key
        {
            GenericSerialiser().updateValue(onKey: "/allTeams/\(generatedKey)", withData: dataBundle) { (returnedError) in
                if let error = returnedError
                {
                    completion(nil, errorInformation(forError: (error as NSError)))
                }
                else
                {
                    for (index, user) in participantIdentifiers.enumerated()
                    {
                        GenericSerialiser().updateValue(onKey: "/allUsers/\(user)", withData: ["associatedTeams": [generatedKey]]) { (returnedError) in
                            if let error = returnedError
                            {
                                completion(nil, errorInformation(forError: (error as NSError)))
                            }
                            else
                            {
                                if index == participantIdentifiers.count - 1
                                {
                                    completion(generatedKey, nil)
                                }
                            }
                        }
                    }
                    
                }
            }
        }
        else { completion(nil, "Unable to create key in database.") }
    }
    
    /**
     Gets and deserialises a **Team** from a given identifier string.
     
     - Parameter withIdentifier: The identifier of the requested **Team.**
     - Parameter completion: Returns a deserialised **Team** object if successful. If unsuccessful, a string describing the error encountered. *Mutually exclusive.*
     */
    func getTeam(withIdentifier: String, completion: @escaping(_ returnedTeam: Team?, _ errorDescriptor: String?) -> Void)
    {
        if verboseFunctionExposure { print("getting team") }
        
        Database.database().reference().child("allTeams").child(withIdentifier).observeSingleEvent(of: .value, with: { (returnedSnapshot) in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary, let asDataBundle = returnedSnapshotAsDictionary as? [String:Any]
            {
                if verboseFunctionExposure { print("returned snapshot") }
                
                var mutableDataBundle = asDataBundle
                
                mutableDataBundle["associatedIdentifier"] = withIdentifier
                
                self.deSerialiseTeam(from: mutableDataBundle) { (returnedTeam, errorDescriptor) in
                    if let error = errorDescriptor
                    {
                        if verboseFunctionExposure { print("failed to deserialise team") }
                        
                        completion(nil, error)
                    }
                    else if let team = returnedTeam
                    {
                        if verboseFunctionExposure { print("deserialised team") }
                        
                        completion(team, nil)
                    }
                    else
                    {
                        completion(nil, "An unknown error occurred.")
                    }
                }
            }
            else { completion(nil, "No Team exists with the identifier \"\(withIdentifier)\".") }
        })
        { (returnedError) in
            
            completion(nil, "Unable to retrieve the specified data. (\(returnedError.localizedDescription))")
        }
    }
    
    /**
     Gets and deserialises multiple **Team** objects from a given array of identifier strings.
     
     - Parameter withIdentifiers: The identifiers to query for.
     
     - Parameter completion: Returns an array of deserialised **Team** objects if successful. If unsuccessful, an array of strings describing the error(s) encountered. *Mutually exclusive.*
     */
    func getTeams(withIdentifiers: [String], completion: @escaping(_ returnedTeams: [Team]?, _ errorDescriptors: [String]?) -> Void)
    {
        var teamArray: [Team]! = []
        var errorDescriptorArray: [String]! = []
        
        if withIdentifiers.count > 0
        {
            let dispatchGroup = DispatchGroup()
            
            for individualIdentifier in withIdentifiers
            {
                if verboseFunctionExposure { print("entered group") }
                dispatchGroup.enter()
                
                getTeam(withIdentifier: individualIdentifier) { (returnedTeam, errorDescriptor) in
                    if let team = returnedTeam
                    {
                        teamArray.append(team)
                        
                        if verboseFunctionExposure { print("left group") }
                        dispatchGroup.leave()
                    }
                    else
                    {
                        errorDescriptorArray.append(errorDescriptor!)
                        
                        if verboseFunctionExposure { print("left group") }
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                if teamArray.count + errorDescriptorArray.count == withIdentifiers.count
                {
                    completion(teamArray.count == 0 ? nil : teamArray, errorDescriptorArray.count == 0 ? nil : errorDescriptorArray)
                }
            }
        }
        else
        {
            completion(nil, ["No identifiers passed!"])
        }
    }
    
    /**
     Gets random **Team** identifiers from the server.
     
     - Parameter amountToGet: An optional integer specifying the amount of random **Team** identifiers to get. *Defaults to all.*
     
     - Parameter completion: Returns an array of **Team** identifier strings if successful. May also return a string describing an event or error encountered. *NOT mutually exclusive.*
     */
    func getRandomTeams(amountToGet: Int?, completion: @escaping(_ returnedIdentifiers: [String]?, _ noticeDescriptor: String?) -> Void)
    {
        Database.database().reference().child("allTeams").observeSingleEvent(of: .value) { (returnedSnapshot) in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary,
               let teamIdentifiers = returnedSnapshotAsDictionary.allKeys as? [String]
            {
                if amountToGet == nil
                {
                    completion(teamIdentifiers.shuffledValue, nil)
                }
                else
                {
                    if amountToGet! > teamIdentifiers.count
                    {
                        completion(teamIdentifiers.shuffledValue, "Requested amount was larger than database size.")
                    }
                    else if amountToGet! == teamIdentifiers.count
                    {
                        completion(teamIdentifiers.shuffledValue, nil)
                    }
                    else if amountToGet! < teamIdentifiers.count
                    {
                        completion(Array(teamIdentifiers.shuffledValue[0...amountToGet!]), nil)
                    }
                }
            }
            else
            {
                completion(nil, "Unable to deserialise snapshot.")
            }
        }
    }
    
    //==================================================//
    
    /* Private Functions */
    
    /**
     Deserialises an array of completed **Challenges** from a given data bundle. Returns an array of deserialised `(Challenge, [(User, Date)]` tuples if successful. If unsuccessful, a string describing the error encountered. *Mutually exclusive.*
     
     - Parameter from: The data bundle from which to deserialise the **Team.**
     */
    private func deSerialiseCompletedChallenges(with challenges: [String:[String]], completion: @escaping(_ completedChallenges: [(Challenge, [(user: User, dateCompleted: Date)])]?, _ errorDescriptor: String?) -> Void)
    {
        if verboseFunctionExposure { print("deserialising completed challenges") }
        var deSerialisedCompletedChallenges: [(Challenge, [(user: User, dateCompleted: Date)])] = []
        
        //serialised completed challenges = ["challengeId":["userId – dateString"]]
        
        for challengeIdentifier in Array(challenges.keys)
        {
            if verboseFunctionExposure { print("processing \(challengeIdentifier)") }
            
            ChallengeSerialiser().getChallenge(withIdentifier: challengeIdentifier) { (returnedChallenge, errorDescriptor) in
                if let error = errorDescriptor
                {
                    completion(nil, "While getting Challenges: \(error)")
                }
                else if let challenge = returnedChallenge, let metadata = challenges[challengeIdentifier]
                {
                    var deSerialisedMetadata: [(User, Date)] = []
                    
                    for (index, string) in metadata.enumerated()
                    {
                        let components = string.components(separatedBy: " – ")
                        
                        guard components.count == 2 else
                        { completion(nil, "A Challenge's metadata array was improperly formatted."); return }
                        
                        guard let completionDate = secondaryDateFormatter.date(from: components[1]) else
                        { completion(nil, "Unable to convert a Challenge's completion date string to a Date."); return }
                        
                        let userIdentifier = components[0]
                        
                        UserSerialiser().getUser(withIdentifier: userIdentifier) { (returnedUser, errorDescriptor)  in
                            if let error = errorDescriptor
                            {
                                completion(nil, "While getting a User for a Challenge: \(error)")
                            }
                            else if let user = returnedUser
                            {
                                deSerialisedMetadata.append((user, completionDate))
                                
                                if index == metadata.count - 1
                                {
                                    deSerialisedCompletedChallenges.append((challenge, deSerialisedMetadata))
                                    
                                    if deSerialisedCompletedChallenges.count == challenges.count
                                    {
                                        completion(deSerialisedCompletedChallenges, nil)
                                    }
                                }
                            }
                            else
                            {
                                completion(nil, "An unknown error occurred while getting a User for a Challenge.")
                            }
                        }
                    }
                }
                else { completion(nil, "An unknown error occurred while getting a Challenge.") }
            }
        }
    }
    
    /**
     Deserialises a **Team** from a given data bundle. Returns a deserialised **Team** object if successful. If unsuccessful, a string describing the error encountered. *Mutually exclusive.*
     
     - Parameter from: The data bundle from which to deserialise the **Team.**
     */
    private func deSerialiseTeam(from dataBundle: [String:Any], completion: @escaping(_ deSerialisedTeam: Team?, _ errorDescriptor: String?) -> Void)
    {
        if verboseFunctionExposure { print("deserialising team") }
        
        guard validateTeamMetadata(dataBundle) == true else
        { completion(nil, "Improperly formatted metadata."); return }
        
        let associatedIdentifier = dataBundle["associatedIdentifier"] as! String
        let completedChallenges = dataBundle["completedChallenges"] as! [String:[String]]
        let name = dataBundle["name"] as! String
        let participantIdentifiers = dataBundle["participantIdentifiers"] as! [String]
        
        if completedChallenges.keys.first != "!"
        {
            deSerialiseCompletedChallenges(with: completedChallenges) { (completedChallenges, errorDescriptor) in
                if let error = errorDescriptor
                {
                    if verboseFunctionExposure { print("failed to deserialise completed challenges") }
                    
                    completion(nil, error)
                }
                else if let challenges = completedChallenges
                {
                    let deSerialisedTeam = Team(associatedIdentifier:   associatedIdentifier,
                                                completedChallenges:    challenges,
                                                name:                   name,
                                                participantIdentifiers: participantIdentifiers)
                    
                    if verboseFunctionExposure { print("deserialised completed challenges") }
                    
                    completion(deSerialisedTeam, nil)
                }
                else
                {
                    completion(nil, "An unknown error occurred.")
                }
            }
        }
        else
        {
            let deSerialisedTeam = Team(associatedIdentifier:   associatedIdentifier,
                                        completedChallenges:    nil,
                                        name:                   name,
                                        participantIdentifiers: participantIdentifiers)
            
            if verboseFunctionExposure { print("deserialised team") }
            
            completion(deSerialisedTeam, nil)
        }
    }
    
    private func validateTeamMetadata(_ withDataBundle: [String:Any]) -> Bool
    {
        guard withDataBundle["associatedIdentifier"] as? String != nil else
        { report("Malformed «associatedIdentifier».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return false }
        
        guard withDataBundle["completedChallenges"] as? [String:[String]] != nil else
        { report("Malformed «completedChallenges».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return false }
        
        guard withDataBundle["name"] as? String != nil else
        { report("Malformed «name».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return false }
        
        guard withDataBundle["participantIdentifiers"] as? [String] != nil else
        { report("Malformed «participantIdentifiers».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return false }
        
        return true
    }
}
