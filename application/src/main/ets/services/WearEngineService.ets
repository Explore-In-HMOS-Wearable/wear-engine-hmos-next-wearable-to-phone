import { wearEngine } from '@kit.WearEngine';
import { fileUri, fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class WearEngineService {
  private bundleName: string = 'YOUR_MOBILE_PACKAGE_NAME'; // TODO: SET MOBILE PACKAGE NAME
  private fingerprint: string = 'YOUR_MOBILE_FINGERPRINT'; // TODO: SET MOBILE FINGERPRINT

  private deviceClient: wearEngine.DeviceClient;
  private p2pClient: wearEngine.P2pClient;
  private targetDevice: wearEngine.Device | undefined;
  private textEncoder = new util.TextEncoder();
  private textDecoder = new util.TextDecoder();

  constructor(context: Context) {
    this.deviceClient = wearEngine.getDeviceClient(context);
    this.p2pClient = wearEngine.getP2pClient(context);
  }

  async getConnectedDevice(): Promise<wearEngine.Device | undefined> {
    try {
      const devices = await this.deviceClient.getConnectedDevices();
      hilog.info(0x0000, 'WearEngineService', `Connected devices: ${devices.length}`);
      this.targetDevice = devices[0];
      return this.targetDevice;
    } catch (error) {
      hilog.error(0x0000, 'WearEngineService', `getConnectedDevices error: ${error.code}, ${error.message}`);
      return undefined;
    }
  }

  async isRemoteAppInstalled(): Promise<boolean> {
    if (!this.targetDevice) {
      return false;
    }
    try {
      return await this.p2pClient.isRemoteAppInstalled(this.targetDevice.randomId, this.bundleName);
    } catch (error) {
      hilog.error(0x0000, 'WearEngineService', `isRemoteAppInstalled error: ${error.code}, ${error.message}`);
      return false;
    }
  }

  async registerReceiver(
    messageCallback: Callback<wearEngine.P2pMessage>,
    fileCallback: Callback<wearEngine.P2pFile>
  ): Promise<void> {
    if (!this.targetDevice) {
      return;
    }

    const appInfo: wearEngine.AppInfo = {
      bundleName: this.bundleName,
      fingerprint: this.fingerprint
    };

    const appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };

    await this.p2pClient.registerMessageReceiver(this.targetDevice.randomId, appParam, messageCallback);
    await this.p2pClient.registerFileReceiver(this.targetDevice.randomId, appParam, fileCallback);
  }

  async sendMessage(messageText: string): Promise<wearEngine.P2pResult | undefined> {
    if (!this.targetDevice) {
      return;
    }

    const appInfo: wearEngine.AppInfo = {
      bundleName: this.bundleName,
      fingerprint: this.fingerprint
    };

    const appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };

    const message: wearEngine.P2pMessage = {
      content: this.textEncoder.encode(messageText)
    };

    try {
      await this.p2pClient.sendMessage(this.targetDevice.randomId, appParam, message);
    } catch (error) {
      hilog.error(0x0000, 'WearEngineService', `sendMessage error: ${error.code}, ${error.message}`);
    }
  }

  async sendFile(filePath: string): Promise<void> {
    if (!this.targetDevice) {
      return;
    }

    const appInfo: wearEngine.AppInfo = {
      bundleName: this.bundleName,
      fingerprint: this.fingerprint
    };

    const appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };

    const fileDescriptor = fs.openSync(filePath);
    const p2pFile: wearEngine.P2pFile = {
      file: fileDescriptor
    };

    try {
      this.p2pClient.transferFile(this.targetDevice.randomId, appParam, p2pFile, (error, result) => {
        if (error) {
          hilog.error(0x0000, 'WearEngineService', `sendFile error: ${error.code}, ${error.message}`);
          return;
        }
        hilog.info(0x0000, 'WearEngineService', `sendFile result: ${result.code}, progress: ${result.progress}`);
      });
    } catch (e) {
      hilog.error(0x0000, 'WearEngineService', `sendFile error: ${e}`);
    } finally {
      fs.closeSync(p2pFile.file);
    }
  }

  decodeMessage(content: Uint8Array): string {
    return this.textDecoder.decodeToString(content);
  }

  getFileUri(path: string): string {
    return fileUri.getUriFromPath(path);
  }
}
