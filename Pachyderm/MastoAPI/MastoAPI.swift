//
//  MastoAPI.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-12.
//

import Foundation
import Perception

@Perceptible final class MastoAPI: Sendable {
    private(set) public var instanceDomain: String
    private(set) public var accessToken: String
    
    private(set) public var me: Account?
    
    private var urlSession: URLSession = URLSession(configuration: .default)
    
    
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
    
    init(instanceDomain: String, accessToken: String) {
        self.instanceDomain = instanceDomain
        self.accessToken = accessToken
        self.login(instanceDomain: instanceDomain, accessToken: accessToken)
    }
    
    func login(instanceDomain: String, accessToken: String) {
        self.instanceDomain = instanceDomain
        self.accessToken = accessToken
        
        DispatchQueue(label: "", qos: .background).async {
            Task {
                do {
                    let acc = try await self.me()
                    await MainActor.run {
                        self.me = acc
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
    
    enum TimelineType: String {
        case home = "home"
        case federated = "public?remote=true"
        case local = "public?local=true"
        case bubble = "public?bubble=true"
    }
    
    @discardableResult func grab(endpoint: String, method: String = "GET", parameters: [String: Any]? = nil, body: [String:Any]? = nil) async throws -> Data {
        var endpoint = endpoint
        if endpoint.hasPrefix("/") {
            endpoint = String(endpoint.dropFirst())
        }
        var urlComponents = URLComponents(url: URL(string: "https://\(instanceDomain)/api/\(endpoint)")!, resolvingAgainstBaseURL: false)
        
        if let parameters = parameters {
            urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }
        
        guard let url = urlComponents?.url else {
            throw NSError(domain: "MastoAPIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        print(url.absoluteString)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await urlSession.data(for: request)
        print((response as? HTTPURLResponse)?.statusCode ?? 0)
        print(String(data: data, encoding: .utf8) ?? "\(data.count) bytes of data")
        return data
    }
    
    func me() async throws -> Account {
        let res = try await self.grab(endpoint: "/v1/accounts/verify_credentials")
        return try decoder.decode(Account.self, from: res)
    }
    
    func post(status: String, visibility: MastoAPI.Visibility, mediaIds: [String] = []) async throws {
        let body: [String: Any] = ["status": status, "media_ids": mediaIds, "visibility": visibility.rawValue]
        let res = try await self.grab(endpoint: "/v1/statuses", method: "POST", parameters: nil, body: body)
        print(res)
    }
    
    
    func timeline(type: TimelineType, after id: String?) async throws -> [Status] {
        var params: [String: Any]?
        
        if let id = id {
            params = ["max_id": id]
        }
        
        let data = try await grab(endpoint: "/v1/timelines/\(type.rawValue)", parameters: params)
        return try decoder.decode([Status].self, from: data)
    }
    
    func account(id: String) async throws -> Account {
        let data = try await grab(endpoint: "/v1/accounts/\(id)")
        return try decoder.decode(Account.self, from: data)
    }
    
    func notifications() async throws -> [Notification] {
        let data = try await grab(endpoint: "/v1/notifications")
        return try decoder.decode([Notification].self, from: data)
    }
    
    
    enum AccountViewType: String {
        case `default` = "exclude_replies=true"
        case withReplies = "exclude_replies=false"
        case onlyMedia = "only_media=true"
        var dictValue: [String: Any] {
            [self.rawValue.components(separatedBy: "=").first ?? "exclude_replies": self.rawValue.components(separatedBy: "=").last ?? "true"]
        }
    }
    
    func accountPosts(for account: Account, view: AccountViewType, after: String? = nil) async throws -> [Status] {
        var params: [String: Any] = view.dictValue
        
        if let after = after {
            params["max_id"] = after
        }
        
        let data = try await grab(endpoint: "/v1/accounts/\(account.id)/statuses", parameters: params)
        let posts = try decoder.decode([Status].self, from: data)
        return posts
    }
    
    @discardableResult func favourite(_ post: Status) async throws -> Status {
        let endpoint = post.favourited == true ? "unfavourite" : "favourite"
        let data = try await grab(endpoint: "/v1/statuses/\(post.id)/\(endpoint)", method: "POST")
        return try decoder.decode(Status.self, from: data)
    }
    
    @discardableResult func reblog(_ post: Status) async throws -> Status {
        let endpoint = post.reblogged == true ? "unreblog" : "reblog"
        try await grab(endpoint: "/v1/statuses/\(post.id)/\(endpoint)", method: "POST")
        let newPost = post
        newPost.reblogged?.toggle()
        newPost.reblogsCount += 1
        return newPost
    }
    
    enum Visibility: String, Codable {
        case `public` = "public"
        case unlisted = "unlisted"
        case `private` = "private"
        case direct = "direct"
    }
    
    class Status: Codable, Identifiable {
        let id: String
        let createdAt: String?
        let inReplyToId: String?
        let inReplyToAccountId: String?
        let sensitive: Bool
        let spoilerText: String?
        let visibility: Visibility
        let language: String?
        let uri: String
        let url: String?
        let repliesCount: Int
        var reblogsCount: Int
        let favouritesCount: Int
        let reactionsCount: Int?
        let editedAt: String?
        let conversationId: Int?
        var favourited: Bool?
        var reblogged: Bool?
        let muted: Bool?
        let bookmarked: Bool?
        let pinned: Bool?
        let localOnly: Bool?
        let content: String
        let filtered: [FilterResult]?
        var reblog: Status?
        let account: Account
        let mediaAttachments: [MediaAttachment]?
        let mentions: [Mention]?
        let tags: [Tag]?
        let emojis: [Emoji]?
        let reactions: [Reaction]?
        let quote: QuoteStatus?
        let card: Card?
        let poll: Poll?
        let application: ApplicationInfo?
    }
    
    // quotes are very broken
    struct QuoteStatus: Codable, Identifiable, Hashable {
        let id: String?
        let content: String?
    }
    
    struct Account: Codable, Identifiable, Hashable {
        let id: String
        let username: String
        let acct: String
        let displayName: String?
        let locked: Bool
        let bot: Bool
        let discoverable: Bool?
        let indexable: Bool?
        let group: Bool
        let createdAt: String?
        let note: String
        let url: String
        let uri: String
        let avatar: String
        let avatarStatic: String
        let avatarDescription: String?
        let header: String
        let headerStatic: String
        let headerDescription: String?
        let followersCount: Int
        let followingCount: Int
        let statusesCount: Int
        let lastStatusAt: String?
        let hideCollections: Bool?
        let emojis: [Emoji]?
        let fields: [Field]?
        let roles: [Role]?
    }
    
    struct MediaAttachment: Codable, Identifiable, Hashable {
        let id: String
        let type: String // e.g., "image", "video", "gifv", "audio"
        let url: String
        let previewUrl: String?
        let remoteUrl: String?
        let previewRemoteUrl: String?
        let textUrl: String?
        let description: String?
        let blurhash: String?
        let meta: MediaMeta?
    }
    
    struct Mention: Codable, Identifiable, Hashable {
        let id: String
        let username: String
        let url: String
        let acct: String
    }
    
    struct Tag: Codable, Hashable {
        let name: String
        let url: String
    }
    
    struct Emoji: Codable, Identifiable, Hashable {
        let shortcode: String
        let url: String
        let staticUrl: String?
        let visibleInPicker: Bool
        
        var id: String { shortcode }
    }
    
    struct Field: Codable, Hashable {
        let name: String
        let value: String
        let verifiedAt: String?
    }

    struct ApplicationInfo: Codable, Hashable {
        let name: String
        let website: String?
    }

    struct MediaFocus: Codable, Hashable {
        let x: Double
        let y: Double
    }

    struct MediaSize: Codable, Hashable {
        let width: Int?
        let height: Int?
        let size: String?
        let aspect: Double?
        let frameRate: String?
        let duration: Double?
        let bitrate: Int?
    }

    struct MediaMeta: Codable, Hashable {
        let original: MediaSize?
        let small: MediaSize?
        let focus: MediaFocus?
    }
    
    // New struct for Account roles
    struct Role: Codable, Identifiable, Hashable {
        let id: String
        let name: String
        let color: String?
    }

    // New structs for Post fields
    struct Filter: Codable, Identifiable, Hashable {
        let id: String
        let title: String
        let context: [String]
        let expiresAt: String?
        let irreversible: Bool?
        let wholeWord: Bool?
        // let filterAction: String // e.g., "warn", "hide" - add if needed
    }

    struct FilterResult: Codable, Hashable {
        let filter: Filter
        let keywordMatches: [String]?
        let statusMatches: [String]?
    }

    struct Reaction: Codable, Identifiable, Hashable {
        let name: String
        let count: Int
        let me: Bool?
        let url: String?
        let staticUrl: String?

        var id: String { name }

//        enum CodingKeys: String, CodingKey {
//            case name, count, me, url
//            case staticUrl = "static_url"
//        }
    }
    
    struct Card: Codable {
        let url: String
        let title: String
        let description: String
        let language: String?
        let type: String // "link", "photo", "video", "rich"
        let authorName: String?
        let authorUrl: String?
        let providerName: String?
        let providerUrl: String?
        let html: String?
        let width: Int?
        let height: Int?
        let image: String?
        let imageDescription: String?
        let embedUrl: String?
        let blurhash: String?
        let publishedAt: String?
        let authors: [CardAuthor]?
    }
    
    struct CardAuthor: Codable {
        let name: String
        let url: String?
        // let account: String? // or a more complex AccountPreview struct if needed
    }
    
    struct Poll: Codable, Identifiable {
        let id: String
        let expiresAt: String?
        let expired: Bool
        let multiple: Bool
        let votesCount: Int
        let votersCount: Int?
        let voted: Bool?
        let ownVotes: [Int]?
        let options: [PollOption]
        let emojis: [Emoji]?
    }
    
    struct PollOption: Codable {
       let title: String
       let votesCount: Int?
    }
    
    struct Notification: Codable, Hashable {
        let type: String
        let status: Status?
        let account: Account
    }
}

extension MastoAPI.Status: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: MastoAPI.Status, rhs: MastoAPI.Status) -> Bool {
        return lhs.id == rhs.id
    }
}

extension MastoAPI.TimelineType {
    var description: String {
        switch self {
        case .home: "Home"
        case .federated: "Federated"
        case .local: "Local"
        case .bubble: "Bubble"
        @unknown default: self.rawValue
        }
    }
}

extension MastoAPI.Visibility {
    var description: String {
        switch self {
        case .public: "Public"
        case .unlisted: "Quiet Public"
        case .private: "Followers Only"
        case .direct: "Direct"
        @unknown default: self.rawValue.capitalized
        }
    }
    
    var icon: String {
        switch self {
        case .public: "network"
        case .unlisted: "moon"
        case .private: "lock"
        case .direct: "envelope"
        @unknown default: "eye"
        }
    }
    
    static var allCases = [Self.public, Self.unlisted, Self.private, Self.direct]
}
