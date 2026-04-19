# Dicto – Projekt-Brief

## Problem

Diktat-Software für macOS ist entweder cloud-gebunden (Datenschutzrisiko), teuer oder zu komplex. Es gibt keine leichtgewichtige, vollständig lokale Lösung mit Push-to-Talk für Apple Silicon.

## Lösung

Dicto ist eine native macOS-Menübar-App ohne Dock-Icon. Per Fn-Taste (Push-to-Talk) wird Audio aufgenommen, lokal via WhisperKit transkribiert und der Text direkt an der Cursor-Position eingefügt.

## Zielgruppe

Einzelperson (Oliver Kern), MacBook Pro M4. Keine Mehrbenutzerfähigkeit, kein App Store, keine Cloud.

## Kernziele

1. **Lokal**: Kein Audio, kein Text verlässt das Gerät
2. **Schnell**: Transkription fühlt sich flüssig an (Ziel: <2 s für 10-s-Clip)
3. **Unsichtbar**: Nur im Menübar sichtbar, kein Dock-Icon
4. **Einfach**: Ein Hotkey, ein Modell, kein Onboarding

## Nicht-Ziele

- App-Store-Distribution
- Mehrsprachigkeit (nur Deutsch)
- Cloud-Fallback
- Mehrbenutzer / Sync
