"use strict";
// Draait het VariThread-blok uit de post tegen een nagebootste post-omgeving,
// gevoed met de echte parameters uit reference/fusion-1001-debug.mpf.
// Controleert dat er een uitvoerbaar blok uitkomt en niet alleen dat de
// rekenkern klopt.

var fs = require("fs");
var path = require("path");

var ROOT = path.join(__dirname, "..");
var post = fs.readFileSync(path.join(ROOT, "post", "DMG_EcoTurn_V4_variThread.cps"), "utf8");

function block(beginMark, endMark) {
    var a = post.indexOf(beginMark), b = post.indexOf(endMark);
    if (a < 0 || b < 0) { throw new Error("blok niet gevonden: " + beginMark); }
    return post.slice(a, b + endMark.length);
}

// --- parameters uit het gedebugde Fusion-programma -------------------------
var params = {};
fs.readFileSync(path.join(ROOT, "reference", "fusion-1001-debug.mpf"), "utf8")
    .split(/\r?\n/).forEach(function (line) {
        var m = /^!DEBUG: onParameter\('([^']+)', (.*)\)$/.exec(line.trim());
        if (!m) { return; }
        var raw = m[2];
        params[m[1]] = /^-?[\d.]+$/.test(raw) ? parseFloat(raw) : raw.replace(/^"|"$/g, "");
    });

// --- nagebootste post-omgeving ---------------------------------------------
var out = [];
var g = globalThis;

// scale bootst createFormat({scale: n}) na: xFormat in de post heeft scale 2,
// dus hij krijgt een radius en schrijft een diameter.
function fmt(dec, scale) {
    scale = scale || 1;
    return {
        format: function (v) {
            var s = Number(v * scale).toFixed(dec);
            if (s.indexOf(".") >= 0) { s = s.replace(/0+$/, "").replace(/\.$/, ""); }
            return s;
        },
        getResultingValue: function (v) { return Number(Number(v * scale).toFixed(dec)); }
    };
}
function outputVar(prefix, format) {
    var current = null;
    return {
        format: function (v) {
            var n = Number(Number(v).toFixed(4));
            if (current === n) { return ""; }
            current = n;
            return prefix + format.format(v);
        },
        reset: function () { current = null; }
    };
}

g.xFormat = fmt(3, 2); // diametermodus, net als in de post
g.zFormat = fmt(3);
g.spatialFormat = fmt(3);
g.integerFormat = fmt(0);
g.rpmFormat = fmt(0);
g.xOutput = outputVar("X", g.xFormat);
g.yOutput = outputVar("Y", fmt(3));
g.zOutput = outputVar("Z", g.zFormat);
g.sOutput = outputVar("S", g.rpmFormat);
// Modaal, net als createOutputVariable in de post: een tweede G0 op rij levert
// een lege string op. Zonder dit verbergt de stub ontbrekende G-woorden.
g.gMotionModal = (function () {
    var current = null;
    return {
        format: function (v) { if (current === v) { return ""; } current = v; return "G" + v; },
        reset: function () { current = null; }
    };
})();
g.currentSection = {};
g.spindleSpeed = params["operation:tool_spindleSpeed"];
g.errors = [];
g.error = function (m) { g.errors.push(m); };
g.localize = function (m) { return m; };
g.forceFeed = function () {};
g.getSpindleCode = function () { return 4; };
g.hasParameter = function (n) { return Object.prototype.hasOwnProperty.call(params, n); };
g.getParameter = function (n, d) { return g.hasParameter(n) ? params[n] : d; };
g.writeBlock = function () {
    var words = [];
    for (var i = 0; i < arguments.length; i++) {
        if (arguments[i] !== "" && arguments[i] !== undefined && arguments[i] !== null) { words.push(arguments[i]); }
    }
    if (words.length) { out.push(words.join(" ")); }
};
g.writeComment = function (t) { out.push("; " + t); };

var settings = {
    _11_oscillatie: "fine",
    _12_aantalPassen: 0,
    _13_extraGladdeSnede: true,
    _14_snijsnelheid: 0,
    _15_toerentalVariatie: 5
};
g.properties = {};
Object.keys(settings).forEach(function (k) { g.properties[k] = k; });
g.getProperty = function (key) { return settings[key]; };

(0, eval)(block("// >>> VARITHREAD CORE BEGIN", "// <<< VARITHREAD CORE END"));
(0, eval)(block("// >>> VARITHREAD EMITTER BEGIN", "// <<< VARITHREAD EMITTER END"));

// --- de bewegingen van Fusion opnieuw afspelen -----------------------------
// X is in de post een radius; de rapids en de G33 uit het gedebugde programma.
var fusionMoves = [
    { x: 57.5, z: 3, cut: false },
    { x: 115 / 2, z: 3, cut: false },
    { x: 115 / 2, z: 5, cut: false },
    { x: 63.22 / 2, z: 5, cut: false }, { x: 63.22 / 2, z: -54.5, cut: true },
    { x: 115 / 2, z: -54.5, cut: false },
    { x: 62.82 / 2, z: 5, cut: false }, { x: 62.82 / 2, z: -54.5, cut: true },
    { x: 115 / 2, z: -54.5, cut: false },
    { x: 62.42 / 2, z: 5, cut: false }, { x: 62.42 / 2, z: -54.5, cut: true },
    { x: 115 / 2, z: -54.5, cut: false },
    { x: 62.02 / 2, z: 5, cut: false }, { x: 62.02 / 2, z: -54.5, cut: true },
    { x: 115 / 2, z: -54.5, cut: false },
    { x: 61.62 / 2, z: 5, cut: false }, { x: 61.62 / 2, z: -54.5, cut: true },
    { x: 115 / 2, z: -54.5, cut: false }
];

g.variThread.start();
fusionMoves.forEach(function (m) { g.variThread.record(m.x, 0, m.z, m.cut); });

var geo = g.variThread.geometry();
var fails = 0, checks = 0;
function ok(cond, msg) { checks++; if (!cond) { fails++; console.log("  FAIL  " + msg); } }
function near(a, b, tol, msg) { ok(Math.abs(a - b) <= tol, msg + " (" + a + " vs " + b + ")"); }

console.log("\nGeometrie afgeleid uit de bewegingen van Fusion");
ok(geo !== null, "geometrie kon worden afgeleid");
near(geo.pitch, 6, 1e-9, "spoed 6 uit operation:threadPitch");
near(geo.nominalDiameter, 63.62, 1e-9, "nominale diameter = diepste snede + 2x draaddiepte");
near(geo.startDiameter, 63.72, 1e-9, "startdiameter = nominaal + 0.1");
near(geo.totalDepth, 1.05, 1e-9, "totale diepte = draaddiepte + 0.05");
near(geo.zMotionStart, 5, 1e-9, "Z-begin uit de positionering van Fusion");
near(geo.zEnd, -54.5, 1e-9, "Z-eind uit de snijbeweging van Fusion");
near(geo.frontOffset, 5, 1e-9, "aanloop 5 mm uit frontHeight_offset");
near(geo.retractDiameter, 115, 1e-9, "vrijloopdiameter 115 uit de rapids van Fusion");
ok(geo.fusionPasses === 5, "Fusion leverde 5 snedes aan");

g.variThread.emit();
ok(g.errors.length === 0, "geen fouten gemeld: " + g.errors.join("; "));

var text = out.join("\n");
console.log("\nGegenereerd blok");
var g33 = out.filter(function (l) { return l.indexOf("G33") === 0; });
ok(g33.length > 5, "meer G33-regels dan Fusion zelf gaf (" + g33.length + ")");
ok(out.filter(function (l) { return /^; SNEDE \d+$/.test(l); }).length === 5,
    "vijf genummerde snedes, overgenomen uit Fusion");
ok(text.indexOf("; RECHTE SNEDE") >= 0, "rechte snede aanwezig");
ok(/^S4=190$/m.test(text) && /^S4=200$/m.test(text) && /^S4=210$/m.test(text),
    "toerentallen 190 / 200 / 210 bij 200 tpm en 5%");
ok(g33.every(function (l) { return /^G33 X-?[\d.]+ Z-?[\d.]+ K6$/.test(l); }),
    "elke G33 heeft X, Z en K6");
var retracts = out.filter(function (l) { return /^(G0 )?X115$/.test(l); });
ok(retracts.length === 6, "zes terugtrekkingen naar X115 (" + retracts.length + ")");
ok(retracts.every(function (l) { return l === "G0 X115"; }),
    "elke terugtrekking heeft een G0: " + retracts.join(" | "));

// De laatste snijbeweging moet op einddiepte en op het eind van de draad staan.
var last = g33[g33.length - 1];
ok(last === "G33 X61.62 Z-54.5 K6", "laatste G33 op einddiepte en op het Z-eind van Fusion: " + last);
var beyond = g33.filter(function (l) { return parseFloat(/Z(-?[\d.]+)/.exec(l)[1]) < -54.5 - 1e-9; });
ok(beyond.length === 0, "geen enkele beweging voorbij het Z-eind van Fusion");

// Geen enkele X mag dieper gaan dan de einddiepte van Fusion.
var tooDeep = g33.filter(function (l) { return parseFloat(/X(-?[\d.]+)/.exec(l)[1]) < 61.62 - 1e-9; });
ok(tooDeep.length === 0, "geen enkele snede dieper dan 61.62: " + tooDeep.slice(0, 3).join(" | "));

console.log("\n--- eerste 22 regels ---");
console.log(out.slice(0, 22).join("\n"));
console.log("--- laatste 8 regels ---");
console.log(out.slice(-8).join("\n"));

// ===========================================================================
// Regressie: M27x3 met een NEGATIEVE backHeight_offset.
// Hier liep de draad 4.5 mm voorbij de harde stop op Z-46.7709, omdat het
// eindpunt uit backHeight_value + backHeight_offset werd berekend in plaats
// van uit de snijbeweging van Fusion zelf.
// ===========================================================================
console.log("\nRegressie M27x3 - harde stop op Z-46.7709");

var HARD_STOP = -46.7709;
params["operation:threadPitch"] = 3;
params["operation:threadDepth"] = 1.84;
params["operation:frontHeight_value"] = -7.382;
params["operation:frontHeight_offset"] = 4.5;
params["operation:backHeight_value"] = HARD_STOP;
params["operation:backHeight_offset"] = -4.5;   // negatief: hier ging het mis
settings._11_oscillatie = "normal";
settings._12_aantalPassen = 14;
settings._15_toerentalVariatie = 10;
g.spindleSpeed = 1100;

out.length = 0;
g.errors.length = 0;
g.xOutput.reset(); g.yOutput.reset(); g.zOutput.reset(); g.gMotionModal.reset();

g.variThread.start();
[[30.764 / 2, 3, false], [30.764 / 2, -7.382, false]].forEach(function (m) {
    g.variThread.record(m[0], 0, m[1], m[2]);
});
for (var k = 0; k < 5; k++) {
    g.variThread.record(26.5 / 2 - k * 0.2, 0, -7.382, false);
    g.variThread.record(26.5 / 2 - k * 0.2, 0, HARD_STOP, true);
    g.variThread.record(30.764 / 2, 0, HARD_STOP, false);
}

var geo2 = g.variThread.geometry();
near(geo2.zEnd, HARD_STOP, 1e-9, "Z-eind = de harde stop, niet 4.5 mm erachter");
near(geo2.zMotionStart, -7.382, 1e-9, "Z-begin uit de positionering van Fusion");

g.variThread.emit();
ok(g.errors.length === 0, "geen fouten: " + g.errors.join("; "));

var g33b = out.filter(function (l) { return l.indexOf("G33") === 0; });
var zs = g33b.map(function (l) { return parseFloat(/Z(-?[\d.]+)/.exec(l)[1]); });
// Tolerantie = de resolutie van zFormat (3 decimalen); -46.7709 schrijft als
// -46.771, net als in de uitvoer van Fusion zelf.
var RES = 0.0005;
var past = zs.filter(function (z) { return z < HARD_STOP - RES; });
ok(past.length === 0, "geen enkele G33 voorbij Z" + HARD_STOP + ": " + past.slice(0, 3).join(", "));
near(Math.min.apply(null, zs), HARD_STOP, RES, "diepste Z raakt de harde stop");

var starts = out.filter(function (l) { return /^Z-?[\d.]+$/.test(l); })
    .map(function (l) { return parseFloat(l.slice(1)); });
var tooFar = starts.filter(function (z) { return z > -7.382 + RES; });
ok(tooFar.length === 0, "geen enkele aanloop voorbij het Z-begin van Fusion: " + tooFar.slice(0, 3).join(", "));

console.log("\n" + (fails === 0 ? "OK" : "MISLUKT") + " - " + (checks - fails) + "/" + checks + " controles geslaagd");
process.exit(fails === 0 ? 0 : 1);
