# Klipp Screen Recorder 🎬

![Klipp](klipp-1.png)
> A professional, high-performance screen recording and video conversion tool built with **Flutter** and **FFmpeg**. 

Klipp is designed for power users who need a non-intrusive recording experience. It features a Bandicam-inspired "Ghost Frame" interaction model that lets you work while you record.

---

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![FFmpeg](https://img.shields.io/badge/FFmpeg-%235E97D1.svg?style=for-the-badge&logo=FFmpeg&logoColor=white)](https://ffmpeg.org)
[![Platform](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://microsoft.com/windows)

---

## 🌟 Key Features

### 👻 Ghost Frame Interaction
Klipp's signature feature. The recording frame is "hollow," allowing you to click through it to interact with background apps (like your IDE or browser) while recording. The toolbar and borders remain "solid" for instant control.

### 📐 DPI-Aware Capture
No more misaligned recordings on high-resolution displays. Klipp automatically detects your **Windows Display Scaling** (125%, 150%, etc.) and maps logical UI coordinates to physical screen pixels for a pixel-perfect capture.

### 🔄 Intelligent Converter
Drag and drop any video file to quickly switch formats or optimize for web.
- **Formats**: MKV (Crash-Safe), MP4, AVI, GIF.
- **Optimization**: Built-in H.264 compression for reducing file size without losing quality.

### 📁 Reactive Gallery
The built-in gallery tracks your `klippvideos` folder in real-time. If you rename or delete a file in Windows Explorer, Klipp updates instantly using asynchronous directory watching.

---

## 🚀 Getting Started

### Prerequisites
- **FFmpeg**: Must be installed and added to your **System PATH**. 
- **Flutter SDK**: Required if you intend to build from source.

### Installation
```bash
# Clone the repository
git clone https://github.com/xanderelsmith/klipp.git

# Navigate to project
cd klipp

# Get dependencies
flutter pub get

# Run the app
flutter run -d windows
```

---

## ⌨️ Shortcuts & Usage

| Action | Shortcut / Method |
| :--- | :--- |
| **Cancel Selection** | `ESC` |
| **Rename File** | `F2` (in Gallery) |
| **Hollow Mode** | Automatic during Recording |
| **Move Frame** | Drag the top Red Bar |
| **Resize** | Use the 8 circular corner handles |

---

## 🛠️ Technical Stack
- **Frontend**: Flutter Material 3 with Custom Window Management.
- **System Layer**: `window_manager` for native focus/transparency control.
- **Screen Logic**: `screen_retriever` for DPI and cursor tracking.
- **Media Engine**: FFmpeg (Custom pipeline for zero-latency start).

---

## 📄 License
Developed with ❤️ by **Xander**. 
*Klipp is open-source and intended for professional screen capture workflows.*