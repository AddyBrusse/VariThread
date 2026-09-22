# Analyse van de Sandvik-draadprogramma's

Alles hieronder is afgeleid uit programma's die op de machine gedraaid hebben:

| bron | draad | spoed | lengte | snedes | oscillatie |
|---|---|---|---|---|---|
| `reference/sandvik-M48x5-normal.mpf` | M48 | 5 | 58 | 16 + rechte snede | NORMAL |
| M64-export (schermafdrukken) | M64 | 6 | 54 | 18 + rechte snede | FINE |
| M64-export (schermafdrukken) | M64 | 6 | 54 | 18 + rechte snede | COARSE |
| `reference/fusion-1001-debug.mpf` | — | 6 | 54 | 5 | — (Fusion zelf) |

De FINE- en COARSE-export zijn hetzelfde werkstuk met alleen de
oscillatie-instelling anders. Dat bleek de sleutel: alle X- en Z-waarden van de
snedes zijn tussen die twee identiek, dus de frequentie raakt uitsluitend de
knoopafstand.

---

## Vaststaand

### Referentiediameter

De oscillatie van snede 1 trekt terug naar **nominaal + 0,1 mm** op diameter
(M48 → Ø48,1; M64 → Ø64,1). Alle snijdieptes worden vanaf dáár gemeten, niet
vanaf de nominale diameter:

```
X_diep(n) = D_start − 2 × AP_n          D_start = D_nominaal + 0,1
AP_totaal = profieldiepte + 0,05
```

Getoetst op zes snedes van de M64 tegen de AP-tabel van de app: zes van de zes exact.

### Zdisp — de Z-verschuiving per snede

Bij flank-infeed moet de beitel per snede verder naar +Z beginnen, zodat hij op
één flank blijft snijden:

```
Zdisp(n) = (AP_n − AP_1) × tan 29°
Z_start(n) = 2 × spoed − Zdisp(n)
```

Getoetst op alle 18 snedes van de M64 en 15 van de M48. De 29° is de standaard
*modified flank infeed* hoek voor 60°-draad (30° min 1° vrijloop).

De aanloop van 2 × spoed klopt in de M64 (12 mm bij spoed 6) en in de M48 vanaf
snede 2 (10 mm bij spoed 5). Snede 1 van de M48 begint op Z5 — dat is de
aanzethoogte van dat programma, die daar korter was dan de aanloop.

### Knoopafstand

| | oneven snede | even snede |
|---|---|---|
| FINE | 1 × spoed | 0,5 × spoed |
| NORMAL | 2 × spoed | 1 × spoed |
| COARSE | 3 × spoed | 1,5 × spoed |

Even is altijd de helft van oneven; de instelling is een factor 1 / 2 / 3.

### Eindknoop-regel

Knopen liggen op `−j × afstand`; even `j` is diep, oneven `j` is ondiep. Het
eindpunt op `−L` moet diep zijn. Is de laatste tussenknoop even, dan vervalt hij
en wordt het laatste segment navenant langer.

Getoetst op alle zes combinaties van lengte en afstand in de drie programma's.

### Amplitude van de oscillatie

**Oneven snede** — pendelt terug naar exact de diepte van de vorige snede.
Snede 3 → de X van snede 2, snede 5 → de X van snede 4, enzovoort. Snede 1
pendelt naar `D_start`, wat dezelfde regel is met AP₀ = 0.

**Even snede** — gaat daar nog een halve volgende stap bovenuit:

```
AP_ondiep(n) = AP_(n−1) − ½ × (AP_(n+1) − AP_n)
```

Vier van de vier exact op de M64.

**Tussenliggende diepe knopen** van een even snede liggen 0,02 mm op diameter
ondieper dan de knopen aan de uiteinden. Systematisch in alle drie de
programma's. Waarom dat zo is, weet ik niet.

### Het eindpatroon van een even snede

De laatste twee ondiepe toppen wijken af. Dat het echt om *de laatste twee
toppen* gaat en niet om vaste Z-posities, bleek uit FINE vs COARSE: andere
posities (−45/−51 tegen −27/−45), identieke waarden.

```
voorlaatste top = S + d
laatste top     = S − 2d       met d = ½ × (AP_(n−1) − AP_(n−2)) op diameter
```

Acht van de acht exact op de M64, AP₀ = 0 meegerekend.

In de M48 is de draadlengte 58 géén veelvoud van de knoopafstand 5. Daar is er
maar **één** afwijkende top, met deviatie `−d/2`. Zeven van de zeven exact.

De post schakelt tussen die twee takken op de vraag of de lengte een geheel
aantal knoopafstanden is. Dat is de meest waarschijnlijke verklaring, maar met
drie programma's kan ik niet uitsluiten dat er iets anders achter zit.

### De staart van de snedereeks

De laatste stappen zijn vaste minimumstappen van 0,005 mm radiaal (0,01 op
diameter):

| | M48 | M64 |
|---|---|---|
| aantal snedes N | 16 | 18 |
| AP bij snede N−1 | 3,09 | 3,69 |
| AP bij snede N | 3,095 | 3,695 |
| rechte snede | 3,10 | 3,70 |

Snede N en de rechte snede oscilleren niet — één enkele `G33` over de hele
lengte. In beide programma's gelijk.

### De diepteverdeling

Deze is **niet** als formule bekend, maar wel als dimensieloze curve. Normaliseer
`AP_n / AP_(N−1)` tegen `n / (N−1)` en de M48 en de M64 vallen op elkaar:

| n/(N−1) | M48 | M64 |
|---|---|---|
| 0,0625 / 0,0588 | 0,0942 | 0,0946 * |
| 0,2667 | 0,3592 | 0,3596 * |
| 0,5333 | 0,6602 | 0,6623 * |
| 0,6667 | 0,7864 | 0,7886 * |
| 0,8000 | 0,8932 | 0,8933 * |

\* geïnterpoleerd tussen de M64-punten

Twee verschillende draden, verschillende spoed, diameter, aantal snedes en
oscillatie — dezelfde vorm, binnen 0,002. De post gebruikt de zeventien
M64-punten als tabel met lineaire interpolatie.

Een parabool `AP_n = 0,314·n − 0,005·n²` past op de M64 tot snede 12 binnen
0,01, maar loopt op de M48 weg. De tabel is beter.

---

## Nauwkeurigheid

`npm test` reproduceert het volledige M48-programma uit de curve:

| | afwijking |
|---|---|
| aantal snedes en knopen | exact |
| Z-positie van elke knoop | exact |
| Zdisp per snede | ≤ 0,006 mm |
| snijdiepte (diepe knopen) | ≤ 0,019 mm op diameter |
| oscillatie-terugtrekking | ≤ 0,053 mm op diameter |
| einddiepte | exact |

De grootste afwijking zit op een terugtrekpunt in het laatste derde deel. Dat is
geen snijdend vlak — de oscillatie breekt daar spaan.

Voeden we de kern met de *exacte* AP-waarden uit het programma in plaats van met
de curve, dan zakt de grootste afwijking naar 0,031 mm. De rest is curvefout.

---

## Niet bekend

- **De formule achter de diepteverdeling.** De tabel werkt, maar is opgemeten bij
  15 en 17 vormsnedes. Bij een sterk afwijkend aantal wordt er buiten dat bereik
  geïnterpoleerd. Twee extra exports met hetzelfde draad en bijvoorbeeld 10 en 24
  snedes zouden dit sluiten.
- **Waarom de tussenliggende diepe knopen 0,02 mm ondieper liggen.**
- **Waarom het eindpatroon anders is als de lengte niet rond past.** Eén export
  met een niet-passende lengte op FINE of COARSE zou het bevestigen.
- **De vrijloopdiameter.** Sandvik trekt terug naar Ø55,909 (M48) en Ø73,478
  (M64) — geen van mijn kandidaat-formules kwam er exact uit. De post gebruikt
  daarom de vrijloop die Fusion zelf berekent.

---

## Wat Fusion zelf aanlevert

Uit `reference/fusion-1001-debug.mpf`:

| parameter | waarde | gebruik |
|---|---|---|
| `operation:threadPitch` | 6 | spoed |
| `operation:threadDepth` | 1 | profieldiepte |
| `operation:frontHeight_value/_offset` | 5 / 5 | draadbegin = 0 |
| `operation:backHeight_value/_offset` | −54,5 / 0,5 | draadeinde = −54 |
| `operation:numberOfStepdowns` | 5 | aantal snedes als optie 12 = 0 |

**Let op:** `operation:threadInfoMajorDiameter` is **0** zodra
`threadDefinition = "manual"`. De uitgecommentarieerde Vc-omrekening in de
originele post (rond regel 3994) zou daarop door nul delen. De post leidt de
diameter daarom af uit de diepste snede die Fusion aanlevert plus de draaddiepte.

De post schrijft het toerental als `S4=` via `getSpindleCode()`, niet als `S`.
