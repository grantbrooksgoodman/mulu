//
//  ChallengeSerializer.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 05/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

/* Third-party Frameworks */
import FirebaseDatabase

class ChallengeSerializer
{
    //==================================================//

    /* MARK: Creation Functions */

    /**
     Creates a **Challenge** on the server.

     - Parameter title: The title of this **Challenge.**
     - Parameter prompt: The **Challenge's** prompt.
     - Parameter pointValue: An integer representing the point value for this **Challenge.**
     - Parameter media: An optional tuple providing a URL and a **MediaType** for any media associated with this **Challenge.**

     - Parameter completion: Upon success, returns with the identifier of the newly created **Challenge.** Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*

     ~~~
     completion(returnedIdentifier, errorDescriptor)
     ~~~
     */
    func createChallenge(title: String,
                         prompt: String,
                         datePosted: Date?,
                         pointValue: Int,
                         media: (URL, String?, Challenge.MediaType)?,
                         completion: @escaping (_ returnedIdentifier: String?, _ errorDescriptor: String?) -> Void)
    {
        var dataBundle: [String: Any] = [:]

        dataBundle["title"] = title
        dataBundle["prompt"] = prompt
        dataBundle["datePosted"] = secondaryDateFormatter.string(from: datePosted == nil ? Date() : datePosted!)
        dataBundle["pointValue"] = pointValue

        if let media = media
        {
            if let pathString = media.1
            {
                dataBundle["media"] = "\(media.2.uploadString()) – \(pathString) – \(media.0.absoluteString)"
            }
            else
            { dataBundle["media"] = "\(media.2.uploadString()) – \(media.0.absoluteString)" }
        }
        else { dataBundle["media"] = "!" }

        //Generate a key for the new Challenge.
        if let generatedKey = Database.database().reference().child("/allChallenges/").childByAutoId().key
        {
            GenericSerializer().updateValue(onKey: "/allChallenges/\(generatedKey)", withData: dataBundle) { returnedError in
                if let error = returnedError
                {
                    completion(nil, errorInfo(error))
                }
                else { completion(generatedKey, nil) }
            }
        }
        else { completion(nil, "Unable to create key in database.") }
    }

    //==================================================//

    /* MARK: Getter Functions */

    /**
     Retrieves and deserializes all existing **Challenges** on the server.

     - Parameter completion: Upon success, returns an array of deserialized **Challenge** objects. Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*

     ~~~
     completion(returnedChallenges, errorDescriptor)
     ~~~
     */
    func getAllChallenges(completion: @escaping (_ returnedChallenges: [Challenge]?, _ errorDescriptor: String?) -> Void)
    {
        Database.database().reference().child("allChallenges").observeSingleEvent(of: .value) { returnedSnapshot in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary,
               let challengeIdentifiers = returnedSnapshotAsDictionary.allKeys as? [String]
            {
                self.getChallenges(withIdentifiers: challengeIdentifiers) { returnedChallenges, errorDescriptors in
                    if let challenges = returnedChallenges
                    {
                        completion(challenges, nil)
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
     Gets the identifiers of any **Challenges** posted on a specified date.

     - Parameter forDate: The date to query the requested **Challenges** for.
     - Parameter completion: Upon success, returns an array of **Challenge** identifier strings. Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*

     ~~~
     completion(returnedIdentifiers, errorDescriptor)
     ~~~
     */
    func getChallenges(forDate: Date, completion: @escaping (_ returnedIdentifiers: [String]?, _ errorDescriptor: String?) -> Void)
    {
        var identifiers = [String]()

        Database.database().reference().child("allChallenges").observeSingleEvent(of: .value) { returnedSnapshot in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary,
               let asDataBundle = returnedSnapshotAsDictionary as? [String: Any]
            {
                for (index, identifier) in Array(asDataBundle.keys).enumerated()
                {
                    if let data = asDataBundle[identifier] as? [String: Any],
                       let datePostedString = data["datePosted"] as? String,
                       let datePosted = secondaryDateFormatter.date(from: datePostedString)
                    {
                        if datePosted.comparator == forDate.comparator
                        {
                            identifiers.append(identifier)
                        }
                    }

                    if index == asDataBundle.keys.count - 1
                    {
                        completion(identifiers, nil)
                    }
                }
            }
            else { completion(nil, "Unable to deserialize snapshot.") }
        }
    }

    /**
     Gets and deserializes multiple **Challenge** objects from a given array of identifier strings.

     - Parameter withIdentifiers: The identifiers to query for.
     - Parameter completion: Upon success, returns an array of deserialized **Challenge** objects. Upon failure, an array of strings describing the error(s) encountered.

     - Note: Completion variables are **NOT** *mutually exclusive.*

     ~~~
     completion(returnedChallenges, errorDescriptor)
     ~~~
     */
    func getChallenges(withIdentifiers: [String], completion: @escaping (_ returnedChallenges: [Challenge]?, _ errorDescriptors: [String]?) -> Void)
    {
        var challengeArray = [Challenge]()
        var errorDescriptorArray = [String]()

        if !withIdentifiers.isEmpty
        {
            let dispatchGroup = DispatchGroup()

            for individualIdentifier in withIdentifiers
            {
                if verboseFunctionExposure { print("entered group") }
                dispatchGroup.enter()

                getChallenge(withIdentifier: individualIdentifier) { returnedChallenge, errorDescriptor in
                    if let challenge = returnedChallenge
                    {
                        challengeArray.append(challenge)

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
                if challengeArray.count + errorDescriptorArray.count == withIdentifiers.count
                {
                    completion(challengeArray.isEmpty ? nil : challengeArray, errorDescriptorArray.isEmpty ? nil : errorDescriptorArray)
                }
            }
        }
        else { completion(nil, ["No identifiers passed!"]) }
    }

    /**
     Gets and deserializes a **Challenge** from a given identifier string.

     - Parameter withIdentifier: The identifier of the requested **Challenge.**
     - Parameter completion: Upon success, returns a deserialized **Challenge** object. Upon failure, a string describing the error(s) encountered.

     - Note: Completion variables are *mutually exclusive.*

     ~~~
     completion(returnedChallenge, errorDescriptor)
     ~~~
     */
    func getChallenge(withIdentifier: String, completion: @escaping (_ returnedChallenge: Challenge?, _ errorDescriptor: String?) -> Void)
    {
        Database.database().reference().child("allChallenges").child(withIdentifier).observeSingleEvent(of: .value, with: { returnedSnapshot in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary, let asDataBundle = returnedSnapshotAsDictionary as? [String: Any]
            {
                var mutableDataBundle = asDataBundle

                mutableDataBundle["associatedIdentifier"] = withIdentifier

                let deSerialisationResult = self.deSerialiseChallenge(from: mutableDataBundle)

                if let deSerializedChallenge = deSerialisationResult.deSerializedChallenge
                {
                    completion(deSerializedChallenge, nil)
                }
                else { completion(nil, deSerialisationResult.errorDescriptor!) }
            }
            else { completion(nil, "No Challenge exists with the identifier \"\(withIdentifier)\".") }
        })
        { returnedError in

            completion(nil, "Unable to retrieve the specified data. (\(returnedError.localizedDescription))")
        }
    }

    func deleteChallenge(_ identifier: String, completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        removeChallengeFromAllTeams(identifier) { errorDescriptor in
            if let error = errorDescriptor
            {
                completion(error)
            }
            else
            {
                self.getChallenge(withIdentifier: identifier) { returnedChallenge, errorDescriptor in
                    if let challenge = returnedChallenge
                    {
                        challenge.removeMedia { errorDescriptor in
                            if let error = errorDescriptor
                            {
                                completion(error)
                            }
                            else
                            {
                                GenericSerializer().setValue(onKey: "/allChallenges/\(identifier)", withData: NSNull()) { returnedError in
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
        }
    }

    func removeChallengeFromAllTeams(_ identifier: String, completion: @escaping (_ errorDescriptor: String?) -> Void)
    {
        TeamSerializer().getAllTeams { returnedTeams, errorDescriptor in
            if let teams = returnedTeams
            {
                var errors = [String]()

                for (index, team) in teams.enumerated()
                {
                    if let challenges = team.completedChallenges
                    {
                        var newCompletedChallenges = [(Challenge, [(User, Date)])]()

                        for challengeBundle in challenges
                        {
                            if challengeBundle.challenge.associatedIdentifier != identifier
                            {
                                newCompletedChallenges.append(challengeBundle)
                            }
                        }

                        TeamSerializer().addCompletedChallenges(newCompletedChallenges, toTeam: team.associatedIdentifier, overwrite: true) { errorDescriptor in
                            if let error = errorDescriptor
                            {
                                errors.append(error)

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
                    else
                    {
                        if index == teams.count - 1
                        {
                            completion(errors.isEmpty ? nil : errors.joined(separator: "\n"))
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
     Deserializes a **Challenge** from a given data bundle.

     - Parameter from: The data bundle from which to deserialize the **Challenge.**

     - Note: Returned variables are *mutually exclusive.*
     - Returns: Upon success, returns a deserialized **Challenge** object. Upon failure, a string describing the error(s) encountered.
     */
    private func deSerialiseChallenge(from dataBundle: [String: Any]) -> (deSerializedChallenge: Challenge?, errorDescriptor: String?)
    {
        guard let associatedIdentifier = dataBundle["associatedIdentifier"] as? String else
        { return (nil, "Unable to deserialize «associatedIdentifier».") }

        guard let title = dataBundle["title"] as? String else
        { return (nil, "Unable to deserialize «title».") }

        guard let prompt = dataBundle["prompt"] as? String else
        { return (nil, "Unable to deserialize «prompt».") }

        guard let datePostedString = dataBundle["datePosted"] as? String,
              let datePosted = secondaryDateFormatter.date(from: datePostedString) else
        { return (nil, "Unable to deserialize «datePosted».") }

        guard let pointValue = dataBundle["pointValue"] as? Int else
        { return (nil, "Unable to deserialize «pointValue».") }

        guard let mediaString = dataBundle["media"] as? String else
        { return (nil, "Unable to deserialize «media».") }

        var media: (URL, String?, Challenge.MediaType)?

        if mediaString != "!"
        {
            let components = mediaString.components(separatedBy: " – ")

            var mediaTypeString: String!
            var pathString: String?
            var linkString: String!

            if components.count == 2
            {
                mediaTypeString = components[0]
                linkString = components[1]
            }
            else if components.count == 3
            {
                mediaTypeString = components[0]
                pathString = components[1]
                linkString = components[2]
            }
            else { return (nil, "The media string was improperly formatted.") }

            var mediaType: Challenge.MediaType!

            if let url = URL(string: linkString)
            {
                switch mediaTypeString
                {
                case "gif":
                    mediaType = .gif
                case "staticImage":
                    mediaType = .staticImage
                case "linkedVideo":
                    mediaType = .linkedVideo
                case "autoPlayVideo":
                    mediaType = .autoPlayVideo
                default:
                    return (nil, "Couldn't convert media type into «MediaType».")
                }

                media = (url, pathString, mediaType)
            }
            else { return (nil, "Could not convert media link to URL.") }
        }

        let deSerializedChallenge = Challenge(associatedIdentifier: associatedIdentifier,
                                              title:                title,
                                              prompt:               prompt,
                                              datePosted:           datePosted,
                                              pointValue:           pointValue,
                                              media:                media)

        return (deSerializedChallenge, nil)
    }
}
