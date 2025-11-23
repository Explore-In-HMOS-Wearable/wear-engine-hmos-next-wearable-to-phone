import { fileUri } from '@kit.CoreFileKit';
import promptAction from '@ohos.promptAction';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WearEngineService } from '../services/WearEngineService';

@Entry
@Component
struct Index {
  private context = this.getUIContext().getHostContext() as Context;
  private wearService = new WearEngineService(this.context);
  @State msgFromWatch: string = '';
  receivedLog: string = 'Hi Wear Engine';
  msgToWatch: string = 'Hi, Wear Engine!';
  filePath: string = this.context?.resourceDir + '/test.txt';

  private showToastMessage(message: string, duration: number = 1000): void {
    promptAction.openToast({ message, duration });
  }

  private logInfo(msg: string, toast: boolean = false): void {
    hilog.info(0x0000, 'Wear Engine Operation:', '%{public}s', msg);
    if (toast) {
      this.showToastMessage(msg);
    }
  }

  private logError(msg: string, toast: boolean = false): void {
    hilog.error(0x0000, 'Wear Engine Operation:', '%{public}s', msg);
    if (toast) {
      this.showToastMessage(msg);
    }
  }

  aboutToAppear(): void {
    this.initWearEngine();
  }

  private async initWearEngine(): Promise<void> {
    const device = await this.wearService.getConnectedDevice();
    if (!device) {
      this.logError('No connected device found.', true);
      return;
    }

    const isInstalled = await this.wearService.isRemoteAppInstalled();
    if (!isInstalled) {
      this.logError('Remote app not installed.', true);
      return;
    }

    await this.wearService.registerReceiver(
      (msg) => {
        this.msgFromWatch = this.wearService.decodeMessage(msg.content);
        this.receivedLog = 'Successfully received message: ' + this.msgFromWatch;
        this.logInfo(`Message received: ${this.msgFromWatch}`, true);
      },
      (file) => {
        this.receivedLog = `Received file: ${file.file.name}, path: ${file.file.path}`;
        this.logInfo(this.receivedLog, true);
        this.showToastMessage(file.file.name, 1000);

        if (file.file.name === 'test.txt') {
          AppStorage.setOrCreate('src', fileUri.getUriFromPath(file.file.path));
        }
      }
    );

    this.logInfo('Wear Engine initialized.', true);
  }

  async sendMessage(): Promise<void> {
    const result = await this.wearService.sendMessage(this.msgToWatch);
    if (!result) {
      this.logError('Failed to send message.', true);
      return;
    }

    const toastMsg = `Send result: ${result.code}${result.progress ? ' ' + result.progress : ''}`;
    this.logInfo(toastMsg, true);
  }

  async sendFile(): Promise<void> {
    await this.wearService.sendFile(this.filePath);
  }

  build() {
    Scroll() {
      Column({ space: 10 }) {
        Text($r('app.string.page_title'))
          .fontColor(Color.Gray)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 16, bottom: 6 })
          .fontSize(12)
          .textAlign(TextAlign.Center)

        Column() {
          Button($r('app.string.button_send_message'))
            .width('100%')
            .height(35)
            .margin({ bottom: 6 })
            .onClick(() => this.sendMessage())
            .fontWeight(FontWeight.Bold)

          Button($r('app.string.button_send_file'))
            .width('100%')
            .height(35)
            .onClick(() => this.sendFile())
            .fontWeight(FontWeight.Bold)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Text(`Received log:`)
          .fontColor(Color.Gray)
          .margin(4)
          .textAlign(TextAlign.End)

        Text(this.msgFromWatch)
          .fontColor(Color.Gray)
          .margin({ top: 4, bottom: 10 })
          .textAlign(TextAlign.End)

        Text(` `)
          .fontColor(Color.Black)
          .margin({ top: 5 })
          .lineHeight(1.5)
          .textAlign(TextAlign.End)
          .maxLines(5)
      }
      .padding({
        right: 30,
        left: 30,
        top: 20,
        bottom: 20
      })
      .backgroundColor(Color.White)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}
