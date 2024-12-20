import SwiftUI
import MapKit

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchService = LocationSearchService()
    @Binding var selectedLocation: String
    @State private var searchText = ""
    @State private var directSearchResults: [MKMapItem] = []
    
    var body: some View {
        NavigationView {
            List {
                // Show autocomplete results
                if !searchService.searchResults.isEmpty {
                    Section("Suggestions") {
                        ForEach(searchService.searchResults, id: \.self) { result in
                            Button {
                                selectedLocation = "\(result.title), \(result.subtitle)"
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.title)
                                        .font(.headline)
                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Show direct search results
                if !directSearchResults.isEmpty {
                    Section("Places") {
                        ForEach(directSearchResults, id: \.self) { item in
                            Button {
                                let location = formatLocation(from: item)
                                selectedLocation = location
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name ?? "Unknown Location")
                                        .font(.headline)
                                    if let address = formatAddress(from: item) {
                                        Text(address)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Enter a location")
            .onChange(of: searchText) { oldValue, newValue in
                searchService.searchLocation(newValue)
                performDirectSearch(newValue)
            }
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performDirectSearch(_ query: String) {
        guard !query.isEmpty else {
            directSearchResults = []
            return
        }
        searchService.performDirectSearch(query) { results in
            DispatchQueue.main.async {
                self.directSearchResults = results
            }
        }
    }
    
    private func formatLocation(from item: MKMapItem) -> String {
        var components: [String] = []
        
        // Add name if available
        if let name = item.name {
            components.append(name)
        }
        
        // Add formatted address if available
        if let address = formatAddress(from: item) {
            components.append(address)
        }
        
        return components.isEmpty ? "Unknown Location" : components.joined(separator: ", ")
    }
    
    private func formatAddress(from item: MKMapItem) -> String? {
        let placemark = item.placemark
        var components: [String] = []
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let subLocality = placemark.subLocality {
            components.append(subLocality)
        }
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
} 