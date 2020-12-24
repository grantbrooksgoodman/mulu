//
//  MediaAnalyser.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 24/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class MediaAnalyser
{
    //==================================================//
    
    /* Enumerated Type Declarations */
    
    enum AnalysisResult
    {
        case gif
        case image
        case video
        
        case other
        case error
    }
    
    //==================================================//
    
    /* Public Functions */
    
    func analyseMedia(linkString: String, completion: @escaping(_ returnedResult: AnalysisResult) -> Void)
    {
        if let link = URL(string: linkString), UIApplication.shared.canOpenURL(link)
        {
            verifyLink(link) { (returnedMetadata, errorDescriptor) in
                if let metadata = returnedMetadata
                {
                    if metadata.mimeType.hasSuffix("gif") && UIImage(data: metadata.data) != nil
                    {
                        completion(.gif)
                    }
                    else if metadata.mimeType.hasPrefix("image") && UIImage(data: metadata.data) != nil
                    {
                        completion(.image)
                    }
                    else
                    {
                        if self.convertToEmbedded(linkString: linkString) != nil
                        {
                            completion(.video)
                        }
                        else { completion(.other) }
                    }
                }
                else
                {
                    report(errorDescriptor!, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                    
                    completion(.error)
                }
            }
        }
        else { completion(.error) }
    }
    
    func convertToEmbedded(linkString: String) -> URL?
    {
        var separator: String?
        
        if linkString.contains("youtu.be")
        {
            separator = ".be/"
            
            guard linkString.components(separatedBy: separator!).count == 2 else
            { return nil }
        }
        else if linkString.contains("youtube")
        {
            separator = "watch?v="
            
            guard linkString.components(separatedBy: separator!).count == 2 else
            { return nil }
        }
        
        guard let unwrappedSeparator = separator else
        { return nil }
        
        let videoCode = linkString.components(separatedBy: unwrappedSeparator)[1]
        let videoLink = "https://www.youtube.com/embed/\(videoCode)"
        
        if let link = URL(string: videoLink)
        {
            return link
        }
        
        return nil
    }
    
    //==================================================//
    
    /* Private Functions */
    
    private func verifyLink(_ link: URL, completion: @escaping(_ returnedMetadata: (mimeType: String, data: Data)?, _ errorDescriptor: String?) -> Void)
    {
        URLSession.shared.dataTask(with: link) { (privateRetrievedData, privateUrlResponse, privateOccurredError) in
            
            if let urlResponse = privateUrlResponse as? HTTPURLResponse,
               urlResponse.statusCode == 200,
               let mimeType = privateUrlResponse?.mimeType,
               let retrievedData = privateRetrievedData
            {
                if let error = privateOccurredError
                {
                    completion(nil, errorInformation(forError: (error as NSError)))
                }
                else { completion((mimeType, retrievedData), nil) }
            }
            else
            {
                completion(nil, "The URL response was malformed.")
            }
            
        }.resume()
    }
}
