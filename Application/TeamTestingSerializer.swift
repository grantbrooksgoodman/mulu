//
//  TeamTestingSerializer.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 12/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class TeamTestingSerializer
{
    //==================================================//

    /* MARK: Public Functions */

    /**
     Creates a random **Team** on the server.

     - Parameter with: The identifier of the **Users** to populate this **Team** with.
     - Parameter completedChallenges: The randomly generated completed **Challenges** to add to this **Team.**

     - Parameter completion: Upon success, returns with the identifier of the newly created **Team.** Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*

     ~~~
     completion(returnedIdentifier, errorDescriptor)
     ~~~
     */
    func createRandomTeam(with users: [User], completedChallenges: [(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])], completion: @escaping (_ returnedIdentifier: String?, _ errorDescriptor: String?) -> Void)
    {
        let universityNames = ["Princeton", "Harvard", "Columbia", "MIT", "Yale", "Stanford", "UChicago", "UPenn", "Caltech", "Johns Hopkins", "Northwestern", "Duke", "Dartmouth", "Brown", "Vanderbilt", "Rice", "WashU St. Louis", "Cornell", "Notre Dame", "UCLA", "Emory", "UC Berkeley", "Georgetown", "UMich", "USC", "UVA", "UNC Chapel Hill", "Wake Forest", "NYU", "Tufts", "UCSB"]

        TeamSerializer().createTeam(name: "Team \(universityNames.randomElement()!)", participantIdentifiers: users.instantiateIdentifierDictionary()) { returnedMetadata, errorDescriptor in
            if let error = errorDescriptor
            {
                completion(nil, error)
            }
            else if let metadata = returnedMetadata
            {
                TeamSerializer().addCompletedChallenges(completedChallenges, toTeam: metadata.identifier, overwrite: true) { errorDescriptor in
                    if let error = errorDescriptor
                    {
                        completion(nil, error)
                    }
                    else { completion(metadata.identifier, nil) }
                }
            }
        }
    }

    /**
     Creates multiple random **Teams** on the server.

     - Parameter with: The identifier of the **Users** to populate these **Teams** with.
     - Parameter completedChallenges: The randomly generated completed **Challenges** to add to these **Teams.**
     - Parameter amount: The amount of **Teams** to create.

     - Parameter completion: Upon success, returns with an array of the identifiers of the newly created **Teams.** Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*
     - Requires: The `users` array length to be equal to the `completedChallenges` array length.

     ~~~
     completion(returnedIdentifiers, errorDescriptor)
     ~~~
     */
    func createRandomTeams(with users: [[User]], completedChallenges: [[(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])]], amount: Int, completion: @escaping (_ returnedIdentifiers: [String]?, _ errorDescriptor: String?) -> Void)
    {
        guard users.count == completedChallenges.count else
        { completion(nil, "Unequal ratio of Users to completed Challenges."); return }

        let universityNames = ["Princeton", "Harvard", "Columbia", "MIT", "Yale", "Stanford", "UChicago", "UPenn", "Caltech", "Johns Hopkins", "Northwestern", "Duke", "Dartmouth", "Brown", "Vanderbilt", "Rice", "WashU St. Louis", "Cornell", "Notre Dame", "UCLA", "Emory", "UC Berkeley", "Georgetown", "UMich", "USC", "UVA", "UNC Chapel Hill", "Wake Forest", "NYU", "Tufts", "UCSB"]

        var returnedIdentifiers = [String]()

        for i in 0 ..< amount
        {
            guard i < completedChallenges.count else
            { completion(nil, "Not enough completed Challenges!"); return }

            TeamSerializer().createTeam(name: "Team \(universityNames.randomElement()!)", participantIdentifiers: users[i].instantiateIdentifierDictionary()) { returnedMetadata, errorDescriptor in
                if let error = errorDescriptor
                {
                    completion(nil, error)
                }
                else if let metadata = returnedMetadata
                {
                    TeamSerializer().addCompletedChallenges(completedChallenges[i], toTeam: metadata.identifier, overwrite: true) { errorDescriptor in
                        if let error = errorDescriptor
                        {
                            completion(nil, error)
                        }
                        else
                        {
                            returnedIdentifiers.append(metadata.identifier)

                            if i == amount - 1
                            {
                                generatedJoinCode = metadata.joinCode

                                completion(returnedIdentifiers, nil)
                            }
                        }
                    }
                }
            }
        }
    }
}
