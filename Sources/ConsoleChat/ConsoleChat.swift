import Foundation
import FoundationModels

@main
struct ConsoleChat {
    static func main() async {
        var args = CommandLine.arguments
        args.removeFirst()
        
        if (args.count == 0) { return; }
        if (!checkAvailability()) { return }
        
        let prompt = args.joined(separator: " ")
        await askChat(prompt: prompt)
    }
}


func checkAvailability() -> Bool {
    let model = SystemLanguageModel.default
    
    switch model.availability {
        case .available:
            return true;
        case .unavailable(.deviceNotEligible):
            print("Error: Device not eligible.")
            return false
        case .unavailable(.appleIntelligenceNotEnabled):
            print("Error: Apple Intelligence not enabled.")
            return false
        case .unavailable(.modelNotReady):
            print("Error: Model not ready.")
            return false
        case .unavailable(let other):
            print("Error: \(other)")
            return false
    }

}

func askChat(prompt: String) async {
    let instructions = "Answer the user's questions to the best of your ability. Be consise but correct. Do not add unnecessary details or explanations."
    let session = LanguageModelSession(instructions: instructions)
    
    do {
        let stream = session.streamResponse(to: prompt, )
        for try await partial in stream {
            printFullScreenBox(partial.content, question: "Question: " + prompt)
        }
        
    } catch {
        print("Error streaming response: \(error.localizedDescription)")
    }
}


func printFullScreenBox(_ text: String, question: String? = nil) {
    var ws = winsize()
    let ioctlResult = ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws)
    if ioctlResult == -1 {
        print("Error: Unable to query terminal size.")
        return
    }
    let termRows = Int(ws.ws_row) - 1
    let cols = Int(ws.ws_col)
    
    func wrap(_ content: String, maxWidth: Int) -> [String] {
        var result: [String] = []
        for line in content.components(separatedBy: .newlines) {
            var words = line.split(separator: " ", omittingEmptySubsequences: false)
            var currentLine = ""
            
            while !words.isEmpty {
                let word = words.removeFirst()
                if currentLine.isEmpty {
                    if word.count > maxWidth {
                        let idx = word.index(word.startIndex, offsetBy: maxWidth)
                        result.append(String(word[..<idx]))
                        words.insert(word[idx...], at: 0)
                    } else {
                        currentLine = String(word)
                    }
                } else if currentLine.count + 1 + word.count <= maxWidth {
                    currentLine += " " + word
                } else {
                    result.append(currentLine)
                    if word.count > maxWidth {
                        let idx = word.index(word.startIndex, offsetBy: maxWidth)
                        result.append(String(word[..<idx]))
                        words.insert(word[idx...], at: 0)
                        currentLine = ""
                    } else {
                        currentLine = String(word)
                    }
                }
            }
            
            if !currentLine.isEmpty {
                result.append(currentLine)
            }
        }
        return result
    }
    
    let questionLines = question.map { wrap($0, maxWidth: cols - 4) } ?? []
    let responseLines = wrap(text, maxWidth: cols - 4)
    
    // Dynamically grow height if needed
    let requiredRows = (questionLines.count + 1) + (responseLines.count + 1) + 2
    let rows = max(termRows, requiredRows)
    
    // Clear Screen
    print("\u{001B}[2J")
    
    // Draw box
    print("┌" + String(repeating: "─", count: cols - 2) + "┐")
    
    // Question
    if !questionLines.isEmpty {
        for line in questionLines {
            let padding = String(repeating: " ", count: cols - 4 - line.count)
            print("│ " + line + padding + " │")
        }
        print("│" + String(repeating: " ", count: cols - 2) + "│")
    }
    
    // Fill space so that response sits at bottom
    let usedTop = questionLines.count + (questionLines.isEmpty ? 0 : 1)
    let availableLines = rows - 2 - usedTop
    let contentNeeded = responseLines.count + 1
    let fillerLines = max(availableLines - contentNeeded, 0)
    
    for _ in 0..<fillerLines {
        print("│" + String(repeating: " ", count: cols - 2) + "│")
    }
    
    // Padding above response
    print("│" + String(repeating: " ", count: cols - 2) + "│")
    
    // Response
    for line in responseLines {
        let padding = String(repeating: " ", count: cols - 4 - line.count)
        print("│ " + line + padding + " │")
    }
    
    print("└" + String(repeating: "─", count: cols - 2) + "┘")
}

