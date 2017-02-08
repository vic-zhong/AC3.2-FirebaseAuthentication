//
//  PhotoViewController.swift
//  FirebaseAuthentication
//
//  Created by Victor Zhong on 2/6/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import UIKit
import Photos
import Firebase
import FirebaseAuth
import FirebaseStorage

class PhotoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var takePicButton: UIButton!
    //    @IBOutlet weak var urlTextView: UITextField!
    //    @IBOutlet weak var downloadPicButton: UIButton!
    @IBOutlet weak var urlTextView: UITextView!
    
    @IBAction func logoutButtonClicked(_ sender: UIButton) {
        if FIRAuth.auth()?.currentUser != nil {
            do {
                try FIRAuth.auth()?.signOut()
//                performSegue(withIdentifier: "loggedOut", sender: sender)
               _ = self.navigationController?.popViewController(animated: true)
            }
            catch {
                print(error)
            }
        }
    }
    
    // MARK: - Properties
    let databasePhotoReference = FIRDatabase.database().reference().child("photos")
    let databaseUserReference = FIRDatabase.database().reference().child("users")
    //    let databaseCategoryReference = FIRDatabase.database().reference().child("categories")
    //
    var outPutText = ""
    var storageRef: FIRStorageReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // [START configurestorage]
        storageRef = FIRStorage.storage().reference()
        // [END configurestorage]
        
        // [START storageauth]
        // Using Firebase Storage requires the user be authenticated. Here we are using
        // anonymous authentication.
        if FIRAuth.auth()?.currentUser == nil {
            performSegue(withIdentifier: "loggedOut", sender: self)
        }
        
        if FIRAuth.auth()?.currentUser != nil {
            outPutText += "\(FIRAuth.auth()!.currentUser!.displayName): (\(FIRAuth.auth()!.currentUser!.uid)) Logged In\n\n"
            self.urlTextView.text = outPutText
            self.takePicButton.isEnabled = true
        }
        else {
            self.takePicButton.isEnabled = false
        }
    }
    // [END storageauth]
    
    // MARK: - Image Picker
    
    @IBAction func didTapTakePicture(_: AnyObject) {
        let picker = UIImagePickerController()
        picker.delegate = self
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        
        present(picker, animated: true, completion:nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion:nil)
        
        
        
        self.outPutText += "Beginning Upload\n\n"
        urlTextView.text = outPutText
        // if it's a photo from the library, not an image from the camera
        if #available(iOS 8.0, *), let referenceUrl = info[UIImagePickerControllerReferenceURL] as? URL {
            let assets = PHAsset.fetchAssets(withALAssetURLs: [referenceUrl], options: nil)
            let asset = assets.firstObject
            asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
                let imageFile = contentEditingInput?.fullSizeImageURL
                let filePath = FIRAuth.auth()!.currentUser!.uid +
                "/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(imageFile!.lastPathComponent)"
                
                
                // [START uploadimage]
                let uploadTask = self.storageRef.child(filePath)
                    .putFile(imageFile!, metadata: nil) { (metadata, error) in
                        if let error = error {
                            print("Error uploading: \(error)")
                            self.outPutText += "Upload Failed\n\n"
                            self.urlTextView.text = self.outPutText
                            return
                        }
                        self.uploadSuccess(metadata!, storagePath: filePath)
                        self.createPhotoInDatabase(for: "general")
                }
                // [END uploadimage]
                uploadTask.observe(.progress) { snapshot in
                    let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                        / Double(snapshot.progress!.totalUnitCount)
                    print("\(percentComplete)%\n")
                }
            })
        } else {
            guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
            guard let imageData = UIImageJPEGRepresentation(image, 0.8) else { return }
            let imagePath = FIRAuth.auth()!.currentUser!.uid +
            "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            let uploadTask = self.storageRef.child(imagePath)
                .put(imageData, metadata: metadata) { (metadata, error) in
                    if let error = error {
                        print("Error uploading: \(error)")
                        self.outPutText += "Upload Failed\n\n"
                        self.urlTextView.text = self.outPutText
                        return
                    }
                    self.uploadSuccess(metadata!, storagePath: imagePath)
            }
            uploadTask.observe(.progress) { snapshot in
                let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                    / Double(snapshot.progress!.totalUnitCount)
                print("\(percentComplete)%\n")
            }
        }
    }
    
    // MARK: - Functions and methods
    
    func createPhotoInDatabase(for category: String) {
        let date = Date()
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateStringFormatter.string(from: date)
        
        
        let uploadedPhoto = Photo(filePath: FIRAuth.auth()!.currentUser!.uid +
            "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg", votes: [], uploadedBy: FIRAuth.auth()!.currentUser!.uid, date: dateString, category: category)
        
        let photoRef = databasePhotoReference.childByAutoId()
        let photoDetails : [String : AnyObject] = [
            "filePath" : uploadedPhoto.filePath as AnyObject,
            "date" : uploadedPhoto.date as AnyObject,
            "votes" : uploadedPhoto.votes as AnyObject,
            "uploaded" : uploadedPhoto.uploadedBy as AnyObject,
            "category" : uploadedPhoto.category as AnyObject
        ]
        
        photoRef.setValue(photoDetails)
        
        let userPhotoDirectory = databaseUserReference.child(FIRAuth.auth()!.currentUser!.uid).child("photos")
        let directoryAsURL = URL(string: photoRef.description())!
//        userPhotoDirectory.setValue(directoryAsURL.lastPathComponent)
        let userPhotoDetail : [String : AnyObject ] = [
            directoryAsURL.lastPathComponent : uploadedPhoto.date as AnyObject
        ]
        userPhotoDirectory.updateChildValues(userPhotoDetail)
        
        
    }
    
    func uploadSuccess(_ metadata: FIRStorageMetadata, storagePath: String) {
        print("Upload Succeeded!")
        //        self.urlTextView.text = metadata.downloadURL()?.absoluteString
        
        self.outPutText += "\(metadata.downloadURL()?.absoluteString)\n\n"
        self.urlTextView.text = self.outPutText
        UserDefaults.standard.set(storagePath, forKey: "storagePath")
        UserDefaults.standard.synchronize()
        //        self.downloadPicButton.isEnabled = true
        
        print(metadata.bucket)
        print(metadata.downloadURL())
        print(metadata.downloadURLs)
        print(metadata.path)
        print(metadata.timeCreated)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
}

/*
 storageRef = FIRStorage.storage().reference()
 
 let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
 let documentsDirectory = paths[0]
 let filePath = "file:\(documentsDirectory)/myimage.jpg"
 guard let fileURL = URL.init(string: filePath) else { return }
 guard let storagePath = UserDefaults.standard.object(forKey: "storagePath") as? String else {
 return
 }
 
 // [START downloadimage]
 storageRef.child(storagePath).write(toFile: fileURL, completion: { (url, error) in
 if let error = error {
 print("Error downloading:\(error)")
 self.statusTextView.text = "Download Failed"
 return
 } else if let imagePath = url?.path {
 self.statusTextView.text = "Download Succeeded!"
 self.imageView.image = UIImage.init(contentsOfFile: imagePath)
 }
 })
 // [END downloadimage]
 */
