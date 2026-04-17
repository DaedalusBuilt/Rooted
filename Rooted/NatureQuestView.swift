import SwiftUI
import FirebaseDatabase

struct NatureQuestView: View {
    @State private var currentQuest: String = NatureQuestView.generateRandomQuest()
    @State private var completed = false
    @State private var globalCompletionCount: Int = 0
    
    private let ref = Database.database().reference()
    
    var body: some View {
        VStack(spacing: 35) {
            // Title
            Text("🌿 Random Nature Quest")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundColor(Color.green.opacity(0.85))
                .padding(.top, 40)
                .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
            
            // Quest Card
            VStack(alignment: .leading, spacing: 25) {
                Text(currentQuest)
                    .font(.title3)
                    .foregroundColor(Color.brown.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .background(Color.green.opacity(0.6))
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Color.green.opacity(0.7))
                        .font(.title3)
                        .padding(.top, 3)
                    
                    Text("Take your time, breathe deeply, and be fully present.")
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(Color.brown.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Completion Button
                Button(action: {
                    if !completed {
                        markQuestCompleted()
                    }
                }) {
                    HStack {
                        Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(completed ? .green : .gray)
                        Text(completed ? "Quest Completed" : "Mark as Completed")
                            .foregroundColor(completed ? .green : .primary)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(completed ? Color.green : Color.gray, lineWidth: 2)
                    )
                }
                .disabled(completed)
                
                // Global Completion Count
                Text("🌎 Completed by \(globalCompletionCount) people")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(
                        colors: [Color(.systemGray6), Color(.systemGray5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 10)
            )
            .padding(.horizontal, 20)
            
            // Refresh Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentQuest = NatureQuestView.generateRandomQuest()
                    completed = false
                    fetchGlobalCompletionCount()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title2)
                    Text("New Quest")
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
            
            Divider()
                .padding(.horizontal, 60)
            
            // Quote
            Text("“Look deep into nature, and then you will understand everything better.”\n— Albert Einstein")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.brown.opacity(0.5))
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.25), Color.green.opacity(0.15)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            fetchGlobalCompletionCount()
        }
        .padding(.top, 10)
        .frame(maxWidth: 600) // limit max width on wider screens
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Firebase Methods
    
    func fetchGlobalCompletionCount() {
        let key = sanitizeKey(for: currentQuest)
        ref.child("questCompletions").child(key).observeSingleEvent(of: .value) { snapshot in
            if let count = snapshot.value as? Int {
                globalCompletionCount = count
            } else {
                globalCompletionCount = 0
            }
        }
    }
    
    func markQuestCompleted() {
        let key = sanitizeKey(for: currentQuest)
        let questRef = ref.child("questCompletions").child(key)
        
        questRef.runTransactionBlock({ currentData in
            var value = currentData.value as? Int ?? 0
            value += 1
            currentData.value = value
            return TransactionResult.success(withValue: currentData)
        }, andCompletionBlock: { error, _, _ in
            if let error = error {
                print("Error updating completion count: \(error.localizedDescription)")
            } else {
                completed = true
                fetchGlobalCompletionCount()
            }
        })
    }
    
    func sanitizeKey(for quest: String) -> String {
        var key = quest
        let illegalChars = [".", "#", "$", "[", "]"]
        for ch in illegalChars {
            key = key.replacingOccurrences(of: ch, with: "-")
        }
        return key
    }
    
    static func generateRandomQuest() -> String {
        [
            "Take a 15-minute walk and photograph 3 different types of trees.",
            "Sit quietly in a natural spot and listen for 5 different bird calls.",
            "Find and collect 5 unique leaves and notice their textures.",
            "Spend 10 minutes observing the patterns on tree bark.",
            "Take slow, deep breaths while walking barefoot on grass.",
            "Watch the clouds and imagine shapes for 10 minutes.",
            "Pick up 3 pieces of litter to help keep nature clean.",
            "Draw a quick sketch of a plant or flower you see.",
            "Notice how sunlight filters through leaves on a tree.",
            "Identify 3 different insects crawling on the ground.",
            "Feel the texture of moss or lichen on a rock.",
            "Find a spot with running water and listen closely.",
            "Look for animal tracks and try to identify them.",
            "Collect some pinecones and observe their structure.",
            "Smell the scent of 3 different flowers or plants.",
            "Observe how shadows move as the sun shifts.",
            "Lie down and watch the stars for 10 minutes at night.",
            "Count the number of different colors you see in a flower bed.",
            "Feel the bark of 3 different tree species.",
            "Find a bird’s nest and observe from a distance.",
            "Touch water from a stream or pond and note its temperature.",
            "Notice any spider webs and the shapes they create.",
            "Take a photo of the sunrise or sunset.",
            "Look for signs of animal feeding like chewed leaves.",
            "Spot and identify 5 different cloud types.",
            "Track the path of an ant and watch its behavior.",
            "Listen for frogs or crickets in the evening.",
            "Draw a mandala using natural objects you find.",
            "Collect smooth stones and compare their shapes.",
            "Find a patch of wildflowers and identify their colors.",
            "Observe the wind by watching leaves or grass move.",
            "Take a nature selfie in your favorite outdoor spot.",
            "Find a tree with a hollow and imagine what lives inside.",
            "Watch an insect’s movement and mimic it with your hands.",
            "Write a haiku inspired by your surroundings.",
            "Collect different seeds and guess their plant types.",
            "Find a butterfly and follow it for a few minutes.",
            "Notice the sounds of water, wind, and animals combined.",
            "Feel the temperature difference between sun and shade.",
            "Observe how ants communicate or work together.",
            "Find 3 different types of bark patterns.",
            "Touch different types of leaves and compare their textures.",
            "Lie on the grass and count the number of birds flying overhead.",
            "Notice any mushrooms and their colors or shapes.",
            "Draw the shape of a nearby tree’s canopy.",
            "Find a spot with dappled sunlight and relax there.",
            "Collect fallen leaves and arrange them by size.",
            "Look for feathers and think about which birds they came from.",
            "Trace the outline of a leaf on paper.",
            "Feel the coolness of river water on your hands.",
            "Observe how ants build their hills or tunnels.",
            "Find a flower and describe its scent.",
            "Look for signs of nighttime animals like owl pellets.",
            "Count how many different greens you can see in a forest.",
            "Notice the sound of leaves crunching under your feet.",
            "Collect 3 different kinds of seeds.",
            "Find a place to meditate surrounded by trees.",
            "Observe a spider spinning its web.",
            "Touch a cactus or succulent and note its texture.",
            "Look closely at the veins in a leaf.",
            "Observe a squirrel or small mammal from a distance.",
            "Watch how the water reflects sunlight.",
            "Collect smooth pebbles and stack them carefully.",
            "Smell the fresh scent of rain on soil.",
            "Find a tree that has been marked by animals.",
            "Notice how plants grow towards the sun.",
            "Sketch a scene that inspires calmness.",
            "Listen to the rhythm of the wind through the trees.",
            "Find animal tracks in mud or sand.",
            "Observe how clouds change shape over 10 minutes.",
            "Collect pine needles and notice their length.",
            "Find a bird and try to identify its call.",
            "Watch ants work together carrying food.",
            "Touch wet leaves and feel their texture.",
            "Write a short poem about the sounds of nature.",
            "Feel the bark on an old tree versus a young one.",
            "Find a flower that grows wild nearby.",
            "Observe the patterns in a spider web.",
            "Collect a handful of soil and smell it.",
            "Notice the movement of grass in the breeze.",
            "Sketch the outline of a nearby hill or mountain.",
            "Take a slow walk and notice 10 different natural smells.",
            "Find a stream and watch the water flow.",
            "Listen carefully for bird songs at dawn.",
            "Look for animal homes like burrows or nests.",
            "Touch tree roots that are visible above ground.",
            "Collect different colored leaves and arrange them.",
            "Write down three things you see, hear, and smell.",
            "Watch an insect pollinate a flower.",
            "Collect feathers and compare their sizes.",
            "Feel the roughness of a tree branch.",
            "Notice the shapes made by branches against the sky.",
            "Look for patterns in sand or dirt.",
            "Observe an ant hill from a safe distance.",
            "Collect smooth stones and feel their coolness.",
            "Listen for the sound of running water.",
            "Find a tree with bright-colored leaves.",
            "Take a moment to breathe deeply and relax outdoors.",
            "Draw a leaf’s shadow on paper.",
            "Look for moss growing on rocks or trees.",
            "Find 3 types of wildflowers and name them.",
            "Observe how the wind moves the grass.",
            "Sketch a bird in flight.",
            "Write down a nature-inspired word that makes you happy.",
            "Feel the warmth of sunlight on your skin.",
            "Count how many different insects you can see.",
            "Find a quiet spot and listen for 5 different sounds.",
            "Collect a few seeds and guess which plants they come from.",
            "Look for spider webs covered in dew.",
            "Touch the petals of a flower gently.",
            "Notice how the air smells after a rainstorm.",
            "Watch how leaves fall from trees.",
            "Collect different shaped rocks.",
            "Look for animal footprints in mud.",
            "Feel the coolness of a shaded spot.",
            "Observe the direction of tree branches.",
            "Take a picture of your favorite natural spot.",
            "Write a thank-you note to nature in your journal.",
            "Notice the different textures of tree bark.",
            "Look for tiny flowers in grass.",
            "Feel the texture of a pinecone.",
            "Watch the sunrise or sunset quietly.",
            "Collect different types of seeds from plants.",
            "Observe a butterfly resting on a flower.",
            "Find a patch of clover and make a wish.",
            "Notice how water droplets cling to leaves.",
            "Draw a quick sketch of the sky.",
            "Look for insects crawling on tree trunks.",
            "Take a deep breath and smell the forest.",
            "Find a stick shaped like the letter Y.",
            "Count the number of bird songs you hear.",
            "Feel the softness of a flower petal.",
            "Look closely at the veins in leaves.",
            "Observe how shadows change throughout the day.",
            "Collect colorful fallen leaves.",
            "Listen to the sound of wind through pine needles.",
            "Find animal tracks in the dirt.",
            "Sketch the shape of a tree’s canopy.",
            "Write a haiku inspired by nature.",
            "Look for patterns in the bark of trees.",
            "Feel the texture of grass blades.",
            "Observe the colors of a flower closely.",
            "Find 5 different types of seeds.",
            "Watch a bird build its nest.",
            "Collect smooth river stones.",
            "Notice the sound of leaves rustling.",
            "Find a place to sit quietly for 10 minutes.",
            "Observe how ants move in a line.",
            "Sketch a plant you find interesting.",
            "Write down your favorite nature sound.",
            "Look for mushrooms growing on trees.",
            "Feel the roughness of tree bark.",
            "Collect fallen twigs and arrange them.",
            "Watch how water flows in a stream.",
            "Notice the shape of clouds.",
            "Find a tree with rough bark.",
            "Observe how plants grow towards light.",
            "Write a short story inspired by a natural object.",
            "Take a slow walk and notice smells.",
            "Look for signs of animals like feathers or fur.",
            "Feel the warmth of the sun on your face.",
            "Collect leaves of different shapes.",
            "Watch the movement of fish in a pond.",
            "Sketch the outline of a mountain.",
            "Listen for the sound of rain on leaves.",
            "Find a flower with a strong scent.",
            "Observe a spider weaving its web.",
            "Feel the coolness of a shady spot.",
            "Write a poem about the forest.",
            "Collect small stones and count them.",
            "Look for footprints in mud.",
            "Notice the colors of sunset.",
            "Sketch the silhouette of trees at dusk.",
            "Feel the texture of wet leaves.",
            "Watch a bird fly overhead.",
            "Take a deep breath and relax outdoors.",
            "Find 3 different flowers and identify them.",
            "Observe the pattern of leaves on a branch.",
            "Write down 5 things you see in nature.",
            "Collect seeds and try to plant one.",
            "Look for animal homes like nests or burrows.",
            "Feel the roughness of a tree trunk.",
            "Watch the flow of water in a creek.",
            "Sketch a leaf with detailed veins.",
            "Listen for different bird calls.",
            "Find a flower and touch its petals.",
            "Observe the movement of grass in wind.",
            "Write a thank-you note to nature.",
            "Collect 5 different leaves and press them.",
            "Notice the shapes of rocks along a trail.",
            "Feel the texture of pine needles.",
            "Watch the clouds and imagine shapes.",
            "Sketch the pattern of a spider web.",
            "Find a quiet spot and listen for 5 sounds.",
            "Write a haiku about a tree.",
            "Collect smooth pebbles from a river.",
            "Observe how sunlight filters through leaves.",
            "Feel the cool water of a stream.",
            "Look for signs of animal activity.",
            "Write a poem about the wind.",
            "Sketch a butterfly on a flower.",
            "Take a photo of your favorite natural object.",
            "Notice how shadows move during the day.",
            "Collect fallen twigs and arrange them in a pattern.",
            "Listen for the sound of insects at night.",
            "Feel the softness of moss.",
            "Write down your favorite nature memory.",
            "Observe how ants carry food.",
            "Find a flower and describe its color.",
            "Sketch the silhouette of a tree at sunset.",
            "Look for animal tracks in the snow.",
            "Feel the rough bark of a pine tree.",
            "Collect colorful autumn leaves.",
            "Write a story inspired by a forest walk.",
            "Observe the pattern of veins in a leaf.",
            "Take a slow walk and count different bird songs.",
            "Feel the texture of grass blades.",
            "Watch a squirrel gather food.",
            "Sketch a plant with interesting leaves.",
            "Notice the colors of flowers in bloom.",
            "Collect small stones and sort by color.",
            "Write a thank-you letter to a tree.",
            "Look for mushrooms growing on the forest floor.",
            "Feel the cool breeze on your skin.",
            "Watch the flow of water in a waterfall.",
            "Sketch a scene from your nature walk.",
            "Observe the movement of clouds across the sky.",
            "Write a poem about the stars at night.",
            "Collect different shaped leaves and compare them.",
            "Feel the warmth of sunlight on your arms.",
            "Look for animal footprints near a stream.",
            "Sketch the pattern of ripples in water.",
            "Listen to the sound of birds at dawn.",
            "Write down five things you are grateful for outdoors.",
            "Observe the shapes of rocks along a mountain trail.",
            "Feel the softness of flower petals.",
            "Watch a bee pollinate a flower.",
            "Sketch the outline of a tree’s shadow.",
            "Collect seeds and try to identify their plants.",
            "Write a story about an animal you saw.",
            "Look for signs of rain like dark clouds.",
            "Feel the texture of a rough stone.",
            "Watch the sunset and notice color changes.",
            "Sketch a leaf with unusual shape or color.",
            "Write a haiku about the sound of rain.",
            "Collect fallen branches and arrange a sculpture.",
            "Observe the movement of leaves in a gentle breeze.",
            "Feel the wetness of dew on grass.",
            "Look for birds building nests.",
            "Sketch a flower and its details.",
            "Write a thank-you note to the forest.",
            "Collect feathers and guess which bird they came from.",
            "Notice how water reflects sunlight.",
            "Feel the bark on a tree with your eyes closed.",
            "Watch a caterpillar crawling on a leaf.",
            "Write a poem about a mountain.",
            "Sketch the silhouette of a forest at twilight.",
            "Look for animal tracks in soft soil.",
            "Feel the softness of a fern leaf.",
            "Collect colorful leaves and press them in a book.",
            "Write a story inspired by a river.",
            "Observe the pattern of cracks in dry mud.",
            "Feel the coolness of a shaded area.",
            "Watch a flock of birds fly by.",
            "Sketch a tree with interesting branches.",
            "Write down five things you hear outdoors.",
            "Collect smooth stones from a beach.",
            "Look for patterns in the arrangement of flowers.",
            "Feel the roughness of a tree stump.",
            "Watch clouds form shapes in the sky.",
            "Write a thank-you letter to the earth.",
            "Sketch the pattern of veins in a leaf.",
            "Collect pinecones and notice their shape.",
            "Feel the warmth of the sun on your face.",
            "Look for signs of animals like chewed leaves.",
            "Watch the movement of water in a stream.",
            "Write a poem about the forest at night.",
            "Sketch the outline of a mountain peak.",
            "Collect seeds and try planting them at home.",
            "Feel the texture of tree bark.",
            "Observe how animals move through the forest.",
            "Write a story about a walk in nature.",
            "Look for birds’ nests high in the trees.",
            "Feel the softness of moss on rocks.",
            "Watch the changing colors of leaves in fall.",
            "Sketch a flower and its petals.",
            "Write a haiku about a butterfly.",
            "Collect smooth pebbles from a riverbank.",
            "Observe the pattern of shadows cast by trees.",
            "Feel the cool breeze on a warm day.",
            "Look for animal tracks in snow or mud.",
            "Watch the stars appear at dusk.",
            "Write a thank-you note to a favorite tree.",
            "Sketch the silhouette of a bird in flight.",
            "Collect fallen twigs and arrange them in a pattern.",
            "Feel the texture of pine needles.",
            "Observe how ants work together.",
            "Write a poem about the sound of the wind.",
            "Look for mushrooms growing on decaying wood.",
            "Feel the softness of flower petals.",
            "Watch a squirrel collect nuts.",
            "Sketch a tree with interesting bark.",
            "Write a story inspired by a river’s flow.",
            "Collect colorful leaves and press them.",
            "Observe the shapes of clouds.",
            "Feel the warmth of sunlight filtering through leaves.",
            "Look for signs of rain like dark clouds or puddles.",
            "Watch the movement of animals in a meadow.",
            "Write a haiku about a sunset.",
            "Sketch the outline of a forest path.",
            "Collect seeds and guess their plant types.",
            "Feel the texture of rough stones.",
            "Observe the pattern of ripples in water.",
            "Write a poem about the stars at night.",
            "Look for bird feathers and guess the species.",
            "Feel the bark on a tree with your eyes closed.",
            "Watch the waves crash on a shore.",
            "Sketch a flower and its detailed parts.",
            "Write a thank-you note to nature.",
            "Collect smooth stones and sort by size.",
            "Observe the movement of leaves in the wind.",
            "Feel the coolness of a shaded spot.",
            "Look for animal tracks near water.",
            "Watch a butterfly flutter among flowers.",
            "Write a story inspired by a mountain.",
            "Sketch the silhouette of trees at dawn.",
            "Collect pinecones and notice their patterns.",
            "Feel the softness of moss underfoot.",
            "Observe how sunlight changes throughout the day.",
            "Write a poem about a forest stream.",
            "Look for signs of animals like nests or burrows.",
            "Feel the roughness of bark on different trees.",
            "Watch clouds change shapes over time.",
            "Sketch a bird perched on a branch.",
            "Write down five things you see in nature.",
            "Collect colorful leaves and arrange them.",
            "Observe the sound of running water.",
            "Feel the warmth of the sun on your skin.",
            "Look for patterns in sand or soil.",
            "Watch the flight of birds during migration.",
            "Write a haiku inspired by a flower.",
            "Sketch the outline of a tree with sprawling branches.",
            "Collect seeds and try planting them.",
            "Feel the texture of different leaves.",
            "Observe the colors of a sunset or sunrise.",
            "Write a thank-you note to the earth.",
            "Look for animal tracks in soft dirt.",
            "Watch the movement of fish in a pond.",
            "Sketch a flower with intricate details.",
            "Write a poem about the wind in the trees.",
            "Collect smooth stones and feel their coolness.",
            "Observe how ants work in a colony.",
            "Feel the softness of petals on a flower.",
            "Look for signs of rain like puddles or wet leaves.",
            "Watch the stars at night and identify constellations.",
            "Write a story inspired by a nature walk.",
            "Sketch the silhouette of a mountain range.",
            "Collect different types of seeds and study their shapes.",
            "Feel the texture of bark on an old tree.",
            "Observe the pattern of veins in leaves.",
            "Write a haiku about a bird’s song.",
            "Look for mushrooms growing on the forest floor.",
            "Watch the changing colors of leaves in autumn.",
            "Sketch a tree with interesting bark patterns.",
            "Write a thank-you note to a favorite nature spot.",
            "Collect feathers and guess which birds they came from.",
            "Feel the cool breeze on a summer day.",
            "Observe the sound of water flowing in a stream.",
            "Watch a butterfly land on a flower.",
            "Write a poem about the forest at dawn.",
            "Sketch the outline of a leaf with detailed veins.",
            "Collect fallen twigs and arrange them artfully.",
            "Feel the roughness of a pinecone.",
            "Look for animal footprints in mud or sand.",
            "Watch the clouds and imagine shapes.",
            "Write a story inspired by the sounds of nature.",
            "Sketch a flower with delicate petals.",
            "Collect smooth pebbles and sort by color.",
            "Observe the movement of grass in the wind.",
            "Feel the warmth of sunlight on your face.",
            "Look for signs of wildlife like feathers or fur.",
            "Watch the stars appear in the night sky.",
            "Write a haiku about the scent of flowers.",
            "Sketch the silhouette of trees at sunset.",
            "Collect seeds and try planting them at home.",
            "Feel the texture of soft moss.",
            "Observe the pattern of cracks in dry soil.",
            "Write a poem about the sound of rain.",
            "Look for animal homes like nests or burrows.",
            "Watch a bird build its nest carefully.",
            "Sketch the outline of a mountain peak.",
            "Collect colorful leaves and press them.",
            "Feel the rough bark of a tree.",
            "Observe the flow of water in a river.",
            "Write a thank-you note to the natural world.",
            "Look for butterflies fluttering among flowers.",
            "Watch the sunset and notice color changes.",
            "Sketch a flower and its leaves.",
            "Collect fallen leaves and arrange them by color.",
            "Feel the coolness of a shaded area.",
            "Observe the sound of birds singing at dawn.",
            "Write a poem inspired by the forest.",
            "Look for signs of animals like footprints or droppings.",
            "Watch the flight of birds in the sky.",
            "Sketch a tree with sprawling branches.",
            "Collect pinecones and notice their shapes.",
            "Feel the softness of petals on a flower.",
            "Observe the movement of clouds across the sky.",
            "Write a haiku about the wind in the trees.",
            "Look for mushrooms growing on decaying logs.",
            "Watch a squirrel gather food for winter.",
            "Sketch the silhouette of a forest at twilight.",
            "Collect seeds and try planting them in a garden.",
            "Feel the roughness of tree bark with your fingers.",
            "Observe how animals move in their natural habitats.",
            "Write a story about a walk through the woods.",
            "Look for bird nests hidden in the trees.",
            "Watch the changing colors of leaves in fall.",
            "Sketch a flower and its detailed petals.",
            "Write a poem about a butterfly’s flight.",
            "Collect smooth stones from a streambed.",
            "Observe the pattern of shadows cast by trees.",
            "Feel the cool breeze on a warm afternoon.",
            "Look for animal tracks in mud or snow.",
            "Watch the stars twinkle on a clear night.",
            "Write a thank-you note to a tree that inspires you.",
            "Sketch the outline of a bird in flight.",
            "Collect fallen twigs and arrange them in a pattern.",
            "Feel the texture of pine needles on your hand.",
            "Observe how ants work together to build their colony.",
            "Write a poem about the sound of rain on leaves.",
            "Look for mushrooms growing in shaded areas.",
            "Feel the softness of flower petals on a spring day.",
            "Watch a butterfly fluttering among wildflowers.",
            "Sketch a tree with rough bark and interesting texture.",
            "Write a story inspired by a rushing river.",
            "Collect colorful leaves and press them in a book.",
            "Observe the shapes and patterns of clouds overhead.",
            "Feel the warmth of the sun as it filters through branches.",
            "Look for signs of approaching rain like darkening skies.",
            "Watch the movement of animals in a meadow or forest.",
            "Write a haiku inspired by a beautiful sunset.",
            "Sketch the outline of a peaceful forest path.",
            "Collect seeds and try planting them in pots at home.",
            "Feel the rough texture of stones found on a trail.",
            "Observe the ripple patterns created by a gentle breeze.",
            "Write a poem about the stars shining brightly at night.",
            "Look for feathers dropped by birds and guess their origins.",
            "Feel the bark of a tree with your eyes closed.",
            "Watch waves crashing on a rocky shore or beach.",
            "Sketch a delicate flower and its petals carefully.",
            "Write a thank-you note expressing gratitude for nature.",
            "Collect smooth stones and organize them by size or color.",
            "Observe how leaves flutter in the wind on a breezy day.",
            "Feel the coolness of a shaded forest floor.",
            "Look for animal tracks near bodies of water.",
            "Watch a butterfly rest on a flower for several minutes.",
            "Write a story about an adventurous hike through the wilderness.",
            "Sketch the silhouette of towering trees at dawn.",
            "Collect pinecones and observe the unique patterns they form.",
            "Feel the softness of moss growing on rocks or trees.",
            "Observe the changing colors of foliage throughout the seasons.",
            "Write a poem describing the calming sounds of a forest stream.",
            "Look for signs of animal life such as nests, burrows, or droppings.",
            "Feel the roughness of tree bark with your fingertips.",
            "Watch clouds drift lazily across the bright blue sky.",
            "Sketch a bird perched gracefully on a branch.",
            "Write down five things you notice in your natural surroundings.",
            "Collect colorful leaves and create a nature-inspired collage.",
            "Observe the gentle sound of flowing water in a creek or river.",
            "Feel the warmth of sunlight on your face during a walk.",
            "Look for interesting patterns in sand, dirt, or rock formations.",
            "Watch migrating birds flying in formation overhead.",
            "Write a haiku about the delicate beauty of a flower.",
            "Sketch the outline of a large tree with spreading branches.",
            "Collect seeds and attempt to identify the plants they belong to.",
            "Feel the texture of a variety of leaves you find on the ground.",
            "Observe the brilliant colors of a sunrise or sunset.",
            "Write a thank-you note honoring the natural world around you."
        ].randomElement()!
            }
        }

        struct ScaleButtonStyle: ButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .scaleEffect(configuration.isPressed ? 0.93 : 1)
                    .opacity(configuration.isPressed ? 0.85 : 1)
                    .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            }
        }
