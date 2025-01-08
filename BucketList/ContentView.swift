//
//  ContentView.swift
//  BucketList
//
//  Created by Saydulayev on 26.12.24.
//

import MapKit
import SwiftUI

struct ContentView: View {
    @State private var viewModel = ViewModel()
    
    let startPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 56, longitude: -3),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )
    )
    
    var body: some View {
        if viewModel.isUnlocked {
            ZStack {
                // Карта
                MapReader { proxy in
                    Map(initialPosition: startPosition) {
                        ForEach(viewModel.locations) { location in
                            Annotation("", coordinate: location.coordinate) {
                                VStack {
                                    Text(location.name)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .padding(2)
                                        .background(.white)
                                        .clipShape(Capsule())
                                    
                                    Image(systemName: "mappin.circle")
                                        .resizable()
                                        .foregroundStyle(.red)
                                        .frame(width: 44, height: 44)
                                        .background(.white)
                                        .clipShape(.circle)
                                        .simultaneousGesture(
                                            LongPressGesture().onEnded { _ in
                                                viewModel.selectedPlace = location
                                            }
                                        )
                                }
                            }
                        }
                    }
                    .mapStyle(viewModel.mapType == .standard ? .standard : .hybrid(elevation: .realistic))
                    .onTapGesture { position in
                        if let coordinate = proxy.convert(position, from: .local) {
                            viewModel.addLocation(at: coordinate)
                        }
                    }
                    .sheet(item: $viewModel.selectedPlace) { place in
                        EditView(location: place) {
                            viewModel.update(location: $0)
                        } onDelete: { id in
                            viewModel.removeLocation(id: id)
                        }
                    }
                }
                
                // Кнопка для переключения режимов
                VStack {
                    HStack {
                        Button(action: {
                            viewModel.clearAllLocations()
                        }, label: {
                            Image(systemName: "trash")
                                .padding(10)
                                .background(Color.red.opacity(0.8))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        })
                        
                        Spacer()
                        Button(action: {
                            viewModel.mapType = (viewModel.mapType == .standard) ? .hybrid : .standard
                        }) {
                            Text(viewModel.mapType == .standard ? Image(systemName: "map") : Image(systemName: "map.fill"))
                                .padding(10)
                                .background(Color.blue.opacity(0.8))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        
                    }
                    .padding(.horizontal)
                    Spacer()
                }
                
            }
        } else {
            VStack {
                Spacer()
                Button {
                    viewModel.authenticate()
                } label: {
                    Image(systemName: "lock.shield")
                        .padding()
                        .font(.system(size: 42))
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(.capsule)
                        .alert("Authentication Error", isPresented: $viewModel.showingAlert) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text(viewModel.alertMessage)
                        }
                }
                .padding()
            }
            /*
             else {
                Text("Authenticating...")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            }
            .onAppear {
            viewModel.authenticate()
            }
            .alert("Authentication Error", isPresented: $viewModel.showingAlert) {
            Button("OK", role: .cancel) { }
            } message: {
            Text(viewModel.alertMessage)
            }
             */
        }
    }
}

#Preview {
    ContentView()
}
