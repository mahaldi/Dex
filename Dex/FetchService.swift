//
//  FetchService.swift
//  Dex
//
//  Created by ceboi on 16/01/26.
//

import Foundation

struct FetchService {
    enum FetchError: Error {
        case badResponse
    }
    
    private let basedURL = URL(string: "https://pokeapi.co/api/v2/pokemon")!
    
    func fetchPokemon(_ id: Int) async throws -> FetchedPokemon {
        let fetchURL = basedURL.appending(path: String(id))
        
        let (data, response) = try await URLSession.shared.data(from: fetchURL)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw FetchError.badResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let pokemon = try decoder.decode(FetchedPokemon.self, from: data)
        print("fetched pokemon id \(pokemon.id): \(pokemon.name)")
        return pokemon
    }
    
    
}
