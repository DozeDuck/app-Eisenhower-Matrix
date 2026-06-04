//
//  IOSSettingsView.swift
//  QuadrantTasksIOS
//

import SwiftUI
import SwiftData

struct IOSSettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage(IOSHomeLayoutStyle.storageKey)
    private var layoutStyleRaw = IOSHomeLayoutStyle.list.rawValue

    @State private var colorBlindModeEnabled = false

    private var appGroupDefaults: UserDefaults {
        UserDefaults(suiteName: AppGroupConfig.groupID) ?? .standard
    }

    private var selectedLayoutStyle: IOSHomeLayoutStyle {
        IOSHomeLayoutStyle(rawValue: layoutStyleRaw) ?? .list
    }

    private var selectedColorVisionMode: ColorVisionMode {
        colorBlindModeEnabled ? .colorBlindSafe : .standard
    }

    var body: some View {
        List {
            Section("首页布局") {
                Picker("显示方式", selection: $layoutStyleRaw) {
                    ForEach(IOSHomeLayoutStyle.allCases) { style in
                        Label(style.title, systemImage: style.systemImage)
                            .tag(style.rawValue)
                    }
                }
                .pickerStyle(.inline)

                layoutDescription
            }

            Section("显示辅助") {
                Toggle(isOn: colorBlindModeBinding) {
                    Label("色盲友好模式", systemImage: "eye")
                }

                colorVisionDescription
            }

            Section("App") {
                LabeledContent("名称", value: AppInfo.displayName)
                LabeledContent("版本", value: AppInfo.version)
            }

            Section("隐私") {
                if let url = URL(string: AppInfo.privacyPolicyURLString) {
                    Link(destination: url) {
                        Label("隐私政策", systemImage: "hand.raised")
                    }
                }

                Text("当前版本不需要登录，不使用广告，不使用第三方分析。任务数据默认保存在本机。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("数据") {
                Text("当前版本的任务数据保存在本机。卸载 App 会删除本地数据。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("关于方法") {
                Text("本 App 使用四象限方法帮助你判断任务优先级。你可以先处理重要且紧急的任务，持续推进重要但不紧急的任务，并减少低价值干扰。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("设置")
        .onAppear {
            loadColorBlindMode()
        }
    }

    private var colorBlindModeBinding: Binding<Bool> {
        Binding(
            get: {
                colorBlindModeEnabled
            },
            set: { newValue in
                colorBlindModeEnabled = newValue

                let newMode: ColorVisionMode = newValue ? .colorBlindSafe : .standard

                appGroupDefaults.set(
                    newMode.rawValue,
                    forKey: ColorVisionMode.storageKey
                )

                appGroupDefaults.synchronize()

                NotificationCenter.default.post(
                    name: .colorVisionModeDidChange,
                    object: nil
                )

                refreshWidgetSnapshot()
            }
        )
    }

    private var layoutDescription: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: selectedLayoutStyle.systemImage)
                .foregroundStyle(.blue)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(selectedLayoutStyle.title)
                    .font(.subheadline.weight(.semibold))

                Text(selectedLayoutStyle.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var colorVisionDescription: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: selectedColorVisionMode == .colorBlindSafe ? "eye.fill" : "paintpalette")
                .foregroundStyle(.blue)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(selectedColorVisionMode.title)
                    .font(.subheadline.weight(.semibold))

                Text(selectedColorVisionMode.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                quadrantColorPreview
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }

    private var quadrantColorPreview: some View {
        HStack(spacing: 8) {
            ForEach(Quadrant.allCases) { quadrant in
                HStack(spacing: 4) {
                    Image(systemName: quadrant.iconName)
                        .font(.caption2)

                    Text(quadrant.actionTitle)
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(quadrant.color(for: selectedColorVisionMode))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(quadrant.color(for: selectedColorVisionMode).opacity(0.13))
                )
            }
        }
    }

    private func loadColorBlindMode() {
        let raw = appGroupDefaults.string(forKey: ColorVisionMode.storageKey)
            ?? ColorVisionMode.standard.rawValue

        colorBlindModeEnabled = raw == ColorVisionMode.colorBlindSafe.rawValue
    }

    private func refreshWidgetSnapshot() {
        #if os(iOS)
        WidgetDataService.refreshSnapshot(context: modelContext)
        #endif
    }
}
