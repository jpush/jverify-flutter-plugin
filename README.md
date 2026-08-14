[![QQ Group](https://img.shields.io/badge/QQ%20Group-862401307-red.svg)]()

# JVerify Flutter Plugin

极光 JVerification Flutter 插件，支持 Android、iOS 和 HarmonyOS。

| 平台 | 原生 SDK | 最低要求 |
| --- | --- | --- |
| Android | JVerification Android SDK | 以 Android 工程配置为准 |
| iOS | JVerification iOS SDK | iOS 15.0+ |
| HarmonyOS | `@jg/verify` 1.2.2 | Flutter-OH 3.22.3-ohos、HarmonyOS SDK 5.0.0(12)+ |

## 安装

```yaml
dependencies:
  jverify: ^3.2.0
```

开发分支也可直接使用 Git：

```yaml
dependencies:
  jverify:
    git:
      url: https://github.com/jpush/jverify-flutter-plugin.git
      ref: dev-3.x
```

## Android

在应用的 `android/app/build.gradle` 中配置应用 AppKey 和 channel：

```groovy
android {
  defaultConfig {
    manifestPlaceholders = [
      JPUSH_PKGNAME: applicationId,
      JPUSH_APPKEY: "你的 AppKey",
      JPUSH_CHANNEL: "developer-default",
    ]
  }
}
```

## iOS

3.1.9 起支持 Swift Package Manager 和 CocoaPods，最低 iOS 版本均为 15.0。首次拉取、`flutter clean` 或重新 `flutter pub get` 后，从 Xcode 启动前执行：

```bash
cd example
flutter pub get
flutter build ios --config-only
open ios/Runner.xcworkspace
```

不要提交 `ios/Flutter/ephemeral/`；该目录由 Flutter 生成。

## HarmonyOS

### 1. 工具链

普通 Flutter SDK 不支持 `flutter create --platforms ohos`。开发和构建 HarmonyOS 必须使用 Flutter-OH；`FLUTTER_OH_HOME` 只是本文建议的自定义变量，值应指向实际 Flutter-OH SDK 根目录，而不是 DevEco Studio 或项目目录。

macOS 示例：

```bash
export FLUTTER_OH_HOME="/path/to/flutter_flutter"
export TOOL_HOME="/Applications/DevEco-Studio.app/Contents"
export HOS_SDK_HOME="$TOOL_HOME/sdk"
export DEVECO_SDK_HOME="$TOOL_HOME/sdk"
export NODE_HOME="$TOOL_HOME/tools/node"
export PATH="$TOOL_HOME/tools/node/bin:$TOOL_HOME/tools/ohpm/bin:$TOOL_HOME/tools/hvigor/bin:$FLUTTER_OH_HOME/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
```

保留 `/usr/bin:/bin`，否则 `ohpm` 脚本会找不到 `sed`、`dirname` 和 `uname`。可把上述内容写入当前 shell 对应的 `~/.zshrc` 或 `~/.bash_profile`。

验证：

```bash
flutter --version
flutter doctor -v
ohpm --version
```

### 2. 宿主工程要求

HarmonyOS 1.2.2 的移动认证页强制依赖已挂载的 `Navigation/NavPathStack`。宿主 `example/ohos/entry/src/main/ets/pages/Index.ets` 展示了接入方式：

```ts
@Provide('jverifyNavPathStack') navPathStack: NavPathStack = new NavPathStack();

aboutToAppear(): void {
  JverifyNavigation.attachNavPathStack(this.navPathStack, this);
}

build() {
  Navigation(this.navPathStack) {
    FlutterPage({ viewId: this.viewId });
  }
}
```

仅在插件内部创建但没有挂载到 `Navigation` 的栈不可用。插件在 `loginAuth` 前会检查宿主栈，缺失时返回结构化错误，不会伪造导航栈。

还需要：

- 在极光控制台创建与 HarmonyOS `bundleName` 对应的应用并使用其 AppKey。
- 按 `example/ohos/entry/src/main/module.json5` 配置网络权限。
- 在 DevEco Studio 为自己的 bundleName 配置本地调试签名；证书、profile 和密码不得提交。
- UI 图片使用 HarmonyOS media 资源名，不要传本机绝对路径。

### 3. 构建 example

命令必须在 Flutter example 根目录执行，而不是在插件 `ohos/` module 内执行：

```bash
cd example
flutter clean
# 当前 Flutter-OH 的 clean 不会删除旧的插件 HAR；ArkTS 改动后应显式删除
rm -f ohos/har/jverify.har
flutter pub get
flutter build hap --debug
# 或连接设备后
flutter run
```

Flutter-OH 会先把根插件的 `ohos/` 编译成 HAR，再把 `jverify.har` 与 `flutter.har` 放到 example 的 `ohos/har/` 中，最后由 Hvigor 构建 HAP。本次实测该 Flutter-OH 版本的 `flutter clean` 不会删除旧 `jverify.har`；修改 ArkTS 后应先删除这一个可重建文件，避免旧 HAR 被继续引用。HAR、HAP、`oh_modules`、`.hvigor` 都是生成物，不应提交。

如果同一工作区刚被普通 Flutter SDK 执行过 `pub get/test/analyze`，应在 HarmonyOS 构建前重新使用 Flutter-OH 执行 `flutter pub get`，避免 `.dart_tool/package_config.json` 指向另一套 Flutter SDK。

### 4. 能力说明

HarmonyOS 已实现初始化、网络检查、取 token、预取号、缓存管理、一键登录、授权页关闭和授权页事件。UI 按运营商明确区分：中国移动使用独立 UI Builder，联通/电信使用通用 UI Builder；中国移动特有属性、自定义登录页/文字/图片按钮通过类型化 `JVHarmonyCMUIConfig` 配置，其中 `numberWidth/numberHeight` 可配合对齐规则控制号码节点尺寸，`systemBar` 可设置透明状态栏和内容颜色。`JVCustomWidget` 会转换成受控 ArkUI `Text`、`Button` 或 `Image`，可用于通用授权页和隐私二次弹窗；图片支持 media 资源名或 URI/base64，按钮和图片均保留 widget ID 点击回调。通用控件使用 `harmonyToastText`、移动自定义登录页控件使用 `toastText` 提供原生 Toast 反馈；图片 Button 支持透明背景。未显式配置安全区时，插件自动读取 HarmonyOS 系统避让区。各字段的最终支持范围见 `documents/APIs.md`。

HarmonyOS 原生 SDK 目前没有短信验证码/短信登录以及 `setCollectionAuth` 对应能力。为保持 Flutter 公共 API 一致，这些入口仍可调用：Future/callback 接口返回 `code = -2`，void 接口输出 warning 并正常结束，不会伪造成功。

## 使用

```dart
import 'package:jverify/jverify.dart';

final jverify = Jverify();
jverify.setDebugMode(true);
jverify.setup(appKey: '你的 AppKey', channel: 'developer-default');
```

完整 API 和 UI 字段说明见 [documents/APIs.md](documents/APIs.md)，可运行调用顺序见 [example/lib/main.dart](example/lib/main.dart)。

## 官方资料

- [华为：Flutter 与鸿蒙三方库 ohos 的适配](https://developer.huawei.com/consumer/cn/blog/topic/03188763091797012)
- [华为：Flutter-OH Package 与 Plugin 的区别](https://developer.huawei.com/consumer/cn/blog/topic/03206365458227127)
- [华为：HAR/HSP 共享包引用与管理](https://developer.huawei.com/consumer/cn/doc/doccenter-deveco-studio/ide-har-import)
- [华为：HarmonyOS 应用程序包术语（HAP/HAR/HSP）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-package-glossary)
- [华为：DevEco Terminal 环境变量](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-environment-variable)
- [华为：build-profile.json5 与签名配置](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/ide-hvigor-build-profile-V5)
- [极光：JVerification SDK 资源下载](https://docs.jiguang.cn/jverification/resources)
