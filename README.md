# ClearDish

ClearDish is a cross-platform Flutter application that helps users filter restaurant menus based on their allergens and dietary preferences. This MVP focuses on the "Endorsement Panel" feature set.

## Features

- **Authentication**: Email/password login and registration via Supabase Auth
- **User Profile**: Manage allergens and dietary preferences
- **Restaurant Discovery**: Browse available restaurants with search functionality
- **Menu Filtering**: View menus with "Safe Only" toggle to hide items containing user allergens
- **Onboarding**: Guided setup for allergens and dietary preferences

## Architecture

- **State Management**: Flutter Riverpod
- **Routing**: go_router
- **Backend**: Supabase (Auth + Postgres)
- **Design**: Material 3 with dark green color scheme
- **Null Safety**: Full null-safety compliance

## Project Structure

```
lib/
  core/
    config/app_env.dart          # Environment configuration
    routing/app_router.dart       # App routing setup
    theme/app_theme.dart          # Theme configuration
    utils/result.dart             # Result type for error handling
  data/
    models/                      # Data models
    sources/                     # API clients
    repositories/                # Repository layer
  features/
    auth/                         # Authentication feature
    profile/                      # User profile feature
    restaurants/                  # Restaurants listing
    menu/                         # Menu with allergen filtering
    subscription/                 # Subscription placeholder
    onboarding/                   # Onboarding flow
    home/                         # Home shell with navigation
  widgets/
    app_button.dart               # Custom button widget
    app_input.dart                # Custom input widget
    chips_filter.dart             # Multi-select chips widget
  main.dart                       # Application entry point
```

## Setup Instructions

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Supabase account and project

### 1. Clone and Install Dependencies

```bash
flutter pub get
```

### 2. Configure Supabase

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Get your project URL and anon key from Project Settings > API
3. Configure environment variables:

**Option A: Using environment variables (Recommended for production)**

```bash
# Windows PowerShell
$env:SUPABASE_URL="your-project-url"
$env:SUPABASE_ANON_KEY="your-anon-key"
flutter run
```

**Option B: Direct configuration (Development only)**

Edit `lib/core/config/app_env.dart` and replace the default values:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 3. Run Database Migrations

1. Open your Supabase project dashboard
2. Go to SQL Editor
3. Run `supabase/migrations/001_initial_schema.sql` to create the database schema
4. Run `supabase/migrations/002_seed_data.sql` to insert sample data (optional, for demo purposes)

### 4. Run the App

```bash
flutter run
```

## Demo Account

For testing the MVP flow:

- **Email**: `demo@cleardish.co.uk`
- **Password**: `Passw0rd!`

(You'll need to create this account first through the registration screen)

## MVP Flow

1. **Login/Register**: Sign in or create a new account
2. **Onboarding**: Select allergens and dietary preferences
3. **Restaurants**: Browse available restaurants
4. **Menu**: View restaurant menu with "Safe Only" filter toggle
5. **Profile**: Edit profile, allergens, and diets
6. **Subscription**: Placeholder screen (coming soon)

## Allergen Filtering Logic

When "Safe Only" toggle is enabled:
- Menu items that contain **any** allergen from the user's allergen list are hidden
- A message displays how many items were hidden
- Filtering is done client-side based on the intersection of `menu_item.allergens[]` and `user_profile.allergens[]`

## Available Allergens

- Gluten
- Peanut
- Tree Nuts
- Milk
- Egg
- Fish
- Shellfish
- Soy
- Sesame

## Available Diets

- Vegan
- Vegetarian
- Keto
- Halal
- Kosher
- Paleo

## Testing

Run unit tests:

```bash
flutter test
```

Current test coverage includes:
- Allergen filtering logic
- Profile save operations
- Restaurants empty state handling

## Build & Deployment

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

Note: iOS Store deployment is currently out of scope for this MVP.

## Seed Data

The seed data script includes:
- 3 sample restaurants
- 5 menu categories
- 20 menu items with allergen information

To populate your database, run `supabase/migrations/002_seed_data.sql` in the Supabase SQL Editor.

## Screenshots

Screenshot generation is optional. To create screenshots for documentation:

1. Run the app in a simulator/emulator
2. Navigate to each screen
3. Capture screenshots and save to `screenshots/` directory:
   - `restaurants_screen.png`
   - `menu_safe_toggle.png`
   - `profile_allergens.png`

## Development Notes

- All code follows Flutter lints strict rules
- Material 3 design system with dark green color scheme
- Null-safety enabled throughout
- Modular architecture for maintainability
- Error handling via Result type pattern

## Roadmap (Out of Scope for MVP)

- iOS Store publication
- Advanced admin panel
- Multi-language support
- Push notifications
- Stripe subscription integration (placeholder screen exists)

## Troubleshooting

### Supabase Connection Issues

- Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set correctly
- Check Supabase project is active and accessible
- Ensure RLS policies are correctly configured

### Build Errors

- Run `flutter clean` and `flutter pub get`
- Ensure Flutter SDK version matches requirement
- Check `analysis_options.yaml` for linting issues

## License

This project is proprietary and confidential.

## Support

For issues or questions, please contact the development team.


