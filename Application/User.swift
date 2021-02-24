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

    /* MARK: Class-level Variable Declarations */

    //Arrays
    var associatedTeams: [String]?
    var pushTokens:      [String]?

    //Strings
    var associatedIdentifier: String!
    var emailAddress:         String!
    var firstName:            String!
    var lastName:             String!
    var profileImageData:     String?

    private(set) var DSAssociatedTeams: [Team]?

    //==================================================//

    /* MARK: Constructor Function */

    init(associatedIdentifier: String,
         associatedTeams:      [String]?,
         emailAddress:         String,
         firstName:            String,
         lastName:             String,
         profileImageData:     String?,
         pushTokens:           [String]?)
    {
        self.associatedIdentifier = associatedIdentifier
        self.associatedTeams      = associatedTeams
        self.emailAddress         = emailAddress
        self.firstName            = firstName
        self.lastName             = lastName
        self.profileImageData     = profileImageData
        self.pushTokens           = pushTokens
    }

    //==================================================//

    /* MARK: Public Functions */

    /**
     Gets all of the **User's** completed **Challenges.**

     - Requires: *DSAssociatedTeams* to have been set.
     - Returns: An array of `(Date, Challenge)` tuples.
     */
    func allCompletedChallenges() -> [(date: Date, challenge: Challenge)]?
    {
        guard let DSAssociatedTeams = DSAssociatedTeams else { report("Teams haven't been deserialized.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return nil }

        var matchingChallenges = [(date: Date, challenge: Challenge)]()

        for team in DSAssociatedTeams
        {
            if let challenges = team.completedChallenges
            {
                for challenge in challenges
                {
                    if !challenge.metadata.filter({ $0.user.associatedIdentifier == associatedIdentifier }).isEmpty
                    {
                        matchingChallenges.append((challenge.metadata.first(where: { $0.user.associatedIdentifier == associatedIdentifier })!.dateCompleted, challenge.challenge))
                    }
                }
            }
        }

        return matchingChallenges.isEmpty ? nil : matchingChallenges
    }

    /**
     Gets any **Challenges** the **User** has yet to complete on the specified **Team.**

     - Parameter team: The **Team** on which to find incomplete **Challenges** for this **User.**
     - Parameter completion: Upon success, returns with an array of **Challenge** identifiers. Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*

     ~~~
     completion(returnedIdentifiers, errorDescriptor)
     ~~~
     */
    func challengesToComplete(on team: Team, completion: @escaping (_ returnedIdentifiers: [String]?, _ errorDescriptor: String?) -> Void)
    {
        let previouslyCompleted = completedChallenges(on: team) ?? []
        var incompleteChallenges = [(identifier: String, datePosted: Date)]()

        Database.database().reference().child("allChallenges").observeSingleEvent(of: .value) { returnedSnapshot in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary,
               let asDataBundle = returnedSnapshotAsDictionary as? [String: Any]
            {
                for (index, identifier) in Array(asDataBundle.keys).enumerated()
                {
                    if !previouslyCompleted.contains(where: { $0.challenge.associatedIdentifier == identifier })
                    {
                        if let data = asDataBundle[identifier] as? [String: Any],
                           let datePostedString = data["datePosted"] as? String,
                           let datePosted = secondaryDateFormatter.date(from: datePostedString)
                        {
                            incompleteChallenges.append((identifier, datePosted))
                        }
                    }

                    if index == asDataBundle.keys.count - 1
                    {
                        if incompleteChallenges.isEmpty
                        {
                            completion(nil, "User has completed all Challenges.")
                        }
                        else
                        {
                            incompleteChallenges.sort(by: { $0.datePosted < $1.datePosted })

                            var identifiers = [String]()

                            for challenge in incompleteChallenges
                            {
                                identifiers.append(challenge.identifier)
                            }

                            completion(identifiers, nil)
                        }
                    }
                }
            }
            else { completion(nil, "Unable to deserialize snapshot.") }
        }
    }

    /**
     Marks a **Challenge** as completed both locally and on the server.

     - Parameter withIdentifier: The identifier of the **Challenge** to be marked complete.
     - Parameter team: The **Team** on which to mark this **Challenge** complete.

     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func completeChallenge(withIdentifier: String, on team: Team, completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        let serializedData = "\(associatedIdentifier!) – \(secondaryDateFormatter.string(from: Date()))"

        ChallengeSerializer().getChallenge(withIdentifier: withIdentifier) { returnedChallenge, _ in
            if let challenge = returnedChallenge
            {
                TeamSerializer().getTeam(withIdentifier: team.associatedIdentifier) { returnedTeam, _ in
                    if let returnedTeam = returnedTeam {
                        print("returnedTeam: \(String(describing: returnedTeam.associatedIdentifier))")
                        var newCompletedChallenges = returnedTeam.serializeCompletedChallenges()

                        if let completedChallenges = returnedTeam.completedChallenges
                        {
                            if let index = completedChallenges.challenges().firstIndex(where: { $0.associatedIdentifier == withIdentifier })
                            {
                                returnedTeam.completedChallenges![index].metadata.append((self, Date()))
                            }
                            else { returnedTeam.completedChallenges!.append((challenge, [(self, Date())])) }
                        }
                        else { returnedTeam.completedChallenges = [(challenge, [(self, Date())])] }

                        if newCompletedChallenges[withIdentifier] != nil
                        {
                            newCompletedChallenges[withIdentifier]!.append(serializedData)
                        }
                        else { newCompletedChallenges[withIdentifier] = [serializedData] }
                        currentTeam = returnedTeam
                        GenericSerializer().updateValue(onKey: "/allTeams/\(team.associatedIdentifier!)/", withData: ["completedChallenges": newCompletedChallenges]) { returnedError in
                            if let error = returnedError
                            {
                                completion(errorInfo(error))
                            }
                            else { completion(nil) }
                        }
                    } else {
                        completion("Couldn't get Team.")
                    }
                }
            } else {
                completion("Couldn't get Challenge.")
            }
        }
    }

    /**
     Returns the **User's** completed **Challenges** on the specified **Team.**

     - Parameter team: The **Team** on which to query for completed **Challenges.**

     - Returns: An array of `(Date, Challenge)` tuples.
     */
    func completedChallenges(on team: Team) -> [(date: Date, challenge: Challenge)]?
    {
        var matchingChallenges = [(date: Date, challenge: Challenge)]()

        if let challenges = team.completedChallenges
        {
            for challenge in challenges
            {
                if !challenge.metadata.filter({ $0.user.associatedIdentifier == associatedIdentifier }).isEmpty
                {
                    if verboseFunctionExposure { print("\(firstName!) completed '\(challenge.challenge.title!)' for \(challenge.challenge.pointValue!)pts.") }

                    matchingChallenges.append((challenge.metadata.first(where: { $0.user.associatedIdentifier == associatedIdentifier })!.dateCompleted, challenge.challenge))
                }
            }
        }

        return matchingChallenges.isEmpty ? nil : matchingChallenges
    }

    /**
     Gets and deserializes all of the **Teams** the **User** is a member of using the *associatedTeams* array.

     - Parameter completion: Upon success, returns an array of deserialized **Team** objects. Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*
     */
    func deSerializeAssociatedTeams(completion: @escaping (_ returnedTeams: [Team]?, _ errorDescriptor: String?) -> Void)
    {
        if let DSAssociatedTeams = DSAssociatedTeams
        {
            completion(DSAssociatedTeams, nil)
        }
        else if let associatedTeams = associatedTeams,
                !associatedTeams.filter({ $0 != "!" }).isEmpty
        {
            TeamSerializer().getTeams(withIdentifiers: associatedTeams.filter { $0 != "!" }) { returnedTeams, errorDescriptors in
                if let errors = errorDescriptors
                {
                    completion(nil, errors.unique().joined(separator: "\n"))
                }
                else if let teams = returnedTeams
                {
                    self.DSAssociatedTeams = teams

                    completion(teams, nil)
                }
                else { completion(nil, "No returned Teams, but no error either.") }
            }
        }
        else { completion(nil, "This User is not a member of any Team.") }
    }

    /**
     Updates the **User's** metadata from the server.

     - Parameter completion: Upon failure, returns a string describing the error(s) encountered.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func reloadData(completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        UserSerializer().getUser(withIdentifier: associatedIdentifier) { returnedUser, errorDescriptor in
            if let user = returnedUser
            {
                self.associatedTeams = user.associatedTeams
                self.emailAddress = user.emailAddress
                self.firstName = user.firstName
                self.lastName = user.lastName
                self.profileImageData = user.profileImageData
                self.pushTokens = user.pushTokens

                self.deSerializeAssociatedTeams { returnedTeams, errorDescriptor in
                    if let teams = returnedTeams
                    {
                        self.DSAssociatedTeams = teams

                        completion(nil)
                    }
                    else { completion(errorDescriptor!) }
                }
            }
            else { completion(errorDescriptor!) }
        }
    }

    /**
     Sets the *DSAssociatedTeams* value on the **User.**

     - Warning: Dumps errors to console.
     */
    func setDSAssociatedTeams()
    {
        if DSAssociatedTeams != nil
        {
            report("«DSAssociatedTeams» already set.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
        }
        else if let associatedTeams = associatedTeams,
                !associatedTeams.filter({ $0 != "!" }).isEmpty
        {
            TeamSerializer().getTeams(withIdentifiers: associatedTeams.filter { $0 != "!" }) { returnedTeams, errorDescriptors in
                if let errors = errorDescriptors
                {
                    report(errors.unique().joined(separator: "\n"), errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                }
                else if let teams = returnedTeams
                {
                    self.DSAssociatedTeams = teams

                    if verboseFunctionExposure { report("Successfully set «DSAssociatedTeams».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
                }
            }
        }
        else { report("This User is not a member of any Team.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
    }

    /**
     Gets the **User's** streak on the specified **Team.**

     - Parameter team: The **Team** on which calculate a streak.

     - Returns: An integer describing the amount of consecutive days the **User** has completed a **Challenge.**
     */
    func streak(on team: Team) -> Int
    {
        var total = 0

        if let challenges = completedChallenges(on: team)
        {
            let enumeratedDates = challenges.dates().sorted()

            guard enumeratedDates.last!.comparator >= currentCalendar.date(byAdding: .day, value: -1, to: Date())!.comparator else
            { return 0 }

            if enumeratedDates.count == 1,
               enumeratedDates[0].comparator == Date().comparator
            {
                return 1
            }
            else
            {
                for (index, date) in enumeratedDates.unique().enumerated()
                {
                    let nextIndex = index + 1

                    if nextIndex < enumeratedDates.count
                    {
                        if date.comparator == enumeratedDates[index + 1].comparator
                        {
                            total += 1
                        }
                    }
                }
            }
        }

        return total
    }

    /**
     Updates the **User's** push notification tokens.

     - Parameter token: The token string to add to the **User's** push notification token array.
     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func updatePushTokens(_ token: String, completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        var newPushTokens = pushTokens ?? []
        newPushTokens.append(token)

        GenericSerializer().setValue(onKey: "/allUsers/\(associatedIdentifier!)/pushTokens", withData: newPushTokens.unique()) { returnedError in
            if let error = returnedError
            {
                completion(errorInfo(error))
            }
            else { completion(nil) }
        }
    }
}

extension Array where Element == (challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])
{
    func challenges() -> [Challenge]
    {
        var challenges = [Challenge]()

        for challengeTuple in self
        {
            challenges.append(challengeTuple.challenge)
        }

        return challenges
    }
}
