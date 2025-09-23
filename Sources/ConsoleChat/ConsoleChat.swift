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
    let instructions = "Answer the user's questions to the best of your ability. Be consise but correct."
    let session = LanguageModelSession(instructions: instructions)
    let response = Response()
    
    do {
        print()
        
        let stream = session.streamResponse(to: prompt, )
        for try await partial in stream {
            response.newPartial(partial: partial.content)
        }
        print()
        print()
        
    } catch {
        print("Error streaming response: \(error.localizedDescription)")
    }
}


class Response {
    
    private var content: String = ""
    init() {}
    
    public func newPartial(partial: String) {
        let ds = partial.trimmingPrefix(content)
        content = partial
        
        print(ds, terminator: "")
    }
}
