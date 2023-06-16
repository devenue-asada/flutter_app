# TODO

- 音声入力
- ローカル通知
- 通知数バッチ
- nfc
- state only

## Getting Started

```
flutter run
```

## deploy

- Step1.バージョン更新
  pubspec.yaml

```
version: x.x.x+n
```

- Step2.アプリビルド

```
$ flutter clean
$ flutter build ios
```

xxx -> version
n -> build no

- Step3.xcode で archive 作成
  Product > archive

- Step4.作成した archive をデプロイ
  Windows > Organizer > Distribute App > Upload

## note

### nfc

- ios
  xcode > runner > signin & capabilities > near field communication tag reading

### icon

- icon generate
  https://www.appicon.co/

- android 用の mipmap、ios 用の Assets.xcassets それぞれ既存のフォルダと入れ替える
- android は chat_app/android/app/src/main/res、ios は/chat_app/ios/Runner 配下
