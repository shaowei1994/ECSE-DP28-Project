//
//  Language.swift
//  iKnow
//
//  Created by Shao-Wei Liang on 2018-03-24.
//  Copyright © 2018 Shao-Wei Liang. All rights reserved.
//

import Foundation

class Language: NSObject, NSCoding{
    var symbol: String
    var name: String
    
    init(symbol: String, name: String){
        self.symbol = symbol
        self.name = name
    }
    
    // MARK: NSCoding
    required convenience init?(coder decoder: NSCoder) {
        guard let symbol = decoder.decodeObject(forKey: "symbol") as? String,
            let name = decoder.decodeObject(forKey: "name") as? String
            else { return nil }
        
        self.init(
            symbol: symbol,
            name: name
        )
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.symbol, forKey: "symbol")
        aCoder.encode(self.name, forKey: "name")
    }
}
