//
//  User.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 05/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class User
{
    //==================================================//
    
    /* Class-Level Variable Declarations */
    
    //Arrays
    var associatedTeams: [String]! //String = team ID
    var pushTokens:      [String]?
    
    //Strings
    var associatedIdentifier: String!
    var emailAddress:         String!
    var firstName:            String!
    var lastName:             String!
    var profileImageData:     String?
    
    private var DSAssociatedTeams: [Team]?
    
    //==================================================//
    
    /* Constructor Function */
    
    init(associatedIdentifier: String,
         associatedTeams:      [String],
         emailAddress:         String,
         firstName:            String,
         lastName:             String,
         profileImageData:     String?,
         pushTokens:           [String]?)
    {
        self.associatedIdentifier = associatedIdentifier
        self.associatedTeams = associatedTeams
        self.emailAddress = emailAddress
        self.firstName = firstName
        self.lastName = lastName
        self.profileImageData = profileImageData
        self.pushTokens = pushTokens
    }
    
    //==================================================//
    
    /* Public Functions */
    
    /**
     Gets and deserialises all of the **Teams** the **User** is a member of using the *associatedTeams* array.
     
     - Parameter completion: Returns an array of deserialised **Team** objects if successful. If unsuccessful, a string describing the error(s) encountered. *Mutually exclusive.*
     */
    func deSerialiseAssociatedTeams(completion: @escaping(_ returnedTeams: [Team]?, _ errorDescriptor: String?) -> Void)
    {
        if let DSAssociatedTeams = DSAssociatedTeams
        {
            completion(DSAssociatedTeams, nil)
        }
        else
        {
            TeamSerialiser().getTeams(withIdentifiers: associatedTeams) { (returnedTeams, errorDescriptors) in
                if let errors = errorDescriptors
                {
                    completion(nil, errors.joined(separator: "\n"))
                }
                else if let teams = returnedTeams
                {
                    self.DSAssociatedTeams = teams
                    
                    completion(teams, nil)
                }
            }
        }
    }
    
}