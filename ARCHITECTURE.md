# Architecture — Le Coteau Fleuri (Flutter)

Architecture **hexagonale, layer-first**, identique à `songbook-app` / `kidflix` / `motorz`.

## Arborescence

```
lib/
├── main.dart                 # Point d'entrée : ProviderScope + MaterialApp (racine : AuthGate)
├── core/
│   ├── domain/               # Domain (Dart pur)
│   │   ├── model/            # PhoneNumber, OtpCode, User, Session, AccountDraft, Stay, StayDraft,
│   │   │                     # StayTeam (StaffRole, TeamMember, StayDetail, MyStay),
│   │   │                     # News (StayPhoto, PhotoSorting, NewsDay, DayStatus, PublishedDay, PickedPhoto)
│   │   ├── exceptions/       # AuthException, AccountException, StayException, NewsException (+ codes)
│   │   └── services/         # Ports : AuthRepository, SessionRepository, AccountRepository, StayRepository,
│   │                         # NewsRepository, PhotoPicker
│   └── application/          # Application (Dart pur)
│       ├── dtos/             # UserDto, SessionDto (sans le JWT), OtpRequestDto, StayDto, StayDetailDto,
│       │                     # StayPhotoDto, NewsDayDto, PublishedDayDto
│       ├── usecases/         # RequestOtp, VerifyOtp, RestoreSession, RefreshSession, Logout ;
│       │                     # accounts.usecases (ListAccounts, SaveAccount, DeleteAccount…) ;
│       │                     # stays.usecases (ListStays, CreateStay) ;
│       │                     # stay_team.usecases (GetStay, NameStaff, RemoveStaff, ListMyStays) ;
│       │                     # news.usecases (photos, dépôt, tri, jours, publication, lecture)
│       ├── services/         # AuthApplicationService, AccountsApplicationService, StaysApplicationService,
│       │                     # NewsApplicationService
│       └── session_state.dart  # Machine d'états de la session
├── infrastructure/
│   ├── auth/                 # dio.auth.repository, in_memory.auth.repository, user.codec
│   ├── accounts/             # dio.account.repository, in_memory.account.repository
│   ├── stays/                # dio.stay.repository, in_memory.stay.repository, stay.codec
│   ├── news/                 # dio.news.repository, in_memory.news.repository, news.codec,
│   │                         # image_picker.photo_picker, demo_photos (PNG de démo dessinés à la volée)
│   ├── session/              # shared_preferences.session.repository, in_memory.…, codec JSON
│   ├── http/                 # AuthInterceptor (Bearer, 401, 403), chemins et codes d'erreur de l'API
│   └── providers/            # Providers Riverpod (@riverpod, *.g.dart) — assemblage DI,
│                             # dont SessionController, AccountsController, StaysController,
│                             # StayDetailController, myStays, StayPhotosController,
│                             # NewsDaysController, stayNews et photoImage
└── ui/
    ├── pages/<feature>/      # *.page.dart (+ widgets/ propres à la page) : auth/, home/, admin/, stays/, news/
    ├── widgets/              # *.widget.dart partagés : AuthGate, SpaceCard ; phone_display, stay_display
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

## Droits et espaces

Qui voit quoi est décidé dans `ACCES.md` du dépôt `lecoteaufleuri/dev`
(`../ACCES.md` dans l'espace de travail). **L'app adapte ses écrans, l'API
décide** : rien de ce que l'app masque n'est protégé par ce seul masquage.

- **Les droits se relisent** (`RefreshSessionUseCase`, `GET /api/me`) au
  démarrage, à chaque retour au premier plan (`AuthGate`) et après un
  `403 forbidden` (`AuthInterceptor` → `SessionController.refresh()`). Sans
  réseau, la session garde ce qu'elle savait.
- **L'accueil montre un espace par lien** du compte avec l'association, pas un
  écran par rôle : « Mes séjours » (ceux qu'il dirige ou seconde,
  `GET /api/me/stays`) et, pour les admins, « Administration » (séjours et
  comptes). Les enfants viendront avec leurs liens. Tirer l'accueil vers le
  bas relit les droits et les séjours.
- **Rien ne survit à une session fermée ou à des droits retirés** : `AuthGate`
  referme alors tout écran ouvert par-dessus l'accueil, et les données de ces
  écrans vivent dans des providers sans `keepAlive` (ex. `AccountsController`),
  libérés avec eux.
- **Administration des comptes** (`ui/pages/admin/`) : liste avec recherche,
  création, correction, statut d'admin, coupure des sessions, suppression
  (réversible côté serveur). Le dernier admin garde son statut ; on ne supprime
  pas son propre compte depuis l'app.
- **Administration des séjours** (`ui/pages/admin/`) : liste du dernier
  commencé (ou à venir) au plus ancien, et création (nom, ACM ou non, dates
  choisies au calendrier). Les jours voyagent en `AAAA-MM-JJ` et vivent dans
  l'app à minuit UTC (`calendarDay`) : seuls l'année, le mois et le jour
  comptent.
- **Équipe d'un séjour** (`ui/pages/stays/`) : la fiche d'un séjour montre
  ses directeurs (un ou plusieurs, égaux), ses adjoints et ses animateurs ; les
  boutons suivent `can_manage_directors`, `can_manage_deputies` et
  `can_manage_animators` rendus par l'API (admin : tout ; directeur : les
  adjoints et les animateurs ; adjoint : les animateurs). On désigne une
  personne par son numéro de mobile ; l'admin peut aussi la choisir dans la
  liste des comptes. Un numéro sans compte (`unknown_phone_number`) fait
  apparaître prénom et nom : la même requête, avec eux, crée le compte et nomme
  la personne, tout ou rien. De même, nommer animateur un membre de la
  direction (`already_director`, `already_deputy`) demande une confirmation,
  puis renvoie la requête avec `demote` — seulement si l'appelant peut le
  retirer de son rôle ; sinon l'erreur s'affiche sous le numéro. En mémoire,
  `InMemoryStayRepository` rejoue ces règles d'après le compte connecté.
- **Nouvelles du séjour** (`ui/pages/news/`, `ACCES.md` « Nouvelles du
  séjour ») : la fiche d'un séjour ouvre à la direction les **photos** de
  toute l'équipe (la pioche : retenues, à trier, écartées), les **journées**
  et les **nouvelles publiées** (ce que voient les familles). Un animateur
  retrouve son séjour dans « Mes séjours » et y ouvre **ses** photos et les
  nouvelles, pas la fiche. On dépose plusieurs photos à la fois
  (`PhotoPicker`, réduites à 2048 points par `image_picker`), envoyées une à
  une avec leur progression ; on les trie une à une ou en série (« Trier les
  n photos qui attendent »). Un jour se crée à une date libre du séjour, se
  rédige, s'illustre en piochant (les écartées sont repliées, en dernier
  recours ; une photo d'un autre jour est grisée), s'ordonne en faisant
  glisser ses photos, se publie tout de suite ou se programme (date puis
  heure, dans le fuseau de l'appareil), se dépublie. Les images passent par
  l'API (`photoImage`, en octets, avec le Bearer) : elles restent en mémoire
  cinq minutes après le dernier écran qui les montre et tombent avec la
  session. La visionneuse des nouvelles n'offre ni enregistrement ni partage.
  En mémoire, `InMemoryNewsRepository` rejoue les règles de l'API d'après le
  rôle du compte connecté dans les séjours de démo, avec quelques photos et
  jours sur l'été 2027.
- **L'app est en français**, widgets Material compris (`flutter_localizations`) :
  en test, `tester.pageBack()` ne trouve donc pas l'infobulle « Back », on
  touche le `BackButton`.

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
