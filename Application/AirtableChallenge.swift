//
//  AirtableChallenge.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 06/01/2021.
//  Copyright © 2013-2021 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class AirtableChallenge
{
    //==================================================//

    /* MARK: Class-level Variable Declarations */

    //Strings
    var recordID: String!
    var title:    String!
    var prompt:   String!

    //Other Declarations
    var mediaLink: URL?
    var pointValue: Int!
    var uploadedMedia: [Any]?
    var upToDate: Bool!

    //==================================================//

    /* MARK: Constructor Function */

    init(title:         String,
         prompt:        String,
         pointValue:    Int,
         mediaLink:     URL?,
         recordID:      String,
         uploadedMedia: [Any]?,
         upToDate:      Bool)
    {
        self.title         = title
        self.prompt        = prompt
        self.pointValue    = pointValue
        self.mediaLink     = mediaLink
        self.recordID      = recordID
        self.uploadedMedia = uploadedMedia
        self.upToDate      = upToDate
    }

    //==================================================//

    /* MARK: Public Functions */

    func updatedAirtableValue() -> [String: Any]
    {
        var preserved = [String: Any]()

        preserved["Title"]       = title
        preserved["Prompt"]      = prompt
        preserved["Point value"] = String(pointValue)
        preserved["Link"]        = uploadedMedia == nil ? mediaLink!.absoluteString : ""
        preserved["Media"]       = uploadedMedia == nil ? "" : uploadedMedia!
        preserved["Up to Date?"] = "Yes"

        return preserved
    }
}
