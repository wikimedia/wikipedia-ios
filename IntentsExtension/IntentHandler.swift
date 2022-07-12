import Intents
import WMF

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
                guard intent is GenerateReadingListIntent else {
                    fatalError("Unhandled Intent error : \(intent)")
                }
        return GenerateReadingListIntentHandler()
    }
    
}

class GenerateReadingListIntentHandler : NSObject, GenerateReadingListIntentHandling {
    
    func handle(intent: GenerateReadingListIntent) async -> GenerateReadingListIntentResponse {
        guard let sourceTexts = intent.sourceTexts,
              let readingListName = intent.readingListName else {
            return GenerateReadingListIntentResponse(code: .failure, userActivity: nil)
        }
        
        for sourceText in sourceTexts {
            print(sourceText)
        }
        
        let dispatchGroup = DispatchGroup()
        
        return GenerateReadingListIntentResponse.success(result: "Your \"\(readingListName)\" reading list was generated from \(sourceTexts.count) source texts.")
    }
    
    func resolveSourceTexts(for intent: GenerateReadingListIntent) async -> [INStringResolutionResult] {
        print("resolvingSourceTexts!")

        guard let sourceTexts = intent.sourceTexts else {
            // for some reason I can't seem to trigger MULTIPLE source texxt prompts. I'm not sure what I need to do.
            return [INStringResolutionResult.needsValue(), INStringResolutionResult.needsValue()]
        }

        return sourceTexts.map { INStringResolutionResult.success(with: $0) }
    }
    
    func resolveReadingListName(for intent: GenerateReadingListIntent) async -> INStringResolutionResult {
        print("Resolving reading list name!")
        
        guard let readingListName = intent.readingListName else {
            return INStringResolutionResult.needsValue()
        }
        
        return INStringResolutionResult.success(with: readingListName)
    }
    
    
}
