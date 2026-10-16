import SwiftUI

struct VandaagView: View {
    var body: some View {
        NavigationStack {
            TakenLijstView(weergave: .vandaag)
        }
    }
}

#Preview {
    VandaagView()
        .modelContainer(Voorbeeld.container)
        .environment(\.locale, Datums.taal)
}
