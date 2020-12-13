//
//  GenericTestingSerialiser.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 12/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class GenericTestingSerialiser
{
    //==================================================//
    
    /* Public Functions */
    
    func createRandomDatabase(numberOfUsers: Int, numberOfChallenges: Int, completion: @escaping(_ code: Int, _ status: String) -> Void)
    {
        let dispatchGroup = DispatchGroup()
        
        if verboseFunctionExposure { print("entering createRandomChallenges() group") }
        dispatchGroup.enter()
        
        var randomChallenges: [Challenge]?
        
        ChallengeTestingSerialiser().createRandomChallenges(amountToCreate: numberOfChallenges) { (returnedChallenges, errorDescriptor) in
            if let error = errorDescriptor
            {
                completion(1, error)
                
                dispatchGroup.leave()
            }
            else if let challenges = returnedChallenges
            {
                randomChallenges = challenges
                
                if verboseFunctionExposure { print("leaving createRandomChallenges() group") }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if verboseFunctionExposure { print("createRandomChallenges() completed") }
            
            guard let randomChallenges = randomChallenges else
            { completion(1, "Couldn't get random challenges."); return }
            
            if verboseFunctionExposure { print("entering createRandomUsers() group") }
            dispatchGroup.enter()
            
            var randomUsers: [User]?
            
            UserTestingSerialiser().createRandomUsers(amountToCreate: numberOfUsers) { (returnedUsers, errorDescriptor) in
                if let error = errorDescriptor
                {
                    completion(1, error)
                    
                    if verboseFunctionExposure { print("leaving createRandomUsers() group") }
                    dispatchGroup.leave()
                }
                else if let users = returnedUsers
                {
                    randomUsers = users
                    
                    if verboseFunctionExposure { print("leaving createRandomUsers() group") }
                    dispatchGroup.leave()
                }
            }
            
            var firstTeamIdentifier: String?
            
            dispatchGroup.notify(queue: .main) {
                if verboseFunctionExposure { print("createRandomUsers() completed") }
                
                guard let randomUsers = randomUsers else
                { completion(1, "Couldn't get random Users."); return }
                
                let completedChallenges = ChallengeTestingSerialiser().randomCompletedChallenges(fromChallenges: randomChallenges, withUsers: randomUsers)
                
                if verboseFunctionExposure { print("entering createRandomTeam() group") }
                dispatchGroup.enter()
                
                TeamTestingSerialiser().createRandomTeam(with: randomUsers, completedChallenges: completedChallenges) { (returnedIdentier, errorDescriptor) in
                    if let error = errorDescriptor
                    {
                        completion(1, error)
                        
                        if verboseFunctionExposure { print("leaving createRandomTeam() group") }
                        dispatchGroup.leave()
                    }
                    else if let identifier = returnedIdentier
                    {
                        firstTeamIdentifier = identifier
                        
                        if verboseFunctionExposure { print("leaving createRandomTeam() group") }
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    if verboseFunctionExposure { print("createRandomTeam() completed") }
                    
                    guard let firstTeamIdentifier = firstTeamIdentifier else
                    { completion(1, "Couldn't get first Team identifier."); return }
                    
                    completion(0, firstTeamIdentifier)
                }
            }
        }
    }
    
    func trashDatabase()
    {
        GenericSerialiser().setValue(onKey: "/", withData: "NULL") { (returnedError) in
            if let error = returnedError
            {
                print(error)
            }
        }
    }
}
