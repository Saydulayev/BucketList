//
//  EditView.swift
//  BucketList
//
//  Created by Saydulayev on 06.01.25.
//

import SwiftUI

struct EditView: View {
    enum LoadingState {
        case loading, loaded, failed
    }

    @Environment(\.dismiss) var dismiss
    var location: Location
    var onSave: (Location) -> Void
    var onDelete: (UUID) -> Void // Новый метод для удаления

    @State private var name: String
    @State private var description: String
    @State private var selectedLanguage = "en"

    @State private var loadingState = LoadingState.loading
    @State private var pages = [Page]()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Place name", text: $name)
                    TextField("Description", text: $description)
                }

                Section("Language") {
                    Picker("Language", selection: $selectedLanguage) {
                        Text("English").tag("en")
                        Text("Russian").tag("ru")
                        Text("Spanish").tag("es")
                        Text("German").tag("de")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Nearby…") {
                    switch loadingState {
                    case .loaded:
                        ForEach(pages, id: \.pageid) { page in
                            VStack(alignment: .leading) {
                                Text(page.title)
                                    .font(.headline)
                                Text(page.description)
                                    .italic()
                            }
                        }
                    case .loading:
                        Text("Loading…")
                    case .failed:
                        Text("Please try again later.")
                    }
                }
            }
            .navigationTitle("Place details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var newLocation = location
                        newLocation.id = UUID()
                        newLocation.name = name
                        newLocation.description = description

                        onSave(newLocation)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        onDelete(location.id) // Удаление текущей метки
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .task {
                await fetchNearbyPlaces()
            }
            .onChange(of: selectedLanguage) {
                Task {
                    await fetchNearbyPlaces()
                }
            }
        }
    }

    init(location: Location, onSave: @escaping (Location) -> Void, onDelete: @escaping (UUID) -> Void) {
        self.location = location
        self.onSave = onSave
        self.onDelete = onDelete

        _name = State(initialValue: location.name)
        _description = State(initialValue: location.description)
    }

    func fetchNearbyPlaces() async {
        let urlString = "https://\(selectedLanguage).wikipedia.org/w/api.php?ggscoord=\(location.latitude)%7C\(location.longitude)&action=query&prop=coordinates%7Cpageimages%7Cpageterms&colimit=50&piprop=thumbnail&pithumbsize=500&pilimit=50&wbptterms=description&generator=geosearch&ggsradius=10000&ggslimit=50&format=json"

        guard let url = URL(string: urlString) else {
            print("Bad URL: \(urlString)")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            // Декодируем данные
            let items = try JSONDecoder().decode(Result.self, from: data)

            // Успешно – преобразуем в массив страниц
            pages = items.query.pages.values.sorted()
            loadingState = .loaded
        } catch {
            // В случае ошибки
            print("Failed to fetch data: \(error.localizedDescription)")
            loadingState = .failed
        }
    }
}



//#Preview {
//    EditView(location: .example) { _ in }
//}
