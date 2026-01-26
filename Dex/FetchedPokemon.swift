//
//  FetchedPokemon.swift
//  Dex
//
//  Created by ceboi on 15/01/26.
//

import Foundation

struct FetchedPokemon: Decodable {
    let id: Int16
    let name: String
    let types: [String]
    let hp: Int16
    let attack: Int16
    let defense: Int16
    let specialAttack: Int16
    let specialDefense: Int16
    let speed: Int16
    let spriteURL: URL
    let shinyURL: URL
    
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
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int16.self, forKey: .id)
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
        
        var decodedStats: [Int16] = []
        var statsContainer = try container.nestedUnkeyedContainer(forKey: .stats)
        while !statsContainer.isAtEnd {
            let statsDictionaryContainer = try statsContainer.nestedContainer(keyedBy: CodingKeys.StatDictionaryKeys.self)
            let baseStatContainer = try statsDictionaryContainer.decode(Int16.self, forKey: .baseStat)
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
}
