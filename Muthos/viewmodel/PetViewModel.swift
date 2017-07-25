//
//  PetViewModel.swift
//  Muthos
//
//  Created by shining on 2016. 9. 3..
//
//

import Foundation

class PetViewModel {
    static let sharedInstance = PetViewModel()
    
    var pets:[Pet] = []
    
    init() {
        pets.append(Pet(name:"pig",     dc:(4 / 100), retry:0, coin:0))
        pets.append(Pet(name:"frog",	dc:(0 / 100), retry:2, coin:0))
        pets.append(Pet(name:"rabbit",	dc:(0 / 100), retry:0, coin:4))
        pets.append(Pet(name:"racoon",	dc:(6 / 100), retry:0, coin:0))
        pets.append(Pet(name:"coala",	dc:(0 / 100), retry:3, coin:0))
        pets.append(Pet(name:"panda",	dc:(0 / 100), retry:0, coin:6))
        pets.append(Pet(name:"gorilla",	dc:(8 / 100), retry:0, coin:0))
        pets.append(Pet(name:"bear",	dc:(0 / 100), retry:4, coin:0))
        pets.append(Pet(name:"lion",	dc:(2 / 100), retry:1, coin:8))
    }
    
    func findPetWithName(_ name:String) -> Pet? {
        for p:Pet in pets {
            if p.name == name {
                return p
            }
        }
        return nil
    }
}
