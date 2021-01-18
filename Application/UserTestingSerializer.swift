//
//  UserTestingSerializer.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 12/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class UserTestingSerializer
{
    //==================================================//

    /* MARK: Public Functions */

    /**
     Creates a specified number of random **Users** on the server.

     - Parameter amountToCreate: The amount of **Users** to create. *Defaults to 1.*
     - Parameter completion: Upon success, returns with an array **User** objects. Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are **NOT** *mutually exclusive.*

     ~~~
     completion(returnedUsers, errorDescriptor)
     ~~~
     */
    func createRandomUsers(amountToCreate: Int?, completion: @escaping (_ returnedUsers: [User]?, _ errorDescriptor: String?) -> Void)
    {
        var amount = amountToCreate ?? 1

        if amount == 0
        {
            amount = 1
        }

        let group = DispatchGroup()

        var users = [User]()
        var errors = [String]()

        for _ in 0 ..< amount
        {
            group.enter()

            createRandomUser { returnedUser, errorDescriptor in
                if let error = errorDescriptor
                {
                    errors.append(error)
                    group.leave()
                }
                else if let user = returnedUser
                {
                    users.append(user)
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(users, !errors.isEmpty ? errors.unique().joined(separator: "\n") : nil)
        }
    }

    //==================================================//

    /* MARK: Private Functions */

    /**
     Creates a random **User** on the server.

     - Parameter completion: Upon success, returns with a **User** object. Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*

     ~~~
     completion(returnedUser, errorDescriptor)
     ~~~
     */
    private func createRandomUser(completion: @escaping (_ returnedUser: User?, _ errorDescriptor: String?) -> Void)
    {
        let firstNames = ["James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda", "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica", "Thomas", "Sarah", "Charles", "Karen"]

        let firstPart = firstNames.randomElement() ?? "John"
        let secondPart = firstNames.randomElement() ?? "James"

        let randomFirstName = "\(firstPart)-\(secondPart)"
        let randomLastName = "\(firstPart.stringCharacters[0 ... firstPart.count / 2].joined().capitalized)\(secondPart.stringCharacters[secondPart.count / 2 ... secondPart.count - 1].joined().lowercased())"

        let randomEmail = "\(randomLastName.stringCharacters[0 ... randomLastName.count / 2].joined().lowercased())-\(Int().random(min: 100, max: 1000))@mulu.app"

        UserSerializer().createUser(associatedIdentifier: nil,
                                    associatedTeams:      nil,
                                    emailAddress:         randomEmail,
                                    firstName:            randomFirstName,
                                    lastName:             randomLastName,
                                    profileImageData:     nil,
                                    pushTokens:           nil) { returnedIdentifier, errorDescriptor in
            if let error = errorDescriptor
            {
                completion(nil, error)
            }
            else if let identifier = returnedIdentifier
            {
                let newUser = User(associatedIdentifier: identifier,
                                   associatedTeams:      nil,
                                   emailAddress:         randomEmail,
                                   firstName:            randomFirstName,
                                   lastName:             randomLastName,
                                   profileImageData:     nil,
                                   pushTokens:           nil)

                completion(newUser, nil)
            }
        }
    }
}
