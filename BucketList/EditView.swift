//
//  EditView.swift
//  BucketList
//
//  Created by Saydulayev on 06.01.25.
//

import SwiftUI

struct EditView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (Location) -> Void
    var onDelete: (UUID) -> Void

    @State private var viewModel: EditViewViewModel
    

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Place name", text: $viewModel.name)
                    TextField("Description", text: $viewModel.description)
                }

                Section("Language") {
                    Picker("Language", selection: $viewModel.selectedLanguage) {
                        Text("English").tag("en")
                        Text("Russian").tag("ru")
                        Text("Spanish").tag("es")
                        Text("German").tag("de")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Nearby…") {
                    switch viewModel.loadingState {
                    case .loaded:
                        ForEach(viewModel.pages, id: \.pageid) { page in
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
                        var newLocation = viewModel.location
                        newLocation.name = viewModel.name
                        newLocation.description = viewModel.description

                        onSave(newLocation)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        onDelete(viewModel.location.id)
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
                await viewModel.fetchNearbyPlaces()
            }
            .onChange(of: viewModel.selectedLanguage) {
                Task {
                    await viewModel.fetchNearbyPlaces()
                }
            }
        }
    }

    init(location: Location, onSave: @escaping (Location) -> Void, onDelete: @escaping (UUID) -> Void) {
        self.onSave = onSave
        self.onDelete = onDelete
        _viewModel = State(wrappedValue: EditViewViewModel(location: location))
    }
}




#Preview {
    EditView(location: .example) { _ in } onDelete: { _ in }
}
