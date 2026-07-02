# KINDREDPAWS — RIVE KARAKTER ÜRETİM ANA REHBERİ (MASTER BIBLE)

> **Amaç:** Gelecekteki sanatçılar ve AI ajanları, KindredPaws'ın HER karakterini
> **yalnızca bu rehberi okuyarak** üretebilmelidir. Hiçbir gizli bilgi
> gerektirmez. Tek doğruluk kaynağı (SSOT): `KINDREDPAWS_CANONICAL_DECISION_BRIEF.md`
> → `current_state.json`. Teknik kontrat: `docs/RIVE_CONTRACTOR_HANDOFF.md`,
> `docs/PET_RENDERER_ARCHITECTURE.md`, `docs/LIVE2D_RIG_DESIGN_BRIEF.md`.

**Duygusal kimlik (ezber):** "Terk edilmiş minik bir canlıyı kurtardım, sevgiyle
büyüttüm, ona bağlandım ve birlikte gerçek dünyayı daha iyi bir yer yaptık."
Çekirdek duygular: *bağlanma, şefkat, sorumluluk, huzur, empati, gurur, anlamlılık*.
Her karar bu yedi duyguya hizmet eder. **Asla** suçluluk, korku, baskı yok.

---

## 0. Değişmez kurallar (ihlal edilemez)

1. **Çocuk-güvenli (herkes için).** Hiçbir karakter/animasyon korkutucu,
   şiddet içeren, cinsel ima taşıyan veya kasvetli olamaz. `low` (düşük) ruh hali
   bile **sıcak ve nazik** kalır — "açlık"/"yalnızlık" asla acı verici çizilmez.
2. **Asla suçlandırma/utandırma.** Üzgün durumlar bile "seni özledim ama sorun
   değil" enerjisindedir, "beni terk ettin" değil.
3. **Pati refahı paraya bağlanamaz.** Karakter görünümü/duygusu satın almayla
   *zayıflamaz*; premium yalnızca kozmetik neşe ekler.
4. **Tek rig, parametrik ifade (Risk R7 maliyet kaldıracı).** Her duygu için YENİ
   çizim YOK. Tek rig, parametre karışımlarıyla (blend) 12 duyguyu üretir.
5. **60 fps / orta-segment Android.** Rig hafif olmalı (aşağıdaki bütçeler).

---

## 1. KARAKTER STRATEJİSİ

### 1.1 Türler
- **Puppy (Yavru Köpek)** — varsayılan tür, varsayılan ad **"Biscuit"**.
  Sıcak, sadık, "her zaman sevinçli karşılayan" enerji. Yeni oyuncuya en hızlı
  bağlanmayı veren tür (köpek = koşulsuz sevgi arketipi).
- **Kitten (Yavru Kedi)** — varsayılan ad **"Mochi"**. Daha sakin, meraklı,
  "kendi alanı olan ama sana ısınan" enerji. Daha içe dönük oyuncuya hitap eder.

### 1.2 İlk hangi tür gönderilir?
**Puppy önce devreye girer** (referans karakter), ama **adoptionda her ikisi de
seçilebilir olmalı** (oyuncuya ilk kararı verdirmek = bağlanma başlangıcı).
Üretim sırası: önce Puppy rig'i tamamlanır + dondurulur (referans), sonra Kitten
**aynı rig iskeletine** uyarlanır.

### 1.3 Kaç ırk (breed)?
- **MVP: 1 puppy + 1 kitten. Toplam 2 karakter.** Başka ırk YOK.
- **Neden:**
  - **Solo-kurucu fizibilitesi.** Her ek karakter = 1 rig + **16 durum (4 idle +
    12 reaksiyon)** + 5 mikro-jest + 3 yaş kademesi + QA. İki karakter = **32 durum
    (8 idle + 24 reaksiyon) + 10 mikro-jest** + yaş varyantı demek. Daha fazlası
    MVP'yi boğar.
  - **MVP/post-MVP kesim çizgisi (sigorta).** Zaman daralırsa **MVP-kritik
    reaksiyon alt kümesi**: `happy, content, sleepy, lonely(nazik), hungry(sevimli),
    affectionate` + 4 idle. Kalan 6 reaksiyon (`excited, playful, proud, calm,
    curious, comforted`) **post-MVP cila** olarak ertelenebilir — oyun yine de
    duygusal çekirdeği taşır.
  - **Duygusal derinlik > çeşitlilik.** Oyuncu *tek* bir varlığa bağlanır; çok
    sayıda ırk, "koleksiyon" hissi yaratıp bağı zayıflatır (anti-hedef).
  - **Maliyet (Risk R7).** Tek paylaşılan rig şablonu = en düşük sanat OPEX.
  - **Genişleme kapısı.** Ek ırklar **kozmetik varyant** (kürk deseni/renk) olarak
    yaşam-sonrası içerik (post-launch) ile gelir — yeni rig DEĞİL.
- **Doğrulama:** Kod `Species { puppy, kitten }` ile birebir uyumlu
  (`lib/game/model/species.dart`). Üçüncü tür eklemek = brief güncellemesi gerektirir.

### 1.4 Yaşam kademeleri (her karakter 3 kez yaşlanır)
| id | Görünen ad | Rig ölçeği | His |
|---|---|---|---|
| `pupKit` | Pup/Kit | 0.70 | Bebeksi: büyük kafa, kısa patiler, sakar tatlılık |
| `youngOne` | Young One | 0.85 | Genç: oranlar dengelenir, enerji artar |
| `grown` | Grown | 1.00 | Yetişkin: tam oran, sakin özgüven |

Yaş, **aynı rig** üzerinde `lifeStage` parametresiyle (oran + doku) sürülür —
ayrı çizim değil. İstemci ayrıca render ölçeğini uygular.

---

## 2. GÖRSEL KİMLİK

**Referans:** *My Talking Tom* (silüet okunabilirliği, ifade netliği, mobil-dostu
sadelik). **AMA KindredPaws daha:** **sıcak · güvenli · yumuşak · cozy · duygusal
olarak daha derin.** Talking Tom "komik/yaramaz"; KindredPaws "sevecen/huzurlu".

### 2.1 Karşılaştırma tablosu (his farkı)
| Boyut | My Talking Tom | **KindredPaws** |
|---|---|---|
| Çizgi | Keskin, kontrast yüksek | **Yumuşak, hafif kalın, yuvarlatılmış uçlar** |
| Renk | Canlı, doygun | **Pastel, düşük-doygunluk, sıcak undertone (şeftali/krem)** |
| İfade | Abartılı komedi | **İnce, içten; gözlerde "ışık" var** |
| Gölge | Sert | **Yumuşak ambient occlusion, gradyan** |
| Genel | Oyuncak | **Canlı, sevilebilir bir bebek-hayvan** |

### 2.2 Oranlar (cuteness mühendisliği — "baby schema")
- **Kafa/vücut oranı:** `pupKit` ≈ **1:1.6** (kafa büyük), `grown` ≈ **1:2.2**.
  Talking Tom'dan **biraz daha büyük kafa** → daha bebeksi, daha güvenli.
- **Göz boyutu:** kafa genişliğinin **~%30–34'ü** (Talking Tom ~%25). **Büyük,
  parlak, yuvarlak gözler** + belirgin **catchlight (göz ışığı)** = sıcaklık ve
  canlılık. Gözler **hafif aşağı-içe** yerleşir (savunmasız/sevimli).
- **Kafa şekli:** yuvarlak, köşesiz; yanaklar dolgun.
- **Patiler:** **kısa ve yumuşak yastıkçıklı**, parmak ayrıntısı minimal; jeli
  gibi tombul. Asla pençe/keskinlik vurgusu yok.
- **Kulaklar:** **yumuşak, sarkık-yumuşak** (puppy: hafif düşük, sevimli sarkma;
  kitten: yuvarlatılmış üçgen, uçlar küt). Kulaklar duyguyu taşıyan birincil
  ikincil-hareket (secondary motion) elemanı.
- **Kuyruk:** kalın tabandan inceyen, **yumuşak salınımlı**; en güçlü "mutluluk"
  sinyali (tail wag). Kitten kuyruğu daha uzun/akışkan, puppy daha kısa/canlı.
- **Burun & ağız:** küçük, yumuşak; gülümseme **ince eğri**, abartısız.
- **Silüetler:** Her karakter **siyah silüette bile tanınmalı** (okunabilirlik
  testi). Puppy silüeti: yuvarlak gövde + sarkık kulak + canlı kuyruk. Kitten
  silüeti: zarif kıvrım + dik-yuvarlak kulak + uzun kuyruk. Yaş kademesi
  silüeti orantıyla değiştirir (bebek = top gibi yuvarlak).

### 2.3 Renk paleti (kanonik)
- Ana yüzey: krem/şeftali/açık kahve tonları (sıcak, nötr, herkese sevimli).
- Vurgu: yumuşak turuncu (puppy), açık gri-bal (kitten).
- Arka plan uyumu: UX bible'daki cozy sahnelerle düşük-kontrast uyum.
- **Erişilebilirlik:** ifade asla yalnızca renge dayanmaz (poz + yüz de anlatır).

---

## 3. ÜCRETSİZ / DÜŞÜK MALİYETLİ ASSET STRATEJİSİ

> **Hukuki ilke:** KindredPaws **ticari** bir üründür. Yalnızca **ticari kullanıma
> izin veren, atıf-opsiyonel veya kamu malı** lisanslar kullanılır. Her asset için
> lisans **yazılı kaydedilir** (`assets/CREDITS.md`). Şüphede olan asla kullanılmaz.

### 3.1 Lisans hızlı-referans
| Lisans | Ticari? | Atıf? | KindredPaws'ta kullanım |
|---|---|---|---|
| CC0 / Public Domain | ✅ | ❌ | **Tercih edilen** (serbest) |
| CC-BY | ✅ | ✅ (zorunlu) | İzinli — atıf `CREDITS.md`'ye |
| CC-BY-SA | ⚠️ | ✅ + share-alike | **Kaçın** (viral lisans riski) |
| CC-BY-NC | ❌ | — | **YASAK** (non-commercial) |
| MIT/Apache (kod/şablon) | ✅ | ✅ | Şablon/araç için uygun |

### 3.2 Kaynak kaynak değerlendirme
- **Rive Community (rive.app/community):** Topluluk dosyaları **tek tip CC-BY**
  altındadır → **ticari kullanım SERBEST, ama ATIF ZORUNLU** (`assets/CREDITS.md`).
  ("Netliği değişir" değil — tümü CC-BY.) Yine de bunlar başkasının yazdığı
  rig'in **türev eseridir**; bu yüzden **çekirdek pet rig'i remix DEĞİL, sıfırdan
  özgün çizilir** (kimlik + türev-eser riskinden kaçınma). Community dosyaları
  yalnızca **öğrenme/ilham** ve atıf-kayıtlı yardımcı elemanlar için.
- **OpenGameArt.org:** Filtreyi **CC0/CC-BY** yap. Doku, arka plan elemanı, ikon
  için iyi. Karakterde "jenerik" görünmemek için doğrudan kullanma; stil-uyum için
  yeniden çiz.
- **itch.io (asset packs):** Çok sayıda ücretsiz/uygun-fiyat pack. **Lisansı pack
  sayfasında tek tek oku** (bazıları NC). UI kit + cozy arka plan için verimli.
- **unDraw (undraw.co):** Atıfsız ticari serbest — **ANCAK lisans, illüstrasyonları
  bir uygulamanın İÇİNE gömülü temel asset olarak kullanmayı açıkça kısıtlar**
  (ve ML eğitimini yasaklar). Yani: **web/pazarlama görseli için serbest;
  uygulama-içi gömülü asset (onboarding/empty-state) için lisans gri-alanı.**
  → Bu yüzden empty-state'leri **ÖZGÜN çiz** veya **gerçek CC0** kaynak kullan
  (Humaaans, openpeeps.com, SVGRepo'nun CC0 filtresi). Her asset lisansını
  **tek tek** doğrula; şüphede kullanma.
- **Humaaans (humaaans.com):** CC0-benzeri serbest, karıştırılabilir insan
  illüstrasyonu. KindredPaws insan göstermez (pati odaklı) → **düşük öncelik**;
  yalnızca "bağışçı/yardım" anlatı görselinde dolaylı kullanılabilir.
- **LottieFiles (lottiefiles.com):** Ücretsiz Lottie animasyonları (mikro-etkileşim,
  yükleniyor, konfeti). Lisansı animasyon başına değişir → **yalnızca "Free for
  commercial" işaretli**. Not: Çekirdek pet rig'i **Rive**'dir; Lottie sadece UI
  süslemesi (kalp, yıldız, konfeti) için.
- **Vektör kaynak (genel):** SVGRepo (CC0 filtreli), Google Material Symbols
  (Apache-2.0, ikonlar), Phosphor Icons (MIT).

### 3.3 Karakter için altın kural
**Ana pet karakteri sıfırdan, özgün çizilir** (kimlik + hukuki güvenlik). Ücretsiz
kaynaklar **arka plan, UI çerçeve, ikon, empty-state, mikro-animasyon** için
kullanılır — pet'in kendisi için **referans evet, doğrudan kopya hayır.**

---

## 4. ARAÇ STRATEJİSİ (araç sayısını minimize et)

**Yalnızca 4 araç. Hepsi ücretsiz katmanda yeterli.**

| Aşama | Araç | Neden / Lisans notu |
|---|---|---|
| **Sketch (eskiz)** | **GPT Image** (concept) + kâğıt/Procreate ops. | Hızlı konsept varyasyonu üretir; nihai değil, yön bulma. |
| **Cleanup / illüstrasyon** | **Figma** (ücretsiz) | Vektör çizim, bileşen, palet, layout; tarayıcıda, bedava. |
| **Vektörleştirme** | **Inkscape** (ücretsiz, açık kaynak) | GPT/raster eskizi temiz SVG'ye çevirir (trace + el düzeltme). |
| **Rigging + Animation + State Machine** | **Rive Editor** (ücretsiz katman) | Bones, mesh, blend, state machine; runtime ile birebir. |
| **Export** | **Rive** → `.riv` | Tek dosya; `assets/rive/` altına. |

**Akış özeti:** GPT Image (fikir) → Figma/Inkscape (temiz vektör) → Rive
(kemik+mesh+state machine) → `.riv` export → Flutter.

> **Araç lisansı ≠ asset lisansı.** Inkscape (GPL), Rive Editor veya Figma ile
> ÜRETTİĞİN sanata bu araçların lisansı **bulaşmaz** — sen çiziyorsun, telif
> sende. Lisans yalnızca **dağıttığın 3. taraf asset'i** için önemlidir (§3).

> **GPT Image notu:** GPT Image **konsept ve doku ilhamı** için kullanılır,
> **nihai oyun assetini doğrudan üretmek için değil** (tutarlılık + hukuki
> netlik için son çizim sanatçı/vektör elinde olur). Tüm GPT prompt'ları
> `KINDREDPAWS_GPT_IMAGE_PROMPT_LIBRARY_TR.md`'de.

---

## 5. TAM ÜRETİM PIPELINE (her karakter için adım adım)

**Girdi:** bu rehber + `RIVE_CONTRACTOR_HANDOFF.md`. **Çıktı:** `assets/rive/<tür>.riv`.

1. **Concept (Konsept).** GPT Image ile 3–5 poz/ifade varyasyonu üret (§2 oranları
   + §2.3 palet prompt'uyla). En "sıcak ve okunabilir" olanı seç. Silüet testi yap.
2. **Illustration (İllüstrasyon).** Seçilen konsepti Figma'da **temiz, katmanlı**
   vektöre çiz. Her hareketli parça AYRI katman: kafa, gövde, kulak(sol/sağ),
   ön/arka patiler, kuyruk, göz(ler), göz-kapağı, ağız, kaş/yanak. Nötr "T-poz"
   (rige en uygun, simetrik, ağzı kapalı, gözleri açık) referans poz.
3. **Vector cleanup (Vektör temizliği).** Inkscape'te yolları sadeleştir (düşük
   düğüm sayısı = düşük runtime maliyeti), isimlendir, simetriyi düzelt, SVG'yi
   Rive'ın beklediği gruplara böl.
4. **Rig (İskelet).** Rive'da kemik hiyerarşisi kur: gövde-kök → kafa → (kulaklar,
   gözler, ağız), gövde → (ön patiler, arka patiler, kuyruk). Mesh deformasyonu
   nefes/squash-stretch için. **İkincil hareket** (kulak/kuyruk salınımı) zorunlu.
   Yaş için `lifeStage` parametresine bağlı oran/ölçek hedefleri tanımla.
5. **State machine.** §8 spesifikasyonunu birebir uygula: 3 girdi (`mood`,
   `lifeStage`, `emotion`), 4 idle, 12 reaksiyon. Reaksiyonlar tek-atış (<2 sn),
   sonra mevcut `mood` idle'ına döner.
6. **Export.** `.riv` olarak `assets/rive/<tür>.riv`. Dosya boyutu hedefi **< 400 KB**
   (mesh/keyframe optimizasyonu). Boyut ve fps'i Rive önizlemesinde doğrula.
7. **Flutter entegrasyonu.** `pubspec.yaml` assets'e ekle. `lib/render/` Rive seam'i
   (`RivePetRenderer`) `mood`/`lifeStage`/`emotion` girdilerini sürer
   (`riveMoodValue`/`riveLifeStageValue`/`riveEmotionValue` eşleşmesi). Placeholder
   renderer'dan gerçek `.riv`'e geç; golden testleri güncelle; cihazda 60fps doğrula.

**QA kapısı (her karakter):** silüet okunur · 4 idle ayrışır · 12 reaksiyon
ayrışır + idle'a döner · 3 yaş kademesi oran değiştirir · 60fps · <400KB ·
**hiçbir poz korkutucu/üzücü/şiddetli değil (çocuk-güvenli imzası).**

---

## 6. GEREKLİ RİVE ANİMASYONLARI (tam liste)

**Mimari:** 4 **idle** (mood başına, sürekli döngü) + 12 **reaksiyon** (emotion
başına, tek-atış) + 5 **mikro-katman** (her zaman çalışan jest). Bu, koddaki
`PetMood` (4) ve `PetEmotion` (12) ile **birebir** eşleşir.

### 6.1 Idle döngüleri (mood — sürekli loop)
| # | mood | Duygusal hedef | Süre | Tetik | Loop | Geçiş |
|---|---|---|---|---|---|---|
| 0 | `joyful` | Neşeli, enerjik nefes; ara sıra kuyruk kıpırtısı | 3–4 sn | `mood=0` | ✅ | Diğer idle'a yumuşak blend (~0.3sn) |
| 1 | `content` | Huzurlu, dengeli nefes; sakin bakış | 4–5 sn | `mood=1` | ✅ | Yumuşak blend |
| 2 | `wistful` | Dalgın, yavaş; ara sıra etrafı süzme | 5–6 sn | `mood=2` | ✅ | Yumuşak blend |
| 3 | `low` | Yavaş, yumuşak; **asla acı dolu değil** — sadece sakin/yorgun | 5–6 sn | `mood=3` | ✅ | Yumuşak blend |

### 6.2 Reaksiyonlar (emotion — tek-atış, <2 sn, sonra mevcut mood idle'ına dön)
| idx | emotion | mood ailesi | Duygusal hedef | Süre | Tetik | Loop | Geçiş |
|---|---|---|---|---|---|---|---|
| 0 | happy | joyful | Sıcak gülümseme + küçük zıplama | 1.2 sn | reaksiyon param | ❌ | →idle(mood) |
| 1 | excited | joyful | Coşkulu sıçrama + kuyruk hızlı | 1.5 sn | care/play | ❌ | →idle |
| 2 | playful | joyful | Oyuncu çömelme ("oyna benimle") | 1.6 sn | Play verb | ❌ | →idle |
| 3 | affectionate | joyful | Başını sürtme/kalp gözler | 1.5 sn | petting | ❌ | →idle |
| 4 | content | content | Tatminkâr göz kırpma + iç çekiş | 1.0 sn | beslenme sonrası | ❌ | →idle |
| 5 | proud | content | Gururlu duruş + küçük göğüs | 1.4 sn | milestone | ❌ | →idle |
| 6 | calm | content | Yumuşak esneme, sakinlik | 1.6 sn | ambient | ❌ | →idle |
| 7 | sleepy | wistful | Esneme + göz ağırlaşması | 1.8 sn | gece/ambient | ❌ | →idle |
| 8 | curious | wistful | Kafa eğme + kulak dikme | 1.2 sn | yeni içerik | ❌ | →idle |
| 9 | lonely | wistful | **Nazik** özlem bakışı (asla ağlama/dram) | 1.6 sn | uzun yokluk | ❌ | →idle |
| 10 | hungry | low | **Sevimli** karın işareti (asla acı) | 1.4 sn | açlık metre | ❌ | →idle |
| 11 | comforted | low | Rahatlama, güven nefesi | 1.5 sn | comfort/temizlik | ❌ | →idle |

### 6.3 Her zaman çalışan mikro-katman jestleri (idle/reaksiyon üzerine biner)
| Jest | Hedef | Süre | Tetik | Loop |
|---|---|---|---|---|
| **blink (göz kırpma)** | Canlılık | 0.15 sn | her 3–6 sn rastgele-deterministik | döngüsel |
| **tail wag (kuyruk sallama)** | Mutluluk sinyali | 0.6 sn | joyful idle + happy/excited | döngüsel |
| **breathe (nefes)** | Yaşıyor hissi | idle süresi | her idle'ın tabanı | ✅ |
| **ear twitch (kulak oynatma)** | Dikkat/sevimlilik | 0.3 sn | curious + rastgele | tek-atış |
| **purr/sigh (mırlama/iç çekiş)** | Huzur | 1.0 sn | content/comforted | tek-atış |

### 6.4 Etkileşim-özel kısa animasyonlar (verb reaksiyonları — §7 ile eşleşir)
- **eating (yeme)** — Feed: küçük ısırık + tatmin (≈1.5 sn) → `content`.
- **bath/clean (yıkanma)** — Clean: köpük + silkelenme + ferahlama (≈1.8 sn) → `comforted`.
- **playing (oynama)** — Play: top/ip ile oyun (≈1.6 sn) → `playful/excited`.
- **petting (sevme)** — dokunma: başını yaslama (≈1.2 sn) → `affectionate`.
- **celebration (kutlama)** — milestone: konfeti + zıplama (≈2.0 sn) → `proud`.
- **gift (hediye)** — ödül: kutu açma sevinci (≈1.6 sn) → `excited`.
- **stretch/yawn (gerinme/esneme)** — ambient/uyku öncesi (≈1.8 sn) → `sleepy`.
- **greeting (selamlama)** — uygulama açılışı: "geldin!" sevinci (≈1.4 sn).

> Tüm bu özel animasyonlar **mevcut 12 emotion reaksiyonunun tetiklenmiş
> kullanımıdır** — yeni state değil, mevcut state'lerin oyun tarafından sürülmesi
> (maliyet kaldıracı). Yeni *art* gerekmez.

---

## 7. ETKİLEŞİM TASARIMI (My Talking Tom ilhamı — ama nazik)

**Mutlak kural: HİÇBİR şiddet yok. Vurma yok. Ceza yok. Her etkileşim sıcak ve
çocuk-güvenli.** Talking Tom'un "yaramaz komedisi" ilham; ama KindredPaws'ta
komedi **şefkatli**, asla pet'i aşağılamaz/incitmez.

| Etkileşim | Girdi | Pet tepkisi | Duygu |
|---|---|---|---|
| **Petting (okşama)** | Pet üstünde yumuşak sürükleme | Başını ele yaslar, kalp gözler, mırlar | affectionate |
| **Tapping (dokunma)** | Tek dokunuş | Sana döner, göz kırpar, küçük "selam" | happy/curious |
| **Affection (sevgi)** | Uzun basılı tutma | Derin rahatlama, güven nefesi | comforted |
| **Playful boop (burun dürtme)** | Buruna dokunma | Sevimli irkilme + oyuncu çömelme | playful |
| **Gentle comedic rejection** | Çok hızlı/çok sık dokunma | **Nazik** "yeter biraz 😄" — başını çevirir, küçük somurtma, sonra GÜLER (asla kızgın/üzgün değil) | content (oyuncu) |
| **Playful "bonk"** | Hafif, sevecen kafa-dokunuşu (selamlaşma jesti) | **Şaşkın sevimli pırıltılar** (çarpma/sersemleme DEĞİL — neşeli bir irkilme + parıltı), hemen güler — **asla acı, asla düşme/incinme, asla darbe iması** | happy |

**Reddetme/bonk felsefesi:** Komedi **pet'in sevimliliğini artırır**, onu kurban
yapmaz. "Bonk" = pamuk-yumuşak, çizgi-film yıldızı, anında neşeli toparlanma.
Şüphede kalırsan: **daha nazik** tarafı seç.

**Dokunsal/işitsel:** Her etkileşim yumuşak haptik + sıcak ses (mırlama, mutlu
ufak ses); asla yüksek/ürkütücü ses.

---

## 8. RIVE STATE MACHINE SPESİFİKASYONU (kesin)

> Bu, `docs/RIVE_CONTRACTOR_HANDOFF.md` ile **birebir** aynıdır ve koddaki
> `riveMoodValue` / `riveLifeStageValue` / `riveEmotionValue` eşlemesiyle uyumludur.
> Sapma = runtime kırılması.

**State Machine adı:** `PetStateMachine` (tek SM).

**Girdiler (3 adet, NUMBER):**
| Girdi | Tip | Aralık | Sürdüğü |
|---|---|---|---|
| `mood` | NUMBER | `0.0 … 3.0` | Aktif idle döngüsü (0 joyful, 1 content, 2 wistful, 3 low) |
| `lifeStage` | NUMBER | `0.0 … 2.0` | Oran/doku (0 pupKit, 1 youngOne, 2 grown) |
| `emotion` | NUMBER | `0.0 … 11.0` | Tek-atış reaksiyon (§6.2 indeksleri) |

**Durumlar:**
- **4 idle durumu** — her `mood` değeri için bir tane. Sürekli loop, yumuşak
  nefes/ambient. `mood` değişince hedef idle'a **~0.3 sn blend**.
- **12 reaksiyon durumu** — her `emotion` değeri için bir tane. **Tek-atış, ≤ 2.0 sn**,
  bitince **mevcut `mood`'un idle'ına** döner.
- `lifeStage` ayrı bir durum değildir; tüm durumların üstüne oran/ölçek blendi
  uygular (3 hedef poz). **ZORUNLU:** yaş **kemik-ölçeği interpolasyonu** ile
  yapılır (ucuz), **yaş başına ayrı mesh yeniden-çizimi DEĞİL** (pahalı) — boyut
  bütçesini bu kararla korur.

**Geçiş kuralları:**
- `emotion` bir değere ayarlanınca → ilgili reaksiyon **bir kez** oynar → biter →
  `mood`'a karşılık gelen idle'a döner. (Oyun, reaksiyonu tetikleyip param'ı
  "nötr"e çeker; tekrar tetik = tekrar oynat.)
- `mood` değişimi → yalnızca idle'lar arası blend (reaksiyonu kesmez; reaksiyon
  bitince yeni mood idle'ı gelir).
- `low` mood + `lonely`/`hungry` reaksiyonları **görsel olarak nazik** kalır
  (çocuk-güvenli imza; QA bunu kontrol eder).

**Performans bütçesi:**
- Sürekli **~60 fps**, orta-segment Android (tam mood × emotion taraması).
- `.riv` < **400 KB**; kemik sayısı makul; mesh düğümleri optimize.
- Reaksiyonlar ≤ 2.0 sn; idle'lar 3–6 sn.

**Kabul kriterleri (üretim sonu):**
- [ ] `mood` 0→3 idle'ı değiştirir.
- [ ] `emotion` 0→11 her biri ayrı reaksiyon oynatıp idle'a döner.
- [ ] `lifeStage` 0→2 oran/doku değiştirir.
- [ ] 60 fps korunur; `.riv` < 400 KB.
- [ ] Hiçbir durum/animasyon korkutucu, şiddetli veya üzücü değil (çocuk-güvenli).
- [ ] Puppy ve Kitten **aynı SM arayüzünü** paylaşır (oyun kodu tek seam kullanır).

---

## 9. ÖZET KONTROL LİSTESİ (yeni karakter "bitti" tanımı)
1. Görsel kimlik §2'ye uyar (oran/göz/pati/kulak/kuyruk/silüet, sıcak palet).
2. 3 yaş kademesi (`lifeStage`) çalışır.
3. 4 idle + 12 reaksiyon + mikro-jestler tam.
4. State machine §8 kontratına birebir uyar; cihazda 60fps / <400KB.
5. Tüm etkileşimler §7 — nazik, çocuk-güvenli, şiddetsiz.
6. Tüm dış asset lisansları `assets/CREDITS.md`'de; yalnızca ticari-uygun.
7. Flutter seam'i gerçek `.riv`'i sürer; golden testleri yeşil.

*Bu rehberi izleyen herhangi bir sanatçı/AI, KindredPaws'ın puppy ve kitten
karakterlerini — ve gelecekteki kozmetik varyantlarını — sıfırdan, tutarlı,
çocuk-güvenli ve maliyet-verimli şekilde üretebilir.*
