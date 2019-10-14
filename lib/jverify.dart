import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:platform/platform.dart';



/// 监听添加的自定义控件的点击事件
typedef JVClickWidgetEventListener = void Function(String widgetId);
/// 授权页事件回调 @since 2.4.0
typedef JVAuthPageEventListener = void Function(JVAuthPageEvent event);
/**
 * 一键登录接口的回调监听
 *
 * @param event
 *          code     ：返回码，6000代表loginToken获取成功，6001代表loginToken获取失败，其他返回码详见描述
 *          message  ：返回码的解释信息，若获取成功，内容信息代表loginToken。
 *          operator ：成功时为对应运营商，CM代表中国移动，CU代表中国联通，CT代表中国电信。失败时可能为 null
 *
 * @discussion 调用 loginAuth 接口后，可以通过添加此监听事件来监听接口的返回结果
 * */
typedef JVLoginAuthCallBackListener = void Function(JVListenerEvent event);



class JVEventHandlers {
  static final JVEventHandlers _instance = new JVEventHandlers._internal();
  JVEventHandlers._internal();
  factory JVEventHandlers() => _instance;


  Map<String, JVClickWidgetEventListener> clickEventsMap = Map();
  List<JVAuthPageEventListener> authPageEvents = [];
  List<JVLoginAuthCallBackListener> loginAuthCallBackEvents = [];
}



class Jverify {
  final String flutter_log = "| JVER | Flutter | ";

  factory Jverify() => _instance;
  final JVEventHandlers _eventHanders = new JVEventHandlers();

  final Platform _platform;
  final MethodChannel _channel;

  @visibleForTesting
  Jverify.private(MethodChannel channel, Platform platform)
      : _channel = channel,
        _platform = platform;

  static final _instance = new Jverify.private(
      const MethodChannel("jverify"),
      const LocalPlatform()
  );


  /// 自定义控件的点击事件
  addClikWidgetEventListener(String eventId, JVClickWidgetEventListener callback) {
    _eventHanders.clickEventsMap[eventId] = callback;
  }
  /// 授权页的点击事件， @since v2.4.0
  addAuthPageEventListener(JVAuthPageEventListener callback) {
    _eventHanders.authPageEvents.add(callback);
  }
  /// loginAuth 接口回调的监听
  addLoginAuthCallBackListener(JVLoginAuthCallBackListener callback) {
    _eventHanders.loginAuthCallBackEvents.add(callback);
  }

  Future<void> _handlerMethod(MethodCall call) async {
    print("handleMethod method = ${call.method}");
    switch (call.method) {
      case 'onReceiveClickWidgetEvent': {
        String widgetId = call.arguments.cast<dynamic, dynamic>()['widgetId'];
        bool isContains = _eventHanders.clickEventsMap.containsKey(widgetId);
        if (isContains) {
          JVClickWidgetEventListener cb = _eventHanders.clickEventsMap[widgetId];
          cb(widgetId);
        }
      }
        break;
      case 'onReceiveAuthPageEvent': {
        for (JVAuthPageEventListener cb in _eventHanders.authPageEvents) {
          Map json = call.arguments.cast<dynamic, dynamic>();
          JVAuthPageEvent ev = JVAuthPageEvent.fromJson(json);
          cb(ev);
        }
      }
        break;
      case 'onReceiveLoginAuthCallBackEvent': {
        for (JVLoginAuthCallBackListener cb in _eventHanders.loginAuthCallBackEvents) {
          Map json = call.arguments.cast<dynamic, dynamic>();
          JVListenerEvent event = JVListenerEvent.fromJson(json);
          cb(event);
          _eventHanders.loginAuthCallBackEvents.remove(cb);
        }
      }
      break;
      default:
        throw new UnsupportedError("Unrecognized Event");
    }
    return ;
  }

  /// 初始化
  void setup({String appKey, String channel, bool useIDFA}) {
    print("$flutter_log" + "setup");

    _channel.setMethodCallHandler(_handlerMethod);

    _channel.invokeMethod(
        "setup", {"appKey": appKey, "channel": channel, "useIDFA": useIDFA}
        );
  }

  /// 设置 debug 模式
  void setDebugMode(bool debug) {
    print("$flutter_log" + "setDebugMode");
    _channel.invokeMethod("setDebugMode", {"debug": debug});
  }

  /// 获取 SDK 初始化是否成功标识
  Future<Map<dynamic, dynamic>> isInitSuccess() async {
    print("$flutter_log" + "isInitSuccess");
    return await _channel.invokeMethod("isInitSuccess");
  }

  /// SDK判断网络环境是否支持
  Future<Map<dynamic, dynamic>> checkVerifyEnable() async {
    print("$flutter_log" + "checkVerifyEnable");
    return await _channel.invokeMethod("checkVerifyEnable");
  }

  /// SDK 获取号码认证token
  Future<Map<dynamic, dynamic>> getToken({String timeOut}) async {
    print("$flutter_log" + "getToken");
    var para = {"timeOut": timeOut};
    para.remove((key, value) => value == null);
    return await _channel.invokeMethod("getToken", para);
  }

  /*
  * SDK 发起号码认证
  *
  * 2.4.3 版本开始，此接口已移除
  * */
  Future<Map<dynamic, dynamic>> verifyNumber(String phone,
      {String token}) async {
    print("$flutter_log" + "verifyNumber");

    return {"error":"This interface is deprecated"};
  }


  /// SDK 一键登录预取号,timeOut 有效取值范围[3000,10000]
  Future<Map<dynamic, dynamic>> preLogin({int timeOut}) async {
    var para = new Map();
    if (timeOut != null) {
      if (timeOut >= 3000 && timeOut <= 10000) {
        para["timeOut"] = timeOut;
      }
    }

    print("$flutter_log" + "preLogin" + "$para");
    return await _channel.invokeMethod("preLogin", para);
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
  * @return 通过接口异步返回的 map 获得
  *
  * @discussion since SDK v2.4.0，授权页面点击事件监听：通过添加 JVAuthPageEventListener 监听，来监听授权页点击事件
  *
  * */
  Future<Map<dynamic, dynamic>> loginAuth(bool autoDismiss) async {
    print("$flutter_log" + "loginAuth");
    return await _channel.invokeMethod("loginAuth", {"autoDismiss": autoDismiss});
  }

  /*
  * SDK请求授权一键登录（同步接口）
  *
  * 通过添加 JVLoginAuthCallBackListener 监听，来监听接口的返回结果
  *
  * @discussion since SDK v2.4.0，授权页面点击事件监听：通过添加 JVAuthPageEventListener 监听，来监听授权页点击事件
  *
  * */
  void loginAuthSyncApi({@required bool autoDismiss}) {
    print("$flutter_log" + "loginAuthSyncApi");
    _channel.invokeMethod("loginAuthSyncApi", {"autoDismiss": autoDismiss});
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
  void setCustomAuthorizationView(bool isAutorotate, JVUIConfig portraitConfig, {JVUIConfig landscapeConfig, List<JVCustomWidget>widgets}) {

    if (isAutorotate == true) {
      if (portraitConfig == null || landscapeConfig == null) {
        print("missing Android landscape ui config");
        return ;
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
      var widgetList = List();
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
  void setCustomAuthViewAllWidgets(JVUIConfig uiConfig, {List<JVCustomWidget>widgets}) {

    var para = Map();

    var para1 = uiConfig.toJsonMap();
    para1.removeWhere((key, value) => value == null);
    para["uiconfig"] = para1;


    if (widgets != null) {
      var widgetList = List();
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
  String authBackgroundImage;

  /// 导航栏
  int navColor;
  String navText;
  int navTextColor;
  String navReturnImgPath;
  bool navHidden = false;
  bool navReturnBtnHidden = false;

  /// logo
  int logoWidth;
  int logoHeight;
  int logoOffsetX;
  int logoOffsetY;
  JVIOSLayoutItem logoVerticalLayoutItem;
  bool logoHidden;
  String logoImgPath;

  /// 号码
  int numberColor;
  int numberSize;
  int numFieldOffsetX;
  int numFieldOffsetY;
  int numberFieldWidth;
  int numberFieldHeight;
  JVIOSLayoutItem numberVerticalLayoutItem;

  /// slogan
  int sloganOffsetX;
  int sloganOffsetY;
  JVIOSLayoutItem sloganVerticalLayoutItem;
  int sloganTextColor;
  int sloganTextSize;
  bool sloganHidden = false;

  /// 登录按钮
  int logBtnOffsetX;
  int logBtnOffsetY;
  int logBtnWidth;
  int logBtnHeight;
  JVIOSLayoutItem logBtnVerticalLayoutItem;
  String logBtnText;
  int logBtnTextSize;
  int logBtnTextColor;
  String logBtnBackgroundPath;
  String loginBtnNormalImage;// only ios
  String loginBtnPressedImage;// only ios
  String loginBtnUnableImage;// only ios

  /// 隐私协议栏
  String uncheckedImgPath;
  String checkedImgPath;
  int privacyCheckboxSize;
  bool privacyState = false;//设置隐私条款默认选中状态，默认不选中
  bool privacyCheckboxHidden = false;//设置隐私条款checkbox是否隐藏
  bool privacyCheckboxInCenter = false;//设置隐私条款checkbox是否相对协议文字纵向居中

  int privacyOffsetY; // 隐私条款相对于授权页面底部下边缘 y 偏移
  int privacyOffsetX; // 隐私条款相对于屏幕左边 x 轴偏移
  JVIOSLayoutItem privacyVerticalLayoutItem = JVIOSLayoutItem.ItemSuper;
  String clauseName;
  String clauseUrl;
  int clauseBaseColor;
  int clauseColor;
  String clauseNameTwo;
  String clauseUrlTwo;
  List<String> privacyText;
  int privacyTextSize;
  bool privacyWithBookTitleMark = true;//设置隐私条款运营商协议名是否加书名号
  bool privacyTextCenterGravity = false;//隐私条款文字是否居中对齐（默认左对齐）

  /// 隐私协议页面
  int privacyNavColor;
  int privacyNavTitleTextColor;
  int privacyNavTitleTextSize;
  String privacyNavReturnBtnImage;

  Map toJsonMap() {
    return {
      "authBackgroundImage": authBackgroundImage ??=null,
      "navColor": navColor ??= null,
      "navText": navText ??= null,
      "navTextColor": navTextColor ??= null,
      "navReturnImgPath": navReturnImgPath ??= null,
      "navHidden": navHidden,
      "navReturnBtnHidden": navReturnBtnHidden,
      "logoImgPath": logoImgPath ??= null,
      "logoWidth": logoWidth ??= null,
      "logoHeight": logoHeight ??= null,
      "logoOffsetY": logoOffsetY ??= null,
      "logoOffsetX": logoOffsetX ??= null,
      "logoVerticalLayoutItem": getStringFromEnum(logoVerticalLayoutItem),
      "logoHidden": logoHidden ??= null,
      "numberColor": numberColor ??= null,
      "numberSize": numberSize ??= null,
      "numFieldOffsetY": numFieldOffsetY ??= null,
      "numFieldOffsetX": numFieldOffsetX ??= null,
      "numberFieldWidth": numberFieldWidth ??= null,
      "numberFieldHeight": numberFieldHeight ??= null,
      "numberVerticalLayoutItem": getStringFromEnum(numberVerticalLayoutItem),
      "logBtnText": logBtnText ??= null,
      "logBtnOffsetY": logBtnOffsetY ??= null,
      "logBtnOffsetX": logBtnOffsetX ??= null,
      "logBtnWidth": logBtnWidth ??= null,
      "logBtnHeight": logBtnHeight ??= null,
      "logBtnVerticalLayoutItem": getStringFromEnum(logBtnVerticalLayoutItem),
      "logBtnTextSize": logBtnTextSize ??= null,
      "logBtnTextColor": logBtnTextColor ??= null,
      "logBtnBackgroundPath": logBtnBackgroundPath ??= null,
      "loginBtnNormalImage": loginBtnNormalImage ??= null,
      "loginBtnPressedImage": loginBtnPressedImage ??= null,
      "loginBtnUnableImage": loginBtnUnableImage ??= null,
      "uncheckedImgPath": uncheckedImgPath ??= null,
      "checkedImgPath": checkedImgPath ??= null,
      "privacyCheckboxSize": privacyCheckboxSize ??= null,
      //"checkboxVerticalLayoutItem": getStringFromEnum(checkboxVerticalLayoutItem),
      "privacyOffsetY": privacyOffsetY ??= null,
      "privacyOffsetX": privacyOffsetX ??= null,
      "privacyVerticalLayoutItem": getStringFromEnum(privacyVerticalLayoutItem),
      "privacyText": privacyText ??= null,
      "privacyTextSize": privacyTextSize ??= null,
      "clauseName": clauseName ??= null,
      "clauseUrl": clauseUrl ??= null,
      "clauseBaseColor": clauseBaseColor ??= null,
      "clauseColor": clauseColor ??= null,
      "clauseNameTwo": clauseNameTwo ??= null,
      "clauseUrlTwo": clauseUrlTwo ??= null,
      "sloganOffsetY": sloganOffsetY ??= null,
      "sloganTextColor": sloganTextColor ??= null,
      "sloganOffsetX": sloganOffsetX ??= null,
      "sloganVerticalLayoutItem": getStringFromEnum(sloganVerticalLayoutItem),
      "sloganTextSize": sloganTextSize ??= null,
      "sloganHidden": sloganHidden,
      "privacyState": privacyState,
      "privacyCheckboxInCenter": privacyCheckboxInCenter,
      "privacyTextCenterGravity": privacyTextCenterGravity,
      "privacyCheckboxHidden": privacyCheckboxHidden,
      "privacyWithBookTitleMark": privacyWithBookTitleMark,
      "privacyNavColor": privacyNavColor ??= null,
      "privacyNavTitleTextColor": privacyNavTitleTextColor ??= null,
      "privacyNavTitleTextSize": privacyNavTitleTextSize ??= null,
      "privacyNavReturnBtnImage": privacyNavReturnBtnImage ??= null,
    }..removeWhere((key,value) => value == null);
  }
}


/// 自定义控件
class JVCustomWidget {
  String widgetId ;
  JVCustomWidgetType type ;

  JVCustomWidget(@required this.widgetId, @required this.type) {
    this.widgetId = widgetId;
    this.type = type;
    if (type == JVCustomWidgetType.button) {
      this.isClickEnable = true;
    }else{
      this.isClickEnable = false;
    }
  }

  int left = 0;// 屏幕左边缘开始计算
  int top = 0;// 导航栏底部开始计算
  int width = 0;
  int height = 0;

  String title = "";
  double titleFont = 13.0;
  int titleColor = Colors.black.value;
  int backgroundColor;
  String btnNormalImageName;
  String btnPressedImageName;
  JVTextAlignmentType textAlignment;


  int lines = 1;/// textView 行数，
  bool isSingleLine = true; /// textView 是否单行显示，默认：单行，iOS 端无效
  /* 若 isSingleLine = false 时，iOS 端 lines 设置失效，会自适应内容高度，最大高度为设置的 height */

  bool isShowUnderline = false;///是否显示下划线，默认：不显示
  bool isClickEnable ;///是否可点击，默认：不可点击

  Map toJsonMap() {
    return {
      "widgetId":widgetId,
      "type": getStringFromEnum(type),
      "title": title,
      "titleFont": titleFont ??= null,
      "textAlignment": getStringFromEnum(textAlignment),
      "titleColor": titleColor ??= null,
      "backgroundColor": backgroundColor ??= null,
      "isShowUnderline": isShowUnderline,
      "isClickEnable": isClickEnable,
      "btnNormalImageName": btnNormalImageName ??= null,
      "btnPressedImageName": btnPressedImageName ??= null,
      "lines": lines,
      "isSingleLine": isSingleLine,
      "isShowUnderline": isShowUnderline,
      "left":left,
      "top":top,
      "width":width,
      "height":height,
    }..removeWhere((key,value) => value == null);
  }
}

/// 添加自定义控件类型，目前只支持 textView
enum JVCustomWidgetType {
  textView,
  button
}
/// 文本对齐方式
enum JVTextAlignmentType {
  left,
  right,
  center
}

/// 监听返回类
class JVListenerEvent {
  int code;//返回码，具体事件返回码请查看（https://docs.jiguang.cn/jverification/client/android_api/）
  String message;//事件描述、事件返回值等
  String operator;//成功时为对应运营商，CM代表中国移动，CU代表中国联通，CT代表中国电信。失败时可能为null

  JVListenerEvent.fromJson(Map<dynamic, dynamic> json)
      : code = json['code'],
        message = json['message'],
        operator = json['operator'];

  Map toMap() {
    return {
      'code': code ??= null,
      'message': message ??= null,
      'operator': operator ??= null
    };
  }
}

/// 授权页事件
class JVAuthPageEvent extends JVListenerEvent {
  @override
  JVAuthPageEvent.fromJson(Map<dynamic, dynamic> json)
      : super.fromJson(json);

  @override
  Map toMap() {
    return {
      'code': code ??= null,
      'message': message ??= null,
    };
  }
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


String getStringFromEnum<T>(T) {
  if (T == null) {
    return null;
  }

  return T.toString().split('.').last;
}