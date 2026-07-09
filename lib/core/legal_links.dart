/// Canonical legal/support URLs (KP-003/KP-004). One constant per document so
/// the paywall, Settings, and store metadata can never drift apart.
///
/// The pages are authored in-repo under `site/` and deployed by
/// `.github/workflows/pages.yml` to GitHub Pages. Content derives from
/// `store/privacy/data_safety.md` (the honest disclosure SSOT); counsel review
/// before submission is a founder gate (FOUNDER_ACTIONS_TODO.md F-2/F-6).
library;

const String kPrivacyPolicyUrl =
    'https://emredogan-cloud.github.io/kindredpaws/privacy/';

const String kTermsOfUseUrl =
    'https://emredogan-cloud.github.io/kindredpaws/terms/';

const String kSupportUrl =
    'https://emredogan-cloud.github.io/kindredpaws/support/';
