import SwiftUI

struct ShiftInfoBanner: View {
    let date: Date
    let shifts: [Shift]
    let workplaces: [Workplace]
    let onDismiss: () -> Void
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: date)
    }
    
    private var totalWorkingTime: String {
        let totalMinutes = shifts.reduce(0) { $0 + $1.workingMinutes }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return minutes > 0 ? "\(hours):\(String(format: "%02d", minutes))" : "\(hours)"
    }
    
    private func workplaceColor(for shift: Shift) -> Color {
        workplaces.first { $0.id == shift.workplaceId }?.color ?? .gray
    }
    
    private func workplaceName(for shift: Shift) -> String {
        workplaces.first { $0.id == shift.workplaceId }?.name ?? "不明な職場"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateString)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if shifts.isEmpty {
                        Text("お休み")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(shifts.count)件のシフト・\(totalWorkingTime)時間")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            if !shifts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(shifts.sorted { $0.startTime < $1.startTime }) { shift in
                            ShiftBannerCard(
                                shift: shift,
                                workplaceName: workplaceName(for: shift),
                                workplaceColor: workplaceColor(for: shift)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.horizontal, -16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
}

struct ShiftBannerCard: View {
    let shift: Shift
    let workplaceName: String
    let workplaceColor: Color
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: shift.startTime) + " - " + formatter.string(from: shift.endTime)
    }
    
    private var workingTime: String {
        let hours = shift.workingMinutes / 60
        let minutes = shift.workingMinutes % 60
        if minutes == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h\(minutes)m"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(workplaceColor)
                    .frame(width: 8, height: 8)
                
                Text(workplaceName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            
            Text(timeString)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(workingTime)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    let sampleWorkplace = Workplace(
        id: UUID(),
        name: "サンプル職場",
        color: .blue,
        hourlyWage: 1000,
        transportationAllowance: 200,
        createdAt: Date()
    )
    
    let sampleShift = Shift(
        workplaceId: sampleWorkplace.id,
        date: Date(),
        startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
        endTime: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date(),
        breakMinutes: 60
    )
    
    ShiftInfoBanner(
        date: Date(),
        shifts: [sampleShift],
        workplaces: [sampleWorkplace],
        onDismiss: {}
    )
    .padding()
}