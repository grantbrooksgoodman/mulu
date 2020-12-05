//
//  GenericSerialiser.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 17/07/2017.
//  Copyright © 2013-2017 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

/* Third-party Frameworks */
import FirebaseDatabase

class GenericSerialiser
{
    //==================================================//
    
    /* Public Functions */
    
    /**
     Gets values on the server for a given path.
     
     - Parameter atPath: The server path at which to retrieve values.
     
     - Parameter completionHandler: Returns the Firebase snapshot value.
     */
    func getValues(atPath: String, completionHandler: @escaping (Any?) -> Void)
    {
        Database.database().reference().child(atPath).observeSingleEvent(of: .value, with: { (returnedSnapshot) in
            completionHandler(returnedSnapshot.value)
        })
    }
    
    func setValue(onKey: String, withData: Any, completionHandler: @escaping (Error?) -> Void)
    {
        Database.database().reference().child(onKey).setValue(withData) { (returnedError, returnedDatabase) in
            if returnedError != nil
            {
                completionHandler(returnedError!)
            }
            else
            {
                completionHandler(nil)
            }
        }
    }
    
    /**
     Updates a value on the server for a given key and data bundle.
     
     - Parameter atPath: The server path at which to retrieve values.
     - Parameter withData: The data bundle to update the server with.
     
     - Parameter completion: Returns an Error if unable to update values.
     */
    func updateValue(onKey: String, withData: [String:Any], completion: @escaping (Error?) -> Void)
    {
        Database.database().reference().child(onKey).updateChildValues(withData, withCompletionBlock: { (returnedError, returnedDatabase) in
            if returnedError != nil
            {
                completion(returnedError!)
            }
            else
            {
                completion(nil)
            }
        })
    }
}
