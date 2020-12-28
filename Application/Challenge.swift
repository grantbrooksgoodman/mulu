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
    
    /* Class-Level Variable Declarations */
    
    //Strings
    var associatedIdentifier: String!
    var prompt:               String!
    var title:                String!
    
    //Other Declarations
    var datePosted: Date!
    var media: (link: URL, type: MediaType)?
    var pointValue: Int!
    
    //==================================================//
    
    /* Enumerated Type Declarations */
    
    enum MediaType
    {
        case autoPlayVideo
        case gif
        case linkedVideo
        case staticImage
    }
    
    //==================================================//
    
    /* Constructor Function */
    
    init(associatedIdentifier: String,
         title:                String,
         prompt:               String,
         datePosted:           Date,
         pointValue:           Int,
         media:                (URL, MediaType)?)
    {
        self.associatedIdentifier = associatedIdentifier
        self.title = title
        self.prompt = prompt
        self.datePosted = datePosted
        self.pointValue = pointValue
        self.media = media
    }
}
