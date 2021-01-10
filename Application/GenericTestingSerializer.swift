//
//  GenericTestingSerializer.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 12/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class GenericTestingSerializer
{
    //==================================================//

    /* MARK: Public Functions */

    /**
     Creates a random **Team** on the server, with a number of **Users** and **Challenges** to go along with it.

     - Parameter numberOfUsers: The number of **Users** to populate the server with.
     - Parameter numberOfChallenges: The number of **Challenges** to populate the server with.
     - Parameter numberOfTeams: The number of **Teams** to populate the server with.

     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func createRandomDatabase(numberOfUsers: Int, numberOfChallenges: Int, numberOfTeams: Int, completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        //at least 2 people per team
        //so can't be an odd number < 5, can't be 2 Teams 1 User, 3 Users. Must be ≥4.

        guard numberOfUsers >= numberOfTeams * 2 else
        { completion("Number of Users must be at least double the number of Teams."); return }

        if numberOfTeams > 1 && numberOfUsers < 4
        {
            completion("Can't make Teams from \(numberOfUsers) user\(numberOfUsers == 1 ? "." : "s.")")
        }

        let dispatchGroup = DispatchGroup()

        if verboseFunctionExposure { print("entering createRandomChallenges() group") }
        dispatchGroup.enter()

        var randomChallenges: [Challenge]?

        ChallengeTestingSerializer().createRandomChallenges(amountToCreate: numberOfChallenges) { returnedChallenges, errorDescriptor in
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

            UserTestingSerializer().createRandomUsers(amountToCreate: numberOfUsers) { returnedUsers, errorDescriptor in
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

                guard var generatedRandomUsers = randomUsers else
                { completion("Couldn't get random Users."); return }

                if verboseFunctionExposure { print("entering createRandomTeams() group") }
                dispatchGroup.enter()

                var userArray2D = [[User]]()
                var challengeArray2D = [[(Challenge, [(User, Date)])]]()

                let usersPerTeam = Int(numberOfUsers / numberOfTeams)

                for currentTeam in 1 ... numberOfTeams
                {
                    generatedRandomUsers = generatedRandomUsers.shuffled()

                    var randomUsers = Array(generatedRandomUsers[0 ..< usersPerTeam])

                    if currentTeam == numberOfTeams
                    {
                        randomUsers = generatedRandomUsers
                    }

                    generatedRandomUsers.removeSubrange(0 ..< usersPerTeam)

                    let completedChallenges = ChallengeTestingSerializer().randomCompletedChallenges(fromChallenges: randomChallenges, withUsers: randomUsers)

                    let halfwayChallengesIndex = (completedChallenges.count - 1) / 2
                    let randomChallenges = Array(completedChallenges.shuffled()[0 ... halfwayChallengesIndex])

                    userArray2D.append(randomUsers)
                    challengeArray2D.append(randomChallenges)
                }

                var teamIdentifiers: [String]?

                TeamTestingSerializer().createRandomTeams(with: userArray2D, completedChallenges: challengeArray2D, amount: numberOfTeams) { returnedIdentifiers, errorDescriptor in
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

                dispatchGroup.notify(queue: .main) {
                    if verboseFunctionExposure { print("createRandomTeams() completed") }

                    guard let teamIdentifiers = teamIdentifiers else
                    { completion("Couldn't get Team identifiers."); return }

                    let universityNames = ["Princeton", "Harvard", "Columbia", "MIT", "Yale", "Stanford", "UChicago", "UPenn", "Caltech", "Johns Hopkins", "Northwestern", "Duke", "Dartmouth", "Brown", "Vanderbilt", "Rice", "WashU St. Louis", "Cornell", "Notre Dame", "UCLA", "Emory", "UC Berkeley", "Georgetown", "UMich", "USC", "UVA", "UNC Chapel Hill", "Wake Forest", "NYU", "Tufts", "UCSB"]

                    if teamIdentifiers.count == 1
                    {
                        dispatchGroup.notify(queue: .main) {
                            completion(nil)
                        }
                    }
                    else
                    {
                        let teams = teamIdentifiers.count % 2 == 0 ? teamIdentifiers : teamIdentifiers.dropLast()
                        let splitSize = (teamIdentifiers.count - (teams.last! == teamIdentifiers.last ? 0 : 1)) / 2

                        let chunks = self.chunkArray(s: teams, splitSize: splitSize)

                        var errors = [String]()

                        for chunk in chunks
                        {
                            dispatchGroup.enter()

                            let randomName = "\(universityNames.randomElement()!) Tournament (\(Int().random(min: 100, max: 999)))"

                            let randomStartDate = Date().addingTimeInterval(TimeInterval(Int("-\(Int().random(min: 86400, max: 604_800))")!))
                            let randomEndDate = Date().addingTimeInterval(TimeInterval(Int().random(min: 604_800, max: 1_209_600)))

                            TournamentSerializer().createTournament(name: randomName, startDate: randomStartDate, endDate: randomEndDate, associatedChallenges: Array(randomChallenges.shuffled()[0 ... Int().random(min: 1, max: randomChallenges.count - 1)]), teamIdentifiers: chunk) { returnedIdentifier, tournamentErrorDescriptor in
                                if let identifier = returnedIdentifier
                                {
                                    report("\(randomName): \(identifier)", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])

                                    dispatchGroup.leave()
                                }
                                else if let error = tournamentErrorDescriptor
                                {
                                    if error != "This Team is already participating in that Tournament."
                                    {
                                        errors.append(error)

                                        dispatchGroup.leave()
                                    }
                                }
                            }
                        }
                    }

                    dispatchGroup.notify(queue: .main) {
                        GenericSerializer().setValue(onKey: "/deletedUsers", withData: ["!"]) { returnedError in
                            if let error = returnedError
                            {
                                completion(errorInfo(error))
                            }
                            else
                            {
                                GenericSerializer().setValue(onKey: "/globalAnnouncement", withData: "This is a test!") { returnedError in
                                    if let error = returnedError
                                    {
                                        completion(errorInfo(error))
                                    }
                                    else { completion(nil) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func chunkArray<T>(s: [T], splitSize: Int) -> [[T]]
    {
        if s.count <= splitSize
        {
            return [s]
        }
        else { return [[T](s[0 ..< splitSize])] + chunkArray(s: [T](s[splitSize ..< s.count]), splitSize: splitSize) }
    }

    /**
     Deletes all data on the database.

     - Warning: Dumps errors to console.
     */
    func trashDatabase()
    {
        GenericSerializer().setValue(onKey: "/", withData: NSNull()) { returnedError in
            if let error = returnedError
            {
                report(error.localizedDescription, errorCode: (error as NSError).code, isFatal: false, metadata: [#file, #function, #line])
            }
        }
    }
}
