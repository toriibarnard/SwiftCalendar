//
//  ClaudeAPIService.swift
//  SwiftCalendar
//
//  Created by Torii Barnard on 2025-06-03.
//


//
//  ClaudeAPIService.swift
//  SwiftCalendar
//
//  Service for handling Claude API communication
//

import Foundation

class ClaudeAPIService {
    
    private let apiKey: String
    private let apiURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-3-5-sonnet-20241022"
    
    // Conversation history storage
    private var conversationHistory: [[String: Any]] = []
    
    init() {
        // Load API key from Config.plist
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["CLAUDE_API_KEY"] as? String else {
            fatalError("Claude API key not found in Config.plist - add CLAUDE_API_KEY")
        }
        
        // Debug: Print API key format (first/last few characters only for security)
        let keyStart = String(key.prefix(10))
        let keyEnd = String(key.suffix(4))
        print("🔑 Claude API Key format: \(keyStart)...\(keyEnd)")
        print("🔑 Key length: \(key.count)")
        
        if !key.hasPrefix("sk-ant-api03-") {
            print("⚠️ WARNING: Claude API key should start with 'sk-ant-api03-'")
        }
        
        self.apiKey = key
    }
    
    // MARK: - Public API
    
    func sendMessage(
        _ message: String,
        systemPrompt: String
    ) async throws -> ClaudeResponse {
        
        // Add user message to conversation history
        conversationHistory.append([
            "role": "user",
            "content": message
        ])
        
        // Build request
        let request = ClaudeRequest(
            model: model,
            maxTokens: 1500,
            temperature: 0.1, // Low temperature for consistent behavior
            systemPrompt: systemPrompt,
            messages: conversationHistory
        )
        
        // Send to Claude
        let response = try await performAPIRequest(request)
        
        // Add AI response to conversation history
        conversationHistory.append([
            "role": "assistant",
            "content": response.content
        ])
        
        return response
    }
    
    func clearConversationHistory() {
        conversationHistory.removeAll()
    }
    
    // MARK: - Private Implementation
    
    private func performAPIRequest(_ request: ClaudeRequest) async throws -> ClaudeResponse {
        
        var urlRequest = URLRequest(url: URL(string: apiURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key") // Claude uses x-api-key, not Bearer
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version") // Required header
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: request.toDictionary())
        
        // Debug: Print request headers (mask the API key)
        print("🔍 Request URL: \(apiURL)")
        print("🔍 x-api-key header: \(String(apiKey.prefix(10)))...***")
        print("🔍 Content-Type: \(urlRequest.value(forHTTPHeaderField: "Content-Type") ?? "nil")")
        print("🔍 Anthropic-Version: \(urlRequest.value(forHTTPHeaderField: "anthropic-version") ?? "nil")")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Debug response
        if let httpResponse = response as? HTTPURLResponse {
            print("🌐 Claude API Response Status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                print("🌐 Response Headers: \(httpResponse.allHeaderFields)")
            }
        }
        
        // Print raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("🌐 Raw Claude API Response: \(responseString)")
        }
        
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Handle API errors
        if let error = jsonResponse?["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw APIError.claudeError(message)
        }
        
        // Parse Claude response format
        guard let content = jsonResponse?["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw APIError.invalidResponse("Invalid Claude response format")
        }
        
        // Parse usage info if available
        var usage: ClaudeResponse.TokenUsage?
        if let usageData = jsonResponse?["usage"] as? [String: Any],
           let inputTokens = usageData["input_tokens"] as? Int,
           let outputTokens = usageData["output_tokens"] as? Int {
            usage = ClaudeResponse.TokenUsage(
                inputTokens: inputTokens,
                outputTokens: outputTokens
            )
        }
        
        return ClaudeResponse(
            id: jsonResponse?["id"] as? String ?? UUID().uuidString,
            content: text,
            stopReason: jsonResponse?["stop_reason"] as? String,
            usage: usage
        )
    }
}

// MARK: - Error Types

enum APIError: LocalizedError {
    case claudeError(String)
    case invalidResponse(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .claudeError(let message):
            return "Claude API Error: \(message)"
        case .invalidResponse(let message):
            return "Invalid Response: \(message)"
        case .networkError(let error):
            return "Network Error: \(error.localizedDescription)"
        }
    }
}