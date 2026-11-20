# Architecture — Le Coteau Fleuri (Flutter)

Architecture **hexagonale, layer-first**, identique à `songbook-app` / `kidflix` / `motorz`.

## Arborescence

```
lib/
├── main.dart                 # Point d'entrée : ProviderScope + MaterialApp.router (routeur : appRouter)
├── core/
│   ├── domain/               # Domain (Dart pur)
│   │   ├── model/            # PhoneNumber, OtpCode, User, Session, AccountDraft, Stay, StayDraft,
│   │   │                     # StayTeam (StaffRole, TeamMember, StayDetail, MyStay),
│   │   │                     # News (StayPhoto, PhotoSorting, NewsDay, DayStatus, PublishedDay, PickedPhoto)
│   │   ├── exceptions/       # AuthException, AccountException, StayException, NewsException (+ codes)
│   │   └── services/         # Ports : AuthRepository, SessionRepository, AccountRepository, StayRepository,
│   │                         # LastStayRepository, NewsRepository, PhotoPicker
│   └── application/          # Application (Dart pur)
│       ├── dtos/             # UserDto, SessionDto (sans le JWT), OtpRequestDto, StayDto, StayDetailDto,
│       │                     # MyStayDto, StaySpaceDto, StayPhotoDto, NewsDayDto, PublishedDayDto
│       ├── usecases/         # RequestOtp, VerifyOtp, RestoreSession, RefreshSession, Logout ;
│       │                     # accounts.usecases (ListAccounts, SaveAccount, DeleteAccount…) ;
│       │                     # stays.usecases (ListStays, CreateStay) ;
│       │                     # stay_team.usecases (GetStay, NameStaff, RemoveStaff, ListMyStays) ;
│       │                     # last_stay.usecases (PickDefaultStay, RememberStay) ;
│       │                     # news.usecases (photos, dépôt, tri, jours, publication, lecture)
│       ├── services/         # AuthApplicationService, AccountsApplicationService, StaysApplicationService,
│       │                     # NewsApplicationService
│       ├── session_state.dart  # Machine d'états de la session
│       └── stay_periods.dart   # Séjours en cours / à venir / passés, séjour où ouvrir l'app
├── infrastructure/
│   ├── auth/                 # dio.auth.repository, in_memory.auth.repository, user.codec
│   ├── accounts/             # dio.account.repository, in_memory.account.repository
│   ├── stays/                # dio.stay.repository, in_memory.stay.repository, stay.codec,
│   │                         # shared_preferences/in_memory.last_stay.repository
│   ├── news/                 # dio.news.repository, in_memory.news.repository, news.codec,
│   │                         # image_picker.photo_picker, demo_photos (PNG de démo dessinés à la volée)
│   ├── session/              # shared_preferences.session.repository, in_memory.…, codec JSON
│   ├── http/                 # AuthInterceptor (Bearer, 401, 403), chemins et codes d'erreur de l'API
│   └── providers/            # Providers Riverpod (@riverpod, *.g.dart) — assemblage DI,
│                             # dont SessionController, AccountsController, StaysController,
│                             # StayDetailController, myStays, staySpace, StayPhotosController,
│                             # NewsDaysController, stayNews et photoImage
└── ui/
    ├── pages/<feature>/      # *.page.dart (+ widgets/ propres à la page) : auth/, start/, admin/, stays/, news/
    ├── shell/                # AppShell : tiroir, rail ou barre latérale autour des pages
    ├── router/               # AppRoutes (adresses) et SpaceLocation (l'espace d'une adresse)
    ├── providers/            # appRouter (go_router, redirections d'après la session)
    ├── widgets/              # *.widget.dart partagés : SpaceCard ; phone_display, stay_display
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

Le routeur (`appRouter`) choisit l'écran d'après `SessionState` (`SessionRestoring`
→ `/chargement`, `Anonymous` → `/connexion`, `OtpRequested` → `/code`,
`Authenticated` → l'app). L'adresse demandée au lancement (un lien vers un séjour,
sur le web) est reprise une fois la session relue. Les écrans ne voient que des DTOs : le JWT ne quitte
jamais l'infrastructure.

## Droits et espaces

Qui voit quoi est décidé dans `ACCES.md` du dépôt `lecoteaufleuri/dev`
(`../ACCES.md` dans l'espace de travail). **L'app adapte ses écrans, l'API
décide** : rien de ce que l'app masque n'est protégé par ce seul masquage.

- **Les droits se relisent** (`RefreshSessionUseCase`, `GET /api/me`) au
  démarrage, à chaque retour au premier plan (`LeCoteauFleuriApp`) et après un
  `403 forbidden` (`AuthInterceptor` → `SessionController.refresh()`). Sans
  réseau, la session garde ce qu'elle savait.
- **On est toujours dans un espace** (`ui/shell/`, `ui/router/`) : un séjour
  du compte ou l'administration, pas un écran par rôle. L'app s'ouvre (`/`,
  `StartPage`) sur le dernier séjour ouvert sur l'appareil s'il n'est pas
  terminé, sinon celui en cours, le prochain, puis le dernier passé
  (`defaultStay`) ; un admin sans séjour arrive dans l'administration. « Mes
  séjours » (`GET /api/me/stays`) sont ceux où le compte a un rôle ; un admin
  ouvre les autres depuis l'administration. Les enfants viendront avec leurs
  liens.
- **Un séjour se compose de modules** (`StayModule` : Nouvelles, Équipe),
  chacun montré à qui y a droit, et ses pages sont des onglets du module.
  Adresses : `/sejours/:id` (vue d'ensemble, une tuile par module),
  `/sejours/:id/nouvelles`, `/sejours/:id/equipe`, `/admin`,
  `/admin/sejours`, `/admin/comptes`. Un nouvel écran de séjour devient un
  module ou un onglet, pas une carte de plus.
- **Le cadre suit la largeur** (`AppShell`) : sous 600 points, un tiroir ☰
  (les séjours par période, l'administration, la déconnexion) et les tuiles
  de la vue d'ensemble ; jusqu'à 1000, un rail d'icônes ; au-delà, la barre
  latérale dépliée, avec le sélecteur de séjour en tête. Le rail se déplie et
  la barre se replie. Les écrans ouverts depuis un module (éditeur d'un jour,
  visionneuse…) s'empilent dans la zone du contenu, le cadre restant en
  place ; chaque page a ses messages (`ScaffoldMessenger` du cadre).
- **Tirer la vue d'ensemble vers le bas** relit les droits du compte, ses
  séjours et le séjour ouvert.
- **Rien ne survit à une session fermée ou à des droits retirés** : la
  déconnexion renvoie à `/connexion`, hors du cadre, qui se ferme avec tout ce
  qu'il montrait ; perdre le statut d'admin ramène à `/`, quel que soit
  l'écran ouvert. Les données de ces écrans vivent dans des providers sans
  `keepAlive` (ex. `AccountsController`), libérés avec eux.
- **Administration des comptes** (`ui/pages/admin/`) : liste avec recherche,
  création, correction, statut d'admin, coupure des sessions, suppression
  (réversible côté serveur). Le dernier admin garde son statut ; on ne supprime
  pas son propre compte depuis l'app.
- **Administration des séjours** (`ui/pages/admin/`) : liste du dernier
  commencé (ou à venir) au plus ancien, et création (nom, ACM ou non, dates
  choisies au calendrier). Les jours voyagent en `AAAA-MM-JJ` et vivent dans
  l'app à minuit UTC (`calendarDay`) : seuls l'année, le mois et le jour
  comptent.
- **Équipe d'un séjour** (`ui/pages/stays/`, module Équipe) : elle montre
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
- **Nouvelles du séjour** (`ui/pages/news/`, module Nouvelles, `ACCES.md`
  « Nouvelles du séjour ») : la direction y a trois onglets, les **nouvelles
  publiées** (ce que voient les familles), les **journées** et les **photos**
  de toute l'équipe (la pioche : retenues, à trier, écartées). Un animateur y
  a les nouvelles publiées et **ses** photos, et pas le module Équipe. On dépose plusieurs photos à la fois
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
