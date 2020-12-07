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
                else { completion(generatedKey, nil) }
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
        Database.database().reference().child("allTeams").child(withIdentifier).observeSingleEvent(of: .value, with: { (returnedSnapshot) in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary, let asDataBundle = returnedSnapshotAsDictionary as? [String:Any]
            {
                var mutableDataBundle = asDataBundle
                
                mutableDataBundle["associatedIdentifier"] = withIdentifier
                
                self.deSerialiseTeam(from: mutableDataBundle) { (returnedTeam, errorDescriptor) in
                    if let error = errorDescriptor
                    {
                        completion(nil, error)
                    }
                    else if let team = returnedTeam
                    {
                        completion(team, nil)
                    }
                }
            }
            else { completion(nil, "No Team exists with the identifier \"\(withIdentifier)\".") }
        })
        { (returnedError) in
            
            completion(nil, "Unable to retrieve the specified data. (\(returnedError.localizedDescription))")
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
        var deSerialisedCompletedChallenges: [(Challenge, [(user: User, dateCompleted: Date)])] = []
        
        //serialised completed challenges = ["challengeId":["userId – dateString"]]
        
        for challengeIdentifier in Array(challenges.keys)
        {
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
                                    else { completion(nil, "The deserialised completed Challenges array was malformed.") }
                                }
                            }
                            else { completion(nil, "An unknown error occurred while getting a User for a Challenge.") }
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
        guard let associatedIdentifier = dataBundle["associatedIdentifier"] as? String else
        { completion(nil, "Unable to deserialise «associatedIdentifier»."); return }
        
        guard let completedChallenges = dataBundle["completedChallenges"] as? [String:[String]] else
        { completion(nil, "Unable to deserialise «completedChallenges»."); return }
        
        guard let name = dataBundle["name"] as? String else
        { completion(nil, "Unable to deserialise «name»."); return }
        
        guard let participantIdentifiers = dataBundle["participantIdentifiers"] as? [String] else
        { completion(nil, "Unable to deserialise «participantIdentifiers»."); return }
        
        if completedChallenges.keys.first != "!"
        {
            deSerialiseCompletedChallenges(with: completedChallenges) { (completedChallenges, errorDescriptor) in
                if let error = errorDescriptor
                {
                    completion(nil, error)
                }
                else if let challenges = completedChallenges
                {
                    let deSerialisedTeam = Team(associatedIdentifier:   associatedIdentifier,
                                                completedChallenges:    challenges,
                                                name:                   name,
                                                participantIdentifiers: participantIdentifiers)
                    
                    completion(deSerialisedTeam, nil)
                }
            }
        }
        else
        {
            let deSerialisedTeam = Team(associatedIdentifier:   associatedIdentifier,
                                        completedChallenges:    nil,
                                        name:                   name,
                                        participantIdentifiers: participantIdentifiers)
            
            completion(deSerialisedTeam, nil)
        }
    }
}
