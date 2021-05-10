import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 监听添加的自定义控件的点击事件
typedef JVClickWidgetEventListener = void Function(String widgetId);

/// 授权页事件回调
///
/// @since 2.4.0
typedef JVAuthPageEventListener = void Function(JVAuthPageEvent event);

/// 一键登录接口的回调监听
///
/// [event] 回调事件
///
/// 返回 Map：
///   code     ：返回码，6000 代表 loginToken 获取成功，6001 代表 loginToken 获取失败，其他返回码详见描述
///   message  ：返回码的解释信息，若获取成功，内容信息代表 loginToken。
///   operator ：成功时为对应运营商，CM 代表中国移动，CU 代表中国联通，CT 代表中国电信。失败时可能为 null。
///
/// @discussion 调用 loginAuth 接口后，可以通过添加此监听事件来监听接口的返回结果
typedef JVLoginAuthCallBackListener = void Function(JVListenerEvent event);

/// SDK 初始接口回调监听
///
/// [event] 回调事件
///
/// 返回 Map：
///   code     ：返回码，8000 代表初始化成功，其他为失败，详见错误码描述
///   message  ：返回码的解释信息，若获取成功，内容信息代表loginToken。
///
/// @discussion 调用 setup 接口后，可以通过添加此监听事件来监听接口的返回结果
typedef JVSDKSetupCallBackListener = void Function(JVSDKSetupEvent event);

class JVEventHandlers {
  static final JVEventHandlers _instance = JVEventHandlers._internal();

  JVEventHandlers._internal();

  factory JVEventHandlers() => _instance;

  Map<String, JVClickWidgetEventListener> clickEventsMap = Map();
  List<JVAuthPageEventListener> authPageEvents = [];
  List<JVLoginAuthCallBackListener> loginAuthCallBackEvents = [];
  JVSDKSetupCallBackListener? sdkSetupCallBackListener;
}

class Jverify {
  static const String flutter_log = '| JVER | Flutter | ';

  /// 错误码
  static const String j_flutter_code_key = 'code';

  /// 回调的提示信息
  static const String j_flutter_msg_key = 'message';

  /// 重复请求
  static const int j_flutter_error_code_repeat = -1;

  factory Jverify() => _instance;
  final JVEventHandlers _eventHandlers = JVEventHandlers();

  final MethodChannel _channel;
  final List<String> requestQueue = [];

  @visibleForTesting
  Jverify.private(MethodChannel channel) : _channel = channel;

  static final _instance = Jverify.private(const MethodChannel('jverify'));

  /// 自定义控件的点击事件
  addClickWidgetEventListener(
    String eventId,
    JVClickWidgetEventListener callback,
  ) {
    _eventHandlers.clickEventsMap[eventId] = callback;
  }

  /// 授权页的点击事件
  ///
  /// @since v2.4.0
  addAuthPageEventListener(JVAuthPageEventListener callback) {
    _eventHandlers.authPageEvents.add(callback);
  }

  /// loginAuth 接口回调的监听
  addLoginAuthCallBackListener(JVLoginAuthCallBackListener callback) {
    _eventHandlers.loginAuthCallBackEvents.add(callback);
  }

  /// SDK 初始化回调监听
  addSDKSetupCallBackListener(JVSDKSetupCallBackListener callback) {
    _eventHandlers.sdkSetupCallBackListener = callback;
  }

  Future<void> _handlerMethod(MethodCall call) async {
    print('handleMethod method = ${call.method}');
    switch (call.method) {
      case 'onReceiveClickWidgetEvent':
        {
          String widgetId = call.arguments.cast<dynamic, dynamic>()['widgetId'];
          bool isContains = _eventHandlers.clickEventsMap.containsKey(widgetId);
          if (isContains) {
            JVClickWidgetEventListener cb =
                _eventHandlers.clickEventsMap[widgetId]!;
            cb(widgetId);
          }
        }
        break;
      case 'onReceiveAuthPageEvent':
        {
          for (JVAuthPageEventListener cb in _eventHandlers.authPageEvents) {
            Map json = call.arguments.cast<dynamic, dynamic>();
            JVAuthPageEvent ev = JVAuthPageEvent.fromJson(json);
            cb(ev);
          }
        }
        break;
      case 'onReceiveLoginAuthCallBackEvent':
        {
          for (JVLoginAuthCallBackListener cb
              in _eventHandlers.loginAuthCallBackEvents) {
            Map json = call.arguments.cast<dynamic, dynamic>();
            JVListenerEvent event = JVListenerEvent.fromJson(json);
            cb(event);
            _eventHandlers.loginAuthCallBackEvents.remove(cb);
          }
        }
        break;
      case 'onReceiveSDKSetupCallBackEvent':
        {
          if (_eventHandlers.sdkSetupCallBackListener != null) {
            Map json = call.arguments.cast<dynamic, dynamic>();
            JVSDKSetupEvent event = JVSDKSetupEvent.fromJson(json);
            _eventHandlers.sdkSetupCallBackListener!(event);
          }
        }
        break;
      default:
        throw UnsupportedError('Unrecognized Event');
    }
    return;
  }

  Map<dynamic, dynamic>? isRepeatRequest({required String method}) {
    bool isContain = requestQueue.any((element) => (element == method));
    if (isContain) {
      Map map = {
        j_flutter_code_key: j_flutter_error_code_repeat,
        j_flutter_msg_key: method + ' is requesting, please try again later.'
      };
      print(flutter_log + map.toString());
      return map;
    } else {
      requestQueue.add(method);
      return null;
    }
  }

  /// 初始化, [timeout] 单位毫秒，合法范围是 (0,30000]，
  /// 推荐设置为 5000-10000，默认值为 10000
  void setup({
    required String appKey,
    String? channel,
    bool? useIDFA,
    int timeout = 10000,
    bool setControlWifiSwitch = true,
  }) {
    print('$flutter_log' + 'setup');

    _channel.setMethodCallHandler(_handlerMethod);

    _channel.invokeMethod("setup", {
      "appKey": appKey,
      "channel": channel,
      "useIDFA": useIDFA,
      "timeout": timeout,
      "setControlWifiSwitch": setControlWifiSwitch,
    });
  }

  /// 设置 debug 模式
  void setDebugMode(bool debug) {
    print('$flutter_log' + 'setDebugMode');
    _channel.invokeMethod('setDebugMode', {'debug': debug});
  }

  /// 设置前后两次获取验证码的时间间隔，默认 30000ms，有效范围(0,300000)
  void setGetCodeInternal(int intervalTime) {
    print('$flutter_log' + 'setGetCodeInternal');
    _channel.invokeMethod('setGetCodeInternal', {'timeInterval': intervalTime});
  }

  /// SDK 获取短信验证码
  ///
  /// 返回 Map：
  ///   key = 'code', value = 状态码，3000代表获取成功
  ///   key = 'message', 提示信息
  ///   key = 'result', uuid
  Future<Map<dynamic, dynamic>> getSMSCode({
    required String phoneNum,
    String? signId,
    String? tempId,
  }) async {
    print('$flutter_log' + 'getSMSCode');

    var args = <String, String>{
      'phoneNumber': phoneNum,
      if (signId != null) 'signId': signId,
      if (tempId != null) 'tempId': tempId,
    };
    return await _channel.invokeMethod('getSMSCode', args);
  }

  /// 获取 SDK 初始化是否成功标识
  ///
  /// 返回 Map：
  ///   key = 'result'
  ///   value = bool,是否成功
  Future<Map<dynamic, dynamic>> isInitSuccess() async {
    print('$flutter_log' + 'isInitSuccess');
    return await _channel.invokeMethod('isInitSuccess');
  }

  /// SDK 判断网络环境是否支持
  ///
  /// 返回 Map：
  ///   key = 'result'
  ///   value = bool, 是否支持
  Future<Map<dynamic, dynamic>> checkVerifyEnable() async {
    print('$flutter_log' + 'checkVerifyEnable');
    return await _channel.invokeMethod('checkVerifyEnable');
  }

  /// SDK 获取号码认证 token
  ///
  /// 返回 Map：
  ///   key = 'code', value = 状态码，2000 代表获取成功
  ///   key = 'message', value = 成功即为 token，失败为提示
  Future<Map<dynamic, dynamic>> getToken({String? timeOut}) async {
    print('$flutter_log' + 'getToken');

    String method = 'getToken';
    var repeatError = isRepeatRequest(method: method);
    if (repeatError == null) {
      var para = {'timeOut': timeOut};
      para.remove((key, value) => value == null);
      var result = await _channel.invokeMethod(method, para);
      requestQueue.remove(method);
      return result;
    } else {
      return repeatError;
    }
  }

  /// SDK 一键登录预取号, [timeOut] 有效取值范围 [3000,10000]
  ///
  /// 返回 Map：
  ///   key = 'code', value = 状态码，7000 代表获取成功
  ///   key = 'message', value = 结果信息描述
  Future<Map<dynamic, dynamic>> preLogin({int timeOut = 10000}) async {
    var para = Map();
    if (timeOut >= 3000 && timeOut <= 10000) {
      para['timeOut'] = timeOut;
    }
    print('$flutter_log' + 'preLogin' + '$para');

    String method = 'preLogin';
    var repeatError = isRepeatRequest(method: method);
    if (repeatError == null) {
      var result = await _channel.invokeMethod(method, para);
      requestQueue.remove(method);
      return result;
    } else {
      return repeatError;
    }
  }

  /// SDK 清除预取号缓存
  ///
  /// @discussion 清除 sdk 当前预取号结果缓存
  ///
  /// @since v2.4.3
  void clearPreLoginCache() {
    print('$flutter_log' + 'clearPreLoginCache');
    _channel.invokeMethod('clearPreLoginCache');
  }

  /// SDK请求授权一键登录（异步接口）
  ///
  /// [autoDismiss]  设置登录完成后是否自动关闭授权页
  /// [timeout]      设置超时时间，单位毫秒。 合法范围（0，30000],范围以外默认设置为 10000
  ///
  /// 异步返回 Map :
  ///   key = 'code', value = 6000 代表 loginToken 获取成功
  ///   key = message, value = 返回码的解释信息，若获取成功，内容信息代表 loginToken
  ///
  /// @discussion since SDK v2.4.0，授权页面点击事件监听：通过添加 [JVAuthPageEventListener] 监听，来监听授权页点击事件
  Future<Map<dynamic, dynamic>> loginAuth(
    bool autoDismiss, {
    int timeout = 10000,
  }) async {
    print('$flutter_log' + 'loginAuth');

    String method = 'loginAuth';
    var repeatError = isRepeatRequest(method: method);
    if (repeatError == null) {
      var map = {'autoDismiss': autoDismiss, 'timeout': timeout};
      var result = await _channel.invokeMethod(method, map);
      requestQueue.remove(method);
      return result;
    } else {
      return repeatError;
    }
  }

  /// SDK请求授权一键登录（同步接口）
  ///
  /// [autoDismiss]  设置登录完成后是否自动关闭授权页
  /// [timeout]      设置超时时间，单位毫秒。 合法范围（0，30000]，范围以外默认设置为 10000
  ///
  /// 接口回调返回数据监听：通过添加 [JVLoginAuthCallBackListener] 监听，来监听接口的返回结果
  ///
  /// 授权页面点击事件监听：通过添加 [JVAuthPageEventListener] 监听，来监听授权页点击事件
  void loginAuthSyncApi({required bool autoDismiss, int timeout = 10000}) {
    print('$flutter_log' + 'loginAuthSyncApi');

    String method = 'loginAuthSyncApi';
    var repeatError = isRepeatRequest(method: method);
    if (repeatError == null) {
      var map = {'autoDismiss': autoDismiss, 'timeout': timeout};
      _channel.invokeMethod(method, map);
      requestQueue.remove(method);
    } else {
      print('$flutter_log' + repeatError.toString());
    }
  }

  /// 关闭授权页面
  void dismissLoginAuthView() {
    print(flutter_log + 'dismissLoginAuthView');
    _channel.invokeMethod('dismissLoginAuthView');
  }

  /// 设置授权页面
  ///
  /// [isAutorotate]    是否支持横竖屏，true:支持横竖屏，false：只支持竖屏
  /// [portraitConfig]  竖屏的 UI 配置
  /// [landscapeConfig] Android 横屏的 UI 配置，只有当 isAutorotate=true 时必须传，并且该配置只生效在 Android，iOS 使用 portraitConfig 的约束适配横屏
  /// [widgets]         自定义添加的控件
  void setCustomAuthorizationView(
    bool isAutorotate,
    JVUIConfig portraitConfig, {
    JVUIConfig? landscapeConfig,
    List<JVCustomWidget>? widgets,
  }) {
    if (isAutorotate == true) {
      if (landscapeConfig == null) {
        print('missing Android landscape ui config');
        return;
      }
    }

    var para = Map();
    para['isAutorotate'] = isAutorotate;

    var para1 = portraitConfig.toJsonMap();
    para1.removeWhere((key, value) => value == null);
    para['portraitConfig'] = para1;

    if (landscapeConfig != null) {
      var para2 = landscapeConfig.toJsonMap();
      para2.removeWhere((key, value) => value == null);
      para['landscapeConfig'] = para2;
    }

    if (widgets != null) {
      var widgetList = [];
      for (JVCustomWidget widget in widgets) {
        var para2 = widget.toJsonMap();
        para2.removeWhere((key, value) => value == null);

        widgetList.add(para2);
      }
      para['widgets'] = widgetList;
    }

    _channel.invokeMethod('setCustomAuthorizationView', para);
  }

  /// （不建议使用，建议使用 [setCustomAuthorizationView] 接口）
  /// 自定义授权页面，界面原始控件、新增自定义控件
  void setCustomAuthViewAllWidgets(
    JVUIConfig uiConfig, {
    List<JVCustomWidget>? widgets,
  }) {
    var para = Map();

    var para1 = uiConfig.toJsonMap();
    para1.removeWhere((key, value) => value == null);
    para['uiconfig'] = para1;

    if (widgets != null) {
      var widgetList = [];
      for (JVCustomWidget widget in widgets) {
        var para2 = widget.toJsonMap();
        para2.removeWhere((key, value) => value == null);

        widgetList.add(para2);
      }
      para['widgets'] = widgetList;
    }

    _channel.invokeMethod('setCustomAuthViewAllWidgets', para);
  }
}

/// 自定义 UI 界面配置类
///
/// Y 轴
///   iOS      以导航栏底部为 0 作为起点
///   Android  以导航栏底部为 0 作为起点
/// X 轴
///   iOS      以屏幕中心为 0 作为起点，往屏幕左侧则减，往右侧则加，如果不传或者传 null，则默认屏幕居中
///   Android  以屏幕左侧为 0 作为起点，往右侧则加，如果不传或者传 null，则默认屏幕居中
class JVUIConfig {
  /// 授权页背景图片
  String? authBackgroundImage;
  String? authBGGifPath; // 授权界面 gif 图片，仅 Android

  /// 导航栏
  int? navColor;
  String? navText;
  int? navTextColor;
  String? navReturnImgPath;
  bool navHidden = false;
  bool navReturnBtnHidden = false;
  bool navTransparent = false;

  /// logo
  int? logoWidth;
  int? logoHeight;
  int? logoOffsetX;
  int? logoOffsetY;
  JVIOSLayoutItem? logoVerticalLayoutItem;
  bool? logoHidden;
  String? logoImgPath;

  /// 号码
  int? numberColor;
  int? numberSize;
  int? numFieldOffsetX;
  int? numFieldOffsetY;
  int? numberFieldWidth;
  int? numberFieldHeight;
  JVIOSLayoutItem? numberVerticalLayoutItem;

  /// slogan
  int? sloganOffsetX;
  int? sloganOffsetY;
  JVIOSLayoutItem? sloganVerticalLayoutItem;
  int? sloganTextColor;
  int? sloganTextSize;
  int? sloganWidth;
  int? sloganHeight;

  bool sloganHidden = false;

  /// 登录按钮
  int? logBtnOffsetX;
  int? logBtnOffsetY;
  int? logBtnWidth;
  int? logBtnHeight;
  JVIOSLayoutItem? logBtnVerticalLayoutItem;
  String? logBtnText;
  int? logBtnTextSize;
  int? logBtnTextColor;
  String? logBtnBackgroundPath;
  String? loginBtnNormalImage; // 仅 iOS
  String? loginBtnPressedImage; // 仅 iOS
  String? loginBtnUnableImage; // 仅 iOS

  /// 隐私协议栏
  String? uncheckedImgPath;
  String? checkedImgPath;
  int? privacyCheckboxSize;
  bool privacyHintToast = true; // 设置隐私条款不选中时点击登录按钮默认弹出toast。
  bool privacyState = false; // 设置隐私条款默认选中状态，默认不选中
  bool privacyCheckboxHidden = false; // 设置隐私条款checkbox是否隐藏
  bool privacyCheckboxInCenter = false; // 设置隐私条款checkbox是否相对协议文字纵向居中

  int? privacyOffsetY; // 隐私条款相对于授权页面底部下边缘 y 偏移
  int? privacyOffsetX; // 隐私条款相对于屏幕左边 x 轴偏移
  JVIOSLayoutItem privacyVerticalLayoutItem = JVIOSLayoutItem.ItemSuper;
  String? clauseName; // 协议1 名字
  String? clauseUrl; // 协议1 URL
  String? clauseNameTwo; // 协议2 名字
  String? clauseUrlTwo; // 协议2 URL
  int? clauseBaseColor;
  int? clauseColor;
  List<String>? privacyText;
  int? privacyTextSize;
  bool privacyWithBookTitleMark = true; // 设置隐私条款运营商协议名是否加书名号
  bool privacyTextCenterGravity = false; // 隐私条款文字是否居中对齐（默认左对齐）

  /// 隐私协议 web 页 UI 配置
  int? privacyNavColor; // 导航栏颜色
  int? privacyNavTitleTextColor; // 标题颜色
  int? privacyNavTitleTextSize; // 标题大小
  String? privacyNavTitleTitle; // 协议0 web页面导航栏标题（仅 iOS）
  String? privacyNavTitleTitle1; // 协议1 web页面导航栏标题
  String? privacyNavTitleTitle2; // 协议2 web页面导航栏标题
  String? privacyNavReturnBtnImage;
  JVIOSBarStyle? privacyStatusBarStyle; //隐私协议web页 状态栏样式设置（仅 iOS）

  /// 隐私页
  bool privacyStatusBarColorWithNav = false; // 隐私页web状态栏是否与导航栏同色（仅 Android）
  bool privacyStatusBarDarkMode = false; // 隐私页web状态栏是否暗色（仅 Android）
  bool privacyStatusBarTransparent = false; // 隐私页web页状态栏是否透明（仅 Android）
  bool privacyStatusBarHidden = false; // 隐私页web页状态栏是否隐藏 only（仅 Android）
  bool privacyVirtualButtonTransparent = false; // 隐私页web页虚拟按键背景是否透明（仅 Android）

  /// 授权页
  bool statusBarColorWithNav = false; //授权页状态栏是否跟导航栏同色（仅 Android）
  bool statusBarDarkMode = false; //授权页状态栏是否为暗色（仅 Android）
  bool statusBarTransparent = false; //授权页栏状态栏是否透明（仅 Android）
  bool statusBarHidden = false; //授权页状态栏是否隐藏（仅 Android）
  bool virtualButtonTransparent = false; //授权页虚拟按键背景是否透明（仅 Android）

  /// 授权页状态栏样式设置（仅 iOS）
  JVIOSBarStyle authStatusBarStyle = JVIOSBarStyle.StatusBarStyleDefault;

  ///是否需要动画
  bool needStartAnim = false; //设置拉起授权页时是否需要显示默认动画
  bool needCloseAnim = false; //设置关闭授权页时是否需要显示默认动画
  String? enterAnim; // 拉起授权页时进入动画 only android
  String? exitAnim; // 退出授权页时动画 only android

  /// 授权页弹窗模式 配置，选填
  JVPopViewConfig? popViewConfig;

  /// 弹出方式（仅 iOS）
  JVIOSUIModalTransitionStyle modelTransitionStyle =
      JVIOSUIModalTransitionStyle.CoverVertical;

  Map toJsonMap() {
    return {
      'authBackgroundImage': authBackgroundImage,
      'authBGGifPath': authBGGifPath,
      'navColor': navColor,
      'navText': navText,
      'navTextColor': navTextColor,
      'navReturnImgPath': navReturnImgPath,
      'navHidden': navHidden,
      'navReturnBtnHidden': navReturnBtnHidden,
      'navTransparent': navTransparent,
      'logoImgPath': logoImgPath,
      'logoWidth': logoWidth,
      'logoHeight': logoHeight,
      'logoOffsetY': logoOffsetY,
      'logoOffsetX': logoOffsetX,
      'logoVerticalLayoutItem': getStringFromEnum(logoVerticalLayoutItem),
      'logoHidden': logoHidden,
      'numberColor': numberColor,
      'numberSize': numberSize,
      'numFieldOffsetY': numFieldOffsetY,
      'numFieldOffsetX': numFieldOffsetX,
      'numberFieldWidth': numberFieldWidth,
      'numberFieldHeight': numberFieldHeight,
      'numberVerticalLayoutItem': getStringFromEnum(numberVerticalLayoutItem),
      'logBtnText': logBtnText,
      'logBtnOffsetY': logBtnOffsetY,
      'logBtnOffsetX': logBtnOffsetX,
      'logBtnWidth': logBtnWidth,
      'logBtnHeight': logBtnHeight,
      'logBtnVerticalLayoutItem': getStringFromEnum(logBtnVerticalLayoutItem),
      'logBtnTextSize': logBtnTextSize,
      'logBtnTextColor': logBtnTextColor,
      'logBtnBackgroundPath': logBtnBackgroundPath,
      'loginBtnNormalImage': loginBtnNormalImage,
      'loginBtnPressedImage': loginBtnPressedImage,
      'loginBtnUnableImage': loginBtnUnableImage,
      'uncheckedImgPath': uncheckedImgPath,
      'checkedImgPath': checkedImgPath,
      'privacyCheckboxSize': privacyCheckboxSize,
      'privacyHintToast': privacyHintToast,
      'privacyOffsetY': privacyOffsetY,
      'privacyOffsetX': privacyOffsetX,
      'privacyVerticalLayoutItem': getStringFromEnum(privacyVerticalLayoutItem),
      'privacyText': privacyText,
      'privacyTextSize': privacyTextSize,
      'clauseName': clauseName,
      'clauseUrl': clauseUrl,
      'clauseBaseColor': clauseBaseColor,
      'clauseColor': clauseColor,
      'clauseNameTwo': clauseNameTwo,
      'clauseUrlTwo': clauseUrlTwo,
      'sloganOffsetY': sloganOffsetY,
      'sloganTextColor': sloganTextColor,
      'sloganOffsetX': sloganOffsetX,
      'sloganVerticalLayoutItem': getStringFromEnum(sloganVerticalLayoutItem),
      'sloganTextSize': sloganTextSize,
      'sloganWidth': sloganWidth,
      'sloganHeight': sloganHeight,
      'sloganHidden': sloganHidden,
      'privacyState': privacyState,
      'privacyCheckboxInCenter': privacyCheckboxInCenter,
      'privacyTextCenterGravity': privacyTextCenterGravity,
      'privacyCheckboxHidden': privacyCheckboxHidden,
      'privacyWithBookTitleMark': privacyWithBookTitleMark,
      'privacyNavColor': privacyNavColor,
      'privacyNavTitleTextColor': privacyNavTitleTextColor,
      'privacyNavTitleTextSize': privacyNavTitleTextSize,
      'privacyNavTitleTitle1': privacyNavTitleTitle1,
      'privacyNavTitleTitle2': privacyNavTitleTitle2,
      'privacyNavReturnBtnImage': privacyNavReturnBtnImage,
      'popViewConfig':
          popViewConfig != null ? popViewConfig!.toJsonMap() : null,
      'privacyStatusBarColorWithNav': privacyStatusBarColorWithNav,
      'privacyStatusBarDarkMode': privacyStatusBarDarkMode,
      'privacyStatusBarTransparent': privacyStatusBarTransparent,
      'privacyStatusBarHidden': privacyStatusBarHidden,
      'privacyVirtualButtonTransparent': privacyVirtualButtonTransparent,
      'statusBarColorWithNav': statusBarColorWithNav,
      'statusBarDarkMode': statusBarDarkMode,
      'statusBarTransparent': statusBarTransparent,
      'statusBarHidden': statusBarHidden,
      'virtualButtonTransparent': virtualButtonTransparent,
      'authStatusBarStyle': getStringFromEnum(authStatusBarStyle),
      'privacyStatusBarStyle': getStringFromEnum(privacyStatusBarStyle),
      'modelTransitionStyle': getStringFromEnum(modelTransitionStyle),
      'needStartAnim': needStartAnim,
      'needCloseAnim': needCloseAnim,
      'privacyNavTitleTitle': privacyNavTitleTitle,
    }..removeWhere((key, value) => value == null);
  }
}

/// 授权页弹窗模式配置
///
/// 注意：Android 的相关配置可以从 AndroidManifest 中配置，
/// 具体做法参考 https://docs.jiguang.cn/jverification/client/android_api/#sdk_11
class JVPopViewConfig {
  JVPopViewConfig();

  int? width;
  int? height;

  /// 窗口相对屏幕中心的 X 轴偏移量
  int offsetCenterX = 0;

  /// 窗口相对屏幕中心的y轴偏移量
  int offsetCenterY = 0;

  /// 窗口是否居屏幕底部。设置后 offsetCenterY 将失效（仅 Android）
  bool isBottom = false;

  /// 弹窗圆角大小，Android 从 AndroidManifest 配置中读取（仅 iOS）
  double popViewCornerRadius = 5.0;

  /// 背景的透明度，Android 从 AndroidManifest 配置中读取（仅 iOS）
  double backgroundAlpha = 0.3;

  bool isPopViewTheme = true; // 是否支持弹窗模式
  Map toJsonMap() {
    return {
      'isPopViewTheme': isPopViewTheme,
      'width': width,
      'height': height,
      'offsetCenterX': offsetCenterX,
      'offsetCenterY': offsetCenterY,
      'isBottom': isBottom,
      'popViewCornerRadius': popViewCornerRadius,
      'backgroundAlpha': backgroundAlpha,
    }..removeWhere((key, value) => value == null);
  }
}

/// 自定义控件
class JVCustomWidget {
  String widgetId;
  JVCustomWidgetType type;

  JVCustomWidget(this.widgetId, this.type) {
    if (type == JVCustomWidgetType.button) {
      this.isClickEnable = true;
    } else {
      this.isClickEnable = false;
    }
  }

  int left = 0; // 屏幕左边缘开始计算
  int top = 0; // 导航栏底部开始计算
  int width = 0;
  int height = 0;

  String title = '';
  double titleFont = 13.0;
  int titleColor = Colors.black.value;
  int? backgroundColor;
  String? btnNormalImageName;
  String? btnPressedImageName;
  JVTextAlignmentType? textAlignment;

  int lines = 1;

  /// TextView 行数
  bool isSingleLine = true;

  /// TextView 是否单行显示，默认：单行，iOS 端无效
  ///
  /// 若 isSingleLine = false 时，iOS 端 lines 设置失效，会自适应内容高度，最大高度为设置的 height
  bool isShowUnderline = false;

  /// 是否显示下划线，默认：不显示
  late bool isClickEnable;

  /// 是否可点击，默认：不可点击

  Map toJsonMap() {
    return {
      'widgetId': widgetId,
      'type': getStringFromEnum(type),
      'title': title,
      'titleFont': titleFont,
      'textAlignment': getStringFromEnum(textAlignment),
      'titleColor': titleColor,
      'backgroundColor': backgroundColor,
      'isShowUnderline': isShowUnderline,
      'isClickEnable': isClickEnable,
      'btnNormalImageName': btnNormalImageName,
      'btnPressedImageName': btnPressedImageName,
      'lines': lines,
      'isSingleLine': isSingleLine,
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    }..removeWhere((key, value) => value == null);
  }
}

/// 添加自定义控件类型，目前只支持 [textView]
enum JVCustomWidgetType { textView, button }

/// 文本对齐方式
enum JVTextAlignmentType { left, right, center }

/// 监听返回类
class JVListenerEvent {
  const JVListenerEvent({
    required this.code,
    required this.message,
    this.operator,
  });

  JVListenerEvent.fromJson(Map<dynamic, dynamic> json)
      : code = json['code'],
        message = json['message'],
        operator = json['operator'];

  /// 返回码
  ///
  /// 具体事件返回码请查看 https://docs.jiguang.cn/jverification/client/android_api/
  final int code;

  /// 事件描述、事件返回值等
  final String message;

  /// 成功时为对应运营商，CM 代表中国移动，CU 代表中国联通，CT 代表中国电信。
  /// 失败时可能为 null
  final String? operator;

  Map toMap() {
    return {'code': code, 'message': message, 'operator': operator};
  }
}

/// 授权页事件
class JVAuthPageEvent extends JVListenerEvent {
  @override
  JVAuthPageEvent.fromJson(Map<dynamic, dynamic> json) : super.fromJson(json);

  @override
  Map toMap() {
    return {'code': code, 'message': message};
  }
}

/// SDK 初始化回调事件
class JVSDKSetupEvent extends JVAuthPageEvent {
  @override
  JVSDKSetupEvent.fromJson(Map<dynamic, dynamic> json) : super.fromJson(json);
}

/// iOS 布局参照 item
///
/// [ItemNone]    不参照任何item。可用来直接设置 Y、width、height
/// [ItemLogo]    参照logo视图
/// [ItemNumber]  参照号码栏
/// [ItemSlogan]  参照标语栏
/// [ItemLogin]   参照登录按钮
/// [ItemCheck]   参照隐私选择框
/// [ItemPrivacy] 参照隐私栏
/// [ItemSuper]   参照父视图
enum JVIOSLayoutItem {
  ItemNone,
  ItemLogo,
  ItemNumber,
  ItemSlogan,
  ItemLogin,
  ItemCheck,
  ItemPrivacy,
  ItemSuper
}

/// iOS 授权界面弹出模式
///
/// 注意：窗口模式下不支持 [PartialCurl]
enum JVIOSUIModalTransitionStyle {
  CoverVertical,
  FlipHorizontal,
  CrossDissolve,
  PartialCurl
}

/// iOS 状态栏设置，需要设置 info.plist 文件中
/// View controller-based status bar appearance 值为 YES
/// 授权页和隐私页状态栏才会生效
enum JVIOSBarStyle {
  /// Automatically chooses light or dark content based on the user interface style
  StatusBarStyleDefault,

  /// Light content, for use on dark backgrounds
  /// iOS 7 以上
  StatusBarStyleLightContent,

  /// Dark content, for use on light background
  /// iOS 13 以上
  StatusBarStyleDarkContent
}

String? getStringFromEnum<T>(T) {
  if (T == null) {
    return null;
  }

  return T.toString().split('.').last;
}
