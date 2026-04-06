import SwiftUI
import AppKit

struct ContentView: View {
    @State private var input = ""
    @State private var output = ""
    @State private var selectedOp: Operation = .base64Encode
    @State private var errorMessage: String?
    @State private var showCopied = false
    @State private var splitFraction = 0.4

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedOp) {
                ForEach(OperationCategory.allCases) { category in
                    Section(category.displayName) {
                        ForEach(category.operations) { op in
                            Text(op.displayName)
                                .tag(op)
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
        } detail: {
            GeometryReader { geo in
                let buttonsHeight: CGFloat = 36
                let dividerHeight: CGFloat = 8
                let spacing: CGFloat = 12
                let padding: CGFloat = 16
                let chrome = buttonsHeight + dividerHeight + spacing * 4 + padding * 2
                let available = max(geo.size.height - chrome, 100)
                let inputHeight = available * splitFraction
                let outputHeight = available * (1 - splitFraction)

                VStack(spacing: spacing) {
                    GroupBox {
                        TextEditor(text: $input)
                            .font(.system(.body, design: .monospaced))
                    } label: {
                        Text("Input").bold()
                    }
                    .frame(height: inputHeight)

                    // Draggable divider
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: dividerHeight)
                        .onHover { inside in
                            if inside {
                                NSCursor.resizeUpDown.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 1)
                                .onChanged { value in
                                    let startY = value.startLocation.y + inputHeight
                                    let currentY = startY + value.translation.height
                                    let newFraction = currentY / available
                                    splitFraction = min(max(newFraction, 0.15), 0.85)
                                }
                        )

                    HStack(spacing: 8) {
                        Spacer()

                        Button("Transform") { runTransform() }
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut(.return, modifiers: .command)

                        Button("Clear") {
                            input = ""
                            output = ""
                            errorMessage = nil
                            showCopied = false
                        }
                    }
                    .frame(height: buttonsHeight)

                    GroupBox {
                        ZStack(alignment: .topTrailing) {
                            ReadOnlyTextView(text: output)

                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(output, forType: .string)
                                showCopied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showCopied = false
                                }
                            } label: {
                                Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            }
                            .disabled(output.isEmpty)
                            .padding(6)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Output").bold()
                            if let err = errorMessage {
                                Text("— \(err)")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                    .frame(height: outputHeight)
                }
                .padding()
            }
        }
        .frame(minWidth: 700, idealWidth: 820, minHeight: 540)
    }

    private func runTransform() {
        errorMessage = nil
        showCopied = false
        switch selectedOp.transform(input) {
        case .success(let result):
            output = result
        case .failure(let error):
            output = ""
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Selectable, non-editable text view

struct ReadOnlyTextView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: .greatestFiniteMagnitude
        )

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }
}
