//
//  GenericSerializer.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 17/07/2017.
//  Copyright © 2013-2017 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

/* Third-party Frameworks */
import FirebaseDatabase
import FirebaseStorage

class GenericSerializer
{
    //==================================================//

    /* MARK: Public Functions */

    /**
     Gets values on the server for a given path.

     - Parameter atPath: The server path at which to retrieve values.
     - Parameter completion: Returns the Firebase snapshot value.
     */
    func getValues(atPath: String, completion: @escaping (Any?) -> Void)
    {
        Database.database().reference().child(atPath).observeSingleEvent(of: .value, with: { returnedSnapshot in
            completion(returnedSnapshot.value)
        })
    }

    func setValue(onKey: String, withData: Any, completion: @escaping (Error?) -> Void)
    {
        Database.database().reference().child(onKey).setValue(withData) { returnedError, _ in
            if let error = returnedError
            {
                completion(error)
            }
            else { completion(nil) }
        }
    }

    /**
     Updates a value on the server for a given key and data bundle.

     - Parameter onKey: The server path at which to update values.
     - Parameter withData: The data bundle to update the server with.

     - Parameter completion: Returns an `Error` if unable to update values.
     */
    func updateValue(onKey: String, withData: [String: Any], completion: @escaping (Error?) -> Void)
    {
        Database.database().reference().child(onKey).updateChildValues(withData, withCompletionBlock: { returnedError, _ in
            if let error = returnedError
            {
                completion(error)
            }
            else { completion(nil) }
        })
    }

    func upload(image: Bool, withData: Data, extension: String, completion: @escaping (_ returnedMetadata: (link: URL, path: String)?, _ errorDescriptor: String?) -> Void)
    {
        if image
        {
            let imagePath = "images/\(Int().random(min: 1000, max: 10000)).\(`extension`)"
            let imageReference = dataStorage.child(imagePath)

            let metadata = StorageMetadata()
            metadata.contentType = "image/\(`extension`)"

            let uploadTask = imageReference.putData(withData, metadata: metadata) { _, returnedError in
                if let error = returnedError
                {
                    completion(nil, errorInfo(error))
                }
                else
                {
                    imageReference.downloadURL { returnedURL, returnedError in
                        if let url = returnedURL
                        {
                            completion((url, imagePath), nil)
                        }
                        else if let error = returnedError
                        {
                            completion(nil, errorInfo(error))
                        }
                    }
                }
            }

            uploadTask.resume()
        }
        else
        {
            let videoPath = "videos/\(Int().random(min: 1000, max: 10000)).\(`extension`)"
            let videoReference = dataStorage.child(videoPath)

            let metadata = StorageMetadata()
            metadata.contentType = "video/\(`extension`)"

            let uploadTask = videoReference.putData(withData, metadata: metadata) { _, returnedError in
                if let error = returnedError
                {
                    completion(nil, errorInfo(error))
                }
                else
                {
                    videoReference.downloadURL { returnedURL, returnedError in
                        if let url = returnedURL
                        {
                            completion((url, videoPath), nil)
                        }
                        else if let error = returnedError
                        {
                            completion(nil, errorInfo(error))
                        }
                    }
                }
            }

            uploadTask.resume()
        }
    }
}
