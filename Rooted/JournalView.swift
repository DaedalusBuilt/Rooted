import SwiftUI
import FirebaseDatabase

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let content: String
    
    init(id: UUID = UUID(), date: Date, content: String) {
        self.id = id
        self.date = date
        self.content = content
    }
    
    // Helper to convert to dictionary for Firebase saving
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "date": date.timeIntervalSince1970,
            "content": content
        ]
    }
    
    // Helper to create from dictionary (Firebase loading)
    static func fromDictionary(_ dict: [String: Any]) -> JournalEntry? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let timestamp = dict["date"] as? TimeInterval,
              let content = dict["content"] as? String else {
            return nil
        }
        let date = Date(timeIntervalSince1970: timestamp)
        return JournalEntry(id: id, date: date, content: content)
    }
}
struct DayStreakBar: View {
    let currentStreak: Int
    let goal: Int

    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(currentStreak) / Double(goal), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Streak")
                .font(.headline)
                .foregroundColor(Color.green.opacity(0.85))

            ZStack(alignment: .leading) {
                Capsule().frame(height: 20).foregroundColor(Color.green.opacity(0.3))
                Capsule()
                    .frame(width: CGFloat(progress) * 300, height: 20)
                    .foregroundColor(Color.green)
                    .animation(.easeInOut, value: progress)
            }

            Text("\(currentStreak) / \(goal) days")
                .font(.subheadline)
                .foregroundColor(Color.brown.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 5)
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}


struct LeaderboardView: View {
    let currentUserStreak: Int
    @EnvironmentObject var accountManager: AccountManager
    
    @State private var leaderboardData: [(username: String, streak: Int)] = []
    
    private let ref = Database.database().reference()
    
    var userId: String? {
        accountManager.currentUser?.username
    }
    
    var body: some View {
        List {
            ForEach(Array(leaderboardData.enumerated()), id: \.offset) { index, entry in
                HStack {
                    Text("\(index + 1). \(entry.username)")
                        .fontWeight(entry.username == (accountManager.currentUser?.username ?? "") ? .bold : .regular)
                    Spacer()
                    Text("\(entry.streak) days")
                        .foregroundColor(.green)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("🏆 Leaderboard")
        .onAppear {
            loadLeaderboard()
        }
    }
    
    // MARK: - Firebase Functions
    
    func loadLeaderboard() {
        ref.child("leaderboard").observeSingleEvent(of: .value) { snapshot in
            var tempData: [(String, Int)] = []
            
            if let dict = snapshot.value as? [String: Any] {
                for (key, value) in dict {
                    if let streak = value as? Int {
                        tempData.append((key, streak))
                    }
                }
            }
            
            // Update current user's streak in leaderboard data or add it
            if let userId = userId {
                if let index = tempData.firstIndex(where: { $0.0 == userId }) {
                    tempData[index].1 = max(tempData[index].1, currentUserStreak)
                } else {
                    tempData.append((userId, currentUserStreak))
                }
            }
            
            // Sort descending by streak
            leaderboardData = tempData.sorted { $0.1 > $1.1 }
            
            // Save updated leaderboard back to Firebase
            saveLeaderboard()
        }
    }
    
    func saveLeaderboard() {
        var dataToSave: [String: Int] = [:]
        for entry in leaderboardData {
            dataToSave[entry.0] = entry.1
        }
        ref.child("leaderboard").setValue(dataToSave) { error, _ in
            if let error = error {
                print("Error saving leaderboard: \(error.localizedDescription)")
            } else {
                print("Leaderboard saved successfully")
            }
        }
    }
}

struct AddJournalEntryView: View {
    @State private var text = ""
    @Environment(\.dismiss) private var dismiss
    var onSave: (String) -> Void

    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $text)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.6), lineWidth: 1))
                    .font(.title3)
                    .foregroundColor(Color.brown.opacity(0.85))
                    .frame(minHeight: 200)
                    .padding()
                Spacer()
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.25), Color.green.opacity(0.15)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                .ignoresSafeArea()
            )
            .navigationTitle("New Journal Entry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.green.opacity(0.8))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onSave(trimmed)
                        }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(
                        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? .gray
                        : Color.green.opacity(0.8)
                    )
                }
            }
        }
    }
}

struct JournalView: View {
    @EnvironmentObject var accountManager: AccountManager
    @State private var entries: [JournalEntry] = []
    @State private var showingAddEntry = false

    private let streakGoal = 30
    private let ref = Database.database().reference()
    
    var userId: String? {
        // Assuming currentUser has a userId property (replace as needed)
        
        accountManager.currentUser?.username
        

    }
    
    var currentStreak: Int {
        // ... your existing streak calculation ...
        guard !entries.isEmpty else { return 0 }
        let sortedEntries = entries.sorted(by: { $0.date > $1.date })
        var streak = 0
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        var dayToCheck = calendar.startOfDay(for: Date())
        
        for entry in sortedEntries {
            let entryDay = calendar.startOfDay(for: entry.date)
            if entryDay == dayToCheck {
                streak += 1
                if let previousDay = calendar.date(byAdding: .day, value: -1, to: dayToCheck) {
                    dayToCheck = previousDay
                }
            } else if entryDay < dayToCheck {
                let diff = calendar.dateComponents([.day], from: entryDay, to: dayToCheck).day ?? 0
                if diff == 1 {
                    streak += 1
                    dayToCheck = calendar.date(byAdding: .day, value: -1, to: entryDay) ?? dayToCheck
                } else {
                    break
                }
            }
        }
        return streak
    }
    
    // MARK: - Firebase save/load/delete

    func saveEntries() {
        guard let userId = userId else {
            print("No user ID - cannot save entries")
            return
        }
        
        let entriesDict = entries.reduce(into: [String: Any]()) { partialResult, entry in
            partialResult[entry.id.uuidString] = entry.toDictionary()
        }
        
        ref.child("users").child(userId).child("journalEntries").setValue(entriesDict) { error, _ in
            if let error = error {
                print("Error saving journal entries: \(error.localizedDescription)")
            } else {
                print("Journal entries saved successfully.")
            }
        }
    }
    
    func loadEntries() {
        guard let userId = userId else {
            print("No user ID - cannot load entries")
            return
        }
        
        ref.child("users").child(userId).child("journalEntries").observeSingleEvent(of: .value) { snapshot in
            var loadedEntries: [JournalEntry] = []
            
            if let dict = snapshot.value as? [String: Any] {
                for (_, value) in dict {
                    if let entryDict = value as? [String: Any],
                       let entry = JournalEntry.fromDictionary(entryDict) {
                        loadedEntries.append(entry)
                    }
                }
            }
            
            entries = loadedEntries.sorted(by: { $0.date > $1.date })
        }
    }
    
    func deleteEntry(_ entry: JournalEntry) {
        guard let userId = userId else {
            print("No user ID - cannot delete entry")
            return
        }
        
        ref.child("users").child(userId).child("journalEntries").child(entry.id.uuidString).removeValue { error, _ in
            if let error = error {
                print("Error deleting entry: \(error.localizedDescription)")
            } else {
                entries.removeAll(where: { $0.id == entry.id })
                print("Entry deleted successfully")
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 35) {
                let usernameText = accountManager.currentUser?.username != nil ? "– \(accountManager.currentUser!.username)" : ""
                Spacer(minLength: 40)
                Text("📓 Nature Journal \(usernameText)")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundColor(Color.green.opacity(0.85))
                    .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)

                DayStreakBar(currentStreak: currentStreak, goal: streakGoal)

                ScrollView {
                    if entries.isEmpty {
                        Text("No entries yet.\nTap the + button to add a reflection.")
                            .font(.title3)
                            .foregroundColor(Color.brown.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(50)
                    } else {
                        VStack(alignment: .leading, spacing: 25) {
                            ForEach(entries) { entry in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundColor(Color.green.opacity(0.7))

                                            Text(entry.content)
                                                .font(.title3)
                                                .foregroundColor(Color.brown.opacity(0.95))
                                                .fixedSize(horizontal: false, vertical: true)
                                                .lineSpacing(5)
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            deleteEntry(entry)
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                }
                                .padding(.vertical, 8)

                                Divider().background(Color.green.opacity(0.6))
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 25)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(LinearGradient(colors: [Color(.systemGray6), Color(.systemGray5)],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 10)
                )
                .padding(.horizontal, 24)
                .frame(maxHeight: 450)

                Button(action: { showingAddEntry = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill").font(.title2)
                        Text("New Entry").fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 36)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.85))
                            .shadow(color: Color.green.opacity(0.4), radius: 8, x: 0, y: 5)
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                Spacer()
            }
            .navigationBarItems(trailing:
                NavigationLink(destination: LeaderboardView(currentUserStreak: currentStreak)) {
                    Image(systemName: "list.number")
                        .imageScale(.large)
                        .foregroundColor(.green)
                }
            )
            .ignoresSafeArea(edges: .top)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.25), Color.green.opacity(0.15)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                .ignoresSafeArea()
            )
            .sheet(isPresented: $showingAddEntry) {
                AddJournalEntryView { content in
                    let newEntry = JournalEntry(date: Date(), content: content)
                    entries.append(newEntry)
                    saveEntries() // Save all entries after appending
                    showingAddEntry = false
                }
                .environmentObject(accountManager)
            }
            .onAppear {
                loadEntries()
            }
        }
    }
}

