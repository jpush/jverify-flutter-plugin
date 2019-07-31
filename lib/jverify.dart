import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:platform/platform.dart';



/// 监听添加的自定义控件的点击事件
typedef JVClickWidgetEventListener = void Function(String widgetId);

class JVEventHandlers {
  static final JVEventHandlers _instance = new JVEventHandlers._internal();
  JVEventHandlers._internal();
  factory JVEventHandlers() => _instance;


  Map<String, JVClickWidgetEventListener> clickEventsMap = Map();
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


  // Events
  addClikWidgetEventListener(String eventId, JVClickWidgetEventListener callback) {
    _eventHanders.clickEventsMap[eventId] = callback;
  }


  Future<void> _handlerMethod(MethodCall call) async {
    print("handleMethod method = ${call.method}");
    switch (call.method) {
      case 'onReceiveClickWidgetEvent':{
        String widgetId = call.arguments.cast<dynamic, dynamic>()['widgetId'];
        bool isContains = _eventHanders.clickEventsMap.containsKey(widgetId);
        if (isContains) {
          JVClickWidgetEventListener cb = _eventHanders.clickEventsMap[widgetId];
          cb(widgetId);
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

  /// SDK 发起号码认证
  Future<Map<dynamic, dynamic>> verifyNumber(String phone,
      {String token}) async {
    print("$flutter_log" + "verifyNumber");
    var para = {"phone": phone, "token": token};
    para.remove((key, value) => value == null);
    return await _channel.invokeMethod("verifyNumber", para);
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

  /// SDK 请求授权一键登录
  Future<Map<dynamic, dynamic>> loginAuth(bool autoDismiss) async {
    print("$flutter_log" + "loginAuth");
    return await _channel
        .invokeMethod("loginAuth", {"autoDismiss": autoDismiss});
  }

  /// (新接口) 自定义授权页面，界面原始控件、新增自定义控件
  void setCustomAuthViewAllWidgets(JVUIConfig uiConfig , {List<JVCustomWidget>widgets}) {

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


/// 自定义 UI 界面配置类
class JVUIConfig {
  int navColor;
  String navText;
  int navTextColor;
  String navReturnImgPath;
  String logoImgPath;
  int logoWidth;
  int logoHeight;
  int logoOffsetY;
  bool logoHidden;
  int numberColor;
  int numFieldOffsetY;
  String logBtnText;
  int logBtnOffsetY;
  int logBtnTextColor;
  String logBtnBackgroundPath;
  String loginBtnNormalImage;
  String loginBtnPressedImage;
  String loginBtnUnableImage;
  String uncheckedImgPath;
  String checkedImgPath;
  int privacyOffsetY;
  String clauseName;
  String clauseUrl;
  int clauseBaseColor;
  int clauseColor;
  String clauseNameTwo;
  String clauseUrlTwo;
  int sloganOffsetY;
  int sloganTextColor;
  ///设置隐私条款默认选中状态，默认不选中
  bool privacyState = false;


  Map toJsonMap() {
    return {
      "navColor": navColor ??= null,
      "navText": navText ??= null,
      "navTextColor": navTextColor ??= null,
      "navReturnImgPath": navReturnImgPath ??= null,
      "logoImgPath": logoImgPath ??= null,
      "logoWidth": logoWidth ??= null,
      "logoHeight": logoHeight ??= null,
      "logoOffsetY": logoOffsetY ??= null,
      "logoHidden": logoHidden ??= null,
      "numberColor": numberColor ??= null,
      "numFieldOffsetY": numFieldOffsetY ??= null,
      "logBtnText": logBtnText ??= null,
      "logBtnOffsetY": logBtnOffsetY ??= null,
      "logBtnTextColor": logBtnTextColor ??= null,
      "logBtnBackgroundPath": logBtnBackgroundPath ??= null,
      "loginBtnNormalImage": loginBtnNormalImage ??= null,
      "loginBtnPressedImage": loginBtnPressedImage ??= null,
      "loginBtnUnableImage": loginBtnUnableImage ??= null,
      "uncheckedImgPath": uncheckedImgPath ??= null,
      "checkedImgPath": checkedImgPath ??= null,
      "privacyOffsetY": privacyOffsetY ??= null,
      "clauseName": clauseName ??= null,
      "clauseUrl": clauseUrl ??= null,
      "clauseBaseColor": clauseBaseColor ??= null,
      "clauseColor": clauseColor ??= null,
      "clauseNameTwo": clauseNameTwo ??= null,
      "clauseUrlTwo": clauseUrlTwo ??= null,
      "sloganOffsetY": sloganOffsetY ??= null,
      "sloganTextColor": sloganTextColor ??= null,
      "privacyState": privacyState,
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

String getStringFromEnum<T>(T) {
  if (T == null) {
    return null;
  }

  return T.toString().split('.').last;
}