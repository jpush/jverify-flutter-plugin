package com.jiguang.jverify;

import android.content.Context;
import android.util.Log;

import java.util.HashMap;
import java.util.Map;

import cn.jiguang.api.JCoreInterface;
import cn.jiguang.verifysdk.api.JVerificationInterface;
import cn.jiguang.verifysdk.api.JVerifyUIConfig;
import cn.jiguang.verifysdk.api.VerifyListener;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** JverifyPlugin */
public class JverifyPlugin implements MethodCallHandler {

  private Context context;
  private MethodChannel channel;

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "jverify");
    channel.setMethodCallHandler(new JverifyPlugin(registrar,channel));
  }

  private JverifyPlugin(Registrar registrar,MethodChannel channel){
    this.context = registrar.context();
    this.channel = channel;
  }


  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("setup")) {
      setup(call,result);
    }else if(call.method.equals("setDebugMode")){
      setDebugMode(call,result);
    }else if(call.method.equals("checkVerifyEnable")){
      checkVerifyEnable(call,result);
    }else if(call.method.equals("getToken")){
      getToken(call,result);
    }else if(call.method.equals("verifyNumber")){
      verifyNumber(call,result);
    }else if(call.method.equals("loginAuth")){
      loginAuth(call,result);
    }else if(call.method.equals("setCustomUI")){
      setCustomUI(call,result);
    } else {
      result.notImplemented();
    }
  }

  private void setup(MethodCall call,Result result){
    JVerificationInterface.init(context);
  }

  private void setDebugMode(MethodCall call,Result result){
    Object enable =  getValueByKey(call,"debug");
    if (enable != null){
      JVerificationInterface.setDebugMode((Boolean) enable);
    }

  }

  private void checkVerifyEnable(MethodCall call,Result result){
    boolean verifyEnable = JVerificationInterface.checkVerifyEnable(context);
    Map<String,Object> map = new HashMap<>();
    map.put("result",verifyEnable);
    result.success(map);
  }

  private void getToken(MethodCall call, final Result result){
    JVerificationInterface.getToken(context, new VerifyListener() {
      @Override
      public void onResult(int code, String content, String operator) {
        Map<String,Object> map = new HashMap<>();
        map.put("code",code);
        map.put("content",content);
        map.put("operator",operator);
        result.success(map);
      }
    });
  }

  private void verifyNumber(MethodCall call, final Result result){
    String token = null;
    if (call.hasArgument("token")){
      token = call.argument("token");
    }
    String phone= null;
    if (call.hasArgument("phone")){
      phone = call.argument("phone");
    }
    JVerificationInterface.verifyNumber(context, token, phone, new VerifyListener() {
      @Override
      public void onResult(int code, String content, String operator) {
        Map<String,Object> map = new HashMap<>();
        map.put("code",code);
        map.put("content",content);
        map.put("operator",operator);
        result.success(map);
      }
    });
  }

  private void loginAuth(MethodCall call,final Result result){
    JVerificationInterface.loginAuth(context, new VerifyListener() {
      @Override
      public void onResult(int code, String content, String operator) {
        Map<String,Object> map = new HashMap<>();
        map.put("code",code);
        map.put("content",content);
        map.put("operator",operator);
        result.success(map);
      }
    });
  }

  /**
   * @param call
   * @param result
   */
  private void setCustomUI(MethodCall call,final Result result){
    Object navColor = getValueByKey(call,"navColor");
    Object navText = getValueByKey(call,"navText");
    Object navTextColor = getValueByKey(call,"navTextColor");
    Object navReturnImgPath = getValueByKey(call,"navReturnImgPath");
    Object logoImgPath = getValueByKey(call,"logoImgPath");
    Object logoWidth = getValueByKey(call,"logoWidth");
    Object logoHeight = getValueByKey(call,"logoHeight");
    Object logoOffsetY = getValueByKey(call,"logoOffsetY");
    Object logoHidden = getValueByKey(call,"logoHidden");
    Object numberColor = getValueByKey(call,"numberColor");
    Object numFieldOffsetY = getValueByKey(call,"numFieldOffsetY");
    Object logBtnText = getValueByKey(call,"logBtnText");
    Object logBtnOffsetY = getValueByKey(call,"logBtnOffsetY");
    Object logBtnTextColor = getValueByKey(call,"logBtnTextColor");
    Object logBtnBackgroundPath = getValueByKey(call,"logBtnBackgroundPath");
    Object uncheckedImgPath = getValueByKey(call,"uncheckedImgPath");
    Object checkedImgPath = getValueByKey(call,"checkedImgPath");
    Object privacyOffsetY = getValueByKey(call,"privacyOffsetY");
    Object CLAUSE_NAME = getValueByKey(call,"clauseName");
    Object CLAUSE_URL = getValueByKey(call,"clauseUrl");
    Object CLAUSE_BASE_COLOR = getValueByKey(call,"clauseBaseColor");
    Object CLAUSE_COLOR = getValueByKey(call,"clauseColor");
    Object CLAUSE_NAME_TWO = getValueByKey(call,"clauseNameTwo");
    Object CLAUSE_URL_TWO = getValueByKey(call,"clauseUrlTwo");
    Object sloganOffsetY = getValueByKey(call,"sloganOffsetY");
    Object sloganTextColor = getValueByKey(call,"sloganTextColor");

    JVerifyUIConfig.Builder builder =  new JVerifyUIConfig.Builder();
    if (navColor != null){
      if (navColor instanceof Long){
        builder.setNavColor(((Long) navColor).intValue());
      }else {
        builder.setNavColor((Integer) navColor);
      }

    }
    if (navText != null){
      builder.setNavText((String) navText);
    }
    if (navTextColor != null){
      if (navTextColor instanceof Long){
        builder.setNavTextColor(((Long) navTextColor).intValue());
      }else {
        builder.setNavTextColor((Integer) navTextColor);
      }
    }
    if (navReturnImgPath != null){
      builder.setNavReturnImgPath((String) navReturnImgPath);
    }
    if (logoImgPath != null ){
      builder.setLogoImgPath((String)logoImgPath);
    }
    if (logoWidth != null){
      if (logoWidth instanceof Long){
        builder.setLogoWidth(((Long) logoWidth).intValue());
      }else {
        builder.setLogoWidth((Integer) logoWidth);
      }
    }
    if (logoHeight != null){
      if (logoHeight instanceof Long){
        builder.setLogoHeight(((Long) logoHeight).intValue());
      }else {
        builder.setLogoHeight((Integer) logoHeight);
      }
    }
    if (logoOffsetY != null){
      if (logoOffsetY instanceof Long){
        builder.setLogoOffsetY(((Long) logoOffsetY).intValue());
      }else {
        builder.setLogoOffsetY((Integer) logoOffsetY);
      }
    }
    if (logoHidden != null){
      builder.setLogoHidden((Boolean)logoHidden);
    }
    if (numberColor != null){
      if (numberColor instanceof Long){
        builder.setNumberColor(((Long) numberColor).intValue());
      }else {
        builder.setNumberColor((Integer) numberColor);
      }
    }
    if (numFieldOffsetY != null){
      if (numFieldOffsetY instanceof Long){
        builder.setNumFieldOffsetY(((Long) numFieldOffsetY).intValue());
      }else {
        builder.setNumFieldOffsetY((Integer) numFieldOffsetY);
      }
    }
    if (logBtnText != null){
      builder.setLogBtnText((String) logBtnText);
    }
    if (logBtnOffsetY != null){
      if (logBtnOffsetY instanceof Long){
        builder.setLogBtnOffsetY(((Long) logBtnOffsetY).intValue());
      }else {
        builder.setLogBtnOffsetY((Integer) logBtnOffsetY);
      }
    }
    if (logBtnTextColor != null){
      if (logBtnTextColor instanceof Long){
        builder.setLogBtnTextColor(((Long) logBtnTextColor).intValue());
      }else {
        builder.setLogBtnTextColor((Integer) logBtnTextColor);
      }
    }
    if (logBtnBackgroundPath != null){
      builder.setLogBtnImgPath((String) logBtnBackgroundPath);
    }
    if (uncheckedImgPath != null){
      builder.setUncheckedImgPath((String) uncheckedImgPath);
    }
    if (checkedImgPath != null){
      builder.setCheckedImgPath((String) checkedImgPath);
    }
    if (privacyOffsetY != null){
      if (privacyOffsetY instanceof Long){
        builder.setPrivacyOffsetY(((Long) privacyOffsetY).intValue());
      }else {
        builder.setPrivacyOffsetY((Integer) privacyOffsetY);
      }
    }
    if (CLAUSE_NAME != null && CLAUSE_URL != null){
      builder.setAppPrivacyOne( (String) CLAUSE_NAME, (String) CLAUSE_URL);
    }
    int baseColor = -10066330;;
    int color = -16007674;
    if (CLAUSE_BASE_COLOR != null ){
      if (CLAUSE_BASE_COLOR instanceof Long){
        baseColor = ((Long) CLAUSE_BASE_COLOR).intValue();
      }else {
        baseColor = (Integer) CLAUSE_BASE_COLOR;
      }
    }
    if (CLAUSE_COLOR!= null){
      if (CLAUSE_COLOR instanceof Long){
        color = ((Long) CLAUSE_COLOR).intValue();
      }else {
        color = (Integer) CLAUSE_COLOR;
      }
    }
    builder.setAppPrivacyColor(baseColor,color);
    if (CLAUSE_NAME_TWO != null && CLAUSE_URL_TWO != null){
      builder.setAppPrivacyTwo( (String) CLAUSE_NAME_TWO, (String) CLAUSE_URL_TWO);
    }

    if (sloganOffsetY!= null){
      if (sloganOffsetY instanceof Long){
        builder.setSloganOffsetY(((Long) sloganOffsetY).intValue());
      }else {
        builder.setSloganOffsetY((Integer) sloganOffsetY);
      }
    }
    if (sloganTextColor != null){
      if (sloganTextColor instanceof Long){
        builder.setSloganTextColor(((Long) sloganTextColor).intValue());
      }else {
        builder.setSloganTextColor((Integer) sloganTextColor);
      }
    }

    JVerificationInterface.setCustomUIWithConfig(builder.build());

  }

  private Object getValueByKey(MethodCall call,String key){
    if (call != null && call.hasArgument(key)){
      return  call.argument(key);
    }else {
      return null;
    }
  }
}
