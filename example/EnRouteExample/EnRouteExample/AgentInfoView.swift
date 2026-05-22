import SwiftUI
import EnRouteApi

struct AgentInfoView: View {
    @State private var agent: GlyAgent?
    var body: some View {
        ScrollView(.vertical) {
            if let agent = agent {
                let generalRows = getGeneralInfoRows(for: agent)
                InfoCardView(title: "General Information", rows: generalRows)
                
                Button("Logout") {
                    enrouteWrapper.enroute?.logout(GlyEnRouteConstants.logout_REASON_USER_ACTION())
                }
                .padding(8)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal)
        .onAppear {
            self.agent = enrouteWrapper.enroute?.getSelfAgent()
        }
    }
    
    func getGeneralInfoRows(for agent: GlyAgent) -> [InfoRowData] {
        var rows: [InfoRowData] = []
        rows.append(InfoRowData(label: "Display Name", value: agent.getDisplayName()))
        rows.append(InfoRowData(label: "Name", value: agent.getName()))
        rows.append(InfoRowData(label: "Email", value: agent.getEmail()))
        rows.append(InfoRowData(label: "Roles", value: joinToString(agent.getRoles())))

        return rows
    }
}
