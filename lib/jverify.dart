import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 监听添加的自定义控件的点击事件
typedef JVClickWidgetEventListener = void Function(String widgetId);

/// 授权页事件回调 @since 2.4.0
typedef JVAuthPageEventListener = void Function(JVAuthPageEvent event);
/**
 * 一键登录接口的回调监听
 *
 * @param event
 *          code     ：返回码，6000 代表loginToken获取成功，6001 代表loginToken获取失败，其他返回码详见描述
 *          message  ：返回码的解释信息，若获取成功，内容信息代表loginToken。
 *          operator ：成功时为对应运营商，CM代表中国移动，CU代表中国联通，CT代表中国电信。失败时可能为 null
 *
 * @discussion 调用 loginAuth 接口后，可以通过添加此监听事件来监听接口的返回结果
 * */
typedef JVLoginAuthCallBackListener = void Function(JVListenerEvent event);

/**
 * 短信登录接口的回调监听
 *
 * @param event
 *          code     ：返回码，6000 代表loginToken获取成功，6001 代表loginToken获取失败，其他返回码详见描述
 *          message  ：返回码的解释信息，若获取成功，内容信息代表loginToken。
 *          phone ：手机号
 *
 * @discussion 调用 smsAuth 接口后，可以通过添加此监听事件来监听接口的返回结果
 * */
typedef JVSMSListener = void Function(JVSMSEvent event);

/**
 * SDK 初始接口回调监听
 *
 * @param event
 *          code     ：返回码，8000代表初始化成功，其他为失败，详见错误码描述
 *          message  ：返回码的解释信息，若获取成功，内容信息代表loginToken。
 *
 * @discussion 调用 setup 接口后，可以通过添加此监听事件来监听接口的返回结果
 * */
typedef JVSDKSetupCallBackListener = void Function(JVSDKSetupEvent event);

class JVEventHandlers {
  static final JVEventHandlers _instance = new JVEventHandlers._internal();

  JVEventHandlers._internal();

  factory JVEventHandlers() => _instance;

  Map<String, JVClickWidgetEventListener> clickEventsMap =
      Map<String, JVClickWidgetEventListener>();
  List<JVAuthPageEventListener> authPageEvents = [];
  List<JVLoginAuthCallBackListener> loginAuthCallBackEvents = [];
  JVSDKSetupCallBackListener? sdkSetupCallBackListener;

  int loginAuthIndex = 0;
  int smsAuthIndex = 0;
  Map<int, JVAuthPageEventListener> authPageEventsMap = {};
  Map<int, JVLoginAuthCallBackListener> loginAuthCallBackEventsMap = {};
  Map<int, JVSMSListener> smsCallBackEventsMap = {};
}

class Jverify {
  static const String flutter_log = "| JVER | Flutter | ";

  /// 错误码
  static const String j_flutter_code_key = "code";

  /// 回调的提示信息
  static const String j_flutter_msg_key = "message";

  /// 重复请求
  static const int j_flutter_error_code_repeat = -1;

  factory Jverify() => _instance;
  final JVEventHandlers _eventHanders = new JVEventHandlers();

  final MethodChannel _channel;
  final List<String> requestQueue = [];

  @visibleForTesting
  Jverify.private(MethodChannel channel) : _channel = channel;

  static final _instance = new Jverify.private(const MethodChannel("jverify"));

  /// 自定义控件的点击事件
  addClikWidgetEventListener(
      String eventId, JVClickWidgetEventListener callback) {
    _eventHanders.clickEventsMap[eventId] = callback;
  }

  /// 授权页的点击事件， @since v2.4.0
  addAuthPageEventListener(JVAuthPageEventListener callback) {
    _eventHanders.authPageEvents.add(callback);
  }

  /// loginAuth 接口回调的监听 （旧，用于配合旧版loginAuthSyncApi使用）
  addLoginAuthCallBackListener(JVLoginAuthCallBackListener callback) {
    _eventHanders.loginAuthCallBackEvents.add(callback);
  }

  /// SDK 初始化回调监听
  addSDKSetupCallBackListener(JVSDKSetupCallBackListener? callback) {
    _eventHanders.sdkSetupCallBackListener = callback;
  }

  Future<void> _handlerMethod(MethodCall call) async {
    print("handleMethod method = ${call.method}");
    switch (call.method) {
      case 'onReceiveClickWidgetEvent':
        {
          String widgetId = call.arguments.cast<dynamic, dynamic>()['widgetId'];
          bool isContains = _eventHanders.clickEventsMap.containsKey(widgetId);
          if (isContains) {
            JVClickWidgetEventListener cb =
                _eventHanders.clickEventsMap[widgetId]!;
            cb(widgetId);
          }
        }
        break;
      case 'onReceiveAuthPageEvent':
        {
          Map json = call.arguments.cast<dynamic, dynamic>();
          JVAuthPageEvent ev = JVAuthPageEvent.fromJson(json);
          int index = json["loginAuthIndex"];

          for (JVAuthPageEventListener cb in _eventHanders.authPageEvents) {
            cb(ev);
          }

          if (_eventHanders.authPageEventsMap.containsKey(index)) {
            _eventHanders.authPageEventsMap[index]!(ev);
          }
        }
        break;
      case 'onReceiveLoginAuthCallBackEvent':
        {
          Map json = call.arguments.cast<dynamic, dynamic>();
          print(json.toString());

          JVListenerEvent event = JVListenerEvent.fromJson(json);
          if (json["loginAuthIndex"] != null) {
            int index = json["loginAuthIndex"];
            if (_eventHanders.loginAuthCallBackEventsMap.containsKey(index)) {
              _eventHanders.loginAuthCallBackEventsMap[index]!(event);
              _eventHanders.loginAuthCallBackEventsMap.remove(index);
            }
          }

          //老版本callback
          for (JVLoginAuthCallBackListener cb
              in _eventHanders.loginAuthCallBackEvents) {
            cb(event);
            _eventHanders.loginAuthCallBackEvents.remove(cb);
          }
        }
        break;
      case 'onReceiveSMSAuthCallBackEvent':
        {
          Map json = call.arguments.cast<dynamic, dynamic>();
          print(json.toString());
          JVSMSEvent event = JVSMSEvent.fromJson(json);
          if (json["smsAuthIndex"] != null) {
            int index = json["smsAuthIndex"];
            if (_eventHanders.smsCallBackEventsMap.containsKey(index)) {
              _eventHanders.smsCallBackEventsMap[index]!(event);
              _eventHanders.smsCallBackEventsMap.remove(index);
            }
          }
        }
        break;
      case 'onReceiveSDKSetupCallBackEvent':
        {
          if (_eventHanders.sdkSetupCallBackListener != null) {
            Map json = call.arguments.cast<dynamic, dynamic>();
            JVSDKSetupEvent event = JVSDKSetupEvent.fromJson(json);
            _eventHanders.sdkSetupCallBackListener!(event);
          }
        }
        break;
      default:
        throw new UnsupportedError("Unrecognized Event");
    }
    return;
  }

  Map<dynamic, dynamic>? isRepeatRequest({required String method}) {
    bool isContain = requestQueue.any((element) => (element == method));
    if (isContain) {
      Map map = {
        j_flutter_code_key: j_flutter_error_code_repeat,
        j_flutter_msg_key: method + " is requesting, please try again later."
      };
      print(flutter_log + map.toString());
      return map;
    } else {
      requestQueue.add(method);
      return null;
    }
  }

  /// 初始化, timeout单位毫秒，合法范围是(0,30000]，推荐设置为5000-10000,默认值为10000
  void setup(
      {@required String? appKey,
      String? channel,
      bool? useIDFA,
      int timeout = 10000,
      bool setControlWifiSwitch = true}) {
    print("$flutter_log" + "setup");

    _channel.setMethodCallHandler(_handlerMethod);

    _channel.invokeMethod("setup", {
      "appKey": appKey,
      "channel": channel,
      "useIDFA": useIDFA,
      "timeout": timeout,
      "setControlWifiSwitch": setControlWifiSwitch
    });
  }

  /// 设置 debug 模式
  void setDebugMode(bool debug) {
    print("$flutter_log" + "setDebugMode");
    _channel.invokeMethod("setDebugMode", {"debug": debug});
  }

  /// 合规采集开关
  void setCollectionAuth(bool auth) {
    print("$flutter_log" + "setCollectionAuth");
    _channel.invokeMethod("setCollectionAuth", {"auth": auth});
  }

  ///设置前后两次获取验证码的时间间隔，默认 30000ms，有效范围(0,300000)
  void setGetCodeInternal(int intervalTime) {
    print("$flutter_log" + "setGetCodeInternal");
    _channel.invokeMethod("setGetCodeInternal", {"timeInterval": intervalTime});
  }

/*
   * SDK 获取短信验证码
   *
   * return Map
   *        key = "code", vlaue = 状态码，3000代表获取成功
   *        key = "message", 提示信息
   *        key = "result",uuid
   * */
  Future<Map<dynamic, dynamic>> getSMSCode(
      {@required String? phoneNum, String? signId, String? tempId}) async {
    print("$flutter_log" + "getSMSCode");

    var args = <String, String>{};
    if (phoneNum != null) {
      args["phoneNumber"] = phoneNum;
    }

    if (signId != null) {
      args["signId"] = signId;
    }

    if (tempId != null) {
      args["tempId"] = tempId;
    }

    return await _channel.invokeMethod("getSMSCode", args);
  }

  /*
   * 获取 SDK 初始化是否成功标识
   *
   * return Map
   *          key = "result"
   *          vlue = bool,是否成功
   * */
  Future<Map<dynamic, dynamic>> isInitSuccess() async {
    print("$flutter_log" + "isInitSuccess");
    return await _channel.invokeMethod("isInitSuccess");
  }

  /*
   * SDK判断网络环境是否支持
   *
   * return Map
   *          key = "result"
   *          vlue = bool,是否支持
   * */
  Future<Map<dynamic, dynamic>> checkVerifyEnable() async {
    print("$flutter_log" + "checkVerifyEnable");
    return await _channel.invokeMethod("checkVerifyEnable");
  }

  /*
   * SDK 获取号码认证token
   *
   * return Map
   *        key = "code", vlaue = 状态码，2000代表获取成功
   *        key = "message", value = 成功即为 token，失败为提示
   * */
  Future<Map<dynamic, dynamic>> getToken({String? timeOut}) async {
    print("$flutter_log" + "getToken");

    String method = "getToken";
    var repeatError = isRepeatRequest(method: method);
    if (repeatError == null) {
      var para = {"timeOut": timeOut};
      para.remove((key, value) => value == null);
      var result = await _channel.invokeMethod(method, para);
      requestQueue.remove(method);
      return result;
    } else {
      return repeatError;
    }
  }

  /*
  * SDK 发起号码认证
  *
  * 2.4.3 版本开始，此接口已移除
  * */
  Future<Map<dynamic, dynamic>> verifyNumber(String phone,
      {String? token}) async {
    print("$flutter_log" + "verifyNumber");

    return {"error": "This interface is deprecated"};
  }

  /*
   * SDK 一键登录预取号,timeOut 有效取值范围[3000,10000]
   *
   * return Map
   *        key = "code", vlaue = 状态码，7000代表获取成功
   *        key = "message", value = 结果信息描述
   * */
  Future<Map<dynamic, dynamic>> preLogin({int timeOut = 10000}) async {
    var para = new Map();
    if (timeOut != null) {
      if (timeOut >= 3000 && timeOut <= 10000) {
        para["timeOut"] = timeOut;
      }
    }
    print("$flutter_log" + "preLogin" + "$para");

    String method = "preLogin";
    var repeatError = isRepeatRequest(method: method);
    if (repeatError == null) {
      var result = await _channel.invokeMethod(method, para);
      requestQueue.remove(method);
      return result;
    } else {
      return repeatError;
    }
  }

  /*
  * SDK 清除预取号缓存
  *
  * @discussion 清除 sdk 当前预取号结果缓存
  *
  * @since v2.4.3
  * */
  void clearPreLoginCache() {
    print("$flutter_log" + "clearPreLoginCache");
    _channel.invokeMethod("clearPreLoginCache");
  }

  /*
  * SDK请求授权一键登录（异步接口）
  *
  * @param autoDismiss  设置登录完成后是否自动关闭授权页
  * @param timeout      设置超时时间，单位毫秒。 合法范围（0，30000],范围以外默认设置为10000
  *
  * @return 通过接口异步返回的 map :
  *                           key = "code", value = 6000 代表loginToken获取成功
  *                           key = message, value = 返回码的解释信息，若获取成功，内容信息代表loginToken
  *
  * @discussion since SDK v2.4.0，授权页面点击事件监听：通过添加 JVAuthPageEventListener 监听，来监听授权页点击事件
  *
  * */
  Future<Map<dynamic, dynamic>> loginAuth(bool autoDismiss,
      {int timeout = 10000}) async {
    print("$flutter_log" + "loginAuth");

    String method = "loginAuth";
    var repeatError = isRepeatRequest(method: method);
    if (repeatError == null) {
      var map = {"autoDismiss": autoDismiss, "timeout": timeout};
      var result = await _channel.invokeMethod(method, map);
      requestQueue.remove(method);
      return result;
    } else {
      return repeatError;
    }
  }

  /*
  * SDK请求授权一键登录（同步接口）（旧）
  *
  * @param autoDismiss  设置登录完成后是否自动关闭授权页
  * @param timeout      设置超时时间，单位毫秒。 合法范围（0，30000],范围以外默认设置为10000
  *
  * 接口回调返回数据监听：通过添加 JVLoginAuthCallBackListener 监听，来监听接口的返回结果
  *
  * 授权页面点击事件监听：通过添加 JVAuthPageEventListener 监听，来监听授权页点击事件
  *
  * */
  void loginAuthSyncApi(
      {@required bool autoDismiss = false, int timeout = 10000}) {
    print("$flutter_log" + "loginAuthSyncApi");

    String method = "loginAuthSyncApi";
    var repeatError = isRepeatRequest(method: method);
    if (repeatError == null) {
      var map = {"autoDismiss": autoDismiss, "timeout": timeout};
      _channel.invokeMethod(method, map);
      requestQueue.remove(method);
    } else {
      print("$flutter_log" + repeatError.toString());
    }
  }

  /*
  * SDK请求授权一键登录（同步接口）
  *
  * @param autoDismiss  设置登录完成后是否自动关闭授权页
  * @param timeout      设置超时时间，单位毫秒。 合法范围（0，30000],范围以外默认设置为10000
  * @param enableSms     是否开启短信登录切换服务，开启时在授权登录失败时拉起短信登录页面，默认为false
  *
  * 接口回调返回数据监听：通过添加 JVLoginAuthCallBackListener 监听，来监听接口的返回结果
  *
  * 授权页面点击事件监听：通过添加 JVAuthPageEventListener 监听，来监听授权页点击事件
  *
  * */
  void loginAuthSyncApi2(
      {required bool autoDismiss,
      int timeout = 10000,
      bool enableSms = false,
      JVLoginAuthCallBackListener? loginAuthcallback,
      JVAuthPageEventListener? pageEventCallback}) {
    print("$flutter_log" + "loginAuthSyncApi");

    String method = "loginAuthSyncApi";
    var repeatError = isRepeatRequest(method: method);
    if (repeatError == null) {
      _eventHanders.loginAuthIndex++;
      var map = {
        "autoDismiss": autoDismiss,
        "timeout": timeout,
        "enableSms": enableSms,
        "loginAuthIndex": _eventHanders.loginAuthIndex
      };
      if (loginAuthcallback != null) {
        _eventHanders.loginAuthCallBackEventsMap[_eventHanders.loginAuthIndex] =
            loginAuthcallback;
      }
      if (pageEventCallback != null) {
        _eventHanders.authPageEventsMap[_eventHanders.loginAuthIndex] =
            pageEventCallback;
      }
      _channel.invokeMethod(method, map);
      requestQueue.remove(method);
    } else {
      print("$flutter_log" + repeatError.toString());
    }
  }

  /*
  * 短信登录
  *
  * @param autoDismiss  设置登录完成后是否自动关闭授权页
  * @param timeout      设置超时时间，单位毫秒。 合法范围（0，10000],若小于等于 0 则取默认值 5000. 大于 10000 则取 10000
  *
  * 接口回调返回数据监听：通过添加 JVSMSListener 监听，来监听接口的返回结果
  *
  *
  * */
  void smsAuth(
      {required bool autoDismiss,
      int timeout = 5000,
      JVSMSListener? smsCallback}) {
    print("$flutter_log" + "smsAuth");

    String method = "smsAuth";
    var repeatError = isRepeatRequest(method: method);
    if (repeatError == null) {
      _eventHanders.smsAuthIndex++;
      var map = {
        "autoDismiss": autoDismiss,
        "timeout": timeout,
        "smsAuthIndex": _eventHanders.smsAuthIndex
      };
      if (smsCallback != null) {
        _eventHanders.smsCallBackEventsMap[_eventHanders.smsAuthIndex] =
            smsCallback;
      }
      _channel.invokeMethod(method, map);
      requestQueue.remove(method);
    } else {
      print("$flutter_log" + repeatError.toString());
    }
  }

  /*
  * 关闭授权页面
  * */
  void dismissLoginAuthView() {
    print(flutter_log + "dismissLoginAuthView");
    _channel.invokeMethod("dismissLoginAuthView");
  }

  /*
  * 设置授权页面
  *
  * @para isAutorotate      是否支持横竖屏，true:支持横竖屏，false：只支持竖屏
  * @para portraitConfig    竖屏的 UI 配置
  * @para landscapeConfig   Android 横屏的 UI 配置，只有当 isAutorotate=true 时必须传，并且该配置只生效在 Android，iOS 使用 portraitConfig 的约束适配横屏
  * @para widgets           自定义添加的控件
  * */
  void setCustomAuthorizationView(bool isAutorotate, JVUIConfig portraitConfig,
      {JVUIConfig? landscapeConfig, List<JVCustomWidget>? widgets}) {
    if (isAutorotate == true) {
      if (portraitConfig == null || landscapeConfig == null) {
        print("missing Android landscape ui config");
        return;
      }
    }

    var para = Map();
    para["isAutorotate"] = isAutorotate;

    var para1 = portraitConfig.toJsonMap();
    para1.removeWhere((key, value) => value == null);
    para["portraitConfig"] = para1;

    if (landscapeConfig != null) {
      var para2 = landscapeConfig.toJsonMap();
      para2.removeWhere((key, value) => value == null);
      para["landscapeConfig"] = para2;
    }

    if (widgets != null) {
      var widgetList = [];
      for (JVCustomWidget widget in widgets) {
        var para2 = widget.toJsonMap();
        para2.removeWhere((key, value) => value == null);

        widgetList.add(para2);
      }
      para["widgets"] = widgetList;
    }

    _channel.invokeMethod("setCustomAuthorizationView", para);
  }

  /// （不建议使用，建议使用 setAuthorizationView 接口）自定义授权页面，界面原始控件、新增自定义控件
  void setCustomAuthViewAllWidgets(JVUIConfig uiConfig,
      {List<JVCustomWidget>? widgets}) {
    var para = Map();

    var para1 = uiConfig.toJsonMap();
    para1.removeWhere((key, value) => value == null);
    para["uiconfig"] = para1;

    if (widgets != null) {
      var widgetList = [];
      for (JVCustomWidget widget in widgets) {
        var para2 = widget.toJsonMap();
        para2.removeWhere((key, value) => value == null);

        widgetList.add(para2);
      }
      para["widgets"] = widgetList;
    }

    _channel.invokeMethod("setCustomAuthViewAllWidgets", para);
  }
}

/*
* 自定义 UI 界面配置类
*
* Y 轴
*     iOS       以导航栏底部为 0 作为起点
*     Android   以导航栏底部为 0 作为起点
* X 轴
*     iOS       以屏幕中心为 0 作为起点，往屏幕左侧则减，往右侧则加，如果不传或者传 null，则默认屏幕居中
*     Android   以屏幕左侧为 0 作为起点，往右侧则加，如果不传或者传 null，则默认屏幕居中
* */
class JVUIConfig {
  /// 授权页背景图片
  String? authBackgroundImage;
  String? authBGGifPath; // 授权界面gif图片 only android
  String? authBGVideoPath; // 授权界面video
  String? authBGVideoImgPath; // 授权界面video的第一频图片

  /// 导航栏
  int? navColor;
  String? navText;
  int? navTextColor;
  String? navReturnImgPath;
  bool navHidden = false;
  bool navReturnBtnHidden = false;
  bool navTransparent = false;
  bool? navTextBold;

  /// logo
  int? logoWidth;
  int? logoHeight;
  int? logoOffsetX;
  int? logoOffsetY;
  int? logoOffsetBottomY;
  JVIOSLayoutItem? logoVerticalLayoutItem;
  bool? logoHidden;
  String? logoImgPath;

  /// 号码
  int? numberColor;
  int? numberSize;
  bool? numberTextBold;
  int? numFieldOffsetX;
  int? numFieldOffsetY;
  int? numberFieldWidth;
  int? numberFieldHeight;
  JVIOSLayoutItem? numberVerticalLayoutItem;
  int? numberFieldOffsetBottomY;

  /// slogan
  int? sloganOffsetX;
  int? sloganOffsetY;
  int? sloganBottomOffsetY;
  JVIOSLayoutItem? sloganVerticalLayoutItem;
  int? sloganTextColor;
  int? sloganTextSize;
  int? sloganWidth;
  int? sloganHeight;
  bool? sloganTextBold;
  bool sloganHidden = false;

  /// 登录按钮
  int? logBtnOffsetX;
  int? logBtnOffsetY;
  int? logBtnBottomOffsetY;
  int? logBtnWidth;
  int? logBtnHeight;
  JVIOSLayoutItem? logBtnVerticalLayoutItem;
  String? logBtnText;
  int? logBtnTextSize;
  int? logBtnTextColor;
  bool? logBtnTextBold;
  String? logBtnBackgroundPath;
  String? loginBtnNormalImage; // only ios
  String? loginBtnPressedImage; // only ios
  String? loginBtnUnableImage; // only ios

  /// 隐私协议栏
  String? uncheckedImgPath;
  String? checkedImgPath;
  int? privacyCheckboxSize;
  bool privacyHintToast = true; //设置隐私条款不选中时点击登录按钮默认弹出toast。
  bool privacyState = false; //设置隐私条款默认选中状态，默认不选中
  bool privacyCheckboxHidden = false; //设置隐私条款checkbox是否隐藏
  bool privacyCheckboxInCenter = false; //设置隐私条款checkbox是否相对协议文字纵向居中

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
  List<JVPrivacy>? privacyItem;
  bool privacyWithBookTitleMark = true; //设置隐私条款运营商协议名是否加书名号
  bool privacyTextCenterGravity = false; //隐私条款文字是否居中对齐（默认左对齐）
  int? textVerAlignment = 1; //设置条款文字是否垂直居中对齐(默认居中对齐) 0是top 1是m 2是b
  int? privacyTopOffsetY;
  bool? privacyTextBold;
  bool? privacyUnderlineText; //设置隐私条款文字字体是否加下划线
  bool? isAlertPrivacyVc; //是否在未勾选隐私协议的情况下 弹窗提示窗口

  /// 隐私协议 web 页 UI 配置
  int? privacyNavColor; // 导航栏颜色
  int? privacyNavTitleTextColor; // 标题颜色
  int? privacyNavTitleTextSize; // 标题大小
  bool? privacyNavTitleTextBold; // 标题字体加粗
  String? privacyNavTitleTitle; //协议0 web页面导航栏标题 only ios
  String? privacyNavTitleTitle1; // 协议1 web页面导航栏标题
  String? privacyNavTitleTitle2; // 协议2 web页面导航栏标题
  String? privacyNavReturnBtnImage;
  JVIOSBarStyle? privacyStatusBarStyle; //隐私协议web页 状态栏样式设置 only iOS

  ///隐私页
  bool privacyStatusBarColorWithNav = false; //隐私页web状态栏是否与导航栏同色 only android
  bool privacyStatusBarDarkMode = false; //隐私页web状态栏是否暗色 only android
  bool privacyStatusBarTransparent = false; //隐私页web页状态栏是否透明 only android
  bool privacyStatusBarHidden = false; //隐私页web页状态栏是否隐藏 only android
  bool privacyVirtualButtonTransparent = false; //隐私页web页虚拟按键背景是否透明 only android

  ///授权页
  bool statusBarColorWithNav = false; //授权页状态栏是否跟导航栏同色 only android
  bool statusBarDarkMode = false; //授权页状态栏是否为暗色 only android
  bool statusBarTransparent = false; //授权页栏状态栏是否透明 only android
  bool statusBarHidden = false; //授权页状态栏是否隐藏 only android
  bool virtualButtonTransparent = false; //授权页虚拟按键背景是否透明 only android

  JVIOSBarStyle authStatusBarStyle =
      JVIOSBarStyle.StatusBarStyleDefault; //授权页状态栏样式设置 only iOS

  ///是否需要动画
  bool needStartAnim = false; //设置拉起授权页时是否需要显示默认动画
  bool needCloseAnim = false; //设置关闭授权页时是否需要显示默认动画
  String? enterAnim; // 拉起授权页时进入动画 only android
  String? exitAnim; // 退出授权页时动画 only android

  /// 授权页弹窗模式 配置，选填
  JVPopViewConfig? popViewConfig;

  /// Android协议二次弹窗配置，选填
  JVPrivacyCheckDialogConfig? privacyCheckDialogConfig;

  JVIOSUIModalTransitionStyle modelTransitionStyle = //弹出方式 only ios
      JVIOSUIModalTransitionStyle.CoverVertical;

  /// 协议二次弹窗-iOS
  int agreementAlertViewTitleTexSize = 14; // 协议二次弹窗标题文本样式
  int? agreementAlertViewTitleTextColor; //协议二次弹窗标题文本颜色
  JVTextAlignmentType agreementAlertViewContentTextAlignment =
      JVTextAlignmentType.center; //协议二次弹窗内容文本对齐方式
  int agreementAlertViewContentTextFontSize = 12; //协议二次弹窗内容文本字体大小
  String? agreementAlertViewLoginBtnNormalImagePath; // 协议二次弹窗登录按钮背景图片 - 激活状态的图片
  String?
      agreementAlertViewLoginBtnPressedImagePath; // 协议二次弹窗登录按钮背景图片 - 高亮状态的图片
  String? agreementAlertViewLoginBtnUnableImagePath; //协议二次弹窗登录按钮背景图片 - 失效状态的图片
  int? agreementAlertViewLogBtnTextColor; //协议二次弹窗登录按钮文本颜色
  List<JVCustomWidget>? agreementAlertViewWidgets; //协议二次弹窗自定义视图
  Map<String, List<int>>?
      agreementAlertViewUIFrames; // 协议二次弹窗各控件的frame设置 { "superViewFrame": [left, top, width, height],"alertViewFrame": [left, top, width, height],"titleFrame": [left, top, width, height],"contentFrame": [left, top, width, height],"buttonFrame": [left, top, width, height]};

  bool setIsPrivacyViewDarkMode = true; //协议页面是否支持暗黑模式

  /// sms UI
  JVSMSUIConfig? smsUIConfig;

  Map toJsonMap() {
    var agreementAlertViewWidgetsList = [];

    if (agreementAlertViewWidgets != null) {
      for (JVCustomWidget widget in agreementAlertViewWidgets!) {
        var para2 = widget.toJsonMap();
        para2.removeWhere((key, value) => value == null);
        agreementAlertViewWidgetsList.add(para2);
      }
    }

    return {
      "privacyItem": privacyItem != null ? json.encode(privacyItem) : null,
      "authBackgroundImage": authBackgroundImage ??= null,
      "authBGGifPath": authBGGifPath ??= null,
      "authBGVideoPath": authBGVideoPath ??= null,
      "authBGVideoImgPath": authBGVideoImgPath ??= null,
      "navColor": navColor ??= null,
      "navText": navText ??= null,
      "navTextColor": navTextColor ??= null,
      "navTextBold": navTextBold ??= null,
      "navReturnImgPath": navReturnImgPath ??= null,
      "navHidden": navHidden,
      "navReturnBtnHidden": navReturnBtnHidden,
      "navTransparent": navTransparent,
      "logoImgPath": logoImgPath ??= null,
      "logoWidth": logoWidth ??= null,
      "logoHeight": logoHeight ??= null,
      "logoOffsetY": logoOffsetY ??= null,
      "logoOffsetX": logoOffsetX ??= null,
      "logoOffsetBottomY": logoOffsetBottomY ??= null,
      "logoVerticalLayoutItem": getStringFromEnum(logoVerticalLayoutItem),
      "logoHidden": logoHidden ??= null,
      "numberColor": numberColor ??= null,
      "numberSize": numberSize ??= null,
      "numberTextBold": numberTextBold ??= null,
      "numFieldOffsetY": numFieldOffsetY ??= null,
      "numFieldOffsetX": numFieldOffsetX ??= null,
      "numberFieldOffsetBottomY": numberFieldOffsetBottomY ??= null,
      "numberFieldWidth": numberFieldWidth ??= null,
      "numberFieldHeight": numberFieldHeight ??= null,
      "numberVerticalLayoutItem": getStringFromEnum(numberVerticalLayoutItem),
      "logBtnText": logBtnText ??= null,
      "logBtnOffsetY": logBtnOffsetY ??= null,
      "logBtnOffsetX": logBtnOffsetX ??= null,
      "logBtnBottomOffsetY": logBtnBottomOffsetY ??= null,
      "logBtnWidth": logBtnWidth ??= null,
      "logBtnHeight": logBtnHeight ??= null,
      "logBtnVerticalLayoutItem": getStringFromEnum(logBtnVerticalLayoutItem),
      "logBtnTextSize": logBtnTextSize ??= null,
      "logBtnTextColor": logBtnTextColor ??= null,
      "logBtnTextBold": logBtnTextBold ??= null,
      "logBtnBackgroundPath": logBtnBackgroundPath ??= null,
      "loginBtnNormalImage": loginBtnNormalImage ??= null,
      "loginBtnPressedImage": loginBtnPressedImage ??= null,
      "loginBtnUnableImage": loginBtnUnableImage ??= null,
      "uncheckedImgPath": uncheckedImgPath ??= null,
      "checkedImgPath": checkedImgPath ??= null,
      "privacyCheckboxSize": privacyCheckboxSize ??= null,
      "privacyHintToast": privacyHintToast,
      "privacyOffsetY": privacyOffsetY ??= null,
      "privacyOffsetX": privacyOffsetX ??= null,
      "privacyTopOffsetY": privacyTopOffsetY ??= null,
      "privacyVerticalLayoutItem": getStringFromEnum(privacyVerticalLayoutItem),
      "privacyText": privacyText ??= null,
      "privacyTextSize": privacyTextSize ??= null,
      "privacyTextBold": privacyTextBold ??= null,
      "privacyUnderlineText": privacyUnderlineText ??= null,
      "isAlertPrivacyVc": isAlertPrivacyVc ??= null,
      "clauseName": clauseName ??= null,
      "clauseUrl": clauseUrl ??= null,
      "clauseBaseColor": clauseBaseColor ??= null,
      "clauseColor": clauseColor ??= null,
      "clauseNameTwo": clauseNameTwo ??= null,
      "clauseUrlTwo": clauseUrlTwo ??= null,
      "sloganOffsetY": sloganOffsetY ??= null,
      "sloganTextColor": sloganTextColor ??= null,
      "sloganOffsetX": sloganOffsetX ??= null,
      "sloganBottomOffsetY": sloganBottomOffsetY ??= null,
      "sloganVerticalLayoutItem": getStringFromEnum(sloganVerticalLayoutItem),
      "sloganTextSize": sloganTextSize ??= null,
      "sloganWidth": sloganWidth ??= null,
      "sloganHeight": sloganHeight ??= null,
      "sloganHidden": sloganHidden,
      "sloganTextBold": sloganTextBold ??= null,
      "privacyState": privacyState,
      "privacyCheckboxInCenter": privacyCheckboxInCenter,
      "privacyTextCenterGravity": privacyTextCenterGravity,
      "privacyCheckboxHidden": privacyCheckboxHidden,
      "privacyWithBookTitleMark": privacyWithBookTitleMark,
      "privacyNavColor": privacyNavColor ??= null,
      "privacyNavTitleTextColor": privacyNavTitleTextColor ??= null,
      "privacyNavTitleTextSize": privacyNavTitleTextSize ??= null,
      "privacyNavTitleTextBold": privacyNavTitleTextBold ??= null,
      "privacyNavTitleTitle1": privacyNavTitleTitle1 ??= null,
      "privacyNavTitleTitle2": privacyNavTitleTitle2 ??= null,
      "privacyNavReturnBtnImage": privacyNavReturnBtnImage ??= null,
      "popViewConfig":
          popViewConfig != null ? popViewConfig?.toJsonMap() : null,
      "privacyStatusBarColorWithNav": privacyStatusBarColorWithNav,
      "privacyStatusBarDarkMode": privacyStatusBarDarkMode,
      "privacyStatusBarTransparent": privacyStatusBarTransparent,
      "privacyStatusBarHidden": privacyStatusBarHidden,
      "privacyVirtualButtonTransparent": privacyVirtualButtonTransparent,
      "statusBarColorWithNav": statusBarColorWithNav,
      "statusBarDarkMode": statusBarDarkMode,
      "statusBarTransparent": statusBarTransparent,
      "statusBarHidden": statusBarHidden,
      "virtualButtonTransparent": virtualButtonTransparent,
      "authStatusBarStyle": getStringFromEnum(authStatusBarStyle),
      "privacyStatusBarStyle": getStringFromEnum(privacyStatusBarStyle),
      "modelTransitionStyle": getStringFromEnum(modelTransitionStyle),
      "needStartAnim": needStartAnim,
      "needCloseAnim": needCloseAnim,
      "enterAnim": enterAnim,
      "exitAnim": exitAnim,
      "privacyNavTitleTitle": privacyNavTitleTitle ??= null,
      "textVerAlignment": textVerAlignment,
      //ios-协议的二次弹窗
      "agreementAlertViewTitleTexSize": agreementAlertViewTitleTexSize,
      "agreementAlertViewTitleTextColor": agreementAlertViewTitleTextColor ??=
          Colors.black.value,
      "agreementAlertViewContentTextAlignment":
          getStringFromEnum(agreementAlertViewContentTextAlignment),
      "agreementAlertViewContentTextFontSize":
          agreementAlertViewContentTextFontSize,
      "agreementAlertViewLoginBtnNormalImagePath":
          agreementAlertViewLoginBtnNormalImagePath ??= null,
      "agreementAlertViewLoginBtnPressedImagePath":
          agreementAlertViewLoginBtnPressedImagePath ??= null,
      "agreementAlertViewLoginBtnUnableImagePath":
          agreementAlertViewLoginBtnUnableImagePath ??= null,
      "agreementAlertViewLogBtnTextColor": agreementAlertViewLogBtnTextColor ??=
          Colors.black.value,
      "agreementAlertViewWidgets": agreementAlertViewWidgetsList,
      "agreementAlertViewUIFrames": agreementAlertViewUIFrames ??= null,
      "privacyCheckDialogConfig": privacyCheckDialogConfig != null
          ? privacyCheckDialogConfig?.toJsonMap()
          : null,
      "setIsPrivacyViewDarkMode": setIsPrivacyViewDarkMode,
      "smsUIConfig": smsUIConfig != null ? smsUIConfig?.toJsonMap() : null
    }..removeWhere((key, value) => value == null);
  }
}

/*
 * 授权页弹窗模式配置
 *
 * 注意：Android 的相关配置可以从 AndroidManifest 中配置，具体做法参考https://docs.jiguang.cn/jverification/client/android_api/#sdk_11
 * */
class JVPopViewConfig {
  int? width;
  int? height;
  int offsetCenterX = 0; // 窗口相对屏幕中心的x轴偏移量
  int offsetCenterY = 0; // 窗口相对屏幕中心的y轴偏移量
  bool isBottom = false; // only Android，窗口是否居屏幕底部。设置后 offsetCenterY 将失效，
  double popViewCornerRadius =
      5.0; // only ios，弹窗圆角大小，Android 从 AndroidManifest 配置中读取
  double backgroundAlpha =
      0.3; // only ios，背景的透明度，Android 从 AndroidManifest 配置中读取

  bool? isPopViewTheme; // 是否支持弹窗模式
  JVPopViewConfig() {
    this.isPopViewTheme = true;
  }

  Map toJsonMap() {
    return {
      "isPopViewTheme": isPopViewTheme,
      "width": width,
      "height": height,
      "offsetCenterX": offsetCenterX,
      "offsetCenterY": offsetCenterY,
      "isBottom": isBottom,
      "popViewCornerRadius": popViewCornerRadius,
      "backgroundAlpha": backgroundAlpha,
    }..removeWhere((key, value) => value == null);
  }
}

/*
 * 未勾选协议时的二次弹窗提示页面配置
 *
 * */
class JVPrivacyCheckDialogConfig {
  int? width; //协议⼆次弹窗本身的宽
  int? height; //协议⼆次弹窗本身的⾼
  int? offsetX; // 窗口相对屏幕中心的x轴偏移量
  int? offsetY; // 窗口相对屏幕中心的y轴偏移量
  String? title; //弹窗标题
  int? titleTextSize; // 弹窗标题字体大小
  int? titleTextColor; // 弹窗标题字体颜色
  String? contentTextGravity; //协议⼆次弹窗协议内容对⻬⽅式
  int? contentTextSize; //协议⼆次弹窗协议内容字体⼤⼩
  String? gravity; //弹窗对齐方式
  bool? enablePrivacyCheckDialog;
  List<JVCustomWidget>? widgets;

  String? logBtnText; //弹窗登录按钮
  String? logBtnImgPath; //协议⼆次弹窗登录按钮的背景图⽚
  int? logBtnTextColor; //协议⼆次弹窗登录按钮的字体颜⾊
  int? logBtnMarginL; //协议⼆次弹窗登录按钮左边距
  int? logBtnMarginR; //协议⼆次弹窗登录按钮右边距
  int? logBtnMarginT; //协议⼆次弹窗登录按钮上边距
  int? logBtnMarginB; //协议⼆次弹窗登录按钮下边距
  int? logBtnWidth; //协议⼆次弹窗登录按钮宽
  int? logBtnHeight; //协议⼆次弹窗登录按高

  JVPrivacyCheckDialogConfig() {
    this.enablePrivacyCheckDialog = true;
  }

  Map toJsonMap() {
    var widgetList = [];

    if (widgets != null) {
      for (JVCustomWidget widget in widgets!) {
        var para2 = widget.toJsonMap();
        para2.removeWhere((key, value) => value == null);
        widgetList.add(para2);
      }
    }

    return {
      "width": width,
      "height": height,
      "offsetX": offsetX,
      "offsetY": offsetY,
      "gravity": gravity,
      "title": title,
      "titleTextSize": titleTextSize,
      "titleTextColor": titleTextColor,
      "contentTextGravity": contentTextGravity,
      "contentTextSize": contentTextSize,
      "enablePrivacyCheckDialog": enablePrivacyCheckDialog,
      "widgets": widgetList,
      "logBtnText": logBtnText,
      "logBtnImgPath": logBtnImgPath,
      "logBtnTextColor": logBtnTextColor,
      "logBtnMarginL": logBtnMarginL,
      "logBtnMarginR": logBtnMarginR,
      "logBtnMarginT": logBtnMarginT,
      "logBtnMarginB": logBtnMarginB,
      "logBtnWidth": logBtnWidth,
      "logBtnHeight": logBtnHeight,
    }..removeWhere((key, value) => value == null);
  }
}

/*
 * 短信页面的配置
 *
 * */
class JVSMSUIConfig {
  String? smsAuthPageBackgroundImagePath; // 登录界面背景图片
  String? smsNavText; //导航栏标题文字
  int? smsNavTextColor; //导航栏标题颜色 only iOS
  bool? smsNavTextBold; // 导航栏标题 是否加粗 only iOS
  int? smsNavTextSize; //导航栏标题大小 only iOS
  int? smsSloganTextSize; //设置 slogan 字体大小
  bool? isSmsSloganHidden; //设置 slogan 字体是否隐藏  only android
  bool? isSmsSloganTextBold; //设置 slogan 字体是否加粗 only android
  int? smsSloganOffsetX; //设置 slogan 相对于屏幕左边 x 轴偏移
  int? smsSloganOffsetY; //设置 slogan 相对于标题栏下边缘 y 偏移
  int? smsSloganOffsetBottomY; //设置 slogan 相对于屏幕底部下边缘 y 轴偏移
  int? smsSloganWidth; //设置 slogan 宽度  only iOS
  int? smsSloganHeight; //设置 slogan 高度 only iOS
  int? smsSloganTextColor; //设置移动 slogan 文字颜色
  int? smsLogoWidth; //设置 logo 宽度（单位：dp）
  int? smsLogoHeight; //设置 logo 高度（单位：dp）
  int? smsLogoOffsetX; //设置 logo 相对于屏幕左边 x 轴偏移
  int? smsLogoOffsetY; //设置 logo 相对于标题栏下边缘 y 偏移
  int? smsLogoOffsetBottomY; //	设置 logo 相对于屏幕底部 y 轴偏移
  bool? isSmsLogoHidden; //隐藏 logo
  String? smsLogoResName; //设置 logo 图片
  int? smsPhoneTextViewOffsetX; //设置号码标题相对于屏幕左边 x 轴偏移  only android
  int? smsPhoneTextViewOffsetY; //设置号码标题相对于相对于标题栏下边缘 y 偏移 only android
  int? smsPhoneTextViewTextSize; //设置号码标题字体大小  only android
  int? smsPhoneTextViewTextColor; //设置号码标题文字颜色  only android
  int? smsPhoneInputViewOffsetX; //设置号码输入框相对于屏幕左边 x 轴偏移
  int? smsPhoneInputViewOffsetY; //设置号码输入框相对于屏幕底部 y 轴偏移
  int? smsPhoneInputViewWidth; //设置号码输入框宽度
  int? smsPhoneInputViewHeight; //设置号码输入框高度
  int? smsPhoneInputViewTextColor; //设置手机号码输入框字体颜色
  int? smsPhoneInputViewTextSize; //设置手机号码输入框字体大小
  String? smsPhoneInputViewPlaceholderText; // 设置手机号码输入框提示词 only iOS
  JVIOSTextBorderStyle? smsPhoneInputViewBorderStyle; //设置手机号码输入框样式 only iOS
  int? smsVerifyCodeTextViewOffsetX; //设置验证码标题相对于屏幕左边 x 轴偏移  only android
  int? smsVerifyCodeTextViewOffsetY; //设置验证码标题相对于相对于标题栏下边缘 y 偏移  only android
  int? smsVerifyCodeTextViewTextSize; //设置验证码标题字体大小  only android
  int? smsVerifyCodeTextViewTextColor; //设置验证码标题文字颜色  only android
  int? smsVerifyCodeEditTextViewTextSize; //设置验证码输入框字体大小
  int? smsVerifyCodeEditTextViewTextColor; //设置验证码输入框字体颜色
  String? smsVerifyCodeEditTextViewPlaceholderText; // 设置验证码输入框提示词 only iOS
  int? smsVerifyCodeEditTextViewOffsetX; //设置验证码输入框相对于屏幕左边 x 轴偏移
  int? smsVerifyCodeEditTextViewOffsetY; //设置验证码输入框相对于标题栏下边缘 y 偏移
  int? smsVerifyCodeEditTextViewOffsetR; //设置验证码输入框相对于屏幕右边偏移
  int? smsVerifyCodeEditTextViewWidth; //设置验证码输入框宽度
  int? smsVerifyCodeEditTextViewHeight; //设置验证码输入框高度
  JVIOSTextBorderStyle?
      smsVerifyCodeEditTextViewBorderStyle; //设置验证码输入框样式 only iOS
  int? smsGetVerifyCodeTextViewOffsetX; //设置获取验证码按钮相对于屏幕左边 x 轴偏移
  int? smsGetVerifyCodeTextViewOffsetY; //设置获取验证码按钮相对于标题栏下边缘 y 偏移
  int? smsGetVerifyCodeTextViewTextSize; //设置获取验证码按钮字体大小
  int? smsGetVerifyCodeTextViewTextColor; //设置获取验证码按钮文字颜色
  int? smsGetVerifyCodeTextViewOffsetR; //设置获取验证码按钮相对于屏幕右边偏移
  int? smsGetVerifyCodeBtnWidth; //设置获取验证码按钮宽度 only iOS
  int? smsGetVerifyCodeBtnHeight; //设置获取验证码按钮高度 only iOS
  int? smsGetVerifyCodeBtnCornerRadius; // 设置获取验证码按钮圆角度数 only iOS
  String? smsGetVerifyCodeBtnBackgroundPath; //设置获取验证码按钮图片
  List<String>?
      smsGetVerifyCodeBtnBackgroundPaths; //设置获取验证码按钮图片 [激活状态的图片,失效状态的图片,高亮状态的图片] only iOS
  String? smsGetVerifyCodeBtnText; //设置获取验证码按钮文字  only iOS
  //enableSmsGetVerifyCodeDialog;
  //smsGetVerifyCodeDialog
  int? smsLogBtnOffsetX; //设置登录按钮相对于屏幕左边 x 轴偏移
  int? smsLogBtnOffsetY; //设置登录按钮相对于标题栏下边缘 y 偏移
  int? smsLogBtnWidth; //设置登录按钮宽度
  int? smsLogBtnHeight; //设置登录按钮高度
  int? smsLogBtnTextSize; //设置登录按钮字体大小
  int? smsLogBtnBottomOffsetY; //	设置登录按钮相对屏幕底部 y 轴偏移
  String? smsLogBtnText; //设置登录按钮文字
  int? smsLogBtnTextColor; //设置登录按钮文字颜色
  bool? isSmsLogBtnTextBold; //	设置登录按钮字体是否加粗
  String? smsLogBtnBackgroundPath; //设置授权登录按钮图片
  String?
      smsLogBtnBackgroundPaths; //设置授权登录按钮图片 @[激活状态的图片,失效状态的图片,高亮状态的图片] only iOS
  int? smsFirstSeperLineOffsetX; //第一分割线相对于屏幕左边 x 轴偏移 only android
  int? smsFirstSeperLineOffsetY; //第一分割线相对于标题栏下边缘 y 偏移 only android
  int? smsFirstSeperLineOffsetR; //第一分割线相对于屏幕右边偏移 only android
  int? smsFirstSeperLineColor; //第一分割线颜色 only android
  int? smsSecondSeperLineOffsetX; //第二分割线相对于屏幕左边 x 轴偏移 only android
  int? smsSecondSeperLineOffsetY; //第二分割线相对于标题栏下边缘 y 偏移 only android
  int? smsSecondSeperLineOffsetR; //第二分割线相对于屏幕右边偏移 only android
  int? smsSecondSeperLineColor; //第二分割线颜色 only android
  bool? isSmsPrivacyTextGravityCenter; //设置隐私条款文字是否居中对齐（默认左对齐）
  List<int>? smsPrivacyColor; // 设置隐私条款名称颜色 [基础文字颜色，协议文字颜色] only iOS
  int?
      smsPrivacyTextVerAlignment; // 设置隐私条款垂直对齐方式 0:top 1:middle 2:bottom only iOS
  int? smsPrivacyOffsetX; //协议相对于屏幕左边 x 轴偏移
  int? smsPrivacyOffsetY; //协议相对于底部 y 偏移
  int? smsPrivacyTopOffsetY; //协议相对于标题栏下边缘 y 偏移
  int? smsPrivacyWidth; //协议宽度 only iOS
  int? smsPrivacyHeight; //协议高度 only iOS
  int? smsPrivacyMarginL; //设置协议相对于登录页左边的间距 only android
  int? smsPrivacyMarginR; //设置协议相对于登录页右边的间距 only android
  int? smsPrivacyMarginT; //设置协议相对于登录页顶部的间距 only android
  int? smsPrivacyMarginB; //设置协议相对于登录页底部的间距 only android
  int? smsPrivacyCheckboxSize; //设置隐私条款 checkbox 尺寸
  int? smsPrivacyCheckboxOffsetX; //设置隐私条款 checkbox 相对于屏幕左边 x 轴偏移 only iOS
  bool? isSmsPrivacyCheckboxInCenter; //设置隐私条款 checkbox 是否相对协议文字纵向居中
  bool? smsPrivacyCheckboxState; //设置隐私条款 checkbox 默认状态 : 是否选择 默认:NO
  List<int>? smsPrivacyCheckboxMargin; //设置协议相对于登录页的间距 only android
  String? smsPrivacyCheckboxUncheckedImgPath; // 设置隐私条款 checkbox 未选中时图片 only iOS
  String? smsPrivacyCheckboxCheckedImgPath; // 设置隐私条款 checkbox 选中时图片 only iOS
  List<JVPrivacy>? smsPrivacyBeanList; //设置协议内容
  String? smsPrivacyClauseStart; //设置协议条款开头文本
  String? smsPrivacyClauseEnd; //设置协议条款结尾文本
  // List<VerifyCustomView> smsCustomViews
  bool? enableSMSService; //如果开启了短信服务，在认证服务失败时，短信服务又可用的情况下拉起短信服务

  //android独占
  String? smsPrivacyUncheckedMsg; //短信协议没有被勾选的提示
  String? smsGetCodeFailMsg; //短信获取失败提示
  String? smsPhoneInvalidMsg; //手机号无效提示

  Map toJsonMap() {
    return {
      "smsAuthPageBackgroundImagePath": smsAuthPageBackgroundImagePath ??= null,
      "smsNavText": smsNavText ??= null,
      "smsNavTextColor": smsNavTextColor ??= null,
      "smsNavTextBold": smsNavTextBold ??= null,
      "smsNavTextSize": smsNavTextSize ??= null,
      "smsSloganTextSize": smsSloganTextSize ??= null,
      "isSmsSloganHidden": isSmsSloganHidden ??= null,
      "isSmsSloganTextBold": isSmsSloganTextBold ??= null,
      "smsSloganOffsetX": smsSloganOffsetX ??= null,
      "smsSloganOffsetY": smsSloganOffsetY ??= null,
      "smsSloganOffsetBottomY": smsSloganOffsetBottomY ??= null,
      "smsSloganWidth": smsSloganWidth ??= null,
      "smsSloganHeight": smsSloganHeight ??= null,
      "smsSloganTextColor": smsSloganTextColor ??= null,
      "smsLogoWidth": smsLogoWidth ??= null,
      "smsLogoHeight": smsLogoHeight ??= null,
      "smsLogoOffsetX": smsLogoOffsetX ??= null,
      "smsLogoOffsetY": smsLogoOffsetY ??= null,
      "smsLogoOffsetBottomY": smsLogoOffsetBottomY ??= null,
      "isSmsLogoHidden": isSmsLogoHidden ??= null,
      "smsLogoResName": smsLogoResName ??= null,
      "smsPhoneTextViewOffsetX": smsPhoneTextViewOffsetX ??= null,
      "smsPhoneTextViewOffsetY": smsPhoneTextViewOffsetY ??= null,
      "smsPhoneTextViewTextSize": smsPhoneTextViewTextSize ??= null,
      "smsPhoneTextViewTextColor": smsPhoneTextViewTextColor ??= null,
      "smsPhoneInputViewOffsetX": smsPhoneInputViewOffsetX ??= null,
      "smsPhoneInputViewOffsetY": smsPhoneInputViewOffsetY ??= null,
      "smsPhoneInputViewWidth": smsPhoneInputViewWidth ??= null,
      "smsPhoneInputViewHeight": smsPhoneInputViewHeight ??= null,
      "smsPhoneInputViewTextColor": smsPhoneInputViewTextColor ??= null,
      "smsPhoneInputViewTextSize": smsPhoneInputViewTextSize ??= null,
      "smsPhoneInputViewPlaceholderText": smsPhoneInputViewPlaceholderText ??=
          null,
      "smsPhoneInputViewBorderStyle":
          getStringFromEnum(smsPhoneInputViewBorderStyle),
      "smsVerifyCodeTextViewOffsetX": smsVerifyCodeTextViewOffsetX ??= null,
      "smsVerifyCodeTextViewOffsetY": smsVerifyCodeTextViewOffsetY ??= null,
      "smsVerifyCodeTextViewTextSize": smsVerifyCodeTextViewTextSize ??= null,
      "smsVerifyCodeTextViewTextColor": smsVerifyCodeTextViewTextColor ??= null,
      "smsVerifyCodeEditTextViewTextSize": smsVerifyCodeEditTextViewTextSize ??=
          null,
      "smsVerifyCodeEditTextViewTextColor":
          smsVerifyCodeEditTextViewTextColor ??= null,
      "smsVerifyCodeEditTextViewPlaceholderText":
          smsVerifyCodeEditTextViewPlaceholderText ??= null,
      "smsVerifyCodeEditTextViewOffsetX": smsVerifyCodeEditTextViewOffsetX ??=
          null,
      "smsVerifyCodeEditTextViewOffsetY": smsVerifyCodeEditTextViewOffsetY ??=
          null,
      "smsVerifyCodeEditTextViewOffsetR": smsVerifyCodeEditTextViewOffsetR ??=
          null,
      "smsVerifyCodeEditTextViewWidth": smsVerifyCodeEditTextViewWidth ??= null,
      "smsVerifyCodeEditTextViewHeight": smsVerifyCodeEditTextViewHeight ??=
          null,
      "smsVerifyCodeEditTextViewBorderStyle":
          getStringFromEnum(smsVerifyCodeEditTextViewBorderStyle),
      "smsGetVerifyCodeTextViewOffsetX": smsGetVerifyCodeTextViewOffsetX ??=
          null,
      "smsGetVerifyCodeTextViewOffsetY": smsGetVerifyCodeTextViewOffsetY ??=
          null,
      "smsGetVerifyCodeTextViewTextSize": smsGetVerifyCodeTextViewTextSize ??=
          null,
      "smsGetVerifyCodeTextViewTextColor": smsGetVerifyCodeTextViewTextColor ??=
          null,
      "smsGetVerifyCodeTextViewOffsetR": smsGetVerifyCodeTextViewOffsetR ??=
          null,
      "smsGetVerifyCodeBtnWidth": smsGetVerifyCodeBtnWidth ??= null,
      "smsGetVerifyCodeBtnHeight": smsGetVerifyCodeBtnHeight ??= null,
      "smsGetVerifyCodeBtnCornerRadius": smsGetVerifyCodeBtnCornerRadius ??=
          null,
      "smsGetVerifyCodeBtnBackgroundPath": smsGetVerifyCodeBtnBackgroundPath ??=
          null,
      "smsGetVerifyCodeBtnBackgroundPaths":
          smsGetVerifyCodeBtnBackgroundPaths ??= null,
      "smsGetVerifyCodeBtnText": smsGetVerifyCodeBtnText ??= null,
      "smsLogBtnOffsetX": smsLogBtnOffsetX ??= null,
      "smsLogBtnOffsetY": smsLogBtnOffsetY ??= null,
      "smsLogBtnWidth": smsLogBtnWidth ??= null,
      "smsLogBtnHeight": smsLogBtnHeight ??= null,
      "smsLogBtnTextSize": smsLogBtnTextSize ??= null,
      "smsLogBtnBottomOffsetY": smsLogBtnBottomOffsetY ??= null,
      "smsLogBtnText": smsLogBtnText ??= null,
      "smsLogBtnTextColor": smsLogBtnTextColor ??= null,
      "isSmsLogBtnTextBold": isSmsLogBtnTextBold ??= null,
      "smsLogBtnBackgroundPath": smsLogBtnBackgroundPath ??= null,
      "smsLogBtnBackgroundPaths": smsLogBtnBackgroundPaths ??= null,
      "smsFirstSeperLineOffsetX": smsFirstSeperLineOffsetX ??= null,
      "smsFirstSeperLineOffsetY": smsFirstSeperLineOffsetY ??= null,
      "smsFirstSeperLineOffsetR": smsFirstSeperLineOffsetR ??= null,
      "smsSecondSeperLineOffsetX": smsSecondSeperLineOffsetX ??= null,
      "smsSecondSeperLineOffsetY": smsSecondSeperLineOffsetY ??= null,
      "smsSecondSeperLineOffsetR": smsSecondSeperLineOffsetR ??= null,
      "smsFirstSeperLineColor": smsFirstSeperLineColor ??= null,
      "smsSecondSeperLineColor": smsSecondSeperLineColor ??= null,
      "isSmsPrivacyTextGravityCenter": isSmsPrivacyTextGravityCenter ??= null,
      "smsPrivacyColor": smsPrivacyColor ??= null,
      "smsPrivacyTextVerAlignment": smsPrivacyTextVerAlignment ??= null,
      "smsPrivacyOffsetX": smsPrivacyOffsetX ??= null,
      "smsPrivacyOffsetY": smsPrivacyOffsetY ??= null,
      "smsPrivacyTopOffsetY": smsPrivacyTopOffsetY ??= null,
      "smsPrivacyWidth": smsPrivacyWidth ??= null,
      "smsPrivacyHeight": smsPrivacyHeight ??= null,
      "smsPrivacyMarginL": smsPrivacyMarginL ??= null,
      "smsPrivacyMarginR": smsPrivacyMarginR ??= null,
      "smsPrivacyMarginT": smsPrivacyMarginT ??= null,
      "smsPrivacyMarginB": smsPrivacyMarginB ??= null,
      "smsPrivacyCheckboxSize": smsPrivacyCheckboxSize ??= null,
      "smsPrivacyCheckboxOffsetX": smsPrivacyCheckboxOffsetX ??= null,
      "isSmsPrivacyCheckboxInCenter": isSmsPrivacyCheckboxInCenter ??= null,
      "smsPrivacyCheckboxState": smsPrivacyCheckboxState ??= null,
      "smsPrivacyCheckboxMargin": smsPrivacyCheckboxMargin ??= null,
      "smsPrivacyCheckboxUncheckedImgPath":
          smsPrivacyCheckboxUncheckedImgPath ??= null,
      "smsPrivacyCheckboxCheckedImgPath": smsPrivacyCheckboxCheckedImgPath ??=
          null,
      "smsPrivacyBeanList":
          smsPrivacyBeanList != null ? json.encode(smsPrivacyBeanList) : null,
      "smsPrivacyClauseStart": smsPrivacyClauseStart ??= null,
      "smsPrivacyClauseEnd": smsPrivacyClauseEnd ??= null,
      "smsPrivacyUncheckedMsg": smsPrivacyUncheckedMsg ??= null,
      "smsGetCodeFailMsg": smsGetCodeFailMsg ??= null,
      "smsPhoneInvalidMsg": smsPhoneInvalidMsg ??= null,
      "enableSMSService": enableSMSService ??= null,
    }..removeWhere((key, value) => value == null);
  }
}

/// 自定义控件
class JVCustomWidget {
  String? widgetId;
  JVCustomWidgetType? type;

  JVCustomWidget(this.widgetId, this.type) {
    this.widgetId = widgetId;
    this.type = type;
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

  String title = "";
  double titleFont = 13.0;
  int titleColor = Colors.black.value;
  int? backgroundColor;
  String? btnNormalImageName;
  String? btnPressedImageName;
  JVTextAlignmentType? textAlignment;

  int lines = 1;

  /// textView 行数，
  bool isSingleLine = true;

  /// textView 是否单行显示，默认：单行，iOS 端无效
  /* 若 isSingleLine = false 时，iOS 端 lines 设置失效，会自适应内容高度，最大高度为设置的 height */

  bool isShowUnderline = false;

  ///是否显示下划线，默认：不显示
  bool isClickEnable = false;

  ///是否可点击，默认：不可点击

  Map toJsonMap() {
    return {
      "widgetId": widgetId,
      "type": getStringFromEnum(type),
      "title": title,
      "titleFont": titleFont,
      "textAlignment": getStringFromEnum(textAlignment),
      "titleColor": titleColor,
      "backgroundColor": backgroundColor,
      "isShowUnderline": isShowUnderline,
      "isClickEnable": isClickEnable,
      "btnNormalImageName": btnNormalImageName,
      "btnPressedImageName": btnPressedImageName,
      "lines": lines,
      "isSingleLine": isSingleLine,
      "left": left,
      "top": top,
      "width": width,
      "height": height,
    }..removeWhere((key, value) => value == null);
  }
}

/// 添加自定义控件类型，目前只支持 textView
enum JVCustomWidgetType { textView, button }

/// 文本对齐方式
enum JVTextAlignmentType { left, right, center }

/// SMS监听返回类
class JVSMSEvent {
  int?
      code; //返回码，具体事件返回码请查看（https://docs.jiguang.cn/jverification/client/android_api/）
  String? message; //事件描述、事件返回值等
  String? phone; //电话号

  JVSMSEvent.fromJson(Map<dynamic, dynamic> json)
      : code = json['code'],
        message = json['message'],
        phone = json['phone'];

  Map toMap() {
    return {'code': code, 'message': message, 'phone': phone};
  }
}

/// 监听返回类
class JVListenerEvent {
  int?
      code; //返回码，具体事件返回码请查看（https://docs.jiguang.cn/jverification/client/android_api/）
  String? message; //事件描述、事件返回值等
  String? operator; //成功时为对应运营商，CM代表中国移动，CU代表中国联通，CT代表中国电信。失败时可能为null

  JVListenerEvent.fromJson(Map<dynamic, dynamic> json)
      : code = json['code'],
        message = json['message'],
        operator = json['operator'];

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
    return {
      'code': code,
      'message': message,
    };
  }
}

/// SDK 初始化回调事件
class JVSDKSetupEvent extends JVAuthPageEvent {
  @override
  JVSDKSetupEvent.fromJson(Map<dynamic, dynamic> json) : super.fromJson(json);
}

/*
* iOS 布局参照 item (Android 只)
*
* ItemNone    不参照任何item。可用来直接设置 Y、width、height
* ItemLogo    参照logo视图
* ItemNumber  参照号码栏
* ItemSlogan  参照标语栏
* ItemLogin   参照登录按钮
* ItemCheck   参照隐私选择框
* ItemPrivacy 参照隐私栏
* ItemSuper   参照父视图
* */
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

/*
*
* iOS授权界面弹出模式
* 注意：窗口模式下不支持 PartialCurl
*
*
* */
enum JVIOSUIModalTransitionStyle {
  CoverVertical,
  FlipHorizontal,
  CrossDissolve,
  PartialCurl
}

/*
*
* iOS状态栏设置，需要设置info.plist文件中
* View controller-based status barappearance值为YES
* 授权页和隐私页状态栏才会生效
*
* */
enum JVIOSBarStyle {
  StatusBarStyleDefault, // Automatically chooses light or dark content based on the user interface style
  StatusBarStyleLightContent, // Light content, for use on dark backgrounds iOS 7 以上
  StatusBarStyleDarkContent // Dark content, for use on light backgrounds  iOS 13 以上
}

/*
*
* iOS 输入框边框样式
*
* */
enum JVIOSTextBorderStyle {
  BorderStyleNone,
  BorderStyleLine,
  BorderStyleBezel,
  BorderStyleRoundedRect
}

String getStringFromEnum<T>(T) {
  if (T == null) {
    return "";
  }

  return T.toString().split('.').last;
}

class JVPrivacy {
  String? name;
  String? url;
  String? beforeName;
  String? afterName;
  String? separator; //ios分隔符专属

  JVPrivacy(this.name, this.url,
      {this.beforeName, this.afterName, this.separator});

  Map toMap() {
    return {
      'name': name,
      'url': url,
      'beforeName': beforeName,
      'afterName': afterName,
      'separator': separator
    };
  }

  Map toJson() {
    Map map = new Map();
    map["name"] = this.name;
    map["url"] = this.url;
    map["beforeName"] = this.beforeName;
    map["afterName"] = this.afterName;
    map["separator"] = this.separator;
    return map..removeWhere((key, value) => value == null);
  }
}
