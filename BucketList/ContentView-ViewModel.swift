//
//  ContentView-ViewModel.swift
//  BucketList
//
//  Created by Saydulayev on 06.01.25.
//

import CoreLocation
import Foundation
import LocalAuthentication
import MapKit

extension ContentView {
    @Observable
    class ViewModel {
        let savePath = URL.documentsDirectory.appending(path: "SavedPlaces")

        private(set) var locations: [Location]
        var selectedPlace: Location?
        var isUnlocked = false
        var showingAlert = false
        var alertMessage = ""
        var mapType: MKMapType = .standard

        init() {
            do {
                let data = try Data(contentsOf: savePath)
                locations = try JSONDecoder().decode([Location].self, from: data)
            } catch {
                locations = []
            }
        }

        func save() {
            do {
                let data = try JSONEncoder().encode(locations)
                try data.write(to: savePath, options: [.atomic, .completeFileProtection])
            } catch {
                print("Unable to save data.")
            }
        }

        func addLocation(at point: CLLocationCoordinate2D) {
            let geocoder = CLGeocoder()

            geocoder.reverseGeocodeLocation(CLLocation(latitude: point.latitude, longitude: point.longitude)) { [weak self] placemarks, error in
                guard let self = self else { return }

                if let placemark = placemarks?.first {
                    // Формируем название местности
                    let name = [
                        placemark.locality,           // Город
                        placemark.administrativeArea, // Регион/область
                        placemark.country             // Страна
                    ]
                    .compactMap { $0 } // Убираем nil
                    .joined(separator: ", ") // Объединяем с разделителем

                    // Создаём новую метку с полученным названием
                    let newLocation = Location(
                        id: UUID(),
                        name: name.isEmpty ? "New location" : name,
                        description: "",
                        latitude: point.latitude,
                        longitude: point.longitude
                    )

                    self.locations.append(newLocation)
                    self.save()
                } else {
                    // Если обратное геокодирование не удалось, создаём метку с дефолтным названием
                    let newLocation = Location(
                        id: UUID(),
                        name: "New location",
                        description: "",
                        latitude: point.latitude,
                        longitude: point.longitude
                    )

                    self.locations.append(newLocation)
                    self.save()
                }
            }
        }

        func update(location: Location) {
            guard let selectedPlace else { return }

            if let index = locations.firstIndex(of: selectedPlace) {
                locations[index] = location
                save()
            }
        }

        func removeLocation(id: UUID) {
            if let index = locations.firstIndex(where: { $0.id == id }) {
                locations.remove(at: index)
                save()
            }
        }


        func clearAllLocations() {
            // Полная очистка всех меток
            locations.removeAll()
            save()
        }

        func authenticate() {
                let context = LAContext()
                var error: NSError?

                if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                    let reason = "Please authenticate yourself to unlock your places."

                    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                        DispatchQueue.main.async {
                            if success {
                                self.isUnlocked = true
                            } else {
                                self.alertMessage = authenticationError?.localizedDescription ?? "Authentication failed."
                                self.showingAlert = true
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.alertMessage = error?.localizedDescription ?? "Biometric authentication is not available."
                        self.showingAlert = true
                    }
                }
            }
    }
}

