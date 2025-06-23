//
//  MastoAPI.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-12.
//

import Foundation

@Observable final class MastoAPI: Sendable {
    // This class will handle all interactions with the Mastodon API.
    // It will include methods for authentication, fetching posts, and more.
    
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
        
        DispatchQueue(label: "", qos: .background).async {
            Task {
                self.me = try? await self.getMyAccount()
            }
        }
    }
    
    func login(instanceDomain: String, accessToken: String) {
        self.instanceDomain = instanceDomain
        self.accessToken = accessToken
        
        DispatchQueue(label: "", qos: .background).async {
            Task {
                self.me = try? await self.getMyAccount()
            }
        }
    }
    
    enum TimelineType: String {
        case home = "home"
        case federated = "public?remote=true"
        case local = "public?local=true"
        // TODO: Intelligently support other timeline types such as Chuckya's Bubble timeline
    }
    
    @discardableResult func fetch(endpoint: String, method: String = "GET", parameters: [String: Any]? = nil, body: String? = nil) async throws -> Data {
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
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        if let body = body {
            request.httpBody = body.data(using: .utf8)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, _) = try await urlSession.data(for: request)
        print(String(data: data, encoding: .utf8) ?? "\(data.count) bytes of data")
        return data
    }
    
    func getMyAccount() async throws -> Account {
        let res = try await self.fetch(endpoint: "/v1/accounts/verify_credentials")
        return try decoder.decode(Account.self, from: res)
    }
    
    
    func fetchTimeline(type: TimelineType, after id: String?) async throws -> [Post] {
        var params: [String: Any]?
        
        if let id = id {
            params = ["max_id": id]
        }
        
        let data = try await fetch(endpoint: "/v1/timelines/\(type.rawValue)", parameters: params)
        let posts = try decoder.decode([Post].self, from: data)
        return posts
    }
    
    func fetchAccount(id: String) async throws -> Account {
        let data = try await fetch(endpoint: "/v1/accounts/\(id)")
        let account = try decoder.decode(Account.self, from: data)
        return account
    }
    
    enum AccountViewType: String {
        case `default` = "exclude_replies=true"
        case withReplies = "exclude_replies=false"
        case onlyMedia = "only_media=true"
        var dictValue: [String: Any] {
            [self.rawValue.components(separatedBy: "=").first ?? "exclude_replies": self.rawValue.components(separatedBy: "=").last ?? "true"]
        }
    }
    
    func fetchAccountPosts(for account: Account, view: AccountViewType, after: String? = nil) async throws -> [Post] {
        var params: [String: Any] = view.dictValue
        
        if let after = after {
            params["max_id"] = after
        }
        
        let data = try await fetch(endpoint: "/v1/accounts/\(account.id)/statuses", parameters: params)
        let posts = try decoder.decode([Post].self, from: data)
        return posts
    }
    
    @discardableResult func favourite(_ post: Post) async throws -> Post {
        let endpoint = post.favourited == true ? "unfavourite" : "favourite"
        let data = try await fetch(endpoint: "/v1/statuses/\(post.id)/\(endpoint)", method: "POST")
        let newPost = try decoder.decode(Post.self, from: data)
        return newPost
    }
    
    @discardableResult func reblog(_ post: Post) async throws -> Post {
        let endpoint = post.reblogged == true ? "unreblog" : "reblog"
        try await fetch(endpoint: "/v1/statuses/\(post.id)/\(endpoint)", method: "POST")
        let newPost = post
        newPost.reblogged?.toggle()
        newPost.reblogsCount += 1
        return newPost
    }
    
    class Post: Codable, Identifiable {
        let id: String
        let createdAt: String?
        let inReplyToId: String?
        let inReplyToAccountId: String?
        let sensitive: Bool
        let spoilerText: String?
        let visibility: String
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
        var reblog: Post?
        let account: Account
        let mediaAttachments: [MediaAttachment]?
        let mentions: [Mention]?
        let tags: [Tag]?
        let emojis: [Emoji]?
        let reactions: [Reaction]?
        let quote: Post?
        let card: Card?
        let poll: Poll?
        let application: ApplicationInfo?
    }
    
    struct Account: Codable, Identifiable {
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
    
    struct MediaAttachment: Codable, Identifiable {
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
    
    struct Tag: Codable {
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
    
    struct Field: Codable {
        let name: String
        let value: String
        let verifiedAt: String?
    }

    struct ApplicationInfo: Codable {
        let name: String
        let website: String?
    }

    struct MediaFocus: Codable {
        let x: Double
        let y: Double
    }

    struct MediaSize: Codable {
        let width: Int?
        let height: Int?
        let size: String?
        let aspect: Double?
        let frameRate: String?
        let duration: Double?
        let bitrate: Int?
    }

    struct MediaMeta: Codable {
        let original: MediaSize?
        let small: MediaSize?
        let focus: MediaFocus?
    }
    
    // New struct for Account roles
    struct Role: Codable, Identifiable {
        let id: String
        let name: String
        let color: String?
    }

    // New structs for Post fields
    struct Filter: Codable, Identifiable {
        let id: String
        let title: String
        let context: [String]
        let expiresAt: String?
        let irreversible: Bool?
        let wholeWord: Bool?
        // let filterAction: String // e.g., "warn", "hide" - add if needed
    }

    struct FilterResult: Codable {
        let filter: Filter
        let keywordMatches: [String]?
        let statusMatches: [String]?
    }

    struct Reaction: Codable, Identifiable {
        let name: String
        let count: Int
        let me: Bool?
        let url: String?
        let staticUrl: String?

        var id: String { name }

        enum CodingKeys: String, CodingKey {
            case name, count, me, url
            case staticUrl = "static_url"
        }
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
}

extension MastoAPI.TimelineType {
    var description: String {
        switch self {
        case .home: "Home"
        case .federated: "Federated"
        case .local: "Local"
        }
    }
}
