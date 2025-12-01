import Foundation

struct GlobalUserInfoResponse: Decodable {
    let batchcomplete: Bool
    let query: Query

    struct Query: Decodable {
        let globaluserinfo: GlobalUserInfo
    }

}

struct GlobalUserInfo: Decodable {
    let home: String
    let id: Int
    let registration: String
    let name: String
    let editcount: Int
}
