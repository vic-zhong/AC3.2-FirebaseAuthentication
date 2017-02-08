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
    func voted(for photo: Photo) {
        
    }
}
