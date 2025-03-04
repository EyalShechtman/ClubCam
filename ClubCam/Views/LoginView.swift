//
//  LoginView.swift
//  ClubCam
//
//  Created on 3/4/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingSignUp = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("ClubCam")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .padding()
            
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: login) {
                    Text("Log In")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                Button(action: { isShowingSignUp = true }) {
                    Text("Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $isShowingSignUp) {
            SignUpView()
        }
    }
    
    private func login() {
        // For now, simulate login
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please enter both email and password"
            return
        }
        
        // Simulate successful login
        authManager.login(email: email, password: password) { success in
            if !success {
                errorMessage = "Invalid email or password"
            }
        }
    }
}

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: signUp) {
                    Text("Sign Up")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Create Account")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func signUp() {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields"
            return
        }
        
        if password != confirmPassword {
            errorMessage = "Passwords don't match"
            return
        }
        
        // Simulate account creation
        authManager.signUp(email: email, password: password) { success in
            if success {
                dismiss()
            } else {
                errorMessage = "Failed to create account"
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager())
    }
} 