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
    
    /**
     Adds an array of completed **Challenges** to a **Team** on the server.
     
     - Parameter withBundle: The completed **Challenges** to add to or populate this **Team** with.
     - Parameter toTeam: The identifier of the **Team** to add these **Challenges** to.
     - Parameter overwrite: A Boolean describing whether to add these **Challenges** to the **Team** with or without overwriting the previous data.
     
     - Parameter completion: Upon failure, returns with a string describing the error encountered.
     */
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
    
    /**
     Adds an array of **Users** to a **Team**.
     
     - Parameter users: The **Users** to add to this **Team**.
     - Parameter toTeam: The **Team** to add these **Users** to.
     
     - Parameter completion: Upon failure, returns with a string describing the error encountered.
     */
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
    
    func addTeams(_ withIdentifiers: [String], toTournament: String, completion: @escaping(_ errorDescriptor: String?) -> Void)
    {
        for (index, identifier) in withIdentifiers.enumerated()
        {
            addTeam(identifier, toTournament: toTournament) { (errorDescriptor) in
                if let error = errorDescriptor
                {
                    completion(error)
                }
                else
                {
                    if index == withIdentifiers.count - 1
                    {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    #warning("Sometimes «associatedTournament» is not correctly set. (?)")
    /**
     Adds a **Team** to a **Tournament.**
     
     - Parameter withIdentifier: The identifier of the **Team** to add to this **Tournament.**
     - Parameter toTournament: The identifier of the **Tournament** to add this **Team** to.
     
     - Parameter completion: Upon failure, returns with a string describing the error encountered.
     */
    func addTeam(_ withIdentifier: String, toTournament: String, completion: @escaping(_ errorDescriptor: String?) -> Void)
    {
        let group = DispatchGroup()
        
        group.enter()
        
        var newAssociatedTournament: String?
        var newTeamIdentifiers: [String]?
        
        Database.database().reference().child("allTeams").child(withIdentifier).observeSingleEvent(of: .value, with: { (returnedSnapshot) in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary,
               let asDataBundle =                 returnedSnapshotAsDictionary as? [String:Any]
            {
                var mutableDataBundle = asDataBundle
                mutableDataBundle["associatedIdentifier"] = withIdentifier
                
                guard self.validateTeamMetadata(mutableDataBundle) == true else
                { completion("Improperly formatted metadata."); return }
                
                let associatedTournament = mutableDataBundle["associatedTournament"] as! String
                
                if associatedTournament != "!"
                {
                    group.leave()
                    
                    completion("The specified Team is already participating in a Tournament.")
                }
                else
                {
                    newAssociatedTournament = toTournament
                    
                    group.leave()
                }
            }
        })
        { (returnedError) in
            group.leave()
            
            completion("Unable to retrieve the specified data. (\(returnedError.localizedDescription))")
        }
        
        group.notify(queue: .main) {
            guard newAssociatedTournament != nil else
            { completion("Couldn't get new associated Tournament."); return }
            
            group.enter()
            
            Database.database().reference().child("allTournaments").child(toTournament).observeSingleEvent(of: .value, with: { (returnedSnapshot) in
                if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary,
                   let asDataBundle =                 returnedSnapshotAsDictionary as? [String:Any]
                {
                    guard var teamIdentifiers = asDataBundle["teamIdentifiers"] as? [String] else
                    { completion("This Tournament has corrupted «teamIdentifiers»."); return }
                    
                    teamIdentifiers = teamIdentifiers.filter({$0 != "!"})
                    
                    teamIdentifiers.append(withIdentifier)
                    newTeamIdentifiers = teamIdentifiers
                    
                    group.leave()
                }
            })
            { (returnedError) in
                group.leave()
                
                completion("Unable to retrieve the specified data. (\(returnedError.localizedDescription))")
            }
            
            group.notify(queue: .main) {
                guard let newAssociatedTournament = newAssociatedTournament else
                { completion("Couldn't get new associated Tournament."); return }
                
                guard let newTeamIdentifiers = newTeamIdentifiers?.unique() else
                { completion("Couldn't get new associated Teams."); return }
                
                //                guard newAssociatedTournaments.unique() == newAssociatedTournaments && newTeamIdentifiers.unique() == newTeamIdentifiers else
                //                { completion("This Team is already participating in that Tournament."); return }
                
                group.enter()
                
                GenericSerialiser().updateValue(onKey: "/allTeams/\(withIdentifier)", withData: ["associatedTournament": newAssociatedTournament]) { (returnedError) in
                    
                    if let error = returnedError
                    {
                        group.leave()
                        
                        completion(errorInformation(forError: (error as NSError)))
                    }
                    else
                    {
                        GenericSerialiser().updateValue(onKey: "/allTournaments/\(toTournament)", withData: ["teamIdentifiers": newTeamIdentifiers]) { (returnedError) in
                            if let error = returnedError
                            {
                                group.leave()
                                
                                completion(errorInformation(forError: (error as NSError)))
                            }
                            else
                            {
                                group.leave()
                            }
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    completion(nil)
                }
            }
        }
    }
    
    /**
     Adds a **User** to a **Team**.
     
     - Parameter withIdentifier: The identifier of the **User** to add to this **Team**.
     - Parameter toTeam: The identifier of the **Team** to add this **User** to.
     
     - Parameter completion: Upon failure, returns with a string describing the error encountered.
     */
    func addUser(_ withIdentifier: String, toTeam: String, completion: @escaping(_ errorDescriptor: String?) -> Void)
    {
        let group = DispatchGroup()
        
        group.enter()
        
        var newUserList: [String]?
        var newAssociatedTeams: [String]?
        
        Database.database().reference().child("allTeams").child(toTeam).observeSingleEvent(of: .value, with: { (returnedSnapshot) in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary,
               let asDataBundle =                 returnedSnapshotAsDictionary as? [String:Any]
            {
                var mutableDataBundle = asDataBundle
                mutableDataBundle["associatedIdentifier"] = withIdentifier
                
                guard self.validateTeamMetadata(mutableDataBundle) == true else
                { completion("Improperly formatted metadata."); return }
                
                newUserList = (mutableDataBundle["participantIdentifiers"] as! [String])
                newUserList!.append(withIdentifier)
                
                group.leave()
            }
        })
        { (returnedError) in
            
            completion("Unable to retrieve the specified data. (\(returnedError.localizedDescription))")
        }
        
        group.notify(queue: .main) {
            guard newUserList != nil else
            { completion("Couldn't get new User list."); return }
            
            group.enter()
            
            Database.database().reference().child("allUsers").child(withIdentifier).observeSingleEvent(of: .value, with: { (returnedSnapshot) in
                if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary,
                   let asDataBundle =                 returnedSnapshotAsDictionary as? [String:Any]
                {
                    guard var associatedTeams = asDataBundle["associatedTeams"] as? [String] else
                    { completion("This user has corrupted «associatedTeams»."); return }
                    
                    associatedTeams.append(toTeam)
                    newAssociatedTeams = associatedTeams
                    
                    group.leave()
                }
            })
            { (returnedError) in
                
                completion("Unable to retrieve the specified data. (\(returnedError.localizedDescription))")
            }
            
            group.notify(queue: .main) {
                guard let newUserList = newUserList else
                { completion("Couldn't get new User list."); return }
                
                guard let newAssociatedTeams = newAssociatedTeams else
                { completion("Couldn't get new associated Teams."); return }
                
                guard newUserList.unique() == newUserList && newAssociatedTeams.unique() == newAssociatedTeams else
                { completion("This User is already on that Team."); return }
                
                group.enter()
                
                GenericSerialiser().updateValue(onKey: "/allTeams/\(toTeam)", withData: ["participantIdentifiers": newUserList]) { (returnedError) in
                    if let error = returnedError
                    {
                        group.leave()
                        
                        completion(errorInformation(forError: (error as NSError)))
                    }
                    else
                    {
                        GenericSerialiser().updateValue(onKey: "/allUsers/\(withIdentifier)", withData: ["associatedTeams": newAssociatedTeams]) { (returnedError) in
                            if let error = returnedError
                            {
                                group.leave()
                                
                                completion(errorInformation(forError: (error as NSError)))
                            }
                            else
                            {
                                report("Successfully added User to Team.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                                
                                group.leave()
                                
                                completion(nil)
                            }
                        }
                    }
                }
            }
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
        
        dataBundle["associatedTournament"] = "!"
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
        let associatedTournament = dataBundle["associatedTournament"] as! String
        let completedChallenges = dataBundle["completedChallenges"] as! [String:[String]]
        let name = dataBundle["name"] as! String
        let participantIdentifiers = dataBundle["participantIdentifiers"] as! [String]
        
        var deSerialisedCompletedChallenges: [(Challenge, [(user: User, dateCompleted: Date)])]?
        
        let group = DispatchGroup()
        
        group.enter()
        
        if completedChallenges.keys.first != "!"
        {
            deSerialiseCompletedChallenges(with: completedChallenges) { (completedChallenges, errorDescriptor) in
                if let error = errorDescriptor
                {
                    if verboseFunctionExposure { print("failed to deserialise completed challenges") }
                    
                    group.leave()
                    
                    completion(nil, error)
                }
                else if let challenges = completedChallenges
                {
                    deSerialisedCompletedChallenges = challenges
                    
                    group.leave()
                }
                else
                {
                    group.leave()
                    
                    completion(nil, "An unknown error occurred.")
                }
            }
        }
        else
        {
            deSerialisedCompletedChallenges = []
            
            group.leave()
        }
        
        group.notify(queue: .main) {
            guard let completedChallenges = deSerialisedCompletedChallenges else
            { completion(nil, "Couldn't get completed Challenges."); return }
            
            if associatedTournament != "!"
            {
                group.enter()
                
                TournamentSerialiser().getTournament(withIdentifier: associatedTournament) { (returnedTournament, errorDescriptor) in
                    if let tournament = returnedTournament
                    {
                        let deSerialisedTeam = Team(associatedIdentifier:   associatedIdentifier,
                                                    associatedTournament:   tournament,
                                                    completedChallenges:    completedChallenges,
                                                    name:                   name,
                                                    participantIdentifiers: participantIdentifiers)
                        
                        group.leave()
                        
                        completion(deSerialisedTeam, nil)
                    }
                    else
                    {
                        group.leave()
                        
                        completion(nil, errorDescriptor)
                    }
                }
            }
            else
            {
                let deSerialisedTeam = Team(associatedIdentifier:   associatedIdentifier,
                                            associatedTournament:   nil,
                                            completedChallenges:    completedChallenges,
                                            name:                   name,
                                            participantIdentifiers: participantIdentifiers)
                
                completion(deSerialisedTeam, nil)
            }
        }
    }
    
    /**
     Serialises an array of completed **Challenges** for the server.
     
     - Parameter with: The array of completed **Challenges** to serialise.
     */
    private func serialiseCompletedChallenges(_ with: [(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])]) -> [String:[String]]
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
    
    /**
     Validates the contents of a serialised **Team**.
     
     - Parameter withDataBundle: The serialised **Team** whose structural integrity will be verified.
     */
    private func validateTeamMetadata(_ withDataBundle: [String:Any]) -> Bool
    {
        guard withDataBundle["associatedIdentifier"] as? String != nil else
        { report("Malformed «associatedIdentifier».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return false }
        
        guard withDataBundle["associatedTournament"] as? String != nil else
        { report("Malformed «associatedTournament».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return false }
        
        guard withDataBundle["completedChallenges"] as? [String:[String]] != nil else
        { report("Malformed «completedChallenges».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return false }
        
        guard withDataBundle["name"] as? String != nil else
        { report("Malformed «name».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return false }
        
        guard withDataBundle["participantIdentifiers"] as? [String] != nil else
        { report("Malformed «participantIdentifiers».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return false }
        
        return true
    }
}
