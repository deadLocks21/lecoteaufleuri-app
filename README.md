# lecoteaufleuri-app

Application **Le Coteau Fleuri** — Flutter (Android · iOS · macOS · Windows · Linux · Web).

- Identifiant : `com.lecoteaufleuri.app` (Android, iOS, macOS, Linux) · package Dart `lecoteaufleuri`.
- Identité visuelle : `design/logo.jpg` du dépôt `lecoteaufleuri/dev`, décliné en icônes dans
  `assets/icon/`.
- Conventions reprises de `songbook-app` / `kidflix` / `motorz` : archi **hexagonale layer-first**
  (`core/domain`, `core/application`, `infrastructure`, `ui`), Riverpod 3 + codegen, imports
  absolus. Détails : [ARCHITECTURE.md](ARCHITECTURE.md).

> Statut : Hello World — structure, dépendances et CI en place.

## Développer

```sh
flutter pub get
flutter run                          # appareil / simulateur au choix
flutter analyze                      # flutter_lints + riverpod_lint
flutter test
dart run build_runner watch -d       # codegen Riverpod (*.g.dart), dès le premier @riverpod
```

Flutter **3.41.7** (même version que la CI, cf. `FLUTTER_VERSION` dans `.github/workflows/release.yml`).

### Icônes

Sources dans `assets/icon/` (`app_icon.png` : icône pleine ; `app_icon_foreground.png` : premier plan
de l'icône adaptative Android, déjà réduit dans la zone sûre). Après modification :

```sh
dart run flutter_launcher_icons
```

## Release

Commits **conventionnels** (`feat:`, `fix:`, …) sur `main` → tout le reste est automatique :

1. **GitLab CI** (`.gitlab-ci.yml`) : `semantic-release` calcule la version, bumpe `pubspec.yaml`,
   commite `chore(release): X.Y.Z` et pose le tag `vX.Y.Z` ; `mirror-to-github` pousse branches et
   tags vers le miroir [`deadLocks21/lecoteaufleuri-app`](https://github.com/deadLocks21/lecoteaufleuri-app).
2. **GitHub Actions** (`.github/workflows/release.yml`), sur le tag : builds signés de toutes les
   plateformes → GitHub Release (APK, .zip Windows, AppImage) → Play Store (piste internal) et
   TestFlight (iOS + macOS, testeurs internes).

Les textes « What's New » des stores sont dans `release_notes.json` (TestFlight) et
`release_notes_android.json` (Play Store).

### Configuration à faire une fois

**GitLab** — Settings → CI/CD → Variables :

| Variable | Contenu |
|---|---|
| `GITLAB_TOKEN` | Project Access Token, scope `write_repository`, rôle Maintainer |
| `GITHUB_TOKEN` | PAT GitHub (masqué) avec écriture sur `deadLocks21/lecoteaufleuri-app` |

Si `main` est protégée : autoriser le token à pousser sur `main` et à créer les tags `v*`.

**GitHub** (`deadLocks21/lecoteaufleuri-app`) — Settings → Secrets and variables → Actions :

| Secret | Contenu |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | keystore upload (.jks) encodé base64 |
| `ANDROID_KEYSTORE_PASSWORD` · `ANDROID_KEY_ALIAS` · `ANDROID_KEY_PASSWORD` | accès à la clé upload |
| `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` | JSON du compte de service Google Play |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` · `APP_STORE_CONNECT_ISSUER_ID` · `APP_STORE_CONNECT_PRIVATE_KEY` | clé API App Store Connect |
| `CERTIFICATE_PRIVATE_KEY` | clé privée du certificat Apple Distribution |
| `MAC_INSTALLER_CERTIFICATE_P12_BASE64` · `MAC_INSTALLER_CERTIFICATE_PASSWORD` | certificat « 3rd Party Mac Developer Installer » |

| Variable | Contenu |
|---|---|
| `APP_STORE_APPLE_ID` | Apple ID numérique de l'app dans App Store Connect (fiche iOS + macOS) |

**Stores** : créer l'app `com.lecoteaufleuri.app` dans la Play Console (un premier AAB peut devoir
être uploadé à la main) et dans App Store Connect (plateformes iOS + macOS).

En local, sans `android/key.properties`, le build release Android est signé avec la clé debug.
