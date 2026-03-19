# 📱 Hushh Agents — iOS App

> Browse-first SwiftUI iOS app where guest users can discover and swipe through a deck of Registered Investment Advisors. Login unlocks onboarding, persistence, claims, and settings.

---

## 🎯 Goal

Ship a **browse-first** SwiftUI iOS app where:
- **Guest users** can see the agent deck, swipe, and view details — no auth required
- **Login** unlocks onboarding, persistence (swipe sync), claims, and settings
- **Delivery** in vertical slices: App Shell → Deck UX → Auth/Onboarding → Sync/Settings → Claims + Polish
- **Existing Supabase schema** is used as-is — **no migrations, no new tables**

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Hushh Agents iOS                       │
│                   SwiftUI · MVVM · iOS 17+                │
├──────────────────────────────────────────────────────────┤
│                                                           │
│   ┌───────────┐    ┌─────────────┐    ┌───────────────┐  │
│   │   Views    │ ←→ │ ViewModels  │ ←→ │   Services    │  │
│   │ (SwiftUI)  │    │   (MVVM)    │    │  (Supabase)   │  │
│   └───────────┘    └─────────────┘    └───────┬───────┘  │
│                                                │          │
│                                    ┌───────────▼────────┐│
│                                    │   Supabase Cloud    ││
│                                    │  hussh-ai project   ││
│                                    │  Auth + PostgreSQL   ││
│                                    └────────────────────┘│
│                                                           │
│   ┌──────────────────────────────────────────────────┐   │
│   │  Bundled: kirkland_agents (21 pre-populated)      │   │
│   │  Fallback JSON if network unavailable              │   │
│   └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

---

## 🔧 Tech Stack

| Component | Technology |
|-----------|-----------|
| **UI Framework** | SwiftUI (iOS 17+) |
| **Architecture** | MVVM |
| **Backend** | Supabase (PostgreSQL + Auth + Realtime) |
| **Auth Providers** | Apple Sign In (native) + Google Sign In |
| **Package Manager** | Swift Package Manager (SPM) |
| **Min iOS Version** | iOS 17.0 |
| **Language** | Swift 5.9+ |

---

## 📦 Dependencies (SPM)

| Package | Version | Purpose | URL |
|---------|---------|---------|-----|
| **Supabase Swift** | Latest | Auth, Database, Realtime | `https://github.com/supabase/supabase-swift` |
| **GoogleSignIn-iOS** | Latest | Google Sign In | `https://github.com/google/GoogleSignIn-iOS` |
| **AuthenticationServices** | Built-in | Apple Sign In | Native framework |

---

## 🔑 Supabase Configuration

| Property | Value |
|----------|-------|
| **Project** | hussh-ai (Production) |
| **URL** | `https://ibsisfnjxeowvdtvgzff.supabase.co` |
| **Anon Key** | (stored in Config.plist, not hardcoded) |
| **Auth Providers** | Apple ✅, Google ✅ |

---

## 📂 Project Structure

```
hushh-agents-ios/
├── HushhAgents/
│   │
│   ├── App/
│   │   ├── HushhAgentsApp.swift              # @main entry, Supabase init
│   │   ├── AppState.swift                     # Root source of truth: session, onboarding,
│   │   │                                      # pending gated action, current user snapshot
│   │   └── ContentView.swift                  # Root view: navigation router
│   │
│   ├── Config/
│   │   └── Supabase.plist                     # URL + anon key (gitignored)
│   │
│   ├── Models/
│   │   ├── KirklandAgent.swift                # Maps to kirkland_agents table
│   │   ├── AppUser.swift                      # Maps to users table
│   │   ├── ConsumerProfile.swift              # Maps to consumer_profiles table
│   │   ├── UserAgentSelection.swift           # Maps to user_agent_selections table
│   │   ├── LeadRequest.swift                  # Maps to lead_requests table
│   │   ├── SwipeDirection.swift               # Enum: .pass, .interested
│   │   ├── ClaimAvailability.swift            # Enum: .claimable(agentProfileId), .unavailable
│   │   └── GatedAction.swift                  # Enum: pending protected actions for resumption
│   │
│   ├── Services/
│   │   ├── SupabaseService.swift              # Supabase client singleton
│   │   ├── AuthService.swift                  # Apple + Google Sign In, session restore,
│   │   │                                      # sign out, auth callback handling
│   │   ├── AgentService.swift                 # Fetch kirkland_agents → fallback bundled JSON
│   │   ├── SwipeService.swift                 # Queue guest swipe, load pending, sync pending,
│   │   │                                      # fetch remote selections, dedupe
│   │   ├── LeadService.swift                  # Resolve claim target, create lead_request,
│   │   │                                      # fetch my claims (mapped agents only)
│   │   └── UserService.swift                  # Upsert users, read/write consumer_profiles,
│   │                                          # fetch profile/settings data
│   │
│   ├── ViewModels/
│   │   ├── DeckViewModel.swift                # Cards, swipe handlers, deck filtering,
│   │   │                                      # detail selection, claim availability
│   │   ├── AuthViewModel.swift                # Auth state, sign in/out, session check
│   │   ├── OnboardingViewModel.swift          # Onboarding flow, save consumer_profile
│   │   ├── AgentDetailViewModel.swift         # Agent detail data
│   │   ├── ProfileViewModel.swift             # User profile + settings data
│   │   └── ClaimViewModel.swift               # Claim/lead request flow
│   │
│   ├── Views/
│   │   │
│   │   ├── Deck/
│   │   │   ├── DeckView.swift                 # Main screen — card stack + action buttons
│   │   │   ├── AgentCardView.swift            # Individual swipeable card
│   │   │   ├── CardStackView.swift            # ZStack of cards with gestures
│   │   │   ├── SwipeActionButtons.swift       # Bottom ✗ ⭐ ✓ buttons
│   │   │   └── EmptyDeckView.swift            # "No more agents" state
│   │   │
│   │   ├── AgentDetail/
│   │   │   ├── AgentDetailView.swift          # Full agent info sheet
│   │   │   ├── AgentPhotoCarousel.swift       # Photo gallery
│   │   │   ├── AgentInfoSection.swift         # Contact, hours, services
│   │   │   ├── AgentMapView.swift             # Location map thumbnail
│   │   │   └── ClaimProfileButton.swift       # CTA: active if claimable, disabled if unmapped
│   │   │
│   │   ├── Auth/
│   │   │   ├── AuthView.swift                 # Sign in screen
│   │   │   ├── AppleSignInButton.swift        # Native Apple Sign In
│   │   │   └── GoogleSignInButton.swift       # Google Sign In
│   │   │
│   │   ├── Onboarding/
│   │   │   └── OnboardingView.swift           # Single page onboarding
│   │   │
│   │   ├── Profile/
│   │   │   ├── SettingsView.swift             # iOS-native settings (List + Sections)
│   │   │   ├── ProfileHeaderView.swift        # Avatar + name + email
│   │   │   ├── SelectedAgentsView.swift       # Agents user liked
│   │   │   ├── PassedAgentsView.swift         # Agents user passed
│   │   │   ├── MyClaimsView.swift             # Lead requests status
│   │   │   └── EditProfileView.swift          # Edit user info
│   │   │
│   │   └── Components/
│   │       ├── RatingStarsView.swift          # ⭐⭐⭐⭐☆ display
│   │       ├── CategoryBadge.swift            # Pill-shaped category tag
│   │       ├── CachedAsyncImage.swift         # Image loading + cache
│   │       ├── ShimmerView.swift              # Loading placeholder
│   │       └── AuthGateModifier.swift         # ViewModifier: show auth if needed,
│   │                                          # resume pending action after auth
│   │
│   ├── Extensions/
│   │   ├── Color+Hushh.swift                  # Brand colors
│   │   ├── View+Haptics.swift                 # Haptic feedback helpers
│   │   └── Date+Formatting.swift              # Date formatters
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets/                   # App icon, colors, images
│   │   ├── kirkland_agents_seed.json          # Bundled 21 agents (offline fallback)
│   │   └── Info.plist
│   │
│   └── Preview Content/
│       └── PreviewData.swift                  # Sample data for SwiftUI previews
│
├── mitm-setup/                                # Existing MITM proxy tools
├── complete_schema.sql                        # Supabase schema reference
└── README.md                                  # This file
```

---

## 🗄️ Database Tables Used (All Pre-existing — No Migrations)

### Core Tables

#### `kirkland_agents` — Pre-populated Agent Deck (21 agents)
```sql
kirkland_agents (
    id text PK,                    -- Yelp business ID (text, NOT uuid)
    name text NOT NULL,
    alias text,
    phone text,
    localized_phone text,
    address1 text,
    address2 text,
    city text,
    state text,
    zip text,
    country text DEFAULT 'US',
    latitude double precision,
    longitude double precision,
    avg_rating double precision,
    review_count integer DEFAULT 0,
    categories text[],
    is_closed boolean DEFAULT false,
    photo_url text,
    email text,
    website text,
    bio text,
    services text[],
    license_number text,
    years_in_business integer,
    contact_person text,
    status text DEFAULT 'active',
    photos text[]
)
```

#### `users` — App Users
```sql
users (
    id uuid PK → auth.users(id),
    email text,
    phone text,
    full_name text,
    avatar_url text,
    zip_code text,
    onboarding_step text DEFAULT 'landing',  -- 'landing' | 'complete'
    house_rules_accepted_at timestamptz,
    metadata jsonb DEFAULT '{}'
)
```

#### `consumer_profiles` — Onboarding Preferences
```sql
consumer_profiles (
    id uuid PK,
    user_id uuid → users(id) UNIQUE,
    first_name text,
    last_name text,
    insurance_goals text[],
    goal_timeline text DEFAULT 'exploring',
    preferred_zip text,
    service_mode text DEFAULT 'any',
    primary_goal text,
    -- ... more fields available
)
```

#### `user_agent_selections` — Swipe Actions (Deck)
```sql
user_agent_selections (
    id uuid PK,
    user_id uuid → auth.users(id),
    agent_id text → kirkland_agents(id),     -- text FK, NOT uuid
    status text CHECK ('selected' | 'rejected'),
    created_at timestamptz
)
```

#### `lead_requests` — Profile Claims
> ⚠️ **Important:** `lead_requests.agent_id` references `agent_profiles(id)` (uuid),
> NOT `kirkland_agents(id)` (text). Claims only work for agents that have a corresponding
> row in `agent_profiles`. Unmapped kirkland_agents show disabled/info CTA.

```sql
lead_requests (
    id uuid PK,
    user_id uuid → users(id),
    agent_id uuid → agent_profiles(id),      -- uuid FK to agent_profiles, NOT kirkland_agents
    message text NOT NULL,
    preferred_channel text DEFAULT 'chat',
    urgency text DEFAULT 'normal',
    status text CHECK ('requested' | 'viewed' | 'need_info' | 'in_review' |
                       'quote_sent' | 'closed_won' | 'closed_lost' | 'archived')
)
```

#### `agent_profiles` — Internal Verified Agent Profiles
```sql
agent_profiles (
    id uuid PK,
    name text NOT NULL,
    agency text NOT NULL,
    photo_url text,
    verified boolean DEFAULT false,
    years_experience integer,
    rating numeric,
    review_count integer,
    specialties text[],
    lines_of_authority text[],
    licenses jsonb,
    states_served text[],
    office_address text,
    response_time text,
    about text,
    profile_status text CHECK ('active' | 'inactive' | 'unavailable' | 'under_review'),
    is_online boolean DEFAULT false
)
```

#### Supporting Tables
| Table | Purpose |
|-------|---------|
| `swipe_actions` | Swipe tracking for `agent_profiles` (pass / interested / priority) |
| `conversations` + `messages` | Chat after lead/claim |
| `agent_reviews` | Reviews on agents |
| `blocked_agents` | User blocks agent |
| `devices` | Push notification tokens (ios/android/web) |
| `notifications` | Notification delivery (push/sms/email) |
| `analytics_events` | Event tracking |

---

## ⚠️ Claim Mapping: `kirkland_agents` → `agent_profiles`

This is a critical architectural constraint:

```
kirkland_agents (text id)     agent_profiles (uuid id)     lead_requests
┌──────────────────┐          ┌──────────────────┐         ┌──────────────┐
│ id: "abc123"     │──?──────▶│ id: uuid         │◀────────│ agent_id: uuid│
│ (Yelp biz ID)    │          │ (internal agent)  │         │ (FK to       │
│                  │          │                  │         │ agent_profiles│
└──────────────────┘          └──────────────────┘         └──────────────┘
```

**Behavior:**
- Each deck card resolves to either `claimable(agentProfileId: UUID)` or `unavailable`
- `LeadService` only creates `lead_requests` against resolved `agent_profiles.id`
- Unresolved cards show disabled/info CTA — **no write attempt**
- Browse/auth/profile features are NOT blocked by claim mapping
- Claim feature ships with **progressive enablement** — works only for mapped agents

**Default:** `Mapped Only` claim behavior. If no backend mapping source exists to resolve `kirkland_agents` → `agent_profiles`, the app still ships with claim CTA disabled for those cards while the rest of v1 remains fully usable.

---

## 🔄 User Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        APP LAUNCH                            │
│                                                              │
│  Check Supabase session → Logged in? → Check onboarding      │
│                            │                                  │
│                     ┌──────┴──────┐                          │
│                     │             │                           │
│                  No Auth    Has Session                       │
│                     │             │                           │
│                     ▼             ▼                           │
│              ┌──────────┐  ┌──────────────┐                  │
│              │  DECK     │  │ onboarding    │                 │
│              │ (Guest)   │  │ complete?     │                 │
│              └──────────┘  └──────┬───────┘                  │
│                     │         Yes │ No                        │
│                     │          │  │                           │
│                     │          │  ▼                           │
│                     │          │ ┌──────────────┐            │
│                     │          │ │ ONBOARDING   │             │
│                     │          │ │ (1 page)     │             │
│                     │          │ └──────┬───────┘            │
│                     │          │        │                     │
│                     ▼          ▼        ▼                     │
│              ┌──────────────────────────────┐                │
│              │         DECK VIEW            │                │
│              │   Card Stack of Agents       │                │
│              │                              │                │
│              │  ┌────────────────────────┐  │                │
│              │  │    Agent Card          │  │                │
│              │  │    ┌──────────────┐    │  │                │
│              │  │    │  Photo       │    │  │                │
│              │  │    │  Name        │    │  │                │
│              │  │    │  ⭐ 4.8 (22) │    │  │                │
│              │  │    │  📍 Kirkland │    │  │                │
│              │  │    │  🏷️ Finance  │    │  │                │
│              │  │    └──────────────┘    │  │                │
│              │  └────────────────────────┘  │                │
│              │                              │                │
│              │   [✗]     [⭐ Claim]   [✓]   │                │
│              └──────────┬───────────────────┘                │
│                         │                                     │
│         ┌───────────────┼───────────────┐                    │
│         ▼               ▼               ▼                    │
│    Swipe Left     Claim Profile    Swipe Right               │
│    (pass)         (auth-gated)     (interested)              │
│         │               │               │                    │
│         │          ┌────┴────┐          │                    │
│         │          │ Logged? │          │                    │
│         │          └┬──────┬┘          │                    │
│         │         No│    Yes│           │                    │
│         │           ▼      │           │                    │
│         │     ┌──────────┐ │           │                    │
│         │     │  AUTH     │ │           │                    │
│         │     │  SCREEN   │ │           │                    │
│         │     └────┬─────┘ │           │                    │
│         │          │       │           │                    │
│         │     Onboarding?  │           │                    │
│         │     ┌────┴────┐  │           │                    │
│         │     │1st time? │  │           │                    │
│         │     └┬──────┬┘  │           │                    │
│         │    Yes│    No│   │           │                    │
│         │      ▼      │   │           │                    │
│         │  ┌────────┐ │   │           │                    │
│         │  │ONBOARD │ │   │           │                    │
│         │  └───┬────┘ │   │           │                    │
│         │      │      │   │           │                    │
│         │      ▼      ▼   ▼           │                    │
│         │   ┌─────────────────┐       │                    │
│         │   │ RESUME PENDING  │       │                    │
│         │   │ GATED ACTION    │       │                    │
│         │   │ (auto-navigate  │       │                    │
│         │   │  back to claim) │       │                    │
│         │   └─────────────────┘       │                    │
│         │                             │                    │
│         ▼                             ▼                    │
│  ┌────────────────┐        ┌────────────────┐             │
│  │ LOCAL QUEUE     │        │ LOCAL QUEUE     │             │
│  │ (guest swipe)   │        │ (guest swipe)   │             │
│  │ UserDefaults    │        │ UserDefaults    │             │
│  └───────┬────────┘        └───────┬────────┘             │
│          │ on auth                  │ on auth               │
│          ▼                          ▼                       │
│  ┌─────────────────────────────────────────┐               │
│  │ BULK SYNC → user_agent_selections       │               │
│  │ (dedupe on existing user-agent pairs)   │               │
│  └─────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

---

## 📱 Screen Designs

### 1️⃣ Deck Screen (Home) — No Auth Required

The main screen. Tinder-style card stack showing agents from `kirkland_agents`.

**Components:**
- **Top Bar:** Hushh logo (left) · Profile/Settings icon (right)
- **Card Stack:** ZStack of 3 visible cards, top card interactive
- **Card Content:** Agent photo, name, rating stars, review count, city/state, category badges
- **Bottom Actions:** ✗ Pass (red) · ⭐ Claim (gold, disabled if unmapped) · ✓ Interested (green)
- **Tap on card** → Opens Agent Detail Sheet
- **Already-seen filtering:** Selected/rejected agents hidden from deck

**Swipe Gestures:**
- Drag left > 100pt → Pass (red overlay "PASS" appears)
- Drag right > 100pt → Interested (green overlay "INTERESTED" appears)
- Spring animation on release
- Haptic feedback on threshold cross

**Guest swipes** stored in local queue (UserDefaults). Remote write only happens after auth.

### 2️⃣ Agent Detail Sheet — No Auth Required

Bottom sheet / full screen detail view. Fully browseable without auth.

**Sections:**
1. **Photo Carousel** — Horizontal scroll of `photos[]`
2. **Header** — Name, rating stars, review count, categories as pills
3. **Quick Info** — 📍 Address · 📞 Phone · 🌐 Website
4. **About / Bio** — Agent bio text
5. **Services** — List of services offered
6. **Contact Person** — Name of representative
7. **Map** — Lat/long on a small MapKit view
8. **CTA Button** — "Claim This Profile" if `claimable`, disabled/info if `unavailable`

### 3️⃣ Auth Screen — On Demand

Clean, minimal sign-in screen shown **only when user triggers a protected action** (claim, settings, saved lists).

**Components:**
- Hushh logo + tagline "Find Your Perfect Financial Advisor"
- **"Sign in with Apple"** — Native `ASAuthorizationAppleIDButton`
- **"Sign in with Google"** — Google branded button
- **"Maybe Later"** — Dismiss and return to deck
- Privacy note: "By signing in, you agree to our Terms & Privacy Policy"

**Auth Flow:**
1. Apple/Google returns token → Supabase `signInWithIdToken()`
2. Upsert `users` row (create if not exists)
3. Check `onboarding_step` → if not `'complete'`, show onboarding
4. If `'complete'`, **automatically resume pending gated action** (no manual re-navigation)

### 4️⃣ Onboarding Screen — After First Sign Up Only

Single page, shown only when `users.onboarding_step != 'complete'`.

**Fields:**
- **Name** — First name + Last name (pre-filled from Apple/Google if available)
- **What are you looking for?** — Multi-select chips:
  - 💰 Wealth Management
  - 📊 Financial Planning
  - 🏠 Insurance
  - 📈 Investment Advisory
  - 🧾 Tax Planning
  - 🏦 Retirement Planning
- **Your ZIP Code** — Text field (for location matching)
- **How soon?** — Single select:
  - 🔥 ASAP
  - 📅 This month
  - 🔍 Just exploring

**On Submit:**
- Creates `consumer_profiles` row
- Updates `users.onboarding_step = 'complete'`
- **Resumes pending protected action** (e.g., claim, settings) instead of user navigating manually

### 5️⃣ Settings / Profile Screen — Auth Required

iOS-native `List` with grouped sections, exactly like iOS Settings app.

```
┌─────────────────────────────────────────┐
│                                          │
│  ┌──────┐                                │
│  │ 👤   │  John Doe                      │
│  │avatar│  john@example.com              │
│  └──────┘  Edit Profile →                │
│                                          │
├─────────────────────────────────────────┤
│  MY ACTIVITY                             │
│  ───────────────────────────────────     │
│  ✓  Selected Agents              12  →  │
│  ✗  Passed Agents                 8  →  │
│  🏢  My Claims                    2  →  │
│                                          │
├─────────────────────────────────────────┤
│  PREFERENCES                             │
│  ───────────────────────────────────     │
│  🎯  Investment Goals           Edit →  │
│  📍  Location          Kirkland, WA →   │
│  🔔  Notifications              On  →   │
│                                          │
├─────────────────────────────────────────┤
│  SUPPORT                                 │
│  ───────────────────────────────────     │
│  📋  Privacy Policy                  →  │
│  📋  Terms of Service                →  │
│  📧  Contact Support                 →  │
│  ℹ️   App Version              1.0.0     │
│                                          │
├─────────────────────────────────────────┤
│                                          │
│  🔴  Sign Out                            │
│                                          │
└─────────────────────────────────────────┘
```

**Sign Out:** Clears protected state but does NOT break guest browsing. User returns to deck as guest.

---

## 🔐 Auth Gate Logic

| User Action | Auth Required? | Behavior |
|-------------|---------------|----------|
| Browse deck (view cards) | ❌ No | Anyone can see agents |
| Tap card → View detail | ❌ No | Full agent info visible |
| Swipe Left (pass) | ⚡ Deferred | Stored in local queue → synced after auth |
| Swipe Right (interested) | ⚡ Deferred | Stored in local queue → synced after auth |
| Claim Profile | ✅ Yes | Auth gate → onboarding if needed → resume claim |
| Open Settings/Profile | ✅ Yes | Auth gate → onboarding if needed → resume settings |
| View Selected/Passed agents | ✅ Yes | Auth gate → show lists |

### Gated Action Resumption

When a protected action triggers auth:
1. `AppState` stores the **pending gated action** (e.g., `.claim(agentId)`, `.openSettings`)
2. Auth screen shown → user signs in
3. If first-time → onboarding shown → user completes
4. After auth+onboarding → **pending action automatically resumes**
5. User does NOT need to manually re-navigate to the action they intended

### Deferred Sync Strategy

1. Guest swipes stored in `UserDefaults` as `[(agentId: String, status: String)]`
2. On successful auth → bulk insert into `user_agent_selections` with **dedupe on existing user-agent pairs**
3. Clear local cache after successful sync
4. Already-swiped agents filtered from deck
5. **Sync retry** on app foreground / session refresh; failed writes stay in queue until success
6. Returning user: remote selections fetched → selected/rejected cards hidden from deck

---

## 🎨 Design System

### Colors
| Name | Light Mode | Dark Mode | Usage |
|------|-----------|-----------|-------|
| `hushhPrimary` | `#6C5CE7` | `#A29BFE` | Buttons, accents |
| `hushhBackground` | System | System | Main background |
| `hushhCard` | `#FFFFFF` | `#1C1C1E` | Card background |
| `hushhPass` | `#FF6B6B` | `#FF6B6B` | Pass/reject action |
| `hushhLike` | `#51CF66` | `#51CF66` | Like/interested action |
| `hushhClaim` | `#FFD43B` | `#FFD43B` | Claim/star action |
| `hushhText` | System primary | System primary | Main text |
| `hushhSubtext` | System secondary | System secondary | Secondary text |

### Typography
- **System default (SF Pro)** — No custom fonts
- Title: `.title` / `.title2`
- Body: `.body`
- Caption: `.caption`
- Card name: `.title3.bold()`
- Card rating: `.subheadline`

### Animations
- **Card swipe:** `spring(response: 0.4, dampingFraction: 0.7)`
- **Card enter:** `scale(0.95)` → `scale(1.0)` with spring
- **Overlay labels:** "PASS" / "INTERESTED" with opacity based on drag distance
- **Haptics:** `.impact(style: .medium)` on threshold, `.notification(.success)` on action

### Spacing & Sizing
- Card corner radius: `20pt`
- Card shadow: `radius: 10, y: 5`
- Card stack offset: each card offset `8pt` down and `0.95` scale
- Bottom buttons: `60pt` circular
- Standard padding: `16pt`

---

## 📋 Public Interfaces / Key Contracts

### `AppState` (ObservableObject — Root Source of Truth)
```swift
class AppState: ObservableObject {
    @Published var sessionStatus: SessionStatus        // .anonymous | .authenticated(user)
    @Published var onboardingStatus: OnboardingStatus  // .incomplete | .complete
    @Published var pendingGatedAction: GatedAction?    // .claim(agentId) | .openSettings | nil
    @Published var currentUser: AppUser?               // Snapshot of users table row
    
    func resolveGatedAction()     // Clears and executes pending action
    func clearProtectedState()    // Sign out: clear user but keep guest browsing
}
```

### `DeckViewModel` (ObservableObject)
```swift
class DeckViewModel: ObservableObject {
    @Published var cards: [KirklandAgent]
    @Published var selectedAgent: KirklandAgent?        // For detail sheet
    
    func swipe(_ agent: KirklandAgent, direction: SwipeDirection)
    func claimAvailability(for agent: KirklandAgent) -> ClaimAvailability
    func filterAlreadySeen()                            // Remove selected/rejected from deck
    func loadAgents()                                   // Fetch from DB → fallback bundled JSON
}
```

### `AuthService`
```swift
class AuthService {
    func restoreSession() async throws -> Session?
    func signInWithApple(credential: ASAuthorizationCredential) async throws
    func signInWithGoogle(presenting: UIViewController) async throws
    func signOut() async throws
    func onAuthCallback(session: Session) async         // Post-auth: upsert user, sync swipes
}
```

### `SwipeService`
```swift
class SwipeService {
    func queueGuestSwipe(agentId: String, status: String)      // Local UserDefaults
    func loadPendingSwipes() -> [(agentId: String, status: String)]
    func syncPendingSwipes(userId: UUID) async throws          // Bulk insert with dedupe
    func fetchRemoteSelections(userId: UUID) async throws -> [UserAgentSelection]
}
```

### `LeadService`
```swift
class LeadService {
    func resolveClaimTarget(kirklandAgentId: String) async -> ClaimAvailability
    func createLeadRequest(userId: UUID, agentProfileId: UUID, message: String) async throws
    func fetchMyClaims(userId: UUID) async throws -> [LeadRequest]
}
```

### `UserService`
```swift
class UserService {
    func upsertUser(from session: Session) async throws -> AppUser
    func fetchUser(id: UUID) async throws -> AppUser?
    func updateOnboardingStep(userId: UUID, step: String) async throws
    func createConsumerProfile(_ profile: ConsumerProfile) async throws
    func fetchConsumerProfile(userId: UUID) async throws -> ConsumerProfile?
    func updateConsumerProfile(_ profile: ConsumerProfile) async throws
}
```

---

## 🏃 Implementation Plan (Vertical Slices)

### Slice 1: Foundation & App Shell
> App boots, shows loading, data loads from DB or bundled JSON.

| # | Task | Files |
|---|------|-------|
| 1.1 | Create Xcode project + folder structure | Project setup |
| 1.2 | Add SPM dependencies (Supabase, GoogleSignIn) | Package dependencies |
| 1.3 | Supabase client singleton | `SupabaseService.swift`, `Supabase.plist` |
| 1.4 | Core data models | `KirklandAgent.swift`, `AppUser.swift`, `ConsumerProfile.swift`, `UserAgentSelection.swift`, `LeadRequest.swift`, `SwipeDirection.swift`, `ClaimAvailability.swift`, `GatedAction.swift` |
| 1.5 | Bundle seed JSON | `kirkland_agents_seed.json` |
| 1.6 | App state bootstrap | `AppState.swift`, `HushhAgentsApp.swift`, `ContentView.swift` |
| 1.7 | Agent loading service | `AgentService.swift` (fetch → fallback) |

**Exit Criteria:** App launches, loads 21 agents (remote or bundled), shows basic list/placeholder.

### Slice 2: Deck UX (Browse-First Experience)
> Guest users can swipe cards and view details. No auth required.

| # | Task | Files |
|---|------|-------|
| 2.1 | Deck ViewModel | `DeckViewModel.swift` |
| 2.2 | Agent Card UI | `AgentCardView.swift` |
| 2.3 | Card Stack with swipe gestures | `CardStackView.swift` |
| 2.4 | Main deck screen | `DeckView.swift` |
| 2.5 | Action buttons (pass/claim/interested) | `SwipeActionButtons.swift` |
| 2.6 | Empty deck state | `EmptyDeckView.swift` |
| 2.7 | Agent Detail sheet | `AgentDetailView.swift`, `AgentPhotoCarousel.swift`, `AgentInfoSection.swift`, `AgentMapView.swift`, `ClaimProfileButton.swift` |
| 2.8 | Shared components | `RatingStarsView.swift`, `CategoryBadge.swift`, `CachedAsyncImage.swift`, `ShimmerView.swift` |
| 2.9 | Theme & extensions | `Color+Hushh.swift`, `View+Haptics.swift` |
| 2.10 | Local swipe queue | Guest swipes → UserDefaults |

**Exit Criteria:** Full deck experience works as guest. Swipe left/right/tap detail. Cards animate. Guest swipes stored locally.

### Slice 3: Auth & Onboarding
> Protected actions trigger auth. New users see onboarding. Pending actions resume.

| # | Task | Files |
|---|------|-------|
| 3.1 | Auth Service (Apple + Google + Supabase) | `AuthService.swift` |
| 3.2 | Auth ViewModel | `AuthViewModel.swift` |
| 3.3 | Auth Screen UI | `AuthView.swift`, `AppleSignInButton.swift`, `GoogleSignInButton.swift` |
| 3.4 | Auth gate modifier | `AuthGateModifier.swift` |
| 3.5 | User Service (upsert, profile) | `UserService.swift` |
| 3.6 | Onboarding ViewModel | `OnboardingViewModel.swift` |
| 3.7 | Onboarding UI | `OnboardingView.swift` |
| 3.8 | Gated action resumption logic | In `AppState.swift` |

**Exit Criteria:** Claim/settings trigger auth. New user sees onboarding. Returning user skips. Pending action resumes after auth+onboarding.

### Slice 4: Persistence, Profile & Sync
> Swipes sync to Supabase. Settings screen shows user data. Returning users see filtered deck.

| # | Task | Files |
|---|------|-------|
| 4.1 | Swipe Service (local queue + remote sync + dedupe) | `SwipeService.swift` |
| 4.2 | Bulk sync on auth | In `AuthService.swift` callback |
| 4.3 | Fetch remote selections → filter deck | In `DeckViewModel.swift` |
| 4.4 | Profile ViewModel | `ProfileViewModel.swift` |
| 4.5 | Settings screen | `SettingsView.swift`, `ProfileHeaderView.swift` |
| 4.6 | Selected/Passed agent lists | `SelectedAgentsView.swift`, `PassedAgentsView.swift` |
| 4.7 | Edit profile | `EditProfileView.swift` |
| 4.8 | Sync retry on foreground/session refresh | In `SwipeService.swift` |

**Exit Criteria:** Guest swipes sync after login. Returning user sees filtered deck. Settings/profile work. Failed syncs retry.

### Slice 5: Claims + Polish
> Claim flow for mapped agents. UI polish, animations, dark mode.

| # | Task | Files |
|---|------|-------|
| 5.1 | Lead Service (resolve mapping, create lead) | `LeadService.swift` |
| 5.2 | Claim ViewModel | `ClaimViewModel.swift` |
| 5.3 | Claim CTA (active/disabled based on mapping) | `ClaimProfileButton.swift` update |
| 5.4 | My Claims list | `MyClaimsView.swift` |
| 5.5 | Preview data | `PreviewData.swift` |
| 5.6 | Dark mode audit | All views |
| 5.7 | Animation & haptics polish | All interactive views |
| 5.8 | Loading states & error handling | `ShimmerView.swift`, error alerts |

**Exit Criteria:** Claim works for mapped agents. Disabled for unmapped. Full polish pass. Dark mode works. Preview data available.

---

## 📊 Data: 21 Pre-populated Agents

| # | Name | City | Rating | Reviews | Source |
|---|------|------|--------|---------|--------|
| 1 | Sound Planning Group | Kirkland, WA | ⭐ 5.0 | 8 | organic |
| 2 | Snider Financial Group | Bellevue, WA | ⭐ 5.0 | 1 | organic |
| 3 | Elite Wealth Management | Kirkland, WA | ⭐ 4.3 | 14 | organic |
| 4 | WaterRock Global Asset Mgmt | Bellevue, WA | ⭐ 4.8 | 22 | organic |
| 5 | Edward Jones - Calen H Johnson | Kirkland, WA | ⭐ 5.0 | 8 | organic |
| 6 | Joanna Maliva Lee | Kirkland, WA | ⭐ 1.0 | 1 | organic |
| 7 | Jeff LaDue NMLS | Kirkland, WA | ⭐ 5.0 | 22 | organic |
| 8 | PCM Encore | Bellevue, WA | ⭐ 0.0 | 0 | organic |
| 9 | Capital Planning | Bellevue, WA | ⭐ 5.0 | 4 | organic |
| 10 | Brein Wealth Management | Bellevue, WA | ⭐ 5.0 | 1 | organic |
| 11 | Charles Schwab | Redmond, WA | ⭐ 4.5 | 2 | organic |
| 12 | KE & Associates | Kirkland, WA | ⭐ 3.9 | 25 | organic |
| 13 | M3 Tax and Accounting | Kirkland, WA | ⭐ 5.0 | 1 | organic |
| 14 | Huddleston Tax CPAs | Bellevue, WA | ⭐ 3.9 | 19 | organic |
| 15 | Omega Financial & Insurance | Kirkland, WA | ⭐ 5.0 | 2 | organic |
| 16 | Edward Jones - Loren P Winter | Kirkland, WA | ⭐ 5.0 | 1 | organic |
| 17 | Edward Jones - Kagan C. Wolfe | Kirkland, WA | ⭐ 0.0 | 0 | organic |
| 18 | ICON Consulting | Bellevue, WA | ⭐ 0.0 | 0 | organic |
| 19 | Green Financial | Kirkland, WA | ⭐ 5.0 | 1 | organic |
| 20 | HighTower Bellevue | Bellevue, WA | ⭐ 5.0 | 1 | organic |
| 21 | Blue Mountain Wealth Mgmt | Monroe, WA | ⭐ 5.0 | 2 | sponsored |

**Data Source:** Yelp MITM Capture (Kirkland, WA 98033 — "Registered Investment Advisor")

---

## 🧪 Test Plan

| # | Scenario | Expected Result |
|---|----------|-----------------|
| 1 | Fresh install, guest launch, network available | 21 agents load from `kirkland_agents` table, deck shows |
| 2 | Fresh install, network unavailable | 21 agents load from bundled `kirkland_agents_seed.json` |
| 3 | Guest swipes left/right, app restart, then login | Deferred swipes sync to `user_agent_selections` successfully |
| 4 | New user signs in | Onboarding shown → completion returns to deck |
| 5 | Returning user signs in | Onboarding skipped → previous selections filtered from deck |
| 6 | Settings access when logged out | Auth gate triggers → auth screen → resumes settings after login |
| 7 | Claim CTA for unmapped agent | CTA disabled/info state, no write attempt |
| 8 | Claim CTA for mapped agent | Lead request created successfully in `lead_requests` |
| 9 | Sign out | Clears protected state, guest browsing continues |
| 10 | Duplicate sync attempts | No duplicate `user_agent_selections` rows (dedupe) |
| 11 | Sync failure | Failed writes stay in queue, retry on foreground/session refresh |
| 12 | Dark mode | All screens render correctly in light and dark mode |

---

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ device or simulator
- Apple Developer account (for Sign in with Apple)
- Google Cloud Console project (for Google Sign In)

### Setup
1. Clone the repository
2. Open `HushhAgents.xcodeproj` in Xcode
3. Add `Supabase.plist` to `Config/` with:
   ```xml
   <dict>
       <key>SUPABASE_URL</key>
       <string>https://ibsisfnjxeowvdtvgzff.supabase.co</string>
       <key>SUPABASE_ANON_KEY</key>
       <string>YOUR_ANON_KEY</string>
   </dict>
   ```
4. Configure Apple Sign In capability in Xcode
5. Configure Google Sign In `GIDClientID` in Info.plist
6. Build and run on iOS 17+ simulator/device

---

## ✅ Assumptions & Defaults

- iOS 17+, SwiftUI, MVVM, SPM-only integration
- No new database tables or schema changes — all tables pre-exist
- **Default:** `Mapped Only` claim behavior for `lead_requests`
- If no backend mapping source resolves `kirkland_agents` → `agent_profiles`, app still ships with claim CTA disabled for those cards. Rest of v1 remains fully usable
- Auth is on-demand only — never forced at launch
- Sign out clears authenticated state but preserves guest browsing
