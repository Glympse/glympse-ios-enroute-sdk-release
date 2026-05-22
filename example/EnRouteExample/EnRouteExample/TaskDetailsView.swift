import SwiftUI
import EnRouteApi

struct TaskDetailsView: View {
    var task: TaskWrapper?
    
    var body: some View {
        if let task = task {
            ScrollView(.vertical) {
                // Header area
                HStack {
                    Text(task.task.getDescription() ?? "No Description")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(task.task.getPhase() ?? "")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12)
                        )
                }
                
                let generalRows = getGeneralInfoRows(for: task.task)
                InfoCardView(title: "General Information", rows: generalRows)
                
                let timelineRows = getTimelineInfoRows(for: task.task)
                InfoCardView(title: "Timeline", rows: timelineRows)
                
                if let operation = task.task.getOperation() {
                    let operationRows = getOperationInfoRows(for: operation)
                    InfoCardView(title: "Operation", rows: operationRows)
                    
                    if let ticket = operation.getTicket() {
                        let ticketRows = getTicketInfoRows(for: ticket)
                        InfoCardView(title: "Ticket", rows: ticketRows)
                    }
                }
                
                let metadataRows = getMetadataRows(for: task.task)
                if !metadataRows.isEmpty {
                    InfoCardView(title: "Metadata", rows: metadataRows)
                }
            }
            .padding(.horizontal)
        }
    }
    
    func getGeneralInfoRows(for task: GlyTask) -> [InfoRowData] {
        var rows: [InfoRowData] = []
        rows.append(InfoRowData(label: "Description", value: task.getDescription()))

        if let operation = task.getOperation(),
           let ticket = operation.getTicket(),
           let destination = ticket.getDestination() {
            rows.append(InfoRowData(label: "Destination", value: destination.getName()))
            rows.append(InfoRowData(label: "Location", value: "\(destination.getLatitude()), \(destination.getLongitude())"))
         }

        rows.append(InfoRowData(label: "Agent ID", value: String(task.getAgentId())))
        rows.append(InfoRowData(label: "Foreign ID", value: task.getForeignId()))

        return rows
    }
    
    func getTimelineInfoRows(for task: GlyTask) -> [InfoRowData] {
        var rows: [InfoRowData] = []
        rows.append(InfoRowData(label: "Due Time", value: formatTime(epoch: task.getDueTime())))
        rows.append(InfoRowData(label: "Arrived Time", value: formatTime(epoch: task.getArrivedTime())))
        rows.append(InfoRowData(label: "Completed Time", value: formatTime(epoch: task.getCompletedTime())))

        return rows
    }
    
    func getOperationInfoRows(for operation: GlyOperation) -> [InfoRowData] {
        var rows: [InfoRowData] = []
        rows.append(InfoRowData(label: "Operation ID", value: String(operation.getId())))
        rows.append(InfoRowData(label: "State", value: String(operation.getState())))
        rows.append(InfoRowData(label: "Start Time", value: formatTime(epoch: operation.getStartTime())))

        return rows
    }
    
    func getTicketInfoRows(for ticket: GlyTicket) -> [InfoRowData] {
        var rows: [InfoRowData] = []
        rows.append(InfoRowData(label: "Ticket ID", value: ticket.getId()))
        rows.append(InfoRowData(label: "Travel Mode", value: getTravelMode(mode: ticket.getTravelMode()?.getMode())))
        rows.append(InfoRowData(label: "ETA", value: formatEta(msFromNow: ticket.getEta())))
        if let route = ticket.getRoute() {
            rows.append(InfoRowData(label: "Route Distance", value: String(route.getDistance())))
        }
        rows.append(InfoRowData(label: "Visibility", value: ticket.getVisibility().getString()))
        
        return rows
    }
    
    func getMetadataRows(for task: GlyTask) -> [InfoRowData] {
        var rows: [InfoRowData] = []
        if let metadata = task.getMetadata() {
            let count = metadata.count()
            for i in 0..<count {
                if let row = metadata[i] {
                    if let key = row.getStringWith("n"),
                       let value = row.getWith("v") {
                        rows.append(InfoRowData(label: key, value: value.asString()))
                    }
                }
            }
        }
        
        return rows
    }
    
    func getTravelMode(mode: Int32?) -> String {
        guard let mode = mode else {
            return "Unknown"
        }
        
        switch mode {
        case 0:
            return "Drive"
        case 1:
            return "Transit"
        case 2:
            return "Bike"
        case 3:
            return "Walk"
        default:
            return "Unknown"
        }
    }
    
    func formatTime(epoch: Int64?) -> String {
        guard let epoch = epoch, epoch > 0 else {
            return "Not set"
        }
        
        let dateFormat = DateFormatter()
        dateFormat.dateStyle = .long
        dateFormat.timeStyle = .long
        
        return dateFormat.string(from: Date(timeIntervalSince1970: TimeInterval(epoch) / 1000.0))
    }
    
    func formatEta(msFromNow: Int64?) -> String {
        guard let msFromNow = msFromNow, msFromNow > 0 else {
            return "Not set"
        }
        
        let dateFormat = DateFormatter()
        dateFormat.dateStyle = .long
        dateFormat.timeStyle = .long
        
        let now = Date()
        let secondsFromNow = Double(msFromNow) / 1000.0
        let etaTime = Date(timeIntervalSince1970: now.timeIntervalSince1970 + secondsFromNow)
        return dateFormat.string(from: etaTime)
    }
}

extension GlyPrimitive {
    func asString() -> String {
        switch self.type() {
        case GlyCoreConstants.primitive_TYPE_STRING():
            return self.getString()
        case GlyCoreConstants.primitive_TYPE_LONG():
            return String(self.getLong())
        case GlyCoreConstants.primitive_TYPE_DOUBLE():
            return String(self.getDouble())
        case GlyCoreConstants.primitive_TYPE_BOOLEAN():
            return String(self.getBool())
        default:
            return ""
        }
    }
}

struct InfoRowData: Hashable {
    let label: String
    let value: String?
}

struct InfoCardView: View {
    let title: String
    let rows: [InfoRowData?]

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            ForEach(rows.compactMap { $0 }, id: \.self) { row in
                InfoRowView(label: row.label, value: row.value)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
    }
}

struct InfoRowView: View {
    let label: String
    let value: String?

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value ?? "N/A")
                .font(.body)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
