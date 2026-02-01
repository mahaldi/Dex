//
//  Pokemon.swift
//  Dex
//
//  Created by ceboi on 01/02/26.
//
//

import Foundation
import SwiftData
import SwiftUI


@Model class Pokemon: Decodable {
    @Attribute(.unique) var attack: Int
    var defense: Int
    var favorite: Bool = false
    var hp: Int
    var id: Int
    var name: String
    var shiny: Data?
    var shinyURL: URL
    var specialAttack: Int
    var specialDefense: Int
    var speed: Int
    var sprite: Data?
    var spriteURL: URL
    var types: [String]
        
    enum CodingKeys: CodingKey {
        case id
        case name
        case types
        case stats
        case sprites
        
        enum TypeDictionaryKeys: CodingKey { // types: [ { type: { name, url }, slot } ]
            case type // karena di dalem array types ada object property type
            
            enum typeKeys: CodingKey {
                case name // karena didalam object type ada property name
            }
        }
        
        enum StatDictionaryKeys: CodingKey {
            case baseStat
        }
        
        enum SpriteKeys: String, CodingKey {
            case spriteURL = "frontDefault" // karena di json datanya front_default, dan disini pengennya mapping nya dengan key sprite, kalau yang lain nya ga ada raw value nya karena make key yang sama dengan case nya. misal case name ga ada raw value nya karena di json nya juga cuma name doang
            case shinyURL = "frontShiny"
        }
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        var decodedTypes: [String] = []
        var typesContainer = try container.nestedUnkeyedContainer(forKey: .types) // ini di array types
        while !typesContainer.isAtEnd { // looping array types
            let typesDictionaryContainer = try typesContainer.nestedContainer(keyedBy: CodingKeys.TypeDictionaryKeys.self) // ini baru masuk kedalam object didalam array, belom di type nya
            let typeContainer = try typesDictionaryContainer.nestedContainer(keyedBy: CodingKeys.TypeDictionaryKeys.typeKeys.self, forKey: .type) // ini pas di object type
            
            let type = try typeContainer.decode(String.self, forKey: .name)
            decodedTypes.append(type)
        }
        
        if decodedTypes.count == 2 && decodedTypes[0] == "normal" {
            let tempType = decodedTypes[0]
            decodedTypes[0] = decodedTypes[1]
            decodedTypes[1] = tempType
            
            // cara shorthand nya
            // decodedTypes.swapAt(0, 1)
        }
        
        self.types = decodedTypes
        
        var decodedStats: [Int] = []
        var statsContainer = try container.nestedUnkeyedContainer(forKey: .stats)
        while !statsContainer.isAtEnd {
            let statsDictionaryContainer = try statsContainer.nestedContainer(keyedBy: CodingKeys.StatDictionaryKeys.self)
            let baseStatContainer = try statsDictionaryContainer.decode(Int.self, forKey: .baseStat)
            decodedStats.append(baseStatContainer)
        }
        
        
        self.hp = decodedStats[0]
        self.attack = decodedStats[1]
        self.defense = decodedStats[2]
        self.specialAttack = decodedStats[3]
        self.specialDefense = decodedStats[4]
        self.speed = decodedStats[5]
        
        let spriteContainer = try container.nestedContainer(keyedBy: CodingKeys.SpriteKeys.self, forKey: .sprites)
        self.spriteURL = try spriteContainer.decode(URL.self, forKey: .spriteURL)
        self.shinyURL = try spriteContainer.decode(URL.self, forKey: .shinyURL)
    }
    var spriteImage: Image {
        // klo ada value sprite maka value nya masuk ke variable data, lalu gunakan data tersebut utk di convert ke Image masukkan ke variable image
        if let data = sprite, let image = UIImage(data: data) {
            Image(uiImage: image)
        } else {
            Image(.bulbasaur)
        }
    }
    
    var shinyImage: Image {
        if let data = shiny, let image = UIImage(data: data) {
            Image(uiImage: image)
        } else {
            Image(.shinybulbasaur)
        }
    }
    var background: ImageResource {
        switch types[0] {
        case "rock", "ground", "steel", "fighting", "ghost", "psyhic":
                .rockgroundsteelfightingghostdarkpsychic
        case "fire", "dragon":
                .firedragon
        case "flying", "bug":
                .flyingbug
        case "ice":
                .ice
        case "water":
                .water
        default:
                .normalgrasselectricpoisonfairy
                
        }
    }
    
    var typeColor: Color {
        Color(types[0].capitalized)
    }
    
    var stats: [Stat] {
        [
            Stat(id: 1, name: "HP", value: hp),
            Stat(id: 2, name: "Attack", value: attack),
            Stat(id: 3, name: "Defense", value: defense),
            Stat(id: 4, name: "Sp. Attack", value: specialAttack),
            Stat(id: 5, name: "Sp. Defense", value: specialDefense),
            Stat(id: 6, name: "Speed", value: speed),
        ]
    }
    
    var highestStat: Stat {
        stats.max { stat1, stat2 in
            stat1.value < stat2.value
        }!
        // bisa juga jadi gini shorthand nya stats.max { &0.value < &1.value }!
    }
    
    struct Stat: Identifiable {
        let id: Int
        let name: String
        let value: Int
    }

}
