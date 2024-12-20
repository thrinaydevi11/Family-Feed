import SwiftUI
import ParseSwift
import UIKit

enum SortOrder {
    case chronological
    case alphabetical
    case category
}

struct FamilyMemberDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FamilyMembersViewModel
    
    // Store the member ID instead of the whole member
    let memberId: String
    
    // Computed property to get the current member from viewModel
    var member: FamilyMember? {
        viewModel.familyMembers.first { $0.objectId == memberId }
    }
    
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedRelationship = ""
    @State private var editedDateOfBirth = Date()
    @State private var editedBirthPlace = ""
    @State private var showingDeleteAlert = false
    @State private var showingErrorAlert = false
    @State private var isUploading = false
    @State private var showingAddDateSheet = false
    @State private var newDateTitle = ""
    @State private var newDate = Date()
    @State private var selectedDateFilter: DateCategory?
    @State private var datesSortOrder: SortOrder = .chronological
    @State private var selectedCategory: DateCategory = .other
    @State private var reminderEnabled = false
    @State private var hapticFeedback = UINotificationFeedbackGenerator()
    @State private var showingImageSourcePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    
    init(member: FamilyMember, viewModel: FamilyMembersViewModel) {
        self.viewModel = viewModel
        self.memberId = member.objectId ?? ""
        _editedName = State(initialValue: member.name)
        _editedRelationship = State(initialValue: member.relationship)
        _editedDateOfBirth = State(initialValue: member.dateOfBirth)
        _editedBirthPlace = State(initialValue: member.birthPlace)
    }
    
    var body: some View {
        Group {
            if let currentMember = member {
                memberDetailContent(currentMember)
            } else {
                Text("Member not found")
                    .foregroundColor(.secondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            saveChanges()
                        } else {
                            isEditing = true
                        }
                    }
                    
                    Button("Delete", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .actionSheet(isPresented: $showingImageSourcePicker) {
            ActionSheet(
                title: Text("Choose Image Source"),
                buttons: [
                    .default(Text("Camera")) {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            imageSource = .camera
                            showingImagePicker = true
                        }
                    },
                    .default(Text("Photo Library")) {
                        imageSource = .photoLibrary
                        showingImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: imageSource)
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            handleImageSelection(newValue)
        }
        .alert("Delete Family Member", isPresented: $showingDeleteAlert) {
            deleteAlertButtons
        } message: {
            Text("Are you sure you want to delete this family member? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .sheet(isPresented: $showingAddDateSheet) {
            addDateSheet
        }
    }
    
    @ViewBuilder
    private func memberDetailContent(_ currentMember: FamilyMember) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                memberInformationSection(currentMember)
                importantDatesSection
                birthChartSection(currentMember)
            }
            .padding()
        }
        .navigationTitle(currentMember.name)
    }
    
    @ViewBuilder
    private func memberInformationSection(_ member: FamilyMember) -> some View {
        GroupBox("Member Information") {
            if isEditing {
                editableInformation
            } else {
                displayInformation(member)
            }
        }
    }
    
    @ViewBuilder
    private var editableInformation: some View {
        EditableDetailRow(title: "Name", text: $editedName)
        EditableDetailRow(title: "Relationship", text: $editedRelationship)
        DatePicker("Date of Birth", 
                  selection: $editedDateOfBirth,
                  displayedComponents: .date)
        EditableDetailRow(title: "Birth Place", text: $editedBirthPlace, isLocation: true)
    }
    
    @ViewBuilder
    private func displayInformation(_ member: FamilyMember) -> some View {
        DetailRow(title: "Name", value: member.name)
        DetailRow(title: "Relationship", value: member.relationship)
        DetailRow(title: "Date of Birth", 
                 value: member.dateOfBirth.formatted(date: .long, time: .omitted))
        if !member.birthPlace.isEmpty {
            DetailRow(title: "Birth Place", value: member.birthPlace)
        }
    }
    
    @ViewBuilder
    private func birthChartSection(_ member: FamilyMember) -> some View {
        GroupBox("Birth Chart") {
            if isUploading {
                ProgressView("Uploading Birth Chart...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if let birthChartURL = member.birthChart,
                      let url = URL(string: birthChartURL) {
                VStack {
                    birthChartImage(url)
                    
                    if isEditing {
                        Button(action: {
                            showingImageSourcePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                Text("Change Birth Chart")
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .padding(.top, 8)
                    }
                }
            } else {
                addBirthChartButton
            }
        }
    }
    
    @ViewBuilder
    private var addBirthChartButton: some View {
        Button(action: {
            showingImageSourcePicker = true
        }) {
            VStack {
                Image(systemName: "chart.bar")
                    .font(.system(size: 30))
                Text("Add Birth Chart")
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    private var toolbarContent: any ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    } else {
                        isEditing = true
                    }
                }
                
                Button("Delete", role: .destructive) {
                    showingDeleteAlert = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    private func handleImageSelection(_ image: UIImage?) {
        if let image = image {
            Task {
                isUploading = true
                if let currentMember = member {
                    if isEditing {
                        await viewModel.updateBirthChart(for: currentMember, image: image)
                    } else {
                        await viewModel.uploadBirthChart(for: currentMember, image: image)
                    }
                }
                isUploading = false
                selectedImage = nil
                
                if viewModel.errorMessage != nil {
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let currentMember = member else { return }
        
        Task {
            var updatedMember = FamilyMember(copying: currentMember)
            updatedMember.name = editedName
            updatedMember.relationship = editedRelationship
            updatedMember.dateOfBirth = editedDateOfBirth
            updatedMember.birthPlace = editedBirthPlace
            
            await viewModel.updateMember(updatedMember)
            
            if viewModel.errorMessage == nil {
                isEditing = false
            } else {
                showingErrorAlert = true
            }
        }
    }
    
    private func addImportantDate() {
        guard let currentMember = member else { return }
        
        Task {
            hapticFeedback.prepare()
            var updatedMember = FamilyMember(copying: currentMember)
            let newImportantDate = ImportantDate(
                date: newDate,
                description: selectedCategory.rawValue,
                category: selectedCategory,
                reminder: reminderEnabled
            )
            
            var dates = updatedMember.importantDates ?? []
            dates.append(newImportantDate)
            updatedMember.importantDates = dates
            
            await viewModel.updateMember(updatedMember)
            hapticFeedback.notificationOccurred(.success)
            
            // Reset form
            selectedCategory = .other
            newDate = Date()
            reminderEnabled = false
            showingAddDateSheet = false
        }
    }
    
    private func deleteImportantDate(_ dateToDelete: ImportantDate) {
        guard let currentMember = member else { return }
        
        Task {
            hapticFeedback.prepare()
            var updatedMember = FamilyMember(copying: currentMember)
            updatedMember.importantDates?.removeAll { date in
                date.date == dateToDelete.date && date.description == dateToDelete.description
            }
            
            await viewModel.updateMember(updatedMember)
            hapticFeedback.notificationOccurred(.success)
        }
    }
    
    var sortedAndFilteredDates: [ImportantDate]? {
        guard let currentMember = member,
              let dates = currentMember.importantDates else { return nil }
        
        var filteredDates = dates
        
        if let filter = selectedDateFilter {
            filteredDates = filteredDates.filter { $0.category == filter }
        }
        
        switch datesSortOrder {
        case .chronological:
            return filteredDates.sorted { $0.date < $1.date }
        case .alphabetical:
            return filteredDates.sorted { $0.description < $1.description }
        case .category:
            return filteredDates.sorted { $0.category.rawValue < $1.category.rawValue }
        }
    }
    
    @ViewBuilder
    private var addDateSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Date Details")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(DateCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.iconName)
                                .tag(category)
                        }
                    }
                    
                    DatePicker("Date", selection: $newDate, displayedComponents: .date)
                }
                
                Section {
                    Toggle("Enable Reminder", isOn: $reminderEnabled)
                }
            }
            .navigationTitle("Add Important Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddDateSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addImportantDate()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var importantDatesSection: some View {
        GroupBox("Important Dates") {
            VStack(alignment: .leading, spacing: 12) {
                dateFilterHeader
                datesList
                addDateButton
            }
        }
    }
    
    @ViewBuilder
    private var dateFilterHeader: some View {
        HStack {
            Menu {
                Button("All") {
                    withAnimation {
                        selectedDateFilter = nil
                    }
                }
                ForEach(DateCategory.allCases, id: \.self) { category in
                    Button(category.rawValue) {
                        withAnimation {
                            selectedDateFilter = category
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(selectedDateFilter?.rawValue ?? "All Dates")
                }
            }
            
            Spacer()
            
            Menu {
                Button("Chronological") { 
                    withAnimation {
                        datesSortOrder = .chronological 
                    }
                }
                Button("Alphabetical") { 
                    withAnimation {
                        datesSortOrder = .alphabetical 
                    }
                }
                Button("By Category") { 
                    withAnimation {
                        datesSortOrder = .category 
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
            }
        }
        .padding(.bottom, 4)
    }
    
    @ViewBuilder
    private var datesList: some View {
        if let dates = sortedAndFilteredDates, !dates.isEmpty {
            ForEach(dates) { importantDate in
                dateSectionRow(importantDate)
            }
        } else {
            Text("No important dates added")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }
    
    @ViewBuilder
    private func dateSectionRow(_ importantDate: ImportantDate) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Image(systemName: importantDate.iconName)
                    .foregroundColor(.accentColor)
                    .imageScale(.large)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(importantDate.description)
                        .font(.headline)
                    Text(importantDate.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if importantDate.reminder {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.yellow)
                        .imageScale(.medium)
                }
                
                if isEditing {
                    Button(action: {
                        withAnimation {
                            deleteImportantDate(importantDate)
                        }
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                            .imageScale(.large)
                    }
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    hapticFeedback.prepare()
                    withAnimation {
                        deleteImportantDate(importantDate)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
    
    @ViewBuilder
    private var addDateButton: some View {
        Button(action: {
            showingAddDateSheet = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .imageScale(.large)
                Text("Add Important Date")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func birthChartImage(_ url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
            case .failure(_):
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.red)
            @unknown default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var deleteAlertButtons: some View {
        Button("Delete", role: .destructive) {
            Task {
                if let currentMember = member {
                    await viewModel.deleteMember(currentMember)
                    if viewModel.errorMessage == nil {
                        dismiss()
                    } else {
                        showingErrorAlert = true
                    }
                }
            }
        }
        Button("Cancel", role: .cancel) { }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}

struct EditableDetailRow: View {
    let title: String
    @Binding var text: String
    let isLocation: Bool
    @State private var showingLocationSearch = false
    
    init(title: String, text: Binding<String>, isLocation: Bool = false) {
        self.title = title
        self._text = text
        self.isLocation = isLocation
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if isLocation {
                HStack {
                    TextField(title, text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        showingLocationSearch = true
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            } else {
                TextField(title, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingLocationSearch) {
            LocationSearchView(selectedLocation: $text)
        }
    }
}

#Preview {
    NavigationView {
        FamilyMemberDetailView(
            member: FamilyMember(),
            viewModel: FamilyMembersViewModel()
        )
    }
} 