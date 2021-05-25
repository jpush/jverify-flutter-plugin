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
