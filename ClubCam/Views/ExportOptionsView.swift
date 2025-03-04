//
//  ExportOptionsView.swift
//  ClubCam
//
//  Created on 3/4/25.
//

import SwiftUI

struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    let album: Album
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Export Options")) {
                    Button(action: {
                        exportAsZip()
                    }) {
                        Label("Export as ZIP", systemImage: "doc.zipper")
                    }
                    
                    Button(action: {
                        exportToPhotos()
                    }) {
                        Label("Save to Photos", systemImage: "photo.on.rectangle")
                    }
                    
                    Button(action: {
                        shareAlbum()
                    }) {
                        Label("Share Album", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Export Album")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportAsZip() {
        // Implement ZIP export functionality
        print("Exporting as ZIP")
        dismiss()
    }
    
    private func exportToPhotos() {
        // Implement export to Photos app
        print("Saving to Photos")
        dismiss()
    }
    
    private func shareAlbum() {
        // Implement sharing functionality
        print("Sharing album")
        dismiss()
    }
}

struct ExportOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        ExportOptionsView(album: Album(id: UUID(), name: "Test Album", photos: []))
    }
} 