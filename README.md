![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Version](https://img.shields.io/badge/version-1.2.0-green.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)


# MyNote 📝

<img width="1920" height="1080" alt="MyNote Preview" src="https://github.com/user-attachments/assets/e4e81767-ac07-4f31-bb52-2d6c6231fd46" />

####  A simple and secure note-taking app built with Flutter. Keep your thoughts organized, protected, and accessible across all your devices.

## ✨ Features

- 🔐 **Secure Notes**: Encrypt sensitive notes with AES encryption and PIN protection
- 📝 **Rich Text Editor**: Full-featured WYSIWYG editor with formatting options
- 📎 **Attachments**: Add images, documents, and files to your notes
- 📌 **Pinned Notes**: Keep important notes at the top
- 🏷️ **Groups & Categories**: Organize notes into custom groups
- 🎨 **Customizable Themes**: Light/dark mode with custom color schemes
- 🌐 **Localization**: Fully localized for Indonesian users
- 💾 **Offline Storage**: All data stored locally for privacy
- 🔄 **Auto-Save**: Never lose your work with automatic saving

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (2.19.0 or higher)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/my_note.git
   cd my_note
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building for Production

- **Android**: `flutter build apk` or `flutter build appbundle`
- **iOS**: `flutter build ios`
- **Web**: `flutter build web`
- **Desktop**: `flutter build linux`, `flutter build macos`, `flutter build windows`

## 🔧 Usage

1. **Creating a Note**: Tap the floating action button to create a new note
2. **Editing**: Use the rich text editor to format your content
3. **Securing Notes**: Mark notes as secret and set a PIN for encryption
4. **Organizing**: Add groups and pin important notes
5. **Customizing**: Go to Settings to change themes and colors

## 🏗️ Architecture

- **Models**: `lib/models/` - Data structures for notes and UI components
- **Pages**: `lib/pages/` - Main screens and navigation
- **Services**: `lib/services/` - Business logic for notes and PIN management
- **Utils**: `lib/utils/` - Helper functions like encryption
- **Widgets**: `lib/widgets/` - Reusable UI components

## 🔒 Security

- AES-256 encryption for secret notes
- PIN-based authentication
- Local storage only (no cloud sync)
- Deterministic IV generation for consistent encryption

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Rich text editing powered by [flutter_quill](https://pub.dev/packages/flutter_quill)
- Icons from [Cupertino Icons](https://pub.dev/packages/cupertino_icons)

---

Made with ❤️ by fiandev
