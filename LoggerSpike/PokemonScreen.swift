//
//  PokemonScreen.swift
//  LoggerSpike
//
//  Created by Cong Le on 29/08/2024.
//

import Foundation
import SwiftUI

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

