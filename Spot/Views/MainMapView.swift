//
//  MainMapView.swift
//  Spot
//
//  Created by Frank Guglielmo on 12/9/24.
//

import SwiftUI
import MapKit

// MARK: - MainMapView (with Tabs)
struct MainMapView: View {
    var body: some View {
        TabView {
            
            Text("Second View")
                .tabItem {
                    Image(systemName: "heart")
                    Text("Favorites")
                }
            
            // First tab: Explore
            ExploreView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Explore")
                }

            // Second tab: Favorites placeholder
            

            // Third tab: Profile placeholder
            Text("Third View")
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
    }
}

// MARK: - ExploreView (Previously ContentView logic)
struct ExploreView: View {
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var cardOffset = CGSize.zero
    @State private var cardPresented = false // Track card state (full screen or half)
    @ObservedObject private var locationViewModel = LocationViewModel()

    init() {
        print("ExploreView init")
        fetchData()
    }

    func fetchData() {
        Task {
            await locationViewModel.fetchData()
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // Map on the top ~half + 30 for styling
                    Map(position: $position) {
                        // The new Map APIs use the Annotation initializer:
                        UserAnnotation()
                    }
                    .mapControls {
                        MapUserLocationButton()
                    }
                    .frame(height: geometry.size.height / 2 + 30)
                    .contentMargins(27)

                    Spacer()
                }

                // Draggable card
                CardView(locations: $locationViewModel.locations)
                    .offset(y: calculatedCardOffset(geometry: geometry))
                    .animation(.spring(), value: cardPresented)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let yOffset = gesture.translation.height
                                // Only allow dragging upwards
                                if yOffset < 0 {
                                    // Limit how far up it can go
                                    self.cardOffset = CGSize(width: 0, height: max(yOffset, -geometry.size.height / 2))
                                }
                            }
                            .onEnded { _ in
                                if self.cardOffset.height < -geometry.size.height / 16 {
                                    // If dragged beyond threshold, present card full screen
                                    self.cardPresented = true
                                } else {
                                    // Snap back to half-screen
                                    self.cardPresented = false
                                }
                                self.cardOffset = .zero
                            }
                    )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func calculatedCardOffset(geometry: GeometryProxy) -> CGFloat {
        if cardPresented {
            // If presented full screen, offset only slightly
            return 50 + cardOffset.height
        } else {
            // If half screen, offset to bottom half
            return geometry.size.height / 2 + cardOffset.height
        }
    }
}

// MARK: - CardView and Supporting Views
struct CardView: View {
    @Binding var locations: [Location]

    var body: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(Color.white)
            .frame(height: UIScreen.main.bounds.height) // Full screen height so it can slide up
            .shadow(radius: 10)
            .overlay(
                VStack {
                    GrabberHandle()
                    LocationsScrollView(locations: locations)
                }
            )
    }
}

struct GrabberHandle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 5)
            .frame(width: 80, height: 10)
            .foregroundColor(.gray)
            .padding(5)
    }
}

// Example scroll view of locations
struct LocationsScrollView: View {
    let locations: [Location]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(locations, id: \.id) { loc in
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                        VStack(alignment: .leading) {
                            Text(loc.name)
                                .font(.headline)
                            Text(loc.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding([.horizontal, .top])
                }
            }
        }
    }
}

// MARK: - Mock Models & ViewModel (Adjust as needed)
struct Location: Identifiable {
    let id = UUID()
    let name: String
    let address: String
}

@MainActor
class LocationViewModel: ObservableObject {
    @Published var locations: [Location] = []

    func fetchData() async {
        // Simulate fetching data
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            self.locations = [
                Location(name: "Coffee Shop A", address: "123 Main St"),
                Location(name: "Coworking Space B", address: "456 Market St"),
                Location(name: "Coffee Shop C", address: "789 Broadway")
            ]
        } catch {
            print("Failed to fetch locations...")
        }
    }
}

// MARK: - Mock MapCameraPosition, UserAnnotation, and MapUserLocationButton for the sake of example

struct MapUserLocationButton: View {
    var body: some View {
        Button(action: {}) {
            Image(systemName: "location.fill")
                .padding(8)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 2)
        }
        .padding()
    }
}

// MARK: - Preview
struct MainMapView_Previews: PreviewProvider {
    static var previews: some View {
        MainMapView()
    }
}
