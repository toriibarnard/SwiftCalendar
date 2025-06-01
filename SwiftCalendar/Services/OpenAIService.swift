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
                name: "remove_event",
                description: "Remove an event from the calendar",
                parameters: FunctionDefinition.Parameters(
                    type: "object",
                    properties: [
                        "event_title": FunctionDefinition.Property(
                            type: "string",
                            description: "The title or partial title of the event to remove",
                            enum: nil,
                            items: nil
                        ),
                        "date": FunctionDefinition.Property(
                            type: "string",
                            description: "The date of the event in ISO format (optional, if multiple events have same title)",
                            enum: nil,
                            items: nil
                        )
                    ],
                    required: ["event_title"]
                )
            ),
            FunctionDefinition(
                name: "check_conflicts",
                description: "Check if there are conflicts at a specific time",
                parameters: FunctionDefinition.Parameters(
                    type: "object",
                    properties: [
                        "date": FunctionDefinition.Property(
                            type: "string",
                            description: "The date to check in ISO format",
                            enum: nil,
                            items: nil
                        ),
                        "start_time": FunctionDefinition.Property(
                            type: "string",
                            description: "Start time to check",
                            enum: nil,
                            items: nil
                        ),
                        "end_time": FunctionDefinition.Property(
                            type: "string",
                            description: "End time to check",
                            enum: nil,
                            items: nil
                        )
                    ],
                    required: ["date"]
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
    
    func sendMessage(_ message: String, conversationHistory: [ChatMessage], existingEvents: [ScheduleEvent] = []) async throws -> (String, FunctionCall?) {
        var messages = conversationHistory
        messages.append(ChatMessage(role: "user", content: message))
        
        // Add system message if it's the first message
        if messages.count == 1 {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.timeZone = TimeZone.current
            
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE, MMMM d, yyyy"
            
            let currentDateTime = dateFormatter.string(from: Date())
            let todayString = dayFormatter.string(from: Date())
            
            // Create a string of existing events for context
            let eventsList = existingEvents.prefix(10).map { event in
                let eventDate = dayFormatter.string(from: event.startTime)
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "h:mm a"
                let startTime = timeFormatter.string(from: event.startTime)
                let endTime = timeFormatter.string(from: event.startTime.addingTimeInterval(TimeInterval(event.duration * 60)))
                return "- \(event.title): \(eventDate) from \(startTime) to \(endTime)"
            }.joined(separator: "\n")
            
            messages.insert(ChatMessage(
                role: "system",
                content: """
                You are Ty, a smart calendar assistant. Today is \(todayString).
                Current exact time: \(currentDateTime)
                
                EXISTING EVENTS ON CALENDAR:
                \(eventsList.isEmpty ? "No events scheduled yet." : eventsList)
                
                CRITICAL RULES:
                1. TODAY IS \(todayString). Calculate all dates relative to this.
                2. When user says "June 4th", calculate what day of week that is based on today's date
                3. ALWAYS check for conflicts before adding events
                4. If there's a conflict, mention it: "You have work scheduled at that time. Would you like me to remove it?"
                5. For times like "noon", use 12:00. For "evening", suggest 6:00 PM
                
                DATE HANDLING:
                - Format all dates as: yyyy-MM-dd'T'HH:mm:ss (no timezone)
                - "Tomorrow" = add 1 day to today
                - "Next Monday" = find the next Monday from today
                - Weekdays for recurring: Monday=1, Tuesday=2, Wednesday=3, Thursday=4, Friday=5
                
                CATEGORIES:
                - work/meeting/office → "work"
                - gym/exercise/workout → "fitness"
                - doctor/dentist/medical → "health"
                - study/homework/class → "study"
                - party/dinner/social → "social"
                - other → "personal"
                
                When adding events, be specific about what you're doing:
                "I've added [event] on [full date with day of week] from [time] to [time]"
                
                For the function calls:
                - Use check_conflicts first if adding to a day that might have events
                - Then use remove_event if user wants to replace something
                - Finally use add_event
                """
            ), at: 0)
        }
        
        let request = ChatRequest(
            model: "gpt-4-0125-preview",  // Latest GPT-4 model
            messages: messages,
            temperature: 0.2, // Even lower for more consistency
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
