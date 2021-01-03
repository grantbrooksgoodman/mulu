//
//  Challenge.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 05/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class Challenge
{
    //==================================================//
    
    /* MARK: Class-level Variable Declarations */
    
    //Strings
    var associatedIdentifier: String!
    var prompt:               String!
    var title:                String!
    
    //Other Declarations
    var datePosted: Date!
    var media: (link: URL, path: String?, type: MediaType)?
    var pointValue: Int!
    
    //==================================================//
    
    /* MARK: Enumerated Type Declarations */
    
    enum MediaType
    {
        case autoPlayVideo
        case gif
        case linkedVideo
        case staticImage
    }
    
    //==================================================//
    
    /* MARK: Constructor Function */
    
    init(associatedIdentifier: String,
         title:                String,
         prompt:               String,
         datePosted:           Date,
         pointValue:           Int,
         media:                (URL, String?, MediaType)?)
    {
        self.associatedIdentifier = associatedIdentifier
        self.title = title
        self.prompt = prompt
        self.datePosted = datePosted
        self.pointValue = pointValue
        self.media = media
    }
    
    //==================================================//
    
    /* MARK: Removal Functions */
    
    /**
     Removes the **Challenge's** media.
     
     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.
     
     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func removeMedia(completion: @escaping(_ errorDescriptor: String?) -> Void)
    {
        if let mediaPath = media?.path
        {
            let mediaReference = dataStorage.child(mediaPath)
            
            mediaReference.delete { (returnedError) in
                if let error = returnedError
                {
                    completion(errorInfo(error))
                }
                else
                {
                    GenericSerialiser().setValue(onKey: "/allChallenges/\(self.associatedIdentifier!)/media", withData: "!") { (returnedError) in
                        if let error = returnedError
                        {
                            completion(errorInfo(error))
                        }
                        else { completion(nil) }
                    }
                }
            }
        }
        else
        {
            GenericSerialiser().setValue(onKey: "/allChallenges/\(associatedIdentifier!)/media", withData: "!") { (returnedError) in
                if let error = returnedError
                {
                    completion(errorInfo(error))
                }
                else { completion(nil) }
            }
        }
    }
    
    //==================================================//
    
    /* MARK: Update Functions */
    
    /**
     Updates the **Challenge's** media.
     
     - Parameter media: A tuple representing the new media link and type for this **Challenge.**
     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.
     
     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func updateMedia(_ media: (link: URL, path: String?, type: MediaType), completion: @escaping(_ errorDescriptor: String?) -> Void)
    {
        var serialisedMedia = "\(media.type.uploadString())"
        
        if let mediaPath = media.path
        {
            serialisedMedia = "\(serialisedMedia) – \(mediaPath) – \(media.link.absoluteString)"
        }
        else { serialisedMedia = "\(serialisedMedia) – \(media.link.absoluteString)" }
        
        GenericSerialiser().setValue(onKey: "/allChallenges/\(associatedIdentifier!)/media", withData: serialisedMedia) { (returnedError) in
            if let error = returnedError
            {
                completion(errorInfo(error))
            }
            else { completion(nil) }
        }
    }
    
    /**
     Updates the **Challenge's** point value.
     
     - Parameter pointValue: The new point value for this **Challenge.**
     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.
     
     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func updatePointValue(_ pointValue: Int, completion: @escaping(_ errorDescriptor: String?) -> Void)
    {
        GenericSerialiser().setValue(onKey: "/allChallenges/\(associatedIdentifier!)/pointValue", withData: pointValue) { (returnedError) in
            if let error = returnedError
            {
                completion(errorInfo(error))
            }
            else { completion(nil) }
        }
    }
    
    /**
     Updates the **Challenge's** prompt.
     
     - Parameter prompt: The new prompt for this **Challenge.**
     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.
     
     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func updatePrompt(_ prompt: String, completion: @escaping(_ errorDescriptor: String?) -> Void)
    {
        GenericSerialiser().setValue(onKey: "/allChallenges/\(associatedIdentifier!)/prompt", withData: prompt) { (returnedError) in
            if let error = returnedError
            {
                completion(errorInfo(error))
            }
            else { completion(nil) }
        }
    }
    
    /**
     Updates the **Challenge's** title.
     
     - Parameter prompt: The new title for this **Challenge.**
     - Parameter completion: Upon failure, returns with a string describing the error(s) encountered.
     
     ~~~
     completion(errorDescriptor)
     ~~~
     */
    func updateTitle(_ title: String, completion: @escaping(_ errorDescriptor: String?) -> Void)
    {
        GenericSerialiser().setValue(onKey: "/allChallenges/\(associatedIdentifier!)/title", withData: title) { (returnedError) in
            if let error = returnedError
            {
                completion(errorInfo(error))
            }
            else { completion(nil) }
        }
    }
}

//==================================================//

/* MARK: Extensions */

extension Challenge.MediaType
{
    func userFacingString() -> String
    {
        switch self
        {
        case .autoPlayVideo:
            return "Auto-play video"
        case .gif:
            return "GIF"
        case .linkedVideo:
            return "Linked video"
        case .staticImage:
            return "Static image"
        }
    }
    
    func uploadString() -> String
    {
        switch self
        {
        case .autoPlayVideo:
            return "autoPlayVideo"
        case .gif:
            return "gif"
        case .linkedVideo:
            return "linkedVideo"
        case .staticImage:
            return "staticImage"
        }
    }
}
