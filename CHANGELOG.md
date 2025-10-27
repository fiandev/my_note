# Changelog

## v2.2.5

- feat: implement secure note sharing via QR codes and local network
- feat: add multi-select, share, and QR scan for secret notes
- feat: style QR codes with primary theme color
- feat: refactor sharing functionality with cancel selection

## v1.2.2

- feat(lang): add support for multiple languages

## v1.2.1

- fix(pin): Fix data corruption after PIN reset by using correct plain PIN for decryption

## v1.2.0

- fix(note): support insert image
- fix(note): improve note edit feature with rich editor support
- fix(storage): change notes storage to SharedPreferences for better persistence
- fix(notes): prevent notes from disappearing when switching between public and secret
- feat(pin): add reset PIN feature in secret notes page
- fix(delete): improve delete functionality with long press and horizontal swipe
- feat(validation): add validation for note title and content to prevent empty saves
- fix(crud): ensure public and secret notes can be updated and deleted correctly

## v1.1.0

- feat(splash): implement native splash screen (4e53cf2)
- feat(settings): add settings page
- feat(note): add auto save feature

## v1.0.0

- initial project
