# VariThread

Fusion-post voor draadsnijden op de DMG EcoTurn met **oscillerende flank-infeed**:
de beitel pendelt tijdens elke snede radiaal in en uit, zodat de spaan breekt in
plaats van als één lange sliert mee te lopen.

De post is `post/DMG_EcoTurn_V4_variThread.cps` — de bestaande Siemens Mill-Turn
post met zes extra opties op de draadoperatie. De rest van de post is ongewijzigd;
`post/DMG_EcoTurn_V4.cps` staat ernaast om tegen te diffen.

## Waar dit vandaan komt

De bewegingen zijn nagebouwd uit programma's van de Sandvik CoroPlus-app die op
de machine gedraaid hebben. Die app rekent het uit, maar levert geen post — de
draadinhoud moest met de hand in het Fusion-programma geplakt worden. Deze post
neemt die stap weg.

Hoe de formules zijn afgeleid en wat er wel en niet bewezen is, staat in
[docs/analyse-sandvik-output.md](docs/analyse-sandvik-output.md).

## Opties op de draadoperatie

Alle zes staan onder *Post Processing* van de draadoperatie zelf
(`scope: "operation"`), naast de bestaande broodsopties.

| Optie | Wat het doet |
|---|---|
| **10 - VariThread draadcyclus gebruiken?** | Aan = de post vervangt de snedes van Fusion. Uit = de post gedraagt zich precies zoals voorheen. |
| **11 - Oscillatie frequentie** | Geen / Fijn / Normaal / Grof. Knoopafstand = 1× / 2× / 3× de spoed op oneven snedes, de helft daarvan op even snedes. |
| **12 - Aantal snedes** | 0 = het aantal uit Fusion overnemen. |
| **13 - Extra rechte snede** | Sluit af met een niet-oscillerende snede op einddiepte. |
| **14 - Snijsnelheid m/min** | Wordt omgerekend naar toerental op de draaddiameter. 0 = toerental uit Fusion. |
| **15 - Toerentalvariatie ± %** | Wisselt per snede tussen −%, 0 en +%, roterend. Tegen trillingen. 0 = uit. |

## Wat de post uitrekent

Per snede:

- **snijdiepte** uit een genormaliseerde diepteverdeling, opgemeten uit de
  Sandvik-programma's
- **Zdisp** — de terugtrekking in Z zodat de beitel op één flank blijft snijden:
  `(AP_n − AP_1) × tan 29°`
- **oscillatieknopen** — afwisselend diep en ondiep langs de draad, met de
  eindknoop altijd op diepte
- **toerental** volgens de rotatie −%, 0, +%

## Testen

```
npm test
```

De testen knippen de rekenkern **uit de post zelf** en leggen hem naast het
echte, op de machine gedraaide M48×5-programma: 17 snedes, elke knoop-Z exact,
elke snijdiepte binnen 0,02 mm op diameter. Een tweede test draait het
post-blok tegen een nagebootste Fusion-omgeving, gevoed met de parameters uit
een echte gedebugde export.

Er is geen build-stap en er zijn geen afhankelijkheden: de post is het product.

## Wat je moet weten voor je dit op de machine zet

- **Fusion simuleert dit niet.** De simulatie en de tijdschatting tonen de
  snedes van Fusion, niet die van de post. Dat verschil is inherent: Fusion kent
  deze cyclus niet.
- **Draai het eerst droog.** Er is nog geen programma van deze post op een
  machine gedraaid.
- De diepteverdeling is opgemeten bij 16 en 18 snedes. Zet je optie 12 op 8 of
  op 25, dan wordt er buiten dat bereik geïnterpoleerd — de einddiepte klopt
  altijd, de verdeling ertussen kan van Sandvik afwijken.
