//
//  Item.swift
//  QuadrantTasks
//
//  Created by 徐敏儿 on 31/05/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
