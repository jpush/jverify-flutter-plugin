package com.jiguang.jverify;

import android.content.Context;
import android.util.Log;

import java.util.HashMap;
import java.util.Map;

import cn.jiguang.api.JCoreInterface;
import cn.jiguang.verifysdk.api.JVerificationInterface;
import cn.jiguang.verifysdk.api.JVerifyUIConfig;
import cn.jiguang.verifysdk.api.PreLoginListener;
import cn.jiguang.verifysdk.api.VerifyListener;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** JverifyPlugin */
public class JverifyPlugin implements MethodCallHandler {

  // 定义日志 TAG
  private  static  final String TAG = "| JVER | Android | -";


  /// 统一 key
  private static  String j_result_key = "result";
  /// 错误码
  private static  String  j_code_key = "code";
  /// 回调的提示信息，统一返回 flutter 为 message
  private static  String  j_msg_key  = "message";
  /// 运营商信息
  private static  String  j_opr_key  = "operator";
  // 默认超时时间
  private  static  int j_default_timeout = 5000;


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
    Log.d(TAG,"onMethodCall:" + call.method);

    if (call.method.equals("setup")) {
      setup(call,result);
    }else if (call.method.equals("setDebugMode")) {
      setDebugMode(call, result);
    }else if (call.method.equals("isInitSuccess")) {
      isInitSuccess(call, result);
    }else if (call.method.equals("checkVerifyEnable")) {
      checkVerifyEnable(call,result);
    }else if (call.method.equals("getToken")) {
      getToken(call,result);
    }else if (call.method.equals("verifyNumber")) {
      verifyNumber(call,result);
    }else if (call.method.equals("loginAuth")) {
      loginAuth(call, result);
    }else  if (call.method.equals("preLogin")) {
      preLogin(call, result);
    }else if (call.method.equals("dismissLoginAuthView")) {
      dismissLoginAuthView(call, result);
    }else if (call.method.equals("setCustomUI")) {
      setCustomUI(call,result);
    } else {
      result.notImplemented();
    }
  }

  /** SDK 初始换  */
  private void setup(MethodCall call,Result result){
    Log.d(TAG,"Action - setup:");
    JVerificationInterface.init(context);
  }

  /** SDK设置debug模式 */
  private void setDebugMode(MethodCall call,Result result){
    Log.d(TAG,"Action - setDebugMode:");
    Object enable =  getValueByKey(call,"debug");
    if (enable != null){
      JVerificationInterface.setDebugMode((Boolean) enable);
    }

    Map<String,Object> map = new HashMap<>();
    map.put(j_result_key,enable);
    result.success(map);
  }

  /** 获取 SDK 初始化是否成功标识 */
  private  boolean isInitSuccess(MethodCall call, Result result) {
    Log.d(TAG,"Action - isInitSuccess:");
    boolean isSuccess = JVerificationInterface.isInitSuccess();
    if (!isSuccess) {
      Log.d( TAG, "SDK 初始化失败: ");
    }

    Map<String,Object> map = new HashMap<>();
    map.put(j_result_key, isSuccess);
    result.success(map);

    return isSuccess;
  }


  /** SDK 判断网络环境是否支持 */
  private boolean checkVerifyEnable(MethodCall call,Result result){
    Log.d(TAG,"Action - checkVerifyEnable:");
    boolean verifyEnable = JVerificationInterface.checkVerifyEnable(context);
    if (!verifyEnable) {
      Log.d( TAG, "当前网络环境不支持");
    }

    Map<String,Object> map = new HashMap<>();
    map.put(j_result_key, verifyEnable);
    result.success(map);

    return verifyEnable;
  }

  /** SDK获取号码认证token*/
  private void getToken(MethodCall call, final Result result) {
    Log.d(TAG,"Action - getToken:");

    int timeOut = j_default_timeout;
    if (call.hasArgument("timeOut")) {
      String timeOutString = call.argument("timeOut");

      try {
        timeOut = Integer.valueOf(timeOutString);
      } catch (Exception e) {
        Log.e(TAG,"timeOut type error.");
      }
    }


    JVerificationInterface.getToken(context, timeOut, new VerifyListener() {
      @Override
      public void onResult(int code, String content, String operator) {

        if (code == 2000){//code: 返回码，2000代表获取成功，其他为失败
          Log.d(TAG, "token=" + content + ", operator=" + operator);
        } else {
          Log.e(TAG, "code=" + code + ", message=" + content);
        }

        Map<String,Object> map = new HashMap<>();
        map.put(j_code_key,code);
        map.put(j_msg_key,content);
        map.put(j_opr_key,operator);
        result.success(map);
      }
    });
  }

  /** SDK 发起号码认证 */
  private void verifyNumber(MethodCall call, final Result result) {
    Log.d(TAG,"Action - verifyNumber:");

    String token = null;
    if (call.hasArgument("token")){
      token = call.argument("token");
    }
    String phone = null;
    if (call.hasArgument("phone")){
      phone = call.argument("phone");
    }
    if (phone == null || phone.isEmpty() || phone.length() == 0) {
      Log.e(TAG,"phone can not be nil.");
      return;
    }
    JVerificationInterface.verifyNumber(context, token, phone, new VerifyListener() {
      @Override
      public void onResult(int code, String content, String operator) {

        if (code == 1000){//code: 返回码，1000代表验证一致，1001代表验证不一致，其他为失败，详见错误码描述
          Log.d(TAG, "verify consistent, operator=" + operator);
        } else if (code == 1001) {
          Log.d(TAG, "verify not consistent");
        } else {
          Log.e(TAG, "code=" + code + ", message=" + content);
        }

        Map<String,Object> map = new HashMap<>();
        map.put(j_code_key,code);
        map.put(j_msg_key,content);
        map.put(j_opr_key,operator);
        result.success(map);
      }
    });
  }

  /** SDK 一键登录预取号 */
  private  void  preLogin(MethodCall call,final Result result) {
    Log.d(TAG,"Action - preLogin:" + call.arguments);

    int timeOut = j_default_timeout;
    if (call.hasArgument("timeOut")) {
      Integer value = call.argument("timeOut");
      timeOut = value;
    }

    JVerificationInterface.preLogin(context, timeOut, new PreLoginListener() {
      @Override
      public void onResult(int code, String message) {

        if (code == 7000){//code: 返回码，7000代表获取成功，其他为失败，详见错误码描述
          Log.d(TAG, "verify consistent, message =" + message);
        }else {
          Log.e(TAG, "code=" + code + ", message =" + message);
        }

        Map<String,Object> map = new HashMap<>();
        map.put(j_code_key,code);
        map.put(j_msg_key,message);
        result.success(map);
      }
    });
  }


  /** SDK请求授权一键登录 */
  private void loginAuth(MethodCall call,final Result result){
    Log.d(TAG,"Action - loginAuth:");

    Object autoFinish =  getValueByKey(call,"autoDismiss");

    JVerificationInterface.loginAuth(context, (Boolean)autoFinish, new VerifyListener() {
      @Override
      public void onResult(int code, String content, String operator) {

        //code: 返回码，6000代表loginToken获取成功，6001代表loginToken获取失败
        if (code == 6000){
          Log.d(TAG, "code = " + code + ", token = " + content +" ,operator = " + operator);
        }else{
          Log.e(TAG, "code = " + code + ", message = " + content);
        }

        Map<String,Object> map = new HashMap<>();
        map.put(j_code_key,code);
        map.put(j_msg_key,content);
        map.put(j_opr_key,operator);
        result.success(map);

      }
    });
  }
  /** SDK关闭授权页面 */
  private  void dismissLoginAuthView(MethodCall call, Result result) {
    Log.d(TAG,"Action - dismissLoginAuthView:");

    JVerificationInterface.dismissLoginAuthActivity();
  }

  /** SDK自定义授权页面UI样式 */
  private void setCustomUI(MethodCall call,final Result result){
    Log.d(TAG,"setCustomUI:");

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

  /** SDK授权页面添加自定义控件 */
  private  void addCustomView(MethodCall call, Result result) {

  }

  private Object getValueByKey(MethodCall call,String key){
    if (call != null && call.hasArgument(key)){
      return  call.argument(key);
    }else {
      return null;
    }
  }
}
