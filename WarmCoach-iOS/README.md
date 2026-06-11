# WarmCoach iOS

SwiftUI 版私教排课 MVP。

## 运行

1. 用 Xcode 打开 `WarmCoach.xcodeproj`。
2. 选择 `WarmCoach` scheme。
3. 选择 iPhone 模拟器或真机运行。

当前工程最低支持 iOS 13.6。已通过真机目标编译检查：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project WarmCoach.xcodeproj -scheme WarmCoach -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

如果需要真机运行，请在 Signing & Capabilities 中选择你的 Apple Developer Team，并把 Bundle Identifier 改成自己的唯一 ID。注意：较新的 Xcode 可能无法给 iOS 13.6 真机挂载 Developer Disk Image；遇到这种情况，需要升级 iPhone 系统，或使用支持 iOS 13 设备调试的旧版 Xcode。

## 已实现

- 首页日程、即将开始课程、本周统计、冲突提醒
- 周课表与按天快速新增课程
- 会员列表、会员详情、新增/编辑会员
- 三步新增/编辑课程
- 课程状态：待上课、已完成、已取消、请假、补课、爽约
- UserDefaults 本地持久化
- UserNotifications 本地课程提醒
