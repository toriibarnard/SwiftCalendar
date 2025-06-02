//
//  MigrationHelper.swift
//  SwiftCalendar
//
//  Helper to clean up old user data structure
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class MigrationHelper {
    private let db = Firestore.firestore()
    
    /// Call this once to remove workingHours from all user documents
    func removeWorkingHoursFromUsers() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        do {
            // Update current user's document
            try await db.collection("users").document(currentUser.uid).updateData([
                "preferences.workingHours": FieldValue.delete()
            ])
            
            print("✅ Successfully removed workingHours from user preferences")
            
        } catch {
            print("❌ Error removing workingHours: \(error)")
        }
    }
    
    /// Call this to ensure user preferences have the correct structure
    func ensureUserPreferencesStructure() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let userRef = db.collection("users").document(currentUser.uid)
        
        do {
            let document = try await userRef.getDocument()
            
            if document.exists {
                // Update only the preferences structure, keeping other fields
                try await userRef.updateData([
                    "preferences.timeZone": TimeZone.current.identifier,
                    "preferences.notificationsEnabled": true,
                    "preferences.workingHours": FieldValue.delete() // Remove if exists
                ])
            }
            
            print("✅ User preferences structure updated")
            
        } catch {
            print("❌ Error updating user preferences: \(error)")
        }
    }
}

// MARK: - Usage
// Add this to your AppDelegate or call it once after login:
//
// Task {
//     let migration = MigrationHelper()
//     await migration.removeWorkingHoursFromUsers()
//     await migration.ensureUserPreferencesStructure()
// }
