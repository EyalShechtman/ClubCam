import SwiftUI
import CoreLocation

struct DebugMenuView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = DebugViewModel()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Test Data")) {
                    Button("Generate 5 Test Events") {
                        Task {
                            await viewModel.generateTestEvents()
                            showingAlert = true
                            alertMessage = "Test events created successfully!"
                        }
                    }
                    
                    Button("Clear All Test Events") {
                        Task {
                            await viewModel.clearTestEvents()
                            showingAlert = true
                            alertMessage = "Test events cleared!"
                        }
                    }
                }
                
                Section(header: Text("Account")) {
                    Button("Reset Account") {
                        Task {
                            await viewModel.resetUserData()
                            showingAlert = true
                            alertMessage = "User data reset!"
                        }
                    }
                }
                
                Section(header: Text("App State")) {
                    Button("Clear Cache") {
                        viewModel.clearCache()
                        showingAlert = true
                        alertMessage = "Cache cleared!"
                    }
                }
            }
            .navigationTitle("Debug Menu")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Debug Action"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

class DebugViewModel: ObservableObject {
    private let supabaseService = SupabaseService.shared
    
    func generateTestEvents() async {
        await TestDataGenerator.shared.generateTestEvents()
    }
    
    func clearTestEvents() async {
        // Implementation to delete test events
    }
    
    func resetUserData() async {
        // Implementation to reset user data
    }
    
    func clearCache() {
        // Implementation to clear app cache
    }
} 