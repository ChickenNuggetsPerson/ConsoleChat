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
            printChat(question: prompt, response: partial.content)
        }
        
    } catch {
        print("Error streaming response: \(error.localizedDescription)")
    }
}




func printChat(question: String, response: String) {
    let (height, width) = getTerminalSize()
    var buffer = newBuffer(width: width, height: height - 1)
    
    drawTextInBox(&buffer, text: "   \(question)", header: "Question:", x: 2, y: 1, width: width * 2/3)
    drawTextInBox(&buffer, text: response, x: 1, y: 6, width: width - 2)
    
    printBuffer(&buffer)
}


