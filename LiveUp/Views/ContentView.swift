import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: CardStore
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            Group {
                if store.cards.isEmpty {
                    ContentUnavailableView(
                        "还没有锁屏卡片",
                        systemImage: "lock.square",
                        description: Text("新建一张卡片，它会钉在锁屏上，抬手就能看到。")
                    )
                } else {
                    List {
                        ForEach(store.cards) { card in
                            CardRow(card: card)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("LiveUp")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreate = true
                    } label: {
                        Label("新建", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateCardView()
            }
        }
    }
}

struct CardRow: View {
    @EnvironmentObject private var store: CardStore
    let card: ReminderCard

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(card.emoji)
                .font(.largeTitle)
            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(.headline)
                if let detail = card.detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Text(kindLabel + " · " + createdAtLabel)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button("完成") {
                store.markDone(card.id)
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.removeCard(card.id)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private var kindLabel: String {
        switch card.kind {
        case .text: return "文字"
        case .photo: return "照片"
        case .voice: return "语音"
        }
    }

    private var createdAtLabel: String {
        card.createdAt.formatted(date: .abbreviated, time: .shortened)
    }
}
