import Foundation
import Combine
import FirebaseDatabase
import FirebaseStorage
import UIKit

class AccountManager: ObservableObject {
    @Published var currentUser: User? {
        didSet {
            if let user = currentUser {
                UserDefaults.standard.set(user.username, forKey: "currentUser")
            } else {
                UserDefaults.standard.removeObject(forKey: "currentUser")
            }
        }
    }

    private let ref = Database.database().reference()
    private let storage = Storage.storage()
    
    init() {
        if let username = UserDefaults.standard.string(forKey: "currentUser") {
            currentUser = User(username: username)
        }
    }
    
    // MARK: - Authentication
    
    func login(username: String, password: String, completion: @escaping (Bool) -> Void) {
        ref.child("users").child(username).observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any],
               let storedPassword = userData["password"] as? String {
                if storedPassword == password { // For real app, hash + salt passwords!
                    DispatchQueue.main.async {
                        self.currentUser = User(username: username)
                        completion(true)
                    }
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    func register(username: String, password: String, completion: @escaping (Bool) -> Void) {
        ref.child("users").child(username).observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                // User already exists
                completion(false)
            } else {
                let userData = ["password": password] // Hash passwords for production!
                self.ref.child("users").child(username).setValue(userData) { error, _ in
                    if let error = error {
                        print("Error saving user: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        DispatchQueue.main.async {
                            self.currentUser = User(username: username)
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    func logout() {
        currentUser = nil
    }
    
    // MARK: - User Profile Handling
    
    func fetchProfile(completion: @escaping (UserProfile?) -> Void) {
        guard let username = currentUser?.username else {
            completion(nil)
            return
        }
        ref.child("users").child(username).observeSingleEvent(of: .value) { snapshot in
            if let dict = snapshot.value as? [String: Any] {
                let bio = dict["bio"] as? String ?? ""
                let email = dict["email"] as? String ?? ""
                let photoURL = dict["photoURL"] as? String
                completion(UserProfile(bio: bio, email: email, photoURL: photoURL))
            } else {
                completion(nil)
            }
        }
    }

    func saveProfile(bio: String, email: String, photoURL: String?, completion: @escaping (Bool) -> Void) {
        guard let username = currentUser?.username else {
            completion(false)
            return
        }
        var dict: [String: Any] = [
            "bio": bio,
            "email": email
        ]
        if let photoURL = photoURL {
            dict["photoURL"] = photoURL
        }
        ref.child("users").child(username).updateChildValues(dict) { error, _ in
            completion(error == nil)
        }
    }

    func uploadProfileImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let username = currentUser?.username else {
            completion(nil)
            return
        }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }
        let storageRef = storage.reference().child("profile_images/\(username).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            storageRef.downloadURL { url, _ in
                completion(url?.absoluteString)
            }
        }
    }
}

// UserProfile struct to hold profile info
struct UserProfile {
    var bio: String
    var email: String
    var photoURL: String?
}

