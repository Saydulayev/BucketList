//
//  EditView-ViewModel.swift
//  BucketList
//
//  Created by Saydulayev on 08.01.25.
//

import Foundation
import Observation


extension EditView {
    enum LoadingState {
            case loading, loaded, failed
        }
    
    @Observable
    @MainActor
    class EditViewViewModel {
        // Properties
         var name: String
         var description: String
         var selectedLanguage: String
         var loadingState: LoadingState = .loading
         var pages: [Page] = []
        
        var location: Location

        init(location: Location) {
            self.location = location
            self.name = location.name
            self.description = location.description
            self.selectedLanguage = "en" // Default language
        }

        // Fetch nearby places
        func fetchNearbyPlaces() async {
            let urlString = "https://\(selectedLanguage).wikipedia.org/w/api.php?ggscoord=\(location.latitude)%7C\(location.longitude)&action=query&prop=coordinates%7Cpageimages%7Cpageterms&colimit=50&piprop=thumbnail&pithumbsize=500&pilimit=50&wbptterms=description&generator=geosearch&ggsradius=10000&ggslimit=50&format=json"

            guard let url = URL(string: urlString) else {
                print("Bad URL: \(urlString)")
                return
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)

                // Decode data
                let items = try JSONDecoder().decode(Result.self, from: data)

                // Successfully decode, sort pages
                DispatchQueue.main.async {
                    self.pages = items.query.pages.values.sorted()
                    self.loadingState = .loaded
                }
            } catch {
                // Handle error
                print("Failed to fetch data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.loadingState = .failed
                }
            }
        }
    }
}


