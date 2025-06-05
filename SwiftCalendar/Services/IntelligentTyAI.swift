//
//  IntelligentTyAI.swift
//  SwiftCalendar
//
//  Main coordinator for Ty AI - orchestrates all AI services
//

import Foundation

class IntelligentTyAI {
    
    // MARK: - Services
    
    private let claudeService = ClaudeAPIService()
    private let responseParser = ResponseParser()
    private let conversationManager = ConversationManager()
    private let scheduleOptimizer = ScheduleOptimizerService()
    
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
                task: result.content as! FlexibleTask,
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
        task: FlexibleTask,
        message: String,
        existingEvents: [ScheduleEvent],
        userPreferences: UserSchedulePreferences
    ) async -> TyResponse {
        
        print("🎯 Handling optimization for: \(task.title)")
        
        // Generate intelligent suggestions using the schedule optimizer
        let suggestions = scheduleOptimizer.generateOptimalSuggestions(
            for: task,
            existingEvents: existingEvents,
            userPreferences: userPreferences
        )
        
        if suggestions.isEmpty {
            let fallbackMessage = "I couldn't find any good times for \(task.title) that work with your current schedule. Would you like me to look at a different time period or adjust the duration?"
            return .conversational(fallbackMessage)
        }
        
        // Enhance message with specific suggestions
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
