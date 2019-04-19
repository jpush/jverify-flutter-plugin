import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:platform/platform.dart';

class Jverify {
  factory Jverify() => _instance;

  final Platform _platform;
  final MethodChannel _channel;
  @visibleForTesting
  Jverify.private(MethodChannel channel, Platform platform)
      : _channel = channel,
        _platform = platform;

  static final _instance = new Jverify.private(
      const MethodChannel("jverify"), const LocalPlatform());

//  static Future<String> get platformVersion async {
//    final String version = await _channel.invokeMethod('getPlatformVersion');
//    return version;
//  }

  void setup({String appKey, String channel,bool useIDFA}) {
    _channel.invokeMethod("setup", {"appKey": appKey, "channel": channel,"useIDFA":useIDFA});
  }

  void setDebugMode(bool debug) {
    _channel.invokeMethod("setDebugMode", {"debug": debug});
  }

  Future<Map<dynamic, dynamic>> checkVerifyEnable() async {
    return await _channel.invokeMethod("checkVerifyEnable");
  }

  Future<Map<dynamic, dynamic>> getToken() async {
    return await _channel.invokeMethod("getToken");
  }

  Future<Map<dynamic, dynamic>> verifyNumber(String phone,
      {String token}) async {
    return await _channel.invokeMethod(
        "verifyNumber",
        {"phone": phone, "token": token}
          ..removeWhere((key, value) => value == null));
  }

  Future<Map<dynamic, dynamic>> loginAuth() async {
    return await _channel.invokeMethod("loginAuth");
  }

  void setCustomUI(
      {int navColor,
      String navText,
      int navTextColor,
      String navReturnImgPath,
      String logoImgPath,
      int logoWidth,
      int logoHeight,
      int logoOffsetY,
      bool logoHidden,
      int numberColor,
      int numFieldOffsetY,
      String logBtnText,
      int logBtnOffsetY,
      int logBtnTextColor,
      String logBtnBackgroundPath,
        String loginBtnNormalImage,
        String loginBtnPressedImage,
        String loginBtnUnableImage,
      String uncheckedImgPath,
      String checkedImgPath,
      int privacyOffsetY,
      String clauseName,
      String clauseUrl,
      int clauseBaseColor,
      int clauseColor,
      String clauseNameTwo,
      String clauseUrlTwo,
      int sloganOffsetY,
      int sloganTextColor}) {
    _channel.invokeMethod(
        "setCustomUI",
        {
          "navColor": navColor,
          "navText": navText,
          "navTextColor": navTextColor,
          "navReturnImgPath": navReturnImgPath,
          "logoImgPath": logoImgPath,
          "logoWidth": logoWidth,
          "logoHeight": logoHeight,
          "logoOffsetY": logoOffsetY,
          "logoHidden": logoHidden,
          "numberColor": numberColor,
          "numFieldOffsetY": numFieldOffsetY,
          "logBtnText": logBtnText,
          "logBtnOffsetY": logBtnOffsetY,
          "logBtnTextColor": logBtnTextColor,
          "logBtnBackgroundPath": logBtnBackgroundPath,
          "loginBtnNormalImage" : loginBtnNormalImage,
          "loginBtnPressedImage": loginBtnPressedImage,
          "loginBtnUnableImage":loginBtnUnableImage,
          "uncheckedImgPath": uncheckedImgPath,
          "checkedImgPath": checkedImgPath,
          "privacyOffsetY": privacyOffsetY,
          "clauseName": clauseName,
          "clauseUrl": clauseUrl,
          "clauseBaseColor": clauseBaseColor,
          "clauseColor": clauseColor,
          "clauseNameTwo": clauseNameTwo,
          "clauseUrlTwo": clauseUrlTwo,
          "sloganOffsetY": sloganOffsetY,
          "sloganTextColor": sloganTextColor
        }..removeWhere((key, value) => value == null));
  }
}
