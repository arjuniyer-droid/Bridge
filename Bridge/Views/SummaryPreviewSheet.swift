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
    /// The indexes of the lines that are section headings.
    let headings: Set<Int>
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
            Screen(footer: true) {
                VStack(alignment: .leading, spacing: Space.half) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        if line.isEmpty {
                            Color.clear.frame(height: Space.half)
                        } else {
                            Text(line)
                                .font(.bridge(role(at: index)))
                                .foregroundStyle(Color.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .textSelection(.enabled)
                .card()
            }
            .navigationTitle("Summary for my doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ShareLink(item: content.text, subject: Text(content.subject)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bridgePrimary)
                .padding(Space.unit)
                .background(.bar)
            }
        }
    }

    /// The first line is the title; the summary says which others are headings.
    private func role(at index: Int) -> TypeRole {
        if index == 0 { return .title }
        return content.headings.contains(index) ? .headline : .body
    }
}
