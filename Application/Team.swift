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

    /* MARK: Class-level Variable Declarations */

    //Arrays
    private(set) var DSParticipants: [User]?

    var completedChallenges:    [(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])]?
    var participantIdentifiers: [String: Int]! //["userID – 10"]

    //Strings
    var associatedIdentifier: String!
    var joinCode:             String!
    var name:                 String!

    //Other Declarations
    var additionalPoints: Int!
    var associatedTournament:  Tournament?

    //==================================================//

    /* MARK: Constructor Function */

    init(associatedIdentifier:   String,
         additionalPoints:       Int,
         associatedTournament:   Tournament?,
         completedChallenges:    [(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])]?,
         joinCode:               String,
         name:                   String,
         participantIdentifiers: [String: Int])
    {
        self.associatedIdentifier   = associatedIdentifier
        self.additionalPoints       = additionalPoints
        self.associatedTournament   = associatedTournament
        self.completedChallenges    = completedChallenges
        self.joinCode               = joinCode
        self.name                   = name
        self.participantIdentifiers = participantIdentifiers
    }

    //==================================================//

    /* MARK: Getter Functions */

    /**
     Gets the total accrued points of a specific **User** on the **Team.**

     - Parameter userIdentifier: The identifier of the **User** to get accrued points for.

     - Returns: An integer describing the specified **User's** total accrued points on the **Team.**
     */
    func getAccruedPoints(for userIdentifier: String) -> Int
    {
        guard Array(participantIdentifiers.keys).contains(userIdentifier) else
        {
            if verboseFunctionExposure { report("This User isn't on that Team.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }

            return -1
        }

        guard let challenges = completedChallenges,
              challenges.first(where: { $0.metadata.first(where: { $0.user.associatedIdentifier == userIdentifier }) != nil }) != nil else
        {
            if verboseFunctionExposure { report("This User hasn't completed any Challenges for this Team.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }

            #warning("Or maybe return 0?")
            return -1
        }

        return challenges.accruedPoints(for: userIdentifier)
    }

    /**
     Gets the **Team's** rank in its associated **Tournament.**

     - Parameter completion: Upon success, returns an integer describing **Team's** rank. Upon failure, returns a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*
     - Requires: The **Team** to be participating in a **Tournament.**

     ~~~
     completion(returnedRank, errorDescriptor)
     ~~~
     */
    func getRank(completion: @escaping (_ returnedRank: Int?, _ errorDescriptor: String?) -> Void)
    {
        guard let tournament = associatedTournament else
        { completion(nil, "This Team is not participating in any Tournament."); return }

        TeamSerializer().getTeams(withIdentifiers: tournament.teamIdentifiers) { returnedTeams, errorDescriptors in
            if let teams = returnedTeams
            {
                var totalPoints = [Int]()

                for team in teams
                {
                    guard team.DSParticipants != nil else
                    { completion(nil, "Participants haven't been deserialized."); return }

                    totalPoints.append(team.getTotalPoints())
                }

                completion(totalPoints.sorted(by: { $0 > $1 }).firstIndex(of: self.getTotalPoints())! + 1, nil)
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

        for user in Array(participantIdentifiers.keys)
        {
            total += participantIdentifiers[user]!
        }

        return total + additionalPoints
    }

    //==================================================//

    /* MARK: Serialization Functions */

    /**
     Gets and deserializes all of the **Users** in the **Team's** *participantIdentifiers* array.

     - Parameter completion: Upon success, returns an an array of deserialized **User** objects. Upon failure, returns a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*

     ~~~
     completion(returnedUsers, errorDescriptor)
     ~~~
     */
    func deSerializeParticipants(completion: @escaping (_ returnedUsers: [User]?, _ errorDescriptor: String?) -> Void)
    {
        if let DSParticipants = DSParticipants
        {
            completion(DSParticipants, nil)
        }
        else if let participantIdentifiers = participantIdentifiers
        {
            UserSerializer().getUsers(withIdentifiers: Array(participantIdentifiers.keys)) { returnedUsers, errorDescriptors in
                if let errors = errorDescriptors
                {
                    completion(nil, errors.unique().joined(separator: "\n"))
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
        else { report("This Team does not have any Users.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
    }

    /**
     Serialises the **Team's** completed **Challenges.**

     - Returns: A dictionary describing the **Team's** completed **Challenges.**
     */
    func serializeCompletedChallenges() -> [String: [String]]
    {
        guard let challenges = completedChallenges else
        { return [:] }

        var dataBundle: [String: [String]] = [:]

        for bundle in challenges
        {
            //["challengeId":["userId – dateString"]]
            var serializedMetadata = [String]()

            for datum in bundle.metadata
            {
                let metadataString = "\(datum.user.associatedIdentifier!) – \(secondaryDateFormatter.string(from: datum.dateCompleted))"
                serializedMetadata.append(metadataString)
            }

            dataBundle["\(bundle.challenge.associatedIdentifier!)"] = serializedMetadata
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
            UserSerializer().getUsers(withIdentifiers: Array(participantIdentifiers.keys)) { returnedUsers, errorDescriptors in
                if let errors = errorDescriptors
                {
                    report(errors.unique().joined(separator: "\n"), errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                }
                else if let users = returnedUsers
                {
                    self.DSParticipants = users

                    if verboseFunctionExposure { report("Successfully set «DSParticipants».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
                }
                else { report("No returned Users, but no error either.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
            }
        }
        else { report("This User is not a member of any Team.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
    }

    //==================================================//

    /* MARK: Update Functions */

    /**
     Updates the **Team's** metadata from the server.

     - Parameter completion: Upon failure, returns a string describing the error(s) encountered.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func reloadData(completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        TeamSerializer().getTeam(withIdentifier: associatedIdentifier) { returnedTeam, errorDescriptor in
            if let team = returnedTeam
            {
                self.associatedIdentifier   = team.associatedIdentifier
                self.additionalPoints       = team.additionalPoints
                self.associatedTournament   = team.associatedTournament
                self.completedChallenges    = team.completedChallenges
                self.joinCode               = team.joinCode
                self.name                   = team.name
                self.participantIdentifiers = team.participantIdentifiers

                team.deSerializeParticipants { returnedUsers, errorDescriptor in
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
     Updates the **Team's** *additionalPoints.*

     - Parameter points: The points to set for this **Team.**
     - Parameter completion: Upon failure, returns a string describing the error(s) encountered.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func updateAdditionalPoints(_ points: Int, completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        GenericSerializer().setValue(onKey: "/allTeams/\(associatedIdentifier!)/additionalPoints", withData: points) { returnedError in
            if let error = returnedError
            {
                completion(errorInfo(error))
            }
            else
            {
                #warning("Considering the use cases, is this really necessary?")
                self.reloadData { errorDescriptor in
                    if let error = errorDescriptor
                    {
                        completion(error)
                    }
                    else { completion(nil) }
                }
            }
        }
    }

    /**
     Updates the **Team's** name.

     - Parameter name: The string of the new name for this **Team.**
     - Parameter completion: Upon failure, returns a string describing the error(s) encountered.

     - Requires: The `name` to be different from the **Team's** current name.
     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func updateName(_ name: String, completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        guard name != self.name else
        { completion("No changes made."); return }

        GenericSerializer().setValue(onKey: "/allTeams/\(associatedIdentifier!)/name", withData: name) { returnedError in
            if let error = returnedError
            {
                completion(errorInfo(error))
            }
            else { completion(nil) }
        }
    }

    /**
     Updates the **Tournament's** *teamIdentifiers* array.

     - Parameter teams: An array with the identifiers of the **Teams** to associate with this **Tournament.**
     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.

     - Requires: The `teams` array to not be empty.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func updateParticipantIdentifiers(_ newIdentifiers: [String: Int], completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        guard !newIdentifiers.isEmpty else
        { completion("The participant identifiers array was empty; Teams must be associated with at least one User."); return }

        let usersToRemove = participantIdentifiers.keys.filter { !newIdentifiers.keys.contains($0) }
        let usersToAdd = newIdentifiers.keys.filter { !participantIdentifiers.keys.contains($0) }

        if !usersToRemove.isEmpty
        {
            var errors = [String]()

            for (index, user) in usersToRemove.enumerated()
            {
                TeamSerializer().removeUser(user, fromTeam: associatedIdentifier, deleting: true) { errorDescriptor in
                    if let error = errorDescriptor
                    {
                        errors.append(error)

                        if index == usersToRemove.count - 1
                        {
                            completion(errors.unique().joined(separator: "\n"))
                        }
                    }
                    else
                    {
                        if index == usersToRemove.count - 1
                        {
                            if errors.isEmpty
                            {
                                if !usersToAdd.isEmpty
                                {
                                    self.finishUpdateParticipantIdentifiers(newIdentifiers, usersToAdd) { errorDescriptor in
                                        completion(errorDescriptor)
                                    }
                                }
                                else { completion(nil) }
                            }
                            else { completion(errors.unique().joined(separator: "\n")) }
                        }
                    }
                }
            }
        }
        else if !usersToAdd.isEmpty
        {
            finishUpdateParticipantIdentifiers(newIdentifiers, usersToAdd) { errorDescriptor in
                completion(errorDescriptor)
            }
        }
        else { completion("No changes made.") }
    }

    #warning("Would it be better to have this in TeamSerializer? (Probably not...)")
    /**
     Updates a **User's** additional points for this **Team.**

     - Parameter points: The points to set for the **User** on this **Team.**
     - Parameter forUser: The identifier of the **User** whose additional points will be set.

     - Parameter completion: Upon failure, returns a string describing the error(s) encountered.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func updatePoints(_ points: Int, forUser: String, completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        guard Array(participantIdentifiers.keys).contains(forUser) else
        { completion("The specified User is not a member of this Team."); return }

        var newParticipantIdentifiers = participantIdentifiers!
        newParticipantIdentifiers[forUser] = points

        GenericSerializer().setValue(onKey: "/allTeams/\(associatedIdentifier!)/participantIdentifiers", withData: newParticipantIdentifiers.delimitedArray()) { returnedError in
            if let error = returnedError
            {
                completion(errorInfo(error))
            }
            else
            {
                #warning("Considering the use cases, is this really necessary?")
                self.reloadData { errorDescriptor in
                    if let error = errorDescriptor
                    {
                        completion(error)
                    }
                    else { completion(nil) }
                }
            }
        }
    }

    //==================================================//

    /* MARK: Other Functions */

    //==================================================//

    /* MARK: Private Functions */

    private func finishUpdateParticipantIdentifiers(_ newIdentifiers: [String: Int], _ usersToAdd: [String], completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        GenericSerializer().setValue(onKey: "/allTeams/\(associatedIdentifier!)/participantIdentifiers", withData: newIdentifiers.delimitedArray()) { returnedError in
            if let error = returnedError
            {
                completion(errorInfo(error))
            }
            else
            {
                var errors = [String]()

                for (index, user) in usersToAdd.enumerated()
                {
                    TeamSerializer().addUser(user, toTeam: self.associatedIdentifier) { errorDescriptor in
                        if let error = errorDescriptor
                        {
                            errors.append(error)

                            if index == usersToAdd.count - 1
                            {
                                completion(errors.unique().joined(separator: "\n"))
                            }
                        }
                        else
                        {
                            if index == usersToAdd.count - 1
                            {
                                completion(errors.isEmpty ? nil : errors.unique().joined(separator: "\n"))
                            }
                        }
                    }
                }
            }
        }
    }
}
