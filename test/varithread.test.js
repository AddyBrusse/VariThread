"use strict";
// Valideert de VariThread-rekenkern tegen de echte, op de machine gedraaide
// programma's. De kern wordt uit de post zelf geknipt, zodat de test bewijst
// dat de post die verstuurd wordt de juiste getallen uitrekent.

var fs = require("fs");
var path = require("path");

var ROOT = path.join(__dirname, "..");
var POST = path.join(ROOT, "post", "DMG_EcoTurn_V4_variThread.cps");
var BEGIN = "// >>> VARITHREAD CORE BEGIN";
var END = "// <<< VARITHREAD CORE END";

var fails = 0;
var checks = 0;

function ok(cond, msg) {
    checks++;
    if (!cond) { fails++; console.log("  FAIL  " + msg); }
}
function near(actual, expected, tol, msg) {
    checks++;
    var d = Math.abs(actual - expected);
    if (!(d <= tol)) {
        fails++;
        console.log("  FAIL  " + msg + ": " + actual + " vs " + expected + " (delta " + d.toFixed(4) + " > " + tol + ")");
    }
    return d;
}
function section(name) { console.log("\n" + name); }

// --- kern uit de post knippen ----------------------------------------------
var post = fs.readFileSync(POST, "utf8");
var a = post.indexOf(BEGIN);
var b = post.indexOf(END);
if (a < 0 || b < 0) { console.log("kern niet gevonden in " + POST); process.exit(1); }
// Indirecte eval: de kern landt in de globale scope, ook al draait deze test
// in strict mode.
(0, eval)(post.slice(a, b + END.length));
var VariThread = globalThis.VariThread;

// --- referentieprogramma inlezen -------------------------------------------
function readSandvik(file) {
    var passes = [], cur = null;
    fs.readFileSync(path.join(ROOT, "reference", file), "utf8").split(/\r?\n/).forEach(function (line) {
        var l = line.trim(), m;
        if (/^;PASS:\d+$/.test(l) || l === ";ZERO PASS") { cur = { zStart: null, nodes: [] }; passes.push(cur); return; }
        if (!cur) { return; }
        if ((m = /^Z(-?[\d.]+)$/.exec(l))) { if (cur.zStart === null) { cur.zStart = +m[1]; } return; }
        if ((m = /^G33 X([\d.]+) Z(-?[\d.]+) K/.exec(l))) { cur.nodes.push({ x: +m[1], z: +m[2] }); }
    });
    return passes;
}

// ===========================================================================
section("M48x5 NORMAL - volledig programma, regel voor regel");
// ===========================================================================
// Ø48 nominaal, profieldiepte 3.05, 16 snedes + rechte snede, draadlichaam 58 mm.
var ref48 = readSandvik("sandvik-M48x5-normal.mpf");
var got48 = VariThread.buildPasses({
    startDiameter: 48.1, totalDepth: 3.10, pitch: 5, threadLength: 58,
    zThreadStart: 0, numPasses: 16, frequency: "normal",
    extraStraightPass: true, baseRpm: 372, rpmVariationPercent: 0
});

ok(ref48.length === 17, "referentie heeft 17 snedes, gevonden " + ref48.length);
ok(got48.length === ref48.length, "aantal snedes komt overeen (" + got48.length + " vs " + ref48.length + ")");

var worstDeep = 0, worstNode = 0, worstZ = 0, zMismatch = 0, countMismatch = 0;
for (var i = 0; i < Math.min(ref48.length, got48.length); i++) {
    var r = ref48[i], g = got48[i];
    if (r.nodes.length !== g.nodes.length) {
        countMismatch++;
        console.log("  FAIL  snede " + (i + 1) + ": aantal knopen " + g.nodes.length + " vs " + r.nodes.length);
        continue;
    }
    // Snede 1 start in het referentieprogramma op de aanzethoogte Z5 in plaats
    // van op 2xP; alle volgende snedes volgen de formule. Zie docs.
    if (i > 0) { worstZ = Math.max(worstZ, Math.abs(g.zStart - r.zStart)); }
    for (var j = 0; j < r.nodes.length; j++) {
        if (Math.abs(r.nodes[j].z - g.nodes[j].z) > 1e-6) { zMismatch++; }
        var d = Math.abs(r.nodes[j].x - g.nodes[j].x);
        worstNode = Math.max(worstNode, d);
        var isDeep = (j === 0 || j === r.nodes.length - 1);
        if (isDeep) { worstDeep = Math.max(worstDeep, d); }
    }
}
ok(countMismatch === 0, "alle snedes hebben het juiste aantal knopen");
ok(zMismatch === 0, "alle knoop-Z-posities exact gelijk (" + zMismatch + " afwijkingen)");
ok(worstZ <= 0.01, "Zdisp per snede binnen 0.01 mm (max " + worstZ.toFixed(4) + ")");
ok(worstDeep <= 0.02, "snijdiepte binnen 0.02 mm op diameter (max " + worstDeep.toFixed(4) + ")");
ok(worstNode <= 0.06, "oscillatie-terugtrekking binnen 0.06 mm op diameter (max " + worstNode.toFixed(4) + ")");
ok(Math.abs(got48[got48.length - 1].xDeep - 41.9) < 1e-9,
    "einddiameter exact 41.9 (" + got48[got48.length - 1].xDeep + ")");

// ===========================================================================
section("M64x6 - dieptes en Zdisp uit de gemeten programma's");
// ===========================================================================
// Ø64 nominaal, profieldiepte 3.65, 18 snedes + rechte snede, draadlichaam 54 mm.
var AP64 = [0.309, 0.608, 0.899, 1.18, 1.45, 1.71, 1.96, 2.20, 2.43, 2.64,
            2.85, 3.03, 3.20, 3.36, 3.50, 3.61, 3.69, 3.695, 3.70];
var ZSTART64 = [12.0, 11.834, 11.673, 11.517, 11.367, 11.222, 11.083, 10.95,
                10.82, 10.71, 10.59, 10.49, 10.39, 10.31, 10.23, 10.17, 10.13, 10.12, 10.12];

["fine", "coarse"].forEach(function (freq) {
    var got = VariThread.buildPasses({
        startDiameter: 64.1, totalDepth: 3.70, pitch: 6, threadLength: 54,
        zThreadStart: 0, numPasses: 18, frequency: freq,
        extraStraightPass: true, baseRpm: 403, rpmVariationPercent: 0
    });
    ok(got.length === 19, freq + ": 19 snedes (" + got.length + ")");
    var wAp = 0, wZ = 0;
    for (var n = 0; n < Math.min(got.length, AP64.length); n++) {
        wAp = Math.max(wAp, Math.abs(got[n].ap - AP64[n]));
        // Zdisp is met 2 decimalen uit het programma gelezen.
        wZ = Math.max(wZ, Math.abs(got[n].zStart - ZSTART64[n]));
    }
    ok(wAp <= 0.011, freq + ": snijdiepte binnen 0.011 mm radiaal (max " + wAp.toFixed(4) + ")");
    ok(wZ <= 0.011, freq + ": Zdisp binnen 0.011 mm (max " + wZ.toFixed(4) + ")");
});

// ===========================================================================
section("Knoopafstand per frequentie");
// ===========================================================================
// Oneven snede = factor x spoed, even snede de helft daarvan.
// fine 1x, normal 2x, coarse 3x - gemeten in M64 (fine, coarse) en M48 (normal).
[["fine", 6, 3], ["normal", 12, 6], ["coarse", 18, 9]].forEach(function (t) {
    ok(VariThread.nodeSpacing(6, t[0], 1) === t[1], t[0] + ": oneven snede " + t[1] + " mm bij spoed 6");
    ok(VariThread.nodeSpacing(6, t[0], 2) === t[2], t[0] + ": even snede " + t[2] + " mm bij spoed 6");
});
ok(VariThread.nodeSpacing(5, "normal", 1) === 10, "normal bij spoed 5: oneven 10 mm");
ok(VariThread.nodeSpacing(5, "normal", 2) === 5, "normal bij spoed 5: even 5 mm");

// ===========================================================================
section("Eindknoop-regel op alle zes gemeten combinaties");
// ===========================================================================
// Laatste knoop moet diep zijn; een even laatste tussenknoop vervalt.
function offsets(L, s) { return VariThread.nodeOffsets(L, s); }
function lastIntermediate(L, s) { var o = offsets(L, s); return o[o.length - 2]; }

ok(lastIntermediate(54, 6) === 42, "M64 fine oneven: laatste tussenknoop op -42 (Z-48 vervalt)");
ok(lastIntermediate(54, 3) === 51, "M64 fine even: laatste tussenknoop op -51");
ok(lastIntermediate(54, 18) === 18, "M64 coarse oneven: laatste tussenknoop op -18 (Z-36 vervalt)");
ok(lastIntermediate(54, 9) === 45, "M64 coarse even: laatste tussenknoop op -45");
ok(lastIntermediate(58, 10) === 50, "M48 normal oneven: laatste tussenknoop op -50");
ok(lastIntermediate(58, 5) === 55, "M48 normal even: laatste tussenknoop op -55");
[[54, 6], [54, 3], [54, 18], [54, 9], [58, 10], [58, 5]].forEach(function (t) {
    var o = offsets(t[0], t[1]);
    ok((o.length - 1) % 2 === 0, "L=" + t[0] + " s=" + t[1] + ": even aantal segmenten, dus eindknoop is diep");
});

// ===========================================================================
section("Toerentalvariatie -5 / 0 / +5 roterend");
// ===========================================================================
var s = VariThread.spindleSpeeds(400, 5, 7);
ok(JSON.stringify(s) === JSON.stringify([380, 400, 420, 380, 400, 420, 380]),
    "patroon -5, 0, +5 roterend: " + s.join(", "));
var s0 = VariThread.spindleSpeeds(400, 0, 4);
ok(JSON.stringify(s0) === JSON.stringify([400, 400, 400, 400]), "0% = geen variatie");
var s3 = VariThread.spindleSpeeds(403, 3, 3);
ok(JSON.stringify(s3) === JSON.stringify([391, 403, 415]), "3% op 403 tpm: " + s3.join(", "));

// ===========================================================================
section("Staartregel van de diepteverdeling");
// ===========================================================================
var d = VariThread.passDepths(3.70, 18, true);
ok(d.length === 19, "18 snedes + rechte snede = 19 dieptes");
near(d[16], 3.69, 1e-9, "snede 17 op einddiepte - 0.01");
near(d[17], 3.695, 1e-9, "snede 18 op einddiepte - 0.005");
near(d[18], 3.70, 1e-9, "rechte snede op einddiepte");
var dn = VariThread.passDepths(3.70, 18, false);
ok(dn.length === 18, "zonder rechte snede 18 dieptes");
near(dn[17], 3.695, 1e-9, "laatste snede zonder rechte snede");

// ===========================================================================
section("Laatste twee snedes oscilleren niet");
// ===========================================================================
var q = VariThread.buildPasses({
    startDiameter: 64.1, totalDepth: 3.70, pitch: 6, threadLength: 54,
    zThreadStart: 0, numPasses: 18, frequency: "fine",
    extraStraightPass: true, baseRpm: 403, rpmVariationPercent: 0
});
ok(q[16].nodes.length > 1, "snede 17 oscilleert (" + q[16].nodes.length + " knopen)");
ok(q[17].nodes.length === 1, "snede 18 is een enkele G33");
ok(q[18].nodes.length === 1, "rechte snede is een enkele G33");
ok(q[18].isZeroPass === true, "laatste snede is gemarkeerd als rechte snede");

console.log("\n" + (fails === 0 ? "OK" : "MISLUKT") + " - " + (checks - fails) + "/" + checks + " controles geslaagd");
process.exit(fails === 0 ? 0 : 1);
