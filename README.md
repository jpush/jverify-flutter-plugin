[![QQ Group](https://img.shields.io/badge/QQ%20Group-862401307-red.svg)]()
# JVerify Flutter Plugin

### 安装

在工程 pubspec.yaml 中加入 dependencies

+ github 集成 

``` 
dependencies:
  jverify:
    git:
      url: git://github.com/jpush/jverify-flutter-plugin.git
      ref: dev-3.x
```

+ pub 集成

```
dependencies:
  jverify: 2.3.6
```

### 配置

##### Android:

在 `/android/app/build.gradle` 中添加下列代码：

```groovy
android: {
  ....
  defaultConfig {
    applicationId "替换成自己应用 ID"
    ...
    ndk {
	//选择要添加的对应 cpu 类型的 .so 库。
	abiFilters 'armeabi', 'armeabi-v7a', 'x86', 'x86_64', 'mips', 'mips64', 'arm64-v8a',        
    }

    manifestPlaceholders = [
        JPUSH_PKGNAME : applicationId,
        JPUSH_APPKEY : "appkey", // NOTE: JPush 上注册的包名对应的 Appkey.
        JPUSH_CHANNEL : "developer-default", //暂时填写默认值即可.
    ]
  }    
}
```

##### iOS:

- 自 `3.1.9` 起，为适配 Flutter 的依赖管理更新，插件支持 Swift Package Manager（SwiftPM）集成；Flutter 3.44 及以上版本默认使用 SwiftPM。
- `3.1.9` 及以上版本无论使用 SwiftPM 还是 CocoaPods，均仅支持 iOS 15.0 及以上版本。集成前请将 App 的 iOS 最低部署版本设为 15.0 或更高。
- 插件会自动解析并链接 `JCore` 和 `JVerification`；同一 iOS Target 中请勿再通过其他包管理方式重复引入这两个 SDK。

### 使用

```dart
import 'package:jverify/jverify.dart';
```

### APIs

**注意** : 需要先调用 Jverify.setup 来初始化插件，才能保证其他功能正常工作。

 [参考](./documents/APIs.md)
