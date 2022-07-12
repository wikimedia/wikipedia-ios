import Intents
import WMF

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
                guard intent is PersonInfoIntent else {
                    fatalError("Unhandled Intent error : \(intent)")
                }
        return PersonInfoIntentHandler()
    }
    
}

class PersonInfoIntentHandler : NSObject, PersonInfoIntentHandling {
    func handle(intent: PersonInfoIntent, completion: @escaping (PersonInfoIntentResponse) -> Void) {
        print("testing overall!")
        print(intent.firstName!)
        print(intent.lastName!)
        print(intent.companyName!)
        completion(PersonInfoIntentResponse.success(result: "Successfully"))
    }
    
    func resolveFirstName(for intent: PersonInfoIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        print("testing first!")
        if intent.firstName == "firstName" {
            completion(INStringResolutionResult.needsValue())
        } else {
            completion(INStringResolutionResult.success(with: intent.firstName ?? ""))
        }
    }
    
    func resolveLastName(for intent: PersonInfoIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        print("testing last!")
        if intent.lastName == "lastName" {
            completion(INStringResolutionResult.needsValue())
        } else {
            completion(INStringResolutionResult.success(with: intent.lastName ?? ""))
        }
    }
    
    func resolveCompanyName(for intent: PersonInfoIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        print("testing company!")
        if intent.companyName == "companyName" {
            completion(INStringResolutionResult.needsValue())
        } else {
            completion(INStringResolutionResult.success(with: intent.companyName ?? ""))
        }
    }
    
    
}
