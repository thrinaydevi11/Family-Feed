//
//  ContentView.swift
//  Family Feed
//
//  Created by Thrinay Devi on 12/10/24.
//

import SwiftUI
import ParseSwift
import UIKit

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var isShowingLaunchScreen = true
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        Group {
            if isShowingLaunchScreen {
                LaunchScreenView()
            } else if authViewModel.currentUser != nil {
                MainView()
                    .environmentObject(authViewModel)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
        .onAppear {
            // Show launch screen for 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    isShowingLaunchScreen = false
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: imageSource)
        }
    }
}

struct MainView: View {
    @StateObject private var viewModel = FamilyMembersViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingAddMember = false
    @State private var showingDeleteAccountAlert = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.familyMembers, id: \.objectId) { member in
                    NavigationLink {
                        FamilyMemberDetailView(member: member, viewModel: viewModel)
                    } label: {
                        Text(member.name)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Family Feed")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: {
                            Task {
                                await authViewModel.signOut()
                            }
                        }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        
                        Button(role: .destructive, action: {
                            showingDeleteAccountAlert = true
                        }) {
                            Label("Delete Account", systemImage: "person.crop.circle.badge.minus")
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMember = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddFamilyMemberView(viewModel: viewModel)
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await authViewModel.deleteAccount()
                    }
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.")
            }
            .alert("Error", isPresented: .init(
                get: { authViewModel.errorMessage != nil },
                set: { if !$0 { authViewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {
                    authViewModel.errorMessage = nil
                }
            } message: {
                Text(authViewModel.errorMessage ?? "An unknown error occurred")
            }
            .onAppear {
                viewModel.fetchFamilyMembers()
            }
        }
    }
}

struct AuthView: View {
    @State private var isShowingLogin = true
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack {
            if isShowingLogin {
                LoginView()
            } else {
                SignUpView()
            }
            
            Button(action: {
                isShowingLogin.toggle()
            }) {
                Text(isShowingLogin ? "Don't have an account? Sign Up" : "Already have an account? Login")
                    .foregroundColor(.blue)
            }
            .padding()
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Login to your account")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if authViewModel.isLoading {
                ProgressView()
            }
            
            Button(action: {
                Task {
                    await authViewModel.login(username: username, password: password)
                }
            }) {
                Text("Login")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .disabled(authViewModel.isLoading)
        }
        .padding()
    }
}

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Full Name", text: $fullName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if authViewModel.isLoading {
                ProgressView()
            }
            
            Button(action: {
                Task {
                    await authViewModel.signUp(
                        username: username,
                        email: email,
                        password: password,
                        fullName: fullName
                    )
                }
            }) {
                Text("Sign Up")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .disabled(authViewModel.isLoading)
        }
        .padding()
    }
}

struct FamilyMemberRow: View {
    let familyMember: FamilyMember
    let viewModel: FamilyMembersViewModel
    
    var body: some View {
        NavigationLink(destination: FamilyMemberDetailView(member: familyMember, viewModel: viewModel)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(familyMember.name)
                    .font(.headline)
                Text(familyMember.relationship)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Born: \(familyMember.dateOfBirth.formatted(date: .long, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                if !familyMember.birthPlace.isEmpty {
                    Text("Place: \(familyMember.birthPlace)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    ContentView()
    
}
