import SwiftUI
#if canImport(UIKit)
import UIKit
#endif


struct ContentView: View {
      @ObservedObject private var authService = AuthService.shared
      @ObservedObject private var themeManager = ThemeManager.shared
      @ObservedObject private var accentColorManager = AccentColorManager.shared
      @StateObject private var viewModel = BookViewModel()
      @State private var capturedImage: UIImage?
      @State private var isShowingCamera = false
      @State private var selectedTab = 0
      @State private var showQuiz = false
      @State private var hasSeenQuizPrompt: Bool = false

      private var userInitials: String {
         let displayName = authService.currentUser?.displayName
         let email = authService.currentUser?.email
         let name = displayName ?? email ?? "?"
         if name == "?" { return "?" }
         let components = name.split(separator: " ")
         if components.count >= 2 {
             let firstInitial = components.first?.first?.uppercased() ?? ""
             let lastInitial = components.last?.first?.uppercased() ?? ""
             let initials = firstInitial + lastInitial
             return initials
         } else if let first = components.first?.first?.uppercased() {
             return first
         }
         return "?"
     }

     var body: some View {
         Group {
             if authService.isAuthenticated {
                 // For authenticated users, assume they have completed onboarding
                 // unless explicitly marked as not completed
                 if authService.hasCompletedOnboarding || authService.isLoadingOnboardingStatus {
                     if authService.currentUser?.hasTakenQuiz == true || hasSeenQuizPrompt {
                         authenticatedView
                     } else {
                         let userId = authService.currentUser?.id
                         QuizPromptView(
                             onTakeQuiz: {
                                 showQuiz = true
                                 hasSeenQuizPrompt = true
                                 if let uid = userId {
                                     UserDefaults.standard.set(true, forKey: "hasSeenQuizPrompt_\(uid)")
                                 }
                             },
                             onDoItLater: {
                                 hasSeenQuizPrompt = true
                                 if let uid = userId {
                                     UserDefaults.standard.set(true, forKey: "hasSeenQuizPrompt_\(uid)")
                                 }
                             }
                         )
                     }
                 } else {
                     OnboardingView()
                 }
             } else {
                 HomeView()
             }
         }
         .preferredColorScheme(themeManager.currentPreference.colorScheme)
         .onAppear {
             // Firebase is initialized in AppDelegate
             if let userId = authService.currentUser?.id {
                 hasSeenQuizPrompt = UserDefaults.standard.bool(forKey: "hasSeenQuizPrompt_\(userId)")
             }
         }
         .onChange(of: authService.isAuthenticated) { isAuthenticated in
             if isAuthenticated {
                 // User signed in, refresh data
                 viewModel.refreshData()
             } else {
                 // User signed out, clear local data
                 viewModel.books = []
             }
         }
    }


    private var selectedView: some View {
        Group {
            switch selectedTab {
            case 0:
                LibraryView(viewModel: viewModel, isShowingCamera: $isShowingCamera)
            case 1:
                ReadingView(viewModel: viewModel)
            case 2:
                DiscoverView(viewModel: viewModel)
            case 3:
                ProfileView(authService: authService)
            default:
                LibraryView(viewModel: viewModel, isShowingCamera: $isShowingCamera)
            }
        }
    }

    public var authenticatedView: some View {
        NavigationView {
            ZStack {
                selectedView
                    .background(AppleBooksColors.background)
                VStack {
                    Spacer()
                    LiquidGlassTabBar(selectedTab: $selectedTab)
                }
                .edgesIgnoringSafeArea(.bottom)

                // Survey modal overlay
                SurveyModalView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $isShowingCamera) {
            CameraView(capturedImage: $capturedImage, isShowingCamera: $isShowingCamera)
        }
        .fullScreenCover(isPresented: $showQuiz) {
            QuizView()
        }
        .onChange(of: isShowingCamera) { newValue in
        }
        .onChange(of: capturedImage) { newImage in
            if let image = newImage {
                viewModel.scanBookshelf(image: image)
                capturedImage = nil
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}