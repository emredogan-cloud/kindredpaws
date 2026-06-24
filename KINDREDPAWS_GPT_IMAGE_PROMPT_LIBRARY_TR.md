# KINDREDPAWS — GPT IMAGE PROMPT KÜTÜPHANESİ

> **Amaç:** KindredPaws'ın **her ekranı, arka planı ve asset'i** için hazır GPT
> Image üretim talimatları. Her giriş: **dosya adı · kayıt yolu · birebir prompt ·
> görsel boyut · şeffaflık/arka plan gereksinimi.** Prompt'lar İngilizce yazılır
> (image modeli için en tutarlı sonuç); açıklama/çerçeve Türkçedir.
> Görsel hedef: **duygusal sıcaklık · retention · conversion.** SSOT:
> `KINDREDPAWS_CANONICAL_DECISION_BRIEF.md`. Stil kontratı:
> `KINDREDPAWS_UX_UI_MASTER_BIBLE_TR.md` §0.2 + `KINDREDPAWS_RIVE_CHARACTER_MASTER_BIBLE_TR.md` §2.

---

## 0. Kullanım kuralları (her prompt için geçerli)

1. **Stil eki (her prompt'a ekle):** `cozy hand-painted children's storybook
   illustration, soft pastel palette (cream/peach/warm), gentle soft shadows,
   rounded soft shapes, warm and safe and emotionally tender mood, premium mobile
   game quality, NOT scary, NOT violent, child-safe, no text, no watermark`.
2. **Karakter tutarlılığı:** Pet illüstrasyonları **nihai oyun assetı DEĞİL** —
   yalnızca **konsept/doku ilhamı**. Nihai pet, Rive'da çizilir (bkz. Karakter
   Bible §4). Sahnelerde "pet için boş yaşam noktası" bırakılır.
3. **Şeffaflık:** UI elemanları (buton, ikon, kart, kozmetik) **transparent PNG**;
   arka planlar **tam opak (full-bleed)**.
4. **Çocuk-güvenli imza:** asla korkutucu/üzücü/şiddetli; "low/üzgün" durumlar bile
   sıcak ve nazik.
5. **Çözünürlük:** verilen boyutlar **@1x mantıksal**; üretimi **2x–3x** iste ve
   ölçekle (mobil yoğunluk). Kare olmayanlar için en-boy oranını koru.
6. **Lisans:** GPT Image çıktısı ticari kullanıma uygun şekilde üretilir; harici
   referans karıştırma; her asset `assets/CREDITS.md`'ye işlenir.

---

## 1. ARKA PLANLAR (backgrounds) — opak, full-bleed, 1080×2400 (portre 9:20)

### 1.1 `assets/backgrounds/cozy_room_day.png`
- **Boyut:** 1080×2400 · **Arka plan:** opak, full-bleed.
- **Prompt:** "A premium cozy children's-game living room at warm daytime, soft
  sunlight through a window, a plush rug, cushions and a little pet bed in the
  lower-center as an empty pet spot, houseplants, warm wooden tones, gentle bokeh
  light particles, inviting and safe, vertical mobile background, lots of soft
  empty space in the center-lower third for a character to stand. " + *(stil eki)*

### 1.2 `assets/backgrounds/cozy_room_night.png`
- **Boyut:** 1080×2400 · opak.
- **Prompt:** "The same cozy children's-game living room at gentle night, warm
  lamp glow, soft moonlight through the window, twinkling fairy lights, calm and
  sleepy and safe mood, a little glowing pet bed in the lower-center, vertical
  mobile background with soft empty space for a character. " + *(stil eki)*

### 1.3 `assets/backgrounds/rainy_window.png`
- **Boyut:** 1080×2400 · opak.
- **Prompt:** "A cozy nook beside a large rainy window, soft raindrops sliding on
  the glass, warm indoor light contrasting the cool rain, a blanket and cushion,
  calm melancholic-but-warm mood, comforting not sad, empty pet spot in the
  lower-center, vertical mobile background. " + *(stil eki)*

### 1.4 `assets/backgrounds/garden_day.png`
- **Boyut:** 1080×2400 · opak.
- **Prompt:** "A gentle sunny garden, soft green grass, a few flowers, floating
  pollen/leaf sparkles, a low wooden fence, butterflies, fresh and peaceful and
  safe, empty grassy pet spot in the lower-center, vertical mobile background. "
  + *(stil eki)*

### 1.5 `assets/backgrounds/campsite_evening.png`
- **Boyut:** 1080×2400 · opak.
- **Prompt:** "A cozy evening campsite, a small warm campfire glow, a tent, a
  blanket, a starry sky with soft fireflies, calm and adventurous-yet-safe mood,
  empty pet spot near the fire in the lower-center, vertical mobile background. "
  + *(stil eki)*

### 1.6 `assets/backgrounds/onboarding_rainy_dark.png`
- **Boyut:** 1080×2400 · opak.
- **Prompt:** "A soft, gently dim rainy evening, a cozy little sheltered nook (an
  awning / doorway) with a small warm glow ALREADY nearby, calm and tender and
  hopeful (never threatening, never 'lost in scary darkness'), a safe waiting
  feeling, lots of negative space, vertical mobile onboarding background,
  child-safe. " + *(stil eki)*

---

## 2. UI ÇERÇEVELERİ (frames) — transparent PNG

### 2.1 `assets/ui/panel_frame.png`
- **Boyut:** 960×1400 (9-slice uyumlu kenarlar) · **transparent**.
- **Prompt:** "A soft rounded UI panel frame for a cozy mobile game, cream colored
  with a gentle warm border, pillow-like soft shadow, very rounded corners (large
  radius), empty center, plush paper texture, transparent background outside the
  panel. " + *(stil eki)*

### 2.2 `assets/ui/card_frame.png`
- **Boyut:** 720×900 · **transparent**.
- **Prompt:** "A soft rounded content card for a cozy mobile game, warm cream
  surface, subtle peach border, large corner radius, gentle soft shadow, empty
  center for content, transparent background. " + *(stil eki)*

### 2.3 `assets/ui/speech_bubble.png`
- **Boyut:** 800×360 · **transparent**.
- **Prompt:** "A soft warm speech bubble for a cute pet to talk, rounded, cream
  with a gentle tail at the bottom, pillow-soft, no text, transparent background. "
  + *(stil eki)*

### 2.4 `assets/ui/top_bar.png`
- **Boyut:** 1080×200 · **transparent (yarı-saydam zemin)**.
- **Prompt:** "A subtle translucent top status bar strip for a cozy game, very
  soft warm gradient, unobtrusive, rounded bottom edge, empty (no icons), mostly
  transparent. " + *(stil eki)*

---

## 3. BUTONLAR (buttons) — transparent PNG, ~320×320 (kare)

> Her buton: dolgun "yastık", büyük dokunma alanı, sıcak. İkon merkezde.

### 3.1 `assets/ui/buttons/feed.png`
- **Boyut:** 320×320 · **transparent.**
- **Prompt:** "A soft round pillowy game button with a cute food bowl / apple icon
  in the center, warm peach color, gentle highlight and soft shadow, very rounded,
  inviting, transparent background. " + *(stil eki)*

### 3.2 `assets/ui/buttons/clean.png`
- **Boyut:** 320×320 · **transparent.**
- **Prompt:** "A soft round pillowy game button with a gentle water-drop / bubble
  icon in the center, soft sky-blue, highlight + soft shadow, very rounded,
  transparent background. " + *(stil eki)*

### 3.3 `assets/ui/buttons/play.png`
- **Boyut:** 320×320 · **transparent.**
- **Prompt:** "A soft round pillowy game button with a cute ball / yarn icon in the
  center, warm green, highlight + soft shadow, very rounded, playful, transparent
  background. " + *(stil eki)*

### 3.4 `assets/ui/buttons/primary.png` ve `secondary.png`
- **Boyut:** 640×200 (pill) · **transparent.**
- **Prompt (primary):** "A soft pill-shaped primary button for a cozy game, warm
  blue-gray fill (#6C8EAD family), pillowy, gentle highlight, empty center for
  text, transparent background. " + *(stil eki)*
- **Prompt (secondary):** aynı ama "translucent cream fill, subtle border".

---

## 4. KARTLAR (cards)

### 4.1 `assets/cards/keepsake_template.png`
- **Boyut:** 800×1120 · **transparent (kart gövdesi opak, dış transparan).**
- **Prompt:** "A beautiful keepsake memory card for a cozy pet game, warm framed
  illustration area at the top, a soft caption strip at the bottom, like a
  treasured polaroid/storybook page, tender and shareable, empty illustration
  area, transparent outside the card. " + *(stil eki)*

### 4.2 `assets/cards/memory_card.png`
- **Boyut:** 720×400 · **transparent.**
- **Prompt:** "A small warm memory entry card for a pet's memory book, a tiny round
  illustration slot on the left, a soft caption area on the right, storybook feel,
  empty slots, transparent background. " + *(stil eki)*

### 4.3 `assets/cards/shop_item.png`
- **Boyut:** 600×760 · **transparent.**
- **Prompt:** "A cozy shop item card, soft cream surface, rounded, a clear product
  image slot in the center, a gentle price ribbon at the bottom, friendly and
  non-pushy, empty image slot, transparent background. " + *(stil eki)*

---

## 5. DÜKKÂN & WARDROBE ASSETLERİ — transparent PNG

### 5.1 `assets/shop/rescue_bundle_badge.png`
- **Boyut:** 400×400 · **transparent.**
- **Prompt:** "A warm gentle badge for a 'Rescue Bundle' that shows giving/heart,
  a soft paw + heart motif, cream and warm green, trustworthy and kind (transparent
  giving), no aggressive sale styling, transparent background. " + *(stil eki)*

### 5.2 `assets/wardrobe/hat_examples.png` (örnek set)
- **Boyut:** 512×512 (her item) · **transparent.**
- **Prompt:** "A set of cute cozy pet accessories on transparent background: a tiny
  knitted bobble hat, a soft bow, a small scarf, a flower crown — pastel, soft,
  child-safe, each centered, transparent background. " + *(stil eki)*

### 5.3 `assets/wardrobe/collar_examples.png`
- **Boyut:** 512×512 · **transparent.**
- **Prompt:** "A set of soft pet collars/bandanas in pastel colors with tiny cute
  charms (star, heart, bell), gentle and safe, on transparent background. "
  + *(stil eki)*

---

## 6. İKONLAR (icons) — transparent PNG, 256×256

> Dolgun, yuvarlatılmış; her zaman UI'da etiketle eşlik eder (a11y).

| Dosya | Konu | Prompt çekirdeği |
|---|---|---|
| `assets/icons/kibble.png` | Kibble parası | "a cute rounded dog/cat kibble bone-treat coin, warm tan" |
| `assets/icons/bond_heart.png` | Bond | "a soft glowing heart, warm pink, gentle" |
| `assets/icons/wardrobe.png` | Gardırop | "a tiny cozy wardrobe / hanger with a bow" |
| `assets/icons/keepsakes.png` | Hatıralar | "a soft photo album / polaroid stack" |
| `assets/icons/memory_book.png` | Anı defteri | "a warm little storybook with a bookmark heart" |
| `assets/icons/shop.png` | Dükkân | "a cozy little shop bag / basket" |
| `assets/icons/settings.png` | Ayarlar | "a soft rounded gear, friendly not technical" |
| `assets/icons/notification_bell.png` | Bildirim | "a gentle soft bell with a tiny sparkle, calm" |

- **Her ikon boyutu:** 256×256 · **transparent.**
- **Tam prompt deseni:** "A filled, rounded, soft mobile-game icon of <konu>,
  pastel, pillowy, centered, simple, child-safe, transparent background. " + *(stil eki)*

---

## 7. PREMIUM ASSETLERİ — transparent / opak

### 7.1 `assets/premium/forever_friends_header.png`
- **Boyut:** 1080×600 · **transparent (üst illüstrasyon).**
- **Prompt:** "A warm tender header illustration for a 'Forever Friends'
  membership, a cozy scene of a pet and a soft glowing heart, gentle premium feel,
  trustworthy and kind (never manipulative), pastel, empty lower area for plan
  cards, transparent background at edges. " + *(stil eki)*

### 7.2 `assets/premium/entitled_glow.png`
- **Boyut:** 720×720 · **transparent.**
- **Prompt:** "A soft celebratory warm glow with tiny hearts/sparkles for a
  'thank you, you're a Forever Friend' state, gentle and grateful, transparent
  background. " + *(stil eki)*

---

## 8. EMPTY-STATE & İLLÜSTRASYONLAR — transparent PNG

### 8.1 `assets/illustrations/empty_keepsakes.png`
- **Boyut:** 800×800 · **transparent.**
- **Prompt:** "A gentle empty-state illustration for an empty keepsakes shelf,
  a single soft polaroid waiting to be filled, warm and hopeful (never sad), a
  tiny 'your memories will live here' feeling, transparent background. " + *(stil eki)*

### 8.2 `assets/illustrations/empty_memory_book.png`
- **Boyut:** 800×800 · **transparent.**
- **Prompt:** "A warm empty-state for a memory book with a few blank soft pages and
  a tiny heart bookmark, inviting and hopeful, transparent background. " + *(stil eki)*

### 8.3 `assets/illustrations/adoption_choice.png`
- **Boyut:** 1080×800 · **transparent.**
- **Prompt:** "A tender illustration of two soft glowing spots inviting a choice
  (a puppy spot and a kitten spot), warm light, emotional 'give it a forever home'
  feeling, empty character slots, transparent background. " + *(stil eki)*

### 8.4 `assets/illustrations/onboarding_beats.png` (3'lü set)
- **Boyut:** 1080×800 (her beat) · **transparent.**
- **Prompt:** "Three gentle onboarding illustrations: (1) a cold rainy evening with
  a soft warm light nearby, (2) a tiny curled-up shape resting under a cozy shelter
  with a safe warm glow close by, calm and waiting (NOT lost-in-the-dark, never
  frightening), (3) a hand of warmth reaching out — emotional, tender, child-safe,
  transparent background. " + *(stil eki)*

---

## 9. SICAKLIK & GÜVEN NOTLARI (görsel taraf)

> İlke: KindredPaws **oyuncunun (çoğu zaman bir çocuğun) duygusal bağını bir
> ticari kaldıraç olarak kullanmaz.** Retention ve conversion, **dürüst
> sıcaklığın ve güvenin doğal sonucudur** — manipülasyon değil. Görsel hedef:
> oyuncunun gerçekten değer verdiği bir deneyim yaratmak.

- **Sıcaklık → kalıcılık:** her sahne "kalmak isteyeceğin bir köşe" hissi vermeli
  (oyuncu için iyi olduğu için, "elde tutma metriği" için değil).
- **Anı görselleri (keepsake/memory) = bağın derinliği:** en çok özen bunlara;
  amaç oyuncunun anlamlı anılarını onurlandırmak.
- **Premium görselleri = güven, asla baskı:** hiçbir agresif satış/FOMO yok.
  Şeffaf ve nazik ton; oyuncu **gerçekten istediği için** seçer.
- **Empty-state'ler asla üzücü değil:** "burası sevgiyle dolacak" umudu.
- **Çocuk-güvenli imza her assette:** korkutucu/üzücü/şiddetli HİÇBİR şey yok.

---

## 10. ÜRETİM KONTROL LİSTESİ (her asset)
1. Doğru dosya adı + `assets/...` yolu.
2. Stil eki (§0.1) prompt'a eklendi.
3. Doğru boyut + 2x/3x ölçek.
4. Doğru şeffaflık (UI = transparent, arka plan = opak).
5. Çocuk-güvenli imza geçti (korkutucu/üzücü/şiddetli yok).
6. `pubspec.yaml` assets'e + `assets/CREDITS.md` lisans kaydına eklendi.

*Bu kütüphane ile bir tasarımcı/AI, KindredPaws'ın tüm görsel dünyasını — sıcak,
tutarlı, çocuk-güvenli ve dönüşüm-dostu — uçtan uca üretebilir.*
