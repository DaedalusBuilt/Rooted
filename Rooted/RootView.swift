import SwiftUI

struct RootView: View {
    @EnvironmentObject var accountManager: AccountManager

    var body: some View {
            if let _ = accountManager.currentUser {
                ContentView() // No need to pass accountManager
            } else {
                LoginView() // No need to pass accountManager
            }
        }
    }



