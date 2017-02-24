# Cloud Speech Streaming gRPC Swift Sample

This app demonstrates how to make streaming gRPC connections to the [Cloud Speech API](https://cloud.google.com/speech/) to recognize speech in recorded audio.

It uses the new [grpc-swift](https://github.com/grpc/grpc-swift) Swift support for gRPC.

## Prerequisites
- An API key for the Cloud Speech API (See
  [the docs][getting-started] to learn more)
- An OSX machine or emulator
- [Xcode 8][xcode] or later

## Instructions
- Clone this repo and `cd` into this directory.
- Enter the `third_party` directory and run `RUNME.sh`
- Enter the `third_party/grpc-swift` directory and run `make` to generate the swift and swiftgrpc plugins for `protoc`.
- Copy the plugins somewhere in your path.
- Install `protoc`.
- Generate Protocol Buffer and gRPC support code by running the `RUNME` script in the main directory.
- Open the Speech.xcodeproj.
- Manually add libz.tbd to the libraries linked by the CgRPC target.
- Replace the header path in the CgRPC modulemap with the full absolute path to CgRPC.h.
- In `Speech/SpeechRecognitionService.swift`, replace `YOUR_API_KEY` with the API key obtained above.
- Build and run the app.


