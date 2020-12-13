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
     - Parameter videoLink: An optional URL for the video associated with this **Challenge.**
     
     - Parameter completion: Returns with the identifier of the newly created **Challenge** if successful. If unsuccessful, a string describing the error encountered. *Mutually exclusive.*
     */
    func createChallenge(title: String,
                         prompt: String,
                         datePosted: Date?,
                         pointValue: Int,
                         videoLink: URL?,
                         completion: @escaping(_ returnedIdentifier: String?, _ errorDescriptor: String?) -> Void)
    {
        var dataBundle: [String:Any] = [:]
        
        dataBundle["title"] = title
        dataBundle["prompt"] = prompt
        dataBundle["datePosted"] = secondaryDateFormatter.string(from: datePosted == nil ? Date() : datePosted!)
        dataBundle["pointValue"] = pointValue
        
        if let videoLink = videoLink
        {
            dataBundle["videoLink"] = videoLink.absoluteString
        }
        else { dataBundle["videoLink"] = "!" }
        
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
        
        guard let videoLink = dataBundle["videoLink"] as? String else
        { return (nil, "Unable to deserialise «videoLink».") }
        
        var videoUrl: URL?
        
        if videoLink != "!"
        {
            videoUrl = URL(string: videoLink)
        }
        
        let deSerialisedChallenge = Challenge(associatedIdentifier: associatedIdentifier,
                                              title:                title,
                                              prompt:               prompt,
                                              datePosted:           datePosted,
                                              pointValue:           pointValue,
                                              videoLink:            videoUrl)
        
        return (deSerialisedChallenge, nil)
    }
}
