import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "text.bubble")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("LLM Text Refiner")
                .font(.title)
            Text("Menu bar application running")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
} 