import SwiftUI

// Shared view components used across multiple views

struct OverlapWarningView: View {
    let overlap: ShiftOverlap
    let workplaces: [Workplace]
    
    private var workplace1: Workplace? {
        workplaces.first { $0.id == overlap.shift1.workplaceId }
    }
    
    private var workplace2: Workplace? {
        workplaces.first { $0.id == overlap.shift2.workplaceId }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("重複: \(overlap.overlapMinutes)分間")
                    .font(.caption)
                    .foregroundColor(.red)
                    .bold()
                Spacer()
            }
            
            HStack {
                Circle()
                    .fill(workplace1?.color ?? .gray)
                    .frame(width: 8, height: 8)
                Text(workplace1?.name ?? "不明")
                    .font(.caption)
                Text("\(timeFormatter.string(from: overlap.shift1.startTime))-\(timeFormatter.string(from: overlap.shift1.endTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Circle()
                    .fill(workplace2?.color ?? .gray)
                    .frame(width: 8, height: 8)
                Text(workplace2?.name ?? "不明")
                    .font(.caption)
                Text("\(timeFormatter.string(from: overlap.shift2.startTime))-\(timeFormatter.string(from: overlap.shift2.endTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
    }
}