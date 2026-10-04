//
//  SummaryPreviewSheet.swift
//  Bridge
//

import SwiftUI

/// The text to show and share, and the subject line for apps that use one,
/// such as Mail.
struct ShareContent: Identifiable {
    let id = UUID()
    let text: String
    let subject: String
}

/// Shows the doctor summary in full so it can be read before it is sent, with
/// a button that opens the share sheet.
struct SummaryPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let content: ShareContent

    private var lines: [String] {
        content.text.components(separatedBy: "\n")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        if line.isEmpty {
                            Color.clear.frame(height: 8)
                        } else {
                            Text(line)
                                .font(font(for: line, at: index))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .textSelection(.enabled)
            }
            .navigationTitle("Summary for my doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                ShareLink(item: content.text, subject: Text(content.subject)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .background(.bar)
            }
        }
    }

    /// The first line is the title and the all-caps section names are headings.
    /// If the summary's wording ever stops matching this, the text simply shows
    /// in the body style.
    private func font(for line: String, at index: Int) -> Font {
        if index == 0 { return .title3.bold() }
        if let first = line.split(separator: " ").first,
           first.count >= 3,
           first == first.uppercased(),
           first.allSatisfy(\.isLetter) {
            return .headline
        }
        return .body
    }
}
