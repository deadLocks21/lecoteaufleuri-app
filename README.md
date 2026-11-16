# lecoteaufleuri-app

Application **Le Coteau Fleuri** — Flutter (Android · iOS · macOS · Windows · Linux · Web).

- Identifiant : `com.lecoteaufleuri.app` (Android, iOS, macOS, Linux) · package Dart `lecoteaufleuri`.
- Identité visuelle : `design/logo.jpg` du dépôt `lecoteaufleuri/dev`, décliné en icônes dans
  `assets/icon/`.
- Conventions reprises de `songbook-app` / `kidflix` / `motorz` : archi **hexagonale layer-first**
  (`core/domain`, `core/application`, `infrastructure`, `ui`), Riverpod 3 + codegen, imports
  absolus. Détails : [ARCHITECTURE.md](ARCHITECTURE.md).

> Statut : connexion par téléphone + OTP en place (accueil minimal une fois connecté).

## Développer

```sh
flutter pub get
flutter run                          # appareil / simulateur au choix
flutter analyze                      # flutter_lints + riverpod_lint
flutter test
dart run build_runner watch -d       # codegen Riverpod (*.g.dart), dès le premier @riverpod
```

### Connexion et API

L'app s'ouvre sur la connexion par numéro de mobile + code reçu par SMS.

- **Sans backend** (par défaut) : compte de démo `06 12 34 56 78`, code `000000`.
- **Contre l'API** (`lecoteaufleuri/api`) : passer son origine à la compilation.

  ```sh
  flutter run --dart-define=API_BASE_URL=http://localhost:7780   # simulateur iOS, macOS
  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:7780    # émulateur Android
  ```

  Le compte se crée côté API (`make console C="app:auth:create-user +33612345678 Prénom Nom"`)
  et, en dev, le code s'y lit dans `var/log/dev.log` au lieu de partir par SMS.

Avec Xcode 27, `flutter build ios --simulator` échoue sur `lipo -verify_arch` (build
universel) : lancer plutôt `flutter run -d <simulateur>`, qui ne compile qu'une architecture.

Flutter **3.41.7** (même version que la CI, cf. `FLUTTER_VERSION` dans `.github/workflows/release.yml`).

### Icônes

Sources dans `assets/icon/` (`app_icon.png` : icône pleine ; `app_icon_foreground.png` : premier plan
de l'icône adaptative Android, déjà réduit dans la zone sûre). Après modification :

```sh
dart run flutter_launcher_icons
```

## Release

Commits **conventionnels** (`feat:`, `fix:`, …) sur `main` → tout le reste est automatique :

1. **GitLab CI** (`.gitlab-ci.yml`) : `mirror-to-github` pousse branches et tags vers le miroir
   [`deadLocks21/lecoteaufleuri-app`](https://github.com/deadLocks21/lecoteaufleuri-app). C'est tout.
2. **GitHub Actions** (`.github/workflows/release.yml`), sur push de `main` :
   - `version` : `semantic-release --dry-run` calcule la prochaine version (rien à publier → stop) ;
     `check` : `flutter analyze` + `flutter test` ;
   - builds signés de toutes les plateformes, avec cette version (`--build-name`) ;
   - `tag` : **une fois tous les builds verts**, `semantic-release` pose `vX.Y.Z` sur le commit buildé
     et le pousse sur GitLab ;
   - GitHub Release (APK, .zip Windows, AppImage, changelog) → Play Store (piste internal) et
     TestFlight (iOS + macOS, testeurs internes).

Un build raté ne laisse donc ni tag ni commit à défaire : on corrige, on pousse, la même version est
retentée (ou « Re-run failed jobs » pour un échec passager). Le tag est la seule source de la version :
`pubspec.yaml` reste à `0.0.0+1` et n'est jamais bumpé. Si `main` avance pendant les builds, le run
ne tague pas et le suivant publie, commits récents compris.

Les textes « What's New » des stores sont dans `release_notes.json` (TestFlight) et
`release_notes_android.json` (Play Store).

### Configuration à faire une fois

**GitLab** — Settings → CI/CD → Variables :

| Variable | Contenu |
|---|---|
| `GITHUB_TOKEN` | PAT GitHub (masqué) avec écriture sur `deadLocks21/lecoteaufleuri-app` |

**GitHub** (`deadLocks21/lecoteaufleuri-app`) — Settings → Secrets and variables → Actions :

| Secret | Contenu |
|---|---|
| `GITLAB_TOKEN` | Project Access Token GitLab (`lecoteaufleuri/app`), scope `write_repository`, rôle Maintainer — sert à poser les tags. Si les tags `v*` sont protégés côté GitLab, autoriser ce rôle à les créer. |
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
