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
      ref: dev-3.0.1
```

+ pub 集成

```
dependencies:
  jverify: 3.0.1 
```

### 配置

##### Android:

在 `/android/app/build.gradle` 中添加下列代码：

```groovy
android: {
  ....

    manifestPlaceholders = [
            // 设置manifest.xml中的变量
            JPUSH_PKGNAME: applicationId,
            JPUSH_APPKEY : "1b5965ba23557bcf384e0b08",  //  JPush 上注册的包名对应的 AppKey.
            JPUSH_CHANNEL: "default_developer", // 默认值即可.
    ]
 
  }

```

### 使用

```dart
import 'package:jverify/jverify.dart';
```

### APIs

**注意** : 需要先调用 Jverify.setup 来初始化插件，才能保证其他功能正常工作。

[参考](./documents/APIs.md)
