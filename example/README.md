# JVerify Flutter Example

这个目录是可运行的 Flutter example 根目录。HarmonyOS 构建命令在本目录执行；`../ohos` 是插件原生 HAR module，不能单独运行。

## HarmonyOS

1. 使用 Flutter-OH，而不是普通 Flutter SDK。
2. 在 DevEco Studio 中为 `ohos/AppScope/app.json5` 的 bundleName 配置本地调试签名。开发测试可临时保留本机真实签名；Git 提交和 pub 发布前必须删除签名路径、证书信息和密码。
3. 使用极光控制台中与该 bundleName 匹配的 HarmonyOS AppKey；本 example 在 `lib/main.dart` 的 `_ohosAppKey` 中按平台硬编码。
4. 连接设备并确认 `hdc list targets -v` 显示 `Connected/Online`，而不是 `Offline`。
5. 执行：

```bash
flutter clean
rm -f ohos/har/jverify.har # 修改 ArkTS/oh-package 后执行
flutter pub get
flutter build hap --debug
# 或
flutter run
```

仓库内 example 默认通过远端开发分支验证插件，而不是读取父目录源码：

```yaml
dependencies:
  jverify:
    git:
      url: https://github.com/jpush/jverify-flutter-plugin.git
      ref: dev-3.x
```

因此必须先把插件提交并推送到 `dev-3.x`，再执行 `flutter pub get`。如需调试尚未推送的本地 ArkTS/Dart 改动，可临时改回 `path: ../`，但不要把临时路径依赖作为远端集成验证结果。

宿主页面 `ohos/entry/src/main/ets/pages/Index.ets` 创建并挂载 `NavPathStack`，再通过 `JverifyNavigation` 交给插件。这是 `@jg/verify` 1.2.2 移动登录页的必需条件。

原生代码或 OHPM 依赖变化后要冷构建。本机 Flutter-OH 3.22.3-ohos 实测 `flutter clean` 不会删除 `ohos/har/jverify.har`，因此 ArkTS/oh-package 变化后需要显式删除该生成文件，再由 `flutter build hap` 重新生成；不要把它复制到源码或提交到 Git/pub。

页面提供初始化状态、网络能力、取 token、预取号/缓存、一键登录和关闭授权页。HarmonyOS 一键登录配置同时演示通用授权页自定义文字和可点击 Image、隐私二次弹窗中不遮挡 SDK 登录按钮的自定义“取消”按钮，以及中国移动默认号码/登录页、登录确认弹窗和单一透明图片 Button；控件通过 widget ID 回调 Flutter，页面销毁时注销 listener。通用纯 callback 控件使用 `harmonyToastText`，移动图片 Button 使用 `toastText`，点击后由原生页面显示 Toast。中国移动 example 还演示号码节点居中、登录按钮下移、checkbox/协议相对对齐，以及透明状态栏配合深色系统栏内容。示例图片来自 `ohos/AppScope/resources/base/media`，实际项目也可改用 URI/base64。HarmonyOS 不支持 SMS 的兼容契约继续由插件实现和自动化测试覆盖，不在 example 页面展示无业务意义的按钮。

通用授权页直接参考 `harmony-verify-sdk/JVerificationProject` 源码 Demo：SDK 非 Stack 模式是顺序 `Column`，Logo 的 150 vp 上边距负责首段下移，号码/slogan/登录按钮使用相对上一控件的 `7/7/22 vp` 间距，不得当作屏幕绝对 Y 坐标。隐私栏距底部 100 vp。二次弹窗使用源码 Demo 的 300×240 vp 结构：SDK 登录按钮 `top=30`；源码 Demo 的取消按钮 `top=80/left=100` 会因 ArkUI `Stack` 的 margin 整体居中规则产生重叠，example 按真机结果校正为居中 `top=130`，与登录按钮保留约 12 vp 间距。浅色背景 `jverify_login_test_back` 也直接来自该源码 Demo。

example 不再手工传安全区：插件设置 UI 时读取当前 HarmonyOS Window 的 `TYPE_SYSTEM` 避让区并换算为 vp；窗口不可用时顶部才使用 44 vp 兜底。顶部按钮使用深色 `jverify_nav_close`，Logo 使用 `app_icon`。

## iOS（Swift Package Manager）

示例的 iOS Deployment Target 为 15.6。首次拉取、`flutter clean` 或重新 `flutter pub get` 后，从 Xcode 启动前执行：

```bash
flutter pub get
flutter build ios --config-only
open ios/Runner.xcworkspace
```

不要修改或提交 `ios/Flutter/ephemeral/`。

## Android

Android 原生 SDK 不读取 Dart `setup(appKey:)`，而是读取 `android/app/build.gradle` 中硬编码的 `JPUSH_APPKEY`：

```groovy
JPUSH_APPKEY: "你的AndroidAppKey"
```

三个 Key 互相独立：Android 修改 `android/app/build.gradle` 的 `JPUSH_APPKEY`，iOS 修改 `lib/main.dart` 的 `_iosAppKey`，HarmonyOS 修改同一文件的 `_ohosAppKey`。Dart 根据当前系统选择 iOS 或 HarmonyOS Key，不需要配置 `--dart-define`。
