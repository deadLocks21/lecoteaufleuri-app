# lecoteaufleuri-app

Application **Le Coteau Fleuri** — Flutter (Android · iOS · macOS · Windows · Linux · Web).

- Identifiant : `com.lecoteaufleuri.app` (Android, iOS, macOS, Linux) · package Dart `lecoteaufleuri`.
- Identité visuelle : `design/logo.jpg` du dépôt `lecoteaufleuri/dev`, décliné en icônes dans
  `assets/icon/` et en palette dans `lib/ui/theme/app_theme_data.dart` (vert `#8CD35F`, bleu
  `#29D3FF`, jaune `#FDD014`, anthracite `#515150`) : boutons dans le vert exact du logo, fonds
  colorés atténués à 18 %, contrastes WCAG AA vérifiés par `test/unit/ui/app_theme_data_test.dart`.
- Logo de l'écran de connexion : `assets/brand/logo.png` (fonds clairs) et `logo_dark.png` (texte
  éclairci pour les fonds sombres), à fond transparent, générés depuis le logo source :
  `python3 -I tool/logo_assets.py ../design/logo.jpg assets/brand` (macOS, conversion par `sips`).
- Conventions reprises de `songbook-app` / `kidflix` / `motorz` : archi **hexagonale layer-first**
  (`core/domain`, `core/application`, `infrastructure`, `ui`), Riverpod 3 + codegen, imports
  absolus. Détails : [ARCHITECTURE.md](ARCHITECTURE.md).

> Statut : connexion par téléphone + OTP, séjours (équipe, nouvelles) et administration en place.

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
  Il est admin, pour essayer l'administration des comptes et des séjours
  (comptes et séjours de démo en mémoire) : l'été 2027 est dirigé par
  Dominique Durand ; le compte de démo n'y a pas de rôle et s'ouvre donc sur
  l'administration (Séjours → l'été 2027). S'y nommer adjoint
  (06 12 34 56 78) le fait apparaître parmi ses séjours. Ses nouvelles (module
  Nouvelles) ont déjà quelques photos et journées : une publiée, une
  programmée, un brouillon ; son calendrier (module Calendrier) a une journée
  type, des arrivées et départs, des activités et deux suggestions en
  attente.
- **Contre l'API** (`lecoteaufleuri/api`) : passer son origine à la compilation.

  ```sh
  flutter run --dart-define=API_BASE_URL=http://localhost:7780   # simulateur iOS, macOS
  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:7780    # émulateur Android
  ```

  Le compte se crée côté API (`make console C="app:auth:create-user +33612345678 Prénom Nom"`)
  et, en dev, le code s'y lit dans `var/log/dev.log` (il part aussi par SMS si httpsms est
  configuré dans le `.env.local` de l'API).

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

Même architecture que `kidflix`, `songbook` et `motorz`. Commits **conventionnels** (`feat:`,
`fix:`, …) sur `main` → tout le reste est automatique :

1. **GitLab CI** (`.gitlab-ci.yml`) :
   - `semantic-release` calcule la version depuis les commits, bumpe `version:` dans
     `pubspec.yaml`, commite `chore(release): X.Y.Z` (changelog dans le corps) et pousse le tag
     `vX.Y.Z` ;
   - `mirror-to-github` (stage `.post`) repousse branches et tags vers le miroir
     [`deadLocks21/lecoteaufleuri-app`](https://github.com/deadLocks21/lecoteaufleuri-app).
2. **GitHub Actions** (`.github/workflows/release.yml`), sur le tag `v*` mirroré :
   - `prepare` : version lue dans le tag ; refus de continuer sans `API_BASE_URL` en HTTPS ;
   - builds signés iOS, Android, macOS, Windows et Linux ;
   - `build-gate` puis GitHub Release (changelog du commit `chore(release)` ; APK, .zip Windows,
     AppImage) → Play Store (piste internal) et TestFlight (iOS + macOS, testeurs internes).

Un build raté laisse le tag en place : on corrige, puis on relance (« Re-run failed jobs ») ou on
pousse un `fix:` qui produit la version suivante. `workflow_dispatch` relance le pipeline à la main
sur la version de `pubspec.yaml`, la release prenant alors un nom `dispatch-v…`.

Les textes « What's New » des stores sont dans `release_notes.json` (TestFlight) et
`release_notes_android.json` (Play Store).

### Configuration à faire une fois

**GitLab** — Settings → CI/CD → Variables :

| Variable | Contenu |
|---|---|
| `GITLAB_TOKEN` | Project Access Token (`lecoteaufleuri/app`, Settings → Access Tokens), scope `write_repository`, rôle Maintainer (masqué) — pousse le commit de release et le tag. Si `main` ou les tags `v*` sont protégés, autoriser ce rôle à y pousser. |
| `GITHUB_TOKEN` | PAT GitHub (masqué) avec écriture sur `deadLocks21/lecoteaufleuri-app` |

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
| `API_BASE_URL` | Origine HTTPS de l'API de prod, injectée dans tous les builds (`--dart-define`). Absente ou non HTTPS → le job `prepare` échoue plutôt que de publier l'app en mode démo. |

**Stores** : créer l'app `com.lecoteaufleuri.app` dans App Store Connect (plateformes iOS + macOS) ;
son Apple ID (`6838406742`) est écrit en dur dans le workflow (`APP_STORE_APPLE_ID`). La créer aussi
dans la Play Console (un premier AAB peut devoir être uploadé à la main).

En local, sans `android/key.properties`, le build release Android est signé avec la clé debug.
