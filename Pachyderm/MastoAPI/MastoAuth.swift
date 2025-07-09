
import Foundation
import AuthenticationServices

struct AppRegistrationResponse: Codable {
    let clientId: String
    let clientSecret: String

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientSecret = "client_secret"
    }
}

struct TokenResponse: Codable {
    let accessToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

enum MastoAuthError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(statusCode: Int, data: Data?)
    case missingClientIdOrSecret
    case authCodeMissing
    case authFailed(String)
    case userCancelled
}

class MastoAuth {
    static let redirectURI = "pachyderm://auth"
    static let scopes = "read write follow profile push"

    private static let urlSession = URLSession(configuration: .default)

    static func registerApp(instanceDomain: String) async throws -> AppRegistrationResponse {
        guard let url = URL(string: "https://\(instanceDomain)/api/v1/apps") else {
            throw MastoAuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_name": "Pachyderm",
            "redirect_uris": redirectURI,
            "scopes": scopes,
            "website": "https://github.com/BomberFish/Pachyderm"
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("Error registering app. Status: \(statusCode). Data: \(String(data: data, encoding: .utf8) ?? "N/A")")
            throw MastoAuthError.apiError(statusCode: statusCode, data: data)
        }

        do {
            return try JSONDecoder().decode(AppRegistrationResponse.self, from: data)
        } catch {
            print("Error decoding app registration response: \(error)")
            throw MastoAuthError.decodingError(error)
        }
    }

    static func fetchToken(instanceDomain: String, clientId: String, clientSecret: String, authCode: String) async throws -> TokenResponse {
        guard let url = URL(string: "https://\(instanceDomain)/oauth/token") else {
            throw MastoAuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "grant_type": "authorization_code",
            "code": authCode,
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectURI
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("Error fetching token. Status: \(statusCode). Data: \(String(data: data, encoding: .utf8) ?? "N/A")")
            throw MastoAuthError.apiError(statusCode: statusCode, data: data)
        }
        do {
            return try JSONDecoder().decode(TokenResponse.self, from: data)
        } catch {
            print("Error decoding token response: \(error)")
            throw MastoAuthError.decodingError(error)
        }
    }
}

#if os(iOS)
import UIKit

class AuthContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.firstWindow ?? ASPresentationAnchor()
    }
}
#else
class AuthContextProvider: NSObject {}
#endif
