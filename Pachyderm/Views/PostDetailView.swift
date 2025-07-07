//
//  PostView.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-13.
//

import SwiftUI

struct PostDetailView: View {
    @Environment(MastoAPI.self) private var api: MastoAPI
    @Binding var post: MastoAPI.Status
    var body: some View {
        PostCell(post: $post)
    }
}

//#Preview {
//    PostView()
//}
