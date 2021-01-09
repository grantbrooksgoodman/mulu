//
//  UserSerializer.swift
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

class UserSerializer
{
    //==================================================//

    /* MARK: Creation Functions */

    /**
     Creates an account for a new user, as well as a serialized **User** object on the server.

     - Parameter associatedTeams: An array containing the identifiers of the **Teams** this **User** is a member of.
     - Parameter emailAddress: The **User's** e-mail address.
     - Parameter firstName: The **User's** first name.
     - Parameter lastName: The **User's** last name.
     - Parameter profileImageData: An optional `base64Encoded` string containg the **User's** profile image data.
     - Parameter pushTokens: An optional array of strings containing the UUIDs of the devices the **User** has opted to receive push notifications for.

     - Parameter completion: Upon success, returns with the identifier of the newly created **User.** Upon failure, a string describing the error(s) encountered. May return both if the **User** was successfully created but an error occurred while adding them to **Teams.**

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
                       completion: @escaping (_ returnedUser: User?, _ errorDescriptor: String?) -> Void)
    {
        guard emailAddress.isValidEmail else
        { completion(nil, "The e-mail address was improperly formatted."); return }

        guard password.lowercasedTrimmingWhitespace.count > 5 else
        { completion(nil, "The password was not long enough."); return }

        Auth.auth().createUser(withEmail: emailAddress, password: password) { returnedResult, returnedError in
            if let error = returnedError
            {
                completion(nil, errorInfo(error))
            }
            else if let result = returnedResult
            {
                UserSerializer().createUser(associatedIdentifier: result.user.uid,
                                            associatedTeams:      associatedTeams == nil ? nil : associatedTeams,
                                            emailAddress:         emailAddress,
                                            firstName:            firstName,
                                            lastName:             lastName,
                                            profileImageData:     profileImageData,
                                            pushTokens:           pushTokens) { returnedIdentifier, errorDescriptor in
                    if let identifier = returnedIdentifier
                    {
                        let newUser = User(associatedIdentifier: identifier,
                                           associatedTeams:      associatedTeams == nil ? nil : associatedTeams,
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

     - Parameter completion: Upon success, returns with the identifier of the newly created **User.** Upon failure, a string describing the error(s) encountered. May return both if the **User** was successfully created but an error occurred while adding them to **Teams.**

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
                    completion: @escaping (_ returnedIdentifier: String?, _ errorDescriptor: String?) -> Void)
    {
        var dataBundle: [String: Any] = [:]

        dataBundle["associatedTeams"] = associatedTeams == nil ? ["!"] : associatedTeams
        dataBundle["emailAddress"] = emailAddress
        dataBundle["firstName"] = firstName
        dataBundle["lastName"] = lastName
        dataBundle["profileImageData"] = profileImageData ?? "!"
        dataBundle["pushTokens"] = pushTokens ?? ["!"]

        //Generate a key for the new User.
        if let identifier = associatedIdentifier
        {
            GenericSerializer().updateValue(onKey: "/allUsers/\(identifier)", withData: dataBundle) { returnedError in
                if let error = returnedError
                {
                    completion(nil, errorInfo(error))
                }
                else
                {
                    if let teams = associatedTeams
                    {
                        TeamSerializer().addUser(identifier, toTeams: teams) { errorDescriptor in
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
            GenericSerializer().updateValue(onKey: "/allUsers/\(generatedKey)", withData: dataBundle) { returnedError in
                if let error = returnedError
                {
                    completion(nil, errorInfo(error))
                }
                else
                {
                    if let teams = associatedTeams
                    {
                        TeamSerializer().addUser(generatedKey, toTeams: teams) { errorDescriptor in
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

    //==================================================//

    /* MARK: Getter Functions */

    /**
     Retrieves and deserializes all existing **Users** on the server.

     - Parameter completion: Upon success, returns an array of deserialized **User** objects. Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*

     ~~~
     completion(returnedUsers, errorDescriptor)
     ~~~
     */
    func getAllUsers(completion: @escaping (_ returnedUsers: [User]?, _ errorDescriptor: String?) -> Void)
    {
        Database.database().reference().child("allUsers").observeSingleEvent(of: .value) { returnedSnapshot in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary,
               let userIdentifiers = returnedSnapshotAsDictionary.allKeys as? [String]
            {
                self.getUsers(withIdentifiers: userIdentifiers) { returnedUsers, errorDescriptors in
                    if let users = returnedUsers
                    {
                        completion(users, nil)
                    }
                    else if let errors = errorDescriptors
                    {
                        completion(nil, errors.joined(separator: "\n"))
                    }
                    else { completion(nil, "An unknown error occurred.") }
                }
            }
            else { completion(nil, "Unable to deserialize snapshot.") }
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
    func getRandomUsers(amountToGet: Int?, completion: @escaping (_ returnedIdentifiers: [String]?, _ noticeDescriptor: String?) -> Void)
    {
        Database.database().reference().child("allUsers").observeSingleEvent(of: .value) { returnedSnapshot in
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
                        completion(Array(userIdentifiers.shuffledValue[0 ... amountToGet!]), nil)
                    }
                }
            }
            else { completion(nil, "Unable to deserialize snapshot.") }
        }
    }

    /**
     Gets and deserializes a **User** from a given identifier string.

     - Parameter withIdentifier: The identifier of the requested **User.**
     - Parameter completion: Upon success, returns a deserialized **User** object. Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*

     ~~~
     completion(returnedUser, errorDescriptor)
     ~~~
     */
    func getUser(withIdentifier: String, completion: @escaping (_ returnedUser: User?, _ errorDescriptor: String?) -> Void)
    {
        Database.database().reference().child("allUsers").child(withIdentifier).observeSingleEvent(of: .value, with: { returnedSnapshot in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary, let asDataBundle = returnedSnapshotAsDictionary as? [String: Any]
            {
                var mutableDataBundle = asDataBundle

                mutableDataBundle["associatedIdentifier"] = withIdentifier

                let deSerialisationResult = self.deSerializeUser(from: mutableDataBundle)

                if let deSerializedUser = deSerialisationResult.deSerializedUser
                {
                    completion(deSerializedUser, nil)
                }
                else { completion(nil, deSerialisationResult.errorDescriptor!) }
            }
            else { completion(nil, "No User exists with the identifier \"\(withIdentifier)\".") }
        })
            { returnedError in

                completion(nil, "Unable to retrieve the specified data. (\(returnedError.localizedDescription))")
            }
    }

    /**
     Gets and deserializes multiple **User** objects from a given array of identifier strings.

     - Parameter withIdentifiers: The identifiers to query for.
     - Parameter completion: Upon success, returns an array of deserialized **User** objects. Upon failure, an array of strings describing the error(s) encountered.

     - Note: Completion variables are **NOT** *mutually exclusive.*

     ~~~
     completion(returnedUsers, errorDescriptors)
     ~~~
     */
    func getUsers(withIdentifiers: [String], completion: @escaping (_ returnedUsers: [User]?, _ errorDescriptors: [String]?) -> Void)
    {
        var userArray = [User]()
        var errorDescriptorArray = [String]()

        if !withIdentifiers.isEmpty
        {
            let dispatchGroup = DispatchGroup()

            for individualIdentifier in withIdentifiers
            {
                if verboseFunctionExposure { print("entered group") }
                dispatchGroup.enter()

                getUser(withIdentifier: individualIdentifier) { returnedUser, errorDescriptor in
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
                    completion(userArray.isEmpty ? nil : userArray, errorDescriptorArray.isEmpty ? nil : errorDescriptorArray)
                }
            }
        }
        else { completion(nil, ["No identifiers passed!"]) }
    }

    //==================================================//

    /* MARK: Removal Functions */

    /**
     Deletes a **User** from the server.

     - Parameter user: The **User** to be deleted.
     - Parameter completion: Upon failure, returns with either an array of problematic **Teams**, or a string describing the error(s) encountered.

     - Requires: All **Teams** the **User** is on (if applicable) to have more participants than just the specified **User.**

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func deleteUser(_ user: User, completion: @escaping (_ problematicTeams: [String]?, _ errorDescriptor: String?) -> Void)
    {
        removeUserFromAllTeams(user) { problematicTeams, errorDescriptor in
            if let teams = problematicTeams
            {
                completion(teams, nil)
            }
            else if let error = errorDescriptor
            {
                completion(nil, error)
            }
            else
            {
                GenericSerializer().setValue(onKey: "/allUsers/\(user.associatedIdentifier!)", withData: NSNull()) { returnedError in
                    if let error = returnedError
                    {
                        completion(nil, errorInfo(error))
                    }
                    else
                    {
                        GenericSerializer().getValues(atPath: "/deletedUsers") { returnedArray in
                            if var array = returnedArray as? [String]
                            {
                                array = array.filter { $0 != "!" }

                                array.append(user.emailAddress!)

                                GenericSerializer().setValue(onKey: "/deletedUsers", withData: array) { returnedError in
                                    if let error = returnedError
                                    {
                                        completion(nil, errorInfo(error))
                                    }
                                    else { completion(nil, nil) }
                                }
                            }
                            else { completion(nil, "Couldn't update deleted users.") }
                        }
                    }
                }
            }
        }
    }

    /**
     Removes a **Team** with the specified identifier from a **User's** *associatedTeams* array.

     - Parameter withIdentifier: The identifier of the **Team** to be removed from the **User's** *associatedTeams* array.
     - Parameter fromUser: The identifier of the **User** whose *associatedTeams* will be modified.

     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.

     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func removeTeam(withIdentifier: String, fromUser: String, completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        getUser(withIdentifier: fromUser) { returnedUser, errorDescriptor in
            if let user = returnedUser
            {
                if var associatedTeams = user.associatedTeams
                {
                    associatedTeams = associatedTeams.filter { $0 != withIdentifier }

                    let newAssociatedTeams = associatedTeams.count == 0 ? ["!"] : associatedTeams

                    GenericSerializer().setValue(onKey: "/allUsers/\(fromUser)/associatedTeams", withData: newAssociatedTeams) { returnedError in
                        if let error = returnedError
                        {
                            completion(errorInfo(error))
                        }
                        else { completion(nil) }
                    }
                }
                else { completion(nil) }
            }
            else { completion(errorDescriptor!) }
        }
    }

    //==================================================//

    /* MARK: Private Functions */

    /**
     Deserializes a **User** from a given data bundle.

     - Parameter from: The data bundle from which to deserialize the **User.**

     - Note: Returned variables are *mutually exclusive.*
     - Returns: Upon success, a deserialized **User** object. Upon failure, a string describing the error(s) encountered.
     */
    private func deSerializeUser(from dataBundle: [String: Any]) -> (deSerializedUser: User?, errorDescriptor: String?)
    {
        guard let associatedIdentifier = dataBundle["associatedIdentifier"] as? String else
        { return (nil, "Unable to deserialize «associatedIdentifier».") }

        guard let associatedTeams = dataBundle["associatedTeams"] as? [String] else
        { return (nil, "Unable to deserialize «associatedTeams».") }

        guard let emailAddress = dataBundle["emailAddress"] as? String else
        { return (nil, "Unable to deserialize «emailAddress».") }

        guard let firstName = dataBundle["firstName"] as? String else
        { return (nil, "Unable to deserialize «firstName».") }

        guard let lastName = dataBundle["lastName"] as? String else
        { return (nil, "Unable to deserialize «lastName».") }

        guard let profileImageData = dataBundle["profileImageData"] as? String else
        { return (nil, "Unable to deserialize «profileImageData».") }

        guard let pushTokens = dataBundle["pushTokens"] as? [String] else
        { return (nil, "Unable to deserialize «pushTokens».") }

        let deSerializedUser = User(associatedIdentifier: associatedIdentifier,
                                    associatedTeams:      associatedTeams == ["!"] ? nil : associatedTeams,
                                    emailAddress:         emailAddress,
                                    firstName:            firstName,
                                    lastName:             lastName,
                                    profileImageData:     profileImageData == "!" ? nil : profileImageData,
                                    pushTokens:           pushTokens == ["!"] ? nil : pushTokens)

        return (deSerializedUser, nil)
    }

    /**
     Removes a **User** from all of their associated **Teams.**

     - Parameter user: The **User** who will be removed from all **Teams.**
     - Parameter completion: Upon failure, returns with either an array of problematic **Teams**, or a string describing the error(s) encountered.

     - Requires: All **Teams** the **User** is on (if applicable) to have more participants than just the specified **User.**

     ~~~
     completion(problematicTeams, errorDescriptor)
     ~~~
     */
    private func removeUserFromAllTeams(_ user: User, completion: @escaping (_ problematicTeams: [String]?, _ errorDescriptor: String?) -> Void)
    {
        verifyGoodToDelete(forUser: user) { problematicTeams, errorDescriptor in
            if let teams = problematicTeams
            {
                completion(teams, nil)
            }
            else if let error = errorDescriptor
            {
                completion(nil, error)
            }
            else
            {
                if let teams = user.associatedTeams
                {
                    var errors = [String]()

                    for (index, teamIdentifier) in Array(teams).enumerated()
                    {
                        TeamSerializer().removeUser(user.associatedIdentifier, fromTeam: teamIdentifier, deleting: false) { errorDescriptor in
                            if let error = errorDescriptor
                            {
                                errors.append(error)

                                if index == teams.count - 1
                                {
                                    completion(nil, errors.joined(separator: "\n"))
                                }
                            }
                            else
                            {
                                if index == teams.count - 1
                                {
                                    completion(nil, errors.isEmpty ? nil : errors.joined(separator: "\n"))
                                }
                            }
                        }
                    }
                }
                else { completion(nil, nil) }
            }
        }
    }

    /**
     Iterates through all the **User's** associated **Teams** to verify that they all have more participants than just the specified **User.**

     - Parameter forUser: The **User** whose associated **Teams** will be iterated through.
     - Parameter completion: Upon success, optionally returns with an array of problematic **Team** identifiers. Upon failure, returns with a string describing the error(s) encountered.

     ~~~
     completion(problematicTeams, errorDescriptor)
     ~~~
     */
    private func verifyGoodToDelete(forUser: User, completion: @escaping (_ problematicTeams: [String]?, _ errorDescriptor: String?) -> Void)
    {
        if forUser.associatedTeams != nil
        {
            forUser.deSerializeAssociatedTeams { returnedTeams, errorDescriptor in
                if let teams = returnedTeams
                {
                    var problematicTeams = [String]()

                    for (index, team) in teams.enumerated()
                    {
                        if team.participantIdentifiers.filter({ $0.key != forUser.associatedIdentifier }).isEmpty
                        {
                            problematicTeams.append(team.associatedIdentifier)
                        }

                        if index == teams.count - 1
                        {
                            completion(problematicTeams.isEmpty ? nil : problematicTeams, nil)
                        }
                    }
                }
                else { completion(nil, errorDescriptor!) }
            }
        }
        else { completion(nil, nil) }
    }
}
