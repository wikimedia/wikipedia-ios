import Foundation


let count = CommandLine.arguments.count
guard count > 1 else {
    abort()
}

struct LanguageJSON: Codable {
    let code: String
    let normalized_code: String?
    let canonical_name: String
    let name: String
}

let path = CommandLine.arguments[1]
let pathComponents = path.components(separatedBy: "/")
let languagesJSONPathComponents = pathComponents + ["Wikipedia", "assets", "languages.json"]
let languagesJSONPath = languagesJSONPathComponents.joined(separator: "/")
let languagesJSONData = try! Data(contentsOf: URL(fileURLWithPath: languagesJSONPath))
let languages = try! JSONDecoder().decode([LanguageJSON].self, from: languagesJSONData)

func getCodeMirrorConfigJSON(for wikiLanguage: String, completion: @escaping (String?) -> Void) {
    guard let url = URL(string: "http://\(wikiLanguage).wikipedia.org/w/load.php?debug=false&lang=en&modules=ext.CodeMirror.data") else {
        completion(nil)
        return
    }
    URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard let data = data else {
            completion(nil)
            return
        }
        guard let responseString = String(data: data, encoding: .utf8) else {
            completion(nil)
            return
        }
        guard let last = responseString.components(separatedBy: "mw.config.set(").last else {
            completion(nil)
            return
        }
        guard let first = last.components(separatedBy: ");});").first else {
            completion(nil)
            return
        }
        completion(first.replacingOccurrences(of: "!0", with: "true"))
        }.resume()
}

let group = DispatchGroup()
for language in languages {
    let codes = [language.normalized_code, language.code].compactMap({ $0 })
    for code in codes {
        group.enter()
        getCodeMirrorConfigJSON(for: code) { (response) in
            defer {
                group.leave()
            }
            guard let response = response else {
                return
            }
            let outputComponents = pathComponents + ["Wikipedia", "assets", "codemirror", "config", "codemirror-config-\(language.code).json"]
            let outputPath = outputComponents.joined(separator: "/")
            try! response.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
        }
    }
}


group.notify(queue: DispatchQueue.main) {
    exit(0)
}

dispatchMain()
