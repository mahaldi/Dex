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

    @FetchRequest<Pokemon>(
        sortDescriptors: [SortDescriptor(\.id)],
        animation: .default)
    private var Pokedex // cara lainnya adalah private var Pokedex: FetchedResults<Pokemon> , lalu hapus <Pokemon> pada FetchRequest diatas, cara yang saat ini dipakai adalah shorthand nya, artinya adalah Pokedex akan menjadi wrapper value dari FetchRequest, jadi variable setelah FetchRequest akan otomatis menjadi wrapper value dari FetchRequest
    
    @State private var searchText = ""
    
    let fetcher = FetchService()
    
    private var dynamicPredicate: NSPredicate {
        var predicates: [NSPredicate] = []
        
        // search predicate
        if !searchText.isEmpty {
            // name ini adalah property dari data,[c] maksudnya adalah insensitife case, lalu %@ adalah binding yang make @
            predicates.append(NSPredicate(format: "name contains[c] %@", searchText))
        }
        
        // filter by favorite predicate
        
        // combine predicates
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Pokedex) { pokemon in
                    NavigationLink(value: pokemon) {
                        AsyncImage(url: pokemon.sprite) { img in
                            img.resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 100, height: 100)
                        
                        VStack(alignment: .leading) {
                            Text(pokemon.name!.capitalized) // make "!" karena untuk nge force udh pasti ada name nya, dan aneh nya klo ga make "!" ga muncul error tapi preview nya ga jalan dan stuck
                                .fontWeight(.bold)
                            HStack {
                                ForEach(pokemon.types!, id: \.self) { type in
                                    Text(type.capitalized)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 13)
                                        .padding(.vertical, 5)
                                        .background(Color(type.capitalized))
                                        .clipShape(.capsule)
                                    
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Pokedex")
            .searchable(text: $searchText, prompt: "Find a pokemon")
            .autocorrectionDisabled()
            .onChange(of: searchText) {
                Pokedex.nsPredicate = dynamicPredicate
            }
            .navigationDestination(for: Pokemon.self) { pokemon in // cara lain untuk munculin page dari navigation link
                Text(pokemon.name ?? "NA")
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
