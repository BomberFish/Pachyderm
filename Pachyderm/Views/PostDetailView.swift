//
//  PostView.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-13.
//

import SwiftUI
import PerceptionCore

struct PostDetailView: View {
    @Environment(MastoAPI.self) private var api: MastoAPI
    @Binding var post: MastoAPI.Status
    var body: some View {
        WithPerceptionTracking {
            PostCell(post: $post)
        }
    }
}

//#Preview {
//    PostView()
//}
