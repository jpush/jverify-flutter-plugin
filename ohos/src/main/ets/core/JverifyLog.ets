import { Log } from '@ohos/flutter_ohos';

const TAG: string = 'JverifyPlugin/OHOS';

export class JverifyLog {
  static info(message: string): void {
    Log.i(TAG, message);
  }

  static warn(message: string): void {
    Log.w(TAG, message);
  }

  static error(message: string): void {
    Log.e(TAG, message);
  }

  static unsupported(method: string): string {
    const message: string = method + ' is not supported on HarmonyOS';
    JverifyLog.warn(message);
    return message;
  }
}
