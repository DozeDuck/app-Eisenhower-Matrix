import SwiftUI

struct IOSSettingsView: View {
    @AppStorage(IOSHomeLayoutStyle.storageKey)
    private var layoutStyleRaw = IOSHomeLayoutStyle.list.rawValue

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

            Section("App") {
                LabeledContent("名称", value: "森豪威尔矩阵")
                LabeledContent("版本", value: "1.0")
            }

            Section("数据") {
                Text("当前版本的任务数据保存在本机。卸载 App 会删除本地数据。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("关于四象限") {
                Text("四象限方法帮助你按照重要性和紧急性安排任务：先处理重要且紧急，持续推进重要但不紧急，减少低价值干扰。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("设置")
    }

    private var selectedLayoutStyle: IOSHomeLayoutStyle {
        IOSHomeLayoutStyle(rawValue: layoutStyleRaw) ?? .list
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
}
