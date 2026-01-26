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
    
    @FetchRequest<Pokemon>(sortDescriptors: []) private var allPokemons

    @FetchRequest<Pokemon>(
        sortDescriptors: [SortDescriptor(\.id)],
        animation: .default)
    private var Pokedex // cara lainnya adalah private var Pokedex: FetchedResults<Pokemon> , lalu hapus <Pokemon> pada FetchRequest diatas, cara yang saat ini dipakai adalah shorthand nya, artinya adalah Pokedex akan menjadi wrapper value dari FetchRequest, jadi variable setelah FetchRequest akan otomatis menjadi wrapper value dari FetchRequest
    
    @State private var searchText = ""
    @State private var filterByFavorite: Bool = false
    
    let fetcher = FetchService()
    
    private var dynamicPredicate: NSPredicate {
        var predicates: [NSPredicate] = []
        
        // search predicate
        if !searchText.isEmpty {
            // name ini adalah property dari data,[c] maksudnya adalah insensitife case, lalu %@ adalah binding yang make @
            predicates.append(NSPredicate(format: "name contains[c] %@", searchText))
        }
        
        // filter by favorite predicate
        if filterByFavorite {
            predicates.append(NSPredicate(format: "favorite == %d", true))
        }
        
        // combine predicates
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    var body: some View {
        if allPokemons.isEmpty {
            ContentUnavailableView {
                Label("No Pokemon", image: .nopokemon)
            } description: {
                Text("There are no Pokemon in your Pokedex yet. Go catch 'em!")
            } actions: {
                Button("Fetch Pokemon", systemImage: "antenna.radiowaves.left.and.right") {
                    getPokemon(from: 1)
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            NavigationStack {
                List {
                    Section {
                        ForEach(Pokedex) { pokemon in
                            NavigationLink(value: pokemon) {
                                if pokemon.sprite == nil {
                                    AsyncImage(url: pokemon.spriteURL) { img in
                                        img.resizable()
                                            .scaledToFit()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 100, height: 100)
                                } else {
                                    // ini dari computed property di PokemonExt
                                    pokemon.spriteImage
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                }
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(pokemon.name!.capitalized) // make "!" karena untuk nge force udh pasti ada name nya, dan aneh nya klo ga make "!" ga muncul error tapi preview nya ga jalan dan stuck
                                            .fontWeight(.bold)
                                        if pokemon.favorite {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                        }
                                    }
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
                            .swipeActions(edge: .leading) {
                                Button(pokemon.favorite ? "Remove from Favorites" : "Add to Favorite", systemImage: "star") {
                                    pokemon.favorite.toggle()
                                    
                                    do {
                                        try viewContext.save()
                                    } catch {
                                        print(error)
                                    }
                                }
                                .tint(pokemon.favorite ? .gray : .yellow)
                            }
                        }
                    } footer: {
                        if allPokemons.count < 151 {
                            ContentUnavailableView {
                                Label("Missing Pokemons", image: .nopokemon)
                            } description: {
                                Text("The Fetch was interrupted! \n Fetch the rest of Pokemon")
                            } actions: {
                                Button("Fetch Pokemon", systemImage: "antenna.radiowaves.left.and.right") {
                                    getPokemon(from: Pokedex.count + 1)
                                }
                                .buttonStyle(.borderedProminent)
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
                .onChange(of: filterByFavorite) {
                    Pokedex.nsPredicate = dynamicPredicate
                }
                .navigationDestination(for: Pokemon.self) { pokemon in // cara lain untuk munculin page dari navigation link
                    PokemonDetail().environmentObject(pokemon)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            filterByFavorite.toggle()
                        } label: {
                            Label("Filter by Favorite", systemImage: filterByFavorite ? "star.fill" : "star")
                        }
                        .tint(.yellow)
                    }
                }
            }
        }
    }
    
    private func getPokemon(from id: Int) {
        Task {
            for idPokemon in id..<152 {
                do {
                    let fetchedPokemon = try await fetcher.fetchPokemon(idPokemon)
                    
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
                    pokemon.spriteURL = fetchedPokemon.spriteURL
                    pokemon.shinyURL = fetchedPokemon.shinyURL
                    
                    try viewContext.save()
                } catch {
                    print(error)
                }
            }
            storeSprites()
        }
    }
    
    private func storeSprites() { // simpan binary data ke core data
        Task {
            do {
                for pokemon in allPokemons {
                    
                    pokemon.sprite = try await URLSession.shared.data(from: pokemon.spriteURL!).0 // 0 ini adalah data nya, sedangkan jika 1 adalah responsenya, sama kaya let (data, response) = URLSession.shared.data
                    pokemon.shiny = try await URLSession.shared.data(from: pokemon.shinyURL!).0
                    try viewContext.save()
                }
            } catch {
                print(error)
            }
        }
    }
}


#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
