import SwiftUI

struct AddFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FamilyMembersViewModel
    
    @State private var name = ""
    @State private var dateOfBirth = Date()
    @State private var relationship = ""
    @State private var birthPlace = ""
    @State private var showingError = false
    
    let relationshipTypes = [
        "Parent", "Child", "Sibling", "Spouse",
        "Grandparent", "Grandchild", "Uncle/Aunt",
        "Niece/Nephew", "Cousin", "In-law"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $name)
                    
                    Picker("Relationship", selection: $relationship) {
                        Text("Select Relationship").tag("")
                        ForEach(relationshipTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    DatePicker("Date of Birth", 
                             selection: $dateOfBirth,
                             displayedComponents: .date)
                    
                    TextField("Birth Place", text: $birthPlace)
                }
            }
            .navigationTitle("Add Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addMember()
                    }
                    .disabled(name.isEmpty || relationship.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error occurred")
            }
        }
    }
    
    private func addMember() {
        Task {
            await viewModel.addFamilyMember(
                name: name,
                dateOfBirth: dateOfBirth,
                relationship: relationship,
                birthPlace: birthPlace
            )
            
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                showingError = true
            }
        }
    }
} 