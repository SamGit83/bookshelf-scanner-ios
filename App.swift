import SwiftUI
import FirebaseCore

@main
struct BookshelfScannerApp: App {
    init() {
        // Configure Firebase with your project details
        let options = FirebaseOptions(googleAppID: "1:244176711240:ios:0448a40563dbcd22bd727d",
                                    gcmSenderID: "244176711240")
        options.apiKey = "AIzaSyBLobo6IH1MTQY5n04PCqI-BvRL2ZMaWfE"
        options.projectID = "bookshelf-scanner-ios"
        options.storageBucket = "bookshelf-scanner-ios.firebasestorage.app"

        FirebaseApp.configure(options: options)
    }

    var body: some Scene {
        WindowGroup {
            BookshelfWrapperView()
        }
    }
}