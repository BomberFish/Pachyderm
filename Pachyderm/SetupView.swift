//
//  SetupView.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-12.
//

import SwiftUI
import AuthenticationServices

struct SetupView: View {
    @Binding public var instanceDomain: String
    @Binding public var accessToken: String

    @State private var webAuthSession: ASWebAuthenticationSession?
    @State private var clientID: String = ""
    @State private var clientSecret: String = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    @Environment(MastoAPI.self) private var api: MastoAPI

    private var authContextProvider = AuthContextProvider()
    
    init(baseURL: Binding<String>, accessToken: Binding<String>) {
        self._instanceDomain = baseURL
        self._accessToken = accessToken
    }

    var body: some View {
        VStack {
            Text("Welcome to Pachyderm!")
                .font(.title2.weight(.semibold))
            Text("Enter the domain of your Mastodon instance here:")
            TextField("Instance Domain", text: $instanceDomain)
                .disableAutocorrection(true)
                .keyboardType(.webSearch)
                .modifier(FancyInputViewModifier())
                .padding()

            Button("Login with Mastodon", systemImage: "person.badge.key") {
                Task {
                    await startOAuthFlow()
                }
            }
            .controlSize(.large)
            .glassProminentButton()
            .disabled(instanceDomain == "")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .padding()
    }

    func startOAuthFlow() async {
        let domain = instanceDomain.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
        guard !domain.isEmpty else {
            await UIApplication.shared.alert(body: "Please enter a valid domain.")
            return
        }

        do {
            let appInfo = try await MastoAuth.registerApp(instanceDomain: domain)
            self.clientID = appInfo.clientId
            self.clientSecret = appInfo.clientSecret
        } catch {
            await UIApplication.shared.alertError(error.localizedDescription)
            return
        }

        guard var authURLComponents = URLComponents(string: "https://\(domain)/oauth/authorize") else {
            await UIApplication.shared.alert(body: "Invalid instance domain. Please check the URL.")
            return
        }
        authURLComponents.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: MastoAuth.redirectURI),
            URLQueryItem(name: "scope", value: MastoAuth.scopes),
            URLQueryItem(name: "force_login", value: "true")
        ]

        guard let authURL = authURLComponents.url else {
            await UIApplication.shared.alert(body: "Failed to construct authorization URL.")
            return
        }

        self.webAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "pachyderm"
        ) { callbackURL, error in
            if let error = error {
                if case ASWebAuthenticationSessionError.canceledLogin = error {
                    print("User cancelled login.")
                } else {
                    UIApplication.shared.alertError(error.localizedDescription)
                }
                return
            }

            guard let callbackURL = callbackURL else {
                showError(message: "Authentication failed: No callback URL received.")
                return
            }
            print("Callback URL received: \(callbackURL)")
            
            handleRedirect(url: callbackURL)
        }

        #if os(iOS)
        self.webAuthSession?.presentationContextProvider = authContextProvider
        #endif
        self.webAuthSession?.prefersEphemeralWebBrowserSession = true

        self.webAuthSession?.start()
    }

    func handleRedirect(url: URL) {
        guard url.scheme == "pachyderm",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let authCode = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            UIApplication.shared.alert(body: "Invalid redirect URL. Please try again.")
            return
        }
        
        Task {
            do {
                let tokenInfo = try await MastoAuth.fetchToken(
                    instanceDomain: instanceDomain.trimmingCharacters(in: .whitespacesAndNewlines),
                    clientId: clientID,
                    clientSecret: clientSecret,
                    authCode: authCode
                )
                self.api.login(instanceDomain: instanceDomain.trimmingCharacters(in: .whitespacesAndNewlines), accessToken: tokenInfo.accessToken)
                
                self.accessToken = tokenInfo.accessToken
            } catch {
                await UIApplication.shared.alertError(error)
            }
        }
    }

    func showError(message: String) {
        print("Error: \(message)")
        self.errorMessage = message
        self.showErrorAlert = true
    }
}

#Preview {
    @Previewable @State var baseURL: String = ""
    @Previewable @State var accessToken: String = ""
    SetupView(baseURL: $baseURL, accessToken: $accessToken)
}
