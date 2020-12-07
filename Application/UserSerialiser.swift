//
//  UserSerialiser.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 06/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

/* Third-party Frameworks */
import FirebaseDatabase

class UserSerialiser
{
    //==================================================//
    
    /* Public Functions */
    
    /**
     Creates a **User** on the server.
     
     - Parameter associatedTeams: An array containing the identifiers of the **Teams** this **User** is a member of.
     - Parameter emailAddress: The **User's** e-mail address.
     
     - Parameter firstName: The **User's** first name.
     - Parameter lastName: The **User's** last name.
     
     - Parameter profileImageData: An optional `base64Encoded` string containg the **User's** profile image data.
     - Parameter pushTokens: An optional array of strings containing the UUIDs of the devices the **User** has opted to receive push notifications for.
     
     - Parameter completion: Returns with the identifier of the newly created **User** if successful. If unsuccessful, a string describing the error encountered. *Mutually exclusive.*
     */
    func createUser(associatedTeams: [String],
                    emailAddress: String,
                    firstName: String,
                    lastName: String,
                    profileImageData: String?,
                    pushTokens: [String]?,
                    completion: @escaping(_ returnedIdentifier: String?, _ errorDescriptor: String?) -> Void)
    {
        var dataBundle: [String:Any] = [:]
        
        dataBundle["associatedTeams"] = associatedTeams
        dataBundle["emailAddress"] = emailAddress
        dataBundle["firstName"] = firstName
        dataBundle["lastName"] = lastName
        dataBundle["profileImageData"] = profileImageData ?? "!"
        dataBundle["pushTokens"] = pushTokens ?? ["!"]
        
        //Generate a key for the new Team.
        if let generatedKey = Database.database().reference().child("/allUsers/").childByAutoId().key
        {
            GenericSerialiser().updateValue(onKey: "/allUsers/\(generatedKey)", withData: dataBundle) { (returnedError) in
                if let error = returnedError
                {
                    completion(nil, errorInformation(forError: (error as NSError)))
                }
                else { completion(generatedKey, nil) }
            }
        }
        else { completion(nil, "Unable to create key in database.") }
    }
    
    /**
     Gets and deserialises a **User** from a given identifier string.
     
     - Parameter withIdentifier: The identifier of the requested **User.**
     - Parameter completion: Returns a deserialised **User** object if successful. If unsuccessful, a string describing the error encountered. *Mutually exclusive.*
     */
    func getUser(withIdentifier: String, completion: @escaping(_ returnedUser: User?, _ errorDescriptor: String?) -> Void)
    {
        Database.database().reference().child("allUsers").child(withIdentifier).observeSingleEvent(of: .value, with: { (returnedSnapshot) in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary, let asDataBundle = returnedSnapshotAsDictionary as? [String:Any]
            {
                var mutableDataBundle = asDataBundle
                
                mutableDataBundle["associatedIdentifier"] = withIdentifier
                
                let deSerialisationResult = self.deSerialiseUser(from: mutableDataBundle)
                
                if let deSerialisedUser = deSerialisationResult.deSerialisedUser
                {
                    completion(deSerialisedUser, nil)
                }
                else { completion(nil, deSerialisationResult.errorDescriptor!) }
            }
            else { completion(nil, "No User exists with the identifier \"\(withIdentifier)\".") }
        })
        { (returnedError) in
            
            completion(nil, "Unable to retrieve the specified data. (\(returnedError.localizedDescription))")
        }
    }
    
    //==================================================//
    
    /* Private Functions */
    
    /**
     Deserialises a **User** from a given data bundle. Returns a deserialised **User** object if successful. If unsuccessful, a string describing the error encountered. *Mutually exclusive.*
     
     - Parameter from: The data bundle from which to deserialise the **User.**
     */
    private func deSerialiseUser(from dataBundle: [String:Any]) -> (deSerialisedUser: User?, errorDescriptor: String?)
    {
        guard let associatedIdentifier = dataBundle["associatedIdentifier"] as? String else
        { return (nil, "Unable to deserialise «associatedIdentifier».") }
        
        guard let associatedTeams = dataBundle["associatedTeams"] as? [String] else
        { return (nil, "Unable to deserialise «associatedTeams».") }
        
        guard let emailAddress = dataBundle["emailAddress"] as? String else
        { return (nil, "Unable to deserialise «emailAddress».") }
        
        guard let firstName = dataBundle["firstName"] as? String else
        { return (nil, "Unable to deserialise «firstName».") }
        
        guard let lastName = dataBundle["lastName"] as? String else
        { return (nil, "Unable to deserialise «lastName».") }
        
        guard let profileImageData = dataBundle["profileImageData"] as? String else
        { return (nil, "Unable to deserialise «profileImageData».") }
        
        guard let pushTokens = dataBundle["pushTokens"] as? [String] else
        { return (nil, "Unable to deserialise «pushTokens».") }
        
        let deSerialisedUser = User(associatedIdentifier: associatedIdentifier,
                                    associatedTeams:      associatedTeams,
                                    emailAddress:         emailAddress,
                                    firstName:            firstName,
                                    lastName:             lastName,
                                    profileImageData:     profileImageData,
                                    pushTokens:           pushTokens)
        
        return (deSerialisedUser, nil)
    }
}
