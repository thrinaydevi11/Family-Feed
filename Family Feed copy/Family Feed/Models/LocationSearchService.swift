import Foundation
import MapKit

class LocationSearchService: NSObject, ObservableObject {
    @Published var searchResults: [MKLocalSearchCompletion] = []
    private let searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest, .query]
        
        // Set worldwide region
        let center = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let span = MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
        searchCompleter.region = MKCoordinateRegion(center: center, span: span)
    }
    
    func searchLocation(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        searchCompleter.queryFragment = query
    }
    
    // Add direct search for more accurate results
    func performDirectSearch(_ query: String, completion: @escaping ([MKMapItem]) -> Void) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        searchRequest.resultTypes = [.address, .pointOfInterest]
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            completion(response.mapItems)
        }
    }
}

extension LocationSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchResults = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search error: \(error.localizedDescription)")
    }
} 