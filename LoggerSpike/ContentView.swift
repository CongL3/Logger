import SwiftUI

struct ContentView: View {

    var body: some View {
        TabView {
            PokemonScreen()
                .tabItem {
                    Label("Pokémon API", systemImage: "leaf")
                }

            JsonPlaceholderScreen()
                .tabItem {
                    Label("JSONPlaceholder", systemImage: "text.bubble")
                }
        }
        .withDebugTools()
    }
}

struct DebugToolsModifier: ViewModifier {
    @StateObject private var viewModel = DebugToolsViewModel()
    
    func body(content: Content) -> some View {
        content
            .overlay(
                OverlayButtonsView(viewModel: viewModel)
            )
            .background(
                SheetManager(viewModel: viewModel)
            )
    }
}

extension View {
    func withDebugTools() -> some View {
        self.modifier(DebugToolsModifier())
    }
}

class DebugToolsViewModel: ObservableObject {
    @Published var showLogs = false
    @Published var showAnalyticsLogs = false
    @Published var showUserdefaultsEditor = false
    @Published var showCrashReporting = false
    
    init() {
        _ = CrashReporter.shared
    }
    
    func toggleLogs() {
        showLogs.toggle()
    }
    
    func toggleAnalyticsLogs() {
        showAnalyticsLogs.toggle()
    }
    
    func toggleUserDefaultsEditor() {
        showUserdefaultsEditor.toggle()
    }
    
    func toggleCrashReporting() {
        showCrashReporting.toggle()
    }
}

struct OverlayButtonsView: View {
    @ObservedObject var viewModel: DebugToolsViewModel

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Button(action: {
                        viewModel.toggleLogs()
                    }) {
                        Image(systemName: "ladybug")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    Button(action: {
                        withAnimation {
                            viewModel.toggleAnalyticsLogs()
                        }
                    }) {
                        Image(systemName: "chart.bar")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    Button(action: {
                        withAnimation {
                            viewModel.toggleUserDefaultsEditor()
                        }
                    }) {
                        Image(systemName: "gear")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    // doesn't work
//                    Button(action: {
//                        withAnimation {
//                            viewModel.toggleCrashReporting()
//                        }
//                    }) {
//                        Image(systemName: "exclamationmark.triangle")
//                            .padding()
//                            .background(Color.red)
//                            .foregroundColor(.white)
//                            .clipShape(Circle())
//                            .shadow(radius: 10)
//                    }
                }
            }
        }
        .padding()
    }
}

struct SheetManager: View {
    @ObservedObject var viewModel: DebugToolsViewModel

    var body: some View {
        EmptyView() // SheetManager doesn't render anything directly
            .sheet(isPresented: $viewModel.showLogs) {
                NavigationView {
                    NetworkLogScreen()
                        .navigationBarTitle("Network Logs", displayMode: .inline)
                        .navigationBarItems(leading: Button("Close") {
                            viewModel.showLogs = false
                        })
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $viewModel.showAnalyticsLogs) {
                AnalyticsLogScreen()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $viewModel.showUserdefaultsEditor) {
                UserDefaultsEditorView()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $viewModel.showCrashReporting) {
                CrashReportingView()
                    .presentationDetents([.medium, .large])
            }
    }
}
