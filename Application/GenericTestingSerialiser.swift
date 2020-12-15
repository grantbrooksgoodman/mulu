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
    
    /**
     Creates a random **Team** on the server, with a number of **Users** and **Challenges** to go along with it.
     
     - Parameter numberOfUsers: The number of **Users** to populate the server with.
     - Parameter numberOfChallenges: The number of **Challenges** to populate the server with.
     
     - Parameter completion: Returns with `status` as a string and exit `code` as an integer, where **0 = success** and **1 = failure.** *NOT mutually exclusive.*
     */
    func createRandomDatabase(numberOfUsers: Int, numberOfChallenges: Int, numberOfTeams: Int, completion: @escaping(_ status: String?) -> Void)
    {
        //at least 2 people per team
        //so can't be an odd number < 5, can't be 2 Teams 1 User, 3 Users. Must be ≥4.
        
        if numberOfTeams > 1 && numberOfUsers < 4
        {
            completion("Can't make Teams from \(numberOfUsers) user\(numberOfUsers == 1 ? "." : "s.")")
        }
        
        let dispatchGroup = DispatchGroup()
        
        if verboseFunctionExposure { print("entering createRandomChallenges() group") }
        dispatchGroup.enter()
        
        var randomChallenges: [Challenge]?
        
        ChallengeTestingSerialiser().createRandomChallenges(amountToCreate: numberOfChallenges) { (returnedChallenges, errorDescriptor) in
            if let error = errorDescriptor
            {
                completion(error)
                
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
            { completion("Couldn't get random challenges."); return }
            
            if verboseFunctionExposure { print("entering createRandomUsers() group") }
            dispatchGroup.enter()
            
            var randomUsers: [User]?
            
            UserTestingSerialiser().createRandomUsers(amountToCreate: numberOfUsers) { (returnedUsers, errorDescriptor) in
                if let error = errorDescriptor
                {
                    completion(error)
                    
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
            
            dispatchGroup.notify(queue: .main) {
                if verboseFunctionExposure { print("createRandomUsers() completed") }
                
                guard let randomUsers = randomUsers else
                { completion("Couldn't get random Users."); return }
                
                let completedChallenges = ChallengeTestingSerialiser().randomCompletedChallenges(fromChallenges: randomChallenges, withUsers: randomUsers)
                
                if verboseFunctionExposure { print("entering createRandomTeams() group") }
                dispatchGroup.enter()
                
                var userArray2D: [[User]] = []
                var challengeArray2D: [[(Challenge, [(User, Date)])]] = []
                
                for _ in 0..<numberOfTeams
                {
                    let halfwayUsersIndex = (randomUsers.count - 1) / 2
                    let halfwayChallengesIndex = (completedChallenges.count - 1) / 2
                    
                    userArray2D.append(Array(randomUsers.shuffled()[0...halfwayUsersIndex]))
                    challengeArray2D.append(Array(completedChallenges.shuffled()[0...halfwayChallengesIndex]))
                }
                
                var teamIdentifiers: [String]?
                
                TeamTestingSerialiser().createRandomTeams(with: userArray2D, completedChallenges: challengeArray2D, amount: numberOfTeams - 1) { (returnedIdentifiers, errorDescriptor) in
                    if let error = errorDescriptor
                    {
                        completion(error)
                        
                        if verboseFunctionExposure { print("leaving createRandomTeams() group") }
                        dispatchGroup.leave()
                    }
                    else if let identifiers = returnedIdentifiers
                    {
                        teamIdentifiers = identifiers
                        
                        if verboseFunctionExposure { print("leaving createRandomTeams() group") }
                        dispatchGroup.leave()
                    }
                }
                
                TeamTestingSerialiser().createRandomTeam(with: randomUsers, completedChallenges: completedChallenges) { (returnedIdentier, errorDescriptor) in
                    
                }
                
                dispatchGroup.notify(queue: .main) {
                    if verboseFunctionExposure { print("createRandomTeams() completed") }
                    
                    guard let teamIdentifiers = teamIdentifiers else
                    { completion("Couldn't get Team identifiers."); return }
                    
                    let universityNames = ["Princeton", "Harvard", "Columbia", "MIT", "Yale", "Stanford", "UChicago", "UPenn", "Caltech", "Johns Hopkins", "Northwestern", "Duke", "Dartmouth", "Brown", "Vanderbilt", "Rice", "WashU St. Louis", "Cornell", "Notre Dame", "UCLA", "Emory", "UC Berkeley", "Georgetown", "UMich", "USC", "UVA", "UNC Chapel Hill", "Wake Forest", "NYU", "Tufts", "UCSB"]
                    
                    let randomTournamentCount = Int().random(min: 1, max: numberOfTeams)
                    
                    let halfwayTeamsIndex = (teamIdentifiers.count - 1) / 2
                    
                    var errors: [String] = []
                    
                    for _ in 0...randomTournamentCount
                    {
                        dispatchGroup.enter()
                        
                        let randomName = "\(universityNames.randomElement()!) Tournament (\(Int().random(min: 100, max: 999)))"
                        
                        let randomStartDate = Date().addingTimeInterval(TimeInterval(Int("-\(Int().random(min: 86400, max: 604800))")!))
                        let randomEndDate = Date().addingTimeInterval(TimeInterval(Int().random(min: 604800, max: 1209600)))
                        
                        TournamentSerialiser().createTournament(name: randomName, startDate: randomStartDate, endDate: randomEndDate, teamIdentifiers: Array(teamIdentifiers.shuffled()[0...halfwayTeamsIndex])) { (returnedIdentifier, errorDescriptor) in
                            if let identifier = returnedIdentifier
                            {
                                report("\(randomName): \(identifier)", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                                
                                dispatchGroup.leave()
                            }
                            else if let error = errorDescriptor
                            {
                                if error != "This Team is already participating in that Tournament."
                                {
                                    errors.append(error)
                                    
                                    dispatchGroup.leave()
                                }
                            }
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    /**
     Deletes all data on the database.
     */
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
