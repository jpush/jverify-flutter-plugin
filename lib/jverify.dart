import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 监听添加的自定义控件的点击事件
typedef JVClickWidgetEventListener = void Function(String widgetId);

/// 授权页事件回调 @since 2.4.0
typedef JVAuthPageEventListener = void Function(JVAuthPageEvent event);

/// Android 授权页系统返回键事件回调 @since Android SDK 3.4.8
typedef JVAuthPageBackPressedListener = void Function();
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

class s {
  s._interna();
}

class JVEventHandlers {
  JVEventHandlers();

  Map<String, JVClickWidgetEventListener> clickEventsMap =
      Map<String, JVClickWidgetEventListener>();
  List<JVAuthPageEventListener> authPageEvents = [];
  List<JVLoginAuthCallBackListener> loginAuthCallBackEvents = [];
  JVAuthPageBackPressedListener? authPageBackPressedListener;
  JVSDKSetupCallBackListener? sdkSetupCallBackListener;

  int loginAuthIndex = 0;
  int smsAuthIndex = 0;
  Map<int, JVAuthPageEventListener> authPageEventsMap = {};
  Map<int, JVLoginAuthCallBackListener> loginAuthCallBackEventsMap = {};
  Map<int, JVSMSListener> smsCallBackEventsMap = {};
  Map<int, JVAuthPageEventListener> smsAuthPageEventsMap = {};
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

  /// 移除指定自定义控件的点击事件监听。
  bool removeClikWidgetEventListener(String eventId) {
    return _eventHanders.clickEventsMap.remove(eventId) != null;
  }

  /// 移除全部自定义控件点击事件监听。
  void removeCustomViewsClickCallback() {
    _eventHanders.clickEventsMap.clear();
  }

  /// 授权页的点击事件， @since v2.4.0
  addAuthPageEventListener(JVAuthPageEventListener callback) {
    _eventHanders.authPageEvents.add(callback);
  }

  /// 移除指定授权页持续事件监听。
  bool removeAuthPageEventListener(JVAuthPageEventListener callback) {
    return _eventHanders.authPageEvents.remove(callback);
  }

  /// 移除全部授权页持续事件监听，与 HarmonyOS `offAuthPageEvent` 语义一致。
  void offAuthPageEvent() {
    _eventHanders.authPageEvents.clear();
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
          final dynamic index = json["loginAuthIndex"];

          for (JVAuthPageEventListener cb in _eventHanders.authPageEvents) {
            cb(ev);
          }

          if (index is int &&
              _eventHanders.authPageEventsMap.containsKey(index)) {
            _eventHanders.authPageEventsMap[index]!(ev);
          }
        }
        break;
      case 'onReceiveAuthPageBackPressedEvent':
        {
          _eventHanders.authPageBackPressedListener?.call();
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
            _eventHanders.authPageEventsMap.remove(index);
          }

          // 老版 callback：先取快照再清理，避免迭代期修改 List 导致异常。
          final List<JVLoginAuthCallBackListener> callbacks =
              List<JVLoginAuthCallBackListener>.of(
                  _eventHanders.loginAuthCallBackEvents);
          _eventHanders.loginAuthCallBackEvents.clear();
          for (JVLoginAuthCallBackListener cb in callbacks) {
            cb(event);
          }
        }
        break;
      case 'onReceiveSMSAuthPageEvent':
        {
          Map json = call.arguments.cast<dynamic, dynamic>();
          JVAuthPageEvent ev = JVAuthPageEvent.fromJson(json);
          int index = json["smsAuthIndex"];

          if (_eventHanders.smsAuthPageEventsMap.containsKey(index)) {
            _eventHanders.smsAuthPageEventsMap[index]!(ev);
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
            _eventHanders.smsAuthPageEventsMap.remove(index);
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
      {String? appKey,
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

  /// 合规采集开关。HarmonyOS 原生 SDK 暂无对应接口，调用时仅输出警告日志。
  void setCollectionAuth(bool auth) {
    print("$flutter_log" + "setCollectionAuth");
    _channel.invokeMethod("setCollectionAuth", {"auth": auth});
  }

  /// 设置前后两次获取验证码的时间间隔，默认 30000ms，有效范围(0,300000)。
  /// HarmonyOS 原生 SDK 暂无短信验证码能力，调用时仅输出警告日志。
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
   * HarmonyOS 原生 SDK 暂无短信验证码能力，返回 code=-2 和警告信息。
   * */
  Future<Map<dynamic, dynamic>> getSMSCode(
      {String? phoneNum, String? signId, String? tempId}) async {
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
   *          value = bool,是否支持
   *
   *          key = "extra"
   *          value = {"operatorType":""}  //operatorType：UNKNOW-未知；CM-移动；CU-联通；CT- 电信；CMHK-中国移动香港
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
      var para = {
        "timeOut": timeOut,
      };
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
   * HarmonyOS 支持预取号，但不支持 enableSms，传 true 时会输出警告并忽略。
   *
   * return Map
   *        key = "code", vlaue = 状态码，7000代表获取成功
   *        key = "message", value = 结果信息描述
   * */
  Future<Map<dynamic, dynamic>> preLogin(
      {int timeOut = 10000, bool enableSms = false}) async {
    var para = new Map();
    if (timeOut >= 3000 && timeOut <= 10000) {
      para["timeOut"] = timeOut;
    }
    para["enableSms"] = enableSms;
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
   * 获取 预取号缓存状态
   *
   * return Map
   *          key = "result"
   *          value = bool,是否有效
   * */
  Future<Map<dynamic, dynamic>> validPreloginCache() async {
    print("$flutter_log" + "validPreloginCache");
    return await _channel.invokeMethod("validPreloginCache");
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
  void loginAuthSyncApi({bool autoDismiss = false, int timeout = 10000}) {
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
  * @param enableSms     是否开启短信登录切换服务；HarmonyOS 暂不支持，传 true 时输出警告并忽略
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
  * 短信登录。HarmonyOS 原生 SDK 暂无对应能力，回调 code=-2 并输出警告日志。
  *
  * @param autoDismiss  设置登录完成后是否自动关闭授权页
  * @param timeout      设置超时时间，单位毫秒。 合法范围（0，10000],若小于等于 0 则取默认值 5000. 大于 10000 则取 10000
  *
  * 接口回调返回数据监听：通过添加 JVSMSListener 监听，来监听接口的返回结果
  * pageEventCallback 事件监听 iOS only
  *
  * */
  void smsAuth(
      {required bool autoDismiss,
      int timeout = 5000,
      JVSMSListener? smsCallback,
      JVAuthPageEventListener? pageEventCallback}) {
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
      if (pageEventCallback != null) {
        _eventHanders.smsAuthPageEventsMap[_eventHanders.smsAuthIndex] =
            pageEventCallback;
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
      if (landscapeConfig == null) {
        print("missing Android landscape ui config");
        return;
      }
    }

    var para = Map();
    para["isAutorotate"] = isAutorotate;

    var para1 = portraitConfig.toJsonMap();
    para1.removeWhere((key, value) => value == null);
    para["portraitConfig"] = para1;
    if (portraitConfig.authPageBackPressedListener != null) {
      _eventHanders.authPageBackPressedListener =
          portraitConfig.authPageBackPressedListener;
    }

    if (landscapeConfig != null) {
      var para2 = landscapeConfig.toJsonMap();
      para2.removeWhere((key, value) => value == null);
      para["landscapeConfig"] = para2;
      if (landscapeConfig.authPageBackPressedListener != null) {
        _eventHanders.authPageBackPressedListener =
            landscapeConfig.authPageBackPressedListener;
      }
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
    if (uiConfig.authPageBackPressedListener != null) {
      _eventHanders.authPageBackPressedListener =
          uiConfig.authPageBackPressedListener;
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

    _channel.invokeMethod("setCustomAuthViewAllWidgets", para);
  }
}

/*
* 自定义 UI 界面配置类
*
* Y 轴
*     iOS       以导航栏底部为 0 作为起点
*     Android   以导航栏底部为 0 作为起点
*     HarmonyOS 由原生 JVerifyUIConfigBuilder 按 vp 解释，具体起点随控件类型而定
* X 轴
*     iOS       以屏幕中心为 0 作为起点，往屏幕左侧则减，往右侧则加，如果不传或者传 null，则默认屏幕居中
*     Android   以屏幕左侧为 0 作为起点，往右侧则加，如果不传或者传 null，则默认屏幕居中
*     HarmonyOS 传 -1 表示水平居中，其余值按原生 SDK 的 vp 偏移解释
* */
class JVUIConfig {
  ///语言
  ///0.中文简体（默认） 1.中文繁体 2.英文
  String? appLanguageType; // HarmonyOS 仅中国移动生效

  /// 授权页背景图片
  String? authBackgroundImage; // HarmonyOS 仅联通/电信生效
  String? authBGGifPath; // 授权界面gif图片，HarmonyOS 仅联通/电信生效
  String? authBGVideoPath; // 授权界面video，HarmonyOS 仅联通/电信生效
  String? authBGVideoImgPath; // 授权界面video的第一帧图片，HarmonyOS 仅联通/电信生效
  JVAuthBGVideoScaleType? authBGVideoScaleType; // Android 授权界面video缩放模式

  /// HarmonyOS 联通/电信，授权页字体是否跟随系统字体大小，默认 true
  bool? harmonyAuthPageFontFollowSystem;

  /// HarmonyOS 联通/电信，授权页顶部安全区高度，单位 vp
  int? harmonyTopSafeAreaHeight;

  /// HarmonyOS 联通/电信，授权页底部安全区高度，单位 vp
  int? harmonyBottomSafeAreaHeight;

  /// HarmonyOS 联通/电信，是否使用 Stack 布局定位号码、slogan、登录按钮和隐私区域
  bool? harmonyStackLayout;

  /// 导航栏
  int? navColor; // HarmonyOS 仅中国移动 Builder 生效
  String? navText; // iOS/Android only，HarmonyOS 1.2.2 无对应导航栏标题字段
  int? navTextColor; // HarmonyOS 仅中国移动 Builder 生效
  String? navReturnImgPath;
  int? navReturnBtnOffsetX;
  int? navReturnBtnOffsetY;

  /// HarmonyOS 联通/电信，返回按钮宽度，单位 vp
  int? harmonyReturnBtnWidth;

  /// HarmonyOS 联通/电信，返回按钮高度，单位 vp
  int? harmonyReturnBtnHeight;

  bool navHidden = false; // HarmonyOS 仅联通/电信生效
  bool navReturnBtnHidden = false; // HarmonyOS 仅联通/电信生效
  bool navTransparent = false; // iOS/Android only
  bool? navTextBold; // iOS/Android only
  bool? navBarDarkMode; //Android only

  /// logo
  int? logoWidth; // HarmonyOS 仅联通/电信生效
  int? logoHeight; // HarmonyOS 仅联通/电信生效
  int? logoOffsetX; // HarmonyOS 仅联通/电信生效
  int? logoOffsetY; // HarmonyOS 仅联通/电信生效
  int? logoOffsetBottomY; // iOS only，HarmonyOS 不生效
  JVIOSLayoutItem? logoVerticalLayoutItem; // iOS only，HarmonyOS 不生效
  bool? logoHidden; // HarmonyOS 仅联通/电信生效
  String? logoImgPath; // HarmonyOS 仅联通/电信生效

  /// 号码
  int? numberColor;
  int? numberSize;
  bool? numberTextBold;
  int? numFieldOffsetX;
  int? numFieldOffsetY;
  int? numberFieldWidth;
  int? numberFieldHeight;
  JVIOSLayoutItem? numberVerticalLayoutItem; // iOS only，HarmonyOS 不生效
  int? numberFieldOffsetBottomY; // iOS/Android only，HarmonyOS 不生效

  /// slogan
  int? sloganOffsetX; // HarmonyOS 仅联通/电信生效
  int? sloganOffsetY; // HarmonyOS 仅联通/电信生效
  int? sloganBottomOffsetY; // iOS/Android only，HarmonyOS 不生效
  JVIOSLayoutItem? sloganVerticalLayoutItem; // iOS only，HarmonyOS 不生效
  int? sloganTextColor; // HarmonyOS 仅联通/电信生效
  int? sloganTextSize; // HarmonyOS 仅联通/电信生效
  int? sloganWidth; // iOS only，HarmonyOS 不生效
  int? sloganHeight; // iOS only，HarmonyOS 不生效
  bool? sloganTextBold; // HarmonyOS 仅联通/电信生效
  bool sloganHidden = false; // HarmonyOS 不生效

  /// 登录按钮
  int? logBtnOffsetX;
  int? logBtnOffsetY;
  int? logBtnBottomOffsetY; // iOS/Android only，HarmonyOS 不生效
  int? logBtnWidth;
  int? logBtnHeight;
  JVIOSLayoutItem? logBtnVerticalLayoutItem; // iOS only，HarmonyOS 不生效
  String? logBtnText;
  int? logBtnTextSize;
  int? logBtnTextColor;
  bool? logBtnTextBold; // HarmonyOS 仅联通/电信生效
  String? logBtnBackgroundPath;
  String? loginBtnNormalImage; // iOS/Android only，HarmonyOS 不生效
  String? loginBtnPressedImage; // iOS/Android only，HarmonyOS 不生效
  String? loginBtnUnableImage; // iOS/Android only，HarmonyOS 不生效

  /// HarmonyOS，登录按钮背景颜色（ARGB int）
  int? harmonyLogBtnBackgroundColor;

  /// HarmonyOS，登录按钮圆角，单位 vp
  int? harmonyLogBtnBorderRadius;

  /// 隐私协议栏
  String? uncheckedImgPath;
  String? checkedImgPath;
  int? privacyCheckboxOffsetX; // HarmonyOS 仅中国移动生效
  int? privacyCheckboxOffsetY; // HarmonyOS 仅中国移动生效
  int? privacyCheckboxSize; //隐私同意框尺寸
  bool privacyHintToast =
      true; // HarmonyOS 自定义文案请使用 harmonyPrivacyHintToastText
  bool privacyState = false; //设置隐私条款默认选中状态，默认不选中
  bool privacyCheckboxHidden = false; // iOS/Android only，HarmonyOS 不生效
  bool privacyCheckboxInCenter =
      false; //设置隐私条款checkbox是否相对协议文字纵向居中；HarmonyOS 仅联通/电信生效
  bool openPrivacyInBrowser = false; // iOS/Android only，HarmonyOS 不生效

  /// HarmonyOS，未勾选隐私协议时的 Toast 文案
  String? harmonyPrivacyHintToastText;

  /// HarmonyOS，隐私条款开头文本；未设置时复用 privacyText[0]
  String? harmonyPrivacyClauseStart;

  /// HarmonyOS，隐私条款结尾文本；未设置时复用 privacyText[1]
  String? harmonyPrivacyClauseEnd;

  int? privacyOffsetY; // 隐私条款相对于授权页面底部下边缘 y 偏移
  int? privacyOffsetX; // 隐私条款相对于屏幕左边 x 轴偏移

  int? privacyMarginR; // Android/HarmonyOS 协议右边距
  int? privacyMarginT; // Android only；HarmonyOS 请使用 privacyTopOffsetY

  JVIOSLayoutItem privacyVerticalLayoutItem =
      JVIOSLayoutItem.ItemSuper; // iOS only，HarmonyOS 不生效
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
  int? textVerAlignment = 1; // iOS only，HarmonyOS 不生效
  int? privacyTopOffsetY;
  bool? privacyTextBold;
  bool? privacyUnderlineText; //设置隐私条款文字字体是否加下划线；HarmonyOS 仅联通/电信生效
  bool? isAlertPrivacyVc; //未勾选隐私协议时弹窗提示；HarmonyOS 仅联通/电信生效

  /// 隐私协议 web 页 UI 配置
  int? privacyNavColor; // 导航栏颜色；HarmonyOS 仅联通/电信生效
  int? privacyNavTitleTextColor; // 标题颜色；HarmonyOS 仅联通/电信生效
  int? privacyNavTitleTextSize; // 标题大小；HarmonyOS 仅联通/电信生效
  bool? privacyNavTitleTextBold; // 标题字体加粗；HarmonyOS 仅联通/电信生效
  String? privacyNavTitleTitle; // iOS only，HarmonyOS 不生效
  String? privacyNavTitleTitle1; // Android/iOS；HarmonyOS 使用协议 name
  String? privacyNavTitleTitle2; // Android/iOS；HarmonyOS 使用协议 name
  String? privacyNavReturnBtnImage;
  JVIOSBarStyle? privacyStatusBarStyle; //隐私协议web页 状态栏样式设置 ios only

  ///隐私页
  bool privacyStatusBarColorWithNav = false; //隐私页web状态栏是否与导航栏同色 android only
  bool privacyStatusBarDarkMode = false; //隐私页web状态栏是否暗色 android only
  bool privacyStatusBarTransparent = false; //隐私页web页状态栏是否透明 android only
  bool privacyStatusBarHidden = false; //隐私页web页状态栏是否隐藏 android only
  bool privacyVirtualButtonTransparent = false; //隐私页web页虚拟按键背景是否透明 android only
  int? privacyVirtualButtonColor; //设置隐私界面底部虚拟导航栏背景 android only

  ///授权页
  bool statusBarColorWithNav = false; //授权页状态栏是否跟导航栏同色 android only
  bool statusBarDarkMode = false; //授权页状态栏是否为暗色 android only
  bool statusBarTransparent = false; //授权页栏状态栏是否透明 android only
  bool statusBarHidden = false; //授权页状态栏是否隐藏 android only
  bool virtualButtonTransparent = false; //授权页虚拟按键背景是否透明 android only
  int? virtualButtonColor; //设置授权页底部虚拟导航栏背景 android only
  bool? virtualButtonHidden; //设置授权页底部虚拟导航栏是否隐藏 android only

  JVIOSBarStyle authStatusBarStyle =
      JVIOSBarStyle.StatusBarStyleDefault; //授权页状态栏样式设置 ios only

  ///是否需要动画
  bool needStartAnim = false; // iOS/Android only，HarmonyOS 不生效
  bool needCloseAnim = false; // iOS/Android only，HarmonyOS 不生效
  String? enterAnim; // Android 与 HarmonyOS 中国移动生效
  String? exitAnim; // Android 与 HarmonyOS 中国移动生效

  /// 授权页弹窗模式 配置，选填
  JVPopViewConfig? popViewConfig;

  /// Android/HarmonyOS 协议二次弹窗配置，HarmonyOS 仅映射原生 Builder 支持字段
  JVPrivacyCheckDialogConfig? privacyCheckDialogConfig;

  JVIOSUIModalTransitionStyle modelTransitionStyle = //弹出方式 ios only
      JVIOSUIModalTransitionStyle.CoverVertical;

  /// 协议二次弹窗-iOS
  double agreementAlertViewCornerRadius = 5.0; // 协议二次弹窗的圆角
  int? agreementAlertViewBackgroundColor; // 协议二次弹窗背景颜色
  String? agreementAlertViewBackgroundImgPath; //协议二次弹窗背景图片
  String? agreementAlertViewTitleText; //协议二次弹窗标题文本
  int agreementAlertViewTitleTexSize = 14; // 协议二次弹窗标题文本样式
  int? agreementAlertViewTitleTextColor; //协议二次弹窗标题文本颜色
  JVTextAlignmentType agreementAlertViewContentTextAlignment =
      JVTextAlignmentType.center; //协议二次弹窗内容文本对齐方式
  int agreementAlertViewContentTextFontSize = 12; //协议二次弹窗内容文本字体大小
  String? agreementAlertViewLogBtnText; //协议二次弹窗登录按钮文本
  int? agreementAlertViewLogBtnTextFontSize; //协议二次弹窗登录按钮文本字体大小
  String? agreementAlertViewLoginBtnNormalImagePath; // 协议二次弹窗登录按钮背景图片 - 激活状态的图片
  String?
      agreementAlertViewLoginBtnPressedImagePath; // 协议二次弹窗登录按钮背景图片 - 高亮状态的图片
  String? agreementAlertViewLoginBtnUnableImagePath; //协议二次弹窗登录按钮背景图片 - 失效状态的图片
  int? agreementAlertViewLogBtnTextColor; //协议二次弹窗登录按钮文本颜色
  List<JVCustomWidget>? agreementAlertViewWidgets; //协议二次弹窗自定义视图
  Map<String, List<int>>?
      agreementAlertViewUIFrames; // 协议二次弹窗各控件的frame设置 { "superViewFrame": [left, top, width, height],"alertViewFrame": [left, top, width, height],"titleFrame": [left, top, width, height],"contentFrame": [left, top, width, height],"buttonFrame": [left, top, width, height]};
  bool setIsPrivacyViewDarkMode = true; // Android only，HarmonyOS 不生效
  /// 是否在 window 中间显示协议弹窗
  bool agreementAlertViewShowWindow = true;

  /// Android 授权页系统返回键监听；HarmonyOS 仅中国移动生效
  JVAuthPageBackPressedListener? authPageBackPressedListener;

  /// SMS UI；HarmonyOS 原生 SDK 无短信页面，设置后不生效并输出 warning
  JVSMSUIConfig? smsUIConfig;

  /// HarmonyOS 中国移动专用 UI 配置；联通/电信忽略这些字段
  JVHarmonyCMUIConfig? harmonyCmUIConfig;

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
      "appLanguageType": appLanguageType ??= null,
      "authBackgroundImage": authBackgroundImage ??= null,
      "authBGGifPath": authBGGifPath ??= null,
      "authBGVideoPath": authBGVideoPath ??= null,
      "authBGVideoImgPath": authBGVideoImgPath ??= null,
      "authBGVideoScaleType":
          getValueFromAuthBGVideoScaleType(authBGVideoScaleType),
      "harmonyAuthPageFontFollowSystem": harmonyAuthPageFontFollowSystem,
      "harmonyTopSafeAreaHeight": harmonyTopSafeAreaHeight,
      "harmonyBottomSafeAreaHeight": harmonyBottomSafeAreaHeight,
      "harmonyStackLayout": harmonyStackLayout,
      "authPageBackPressedListener":
          authPageBackPressedListener != null ? true : null,
      "navColor": navColor ??= null,
      "navText": navText ??= null,
      "navTextColor": navTextColor ??= null,
      "navTextBold": navTextBold ??= null,
      "navBarDarkMode": navBarDarkMode ??= null,
      "navReturnImgPath": navReturnImgPath ??= null,
      "navReturnBtnOffsetX": navReturnBtnOffsetX ??= null,
      "navReturnBtnOffsetY": navReturnBtnOffsetY ??= null,
      "harmonyReturnBtnWidth": harmonyReturnBtnWidth,
      "harmonyReturnBtnHeight": harmonyReturnBtnHeight,
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
      "harmonyLogBtnBackgroundColor": harmonyLogBtnBackgroundColor,
      "harmonyLogBtnBorderRadius": harmonyLogBtnBorderRadius,
      "uncheckedImgPath": uncheckedImgPath ??= null,
      "checkedImgPath": checkedImgPath ??= null,
      "privacyCheckboxOffsetX": privacyCheckboxOffsetX ??= null,
      "privacyCheckboxOffsetY": privacyCheckboxOffsetY ??= null,
      "privacyCheckboxSize": privacyCheckboxSize ??= null,
      "privacyHintToast": privacyHintToast,
      "privacyOffsetY": privacyOffsetY ??= null,
      "privacyOffsetX": privacyOffsetX ??= null,
      "privacyMarginR": privacyMarginR ??= null,
      "privacyMarginT": privacyMarginT ??= null,
      "privacyTopOffsetY": privacyTopOffsetY ??= null,
      "privacyVerticalLayoutItem": getStringFromEnum(privacyVerticalLayoutItem),
      "privacyText": privacyText ??= null,
      "privacyTextSize": privacyTextSize ??= null,
      "privacyTextBold": privacyTextBold ??= null,
      "privacyUnderlineText": privacyUnderlineText ??= null,
      "isAlertPrivacyVc": isAlertPrivacyVc ??= null,
      "openPrivacyInBrowser": openPrivacyInBrowser,
      "harmonyPrivacyHintToastText": harmonyPrivacyHintToastText,
      "harmonyPrivacyClauseStart": harmonyPrivacyClauseStart,
      "harmonyPrivacyClauseEnd": harmonyPrivacyClauseEnd,
      "harmonyCmUIConfig": harmonyCmUIConfig?.toJsonMap(),
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
      "privacyVirtualButtonColor": privacyVirtualButtonColor,
      "statusBarColorWithNav": statusBarColorWithNav,
      "statusBarDarkMode": statusBarDarkMode,
      "statusBarTransparent": statusBarTransparent,
      "statusBarHidden": statusBarHidden,
      "virtualButtonTransparent": virtualButtonTransparent,
      "virtualButtonHidden": virtualButtonHidden,
      "virtualButtonColor": virtualButtonColor,

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
      "agreementAlertViewCornerRadius": agreementAlertViewCornerRadius,
      "agreementAlertViewBackgroundColor": agreementAlertViewBackgroundColor,
      "agreementAlertViewBackgroundImgPath":
          agreementAlertViewBackgroundImgPath,
      "agreementAlertViewTitleText": agreementAlertViewTitleText ??= null,
      "agreementAlertViewTitleTexSize": agreementAlertViewTitleTexSize,
      "agreementAlertViewTitleTextColor": agreementAlertViewTitleTextColor ??=
          0xFF000000,
      "agreementAlertViewContentTextAlignment":
          getStringFromEnum(agreementAlertViewContentTextAlignment),
      "agreementAlertViewContentTextFontSize":
          agreementAlertViewContentTextFontSize,
      "agreementAlertViewLogBtnText": agreementAlertViewLogBtnText,
      "agreementAlertViewLogBtnTextFontSize":
          agreementAlertViewLogBtnTextFontSize,
      "agreementAlertViewLoginBtnNormalImagePath":
          agreementAlertViewLoginBtnNormalImagePath ??= null,
      "agreementAlertViewLoginBtnPressedImagePath":
          agreementAlertViewLoginBtnPressedImagePath ??= null,
      "agreementAlertViewLoginBtnUnableImagePath":
          agreementAlertViewLoginBtnUnableImagePath ??= null,
      "agreementAlertViewLogBtnTextColor": agreementAlertViewLogBtnTextColor ??=
          0xFF000000,
      "agreementAlertViewWidgets": agreementAlertViewWidgetsList,
      "agreementAlertViewUIFrames": agreementAlertViewUIFrames ??= null,
      "privacyCheckDialogConfig": privacyCheckDialogConfig != null
          ? privacyCheckDialogConfig?.toJsonMap()
          : null,
      "setIsPrivacyViewDarkMode": setIsPrivacyViewDarkMode,
      "smsUIConfig": smsUIConfig != null ? smsUIConfig?.toJsonMap() : null,
      "agreementAlertViewShowWindow": agreementAlertViewShowWindow,
    }..removeWhere((key, value) => value == null);
  }
}

/// HarmonyOS 中国移动授权页的专用 UI 配置。
///
/// 这些字段直接对应 `GenAuthThemeConfigBuilder`，Android、iOS、联通和电信会忽略。
class JVHarmonyCMUIConfig {
  JVHarmonySystemBarConfig? systemBar;
  double? authPageGrayScale;
  int? navTextSize;
  JVHarmonyMargin? numberMargin;
  JVHarmonyAlignRule? numberAlignRule;
  double? numberWidth;
  double? numberHeight;
  double? clauseLineSpacing;
  JVHarmonyMargin? loginBtnMargin;
  JVHarmonyAlignRule? loginBtnAlignRule;
  int? loginBtnMarginRight;
  int? loginBtnBorderColor;
  double? loginBtnBorderWidth;
  int? loginBtnDisabledTextColor;
  int? loginBtnDisabledColor;
  String? loginBtnDisabledImgPath;
  int? loginBtnDisabledBorderColor;
  double? loginBtnDisabledBorderWidth;
  JVHarmonyMargin? checkBoxMargin;
  JVHarmonyAlignRule? checkBoxAlignRule;
  JVHarmonySize? checkBoxSize;
  int? checkBoxLocation;
  int? checkedColor;
  JVHarmonyCheckBoxShape? checkBoxShape;
  JVHarmonyTextAlign? clauseTextAlign;
  JVHarmonyMargin? clauseMargin;
  JVHarmonyAlignRule? clauseAlignRule;
  int? clauseNavMarginTop;
  double? privacyMarginRight;
  double? privacyOffsetY;
  double? privacyOffsetYB;
  String? activityIn;
  String? activityOut;
  double? windowWidth;
  double? windowHeight;
  double? windowX;
  double? windowY;
  double? windowBottom;
  int? themeId;
  bool? fitsSystemWindows;
  bool? useDefaultLoginButtonImage;
  String? defaultLoginButtonImagePath;
  List<JVHarmonyCMClause>? clauses;
  JVHarmonyCMLoginPageConfig? loginPage;
  JVHarmonyCMLoginConfirmDialogConfig? loginConfirmDialog;
  bool? webDomStorageEnabled;
  int? webCloseImgWidth;
  int? webCloseImgHeight;
  JVHarmonyMargin? webCloseImgMargin;
  JVHarmonyAlignRule? webCloseImgAlignRule;
  JVHarmonyWindowConfig? windowMode;

  Map<String, dynamic> toJsonMap() {
    return <String, dynamic>{
      'systemBar': systemBar?.toJsonMap(),
      'authPageGrayScale': authPageGrayScale,
      'navTextSize': navTextSize,
      'numberMargin': numberMargin?.toJsonMap(),
      'numberAlignRule': numberAlignRule?.toJsonMap(),
      'numberWidth': numberWidth,
      'numberHeight': numberHeight,
      'clauseLineSpacing': clauseLineSpacing,
      'loginBtnMargin': loginBtnMargin?.toJsonMap(),
      'loginBtnAlignRule': loginBtnAlignRule?.toJsonMap(),
      'loginBtnMarginRight': loginBtnMarginRight,
      'loginBtnBorderColor': loginBtnBorderColor,
      'loginBtnBorderWidth': loginBtnBorderWidth,
      'loginBtnDisabledTextColor': loginBtnDisabledTextColor,
      'loginBtnDisabledColor': loginBtnDisabledColor,
      'loginBtnDisabledImgPath': loginBtnDisabledImgPath,
      'loginBtnDisabledBorderColor': loginBtnDisabledBorderColor,
      'loginBtnDisabledBorderWidth': loginBtnDisabledBorderWidth,
      'checkBoxMargin': checkBoxMargin?.toJsonMap(),
      'checkBoxAlignRule': checkBoxAlignRule?.toJsonMap(),
      'checkBoxSize': checkBoxSize?.toJsonMap(),
      'checkBoxLocation': checkBoxLocation,
      'checkedColor': checkedColor,
      'checkBoxShape': checkBoxShape?.name,
      'clauseTextAlign': clauseTextAlign?.name,
      'clauseMargin': clauseMargin?.toJsonMap(),
      'clauseAlignRule': clauseAlignRule?.toJsonMap(),
      'clauseNavMarginTop': clauseNavMarginTop,
      'privacyMarginRight': privacyMarginRight,
      'privacyOffsetY': privacyOffsetY,
      'privacyOffsetYB': privacyOffsetYB,
      'activityIn': activityIn,
      'activityOut': activityOut,
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'windowX': windowX,
      'windowY': windowY,
      'windowBottom': windowBottom,
      'themeId': themeId,
      'fitsSystemWindows': fitsSystemWindows,
      'useDefaultLoginButtonImage': useDefaultLoginButtonImage,
      'defaultLoginButtonImagePath': defaultLoginButtonImagePath,
      'clauses': clauses?.map((item) => item.toJsonMap()).toList(),
      'loginPage': loginPage?.toJsonMap(),
      'loginConfirmDialog': loginConfirmDialog?.toJsonMap(),
      'webDomStorageEnabled': webDomStorageEnabled,
      'webCloseImgWidth': webCloseImgWidth,
      'webCloseImgHeight': webCloseImgHeight,
      'webCloseImgMargin': webCloseImgMargin?.toJsonMap(),
      'webCloseImgAlignRule': webCloseImgAlignRule?.toJsonMap(),
      'windowMode': windowMode?.toJsonMap(),
    }..removeWhere((key, value) => value == null);
  }
}

/// HarmonyOS ArkUI 宽高，数值单位为 vp。
class JVHarmonySize {
  final double width;
  final double height;

  const JVHarmonySize(this.width, this.height);

  Map<String, dynamic> toJsonMap() => <String, dynamic>{
        'width': width,
        'height': height,
      };
}

/// HarmonyOS 受控 ArkUI 自定义控件的图片配置。
///
/// [name] 是 `resources/base/media` 中不含扩展名的资源名；[source] 可直接
/// 传 ArkUI `Image` 支持的 URI/base64，并且优先于 [name]。
class JVHarmonyImageConfig {
  String? name;
  String? source;
  JVHarmonyImageFit fit;

  JVHarmonyImageConfig({
    this.name,
    this.source,
    this.fit = JVHarmonyImageFit.contain,
  });

  Map<String, dynamic> toJsonMap() => <String, dynamic>{
        'name': name,
        'source': source,
        'fit': fit.name,
      }..removeWhere((key, value) => value == null);
}

/// HarmonyOS 中国移动隐私协议片段。
class JVHarmonyCMClause {
  final String text;
  String? url;
  double fontSize;
  int fontColor;
  bool bold;
  bool isProtocol;

  JVHarmonyCMClause({
    required this.text,
    this.url,
    this.fontSize = 14,
    this.fontColor = 0xFF64748B,
    this.bold = false,
    this.isProtocol = false,
  });

  Map<String, dynamic> toJsonMap() => <String, dynamic>{
        'text': text,
        'url': url,
        'fontSize': fontSize,
        'fontColor': fontColor,
        'bold': bold,
        'isProtocol': isProtocol,
      }..removeWhere((key, value) => value == null);
}

/// HarmonyOS 中国移动授权页的叠加组件配置。
///
/// `setLoginPageComponent` 会把这里的内容叠加到 SDK 原生授权页之上；
/// 默认背景透明，仅在显式配置背景色或背景图时覆盖原生背景。
class JVHarmonyCMLoginPageConfig {
  bool showTitle;
  String title;
  double titleSize;
  int titleColor;
  int backgroundColor;

  /// `resources/base/media` 中的资源名，不含扩展名。
  String? backgroundImage;

  /// 可直接显示的图片 URI/base64；设置后优先于 [backgroundImage]。
  String? backgroundImageSource;
  List<JVHarmonyCMLoginPageWidget> widgets;

  JVHarmonyCMLoginPageConfig({
    this.showTitle = false,
    this.title = '极光认证',
    this.titleSize = 24,
    this.titleColor = 0xFF17233D,
    this.backgroundColor = 0x00000000,
    this.backgroundImage,
    this.backgroundImageSource,
    List<JVHarmonyCMLoginPageWidget>? widgets,
  }) : widgets = widgets ?? <JVHarmonyCMLoginPageWidget>[];

  Map<String, dynamic> toJsonMap() => <String, dynamic>{
        'showTitle': showTitle,
        'title': title,
        'titleSize': titleSize,
        'titleColor': titleColor,
        'backgroundColor': backgroundColor,
        'backgroundImage': backgroundImage,
        'backgroundImageSource': backgroundImageSource,
        'widgets': widgets.map((item) => item.toJsonMap()).toList(),
      }..removeWhere((key, value) => value == null);
}

/// HarmonyOS 中国移动自定义登录页上的文字、按钮或图片。
class JVHarmonyCMLoginPageWidget {
  final String id;
  String anchor;
  JVCustomWidgetType type;
  String text;
  double textSize;
  int textColor;
  int backgroundColor;
  double width;
  double height;
  double borderRadius;
  JVHarmonyImageConfig? image;
  JVHarmonyMargin margin;
  JVHarmonyCustomWidgetAction action;
  String? toastText;

  JVHarmonyCMLoginPageWidget({
    required this.id,
    this.anchor = 'loginBtn',
    this.type = JVCustomWidgetType.button,
    this.text = '',
    this.textSize = 16,
    this.textColor = 0xFFFFFFFF,
    this.backgroundColor = 0xFF359AF3,
    this.width = 180,
    this.height = 44,
    this.borderRadius = 22,
    this.image,
    JVHarmonyMargin? margin,
    this.action = JVHarmonyCustomWidgetAction.callback,
    this.toastText,
  }) : margin = margin ?? JVHarmonyMargin();

  Map<String, dynamic> toJsonMap() => <String, dynamic>{
        'id': id,
        'anchor': anchor,
        'type': getStringFromEnum(type),
        'text': text,
        'textSize': textSize,
        'textColor': textColor,
        'backgroundColor': backgroundColor,
        'width': width,
        'height': height,
        'borderRadius': borderRadius,
        'image': image?.toJsonMap(),
        'margin': margin.toJsonMap(),
        'action': action.name,
        'toastText': toastText,
      }..removeWhere((key, value) => value == null);
}

/// HarmonyOS 中国移动点击登录按钮后的确认弹窗。
class JVHarmonyCMLoginConfirmDialogConfig {
  String message;
  String confirmText;
  String cancelText;
  String confirmColor;
  String cancelColor;

  JVHarmonyCMLoginConfirmDialogConfig({
    this.message = '是否登录授权',
    this.confirmText = '确定',
    this.cancelText = '取消',
    this.confirmColor = '#000000',
    this.cancelColor = '#000000',
  });

  Map<String, dynamic> toJsonMap() => <String, dynamic>{
        'message': message,
        'confirmText': confirmText,
        'cancelText': cancelText,
        'confirmColor': confirmColor,
        'cancelColor': cancelColor,
      };
}

/// HarmonyOS 系统状态栏和导航栏配置，颜色使用 `#AARRGGBB`/`#RRGGBB` 字符串。
class JVHarmonySystemBarConfig {
  String? statusBarColor;
  bool? isStatusBarLightIcon;
  String? statusBarContentColor;
  String? navigationBarColor;
  bool? isNavigationBarLightIcon;
  String? navigationBarContentColor;
  bool? enableStatusBarAnimation;
  bool? enableNavigationBarAnimation;

  Map<String, dynamic> toJsonMap() {
    return <String, dynamic>{
      'statusBarColor': statusBarColor,
      'isStatusBarLightIcon': isStatusBarLightIcon,
      'statusBarContentColor': statusBarContentColor,
      'navigationBarColor': navigationBarColor,
      'isNavigationBarLightIcon': isNavigationBarLightIcon,
      'navigationBarContentColor': navigationBarContentColor,
      'enableStatusBarAnimation': enableStatusBarAnimation,
      'enableNavigationBarAnimation': enableNavigationBarAnimation,
    }..removeWhere((key, value) => value == null);
  }
}

/// HarmonyOS ArkUI Margin，数值单位为 vp。
class JVHarmonyMargin {
  double? left;
  double? right;
  double? top;
  double? bottom;

  JVHarmonyMargin({this.left, this.right, this.top, this.bottom});

  Map<String, dynamic> toJsonMap() {
    return <String, dynamic>{
      'left': left,
      'right': right,
      'top': top,
      'bottom': bottom,
    }..removeWhere((key, value) => value == null);
  }
}

/// HarmonyOS RelativeContainer 对齐规则。
class JVHarmonyAlignRule {
  JVHarmonyHorizontalRule? left;
  JVHarmonyHorizontalRule? right;
  JVHarmonyHorizontalRule? middle;
  JVHarmonyVerticalRule? top;
  JVHarmonyVerticalRule? bottom;
  JVHarmonyVerticalRule? center;

  Map<String, dynamic> toJsonMap() {
    return <String, dynamic>{
      'left': left?.toJsonMap(),
      'right': right?.toJsonMap(),
      'middle': middle?.toJsonMap(),
      'top': top?.toJsonMap(),
      'bottom': bottom?.toJsonMap(),
      'center': center?.toJsonMap(),
    }..removeWhere((key, value) => value == null);
  }
}

class JVHarmonyHorizontalRule {
  final String anchor;
  final JVHarmonyHorizontalAlign align;

  JVHarmonyHorizontalRule(this.anchor, this.align);

  Map<String, dynamic> toJsonMap() => <String, dynamic>{
        'anchor': anchor,
        'align': align.name,
      };
}

class JVHarmonyVerticalRule {
  final String anchor;
  final JVHarmonyVerticalAlign align;

  JVHarmonyVerticalRule(this.anchor, this.align);

  Map<String, dynamic> toJsonMap() => <String, dynamic>{
        'anchor': anchor,
        'align': align.name,
      };
}

/// HarmonyOS 中国移动授权页窗口模式。
///
/// [width]/[height] 使用 vp；也可改用 `widthPercent: '80%'`、
/// `heightPercent: '50%'` 表达百分比宽高。
class JVHarmonyWindowConfig {
  final double? width;
  final double? height;
  final String? widthPercent;
  final String? heightPercent;
  JVHarmonyDialogAlignment alignment;
  double offsetX;
  double offsetY;
  bool showInSubWindow;
  bool isModal;
  bool autoCancel;
  int maskColor;

  JVHarmonyWindowConfig({
    this.width,
    this.height,
    this.widthPercent,
    this.heightPercent,
    this.alignment = JVHarmonyDialogAlignment.center,
    this.offsetX = 0,
    this.offsetY = 0,
    this.showInSubWindow = false,
    this.isModal = true,
    this.autoCancel = true,
    this.maskColor = 0x33000000,
  });

  Map<String, dynamic> toJsonMap() => <String, dynamic>{
        'width': widthPercent ?? width,
        'height': heightPercent ?? height,
        'alignment': alignment.name,
        'offsetX': offsetX,
        'offsetY': offsetY,
        'showInSubWindow': showInSubWindow,
        'isModal': isModal,
        'autoCancel': autoCancel,
        'maskColor': maskColor,
      };
}

enum JVHarmonyHorizontalAlign { start, center, end }

enum JVHarmonyVerticalAlign { top, center, bottom }

enum JVHarmonyTextAlign { start, center, end }

/// HarmonyOS ArkUI `Image` 的缩放模式。
enum JVHarmonyImageFit { fill, contain, cover }

enum JVHarmonyCheckBoxShape { circle, roundedSquare }

enum JVHarmonyDialogAlignment {
  top,
  center,
  bottom,
  topStart,
  topEnd,
  centerStart,
  centerEnd,
  bottomStart,
  bottomEnd,
}

/// HarmonyOS 自定义控件点击后的原生动作。
enum JVHarmonyCustomWidgetAction {
  none,
  callback,
  dismissLoginAuth,
  closeCheckDialog,
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
  bool isBottom = false; // android only，窗口是否居屏幕底部。设置后 offsetCenterY 将失效，
  double popViewCornerRadius =
      5.0; // ios only，弹窗圆角大小，Android 从 AndroidManifest 配置中读取
  double backgroundAlpha =
      0.3; // ios only，背景的透明度，Android 从 AndroidManifest 配置中读取

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
  int? contentTextPaddingL; //协议二次弹窗协议内容左边距
  int? contentTextPaddingT; //协议二次弹窗协议内容上边距
  int? contentTextPaddingR; //协议二次弹窗协议内容右边距
  int? contentTextPaddingB; //协议二次弹窗协议内容下边距
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
  int? privacyBackgroundColor; //隐私协议二次弹窗背景色
  String? privacyBackgroundPath; //隐私协议二次弹窗背景图片

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
      "contentTextPaddingL": contentTextPaddingL,
      "contentTextPaddingT": contentTextPaddingT,
      "contentTextPaddingR": contentTextPaddingR,
      "contentTextPaddingB": contentTextPaddingB,
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
      "privacyBackgroundColor": privacyBackgroundColor,
      "privacyBackgroundPath": privacyBackgroundPath,
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
  int? smsNavTextColor; //导航栏标题颜色 ios only
  bool? smsNavTextBold; // 导航栏标题 是否加粗 ios only
  int? smsNavTextSize; //导航栏标题大小 ios only
  int? smsSloganTextSize; //设置 slogan 字体大小
  bool? isSmsSloganHidden; //设置 slogan 字体是否隐藏  android only
  bool? isSmsSloganTextBold; //设置 slogan 字体是否加粗 android only
  int? smsSloganOffsetX; //设置 slogan 相对于屏幕左边 x 轴偏移
  int? smsSloganOffsetY; //设置 slogan 相对于标题栏下边缘 y 偏移
  int? smsSloganOffsetBottomY; //设置 slogan 相对于屏幕底部下边缘 y 轴偏移
  int? smsSloganWidth; //设置 slogan 宽度  ios only
  int? smsSloganHeight; //设置 slogan 高度 ios only
  int? smsSloganTextColor; //设置移动 slogan 文字颜色
  int? smsLogoWidth; //设置 logo 宽度（单位：dp）
  int? smsLogoHeight; //设置 logo 高度（单位：dp）
  int? smsLogoOffsetX; //设置 logo 相对于屏幕左边 x 轴偏移
  int? smsLogoOffsetY; //设置 logo 相对于标题栏下边缘 y 偏移
  int? smsLogoOffsetBottomY; //	设置 logo 相对于屏幕底部 y 轴偏移
  bool? isSmsLogoHidden; //隐藏 logo
  String? smsLogoResName; //设置 logo 图片
  int? smsPhoneTextViewOffsetX; //设置号码标题相对于屏幕左边 x 轴偏移  android only
  int? smsPhoneTextViewOffsetY; //设置号码标题相对于相对于标题栏下边缘 y 偏移 android only
  int? smsPhoneTextViewTextSize; //设置号码标题字体大小  android only
  int? smsPhoneTextViewTextColor; //设置号码标题文字颜色  android only
  int? smsPhoneInputViewOffsetX; //设置号码输入框相对于屏幕左边 x 轴偏移
  int? smsPhoneInputViewOffsetY; //设置号码输入框相对于屏幕底部 y 轴偏移
  int? smsPhoneInputViewWidth; //设置号码输入框宽度
  int? smsPhoneInputViewHeight; //设置号码输入框高度
  int? smsPhoneInputViewTextColor; //设置手机号码输入框字体颜色
  int? smsPhoneInputViewTextSize; //设置手机号码输入框字体大小
  String? smsPhoneInputViewPlaceholderText; // 设置手机号码输入框提示词 ios only
  JVIOSTextBorderStyle? smsPhoneInputViewBorderStyle; //设置手机号码输入框样式 ios only
  int? smsVerifyCodeTextViewOffsetX; //设置验证码标题相对于屏幕左边 x 轴偏移  android only
  int? smsVerifyCodeTextViewOffsetY; //设置验证码标题相对于相对于标题栏下边缘 y 偏移  android only
  int? smsVerifyCodeTextViewTextSize; //设置验证码标题字体大小  android only
  int? smsVerifyCodeTextViewTextColor; //设置验证码标题文字颜色  android only
  int? smsVerifyCodeEditTextViewTextSize; //设置验证码输入框字体大小
  int? smsVerifyCodeEditTextViewTextColor; //设置验证码输入框字体颜色
  String? smsVerifyCodeEditTextViewPlaceholderText; // 设置验证码输入框提示词 ios only
  int? smsVerifyCodeEditTextViewOffsetX; //设置验证码输入框相对于屏幕左边 x 轴偏移
  int? smsVerifyCodeEditTextViewOffsetY; //设置验证码输入框相对于标题栏下边缘 y 偏移
  int? smsVerifyCodeEditTextViewOffsetR; //设置验证码输入框相对于屏幕右边偏移
  int? smsVerifyCodeEditTextViewWidth; //设置验证码输入框宽度
  int? smsVerifyCodeEditTextViewHeight; //设置验证码输入框高度
  JVIOSTextBorderStyle?
      smsVerifyCodeEditTextViewBorderStyle; //设置验证码输入框样式 ios only
  int? smsGetVerifyCodeTextViewOffsetX; //设置获取验证码按钮相对于屏幕左边 x 轴偏移
  int? smsGetVerifyCodeTextViewOffsetY; //设置获取验证码按钮相对于标题栏下边缘 y 偏移
  int? smsGetVerifyCodeTextViewTextSize; //设置获取验证码按钮字体大小
  int? smsGetVerifyCodeTextViewTextColor; //设置获取验证码按钮文字颜色
  int? smsGetVerifyCodeTextViewOffsetR; //设置获取验证码按钮相对于屏幕右边偏移
  int? smsGetVerifyCodeBtnWidth; //设置获取验证码按钮宽度 ios only
  int? smsGetVerifyCodeBtnHeight; //设置获取验证码按钮高度 ios only
  int? smsGetVerifyCodeBtnCornerRadius; // 设置获取验证码按钮圆角度数 ios only
  String? smsGetVerifyCodeBtnBackgroundPath; //设置获取验证码按钮图片
  List<String>?
      smsGetVerifyCodeBtnBackgroundPaths; //设置获取验证码按钮图片 [激活状态的图片,失效状态的图片,高亮状态的图片] ios only
  String? smsGetVerifyCodeBtnText; //设置获取验证码按钮文字  ios only
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
      smsLogBtnBackgroundPaths; //设置授权登录按钮图片 @[激活状态的图片,失效状态的图片,高亮状态的图片] ios only
  int? smsFirstSeperLineOffsetX; //第一分割线相对于屏幕左边 x 轴偏移 android only
  int? smsFirstSeperLineOffsetY; //第一分割线相对于标题栏下边缘 y 偏移 android only
  int? smsFirstSeperLineOffsetR; //第一分割线相对于屏幕右边偏移 android only
  int? smsFirstSeperLineColor; //第一分割线颜色 android only
  int? smsSecondSeperLineOffsetX; //第二分割线相对于屏幕左边 x 轴偏移 android only
  int? smsSecondSeperLineOffsetY; //第二分割线相对于标题栏下边缘 y 偏移 android only
  int? smsSecondSeperLineOffsetR; //第二分割线相对于屏幕右边偏移 android only
  int? smsSecondSeperLineColor; //第二分割线颜色 android only
  bool? isSmsPrivacyTextGravityCenter; //设置隐私条款文字是否居中对齐（默认左对齐）
  List<int>? smsPrivacyColor; // 设置隐私条款名称颜色 [基础文字颜色，协议文字颜色] ios only
  int?
      smsPrivacyTextVerAlignment; // 设置隐私条款垂直对齐方式 0:top 1:middle 2:bottom ios only
  int? smsPrivacyOffsetX; //协议相对于屏幕左边 x 轴偏移
  int? smsPrivacyOffsetY; //协议相对于底部 y 偏移
  int? smsPrivacyTopOffsetY; //协议相对于标题栏下边缘 y 偏移
  int? smsPrivacyWidth; //协议宽度 ios only
  int? smsPrivacyHeight; //协议高度 ios only
  int? smsPrivacyMarginL; //设置协议相对于登录页左边的间距 android only
  int? smsPrivacyMarginR; //设置协议相对于登录页右边的间距 android only
  int? smsPrivacyMarginT; //设置协议相对于登录页顶部的间距 android only
  int? smsPrivacyMarginB; //设置协议相对于登录页底部的间距 android only

  int? smsPrivacyCheckboxSize; //设置隐私条款 checkbox 尺寸
  int? smsPrivacyCheckboxOffsetX; //设置隐私条款 checkbox 相对于屏幕左边 x 轴偏移
  int? smsPrivacyCheckboxOffsetY; //设置隐私条款 checkbox 相对于屏幕 y 轴偏移
  bool? isSmsPrivacyCheckboxInCenter; //设置隐私条款 checkbox 是否相对协议文字纵向居中
  bool? smsPrivacyCheckboxState; //设置隐私条款 checkbox 默认状态 : 是否选择 默认:NO
  List<int>? smsPrivacyCheckboxMargin; //设置协议相对于登录页的间距 android only
  String? smsPrivacyCheckboxUncheckedImgPath; // 设置隐私条款 checkbox 未选中时图片 ios only
  String? smsPrivacyCheckboxCheckedImgPath; // 设置隐私条款 checkbox 选中时图片 ios only
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
      "smsPrivacyCheckboxOffsetY": smsPrivacyCheckboxOffsetY ??= null,
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
    if (type == JVCustomWidgetType.button || type == JVCustomWidgetType.image) {
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
  int titleColor = 0xFF000000;
  int? backgroundColor;

  /// 按钮常态图片。HarmonyOS 将它作为 media 资源名使用；
  /// [harmonyImage] 已配置时以后者为准。
  String? btnNormalImageName;

  /// iOS/Android 按压态图片；HarmonyOS 受控 ArkUI 图片按钮暂不切换按压态资源。
  String? btnPressedImageName;
  JVTextAlignmentType? textAlignment;

  /// HarmonyOS 受控 ArkUI Builder 的圆角，单位 vp。
  double? harmonyBorderRadius;

  /// HarmonyOS 点击后的原生动作；默认仅回调 [widgetId]。
  JVHarmonyCustomWidgetAction? harmonyAction;

  /// HarmonyOS 点击后显示的原生 Toast；为空时只执行回调和 [harmonyAction]。
  String? harmonyToastText;

  /// HarmonyOS 自定义 Image 或图片 Button；也可用于隐私二次弹窗。
  JVHarmonyImageConfig? harmonyImage;

  int lines = 1;

  /// textView 行数，
  bool isSingleLine = true;

  /// textView 是否单行显示，默认：单行，iOS 端无效
  /* 若 isSingleLine = false 时，iOS 端 lines 设置失效，会自适应内容高度，最大高度为设置的 height */

  bool isShowUnderline = false;

  ///是否显示下划线，默认：不显示
  bool isClickEnable = false;

  //隐私协议二次弹窗专用  android only
  bool belowTheDialogContent = false;

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
      "harmonyBorderRadius": harmonyBorderRadius,
      "harmonyAction": harmonyAction?.name,
      "harmonyToastText": harmonyToastText,
      "harmonyImage": harmonyImage?.toJsonMap(),
      "lines": lines,
      "isSingleLine": isSingleLine,
      "belowTheDialogContent": belowTheDialogContent,
      "left": left,
      "top": top,
      "width": width,
      "height": height,
    }..removeWhere((key, value) => value == null);
  }
}

/// 添加自定义控件类型。HarmonyOS 支持受控 textView、button 和 image。
enum JVCustomWidgetType { textView, button, image }

/// Android 授权页背景视频缩放模式
enum JVAuthBGVideoScaleType {
  fitXY,
  fitCenter,
  centerCrop,
}

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

int? getValueFromAuthBGVideoScaleType(JVAuthBGVideoScaleType? type) {
  switch (type) {
    case JVAuthBGVideoScaleType.fitXY:
      return 0;
    case JVAuthBGVideoScaleType.fitCenter:
      return 1;
    case JVAuthBGVideoScaleType.centerCrop:
      return 2;
    case null:
      return null;
  }
}

class JVPrivacy {
  String? name;
  String? url;
  String? beforeName;
  String? afterName;
  String? separator; // iOS/HarmonyOS 自定义协议分隔符

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
