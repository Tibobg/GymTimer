# GymTimer

Une app Flutter pour construire et suivre mes séances de musculation : plan d'exercices, chronomètre de repos qui reste actif même en changeant d'app, historique et suivi de progression.

## Fonctionnalités

- Création de séances : choix des exercices par jour, avec vidéo de démonstration (YouTube) pour chacun
- Chronomètre de repos en tâche de fond (notification + **bulle flottante par-dessus les autres apps**, comme un picture-in-picture) pour ne pas avoir à rouvrir l'app entre deux séries
- Historique des séances et graphiques de progression (`fl_chart`)
- Synchronisation de l'historique avec mon serveur personnel (TrueNAS), pour ne pas dépendre d'un compte cloud tiers

## Stack

Flutter, Provider, `flutter_foreground_task` + `flutter_overlay_window` (service en tâche de fond et bulle superposée), `flutter_local_notifications`, `youtube_player_flutter`, `fl_chart`

## Architecture

```
lib/
├─ models/          # Exercise, WorkoutPlan, WorkoutSession
├─ screens/          # constructeur de séance, choix du jour, séance en cours, historique, réglages
├─ services/
│  ├─ timer_service.dart      # logique du chronomètre
│  ├─ workout_service.dart    # séances / historique en local
│  ├─ truenas_service.dart    # sync de l'historique vers mon NAS
│  └─ catalog_service.dart    # catalogue d'exercices
├─ bg_service.dart   # service en tâche de fond (timer actif app fermée)
└─ overlay_bubble.dart  # bulle flottante système
```

## Lancer le projet

```bash
flutter pub get
flutter run
```

La synchronisation avec TrueNAS est optionnelle : sans serveur configuré, l'app fonctionne entièrement en local (historique stocké sur l'appareil).

## Ce que j'ai appris

- Faire tourner un chronomètre fiable en tâche de fond sur Android (foreground service) et l'afficher par-dessus les autres apps via une bulle superposée, plutôt que de forcer l'utilisateur à garder l'app au premier plan entre deux séries.
- Concevoir un plan de séance réutilisable (jour → liste d'exercices) plutôt que de saisir chaque séance depuis zéro.
