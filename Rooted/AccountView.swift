import SwiftUI
import PhotosUI

struct AccountView: View {
    @EnvironmentObject var accountManager: AccountManager

    @State private var profile: UserProfile = UserProfile(bio: "", email: "", photoURL: nil)
    @State private var selectedImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var isSaving = false
    @State private var saveStatus = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Profile Image with tap to select
                Group {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                    } else if let urlString = profile.photoURL,
                              let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty: ProgressView()
                            case .success(let image): image.resizable().scaledToFill()
                            case .failure: Image(systemName: "person.crop.circle.fill").resizable()
                            @unknown default: Image(systemName: "person.crop.circle.fill").resizable()
                            }
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                    }
                }
                .frame(width: 140, height: 140)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.green, lineWidth: 3))
                .shadow(radius: 5)
                .onTapGesture {
                    showPhotoPicker = true
                }

                // Username display
                if let user = accountManager.currentUser {
                    Text(user.username)
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                }

                // Editable fields
                VStack(alignment: .leading, spacing: 15) {
                    Text("Email")
                        .fontWeight(.semibold)
                    TextField("Email", text: $profile.email)
                        .textInputAutocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)

                    Text("Bio")
                        .fontWeight(.semibold)
                    TextEditor(text: $profile.bio)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                if !saveStatus.isEmpty {
                    Text(saveStatus)
                        .foregroundColor(saveStatus == "Saved!" ? .green : .red)
                        .fontWeight(.medium)
                }

                // Save button
                Button(action: saveProfile) {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Save")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .disabled(isSaving)
                .background(isSaving ? Color.gray.opacity(0.5) : Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Account")
        .onAppear(perform: loadProfile)
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(selectedImage: $selectedImage)
        }
    }

    func loadProfile() {
        accountManager.fetchProfile { profile in
            if let profile = profile {
                DispatchQueue.main.async {
                    self.profile = profile
                }
            }
        }
    }

    func saveProfile() {
        isSaving = true
        saveStatus = ""

        if let newImage = selectedImage {
            // Upload photo first, then save profile
            accountManager.uploadProfileImage(newImage) { urlString in
                guard let urlString = urlString else {
                    DispatchQueue.main.async {
                        saveStatus = "Failed to upload photo."
                        isSaving = false
                    }
                    return
                }
                accountManager.saveProfile(bio: profile.bio, email: profile.email, photoURL: urlString) { success in
                    DispatchQueue.main.async {
                        saveStatus = success ? "Saved!" : "Failed to save profile."
                        isSaving = false
                    }
                }
            }
        } else {
            // Just save profile (no photo update)
            accountManager.saveProfile(bio: profile.bio, email: profile.email, photoURL: profile.photoURL) { success in
                DispatchQueue.main.async {
                    saveStatus = success ? "Saved!" : "Failed to save profile."
                    isSaving = false
                }
            }
        }
    }
}

