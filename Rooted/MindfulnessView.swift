import SwiftUI

struct MindfulnessView: View {
    @State private var currentPage = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Fixed title
            Text("🧘‍♀️ Mindfulness")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundColor(Color.green.opacity(0.85))
                .padding(.top, 40)
                .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
            
            TabView(selection: $currentPage) {
                GuidedBreathingView()
                    .tag(0)
                SoundscapeView()
                    .tag(1)
                MeditationTipsView()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 480)
            .padding(.horizontal, 24)
            
            // Page indicator dots
            HStack(spacing: 12) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index == currentPage ? Color.green.opacity(0.85) : Color.green.opacity(0.3))
                        .frame(width: 10, height: 10)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.bottom, 10)
            
            // Quote near content
            Text(pageQuote(for: currentPage))
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.brown.opacity(0.5))
                .padding(.horizontal, 40)
            
            Spacer(minLength: 20)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.25), Color.green.opacity(0.15)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
    
    func pageQuote(for page: Int) -> String {
        switch page {
        case 0:
            return "“Mindfulness is the gateway to peace within.”"
        case 1:
            return "“Let nature’s sounds calm your mind.”"
        case 2:
            return "“A moment of calm is a moment of strength.”"
        default:
            return ""
        }
    }
}


struct GuidedBreathingView: View {
    @State private var isBreathing = false
    @State private var breathScale: CGFloat = 1.0
    
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Guided Breathing")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(Color.pink.opacity(0.9))
                .padding(.bottom, 10)
            
            ZStack {
                Circle()
                    .stroke(Color.pink.opacity(0.3), lineWidth: 20)
                    .frame(width: 220, height: 220)
                
                Circle()
                    .fill(Color.pink.opacity(0.5))
                    .frame(width: 160, height: 160)
                    .scaleEffect(breathScale)
                    .animation(.easeInOut(duration: 3), value: breathScale)
                
                Text(isBreathing ? "Breathe\nIn & Out" : "Ready?")
                    .font(.title2.italic())
                    .foregroundColor(Color.pink.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
            
            Button(action: {
                if isBreathing {
                    stopBreathing()
                } else {
                    startBreathing()
                }
            }) {
                Text(isBreathing ? "Stop" : "Start")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 40)
                    .background(
                        Capsule()
                            .fill(Color.pink.opacity(0.85))
                            .shadow(color: Color.pink.opacity(0.4), radius: 8, x: 0, y: 5)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(
                    colors: [Color(.systemGray6), Color(.systemGray5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
                )
                .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 10)
        )
        .onDisappear {
            stopBreathing()
        }
    }
    
    func startBreathing() {
        isBreathing = true
        breathScale = 1.6
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 3)) {
                breathScale = (breathScale == 1.6) ? 1.0 : 1.6
            }
        }
        timer?.fire()
    }
    
    func stopBreathing() {
        isBreathing = false
        timer?.invalidate()
        timer = nil
        withAnimation(.easeOut(duration: 1)) {
            breathScale = 1.0
        }
    }
}

struct SoundscapeView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("Soundscape")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(Color.brown.opacity(0.9))
                .padding(.bottom, 10)
            
            Text("🔈 Coming Soon")
                .font(.title3.italic())
                .foregroundColor(Color.brown.opacity(0.5))
            
            Spacer()
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(
                    colors: [Color(.systemGray6), Color(.systemGray5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
                )
                .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 10)
        )
    }
}

struct MeditationTipsView: View {
    let tips = [
        "Focus on your breath for 5 minutes.",
        "Notice the sensations in your body.",
        "Repeat a calming mantra silently.",
        "Practice gratitude for the moment.",
        "Observe your thoughts without judgment."
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Meditation Tips")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color.brown.opacity(0.9))
                    .padding(.bottom, 10)
                
                ForEach(tips, id: \.self) { tip in
                    Text("• \(tip)")
                        .font(.title3)
                        .foregroundColor(Color.brown.opacity(0.85))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer(minLength: 40)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(
                        colors: [Color(.systemGray6), Color(.systemGray5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                    )
                    .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
        }
    }
}

// Button press scale effect reused
struct ScaleButtonStye: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

