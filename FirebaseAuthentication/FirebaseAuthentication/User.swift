//
//  User.swift
//  FirebaseAuthentication
//
//  Created by Victor Zhong on 2/7/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import UIKit
import Photos
import Firebase
import FirebaseAuth
import FirebaseStorage

struct Photo {
    let filePath: String
    let votes: [Vote]
    let uploadedBy: String
    let date: String
    let time: String
    let category: String
}

struct Vote {
    let userID: String
    let photoID: String
    let vote: VoteCasted
}

struct User {
    let name: String
    let profile: Photo?
    let photos: [String]
    let votes: [Vote]
    
//    func createUserInDatabase(name: String) {
//        let newUser = User(name: name, profile: nil, photos: [], votes: [])
//        
//        let databaseUserReference = FIRDatabase.database().reference().child("users")
//        
//        let newUserRef = databaseUserReference.child("\(FIRAuth.auth()?.currentUser?.uid)")
//        
//        let newUserDetails: [String : AnyObject] = [
//            "name" : newUser.name as AnyObject,
//            "profile" : newUser.profile as AnyObject,
//            "photos" : newUser.photos as AnyObject,
//            "votes" : newUser.votes as AnyObject
//        ]
//        
//        newUserRef.setValue(newUserDetails)
//    }
}

enum VoteCasted {
    case upvote, downvote
}

class Voting {
    func voted(for photoID: FIRDatabaseReference, upvoted: Bool) {
        
        // [START photo_vote_transaction]
        photoID.runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var data = currentData.value as? [String : AnyObject] {
                var votes = data["vote"] as! [String : Int]
                var upvotes = votes["upvotes"]!
                var downvotes = votes["downvotes"]!
                
                if upvoted {
                    upvotes += 1
                }
                else {
                    downvotes += 1
                }
                
                votes["upvotes"] = upvotes
                votes["downvotes"] = downvotes
                
                currentData.value = data
             
                return FIRTransactionResult.success(withValue: currentData)
            }
            return FIRTransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        // [END photo_vote_transaction]
        
        let currentUserString = (FIRAuth.auth()?.currentUser?.uid)!
        let photoIDString = URL(string: photoID.description())!.lastPathComponent
        
        // [START vote_vote_transaction]
           let databaseVoteReference = FIRDatabase.database().reference().child("votes")
        databaseVoteReference.updateChildValues([currentUserString : upvoted])
        // [END vote_vote_transaction]
        
        // [START user_vote_transaction]
        let userVoteReference = FIRDatabase.database().reference().child("users").child(currentUserString).child("votes")
        userVoteReference.updateChildValues([photoIDString : upvoted])
        // [END user_vote_transaction]
    } 
}
