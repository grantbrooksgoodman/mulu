//
//  ChallengeSerialiser.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 05/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

/* Third-party Frameworks */
import FirebaseDatabase

class ChallengeSerialiser
{
    //==================================================//
    
    /* Public Functions */
    
    /**
     Creates a **Challenge** on the server.
     
     - Parameter title: The title of this **Challenge.**
     - Parameter prompt: The **Challenge's** prompt.
     
     - Parameter pointValue: An integer representing the point value for this **Challenge.**
     - Parameter media: An optional tuple providing a URL and a **MediaType** for any media associated with this **Challenge.**
     
     - Parameter completion: Returns with the identifier of the newly created **Challenge** if successful. If unsuccessful, a string describing the error encountered. *Mutually exclusive.*
     */
    func createChallenge(title: String,
                         prompt: String,
                         datePosted: Date?,
                         pointValue: Int,
                         media: (URL, Challenge.MediaType)?,
                         completion: @escaping(_ returnedIdentifier: String?, _ errorDescriptor: String?) -> Void)
    {
        var dataBundle: [String:Any] = [:]
        
        dataBundle["title"] = title
        dataBundle["prompt"] = prompt
        dataBundle["datePosted"] = secondaryDateFormatter.string(from: datePosted == nil ? Date() : datePosted!)
        dataBundle["pointValue"] = pointValue
        
        if let media = media
        {
            var type: String!
            
            switch media.1
            {
            case .gif:
                type = "gif"
            case .staticImage:
                type = "staticImage"
            case .video:
                type = "video"
            }
            
            dataBundle["media"] = "\(type!) – \(media.0.absoluteString)"
        }
        else { dataBundle["media"] = "!" }
        
        //Generate a key for the new Challenge.
        if let generatedKey = Database.database().reference().child("/allChallenges/").childByAutoId().key
        {
            GenericSerialiser().updateValue(onKey: "/allChallenges/\(generatedKey)", withData: dataBundle) { (returnedError) in
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
     Gets and deserialises a **Challenge** from a given identifier string.
     
     - Parameter withIdentifier: The identifier of the requested **Challenge.**
     - Parameter completion: Returns a deserialised **Challenge** object if successful. If unsuccessful, a string describing the error encountered. *Mutually exclusive.*
     */
    func getChallenge(withIdentifier: String, completion: @escaping(_ returnedChallenge: Challenge?, _ errorDescriptor: String?) -> Void)
    {
        Database.database().reference().child("allChallenges").child(withIdentifier).observeSingleEvent(of: .value, with: { (returnedSnapshot) in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary, let asDataBundle = returnedSnapshotAsDictionary as? [String:Any]
            {
                var mutableDataBundle = asDataBundle
                
                mutableDataBundle["associatedIdentifier"] = withIdentifier
                
                let deSerialisationResult = self.deSerialiseChallenge(from: mutableDataBundle)
                
                if let deSerialisedChallenge = deSerialisationResult.deSerialisedChallenge
                {
                    completion(deSerialisedChallenge, nil)
                }
                else { completion(nil, deSerialisationResult.errorDescriptor!) }
            }
            else { completion(nil, "No Challenge exists with the identifier \"\(withIdentifier)\".") }
        })
        { (returnedError) in
            
            completion(nil, "Unable to retrieve the specified data. (\(returnedError.localizedDescription))")
        }
    }
    
    func getChallenges(forDate: Date, completion: @escaping(_ returnedIdentifiers: [String]?, _ errorDescriptor: String?) -> Void)
    {
        var identifiers: [String] = []
        
        Database.database().reference().child("allChallenges").observeSingleEvent(of: .value) { (returnedSnapshot) in
            if let returnedSnapshotAsDictionary = returnedSnapshot.value as? NSDictionary,
               let asDataBundle = returnedSnapshotAsDictionary as? [String:Any]
            {
                for (index, identifier) in Array(asDataBundle.keys).enumerated()
                {
                    if let data = asDataBundle[identifier] as? [String:Any],
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
            else
            {
                completion(nil, "Unable to deserialise snapshot.")
            }
        }
    }
    
    /**
     Gets and deserialises multiple **Challenge** objects from a given array of identifier strings.
     
     - Parameter withIdentifiers: The identifiers to query for.
     
     - Parameter completion: Returns an array of deserialised **Challenge** objects if successful. If unsuccessful, an array of strings describing the error(s) encountered. *NOT mutually exclusive.*
     */
    func getChallenges(withIdentifiers: [String], completion: @escaping(_ returnedChallenges: [Challenge]?, _ errorDescriptors: [String]?) -> Void)
    {
        var challengeArray: [Challenge]! = []
        var errorDescriptorArray: [String]! = []
        
        if withIdentifiers.count > 0
        {
            let dispatchGroup = DispatchGroup()
            
            for individualIdentifier in withIdentifiers
            {
                if verboseFunctionExposure { print("entered group") }
                dispatchGroup.enter()
                
                getChallenge(withIdentifier: individualIdentifier) { (returnedChallenge, errorDescriptor) in
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
                    completion(challengeArray.count == 0 ? nil : challengeArray, errorDescriptorArray.count == 0 ? nil : errorDescriptorArray)
                }
            }
        }
        else
        {
            completion(nil, ["No identifiers passed!"])
        }
    }
    
    //==================================================//
    
    /* Private Functions */
    
    /**
     Deserialises a **Challenge** from a given data bundle. Returns a deserialised **Challenge** object if successful. If unsuccessful, a string describing the error encountered. *Mutually exclusive.*
     
     - Parameter from: The data bundle from which to deserialise the **Challenge.**
     */
    private func deSerialiseChallenge(from dataBundle: [String:Any]) -> (deSerialisedChallenge: Challenge?, errorDescriptor: String?)
    {
        guard let associatedIdentifier = dataBundle["associatedIdentifier"] as? String else
        { return (nil, "Unable to deserialise «associatedIdentifier».") }
        
        guard let title = dataBundle["title"] as? String else
        { return (nil, "Unable to deserialise «title».") }
        
        guard let prompt = dataBundle["prompt"] as? String else
        { return (nil, "Unable to deserialise «prompt».") }
        
        guard let datePostedString = dataBundle["datePosted"] as? String,
              let datePosted = secondaryDateFormatter.date(from: datePostedString) else
        { return (nil, "Unable to deserialise «datePosted».") }
        
        guard let pointValue = dataBundle["pointValue"] as? Int else
        { return (nil, "Unable to deserialise «pointValue».") }
        
        guard let mediaString = dataBundle["media"] as? String else
        { return (nil, "Unable to deserialise «media».") }
        
        var media: (URL, Challenge.MediaType)?
        
        if mediaString != "!"
        {
            let components = mediaString.components(separatedBy: " – ")
            
            guard components.count == 2 else
            { return(nil, "The media string was improperly formatted.") }
            
            let mediaTypeString = components[0]
            let linkString = components[1]
            
            var mediaType: Challenge.MediaType!
            
            if let url = URL(string: linkString)
            {
                switch mediaTypeString
                {
                case "gif":
                    mediaType = .gif
                case "staticImage":
                    mediaType = .staticImage
                case "video":
                    mediaType = .video
                default:
                    return(nil, "Couldn't convert media type into «MediaType».")
                }
                
                media = (url, mediaType)
            }
            else { return(nil, "Could not convert media link to URL.") }
        }
        
        let deSerialisedChallenge = Challenge(associatedIdentifier: associatedIdentifier,
                                              title:                title,
                                              prompt:               prompt,
                                              datePosted:           datePosted,
                                              pointValue:           pointValue,
                                              media:                media)
        
        return (deSerialisedChallenge, nil)
    }
}
