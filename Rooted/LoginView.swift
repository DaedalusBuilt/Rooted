import SwiftUI

struct LoginView: View {
    @EnvironmentObject var accountManager: AccountManager
    @State private var username = ""
    @State private var password = ""
    @State private var isLoginMode = true
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Welcome")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Picker("Mode", selection: $isLoginMode) {
                Text("Login").tag(true)
                Text("Register").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled(true)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.7), lineWidth: 1)
                    )
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.7), lineWidth: 1)
                    )
            }
            .padding(.horizontal)
            
            Button(action: {
                if isLoginMode {
                    accountManager.login(username: username, password: password) { success in
                        if success {
                            errorMessage = ""
                        } else {
                            errorMessage = "Invalid credentials."
                        }
                    }
                } else {
                    accountManager.register(username: username, password: password) { success in
                        if success {
                            errorMessage = ""
                        } else {
                            errorMessage = "User already exists or registration failed."
                        }
                    }
                }
            }) {
                Text(isLoginMode ? "Login" : "Register")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(15)
                    .shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.top, 60)
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
}

