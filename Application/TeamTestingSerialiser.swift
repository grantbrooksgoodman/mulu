//
//  TeamTestingSerialiser.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 12/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class TeamTestingSerialiser
{
    //==================================================//
    
    /* Public Functions */
    
    /**
     Creates a random **Team** on the server.
     
     - Parameter with: The identifier of the **Users** to populate this **Team** with.
     - Parameter completedChallenges: The randomly generated completed **Challenges** to add to this **Team**.
     
     - Parameter completion: Returns with the identifier of the newly created **Team** if successful. If unsuccessful, a string describing the error encountered. *Mutually exclusive.*
     */
    func createRandomTeam(with users: [User], completedChallenges: [(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])], completion: @escaping(_ returnedIdentifier: String?, _ errorDescriptor: String?) -> Void)
    {
        let universityNames = ["Princeton", "Harvard", "Columbia", "MIT", "Yale", "Stanford", "UChicago", "UPenn", "Caltech", "Johns Hopkins", "Northwestern", "Duke", "Dartmouth", "Brown", "Vanderbilt", "Rice", "WashU St. Louis", "Cornell", "Notre Dame", "UCLA", "Emory", "UC Berkeley", "Georgetown", "UMich", "USC", "UVA", "UNC Chapel Hill", "Wake Forest", "NYU", "Tufts", "UCSB"]
        
        TeamSerialiser().createTeam(name: "Team \(universityNames.randomElement()!)", participantIdentifiers: users.identifiers()) { (returnedIdentifier, errorDescriptor) in
            if let error = errorDescriptor
            {
                completion(nil, error)
            }
            else if let identifier = returnedIdentifier
            {
                TeamSerialiser().addCompletedChallenges(completedChallenges, toTeam: identifier, overwrite: true) { (errorDescriptor) in
                    if let error = errorDescriptor
                    {
                        completion(nil, error)
                    }
                    else
                    {
                        completion(identifier, nil)
                    }
                }
            }
        }
    }
    
    /**
     Creates a random **Team** on the server.
     
     - Parameter with: The identifier of the **Users** to populate this **Team** with.
     - Parameter completedChallenges: The randomly generated completed **Challenges** to add to this **Team**.
     
     - Parameter completion: Returns with the identifier of the newly created **Team** if successful. If unsuccessful, a string describing the error encountered. *Mutually exclusive.*
     */
    func createRandomTeams(with users: [[User]], completedChallenges: [[(challenge: Challenge, metadata: [(user: User, dateCompleted: Date)])]], amount: Int, completion: @escaping(_ returnedIdentifiers: [String]?, _ errorDescriptor: String?) -> Void)
    {
        guard users.count == completedChallenges.count else
        { completion(nil, "Unequal ratio of Users to completed Challenges."); return }
        
        let universityNames = ["Princeton", "Harvard", "Columbia", "MIT", "Yale", "Stanford", "UChicago", "UPenn", "Caltech", "Johns Hopkins", "Northwestern", "Duke", "Dartmouth", "Brown", "Vanderbilt", "Rice", "WashU St. Louis", "Cornell", "Notre Dame", "UCLA", "Emory", "UC Berkeley", "Georgetown", "UMich", "USC", "UVA", "UNC Chapel Hill", "Wake Forest", "NYU", "Tufts", "UCSB"]
        
        var returnedIdentifiers: [String] = []
        
        for i in 0..<amount
        {
            guard i < completedChallenges.count else
            { completion(nil, "Not enough completed Challenges!"); return }
            
            TeamSerialiser().createTeam(name: "Team \(universityNames.randomElement()!)", participantIdentifiers: users[i].identifiers()) { (returnedIdentifier, errorDescriptor) in
                if let error = errorDescriptor
                {
                    completion(nil, error)
                }
                else if let identifier = returnedIdentifier
                {
                    TeamSerialiser().addCompletedChallenges(completedChallenges[i], toTeam: identifier, overwrite: true) { (errorDescriptor) in
                        if let error = errorDescriptor
                        {
                            completion(nil, error)
                        }
                        else
                        {
                            returnedIdentifiers.append(identifier)
                            
                            if i == amount - 1
                            {
                                completion(returnedIdentifiers, nil)
                            }
                        }
                    }
                }
            }
        }
    }
}
