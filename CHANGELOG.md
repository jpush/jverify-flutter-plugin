## 3.2.0
+ 新增：支持 HarmonyOS Flutter-OH 插件平台，集成 `@jg/verify` 1.2.2。
+ 新增：初始化、网络检查、取 token、预取号、缓存管理、一键登录、授权页关闭和事件回调的 ArkTS 实现。
+ 新增：宿主 `Navigation/NavPathStack` 接入及生命周期日志，满足 1.2.2 移动登录页要求。
+ 新增：现有授权页 UI 字段的 HarmonyOS 映射，以及安全区、返回按钮尺寸、登录按钮颜色/圆角等 HarmonyOS-only 字段。
+ 新增：中国移动专用 `JVHarmonyCMUIConfig`，覆盖系统栏、灰度、对齐规则、disabled 登录按钮、checkbox、协议片段、Web、窗口模式、自定义登录页和登录确认弹窗。
+ 新增：HarmonyOS 通用授权页/隐私二次弹窗的受控 ArkUI 文字、按钮、图片控件，以及中国移动自定义页图片按钮；支持 media/URI/base64 图片、widget ID 点击回调与监听注销接口。
+ 新增：HarmonyOS `JVCustomWidget.harmonyToastText`，可在回调自定义控件点击时显示当前原生页面可见的 Toast。
+ 新增：中国移动号码节点 `numberWidth/numberHeight`、自定义登录页控件 `toastText` 和透明图片 Button 支持。
+ 兼容：HarmonyOS 不支持的短信与合规采集接口保持公共入口，返回 `code=-2` 或 warning，不伪造成功。
+ 修复：插件自动读取 HarmonyOS 系统安全区；补齐授权页返回键回调、移动协议 span、移动 UI 属性、旧登录回调清理和不支持参数 warning。
+ 示例：新增完整 `example/ohos` 宿主、资源、权限和构建说明；修正授权页纵向布局、号码/协议对齐、登录按钮位置、透明状态栏和隐私二次弹窗关闭图位置。
+ 测试：补充 HarmonyOS UI DTO/可点击图片控件、监听注销、公共 channel 契约、重复请求、SMS 不支持回调和回调路由测试。

## 3.1.9
+ 新增：适配 Flutter 的依赖管理更新，支持 iOS Swift Package Manager（SwiftPM）集成。
+ 变更：自 3.1.9 起，iOS（SwiftPM 和 CocoaPods）仅支持 iOS 15.0 及以上版本。

## 3.0.8
+ 优化：增加iOS UI属性agreementAlertViewShowWindow
## 3.0.7
+  优化：Android 使用jcore暂时固定使用4.9.1
## 3.0.6
+ 更新：Android 升级到3.4.0版本
+ 新增：同步iOS&Andoid UI配置至最新版
+ 更新：iOS 升级到3.2.7版本
## 3.0.4
+ 优化：修复iOS privacyNavTitleTextSize 字段对自定义协议隐私协议页面不生效的问题
## 3.0.3
+ 优化：修复bug
## 3.0.2
+ 优化：删除使用系统类R.drawable.class映射资源文件的使用方式
## 2.4.4
+ 新增：iOS 二次弹窗支持设置取消按钮
## 2.4.3
+ 优化：修复bug
+ 更新：iOS 升级到 3.2.1版本
## 2.4.1
+ 新增：新增一键登录失败可以选择跳转短信登录的功能
+ 优化：更新iOS最新极光原生SDK_3.2.0
## 2.3.9
+ 优化：修复bug
+ 优化：更新Android最新极光原生SDK_3.1.9
## 2.3.9
+ 优化：修复bug
## 2.3.8
+ 优化： 更新Android最新极光原生SDK_3.1.4
## 2.3.7
+ 优化： 更新Android最新极光原生SDK
## 2.3.6
+ 优化： 增加合规接口
## 2.3.5
+ 优化： fix
## 2.3.4
+ 优化： 增加setIsPrivacyViewDarkMode参数，协议页面是否支持暗黑模式
## 2.3.3
+ 优化： 修复Android的回调参数个数问题 修复setLogBtnBottomOffsetY不生效问题
## 2.3.2
+ 优化： 升级原生SDK iOS：3.1.2 android:3.1.1
## 2.3.1
+ 优化： 优化iOS代码，解决UI问题
## 2.3.0
+ 优化： Android/ios更新到极光原生SDK3.0.1
## 2.2.9
+ 优化： Android更新到2.9.7
## 2.2.7
+ 优化： iOS更新到2.9.3
## 2.2.6
+ 优化： Android更新到2.9.3
## 2.2.5
+ 优化： iOS原生SDK更新到2.7.9
## 2.2.4
+ 优化： Android更新到2.7.7
## 2.2.2
+ 优化： 修复iOS横竖屏锁定无效的问题
## 2.2.1
+ 优化： Android更新到2.7.6
## 2.2.0
+ 优化： ios 认证plug.m代码
+ 优化： iOS更新到2.7.6
## 2.1.9
+ 优化： ios 认证plug.m代码
+ 新增：授权界面视频背景
+ 新增：登录按钮字体加粗
+ 新增：登录按钮相对底部偏移量
+ 新增：隐私协议页面导航栏字体加粗
+ 新增：slogan相对底部偏移量
+ 新增：slogan字体加粗
+ 新增：手机号码字体加粗
+ 新增：隐私条款相对底部偏移量
+ 新增：隐私条款文字加粗
+ 新增：隐私条款文字下划线
+ 新增：logo相对底部偏移量
+ 新增：导航栏标题字体加粗
+ 新增：手机号码相对底部偏移量
## 2.1.8
+ 升级：android 认证 2.7.4,ios 2.7.5 
+ 升级：android Jcore 2.9.0
## 2.1.7
+ 插件兼容ios 2.7.4
## 2.1.6
+ 升级：android 认证 2.7.3,ios 2.7.4 
## 2.1.4
+ 修复：修复setup 接口不会回调问题
## 2.1.2
+ 升级：升级 android 认证 2.7.2 jcore 2.8.2，ios 2.7.1
## 2.1.0
+ 适配：适配 null safety
## 2.0.7
+ 修复：修复android gradle 升级4.0 以上版本编译问题
## 2.0.5
+ 新增：授权界面gif图片 authBGGifPath only android
+ 新增：授权界面动画 enterAnim  exitAnim  only android
+ 优化：升级认证版本 android 2.7.1，ios 2.7.0
## 2.0.3
+ 新增：setup 方法新增 setControlWifiSwitch 参数，默认为true
## 2.0.1
+ 新增：适配Flutter 2.0，flutter sdk 2.0以下版本请使用0.6.23。
## 0.6.23
+ 新增：适配认证 ios  SDK 2.6.7。
## 0.6.22
+ 新增：适配认证Android2.6.7 ios 2.6.6。
## 0.6.20
+ 新增：添加iOS 授权界面弹出方式 modelTransitionStyle。
## 0.6.18
+ 修复：修复ios needStartAnim needStartAnim 无效果的bug。
## 0.6.16
+ 修复：修复ios 添加多个点击事件，响应的都是同一个。
## 0.6.14
+ 优化：优化体验。
## 0.6.11
+ 优化：ios 在不选中认证协议的时候，设置是否显示toast提示。
## 0.6.10
+ 优化：jcore 2.2.5库获取不到的问题
## 0.6.9
+ 优化：优化android端隐私协议不选中时点击登录按钮，设置是否显示toast提示。具体使用查看 API 文档或者 demo 样例
## 0.6.8
+ 优化：优化android端隐私协议不选中时点击登录按钮，设置是否显示toast提示。
## 0.6.7
+ 修复：修复已知问题
## 0.6.6
+ 修复：修复已知问题
+ 同步 JVerification SDK ios 2.6.3 android 2.6.4 版本
## 0.6.5
+ 修复：ios隐私页面标题获取异常及navColor问题
## 0.6.4
+ 新增：授权页和隐私页状态栏样式
+ 新增：授权页弹出是否使用动画
+ 新增：设置前后两次获取验证码的时间间隔 [setSmsIntervalTime]
+ 新增：获取验证码 [getSmsCode] 具体使用查看 API 文档或者 demo 样例；
## 0.6.3
+ 修改文档
## 0.6.2
+ 同步 JVerification SDK 版本
+ 内部安全策略优化
## 0.6.1
+ 优化：Android 回调 flutter 的回调函数
+ 优化重复请求逻辑
## 0.6.0
+ 新增：SDK 初始化回调监听
+ 新增：授权页弹窗模式
+ 修复：授权页无法唤起问题
+ 同步 JVerification SDK 2.5.2 版本
## 0.5.2
+ 修复：授权登录回调通知 bug
## 0.5.1
+ 修复：iOS 授权页 loading 框位置偏移问题
+ 修复：iOS 授权页监听点击事件 bug
+ 同步 JVerification SDK 2.5.0 版本
## 0.5.0
+ 新增：一键登录的同步接口 [loginAuthSyncApi]
## 0.4.0
+ 新增：一键登录接口（loginAuth）返回数据支持添加监听获取 [addLoginAuthCallBackListener],具体使用查看 API 文档或者 demo 样例；
## 0.3.0
+ 新增：关闭授权页面接口
## 0.2.0
+ 新增：设置授权页背景图片
+ 新增：支持隐藏导航栏、返回按钮
## 0.1.0
+ 新增：SDK 清除预取号缓存接口
+ 新增：可设置横竖屏授权页接口
+ 新增：授权页点击事件监听
+ sdk 适配到 v2.4.8
## 0.0.5
+ fix
    1、修复：自定义 UI 时传入无资源的图片导致错误问题；
    2、修复：自定义 UI 时不传 widgets 导致错误问题；
    3、SDK 适配到 v2.3.6
## 0.0.4
+ fix
    1、新增：添加自定义 Textview 控件；
    2、新增：添加自定义 Button 控件；
    3、新增：设置协议勾选框默认状态属性；
    4、变更：自定义 UI 界面接口将使用新接口 [setCustomAuthViewAllWidgets],具体使用查看 API 文档或者 demo 样例；
## 0.0.3
+ fix
    1、修复与微信插件 fluwx 命名冲突问题；
## 0.0.2
+ fix
    1、适配最新版本的认证 SDK;
    2、修复 bug;
## 0.0.1

official release.
