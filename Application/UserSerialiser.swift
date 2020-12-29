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
import FirebaseAuth
import FirebaseDatabase

class UserSerialiser
{
    //==================================================//
    
    /* Public Functions */
    
    /**
     Creates an account for a new user, as well as a serialised **User** object on the server.
     
     - Parameter associatedTeams: An array containing the identifiers of the **Teams** this **User** is a member of.
     - Parameter emailAddress: The **User's** e-mail address.
     - Parameter firstName: The **User's** first name.
     - Parameter lastName: The **User's** last name.
     - Parameter profileImageData: An optional `base64Encoded` string containg the **User's** profile image data.
     - Parameter pushTokens: An optional array of strings containing the UUIDs of the devices the **User** has opted to receive push notifications for.
     
     - Parameter completion: Upon success, returns with the identifier of the newly created **User.** Upon failure, a string describing the error encountered. May return both if the **User** was successfully created but an error occurred while adding them to **Teams.**
     
     - Note: Completion variables are **NOT** *mutually exclusive.*
     - Requires: The `emailAddress` to be well-formed and the `password` to be 6 or more characters long.
     
     ~~~
     completion(returnedUser, errorDescriptor)
     ~~~
     */
    func createAccount(associatedTeams: [String]?,
                       emailAddress: String,
                       firstName: String,
                       lastName: String,
                       password: String,
                       profileImageData: String?,
                       pushTokens: [String]?,
                       completion: @escaping(_ returnedUser: User?, _ errorDescriptor: String?) -> Void)
    {
        guard emailAddress.isValidEmail else
        { completion(nil, "The e-mail address was improperly formatted."); return }
        
        guard password.lowercasedTrimmingWhitespace.count > 5 else
        { completion(nil, "The password was not long enough."); return }
        
        Auth.auth().createUser(withEmail: emailAddress, password: password) { (returnedResult, returnedError) in
            if let error = returnedError
            {
                completion(nil, errorInfo(error))
            }
            else if let result = returnedResult
            {
                UserSerialiser().createUser(associatedIdentifier: result.user.uid,
                                            associatedTeams:      associatedTeams == nil ? ["!"] : associatedTeams,
                                            emailAddress:         emailAddress,
                                            firstName:            firstName,
                                            lastName:             lastName,
                                            profileImageData:     profileImageData,
                                            pushTokens:           pushTokens) { (returnedIdentifier, errorDescriptor) in
                    if let identifier = returnedIdentifier
                    {
                        let newUser = User(associatedIdentifier: identifier,
                                           associatedTeams:      associatedTeams,
                                           emailAddress:         emailAddress,
                                           firstName:            firstName,
                                           lastName:             lastName,
                                           profileImageData:     profileImageData,
                                           pushTokens:           pushTokens)
                        
                        completion(newUser, errorDescriptor == nil ? nil : errorDescriptor!)
                    }
                    else { completion(nil, errorDescriptor!) }
                }
            }
            else
            {
                completion(nil, "An unknown error occurred.")
            }
        }
    }
    
    /**
     Creates a **User** on the server.
     
     - Parameter associatedIdentifier: The identifier of the **User** to create. Provided after running `createAccount(...)`. If not provided, an identifier will be **auto-generated.**
     - Parameter associatedTeams: An array containing the identifiers of the **Teams** this **User** is a member of.
     - Parameter emailAddress: The **User's** e-mail address.
     - Parameter firstName: The **User's** first name.
     - Parameter lastName: The **User's** last name.
     - Parameter profileImageData: An optional `base64Encoded` string containg the **User's** profile image data.
     - Parameter pushTokens: An optional array of strings containing the UUIDs of the devices the **User** has opted to receive push notifications for.
     
     - Parameter completion: Upon success, returns with the identifier of the newly created **User.** Upon failure, a string describing the error encountered. May return both if the **User** was successfully created but an error occurred while adding them to **Teams.**
     
     - Note: Completion variables are **NOT** *mutually exclusive.*
     
     ~~~
     completion(returnedIdentifier, errorDescriptor)
     ~~~
     */
    func createUser(associatedIdentifier: String?,
                    associatedTeams: [String]?,
                    emailAddress: String,
                    firstName: String,
                    lastName: String,
                    profileImageData: String?,
                    pushTokens: [String]?,
                    completion: @escaping(_ returnedIdentifier: String?, _ errorDescriptor: String?) -> Void)
    {
        var dataBundle: [String:Any] = [:]
        
        dataBundle["associatedTeams"] = associatedTeams == nil ? ["!"] : associatedTeams
        dataBundle["emailAddress"] = emailAddress
        dataBundle["firstName"] = firstName
        dataBundle["lastName"] = lastName
        dataBundle["profileImageData"] = profileImageData ?? "!"
        dataBundle["pushTokens"] = pushTokens ?? ["!"]
        
        //Generate a key for the new User.
        if let identifier = associatedIdentifier
        {
            GenericSerialiser().updateValue(onKey: "/allUsers/\(identifier)", withData: dataBundle) { (returnedError) in
                if let error = returnedError
                {
                    completion(nil, errorInfo(error))
                }
                else
                {
                    if let teams = associatedTeams
                    {
                        TeamSerialiser().addUser(identifier, toTeams: teams) { (errorDescriptor) in
                            if let error = errorDescriptor
                            {
                                completion(identifier, error)
                            }
                            else { completion(identifier, nil) }
                        }
                    }
                    else { completion(identifier, nil) }
                }
            }
        }
        else if let generatedKey = Database.database().reference().child("/allUsers/").childByAutoId().key
        {
            GenericSerialiser().updateValue(onKey: "/allUsers/\(generatedKey)", withData: dataBundle) { (returnedError) in
                if let error = returnedError
                {
                    completion(nil, errorInfo(error))
                }
                else
                {
                    if let teams = associatedTeams
                    {
                        TeamSerialiser().addUser(generatedKey, toTeams: teams) { (errorDescriptor) in
                            if let error = errorDescriptor
                            {
                                completion(generatedKey, error)
                            }
                            else { completion(generatedKey, nil) }
                        }
                    }
                    else { completion(generatedKey, nil) }
                }
            }
        }
        else { completion(nil, "Unable to create key in database.") }
    }
    
    /**
     Gets and deserialises a **User** from a given identifier string.
     
     - Parameter withIdentifier: The identifier of the requested **User.**
     - Parameter completion: Upon success, returns a deserialised **User** object. Upon failure, a string describing the error encountered.
     
     - Note: Completion variables are *mutually exclusive.*
     
     ~~~
     completion(returnedUser, errorDescriptor)
     ~~~
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
    
    /**
     Gets and deserialises multiple **User** objects from a given array of identifier strings.
     
     - Parameter withIdentifiers: The identifiers to query for.
     - Parameter completion: Upon success, returns an array of deserialised **User** objects. Upon failure, an array of strings describing the error(s) encountered.
     
     - Note: Completion variables are **NOT** *mutually exclusive.*
     
     ~~~
     completion(returnedUsers, errorDescriptors)
     ~~~
     */
    func getUsers(withIdentifiers: [String], completion: @escaping(_ returnedUsers: [User]?, _ errorDescriptors: [String]?) -> Void)
    {
        var userArray: [User]! = []
        var errorDescriptorArray: [String]! = []
        
        if withIdentifiers.count > 0
        {
            let dispatchGroup = DispatchGroup()
            
            for individualIdentifier in withIdentifiers
            {
                if verboseFunctionExposure { print("entered group") }
                dispatchGroup.enter()
                
                getUser(withIdentifier: individualIdentifier) { (returnedUser, errorDescriptor) in
                    if let user = returnedUser
                    {
                        userArray.append(user)
                        
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
                if userArray.count + errorDescriptorArray.count == withIdentifiers.count
                {
                    completion(userArray.count == 0 ? nil : userArray, errorDescriptorArray.count == 0 ? nil : errorDescriptorArray)
                }
            }
        }
        else
        {
            completion(nil, ["No identifiers passed!"])
        }
    }
    
    /**
     Gets random **User** identifiers from the server.
     
     - Parameter amountToGet: An optional integer specifying the amount of random **User** identifiers to get. *Defaults to all.*
     - Parameter completion: Upon success, returns an array of **User** identifier strings. May also return a string describing an event or error encountered.
     
     - Note: Completion variables are **NOT** *mutually exclusive.*
     
     ~~~
     completion(returnedIdentifiers, noticeDescriptor)
     ~~~
     */
    func getRandomUsers(amountToGet: Int?, completion: @escaping(_ returnedIdentifiers: [String]?, _ noticeDescriptor: String?) -> Void)
    {
        Database.database().reference().child("allUsers").observeSingleEvent(of: .value) { (returnedSnapshot) in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary,
               let userIdentifiers = returnedSnapshotAsDictionary.allKeys as? [String]
            {
                if amountToGet == nil
                {
                    completion(userIdentifiers.shuffledValue, nil)
                }
                else
                {
                    if amountToGet! > userIdentifiers.count
                    {
                        completion(userIdentifiers.shuffledValue, "Requested amount was larger than database size.")
                    }
                    else if amountToGet! == userIdentifiers.count
                    {
                        completion(userIdentifiers.shuffledValue, nil)
                    }
                    else if amountToGet! < userIdentifiers.count
                    {
                        completion(Array(userIdentifiers.shuffledValue[0...amountToGet!]), nil)
                    }
                }
            }
            else
            {
                completion(nil, "Unable to deserialise snapshot.")
            }
        }
    }
    
    //==================================================//
    
    /* Private Functions */
    
    /**
     Deserialises a **User** from a given data bundle.
     
     - Parameter from: The data bundle from which to deserialise the **User.**
     
     - Note: Returned variables are *mutually exclusive.*
     - Returns: Upon success, a deserialised **User** object. Upon failure, a string describing the error encountered.
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
                                    associatedTeams:      associatedTeams == ["!"] ? nil : associatedTeams,
                                    emailAddress:         emailAddress,
                                    firstName:            firstName,
                                    lastName:             lastName,
                                    profileImageData:     profileImageData == "!" ? nil : profileImageData,
                                    pushTokens:           pushTokens == ["!"] ? nil : pushTokens)
        
        return (deSerialisedUser, nil)
    }
}
