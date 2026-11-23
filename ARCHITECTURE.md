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
│   │   │                     # News (StayPhoto, PhotoSorting, NewsDay, DayStatus, PublishedDay, PickedPhoto),
│   │   │                     # Calendar (CalendarEntry, EntrySchedule, ClockTime, OccurrenceChange,
│   │   │                     # EntryDraft/OccurrenceDraft, CalendarOccurrence, CalendarSuggestion, CalendarFeed)
│   │   ├── exceptions/       # AuthException, AccountException, StayException, NewsException,
│   │   │                     # CalendarException (+ codes)
│   │   └── services/         # Ports : AuthRepository, SessionRepository, AccountRepository, StayRepository,
│   │                         # LastStayRepository, NewsRepository, PhotoPicker, CalendarRepository
│   └── application/          # Application (Dart pur)
│       ├── dtos/             # UserDto, SessionDto (sans le JWT), OtpRequestDto, StayDto, StayDetailDto,
│       │                     # MyStayDto, StaySpaceDto, StayPhotoDto, NewsDayDto, PublishedDayDto,
│       │                     # StayCalendarDto, CalendarEntryDto, EntryDraftDto, OccurrenceDraftDto,
│       │                     # CalendarOccurrenceDto, CalendarSuggestionDto, CalendarFeedDto
│       ├── usecases/         # RequestOtp, VerifyOtp, RestoreSession, RefreshSession, Logout ;
│       │                     # accounts.usecases (ListAccounts, SaveAccount, DeleteAccount…) ;
│       │                     # stays.usecases (ListStays, CreateStay) ;
│       │                     # stay_team.usecases (GetStay, NameStaff, RemoveStaff, ListMyStays) ;
│       │                     # last_stay.usecases (PickDefaultStay, RememberStay) ;
│       │                     # news.usecases (photos, dépôt, tri, jours, publication, lecture) ;
│       │                     # calendar.usecases (calendrier, occurrences, suggestions, abonnement)
│       ├── services/         # AuthApplicationService, AccountsApplicationService, StaysApplicationService,
│       │                     # NewsApplicationService, CalendarApplicationService
│       ├── session_state.dart  # Machine d'états de la session
│       └── stay_periods.dart   # Séjours en cours / à venir / passés, séjour où ouvrir l'app
├── infrastructure/
│   ├── auth/                 # dio.auth.repository, in_memory.auth.repository, user.codec
│   ├── accounts/             # dio.account.repository, in_memory.account.repository
│   ├── stays/                # dio.stay.repository, in_memory.stay.repository, stay.codec,
│   │                         # shared_preferences/in_memory.last_stay.repository
│   ├── news/                 # dio.news.repository, in_memory.news.repository, news.codec,
│   │                         # image_picker.photo_picker, demo_photos (PNG de démo dessinés à la volée)
│   ├── calendar/             # dio.calendar.repository, in_memory.calendar.repository, calendar.codec
│   ├── session/              # shared_preferences.session.repository, in_memory.…, codec JSON
│   ├── http/                 # AuthInterceptor (Bearer, 401, 403), chemins et codes d'erreur de l'API
│   └── providers/            # Providers Riverpod (@riverpod, *.g.dart) — assemblage DI,
│                             # dont SessionController, AccountsController, StaysController,
│                             # StayDetailController, myStays, staySpace, StayPhotosController,
│                             # NewsDaysController, stayNews, photoImage, StayCalendarController,
│                             # CalendarSuggestionsController et CalendarFeedController
└── ui/
    ├── pages/<feature>/      # *.page.dart (+ widgets/ propres à la page) : auth/, start/, admin/, stays/, news/,
    │                         # calendar/
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
- **Un séjour se compose de modules** (`StayModule` : Nouvelles, Calendrier, Équipe),
  chacun montré à qui y a droit, et ses pages sont des onglets du module.
  Adresses : `/sejours/:id` (vue d'ensemble, une tuile par module),
  `/sejours/:id/nouvelles`, `/sejours/:id/calendrier`, `/sejours/:id/equipe`, `/admin`,
  `/admin/sejours`, `/admin/comptes`. Un nouvel écran de séjour devient un
  module ou un onglet, pas une carte de plus.
- **Le cadre suit la largeur** (`AppShell`) : sous 600 points, un tiroir ☰
  (les séjours par période, l'administration, la déconnexion) et les tuiles
  de la vue d'ensemble ; au-delà, une barre latérale, repliée en rail
  jusqu'à 1000 points et dépliée ensuite, qu'on replie ou déplie par le
  bouton de sa tête. Elle porte le sélecteur de séjour (rôle et dates, et
  les autres séjours du compte), les modules, puis l'administration et la
  déconnexion. Sur grand écran, elle tient lieu de vue d'ensemble : un
  séjour s'ouvre sur ses nouvelles, l'administration sur ses séjours. Les
  écrans ouverts depuis un module (éditeur d'un jour, visionneuse…)
  s'empilent dans la zone du contenu, le cadre restant en place ; chaque
  page a ses messages (`ScaffoldMessenger` du cadre).
- **Transitions** (`PageTransitions`) : sur téléphone, un écran glisse depuis
  la droite, sur toutes les plateformes ; sur grand écran, un fondu zoomé,
  sur toutes les plateformes aussi.
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
- **Calendrier du séjour** (`ui/pages/calendar/`, module Calendrier, `ACCES.md`
  « Calendrier du séjour ») : toute l'équipe le lit, jour par jour — une
  colonne par jour, autant que la largeur en permet (une sur téléphone, où
  l'on glisse d'un jour à l'autre), un bandeau des jours du séjour au-dessus.
  Par défaut en **grille des heures**, comme Google Agenda (`time_grid.dart`) :
  chaque occurrence est un bloc à son heure, aussi haut que sa durée (un
  quart d'heure sur une ligne sans heure de fin), celles qui se chevauchent
  côte à côte (`layoutDay`) ; la journée et les événements sur plusieurs
  jours dans l'en-tête du jour ; une ligne pour l'heure qu'il est ; toucher
  un créneau libre y ajoute (ou y propose) un événement. Un bouton passe à
  la **liste** de chaque jour.
  Chaque événement a sa catégorie (vie quotidienne, arrivée ou départ,
  imprévu, activité) et sa couleur ; une série se répète certains jours de
  la semaine, et un jour peut s'en écarter (modifié ou annulé). Les jours
  vivent à minuit UTC, les heures sont celles du séjour (`ClockTime`), sans
  fuseau ; l'app déplie elle-même les séries (`CalendarEntry.occurrences`).
  La **direction** ajoute, modifie (un jour seulement ou toute la série),
  annule, rétablit et supprime ; elle voit les jours annulés, barrés. Un
  **animateur** ne modifie rien : depuis le bouton « Proposer » ou un
  événement, il propose un ajout, un changement ou une annulation, avec un
  mot ; il suit ses propositions dans « Mes suggestions » et retire celles
  qui attendent. La direction voit toutes les suggestions (le nombre en
  attente sur l'onglet), les accepte — un ajout ou un changement s'ouvre
  dans l'éditeur, pour l'ajuster — ou les refuse en répondant. Le bouton
  d'agenda de la barre donne le **lien d'abonnement** personnel
  (`webcal://` pour iPhone et Mac, Google Agenda, ou copié), régénérable ;
  `url_launcher` ouvre les deux premiers. En mémoire,
  `InMemoryCalendarRepository` rejoue les règles de l'API, avec un été 2027
  rempli (journée type, arrivées et départs, activités, un imprévu) et deux
  suggestions de Sacha Bernard.
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
