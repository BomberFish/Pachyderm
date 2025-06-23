//
//  PostContentView.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-06-12.
//

import SwiftUI

struct RichContentView: View {
    let content: String
    let emojis: [MastoAPI.Emoji]?
    @State private var attributedContent: AttributedString

    init(content: String, emojis: [MastoAPI.Emoji]?) {
        self.content = content
        self.emojis = emojis
        _attributedContent = State(initialValue: AttributedString(content.prefix(100) + (content.count > 100 ? "..." : "")))
    }

    var body: some View {
        Text(attributedContent)
            .task(priority: .medium) {
                self.attributedContent = await RichContentView.buildAttributedContent(content: content, emojis: emojis)
            }
    }

    static func buildAttributedContent(content: String, emojis: [MastoAPI.Emoji]?) async -> AttributedString {
        var attributedString: AttributedString

        if let data = content.data(using: .utf8) {
            do {
                let nsAttributedString = try NSAttributedString(data: data,
                                                                options: [.documentType: NSAttributedString.DocumentType.html,
                                                                          .characterEncoding: String.Encoding.utf8.rawValue],
                                                                documentAttributes: nil)
                attributedString = AttributedString(nsAttributedString)
            } catch {
                print("Error during NSAttributedString HTML parsing or conversion: \(error)")
                attributedString = AttributedString(content)
            }
        } else {
            attributedString = AttributedString(content)
        }

        if let emojis = emojis, !emojis.isEmpty {
            struct EmojiMatch: Comparable {
                let range: Range<AttributedString.Index>
                let imageUrl: URL

                static func < (lhs: EmojiMatch, rhs: EmojiMatch) -> Bool {
                    if lhs.range.lowerBound != rhs.range.lowerBound {
                        return lhs.range.lowerBound < rhs.range.lowerBound
                    }
                    return lhs.range.upperBound < rhs.range.upperBound
                }

                static func == (lhs: EmojiMatch, rhs: EmojiMatch) -> Bool {
                    lhs.range == rhs.range && lhs.imageUrl == rhs.imageUrl
                }
            }

            var allMatches: [EmojiMatch] = []
            for emoji in emojis {
                let shortcode = ":\(emoji.shortcode):"
                guard let imageUrl = URL(string: emoji.url) else { continue }

                var searchStartIndex = attributedString.startIndex
                while searchStartIndex < attributedString.endIndex,
                      let foundRange = attributedString[searchStartIndex...].range(of: shortcode, options: .literal) {
                    if !foundRange.isEmpty {
                        allMatches.append(EmojiMatch(range: foundRange, imageUrl: imageUrl))
                        searchStartIndex = foundRange.upperBound
                    } else {
                        if searchStartIndex < attributedString.endIndex {
                            let nextPossibleIndex = attributedString.index(afterCharacter: searchStartIndex)
                            if nextPossibleIndex > searchStartIndex {
                                searchStartIndex = nextPossibleIndex
                            } else {
                                searchStartIndex = attributedString.endIndex
                            }
                        } else {
                            searchStartIndex = attributedString.endIndex
                        }
                    }
                }
            }

            if !allMatches.isEmpty {
                allMatches.sort()

                var newStringWithEmojis = AttributedString()
                var currentIndex = attributedString.startIndex
                var processedMatchEndIndex = attributedString.startIndex

                for match in allMatches {
                    if match.range.lowerBound < processedMatchEndIndex { continue }

                    if match.range.lowerBound > currentIndex {
                        newStringWithEmojis.append(attributedString[currentIndex..<match.range.lowerBound])
                    }
                    var imageContainer = AttributeContainer()
                    imageContainer.link = match.imageUrl
                    let imageReplacement = AttributedString(" ", attributes: imageContainer)
                    newStringWithEmojis.append(imageReplacement)

                    currentIndex = match.range.upperBound
                    processedMatchEndIndex = match.range.upperBound
                }

                if currentIndex < attributedString.endIndex {
                    newStringWithEmojis.append(attributedString[currentIndex...])
                }

                attributedString = newStringWithEmojis
            }
        }
        
        if !attributedString.runs.isEmpty {
            let fullRange = attributedString.startIndex..<attributedString.endIndex
            attributedString[fullRange].font = .system(.body)
            attributedString[fullRange].foregroundColor = .primary
        }

        return attributedString
    }
}

