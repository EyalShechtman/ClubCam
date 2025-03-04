//
//  PhotoDetailView.swift
//  ClubCam
//
//  Created on 3/4/25.
//

import SwiftUI

struct PhotoDetailView: View {
    let photo: Photo
    
    var body: some View {
        VStack {
            Image(uiImage: photo.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
            
            Text("Taken: \(photo.dateTaken.formatted())")
                .font(.caption)
                .padding(.bottom)
            
            Spacer()
        }
        .navigationTitle("Photo Details")
    }
}

struct PhotoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoDetailView(photo: Photo(id: UUID(), image: UIImage(), dateTaken: Date()))
    }
} 