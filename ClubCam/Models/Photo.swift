//
//  Photo.swift
//  ClubCam
//
//  Created on 3/4/25.
//

import Foundation
import UIKit
import CoreLocation

struct Photo: Identifiable {
    let id: UUID
    let image: UIImage
    let dateTaken: Date
    var takenBy: String?
    
    // Optional additional properties
    var location: CLLocation?
    var metadata: [String: Any]?
} 