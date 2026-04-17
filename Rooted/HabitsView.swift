import SwiftUI

struct HabitsView: View {
    @State private var habits: [Habit] = []
    @State private var newHabitName: String = ""
    
    private let habitsKey = "savedHabits"
    
    var body: some View {
        VStack(spacing: 30) {
            
            // Title
            Text("🌱 Eco Habits")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundColor(Color.green.opacity(0.85))
                .padding(.top, 40)
                .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // Add Habit Input
            HStack {
                TextField("New habit...", text: $newHabitName)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .shadow(radius: 1)
                
                Button(action: {
                    let trimmed = newHabitName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    habits.append(Habit(name: trimmed))
                    newHabitName = ""
                    saveHabits()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(Color.green.opacity(0.85))
                }
            }
            .padding(.horizontal)
            
            // Habit List
            List {
                ForEach($habits) { $habit in
                    HStack {
                        Button(action: {
                            habit.isComplete.toggle()
                            saveHabits()
                        }) {
                            Image(systemName: habit.isComplete ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(habit.isComplete ? Color.green.opacity(0.85) : Color.brown.opacity(0.4))
                                .font(.title2)
                        }

                        Text(habit.name)
                            .font(.title3)
                            .foregroundColor(habit.isComplete ? Color.brown.opacity(0.7) : Color.brown.opacity(0.95))
                            .strikethrough(habit.isComplete, color: Color.brown.opacity(0.7))
                        
                        Spacer()
                    }
                    .listRowBackground(Color(.systemGray6))
                }
                .onDelete(perform: deleteHabits)
            }
            .listStyle(.plain)
            .frame(maxHeight: 340)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)
            .shadow(radius: 4)
            
            // Clear All Button
            Button(action: {
                withAnimation {
                    habits.indices.forEach { habits[$0].isComplete = false }
                    saveHabits()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.title2)
                    Text("Clear All")
                        .fontWeight(.semibold)
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
        .onAppear(perform: loadHabits)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.25), Color.green.opacity(0.15)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
    
    private func deleteHabits(at offsets: IndexSet) {
        habits.remove(atOffsets: offsets)
        saveHabits()
    }
    
    // MARK: - Persistence
    
    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: habitsKey)
        }
    }
    
    private func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: habitsKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        } else {
            // Load default habits on first launch
            habits = [
                Habit(name: "Use a reusable water bottle"),
                Habit(name: "Turn off lights when not in use"),
                Habit(name: "Avoid single-use plastics")
            ]
        }
    }
}

struct Habit: Identifiable, Codable {
    let id: UUID
    var name: String
    var isComplete: Bool
    
    init(id: UUID = UUID(), name: String, isComplete: Bool = false) {
        self.id = id
        self.name = name
        self.isComplete = isComplete
    }
}

struct ScaleButtonStle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

