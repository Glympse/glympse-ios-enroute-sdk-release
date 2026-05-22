import SwiftUI
import EnRouteApi

struct OrgInfoView: View {
    @State private var org: GlyOrganization?
    var body: some View {
        ScrollView(.vertical) {
            if let org = org {
                let generalRows = getGeneralInfoRows(for: org)
                InfoCardView(title: "General Information", rows: generalRows)
                
                let orgConfigRows = getOrgConfigRows(for: org.getConfig())
                InfoCardView(title: "Config", rows: orgConfigRows)
            }
        }
        .padding(.horizontal)
        .onAppear {
            self.org = enrouteWrapper.enroute?.getOrganization()
        }
    }
    
    func getGeneralInfoRows(for org: GlyOrganization) -> [InfoRowData] {
        var rows: [InfoRowData] = []
        rows.append(InfoRowData(label: "Name", value: org.getName()))
        rows.append(InfoRowData(label: "Referrer ID", value: String(org.getReferrerOrgId())))
        rows.append(InfoRowData(label: "Admin Email", value: org.getAdminEmail()))

        return rows
    }
    
    func getOrgConfigRows(for config: GlyOrgConfig) -> [InfoRowData] {
        var rows: [InfoRowData] = []
        rows.append(InfoRowData(label: "Shifts Enabled", value: String(config.areShiftsEnabled())))
        rows.append(InfoRowData(label: "Arrival Phase", value: config.getArrivalPhase()))
        rows.append(InfoRowData(label: "Branding ID", value: config.getBrandingId()))
        rows.append(InfoRowData(label: "Completion Phases", value: joinToString(config.getCompletionPhases())))
        rows.append(InfoRowData(label: "Default Travel Mode", value: config.getDefaultTravelMode()))
        rows.append(InfoRowData(label: "Final Phase", value: config.getFinalPhase()))
        rows.append(InfoRowData(label: "Initial Phase", value: config.getInitialPhase()))
        rows.append(InfoRowData(label: "Initial Tracking Phase", value: config.getInitialTrackingPhase()))
        rows.append(InfoRowData(label: "Photo Upload Enabled", value: String(config.isPhotoUploadEnabled())))
        rows.append(InfoRowData(label: "Pickup Mode", value: String(config.isPickupEnabled())))
        rows.append(InfoRowData(label: "Session Mode", value: String(config.isSessionModeEnabled())))
        rows.append(InfoRowData(label: "Signature Upload Enabled", value: String(config.isSignatureUploadEnabled())))
        rows.append(InfoRowData(label: "Picker Disabled Task Phases", value: joinToString(config.getPickerDisabledTaskPhases())))

        return rows
    }
}

func joinToString(_ array: GlyArray<NSString>, separator: String = ", ") -> String {
    var joinedString: String = ""
    for i in 0..<array.count() {
        let item = array.object(at: i)
        if let stringValue = item as? String {
            joinedString.append(stringValue)
        }
        if i != array.count() - 1 {
            joinedString.append(separator)
        }
    }
    return joinedString
}
