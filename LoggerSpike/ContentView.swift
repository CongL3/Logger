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

struct PokemonScreen: View {
    @State private var pokemon: Pokemon?
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var searchText: String = "pikachu"

    private let pokemonService = PokemonService()

    var body: some View {
        VStack {
            HStack {
                TextField("Enter Pokémon name", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button(action: {
                    fetchPokemonData()
                    AnalyticsService.logEvent("Search button pressed")
                }) {
                    Text("Search")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isLoading)
            }

            if isLoading {
                ProgressView("Loading...")
                    .padding()
            } else if let pokemon = pokemon {
                VStack(alignment: .leading, spacing: 16) {
                    if let imageUrl = URL(string: pokemon.sprites.frontDefault) {
                        AsyncImage(url: imageUrl) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 150, height: 150)
                        } placeholder: {
                            ProgressView()
                        }
                    }

                    Text("Name: \(pokemon.name.capitalized)")
                        .font(.headline)
                    Text("ID: \(pokemon.id)")
                    Text("Height: \(pokemon.height)")
                    Text("Weight: \(pokemon.weight)")
                    
                    Text("Types:")
                    ForEach(pokemon.types, id: \.slot) { typeInfo in
                        Text(typeInfo.type.name.capitalized)
                    }
                    
                    Text("Abilities:")
                    ForEach(pokemon.abilities, id: \.slot) { abilityInfo in
                        Text(abilityInfo.ability.name.capitalized)
                    }
                }
                .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }

    private func fetchPokemonData() {
        isLoading = true
        pokemonService.fetchPokemonData(for: searchText.lowercased()) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let pokemon):
                    self.pokemon = pokemon
                    self.errorMessage = nil
                case .failure(let error):
                    self.pokemon = nil
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }
        }
    }
}

struct JsonPlaceholderScreen: View {
    @State private var responseData: Data?
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var httpMethod: HttpMethod = .post
    @State private var requestBodyType: RequestBodyType = .defaultBody
    @State private var contentType: ContentType = .json
    @State private var authorizationType: AuthorizationType = .bearer

    private let jsonPlaceholderService = JsonPlaceholderService()

    var body: some View {
        VStack(spacing: 20) {
            Picker("HTTP Method", selection: $httpMethod) {
                ForEach(HttpMethod.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Picker("Body Type", selection: $requestBodyType) {
                ForEach(RequestBodyType.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .disabled(httpMethod == .get)

            Picker("Content-Type", selection: $contentType) {
                ForEach(ContentType.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Picker("Authorization", selection: $authorizationType) {
                ForEach(AuthorizationType.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Button(action: {
                sendRequest()
            }) {
                Text("Send \(httpMethod.rawValue) Request")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isLoading)

            if isLoading {
                ProgressView("Loading...")
                    .padding()
            } else if let data = responseData {
                Text("Response Data: \(String(data: data, encoding: .utf8) ?? "No Data")")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }

    private func sendRequest() {
        isLoading = true
        jsonPlaceholderService.sendRequest(httpMethod: httpMethod, requestBodyType: requestBodyType, contentType: contentType, authorizationType: authorizationType) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.responseData = data
                    self.errorMessage = nil
                case .failure(let error):
                    self.responseData = nil
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }
        }
    }
}


enum HttpMethod: String, CaseIterable {
    case get = "GET"
    case post = "POST"
}

enum RequestBodyType: String, CaseIterable {
    case defaultBody = "Default Body"
    case customBody = "Custom Body"
}

enum ContentType: String, CaseIterable {
    case json = "application/json"
    case xml = "application/xml"
}

enum AuthorizationType: String, CaseIterable {
    case bearer = "Bearer Token"
    case basic = "Basic Auth"
}

// MARK: - Pokémon Models
struct Pokemon: Codable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let types: [PokemonTypeInfo]
    let abilities: [PokemonAbilityInfo]
    let sprites: PokemonSprites
}

struct PokemonSprites: Codable {
    let frontDefault: String

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

struct PokemonTypeInfo: Codable {
    let slot: Int
    let type: NamedAPIResource
}

struct PokemonAbilityInfo: Codable {
    let slot: Int
    let ability: NamedAPIResource
}

struct NamedAPIResource: Codable {
    let name: String
    let url: String
}

// MARK: - Pokémon Service
class PokemonService {
    private let session: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [NetworkLoggingProtocol.self] + (configuration.protocolClasses ?? [])
        self.session = URLSession(configuration: configuration)
    }
    
    func fetchPokemonData(for name: String, completion: @escaping (Result<Pokemon, Error>) -> Void) {
        let urlString = "https://pokeapi.co/api/v2/pokemon/\(name)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }
        
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: 404, userInfo: nil)))
                return
            }
            
            do {
                let pokemon = try JSONDecoder().decode(Pokemon.self, from: data)
                completion(.success(pokemon))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

class JsonPlaceholderService {
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [NetworkLoggingProtocol.self] + (configuration.protocolClasses ?? [])
        self.session = URLSession(configuration: configuration)
    }

    func sendRequest(httpMethod: HttpMethod, requestBodyType: RequestBodyType, contentType: ContentType, authorizationType: AuthorizationType, completion: @escaping (Result<Data, Error>) -> Void) {
        let urlString = "https://jsonplaceholder.typicode.com/posts"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.addValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        
        switch authorizationType {
        case .bearer:
            request.addValue("Bearer abcdef123456", forHTTPHeaderField: "Authorization")
        case .basic:
            let credentials = "username:password".data(using: .utf8)?.base64EncodedString() ?? ""
            request.addValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        }

        if httpMethod == .post {
            let body: [String: Any] = requestBodyType == .defaultBody ? [
                "title": "foo",
                "body": "bar",
                "userId": 1
            ] : [
                "title": "Custom Title",
                "body": "Custom Body",
                "userId": 2
            ]
            
            let jsonData = try? JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
        }

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: 404, userInfo: nil)))
                return
            }

            completion(.success(data))
        }
        task.resume()
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
