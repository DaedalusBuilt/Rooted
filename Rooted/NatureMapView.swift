import SwiftUI
import MapKit
import CoreLocation

struct NatureMapView: View {
    @StateObject private var locationManager = LocationManager()

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default fallback location
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var hasCenteredOnUser = false

    @State private var userNotes: [UserNote] = []
    @State private var newNoteLocation: CLLocationCoordinate2D?
    @State private var showingNoteAlert = false
    @State private var noteText = ""

    private let userNotesKey = "userNotes"

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: userNotes) { note in
                MapAnnotation(coordinate: note.coordinate) {
                    VStack(spacing: 2) {
                        Image(systemName: "leaf.circle.fill")
                            .foregroundColor(.green)
                            .font(.title)
                        Text(note.title)
                            .font(.caption2)
                            .foregroundColor(.brown)
                    }
                }
            }
            .onAppear {
                locationManager.requestLocation()
                loadUserNotes()
            }
            .onChange(of: locationManager.lastLocation) { newLocation in
                if let location = newLocation, !hasCenteredOnUser {
                    withAnimation {
                        region.center = location.coordinate
                        hasCenteredOnUser = true
                    }
                }
            }
            .gesture(
                LongPressGesture(minimumDuration: 1.0)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onEnded { value in
                        switch value {
                        case .second(true, let drag?):
                            let location = drag.location
                            let coordinate = convertToCoordinate(from: location)
                            newNoteLocation = coordinate
                            showingNoteAlert = true
                        default:
                            break
                        }
                    }
            )
            .ignoresSafeArea()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    TipCard(text: "🌿 Find a nearby park and walk its full loop.")
                    TipCard(text: "🧘‍♂️ Sit quietly and listen for five different sounds.")
                    TipCard(text: "📸 Take a photo of something blooming.")
                }
                .padding()
            }
            .background(.ultraThinMaterial)
        }
        .alert("New Note", isPresented: $showingNoteAlert, actions: {
            TextField("Describe this place...", text: $noteText)
            Button("Add") {
                if let coord = newNoteLocation {
                    let note = UserNote(title: noteText, coordinate: coord)
                    userNotes.append(note)
                    saveUserNotes()
                }
                noteText = ""
            }
            Button("Cancel", role: .cancel) {}
        })
    }

    func convertToCoordinate(from location: CGPoint) -> CLLocationCoordinate2D {
        // You can improve this by bridging with UIKit's MKMapView if needed,
        // but for now, just return region.center as fallback:
        return region.center
    }

    func saveUserNotes() {
        if let encoded = try? JSONEncoder().encode(userNotes) {
            UserDefaults.standard.set(encoded, forKey: userNotesKey)
        }
    }

    func loadUserNotes() {
        if let data = UserDefaults.standard.data(forKey: userNotesKey),
           let decoded = try? JSONDecoder().decode([UserNote].self, from: data) {
            userNotes = decoded
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.first
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

struct TipCard: View {
    let text: String

    var body: some View {
        Text(text)
            .padding()
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.green.opacity(0.1)))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            .frame(width: 260)
    }
}

struct UserNote: Identifiable, Codable {
    let id: UUID
    var title: String
    var coordinate: CLLocationCoordinate2D

    enum CodingKeys: CodingKey {
        case id, title, latitude, longitude
    }

    init(id: UUID = UUID(), title: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.title = title
        self.coordinate = coordinate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
}

#Preview {
    NatureMapView()
}

