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
    
    //Dates
    var startDate: Date!
    var endDate:   Date!
    
    //Strings
    var associatedIdentifier: String!
    var name:                 String!
    
    //Other Declarations
    var teamIdentifiers: [String]!
    
    private(set) var DSTeams: [Team]?
    
    //==================================================//
    
    /* MARK: Constructor Function */
    
    init(associatedIdentifier: String, name: String, startDate: Date, endDate: Date, teamIdentifiers: [String])
    {
        self.associatedIdentifier = associatedIdentifier
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.teamIdentifiers = teamIdentifiers
    }
    
    //==================================================//
    
    /* MARK: Public Functions */
    
    /**
     Gets and deserialises all of the **Teams** participating in the **Tournament** using the *teamIdentifiers* array.
     
     - Parameter completion: Upon success, returns an array of deserialised **Team** objects. Upon failure, a string describing the error(s) encountered.
     
     - Note: Completion variables are *mutually exclusive.*
     
     ~~~
     completion(returnedTeams, errorDescriptor)
     ~~~
     */
    func deSerialiseTeams(completion: @escaping(_ returnedTeams: [Team]?, _ errorDescriptor: String?) -> Void)
    {
        if let DSTeams = DSTeams
        {
            completion(DSTeams, nil)
        }
        else
        {
            TeamSerialiser().getTeams(withIdentifiers: teamIdentifiers) { (returnedTeams, errorDescriptors) in
                if let errors = errorDescriptors
                {
                    completion(nil, errors.joined(separator: "\n"))
                }
                else if let teams = returnedTeams
                {
                    self.DSTeams = teams
                    
                    completion(teams, nil)
                }
                else
                {
                    completion(nil, "No returned Teams, but no error either.")
                }
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
        guard let DSTeams = DSTeams else { report("Teams haven't been deserialised.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return nil }
        
        var leaderboard: [(Team, Int)] = []
        
        for team in DSTeams
        {
            leaderboard.append((team, team.getTotalPoints()))
        }
        
        leaderboard = leaderboard.sorted(by: {$0.1 > $1.1})
        
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
            TeamSerialiser().getTeams(withIdentifiers: teamIdentifiers) { (returnedTeams, errorDescriptors) in
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
}
