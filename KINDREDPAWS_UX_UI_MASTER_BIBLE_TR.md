# KINDREDPAWS — UX/UI ANA REHBERİ (MASTER BIBLE)

> **Amaç:** KindredPaws'ın **kalıcı görsel ve duygusal arayüz kimliğini** sıfırdan
> tanımlar. Mevcut arayüz (beyaz arka plan + ilerleme çubuğu + çember + 3 buton)
> **terk edilmiştir.** Bu rehber, her ekranı ve her etkileşimi bir tasarımcı/AI'nin
> uygulayabileceği netlikte verir. SSOT: `KINDREDPAWS_CANONICAL_DECISION_BRIEF.md`,
> `current_state.json`. Görseller: `KINDREDPAWS_GPT_IMAGE_PROMPT_LIBRARY_TR.md`.

**Duygusal kimlik:** "minik bir canlıyı kurtardım, sevgiyle büyüttüm, ona bağlandım."
Çekirdek duygular: bağlanma, şefkat, huzur, gurur, anlamlılık. **Asla** suçluluk/baskı.

---

## 0. Tasarım felsefesi + referanslar

| Referans | KindredPaws ne alır | Ne almaz |
|---|---|---|
| **My Talking Tom** | Pet sahnede yaşar; doğrudan dokunsal etkileşim; net ifade | Yaramaz/komik ton; reklam-yoğun his; sert UI |
| **Finch** | Sıcak, sakin renk; nazik dil; refah hissi; baskısız | — |
| **Animal Crossing** | Cozy, yumuşak, "kendi köşen"; el yapımı doku; mevsim hissi | Karmaşık menü derinliği |

**Özgün kimlik:** *Cozy companion* — pet senin **küçük, sıcak dünyanda yaşar**.
Beyaz/steril değil; **sıcak, dokulu, yaşayan** bir sahne. Sayı-hafif (§5.5),
geri bildirim her zaman sıcak.

### 0.1 Tasarım ilkeleri
1. **Sahne her şeydir.** Beyaz boşluk yok — pet her zaman bir **cozy ortamda**.
2. **Pet öznedir.** Arayüz pet'i çevreler, gölgelemez. Düşük-kontrast UI, yumuşak.
3. **Sıcaklık > verimlilik.** Mikro-animasyon, yumuşak geçiş, nazik dil.
4. **Sayı-hafif.** Çubuk/yüzde minimal; durum **görsel** anlatılır (pet hali, ışık).
5. **Asla suçlandırma.** Boş metre "açsın!" demez; "biraz atıştırabilir 🍎" der.
6. **Çocuk-güvenli + erişilebilir.** Büyük dokunma hedefleri, semantics etiketleri,
   renge tek-başına dayanmayan durum.

### 0.2 Görsel dil
- **Renk:** sıcak pastel zemin (krem/şeftali), yumuşak mavi-gri vurgu
  (`seedColor 0xFF6C8EAD` koddaki tema ile uyumlu), doğa-yeşili aksanlar.
- **Köşeler:** büyük yuvarlatma (16–28 px); kart ve buton "yastık" gibi.
- **Gölge:** yumuşak, düşük; "kâğıt/pelüş" hissi.
- **Tipografi:** yuvarlak hatlı, sıcak, okunabilir (Nunito/Quicksand benzeri).
- **İkonografi:** dolgun, yuvarlatılmış; asla keskin/teknik.
- **Hareket:** her geçiş 200–350 ms ease; "spring" hissi; ani kesme yok.

---

## 1. ANA EKRAN (Home / Companion Home)

> Oyuncunun %90 zamanını geçirdiği yer. Pet **animasyonlu bir sahnede yaşar**.

### 1.1 Katmanlar (arkadan öne)
1. **Animasyonlu arka plan (sahne).** Seçilebilir/zamana göre değişen cozy ortam:
   - **cozy room (sıcak oda)** — varsayılan; pencereden yumuşak ışık, halı, yastık.
   - **rainy window (yağmurlu pencere)** — sakin, melankolik-sıcak; cam damlaları.
   - **garden (bahçe)** — gündüz, yeşil, kelebek/yaprak parıltısı.
   - **campsite (kamp)** — akşam, ateş ışığı, yıldızlar.
   Sahne **hafif canlı**: ışık titreşimi, yaprak/damla parçacıkları (düşük maliyet,
   parallax). Gündüz/gece döngüsü cihaz saatine göre yumuşak ton değiştirir.
2. **Orta plan: pet.** Rive karakteri sahnenin "yaşam noktasında" (yastık/çim).
   Pet idle döngüsünde nefes alır; dokunmaya tepki verir (§1.4). **Çember YOK** —
   pet doğrudan sahnede durur, sevimli bir gölge ile zemine oturur.
3. **Üst bilgi (hafif, saydam):** sol — pet adı; sağ — Kibble (🦴) + küçük Bond
   kalbi. **İnce, sayı-hafif**; metre çubuğu yerine **pet'in hali** durumu anlatır.
4. **Konuşma balonu:** pet bir şey "söyleyince" (Heartmind) yumuşak balon belirir,
   3–4 sn sonra solar. Asla ekranı kaplamaz.
5. **Alt eylem çubuğu:** 3 birincil **bakım verb'i** — **Feed (🍎/kase) · Clean
   (🫧/su) · Play (🎾)** — büyük, yumuşak, etiketsiz değil etiketli; basınca pet
   ilgili reaksiyonu oynatır.
6. **Yan navigasyon (side nav):** kenardan çekme veya köşe sekmesi ile açılan
   yumuşak panel: **Wardrobe (Gardırop) · Keepsakes (Anılar) · Memory Book (Anı
   Defteri) · Shop (Dükkân) · Settings (Ayarlar)**. (Premium, Shop içinden ve
   ayrı bir kalp ikonundan erişilir.)

### 1.2 Bond (Bağ) göstergesi
- 5 kademe: **Stranger → Friend → Companion → Kindred → Soulmate** (kanonik).
  *Not: "Soulmate" platonik "can yoldaşı" anlamındadır — romantik değil, çocuk-
  güvenli (§0).* Görsel: küçük kalp + kademe adı + ince ilerleme; **baskısız**.

### 1.3 Bakım metreleri (Care Meters)
- Üç ihtiyaç (tokluk/temizlik/oyun) **görsel** anlatılır: pet'in hali + sahnedeki
  küçük ipuçları (ör. yanına gelmiş kase). Çubuk minimal/gizli; "kritik" durum
  **asla alarm/kırmızı-panik** değil — yumuşak davet ("biraz atıştırabilir 🍎").
- **No-death floor:** pet asla "ölmez"/ceza görmez; ihmal sadece "özlemiş" haliyle
  gösterilir, suçlama yok.

### 1.4 Ana ekran etkileşimleri (her biri)
| Etkileşim | Tepki |
|---|---|
| **Pet'e dokun** | Sana döner, göz kırpar, küçük "selam" (happy/curious reaksiyon) |
| **Pet'i okşa (sürükle)** | Başını yaslar, kalp gözler, mırlar (affectionate) |
| **Buruna boop** | Sevimli irkilme + oyuncu çömelme (playful) |
| **Çok hızlı dokunma** | Nazik komik "yeter 😄" + güler (asla kızgın) |
| **Feed** | Kase animasyonu → pet yer → `content`; Kibble harcanır; sıcak mesaj |
| **Clean** | Köpük + silkelenme → `comforted`; "mis gibi oldun!" |
| **Play** | Top/ip oyunu → `playful/excited`; Bond artışı; "harika vakit!" |
| **Yan nav aç** | Panel yumuşak kayar; sahne hafif bulanır (pet görünür kalır) |
| **Uygulamayı aç** | Selamlama animasyonu + sıcak karşılama balonu |

---

## 2. EK EKRANLAR (layout açıklamalı)

> Genel: her ekran cozy zemin + büyük yuvarlak kartlar + yumuşak geçiş. Üstte
> küçük geri/başlık; pet mümkünse köşede minik eşlik eder.

### 2.1 Onboarding (Karşılama / Rescue Day)
- **Amaç:** duygusal kanca — "minik bir canlı sana ihtiyaç duyuyor."
- **Layout:** tam ekran sahne (yağmurlu, **loş ama asla ürkütücü** — yakında her
  zaman küçük bir sıcak ışık vardır). Merkezde nazik anlatı metni (3 "beat":
  *"Soğuk, yağmurlu bir akşam." → "Bir saçağın altına kıvrılmış minik bir şekil,
  seni bekliyor." → "Yardım eder misin?"*). **Çocuk-güvenli not:** "karanlık =
  tehdit" çerçevesinden kaçın; his "yalnız ve korkmuş" değil, "güvende ama bir
  dosta hazır" olmalı. Altta tek büyük buton: **"Reach out (Elini uzat)"**.
  Minimal, duygusal, baskısız. İlerledikçe ışık ısınır.

### 2.2 Adoption (Sahiplenme / Tür + İsim)
- **Tür seçimi:** "Will you give it a forever home?" — iki büyük kart: **Puppy
  (🐶 Biscuit) · Kitten (🐱 Mochi)**. Seçince kart yumuşak büyür, pet ısınan
  ışıkla belirir.
- **İsim:** "What will you name your new friend?" — ön-dolu varsayılan ad + metin
  alanı (max 16, filtreli) + büyük **"Welcome home 💛"** butonu. Onay → ilk
  selamlama + ana ekrana sıcak geçiş. (Bildirim izni burada, bağlam içinde istenir.)

### 2.3 Wardrobe (Gardırop / Kozmetik)
- **Amaç:** pet'i süsle (kozmetik, **pay-to-win değil**).
- **Layout:** üstte canlı pet önizlemesi (giydirilen anında görünür); altta
  kategorili grid (şapka, tasma, aksesuar, kürk-deseni). Sahip olunanlar etkin;
  kilitliler "Shop"a yumuşak yönlendirir. **Asla baskı**; "ister misin?" tonu.

### 2.4 Bathroom (Banyo / Temizlik)
- **Amaç:** Clean verb'inin zengin hali.
- **Layout:** küvet sahnesi; köpük + su sesi; oyuncu pet'i ovuşturur (sürükleme).
  Tamamlanınca silkelenme + `comforted` + parıltı. Neşeli, oyuncu; asla "kirliydin!"
  suçlaması — "hadi ferahlayalım 🫧".

### 2.5 Memory Book (Anı Defteri)
- **Amaç:** "pet seni hatırlıyor" — en güçlü bağ kaldıracı.
- **Layout:** kitap/albüm metaforu; kategorilere göre (paylaşılan anlar, kilometre
  taşları, alışkanlıklar) sıcak kartlar. Her anı: küçük illüstrasyon + bir cümle.
  Pet bazen bir anıyı "hatırlayıp" gülümser. Sayfa çevirme yumuşak animasyon.

### 2.6 Keepsakes (Hatıralar / Kartlar)
- **Amaç:** paylaşılabilir duygusal kartlar (virallik).
- **Layout:** grid; her keepsake güzel bir kart (Rescue Day, ilk milestone…).
  Karta dokun → büyür → **Paylaş** butonu (sıcak, baskısız). İlk kart sahiplenmede
  otomatik oluşur.

### 2.7 Shop (Dükkân)
- **Amaç:** kozmetik + Kibble/Heartstone; **etik**, baskısız.
- **Layout:** kategorili, sakin grid (kozmetikler, para paketleri, Rescue Bundle).
  Fiyatlar net; **Rescue Bundle**'da bağış payı şeffaf gösterilir. Hiçbir FOMO/geri
  sayım/gacha yok. "Forever Friends" premium girişi buradan da erişilir.

### 2.8 Premium (Forever Friends paywall)
- **Amaç:** tek abonelik tier'i, **etik**.
- **Layout:** sıcak başlık + iki KİLİTLİ plan (aylık $5.99 / yıllık $39.99 ·
  "Save 44%"); kozmetik/QoL fayda listesi; **etik duvar notu** ("yalnızca kozmetik
  & sıcaklık — asla avantaj; iptal pet'ini asla etkilemez 💛"); Heartstone + Rescue
  Bundle. Sahipse: teşekkür durumu (nag yok). "Restore purchases" linki. Sonuç
  **sayfa-içi canlı bölgede** duyurulur (a11y).

### 2.9 Settings (Ayarlar)
- **Layout:** sade liste: **bildirimler** (aç/kapa + sıklık), ses/haptik, hesap
  (giriş/geri yükleme), gizlilik + **veri silme** (right-to-be-forgotten), yaş/uyumluluk,
  diagnostics export (beta), hakkında/krediler. Sıcak ama net.

### 2.10 Profile (Profil)
- **Layout:** pet portresi + ad + tür + yaş kademesi; **Bond** kademesi + ilerleme;
  **birlikte yapılan iyilik** (Compassion Coins / bağış etkisi — şeffaf, gurur
  verici); birliktelik süresi ("Gotcha Day"); öne çıkan keepsake. Anlam + gurur
  ekranı.

---

## 3. NAVİGASYON HARİTASI

```
Onboarding → Adoption → [ANA EKRAN]
                              ├─ Feed / Clean / Play (yerinde reaksiyon)
                              └─ Yan Nav:
                                   ├─ Wardrobe → (Shop'a kozmetik linki)
                                   ├─ Keepsakes → Paylaş
                                   ├─ Memory Book
                                   ├─ Shop → Premium (Forever Friends)
                                   └─ Settings
                              └─ Profil (üst bilgi / pet adına dokun)
                              └─ Bathroom (Clean'in zengin hali)
```

---

## 4. ETKİLEŞİM & HAREKET KURALLARI (global)
- **Geçişler:** 200–350 ms, ease-out; ekranlar yumuşak kayar/solar; pet süreklilik
  hissi için köşede eşlik eder.
- **Geri bildirim:** her dokunuş yumuşak haptik + mikro-animasyon + sıcak ses.
- **Boş/yükleniyor durumları:** asla boş beyaz; sıcak illüstrasyon + nazik cümle
  ("Biscuit bir saniye geriniyor… 🐾").
- **Hata durumları:** sakin, suçlamasız ("bir şey ters gitti — ücret alınmadı,
  tekrar dener misin?").
- **Erişilebilirlik:** ≥48dp dokunma hedefi; `Semantics` etiketleri; durum renge
  tek-başına bağlı değil; canlı-bölge (liveRegion) önemli sonuçlar için.

---

## 5. KOZMETİK/KART/İKON SİSTEMİ (özet)
- **Kartlar:** 16–28px köşe, yumuşak gölge, sıcak zemin; başlık + tek satır + küçük
  illüstrasyon.
- **Butonlar:** dolgun "yastık", büyük dokunma alanı; birincil = sıcak vurgu rengi,
  ikincil = saydam.
- **İkonlar:** dolgun yuvarlak; her zaman metin/etiket eşliğinde (a11y).
- **Empty-state illüstrasyonları:** unDraw/özel, sıcak, asla üzücü.

> Tüm bu ekran ve elemanların görsel üretimi için **birebir GPT/Rive prompt'ları**
> `KINDREDPAWS_GPT_IMAGE_PROMPT_LIBRARY_TR.md`'dedir (dosya adı, yol, boyut,
> şeffaflık dahil).

---

## 6. "BİTTİ" TANIMI (UX)
1. Hiçbir ekranda steril beyaz boşluk yok; pet her zaman cozy sahnede.
2. Ana ekran: animasyonlu arka plan + sahnede yaşayan pet + Feed/Clean/Play + yan nav.
3. 10 ek ekran (§2) layout'a uygun, sıcak, sayı-hafif.
4. Her etkileşim belgelenmiş, nazik, çocuk-güvenli, suçlamasız.
5. Hareket/geçiş/erişilebilirlik kuralları (§4) uygulanmış.
6. Görsel dil (§0.2) tutarlı; tema kod `seedColor` ile uyumlu.

*Bu rehber, KindredPaws'ın kalıcı arayüz kimliğidir: pet'in senin küçük, sıcak
dünyanda yaşadığı; her dokunuşun şefkatle karşılandığı bir cozy companion deneyimi.*
