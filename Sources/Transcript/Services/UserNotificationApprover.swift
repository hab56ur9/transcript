import UserNotifications

@MainActor
final class UserNotificationApprover: NSObject {
    private var pending: CheckedContinuation<Bool, Never>?

    func requestApproval() async -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return false }
        registerCategory(in: center)
        resolve(approved: false)
        try? await center.add(approvalRequest())
        return await withCheckedContinuation { pending = $0 }
    }

    private func resolve(approved: Bool) {
        pending?.resume(returning: approved)
        pending = nil
    }

    private func registerCategory(in center: UNUserNotificationCenter) {
        let start = UNNotificationAction(identifier: "transcript.start", title: "녹음 시작")
        let category = UNNotificationCategory(
            identifier: "transcript.approval",
            actions: [start],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        center.setNotificationCategories([category])
    }

    private func approvalRequest() -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "녹음 승인 요청"
        content.body = "전사 녹음 시작 요청이 도착했습니다. 시작하려면 눌러주세요."
        content.categoryIdentifier = "transcript.approval"
        content.sound = .default
        return UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    }
}

extension UserNotificationApprover: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let approved = response.actionIdentifier != UNNotificationDismissActionIdentifier
        Task { @MainActor in
            self.resolve(approved: approved)
            completionHandler()
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
