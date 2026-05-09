import SwiftUI
import UIKit
import MessageUI

// =============================================================================
//  FeedbackComposeSheet
//  -----------------------------------------------------------------------------
//  Replaces the previous `openURL("mailto:...")` flow which silently fails on
//  the simulator and on devices without Apple Mail configured.
//
//  Two branches:
//    • `MFMailComposeViewController.canSendMail() == true`
//      → present Apple Mail composer inline. Recipient, subject, and body
//        are pre-filled. User can edit, send, or cancel.
//
//    • else (simulator / no Mail account)
//      → present an instrument-styled fallback that lets the user:
//          - copy the recipient email to clipboard
//          - copy the full pre-filled message to clipboard
//          - open the message in Gmail web
//          - open the message in Outlook web
//
//  Use it like:
//      .sheet(isPresented: $showingFeedback) {
//          FeedbackComposeSheet(
//              recipient: NoJetLagContact.feedbackEmail,
//              subject: "NoJetLag — feedback",
//              messageBody: "..."
//          )
//      }
// =============================================================================

struct FeedbackComposeSheet: View {
    let recipient: String
    let subject: String
    let messageBody: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if MFMailComposeViewController.canSendMail() {
                // Native iOS Mail composer takes over the entire sheet — that
                // is the iOS-native UX users expect.
                MailComposeView(
                    recipient: recipient,
                    subject: subject,
                    messageBody: messageBody
                ) { _ in
                    dismiss()
                }
                .ignoresSafeArea()
            } else {
                FallbackComposeView(
                    recipient: recipient,
                    subject: subject,
                    messageBody: messageBody
                )
            }
        }
    }
}

// MARK: - UIKit bridge for Mail composer

private struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let messageBody: String
    let onComplete: (MFMailComposeResult) -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.setMessageBody(messageBody, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onComplete: (MFMailComposeResult) -> Void

        init(onComplete: @escaping (MFMailComposeResult) -> Void) {
            self.onComplete = onComplete
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true) { [onComplete] in
                onComplete(result)
            }
        }
    }
}

// MARK: - Fallback: simulator / no Mail account

private struct FallbackComposeView: View {
    let recipient: String
    let subject: String
    let messageBody: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var toast: ToastKind?

    enum ToastKind: String {
        case email = "EMAIL COPIED"
        case message = "MESSAGE COPIED"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg0.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        statusBanner
                        recipientCard
                        subjectCard
                        bodyCard
                        actions
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .navigationTitle("FEEDBACK")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CLOSE") { dismiss() }
                        .font(Typography.mono(11, weight: .semibold))
                        .foregroundStyle(Color.textLo)
                }
            }
            .overlay(alignment: .bottom) { toastOverlay }
        }
    }

    // MARK: - Pieces

    private var statusBanner: some View {
        InstrumentCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(Color.advisoryRed)
                        .frame(width: 6, height: 6)
                    Text("MAIL UNAVAILABLE")
                        .font(Typography.mono(10, weight: .semibold))
                        .trackedUppercase(1.6)
                        .foregroundStyle(Color.advisoryRed)
                }
                Text("No Mail account configured (or you're on the simulator). Use one of the options below to deliver the message.")
                    .font(Typography.body(13))
                    .foregroundStyle(Color.textMid)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var recipientCard: some View {
        InstrumentCard(padding: 0) {
            Button(action: copyEmail) {
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TO")
                            .font(Typography.mono(10, weight: .semibold))
                            .trackedUppercase(1.6)
                            .foregroundStyle(Color.textLo)
                        Text(recipient)
                            .font(Typography.mono(14, weight: .medium))
                            .foregroundStyle(Color.textHi)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    Spacer(minLength: 0)
                    Text("COPY")
                        .font(Typography.mono(10, weight: .semibold))
                        .trackedUppercase(1.6)
                        .foregroundStyle(Color.amber)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var subjectCard: some View {
        InstrumentCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("SUBJECT")
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.textLo)
                Text(subject)
                    .font(Typography.body(14, weight: .medium))
                    .foregroundStyle(Color.textHi)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var bodyCard: some View {
        InstrumentCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("BODY")
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.textLo)
                Text(messageBody)
                    .font(Typography.body(13))
                    .foregroundStyle(Color.textMid)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: Spacing.sm) {
            Button(action: copyMessage) {
                Text("COPY MESSAGE").trackedUppercase(1.4)
            }
            .buttonStyle(.instrument)

            Button { openInGmail() } label: {
                Text("OPEN IN GMAIL WEB").trackedUppercase(1.4)
            }
            .buttonStyle(.instrumentSecondary)

            Button { openInOutlook() } label: {
                Text("OPEN IN OUTLOOK WEB").trackedUppercase(1.4)
            }
            .buttonStyle(.instrumentSecondary)
        }
        .padding(.top, Spacing.sm)
    }

    @ViewBuilder
    private var toastOverlay: some View {
        if let toast {
            HStack(spacing: Spacing.sm) {
                Circle().fill(Color.amber).frame(width: 6, height: 6)
                Text(toast.rawValue)
                    .font(Typography.mono(10, weight: .semibold))
                    .trackedUppercase(1.6)
                    .foregroundStyle(Color.textHi)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(Color.bg1)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .stroke(Color.stroke, lineWidth: 1)
                    )
            )
            .padding(.bottom, Spacing.xl)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    // MARK: - Actions

    private func copyEmail() {
        UIPasteboard.general.string = recipient
        flash(.email)
    }

    private func copyMessage() {
        let composed = """
        To: \(recipient)
        Subject: \(subject)

        \(messageBody)
        """
        UIPasteboard.general.string = composed
        flash(.message)
    }

    private func openInGmail() {
        let allowed = CharacterSet.urlQueryAllowed
        let su = subject.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let bd = messageBody.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let url = URL(string: "https://mail.google.com/mail/?view=cm&fs=1&to=\(recipient)&su=\(su)&body=\(bd)")
        if let url { openURL(url) }
    }

    private func openInOutlook() {
        let allowed = CharacterSet.urlQueryAllowed
        let su = subject.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let bd = messageBody.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let url = URL(string: "https://outlook.office.com/mail/deeplink/compose?to=\(recipient)&subject=\(su)&body=\(bd)")
        if let url { openURL(url) }
    }

    private func flash(_ kind: ToastKind) {
        withAnimation(.easeOut(duration: 0.2)) { toast = kind }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) { toast = nil }
        }
    }
}
