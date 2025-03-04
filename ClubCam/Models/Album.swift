//
//  Album.swift
//  ClubCam
//
//  Created on 3/4/25.
//

import Foundation
import UIKit

struct Album: Identifiable {
    let id: UUID
    var name: String
    var photos: [Photo]
    var coverImage: UIImage? {
        return photos.first?.image
    }
    var creationDate: Date = Date()
    
    var photoCount: Int {
        return photos.count
    }
} 