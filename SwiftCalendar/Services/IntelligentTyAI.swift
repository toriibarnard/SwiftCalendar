//
//  IntelligentTyAI.swift
//  SwiftCalendar
//
//  UPDATED: Main coordinator for Ty AI - prioritizes Claude's suggestions
//

import Foundation

class IntelligentTyAI {
    
    // MARK: - Services - REMOVED ScheduleOptimizer
    
    private let claudeService = ClaudeAPIService()
    private let responseParser = ResponseParser()
    private let conversationManager = ConversationManager()
    
    // MARK: - Public API
    
    func processRequest(
        _ message: String,
        existingEvents: [ScheduleEvent],
        userPreferences: UserSchedulePreferences
    ) async throws -> TyResponse {
        
        print("🧠 Processing request: \(message)")
        print("📊 Context: \(existingEvents.count) existing events")
        
        // Build system prompt with full schedule context
        let systemPrompt = conversationManager.buildSystemPrompt(
            with: existingEvents,
            userPreferences: userPreferences
        )
        
        // Send to Claude with context
        let claudeResponse = try await claudeService.sendMessage(
            message,
            systemPrompt: systemPrompt
        )
        
        // Parse Claude's response
        let parseResult = responseParser.parseResponse(claudeResponse.content)
        
        // Handle different response types
        return try await handleParseResult(
            parseResult,
            existingEvents: existingEvents,
            userPreferences: userPreferences
        )
    }
    
    func clearConversationHistory() {
        claudeService.clearConversationHistory()
    }
    
    // MARK: - Response Handling
    
    private func handleParseResult(
        _ result: ParseResult,
        existingEvents: [ScheduleEvent],
        userPreferences: UserSchedulePreferences
    ) async throws -> TyResponse {
        
        switch result.responseType {
        case .optimization:
            return await handleOptimizationRequest(
                content: result.content,
                message: result.message ?? "Here are the optimal times I found:",
                existingEvents: existingEvents,
                userPreferences: userPreferences
            )
            
        case .automation:
            return handleAutomationRequest(
                action: result.content as! CalendarAction,
                message: result.message ?? "Events have been added to your calendar."
            )
            
        case .removal:
            return handleRemovalRequest(
                action: result.content as! CalendarAction,
                message: result.message ?? "Events have been removed from your calendar."
            )
            
        case .conversation:
            return .conversational(result.content as! String)
        }
    }
    
    private func handleOptimizationRequest(
        content: Any,
        message: String,
        existingEvents: [ScheduleEvent],
        userPreferences: UserSchedulePreferences
    ) async -> TyResponse {
        
        // NO FALLBACKS - Only handle Claude's suggestions
        if let (task, suggestions) = content as? (task: FlexibleTask, suggestions: [TimeSlotSuggestion]) {
            
            if suggestions.isEmpty {
                print("❌ CRITICAL ERROR: Claude provided no suggestions")
                return .conversational("Critical error: Failed to extract time suggestions from Claude's response. The pattern matching failed.")
            }
            
            print("🤖 Using Claude's \(suggestions.count) suggestions directly")
            
            let enhancedMessage = buildOptimizationMessage(
                task: task,
                suggestions: suggestions,
                originalMessage: message
            )
            
            return .scheduleOptimization(
                task: task,
                suggestions: suggestions,
                message: enhancedMessage
            )
        } else {
            print("❌ CRITICAL ERROR: Unexpected optimization content type")
            return .conversational("Critical error: Unexpected content type in optimization response.")
        }
    }
    
    private func handleAutomationRequest(
        action: CalendarAction,
        message: String
    ) -> TyResponse {
        
        print("📅 Handling calendar automation")
        return .calendarAutomation(action: action, message: message)
    }
    
    private func handleRemovalRequest(
        action: CalendarAction,
        message: String
    ) -> TyResponse {
        
        print("🗑️ Handling removal request")
        return .calendarAutomation(action: action, message: message)
    }
    
    // MARK: - Message Enhancement
    
    private func buildOptimizationMessage(
        task: FlexibleTask,
        suggestions: [TimeSlotSuggestion],
        originalMessage: String
    ) -> String {
        
        let count = suggestions.count
        let taskName = task.title
        
        var message = "I found \(count) optimal time\(count == 1 ? "" : "s") for **\(taskName)** that fit perfectly with your schedule:\n\n"
        
        for (index, suggestion) in suggestions.enumerated() {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE h:mm a"
            let startTime = formatter.string(from: suggestion.startTime)
            
            formatter.dateFormat = "h:mm a"
            let endTime = formatter.string(from: suggestion.endTime)
            
            message += "**\(index + 1). \(startTime) - \(endTime)**\n"
            message += "• Score: \(String(format: "%.0f", suggestion.score * 100))% optimal\n"
            
            if let reasoning = suggestion.reasoning, !reasoning.isEmpty {
                message += "• \(reasoning)\n\n"
            } else {
                message += "• Perfect timing for \(task.category.rawValue) activities\n\n"
            }
        }
        
        message += "Tap any option to add it to your calendar! 📅"
        return message
    }
}
