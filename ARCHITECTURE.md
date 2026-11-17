# Architecture — Le Coteau Fleuri (Flutter)

Architecture **hexagonale, layer-first**, identique à `songbook-app` / `kidflix` / `motorz`.

## Arborescence

```
lib/
├── main.dart                 # Point d'entrée : ProviderScope + MaterialApp (racine : AuthGate)
├── core/
│   ├── domain/               # Domain (Dart pur)
│   │   ├── model/            # PhoneNumber, OtpCode, User, Session
│   │   ├── exceptions/       # AuthException + AuthErrorCode
│   │   └── services/         # Ports : AuthRepository, SessionRepository
│   └── application/          # Application (Dart pur)
│       ├── dtos/             # UserDto, SessionDto (sans le JWT), OtpRequestDto
│       ├── usecases/         # RequestOtp, VerifyOtp, RestoreSession, Logout
│       ├── services/         # AuthApplicationService (regroupe les cas d'usage)
│       └── session_state.dart  # Machine d'états de la session
├── infrastructure/
│   ├── auth/                 # dio.auth.repository, in_memory.auth.repository
│   ├── session/              # shared_preferences.session.repository, in_memory.…, codec JSON
│   ├── http/                 # AuthInterceptor (Bearer + 401), chemins et codes d'erreur de l'API
│   └── providers/            # Providers Riverpod (@riverpod, *.g.dart) — assemblage DI,
│                             # dont SessionController
└── ui/
    ├── pages/<feature>/      # *.page.dart (+ widgets/ propres à la page) : auth/, home/
    ├── widgets/              # *.widget.dart partagés : AuthGate
    └── theme/                # AppThemeData : palette du logo (vert, bleu, jaune, anthracite)
test/
├── helpers/                  # Doublures et données partagées (FakeHttpAdapter, fixtures)
├── unit/                     # Tests unitaires (domain, application, infrastructure)
└── functional/               # Tests de widgets / parcours (pages)
```

Les dossiers vides sont tenus par un `.gitkeep` en attendant leur premier fichier.

## Connexion (téléphone + OTP)

Même parcours que songbook, motorz et kidflix, contre l'API (`API.md` du dépôt api) :

1. **Saisie du numéro** → `RequestOtpUseCase` normalise en E.164 (`06 12…` → `+33612…`)
   et l'API envoie un code par SMS. Pas d'inscription : un numéro inconnu est refusé.
2. **Saisie du code** (6 chiffres, renvoi possible après 60 s) → `VerifyOtpUseCase`
   obtient le JWT et persiste la session (`shared_preferences`).
3. **Session** : restaurée au démarrage tant qu'elle n'est pas expirée. `AuthInterceptor`
   pose le Bearer sur toute route hors `/api/auth/*` ; sur `401 invalid_token`,
   `SessionController.expire()` efface la session et renvoie un SMS au même numéro
   (un seul, même si plusieurs requêtes échouent ensemble).

`AuthGate` choisit l'écran d'après `SessionState` (`SessionRestoring`, `Anonymous`,
`OtpRequested`, `Authenticated`). Les écrans ne voient que des DTOs : le JWT ne quitte
jamais l'infrastructure.

## Dépendances

```
UI → Application → Domain ← Infrastructure
```

1. **Domain** (`lib/core/domain/`) ne dépend de personne — Dart pur.
   - ❌ Pas de Riverpod · ❌ pas de Flutter · ❌ pas d'HTTP. ✅ logique métier pure.
   - `model/` : entités (champs `final`, invariants par `assert`, `copyWith`/`==`/`hashCode`
     manuels), value objects, classes scellées + `switch` exhaustif.
   - `services/` : interfaces de ports (`*.repository.dart`, `*.service.dart`).
2. **Application** (`lib/core/application/`) ne dépend que de Domain — Dart pur.
   - `dtos/` : DTOs (`fromDomain`/`toDomain`/`fromJson`/`toJson`). **L'UI ne manipule que des DTOs.**
   - `usecases/` : un cas d'usage = une classe `NameUseCase` (ports en dépendances).
   - `services/` : orchestration applicative.
3. **Infrastructure** (`lib/infrastructure/`) ne dépend que de Domain. **Seul lieu de Riverpod**
   (avec `ui/providers/`).
   - Implémentations concrètes des ports (`dio.*`, `in_memory.*`, …).
   - `providers/` : providers Riverpod (`@riverpod`, `*.g.dart`) — assemblage des dépendances.
4. **UI** (`lib/ui/`) ne dépend que d'Application (et des interfaces Domain via providers).
   - `pages/<feature>/*.page.dart`, `widgets/*.widget.dart`, `providers/*.provider.dart`.
   - `theme/` : `AppThemeData`.

## Règles

- **Imports absolus** (`package:lecoteaufleuri/...`), jamais de `../`.
- **Modèles écrits à la main** — pas de freezed/json_serializable. `build_runner` seulement pour
  le codegen Riverpod (`dart run build_runner build`, fichiers `*.g.dart` versionnés).
- Lint : `flutter_lints` + `riverpod_lint` (plugin d'analyse, cf. `analysis_options.yaml`).
- Chaque interface a une impl réelle **et** une impl `InMemory*` (tests + dev).
- **Tests** : `InMemory*` comme doublures (pas de mockito).
