//
//  AirtableSerializer.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 06/01/2021.
//  Copyright © 2013-2021 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import Combine
import UIKit

/* Third-party Frameworks */
import AirtableKit

class AirtableSerializer
{
    //==================================================//

    /* MARK: Class-level Variable Declarations */

    let base = Airtable(baseID: "", apiKey: "")

    private var getterRetrieved = [AnyCancellable]()

    //==================================================//

    /* MARK: Challenge Functions */

    func retrieveAirtableChallenges(completion: @escaping (_ airtableChallenges: [AirtableChallenge]?, _ errorDescriptors: [String]?) -> Void)
    {
        base.list(tableName: "Challenges").sink { completionEvent in
            switch completionEvent
            {
            case .finished:
                print("Retrieved record.")
            case let .failure(error):
                completion(nil, [errorInfo(error)])
            }
        } receiveValue: { returnedRecords in
            var airtableChallenges   = [AirtableChallenge]()
            var irretrievableRecords = [String]()

            for record in returnedRecords
            {
                let generatedResult = self.generateAirtableChallenge(record.fields, recordID: record.id!)

                if let challenge = generatedResult.challenge
                {
                    airtableChallenges.append(challenge)
                }
                else if let irretrievableField = generatedResult.irretrievableField
                {
                    irretrievableRecords.append("\(record.id!) – \(irretrievableField)")
                }
            }

            let finalAirtableChallenges = airtableChallenges.isEmpty ? nil : airtableChallenges
            let finalIrretrievableRecords = irretrievableRecords.isEmpty ? nil : irretrievableRecords

            completion(finalAirtableChallenges, finalIrretrievableRecords)

        }.store(in: &getterRetrieved)
    }

    func uploadAirtableChallenge(_ airtableChallenge: AirtableChallenge, completion: @escaping (_ returnedIdentifier: String?, _ errorDescriptor: String?) -> Void)
    {
        if let mediaLink = airtableChallenge.mediaLink
        {
            mediaType(for: mediaLink.absoluteString) { mediaType in
                if let type = mediaType
                {
                    let link = type == .linkedVideo ? (MediaAnalyser().convertToEmbedded(linkString: mediaLink.absoluteString) ?? mediaLink) : mediaLink

                    ChallengeSerializer().createChallenge(title:      airtableChallenge.title,
                                                          prompt:     airtableChallenge.prompt,
                                                          datePosted: nil,
                                                          pointValue: airtableChallenge.pointValue,
                                                          media:      (link, nil, type)) { returnedIdentifier, errorDescriptor in
                        if let identifier = returnedIdentifier
                        {
                            updateStatus(for: airtableChallenge) { errorDescriptor in
                                if let error = errorDescriptor
                                {
                                    completion(nil, error)
                                }
                                else
                                { completion(identifier, nil) }
                            }
                        }
                        else { completion(nil, errorDescriptor!) }
                    }
                }
                else { completion(nil, "Invalid media type.") }
            }
        }
        else
        {
            ChallengeSerializer().createChallenge(title:      airtableChallenge.title,
                                                  prompt:     airtableChallenge.prompt,
                                                  datePosted: nil,
                                                  pointValue: airtableChallenge.pointValue,
                                                  media:      nil) { returnedIdentifier, errorDescriptor in
                if let identifier = returnedIdentifier
                {
                    updateStatus(for: airtableChallenge) { errorDescriptor in
                        if let error = errorDescriptor
                        {
                            completion(nil, error)
                        }
                        else
                        { completion(identifier, nil) }
                    }
                }
                else { completion(nil, errorDescriptor!) }
            }
        }
    }

    //==================================================//

    /* MARK: Private Functions */

    private func generateAirtableChallenge(_ fields: [String: Any], recordID: String) -> (challenge: AirtableChallenge?, irretrievableField: String?)
    {
        let tableTitleString      = "Title"
        let tablePromptString     = "Prompt"
        let tablePointValueString = "Point value"
        let tableLinkString       = "Link"
        let tableMediaString      = "Media"
        let tableUpToDateString   = "Up to Date?"

        guard let title = fields[tableTitleString] as? String else
        { return (nil, tableTitleString) }

        guard let prompt = fields[tablePromptString] as? String else
        { return (nil, tablePromptString) }

        guard let pointValueString = fields[tablePointValueString] as? String else
        { return (nil, tablePointValueString) }

        guard let pointValue = Int(pointValueString) else
        { return (nil, tablePointValueString) }

        guard let upToDateString = fields[tableUpToDateString] as? String else
        { return (nil, tableUpToDateString) }

        var upToDate: Bool!

        if upToDateString == "Yes"
        {
            upToDate = true
        }
        else if upToDateString == "No"
        {
            upToDate = false
        }
        else { return (nil, tableUpToDateString) }

        var mediaLink: URL?
        var uploadedMedia: [Any]?

        if let directLink = fields[tableLinkString] as? String,
           let url = URL(string: directLink)
        {
            mediaLink = url
        }
        else if let media           = fields[tableMediaString] as? [Any],
                let mediaDictionary = media[0]                 as? [String: Any],
                let urlString       = mediaDictionary["url"]   as? String,
                let url             = URL(string: urlString)
        {
            mediaLink = url
            uploadedMedia = media
        }
        else { return (nil, "Link/Media") }

        let airtableChallenge = AirtableChallenge(title:         title,
                                                  prompt:        prompt,
                                                  pointValue:    pointValue,
                                                  mediaLink:     mediaLink,
                                                  recordID:      recordID,
                                                  uploadedMedia: uploadedMedia,
                                                  upToDate:      upToDate)

        return (airtableChallenge, nil)
    }

    private func mediaType(for linkString: String, completion: @escaping (_ type: Challenge.MediaType?) -> Void)
    {
        DispatchQueue.main.async {
            MediaAnalyser().analyseMedia(linkString: linkString) { analysisResult in
                switch analysisResult
                {
                case .autoPlayVideo:
                    completion(.autoPlayVideo)
                case .error:
                    completion(nil)
                case .gif:
                    completion(.gif)
                case .image:
                    completion(.staticImage)
                case .linkedVideo:
                    completion(.linkedVideo)
                case .other:
                    completion(nil)
                }
            }
        }
    }
}
