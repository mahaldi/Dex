//
//  ContentView.swift
//  Dex
//
//  Created by ceboi on 15/01/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Pokemon.id, animation: .default) private var Pokedex: [Pokemon]

    
    @State private var searchText = ""
    @State private var filterByFavorite: Bool = false
    
    let fetcher = FetchService()
    
    private var dynamicPredicate: Predicate<Pokemon> {
        #Predicate<Pokemon> { pokemon in
            if filterByFavorite && !searchText.isEmpty {
                pokemon.favorite && pokemon.name.localizedStandardContains(searchText)
            } else if !searchText.isEmpty {
                pokemon.name.localizedStandardContains(searchText)
            } else if filterByFavorite {
                pokemon.favorite
            } else {
                true
            }
            
        }
    }

    var body: some View {
        if Pokedex.isEmpty {
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
                        ForEach((try? Pokedex.filter(dynamicPredicate)) ?? Pokedex) { pokemon in
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
                                        Text(pokemon.name.capitalized) // make "!" karena untuk nge force udh pasti ada name nya, dan aneh nya klo ga make "!" ga muncul error tapi preview nya ga jalan dan stuck
                                            .fontWeight(.bold)
                                        if pokemon.favorite {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    HStack {
                                        ForEach(pokemon.types, id: \.self) { type in
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
                                        try modelContext.save()
                                    } catch {
                                        print(error)
                                    }
                                }
                                .tint(pokemon.favorite ? .gray : .yellow)
                            }
                        }
                    } footer: {
                        if Pokedex.count < 151 {
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
                .animation(.default, value: searchText)
                .navigationDestination(for: Pokemon.self) { pokemon in // cara lain untuk munculin page dari navigation link
                    PokemonDetail(pokemon: pokemon)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            withAnimation {
                                filterByFavorite.toggle()
                            }
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
                    modelContext.insert(fetchedPokemon)
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
                for pokemon in Pokedex {
                    
                    pokemon.sprite = try await URLSession.shared.data(from: pokemon.spriteURL).0 // 0 ini adalah data nya, sedangkan jika 1 adalah responsenya, sama kaya let (data, response) = URLSession.shared.data
                    pokemon.shiny = try await URLSession.shared.data(from: pokemon.shinyURL).0
                    try modelContext.save()
                }
            } catch {
                print(error)
            }
        }
    }
}


#Preview {
    ContentView().modelContainer(PersistenceController.preview)
}
