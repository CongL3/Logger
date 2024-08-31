//
//  PokemonService.swift
//  LoggerSpike
//
//  Created by Cong Le on 29/08/2024.
//

import Foundation

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
