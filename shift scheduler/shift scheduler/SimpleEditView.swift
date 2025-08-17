import SwiftUI

struct SimpleEditView: View {
    let shift: Shift
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Edit Shift - Simple Test")
                    .font(.title)
                Text("Shift ID: \(shift.id.uuidString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Debug: View is rendering!")
                    .foregroundColor(.green)
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Test Edit")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}