import AppKit

@MainActor
struct AlertApprover {
    func requestApproval() -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "녹음 승인 요청"
        alert.informativeText = "전사 녹음 시작 요청이 도착했습니다. 시작할까요?"
        alert.addButton(withTitle: "녹음 시작")
        alert.addButton(withTitle: "취소")
        return alert.runModal() == .alertFirstButtonReturn
    }
}
