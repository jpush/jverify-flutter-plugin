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
      ref: master
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

- Starting with `3.1.9`, the plugin supports Swift Package Manager (SwiftPM) in response to Flutter's dependency-management update. Flutter 3.44 and later use SwiftPM by default.
- `3.1.9` and later support iOS 15.0 or later only, whether the project uses SwiftPM or CocoaPods. Set the app's iOS deployment target to 15.0 or later before integrating.
- The plugin resolves and links `JCore` and `JVerification` automatically. Do not add either SDK through another package manager in the same iOS target.

### 使用

```dart
import 'package:jverify/jverify.dart';
```

### APIs

**注意** : 需要先调用 Jverify.setup 来初始化插件，才能保证其他功能正常工作。

 [参考](./documents/APIs.md)
