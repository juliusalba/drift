# Screen Pattern Reference — Refero Search Strategies

## Quick-Reference: Best Search Queries by Screen Type

### Authentication
| Screen | Query | Good Reference Apps |
|---|---|---|
| Login | `"login email password dark mode"` | Linear, Notion, Spotify |
| Sign Up | `"signup registration form with social auth"` | Airbnb, Revolut |
| Forgot Password | `"forgot password email reset"` | Stripe, Linear |
| 2FA | `"two factor authentication code input"` | Revolut, Coinbase |

### Onboarding
| Screen | Query | Good Reference Apps |
|---|---|---|
| Welcome | `"onboarding welcome screen with illustration"` | Headspace, Calm |
| Permissions | `"onboarding permissions request notifications"` | Fitness apps |
| Personalization | `"onboarding quiz preferences selection"` | Spotify, Pinterest |
| Feature Tour | `"onboarding feature walkthrough carousel"` | Notion, Linear |

### Core Navigation
| Screen | Query | Good Reference Apps |
|---|---|---|
| Tab Bar Home | `"home dashboard tab bar ios"` | Instagram, Twitter |
| Settings | `"settings page sections toggles dark mode"` | Linear, Apple Settings |
| Profile | `"profile page avatar stats bio"` | Instagram, Twitter |
| Search | `"search screen with filters categories"` | Airbnb, Spotify |

### Commerce
| Screen | Query | Good Reference Apps |
|---|---|---|
| Pricing/Paywall | `"paywall subscription plans toggle"` | Calm, Headspace, Notion |
| Product Detail | `"product detail page hero image"` | Airbnb, Apple Store |
| Cart/Checkout | `"checkout payment summary"` | Stripe, Shopify |

### Content
| Screen | Query | Good Reference Apps |
|---|---|---|
| Feed | `"content feed cards social"` | Instagram, Twitter, Reddit |
| Detail | `"article detail page hero image"` | Medium, Substack |
| Empty State | `"empty state illustration call to action"` | Linear, Notion |
| Error State | `"error state retry illustration"` | Stripe |

### Data & Analytics
| Screen | Query | Good Reference Apps |
|---|---|---|
| Dashboard | `"analytics dashboard cards charts dark mode"` | Linear, Framer |
| Data Table | `"data table filters sorting"` | Linear, Notion |
| Charts | `"analytics charts line bar dark mode"` | Stripe, Anthropic |

## Pattern → SwiftUI Mapping

| Refero Pattern | SwiftUI Implementation |
|---|---|
| Grouped sections with headers | `Form { Section("Header") { ... } }.formStyle(.grouped)` |
| Card grid | `LazyVGrid(columns: [...]) { ForEach { CardView() } }` |
| Hero image with overlay text | `Image().overlay(alignment: .bottom) { gradient + text }` |
| Tab navigation | `TabView { ... }.tabViewStyle(.tabBarOnly)` |
| Bottom sheet | `.sheet(isPresented:) { content }` |
| Segmented control | `Picker().pickerStyle(.segmented)` |
| Toggle row with icon | `HStack { Image(); VStack { title; subtitle }; Spacer(); Toggle() }` |
| Score ring | `Circle().trim(from: 0, to: score).stroke(...)` |
| Status badge | `Text().padding(.horizontal, 8).background(.capsule)` |
| Inline expandable | `DisclosureGroup("Title") { content }` |
