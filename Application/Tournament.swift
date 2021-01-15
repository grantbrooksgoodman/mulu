//
//  Tournament.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 14/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class Tournament
{
    //==================================================//

    /* MARK: Class-level Variable Declarations */

    //Arrays
    private(set) var DSTeams: [Team]?

    var associatedChallenges: [Challenge]?
    var teamIdentifiers:      [String]!

    //Dates
    var startDate: Date!
    var endDate:   Date!

    //Strings
    var announcement:         String?
    var associatedIdentifier: String!
    var name:                 String!

    //==================================================//

    /* MARK: Constructor Function */

    init(associatedIdentifier: String,
         name:                 String,
         announcement:         String?,
         startDate:            Date,
         endDate:              Date,
         associatedChallenges: [Challenge]?,
         teamIdentifiers:      [String])
    {
        self.associatedIdentifier = associatedIdentifier
        self.name                 = name
        self.announcement         = announcement
        self.startDate            = startDate
        self.endDate              = endDate
        self.associatedChallenges = associatedChallenges
        self.teamIdentifiers      = teamIdentifiers
    }

    //==================================================//

    /* MARK: Update Functions */

    /**
     Updates the **Tournament's** announcement.

     - Parameter announcement: The new announcement for this **Tournament.**
     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func updateAnnouncement(_ announcement: String, completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        let newAnnouncement = announcement.lowercasedTrimmingWhitespace == "" ? "!" : announcement

        GenericSerializer().setValue(onKey: "/allTournaments/\(associatedIdentifier!)/announcement", withData: newAnnouncement) { returnedError in
            if let error = returnedError
            {
                completion(errorInfo(error))
            }
            else { completion(nil) }
        }
    }

    /**
     Updates the **Tournament's** *associatedChallenges* array.

     - Parameter challenges: An array with the identifiers of the **Challenges** to associate with this **Tournament.**
     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func updateAssociatedChallenges(_ challenges: [String], completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        let newAssociatedChallenges = challenges.isEmpty ? ["!"] : challenges

        GenericSerializer().setValue(onKey: "/allTournaments/\(associatedIdentifier!)/associatedChallenges", withData: newAssociatedChallenges) { returnedError in
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
    func updateTeamIdentifiers(_ teams: [String], completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        guard !teams.isEmpty else
        { completion("The Team array was empty; Tournaments must be associated with at least one Team."); return }

        let teamsToRemove = teamIdentifiers.filter { !teams.contains($0) }
        let teamsToAdd = teams.filter { !teamIdentifiers.contains($0) }

        if !teamsToRemove.isEmpty
        {
            removeTeams(teamsToRemove) { errorDescriptor in
                if let error = errorDescriptor
                {
                    completion(error)
                }
                else
                {
                    GenericSerializer().setValue(onKey: "/allTournaments/\(self.associatedIdentifier!)/teamIdentifiers", withData: teams) { returnedError in
                        if let error = returnedError
                        {
                            completion(errorInfo(error))
                        }
                        else
                        {
                            if !teamsToAdd.isEmpty
                            {
                                TeamSerializer().addTeams(teams, toTournament: self.associatedIdentifier) { errorDescriptor in
                                    if let error = errorDescriptor
                                    {
                                        completion(error)
                                    }
                                    else { completion(nil) }
                                }
                            }
                            else { completion(nil) }
                        }
                    }
                }
            }
        }
        else if !teamsToAdd.isEmpty
        {
            GenericSerializer().setValue(onKey: "/allTournaments/\(associatedIdentifier!)/teamIdentifiers", withData: teams) { returnedError in
                if let error = returnedError
                {
                    completion(errorInfo(error))
                }
                else
                {
                    TeamSerializer().addTeams(teamsToAdd, toTournament: self.associatedIdentifier) { errorDescriptor in
                        if let error = errorDescriptor
                        {
                            completion(error)
                        }
                        else { completion(nil) }
                    }
                }
            }
        }
        else { completion("No changes made.") }
    }

    /**
     Updates the **Tournament's** start or end date.

     - Parameter startDate: A Boolean specifying whether or not the start date is the one being updated.
     - Parameter to: The new date to push to the server.

     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.

     - Requires: If modifying the **start date,** the provided date not to be greater than the **Tournament's** end date. If modifying the **end date,** the provided date not to be less than the **Tournament's** start date.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func update(startDate: Bool, to: Date, completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        let dateToModify = startDate ? "startDate" : "endDate"

        if startDate
        {
            guard to < endDate else
            { completion("The start date is greater than the end date."); return }
        }
        else
        {
            guard to > self.startDate else
            { completion("The end date is less than the start date."); return }
        }

        GenericSerializer().setValue(onKey: "/allTournaments/\(associatedIdentifier!)/\(dateToModify)", withData: secondaryDateFormatter.string(from: to)) { returnedError in
            if let error = returnedError
            {
                completion(errorInfo(error))
            }
            else { completion(nil) }
        }
    }

    //==================================================//

    /* MARK: Other Functions */

    /**
     Gets and deserializes all of the **Teams** participating in the **Tournament** using the *teamIdentifiers* array.

     - Parameter completion: Upon success, returns an array of deserialized **Team** objects. Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*

     ~~~
     completion(returnedTeams, errorDescriptor)
     ~~~
     */
    func deSerializeTeams(completion: @escaping (_ returnedTeams: [Team]?, _ errorDescriptor: String?) -> Void)
    {
        if let DSTeams = DSTeams
        {
            completion(DSTeams, nil)
        }
        else
        {
            TeamSerializer().getTeams(withIdentifiers: teamIdentifiers) { returnedTeams, errorDescriptors in
                if let errors = errorDescriptors
                {
                    completion(nil, errors.joined(separator: "\n"))
                }
                else if let teams = returnedTeams
                {
                    self.DSTeams = teams

                    completion(teams, nil)
                }
                else { completion(nil, "No returned Teams, but no error either.") }
            }
        }
    }

    /**
     Gets the **Tourmament's** leaderboard.

     - Returns: An array of `(Team, Int)` tuples.
     - Requires: *DSTeams* to have been previously set.
     */
    func leaderboard() -> [(team: Team, points: Int)]?
    {
        guard let DSTeams = DSTeams else
        { report("Teams haven't been deserialized.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return nil }

        var leaderboard = [(Team, Int)]()

        for team in DSTeams
        {
            leaderboard.append((team, team.getTotalPoints()))
        }

        leaderboard = leaderboard.sorted(by: { $0.1 > $1.1 })

        return leaderboard
    }

    /**
     Sets the *DSTeams* value on the **Tournament.**

     - Warning: Dumps errors to console.
     */
    func setDSTeams()
    {
        if DSTeams != nil
        {
            report("«DSTeams» already set.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
        }
        else
        {
            TeamSerializer().getTeams(withIdentifiers: teamIdentifiers) { returnedTeams, errorDescriptors in
                if let errors = errorDescriptors
                {
                    report(errors.joined(separator: "\n"), errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                }
                else if let teams = returnedTeams
                {
                    self.DSTeams = teams

                    if verboseFunctionExposure { report("Successfully set «DSTeams».", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]) }
                }
            }
        }
    }

    //==================================================//

    /* MARK: Private Functions */

    private func removeTeams(_ teams: [String], completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        var errors = [String]()

        for (index, team) in teams.enumerated()
        {
            GenericSerializer().setValue(onKey: "/allTeams/\(team)/associatedTournament", withData: "!") { returnedError in
                if let error = returnedError
                {
                    errors.append(errorInfo(error))

                    if index == teams.count - 1
                    {
                        completion(errors.joined(separator: "\n"))
                    }
                }
                else
                {
                    if index == teams.count - 1
                    {
                        completion(errors.isEmpty ? nil : errors.joined(separator: "\n"))
                    }
                }
            }
        }
    }
}

//==================================================//

/* MARK: Extensions */

extension Array where Element == String
{
    func containsAll(_ in: [String]) -> Bool
    {
        var containsAll = true

        for element in self
        {
            containsAll = `in`.contains(element)
        }

        return containsAll
    }
}
