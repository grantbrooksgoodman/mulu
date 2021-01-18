//
//  TournamentSerializer.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 14/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

/* Third-party Frameworks */
import FirebaseDatabase

class TournamentSerializer
{
    //==================================================//

    /* MARK: Adding Functions */

    /**
     Adds an array of **Challenge** identifiers to all **Tournaments** with the provided identifiers.

     - Parameter withIdentifiers: The identifiers of the **Challenges** to be added to these **Tournaments.**
     - Parameter toTournaments: The identifiers of the **Tournaments** to add these **Challenges** to.

     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func addChallenges(_ withIdentifiers: [String], toTournaments: [String], completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        var errors = [String]()

        for (index, tournament) in toTournaments.enumerated()
        {
            addChallenges(withIdentifiers, toTournament: tournament) { errorDescriptor in
                if let error = errorDescriptor
                {
                    errors.append(error)

                    if index == toTournaments.count - 1
                    {
                        completion(errors.unique().joined(separator: "\n"))
                    }
                }
                else
                {
                    if index == toTournaments.count - 1
                    {
                        completion(errors.isEmpty ? nil : errors.unique().joined(separator: "\n"))
                    }
                }
            }
        }
    }

    /**
     Adds an array of **Challenge** identifiers to a **Tournament** with a specified identifier.

     - Parameter withIdentifiers: The identifiers of the **Challenges** to be added to this **Tournament.**
     - Parameter toTournament: The identifier of the **Tournament** to add these **Challenges** to.

     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func addChallenges(_ withIdentifiers: [String], toTournament: String, completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        TournamentSerializer().getTournament(withIdentifier: toTournament) { returnedTournament, errorDescriptor in
            if let tournament = returnedTournament
            {
                var newAssociatedChallenges = withIdentifiers

                if let challenges = tournament.associatedChallenges
                {
                    newAssociatedChallenges.append(contentsOf: challenges.identifiers())
                }

                newAssociatedChallenges = newAssociatedChallenges.unique()

                GenericSerializer().setValue(onKey: "/allTournaments/\(toTournament)/associatedChallenges", withData: newAssociatedChallenges) { returnedError in
                    if let error = returnedError
                    {
                        completion(errorInfo(error))
                    }
                    else { completion(nil) }
                }
            }
            else { completion(errorDescriptor!) }
        }
    }

    //==================================================//

    /* MARK: Creation Functions */

    /**
     Creates a **Tournament** on the server.

     - Parameter name: The name of this **Tournament.**
     - Parameter announcement: An optional string representing the current announcement for the **Tournament.**
     - Parameter startDate: The **Tournament's** start date.
     - Parameter endDate: The **Tournament's** end date.
     - Parameter associatedChallenges: An optional array containing the **Challenges** associated with this **Tournament.**
     - Parameter teamIdentifiers: An array containing the identifiers of the **Teams** participating in this **Tournament.**

     - Parameter completion: Upon success, returns with the identifier of the newly created **Tournament.** Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*

     ~~~
     completion(returnedIdentifier, errorDescriptor)
     ~~~
     */
    func createTournament(name: String,
                          announcement: String?,
                          startDate: Date,
                          endDate: Date,
                          associatedChallenges: [String]?,
                          teamIdentifiers: [String],
                          completion: @escaping (_ returnedIdentifier: String?, _ errorDescriptor: String?) -> Void)
    {
        var dataBundle: [String: Any] = [:]

        dataBundle["name"]                 = name
        dataBundle["announcement"]         = announcement ?? "!"
        dataBundle["startDate"]            = secondaryDateFormatter.string(from: startDate)
        dataBundle["endDate"]              = secondaryDateFormatter.string(from: endDate)
        dataBundle["associatedChallenges"] = associatedChallenges == nil ? ["!"] : associatedChallenges
        dataBundle["teamIdentifiers"]      = teamIdentifiers.unique()

        //Generate a key for the new Challenge.
        if let generatedKey = Database.database().reference().child("/allTournaments/").childByAutoId().key
        {
            GenericSerializer().updateValue(onKey: "/allTournaments/\(generatedKey)", withData: dataBundle) { returnedError in
                if let error = returnedError
                {
                    completion(nil, errorInfo(error))
                }
                else
                {
                    TeamSerializer().addTeams(teamIdentifiers.unique(), toTournament: generatedKey) { errorDescriptor in
                        if let error = errorDescriptor
                        {
                            completion(nil, error)
                        }
                        else { completion(generatedKey, nil) }
                    }
                }
            }
        }
        else { completion(nil, "Unable to create key in database.") }
    }

    //==================================================//

    /* MARK: Getter Functions */

    /**
     Retrieves and deserializes all existing **Tournaments** on the server.

     - Parameter completion: Upon success, returns an array of deserialized **Tournament** objects. Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*

     ~~~
     completion(returnedTournaments, errorDescriptor)
     ~~~
     */
    func getAllTournaments(completion: @escaping (_ returnedTournaments: [Tournament]?, _ errorDescriptor: String?) -> Void)
    {
        Database.database().reference().child("allTournaments").observeSingleEvent(of: .value) { returnedSnapshot in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary,
               let tournamentIdentifiers = returnedSnapshotAsDictionary.allKeys as? [String]
            {
                self.getTournaments(withIdentifiers: tournamentIdentifiers) { returnedTournaments, errorDescriptors in
                    if let tournaments = returnedTournaments
                    {
                        completion(tournaments, nil)
                    }
                    else if let errors = errorDescriptors
                    {
                        completion(nil, errors.unique().joined(separator: "\n"))
                    }
                    else { completion(nil, "An unknown error occurred.") }
                }
            }
            else { completion(nil, "Unable to deserialize snapshot.") }
        }
    }

    /**
     Gets and deserializes multiple **Tournament** objects from a given array of identifier strings.

     - Parameter withIdentifiers: The identifiers to query for.
     - Parameter completion: Upon success, returns an array of deserialized **Tournament** objects. Upon failure, an array of strings describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*

     ~~~
     completion(returnedTournaments, errorDescriptors)
     ~~~
     */
    func getTournaments(withIdentifiers: [String], completion: @escaping (_ returnedTournaments: [Tournament]?, _ errorDescriptors: [String]?) -> Void)
    {
        var tournamentArray = [Tournament]()
        var errorDescriptorArray = [String]()

        if !withIdentifiers.isEmpty
        {
            let dispatchGroup = DispatchGroup()

            for individualIdentifier in withIdentifiers
            {
                if verboseFunctionExposure { print("entered group") }
                dispatchGroup.enter()

                getTournament(withIdentifier: individualIdentifier) { returnedTournament, errorDescriptor in
                    if let tournament = returnedTournament
                    {
                        tournamentArray.append(tournament)

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
                if tournamentArray.count + errorDescriptorArray.count == withIdentifiers.count
                {
                    completion(tournamentArray.isEmpty ? nil : tournamentArray, errorDescriptorArray.isEmpty ? nil : errorDescriptorArray)
                }
            }
        }
        else { completion(nil, ["No identifiers passed!"]) }
    }

    /**
     Gets and deserializes a **Tournament** from a given identifier string.

     - Parameter withIdentifier: The identifier of the requested **Tournament.**
     - Parameter completion: Upon success, returns a deserialized **Tournament** object. Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*

     ~~~
     completion(returnedTournament, errorDescriptor)
     ~~~
     */
    func getTournament(withIdentifier: String, completion: @escaping (_ returnedTournament: Tournament?, _ errorDescriptor: String?) -> Void)
    {
        Database.database().reference().child("allTournaments").child(withIdentifier).observeSingleEvent(of: .value, with: { returnedSnapshot in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary, let asDataBundle = returnedSnapshotAsDictionary as? [String: Any]
            {
                var mutableDataBundle = asDataBundle

                mutableDataBundle["associatedIdentifier"] = withIdentifier

                self.deSerializeTournament(from: mutableDataBundle) { returnedTournament, errorDescriptor in
                    if let tournament = returnedTournament
                    {
                        completion(tournament, nil)
                    }
                    else { completion(nil, errorDescriptor!) }
                }
            }
            else { completion(nil, "No Tournament exists with the identifier \"\(withIdentifier)\".") }
        })
            { returnedError in

                completion(nil, "Unable to retrieve the specified data. (\(returnedError.localizedDescription))")
            }
    }

    //==================================================//

    /* MARK: Removal Functions */

    /**
     Deletes the **Tournament** with the specified identifier from the server.

     - Parameter identifier: The identifier of the **Tournament** to be deleted.
     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func deleteTournament(_ identifier: String, completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        getTournament(withIdentifier: identifier) { returnedTournament, errorDescriptor in
            if let tournament = returnedTournament
            {
                self.removeTeams(tournament.teamIdentifiers, fromTournament: identifier) { errorDescriptor in
                    if let error = errorDescriptor
                    {
                        completion(error)
                    }
                    else
                    {
                        GenericSerializer().setValue(onKey: "/allTournaments/\(identifier)", withData: NSNull()) { returnedError in
                            if let error = returnedError
                            {
                                completion(errorInfo(error))
                            }
                            else { completion(nil) }
                        }
                    }
                }
            }
            else { completion(errorDescriptor!) }
        }
    }

    /**
     Removes a **Team** from a **Tournament.**

     - Parameter withIdentifier: The identifier of the **Team** to remove from the **Tournament.**
     - Parameter fromTournament: The identifier of the **Tournament** to remove the **Team** from.
     - Parameter deleting: A Boolean describing whether the **Tournament** is being deleted or not.

     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.

     - Requires: If the **Tournament** is not being deleted, for the **Tournament** to have more participants than just the specified **Team.**

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func removeTeam(_ withIdentifier: String, fromTournament: String, deleting: Bool, completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        getTournament(withIdentifier: fromTournament) { returnedTournament, errorDescriptor in
            if let tournament = returnedTournament
            {
                var newTeamIdentifiers = tournament.teamIdentifiers.filter { $0 != withIdentifier }
                newTeamIdentifiers = newTeamIdentifiers.count == 0 ? ["!"] : newTeamIdentifiers

                if newTeamIdentifiers == ["!"] && !deleting
                {
                    completion("Removing this Team leaves the Tournament with no participants; delete the Tournament.")
                }
                else
                {
                    GenericSerializer().setValue(onKey: "/allTeams/\(withIdentifier)/associatedTournament", withData: "!") { returnedError in
                        if let error = returnedError
                        {
                            completion(errorInfo(error))
                        }
                        else
                        {
                            GenericSerializer().setValue(onKey: "/allTournaments/\(fromTournament)/teamIdentifiers", withData: newTeamIdentifiers) { returnedError in
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
            else { completion(errorDescriptor!) }
        }
    }

    //==================================================//

    /* MARK: Private Functions */

    /**
     Deserializes a **Tournament** from a given data bundle.

     - Parameter from: The data bundle from which to deserialize the **Tournament.**
     - Parameter completion: Upon success, returns a deserialized **Tournament** object. Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*
     - Requires: A well-formed bundle of **Tournament** metadata.

     ~~~
     completion(deSerializedTournament, errorDescriptor)
     ~~~
     */
    private func deSerializeTournament(from dataBundle: [String: Any], completion: @escaping (_ deSerializedTournament: Tournament?, _ errorDescriptor: String?) -> Void)
    {
        guard let associatedIdentifier = dataBundle["associatedIdentifier"] as? String else
        { completion(nil, "Unable to deserialize «associatedIdentifier»."); return }

        guard let name = dataBundle["name"] as? String else
        { completion(nil, "Unable to deserialize «name»."); return }

        guard let announcement = dataBundle["announcement"] as? String else
        { completion(nil, "Unable to deserialize «announcement»."); return }

        guard let startDateString = dataBundle["startDate"] as? String,
              let startDate = secondaryDateFormatter.date(from: startDateString) else
        { completion(nil, "Unable to deserialize «startDate»."); return }

        guard let endDateString = dataBundle["endDate"] as? String,
              let endDate = secondaryDateFormatter.date(from: endDateString) else
        { completion(nil, "Unable to deserialize «endDate»."); return }

        guard let associatedChallenges = dataBundle["associatedChallenges"] as? [String] else
        { completion(nil, "Unable to deserialize «associatedChallenges»."); return }

        guard let teamIdentifiers = dataBundle["teamIdentifiers"] as? [String] else
        { completion(nil, "Unable to deserialize «teamIdentifiers»."); return }

        if associatedChallenges == ["!"]
        {
            let deSerializedTournament = Tournament(associatedIdentifier: associatedIdentifier,
                                                    name:                 name,
                                                    announcement:         announcement == "!" ? nil : announcement,
                                                    startDate:            startDate,
                                                    endDate:              endDate,
                                                    associatedChallenges: nil,
                                                    teamIdentifiers:      teamIdentifiers)

            completion(deSerializedTournament, nil)
        }
        else
        {
            ChallengeSerializer().getChallenges(withIdentifiers: associatedChallenges) { returnedChallenges, errorDescriptors in
                if let challenges = returnedChallenges
                {
                    let deSerializedTournament = Tournament(associatedIdentifier: associatedIdentifier,
                                                            name:                 name,
                                                            announcement:         announcement == "!" ? nil : announcement,
                                                            startDate:            startDate,
                                                            endDate:              endDate,
                                                            associatedChallenges: challenges,
                                                            teamIdentifiers:      teamIdentifiers)

                    completion(deSerializedTournament, nil)
                }
                else if let errors = errorDescriptors
                {
                    completion(nil, errors.unique().joined(separator: "\n"))
                }
            }
        }
    }

    /**
     Removes an array of **Teams** from a **Tournament.**

     - Parameter teams: An array of **Team** identifiers to be removed from the specified **Tournament.**
     - Parameter fromTournament: The identifier of the **Tournament** from which to remove the specified **Teams.**

     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    private func removeTeams(_ teams: [String], fromTournament: String, completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        var errors = [String]()

        for (index, team) in teams.enumerated()
        {
            removeTeam(team, fromTournament: fromTournament, deleting: true) { errorDescriptor in
                if let error = errorDescriptor
                {
                    errors.append(error)

                    if index == teams.count - 1
                    {
                        completion(errors.unique().joined(separator: "\n"))
                    }
                }
                else
                {
                    if index == teams.count - 1
                    {
                        completion(errors.isEmpty ? nil : errors.unique().joined(separator: "\n"))
                    }
                }
            }
        }
    }
}
