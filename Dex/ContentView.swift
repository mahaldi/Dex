//
//  ContentView.swift
//  Dex
//
//  Created by ceboi on 15/01/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Pokemon.id, ascending: true)],
        animation: .default)
    private var Pokedex: FetchedResults<Pokemon>
    
    let fetcher = FetchService()

    var body: some View {
        NavigationView {
            List {
                ForEach(Pokedex) { pokemon in
                    NavigationLink {
                        Text(pokemon.name ?? "NA")
                    } label: {
                        Text(pokemon.name ?? "NA")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button("Add Item", systemImage: "plus") {
                        getPokemon()
                    }
                }
            }
            Text("Select an item")
        }
    }
    
    private func getPokemon() {
        Task {
            for id in 1..<152 {
                do {
                    let fetchedPokemon = try await fetcher.fetchPokemon(id)
                    
                    let pokemon = Pokemon(context: viewContext)
                    pokemon.id = fetchedPokemon.id
                    pokemon.name = fetchedPokemon.name
                    pokemon.types = fetchedPokemon.types
                    pokemon.hp = fetchedPokemon.hp
                    pokemon.attack = fetchedPokemon.attack
                    pokemon.speed = fetchedPokemon.speed
                    pokemon.specialAttack = fetchedPokemon.specialAttack
                    pokemon.specialDefense = fetchedPokemon.specialDefense
                    pokemon.defense = fetchedPokemon.defense
                    pokemon.sprite = fetchedPokemon.sprite
                    pokemon.shiny = fetchedPokemon.shiny
                    
                    try viewContext.save()
                } catch {
                    print(error)
                }
            }
        }
    }
}


#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
