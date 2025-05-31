//
//  OpenAIService.swift
//  SwiftCalendar
//
//  AI service for handling OpenAI API calls
//

import Foundation

class OpenAIService {
    static let shared = OpenAIService()
    
    private let apiKey: String
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    
    private init() {
        // Load API key from Config.plist
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["OPENAI_API_KEY"] as? String,
              !key.isEmpty,
              key != "YOUR_API_KEY_HERE" else {
            fatalError("OpenAI API key not found. Please create Config.plist with your API key.")
        }
        self.apiKey = key
    }
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }
    
    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double
        let functions: [FunctionDefinition]?
        let function_call: String?
    }
    
    struct FunctionDefinition: Codable {
        let name: String
        let description: String
        let parameters: Parameters
        
        struct Parameters: Codable {
            let type: String
            let properties: [String: Property]
            let required: [String]
        }
        
        struct Property: Codable {
            let type: String
            let description: String
            let `enum`: [String]?
            let items: Items?
            
            struct Items: Codable {
                let type: String
                let properties: [String: Property]?
            }
        }
    }
    
    struct ChatResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: Message
            
            struct Message: Codable {
                let role: String
                let content: String?
                let function_call: FunctionCall?
                
                struct FunctionCall: Codable {
                    let name: String
                    let arguments: String
                }
            }
        }
    }
    
    // Function definitions for calendar operations
    private var calendarFunctions: [FunctionDefinition] {
        [
            FunctionDefinition(
                name: "add_event",
                description: "Add a new event to the calendar",
                parameters: FunctionDefinition.Parameters(
                    type: "object",
                    properties: [
                        "title": FunctionDefinition.Property(
                            type: "string",
                            description: "The title of the event",
                            enum: nil,
                            items: nil
                        ),
                        "start_date": FunctionDefinition.Property(
                            type: "string",
                            description: "Start date and time in ISO format",
                            enum: nil,
                            items: nil
                        ),
                        "end_date": FunctionDefinition.Property(
                            type: "string",
                            description: "End date and time in ISO format",
                            enum: nil,
                            items: nil
                        ),
                        "category": FunctionDefinition.Property(
                            type: "string",
                            description: "Category of the event",
                            enum: ["work", "fitness", "personal", "study", "health", "social", "other"],
                            items: nil
                        ),
                        "is_recurring": FunctionDefinition.Property(
                            type: "boolean",
                            description: "Whether this event should repeat",
                            enum: nil,
                            items: nil
                        ),
                        "recurrence_days": FunctionDefinition.Property(
                            type: "array",
                            description: "Days of the week for recurring events (0=Sunday, 6=Saturday)",
                            enum: nil,
                            items: FunctionDefinition.Property.Items(
                                type: "integer",
                                properties: nil
                            )
                        )
                    ],
                    required: ["title", "start_date", "end_date", "category"]
                )
            ),
            FunctionDefinition(
                name: "suggest_time",
                description: "Suggest optimal times for an activity",
                parameters: FunctionDefinition.Parameters(
                    type: "object",
                    properties: [
                        "activity": FunctionDefinition.Property(
                            type: "string",
                            description: "The activity to schedule",
                            enum: nil,
                            items: nil
                        ),
                        "duration_minutes": FunctionDefinition.Property(
                            type: "integer",
                            description: "Duration of the activity in minutes",
                            enum: nil,
                            items: nil
                        ),
                        "preferences": FunctionDefinition.Property(
                            type: "object",
                            description: "User preferences for scheduling",
                            enum: nil,
                            items: nil
                        )
                    ],
                    required: ["activity", "duration_minutes"]
                )
            ),
            FunctionDefinition(
                name: "get_schedule",
                description: "Get the current schedule for a specific date range",
                parameters: FunctionDefinition.Parameters(
                    type: "object",
                    properties: [
                        "start_date": FunctionDefinition.Property(
                            type: "string",
                            description: "Start date in ISO format",
                            enum: nil,
                            items: nil
                        ),
                        "end_date": FunctionDefinition.Property(
                            type: "string",
                            description: "End date in ISO format",
                            enum: nil,
                            items: nil
                        )
                    ],
                    required: ["start_date", "end_date"]
                )
            )
        ]
    }
    
    func sendMessage(_ message: String, conversationHistory: [ChatMessage]) async throws -> (String, FunctionCall?) {
        var messages = conversationHistory
        messages.append(ChatMessage(role: "user", content: message))
        
        // Add system message if it's the first message
        if messages.count == 1 {
            messages.insert(ChatMessage(
                role: "system",
                content: """
                You are Ty, a friendly and helpful AI calendar assistant for Swift Calendar app. You help users manage their schedule by:
                1. Adding events to their calendar when they tell you about their commitments
                2. Suggesting optimal times for activities based on their existing schedule
                3. Understanding natural language requests about scheduling
                
                Your personality is cool, rad, and unsufferably swagger. You're like a supportive personal assistant who wants to help people stay organized and achieve their goals.
                
                When users mention regular commitments (like "I work 9-5 on weekdays"), create recurring events.
                When users ask for suggestions (like "when should I go to the gym"), analyze their schedule and suggest optimal times.
                Always be conversational and helpful. Use the provided functions to manage the calendar.
                
                Current date and time: \(ISO8601DateFormatter().string(from: Date()))
                """
            ), at: 0)
        }
        
        let request = ChatRequest(
            model: "gpt-4-turbo-preview",
            messages: messages,
            temperature: 0.7,
            functions: calendarFunctions,
            function_call: "auto"
        )
        
        var urlRequest = URLRequest(url: URL(string: apiURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        
        guard let choice = response.choices.first else {
            throw NSError(domain: "OpenAI", code: 0, userInfo: [NSLocalizedDescriptionKey: "No response from AI"])
        }
        
        let content = choice.message.content ?? "I'll help you with that."
        let functionCall = choice.message.function_call.map { fc in
            FunctionCall(name: fc.name, arguments: fc.arguments)
        }
        
        return (content, functionCall)
    }
    
    struct FunctionCall {
        let name: String
        let arguments: String
    }
}
