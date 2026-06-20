import AppKit
@preconcurrency import ApplicationServices
import Observation
import OSLog

struct AccessibilitySelection {
    let text: String
    let focusedWindowFrame: CGRect?
}

@MainActor
protocol AccessibilityTextProviding {
    var isTrusted: Bool { get }
    func requestTrustPrompt()
    func currentSelection() -> AccessibilitySelection?
}

@MainActor
@Observable
final class AccessibilityTextProvider: AccessibilityTextProviding {
    private struct ExtractedSelection {
        let text: String
        let method: String
    }

    private enum WebAttribute {
        static let selectedTextMarkerRange = "AXSelectedTextMarkerRange"
        static let stringForTextMarkerRange = "AXStringForTextMarkerRange"
        static let attributedStringForTextMarkerRange = "AXAttributedStringForTextMarkerRange"
    }

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "RSVPIsland",
        category: "Accessibility"
    )

    private(set) var isTrusted: Bool

    init() {
        isTrusted = AXIsProcessTrusted()
    }

    func refreshTrustStatus() {
        isTrusted = AXIsProcessTrusted()
    }

    func requestTrustPrompt() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
        refreshTrustStatus()
    }

    func currentSelection() -> AccessibilitySelection? {
        refreshTrustStatus()
        let application = NSWorkspace.shared.frontmostApplication
        let applicationName = application?.localizedName ?? "unknown"
        let bundleIdentifier = application?.bundleIdentifier ?? "unknown"
        Self.logger.info(
            "Reading selection from app=\(applicationName, privacy: .public) bundle=\(bundleIdentifier, privacy: .public) trusted=\(self.isTrusted)"
        )

        guard isTrusted else {
            Self.logger.error("Accessibility access is not trusted")
            return nil
        }

        guard let application else {
            Self.logger.error("Could not resolve the frontmost application")
            return nil
        }

        let applicationElement = AXUIElementCreateApplication(application.processIdentifier)
        let system = AXUIElementCreateSystemWide()
        let focusedElements = [
            copyElement(kAXFocusedUIElementAttribute, from: system),
            copyElement(kAXFocusedUIElementAttribute, from: applicationElement)
        ].compactMap { $0 }

        let focusedWindow = copyElement(kAXFocusedWindowAttribute, from: applicationElement)
            ?? copyElement(kAXMainWindowAttribute, from: applicationElement)
            ?? copyElements(kAXWindowsAttribute, from: applicationElement).first
        let windowFrame = focusedWindow.flatMap(frame)

        for focused in focusedElements {
            let role = role(of: focused)
            Self.logger.info("Trying focused element role=\(role, privacy: .public)")
            if let selection = extractSelection(from: focused, probeStandardAttributes: true) {
                return makeSelection(selection, windowFrame: windowFrame)
            }
        }

        if focusedElements.isEmpty {
            Self.logger.info("No focused Accessibility element; scanning the active window")
        } else {
            Self.logger.info("Focused element had no selection; scanning the active window")
        }

        guard let focusedWindow else {
            Self.logger.error("Could not resolve an Accessibility window to scan")
            return nil
        }
        guard let selection = findSelection(in: focusedWindow) else {
            Self.logger.info("No selected text found through Accessibility")
            return nil
        }
        return makeSelection(selection, windowFrame: windowFrame)
    }

    private func makeSelection(
        _ selection: ExtractedSelection,
        windowFrame: CGRect?
    ) -> AccessibilitySelection {
        Self.logger.info(
            "Captured \(selection.text.count) characters using \(selection.method, privacy: .public)"
        )
        return AccessibilitySelection(text: selection.text, focusedWindowFrame: windowFrame)
    }

    private func findSelection(in root: AXUIElement) -> ExtractedSelection? {
        let maximumElements = 4_000
        let maximumDepth = 30
        var queue: [(element: AXUIElement, depth: Int)] = [(root, 0)]
        var cursor = 0
        var scanned = 0
        var webAreas = 0

        while cursor < queue.count, scanned < maximumElements {
            let item = queue[cursor]
            cursor += 1
            scanned += 1

            let elementRole = role(of: item.element)
            if elementRole == "AXWebArea" {
                webAreas += 1
            }
            if let selection = extractSelection(from: item.element) {
                Self.logger.info(
                    "Window scan succeeded after \(scanned) elements; role=\(elementRole, privacy: .public) webAreas=\(webAreas)"
                )
                return selection
            }

            if item.depth < maximumDepth {
                let remainingCapacity = maximumElements - queue.count
                if remainingCapacity > 0 {
                    queue.append(contentsOf: copyElements(kAXChildrenAttribute, from: item.element)
                        .prefix(remainingCapacity)
                        .map { ($0, item.depth + 1) })
                }
            }
        }

        Self.logger.info(
            "Window scan completed without selection; scanned=\(scanned) webAreas=\(webAreas) queued=\(queue.count)"
        )
        return nil
    }

    private func extractSelection(
        from element: AXUIElement,
        probeStandardAttributes: Bool = false
    ) -> ExtractedSelection? {
        if copyValue(kAXSubroleAttribute, from: element) as? String == (kAXSecureTextFieldSubrole as String) {
            return nil
        }

        let attributes = attributeNames(of: element)
        if probeStandardAttributes || attributes.contains(kAXSelectedTextAttribute as String),
           let text = normalized(copyValue(kAXSelectedTextAttribute, from: element) as? String) {
            return ExtractedSelection(text: text, method: "AXSelectedText")
        }

        if attributes.contains(WebAttribute.selectedTextMarkerRange),
           let markerRange = copyValue(WebAttribute.selectedTextMarkerRange, from: element) {
            if let text = normalized(parameterizedValue(
                WebAttribute.stringForTextMarkerRange,
                parameter: markerRange,
                from: element
            ) as? String) {
                return ExtractedSelection(text: text, method: "web text-marker range")
            }
            if let value = parameterizedValue(
                WebAttribute.attributedStringForTextMarkerRange,
                parameter: markerRange,
                from: element
            ), CFGetTypeID(value) == CFAttributedStringGetTypeID() {
                let attributedString = value as! NSAttributedString
                if let text = normalized(attributedString.string) {
                    return ExtractedSelection(text: text, method: "web attributed text-marker range")
                }
            }
        }

        if (probeStandardAttributes || attributes.contains(kAXSelectedTextRangeAttribute as String)),
           let value = copyValue(kAXValueAttribute, from: element) as? String,
           let rangeValue = copyValue(kAXSelectedTextRangeAttribute, from: element),
           CFGetTypeID(rangeValue) == AXValueGetTypeID() {
            var range = CFRange()
            if AXValueGetValue(rangeValue as! AXValue, .cfRange, &range),
               range.location >= 0,
               range.length > 0,
               range.location + range.length <= (value as NSString).length {
                let text = (value as NSString).substring(
                    with: NSRange(location: range.location, length: range.length)
                )
                if let text = normalized(text) {
                    return ExtractedSelection(text: text, method: "AXValue plus AXSelectedTextRange")
                }
            }
        }
        return nil
    }

    private func normalized(_ text: String?) -> String? {
        guard let text else { return nil }
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }

    private func role(of element: AXUIElement) -> String {
        copyValue(kAXRoleAttribute, from: element) as? String ?? "unknown"
    }

    private func attributeNames(of element: AXUIElement) -> Set<String> {
        var names: CFArray?
        guard AXUIElementCopyAttributeNames(element, &names) == .success,
              let names = names as? [String] else { return [] }
        return Set(names)
    }

    private func parameterizedValue(
        _ attribute: String,
        parameter: CFTypeRef,
        from element: AXUIElement
    ) -> CFTypeRef? {
        var value: CFTypeRef?
        let error = AXUIElementCopyParameterizedAttributeValue(
            element,
            attribute as CFString,
            parameter,
            &value
        )
        guard error == .success else {
            let errorDescription = describe(error)
            Self.logger.info(
                "Parameterized Accessibility query failed: attribute=\(attribute, privacy: .public) error=\(errorDescription, privacy: .public)"
            )
            return nil
        }
        return value
    }

    private func frame(of window: AXUIElement) -> CGRect? {
        guard let positionValue = copyValue(kAXPositionAttribute, from: window),
              let sizeValue = copyValue(kAXSizeAttribute, from: window),
              CFGetTypeID(positionValue) == AXValueGetTypeID(),
              CFGetTypeID(sizeValue) == AXValueGetTypeID() else { return nil }
        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &position),
              AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) else { return nil }
        return CGRect(origin: position, size: size)
    }

    private func copyElement(
        _ attribute: String,
        from element: AXUIElement,
        logFailure: Bool = false
    ) -> AXUIElement? {
        copyValue(attribute, from: element, logFailure: logFailure).flatMap {
            guard CFGetTypeID($0) == AXUIElementGetTypeID() else { return nil }
            return ($0 as! AXUIElement)
        }
    }

    private func copyElements(_ attribute: String, from element: AXUIElement) -> [AXUIElement] {
        guard let values = copyValue(attribute, from: element) as? [Any] else { return [] }
        return values.compactMap { value in
            let value = value as CFTypeRef
            guard CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
            return (value as! AXUIElement)
        }
    }

    private func copyValue(
        _ attribute: String,
        from element: AXUIElement,
        logFailure: Bool = false
    ) -> CFTypeRef? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard error == .success else {
            if logFailure {
                let errorDescription = describe(error)
                Self.logger.error(
                    "Accessibility query failed: attribute=\(attribute, privacy: .public) error=\(errorDescription, privacy: .public)"
                )
            }
            return nil
        }
        return value
    }

    private func describe(_ error: AXError) -> String {
        let name = switch error {
        case .success: "success"
        case .failure: "failure"
        case .illegalArgument: "illegalArgument"
        case .invalidUIElement: "invalidUIElement"
        case .invalidUIElementObserver: "invalidUIElementObserver"
        case .cannotComplete: "cannotComplete"
        case .attributeUnsupported: "attributeUnsupported"
        case .actionUnsupported: "actionUnsupported"
        case .notificationUnsupported: "notificationUnsupported"
        case .notImplemented: "notImplemented"
        case .notificationAlreadyRegistered: "notificationAlreadyRegistered"
        case .notificationNotRegistered: "notificationNotRegistered"
        case .apiDisabled: "apiDisabled"
        case .noValue: "noValue"
        case .parameterizedAttributeUnsupported: "parameterizedAttributeUnsupported"
        case .notEnoughPrecision: "notEnoughPrecision"
        @unknown default: "unknown"
        }
        return "\(name) (\(error.rawValue))"
    }
}
