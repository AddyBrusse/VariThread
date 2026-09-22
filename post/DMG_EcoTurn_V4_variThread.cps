/**
  Copyright (C) 2012-2024 by Autodesk, Inc.
  All rights reserved.

  Siemens mill-turn post processor configuration.

  $Revision: 44132 43e5a58dcd1e7bcc87a95bf253f3ed223d7e7c80 $
  $Date: 2024-06-21 21:12:55 $

  FORKID {323BB66D-F7E5-4EA4-9E64-ED37951A5AFB}
*/

///////////////////////////////////////////////////////////////////////////////
//                        MANUAL NC COMMANDS
//
// The following ACTION commands are supported by this post.
//
//     usePolarInterpolation      - Force Polar interpolation mode for next operation (usePolarMode is deprecated but still supported)
//     usePolarCoordinates        - Force Polar coordinates for the next operation (useXZCMode is deprecated but still supported)
//
///////////////////////////////////////////////////////////////////////////////


debug = false // set to true to enable debug output

// ---------------------------------------------------------------------------
// Buffered header data (populated in onOpen / onParameter, written by myBufferdOpen on first onSection)
// ---------------------------------------------------------------------------
var bufferParameters = {
    part: "",
    prog: "",
    time: "",
    jobNotes: "",
    tools: [],
    workpieceUpperZ: 0,
    workpieceLowerZ: 0,
    workpieceLength: 0,
    stockDiameter: 0,
    isBarPullProg: false,
    pullingDistance: 0
};

var generatedAtRaw = "";
var chuckFrontMode = "";
var chuckOffset = 0;
var centerWorkBuffer = "";


description = "Siemens Mill-Turn";
vendor = "Siemens";
vendorUrl = "http://www.siemens.com";
legal = "Copyright (C) 2012-2024 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45909;

longDescription = "Generic Siemens mill-turn post. This post must be customized for the particular capabilities of your lathe before use. This post requires careful testing when used.";

extension = "mpf";
setCodePage("ascii");

capabilities = CAPABILITY_MILLING | CAPABILITY_TURNING;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
var useArcTurn = false;
maximumCircularSweep = toRad(useArcTurn ? 120 : 120); // max revolutions
allowHelicalMoves = !useArcTurn;
allowedCircularPlanes = undefined; // allow any circular motion
allowSpiralMoves = false;
allowFeedPerRevolutionDrilling = true;
highFeedrate = (unit == IN) ? 470 : 5000;

// user-defined properties
properties = {
    xAxisMinimum: {
        title: "X-axis minimum limit",
        description: "Defines the lower limit of X-axis travel as a radius value.",
        group: "preferences",
        type: "spatial",
        range: [-99999, 0],
        value: 0,
        scope: "post"
    },
    gotChipConveyor: {
        title: "Got chip conveyor",
        description: "Specifies whether to use a chip conveyor.",
        group: "Instellingen",
        type: "boolean",
        value: false,
        scope: "post"
    },
    maximumSpindleSpeed: {
        title: "Max spindle speed",
        description: "Defines the maximum spindle speed allowed by your machines.",
        group: "Instellingen",
        type: "integer",
        range: [0, 999999999],
        value: 2000,
        scope: "post"
    },
    useSmoothing: {
        title: "Use CYCLE832",
        description: "Enable to use CYCLE832.",
        group: "preferences",
        type: "enum",
        values: [
            { title: "Off", id: "-1" },
            { title: "Automatic", id: "9999" },
            { title: "Level 1", id: "1" },
            { title: "Level 2", id: "2" },
            { title: "Level 3", id: "3" }
        ],
        value: "9999",
        scope: "post"
    },
    showSequenceNumbers: {
        title: "Use sequence numbers",
        description: "'Yes' outputs sequence numbers on each block, 'Only on tool change' outputs sequence numbers on tool change blocks only, and 'No' disables the output of sequence numbers.",
        group: "formats",
        type: "enum",
        values: [
            { title: "Yes", id: "true" },
            { title: "No", id: "false" },
            { title: "Only on tool change", id: "toolChange" }
        ],
        value: "true",
        scope: "post"
    },
    sequenceNumberStart: {
        title: "Start sequence number",
        description: "The number at which to start the sequence numbers.",
        group: "formats",
        type: "integer",
        value: 10,
        scope: "post"
    },
    sequenceNumberIncrement: {
        title: "Sequence number increment",
        description: "The amount by which the sequence number is incremented by in each block.",
        group: "formats",
        type: "integer",
        value: 1,
        scope: "post"
    },
    useRadius: {
        title: "Radius arcs",
        description: "If yes is selected, arcs are outputted using radius values rather than IJK.",
        group: "preferences",
        type: "boolean",
        value: true,
        scope: "post"
    },
    optionalStop: {
        title: "Optional stop",
        description: "Outputs optional stop code during when necessary in the code.",
        group: "preferences",
        type: "boolean",
        value: true,
        scope: "post"
    },
    useParametricFeed: {
        title: "Parametric feed",
        description: "Specifies the feed value that should be output using a Q value.",
        group: "preferences",
        type: "boolean",
        value: false,
        scope: "post"
    },
    useTailStock: {
        title: "Use tailstock",
        description: "Specifies whether to use the tailstock or not.",
        group: "Instellingen",
        type: "boolean",
        value: false,
        scope: "post"
    },
    homePositionX: {
        title: "G53 home position X",
        description: "G53 X-axis home position.",
        group: "Instellingen",
        type: "number",
        value: 225,
        scope: "post"
    },
    homePositionY: {
        title: "G53 home position Y",
        description: "G53 Y-axis home position.",
        group: "Instellingen",
        type: "number",
        value: 0,
        scope: "post"
    },
    homePositionZ: {
        title: "G53 home position Z",
        description: "G53 Z-axis home position.",
        group: "Instellingen",
        type: "number",
        value: 685,
        scope: "post"
    },
    homePositionSubZ: {
        title: "G53 home position Z (secondary spindle)",
        description: "G53 Z-axis home position for the secondary spindle.",
        group: "homePositions",
        type: "number",
        value: 0,
        scope: "post"
    },
    useYAxisForDrilling: {
        title: "Position in Y for axial drilling",
        description: "Positions in Y for axial drilling options when it can instead of using the C-axis.",
        group: "preferences",
        type: "boolean",
        value: false,
        scope: "post"
    },
    useSubroutines: {
        title: "Use subroutines",
        description: "Select your desired subroutine option. 'All Operations' creates subroutines per each operation.",
        group: "preferences",
        type: "enum",
        values: [
            { title: "No", id: "none" },
            { title: "All Operations", id: "allOperations" }
            //{title: "Cycles", id: "cycles"},
            //{title: "Patterns", id: "patterns"}
        ],
        value: "none",
        scope: "post"
    },
    useFilesForSubprograms: {
        title: "Use files for subroutines",
        description: "If enabled, subroutines will be saved as individual files.",
        group: "preferences",
        type: "boolean",
        value: false,
        scope: "post"
    },
    separateWordsWithSpace: {
        title: "Separate words with space",
        description: "Adds spaces between words if 'yes' is selected.",
        group: "formats",
        type: "boolean",
        value: true,
        scope: "post"
    },
    showNotes: {
        title: "Show notes",
        description: "Writes operation notes as comments in the outputted code.",
        group: "formats",
        type: "boolean",
        value: false,
        scope: "post"
    },
    writeMachine: {
        title: "Write machine",
        description: "Output the machine settings in the header of the code.",
        group: "formats",
        type: "boolean",
        value: false,
        scope: "post"
    },
    writeTools: {
        title: "Write tool list",
        description: "Output a tool list in the header of the code.",
        group: "formats",
        type: "boolean",
        value: false,
        scope: "post"
    },
    /*toolAsName: {
      title      : "Tool as name",
      description: "If enabled, the tool will be called with the tool description rather than the tool number.",
      group      : "Instellingen",
      type       : "boolean",
      value      : true,
      scope      : "post"
    },
    */
    useShortestDirection: {
        title: "Use shortest direction",
        description: "Specifies that the shortest angular direction should be used.",
        group: "multiAxis",
        type: "boolean",
        value: true,
        scope: "post"
    },
    _01_isBroaching: { // ID changed from 'isBroaching'
        title: "1-Broodscyclus gebruiken?",
        description: "1-Gebruik een broods op de machine ipv een boor.",
        group: "general",
        scope: "operation",
        enabled: "drilling",
        type: "boolean",
        value: false,
        order: 10 // This 'order' might still be ignored for internal sorting
    },
    // Change the ID for "2-Broods diepte" to start with "02_"
    _02_broodsDiepte: { // ID changed from 'broodsDiepte'
        title: "2-Broods diepte",
        description: "2-De diepte vanad de start tot het geselecteerde eindpunt (in radius)",
        group: "general",
        scope: "operation",
        enabled: "drilling",
        type: "number",
        value: 0,
        order: 20
    },
    // Change the ID for "3-Diepte stap" to start with "03_"
    _03_stapGrootte: { // ID changed from 'stapGrootte'
        title: "3-Diepte stap in X-as op radius",
        description: "3-Stel de maximale diepte stap in de X-as riching in.",
        group: "general",
        scope: "operation",
        enabled: "drilling",
        type: "number",
        value: 0,
        order: 30
    },
    // Change the ID for "4-Snijsnelheid" to start with "04_"
    _04_snijSnelheid: { // ID changed from 'snijSnelheid'
        title: "4-Snijsnelheid mm/min",
        description: "4-De snelheid waarmee de Z-as beweegt RVS-5000 Staal-8000",
        group: "general",
        scope: "operation",
        enabled: "drilling",
        type: "number",
        value: 0,
        order: 40
    },
    _10_variThread: {
        title: "10-VariThread draadcyclus gebruiken?",
        description: "10-Vervang de draadsnedes van Fusion door een oscillerende flank-infeed met varierende X-diepte.",
        group: "general",
        scope: "operation",
        enabled: "turning",
        type: "boolean",
        value: false,
        order: 100
    },
    _11_oscillatie: {
        title: "11-Oscillatie frequentie",
        description: "11-Knoopafstand van de oscillatie als veelvoud van de spoed. Grof = 3xP, Normaal = 2xP, Fijn = 1xP (even snedes de helft daarvan).",
        group: "general",
        scope: "operation",
        enabled: "turning",
        type: "enum",
        values: [
            { title: "Geen", id: "none" },
            { title: "Fijn", id: "fine" },
            { title: "Normaal", id: "normal" },
            { title: "Grof", id: "coarse" }
        ],
        value: "normal",
        order: 110
    },
    _12_aantalPassen: {
        title: "12-Aantal snedes",
        description: "12-Aantal snedes exclusief de extra rechte snede. 0 = het aantal uit Fusion overnemen.",
        group: "general",
        scope: "operation",
        enabled: "turning",
        type: "integer",
        value: 0,
        order: 120
    },
    _13_extraGladdeSnede: {
        title: "13-Extra rechte snede",
        description: "13-Sluit af met een niet-oscillerende snede op einddiepte.",
        group: "general",
        scope: "operation",
        enabled: "turning",
        type: "boolean",
        value: true,
        order: 130
    },
    _14_snijsnelheid: {
        title: "14-Snijsnelheid m/min",
        description: "14-Wordt omgerekend naar toerental op de draaddiameter. 0 = het toerental uit Fusion gebruiken.",
        group: "general",
        scope: "operation",
        enabled: "turning",
        type: "number",
        value: 0,
        order: 140
    },
    _15_toerentalVariatie: {
        title: "15-Toerentalvariatie +/- %",
        description: "15-Wisselt het toerental per snede volgens -%, 0, +% en dan weer van voren af aan. Voorkomt trillingen. 0 = uit.",
        group: "general",
        scope: "operation",
        enabled: "turning",
        type: "number",
        value: 0,
        order: 150
    }
}


// wcs definiton
wcsDefinitions = {
    useZeroOffset: false,
    wcs: [
        { name: "Standard", format: "G", range: [54, 57] },
        { name: "Extended", format: "G", range: [505, 599] }
    ]
};

var toolAsName = true;

var singleLineCoolant = false; // specifies to output multiple coolant codes in one line rather than in separate lines
// samples:
// {id: COOLANT_THROUGH_TOOL, on: 88, off: 89}
// {id: COOLANT_THROUGH_TOOL, on: [8, 88], off: [9, 89]}
// {id: COOLANT_THROUGH_TOOL, turret1:{on: [8, 88], off:[9, 89]}, turret2:{on:88, off:89}}
// {id: COOLANT_THROUGH_TOOL, spindle1:{on: [8, 88], off:[9, 89]}, spindle2:{on:88, off:89}}
// {id: COOLANT_THROUGH_TOOL, spindle1t1:{on: [8, 88], off:[9, 89]}, spindle1t2:{on:88, off:89}}
// {id: COOLANT_THROUGH_TOOL, on: "M88 P3 (myComment)", off: "M89"}
var coolants = [
    { id: COOLANT_FLOOD, on: 108, off: 109 },
    { id: COOLANT_MIST },
    { id: COOLANT_THROUGH_TOOL, on: 108, off: 109 },
    { id: COOLANT_AIR },
    { id: COOLANT_AIR_THROUGH_TOOL },
    { id: COOLANT_SUCTION },
    { id: COOLANT_FLOOD_MIST },
    { id: COOLANT_FLOOD_THROUGH_TOOL, on: 108, off: [109] },
    { id: COOLANT_OFF, off: 9 }
];

var settings = {
    smoothing: {
        roughing: 3, // roughing level for smoothing in automatic mode
        semi: 2, // semi-roughing level for smoothing in automatic mode
        semifinishing: 2, // semi-finishing level for smoothing in automatic mode
        finishing: 1, // finishing level for smoothing in automatic mode
        thresholdRoughing: toPreciseUnit(0.2, MM), // operations with stock/tolerance above that threshold will use roughing level in automatic mode
        thresholdFinishing: toPreciseUnit(0.05, MM), // operations with stock/tolerance below that threshold will use finishing level in automatic mode
        thresholdSemiFinishing: toPreciseUnit(0.1, MM), // operations with stock/tolerance above finishing and below threshold roughing that threshold will use semi finishing level in automatic mode

        differenceCriteria: "both", // options: "level", "tolerance", "both". Specifies criteria when output smoothing codes
        autoLevelCriteria: "stock", // use "stock" or "tolerance" to determine levels in automatic mode
        cancelCompensation: false // tool length compensation must be canceled prior to changing the smoothing level
    }
}

var mainSpindleAxisName = ["C4", 4]; // axis name, axis number (number is used for eg. SETMS(VALUE));
var subSpindleAxisName = ["SP3", 3]; // axis name, axis number (number is used for eg. SETMS(VALUE));
var liveToolSpindleAxisName = ["C1", 1]; // axis name, axis number (number is used for eg. SETMS(VALUE));

var gFormat = createFormat({ prefix: "G", decimals: 0 });
var mFormat = createFormat({ prefix: "M", decimals: 0 });

var spatialFormat = createFormat({ decimals: (unit == MM ? 3 : 4) });
var xyzFormat = createFormat({ decimals: (unit == MM ? 3 : 4) });
var xFormat = createFormat({ decimals: (unit == MM ? 3 : 4), scale: 2 }); // diameter mode & IS SCALING POLAR COORDINATES
var yFormat = createFormat({ decimals: (unit == MM ? 3 : 4) });
var zFormat = createFormat({ decimals: (unit == MM ? 3 : 4) });
var abcFormat = createFormat({ decimals: 3, scale: DEG });
var cFormat = createFormat({ decimals: 3, type: FORMAT_REAL, scale: DEG, prefix: "=DC(", suffix: ")" }); // var cFormat = createFormat({ decimals: 3, type: FORMAT_REAL, scale: DEG, prefix: "=" });
var fpmFormat = createFormat({ decimals: (unit == MM ? 2 : 3) });
var fprFormat = createFormat({ decimals: (unit == MM ? 3 : 4), minimum: (unit == MM ? 0.001 : 0.0001) });
var feedFormat = fpmFormat;
var toolFormat = createFormat({ decimals: 0 });
var rpmFormat = createFormat({ decimals: 0 });
var secFormat = createFormat({ decimals: 3 }); // seconds - range 0.001-99999.999
var milliFormat = createFormat({ decimals: 0 }); // milliseconds // range 1-9999
var taperFormat = createFormat({ decimals: 1, scale: DEG });
var integerFormat = createFormat({ decimals: 0 });
var dFormat = createFormat({ prefix: "D", decimals: 0 });

var xOutput = createOutputVariable({ onchange: function () { retracted = false; }, prefix: "X" }, xFormat);
var yOutput = createOutputVariable({ prefix: "Y" }, yFormat);
var zOutput = createOutputVariable({ onchange: function () { retracted = false; }, prefix: "Z" }, zFormat);
var aOutput = createOutputVariable({ prefix: "A" }, abcFormat);
var bOutput = createOutputVariable({ prefix: "B1=" }, abcFormat);
var cOutput = createOutputVariable({ prefix: mainSpindleAxisName[0] }, cFormat);
var feedOutput = createOutputVariable({ prefix: "F" }, feedFormat);
var sOutput = createOutputVariable({ control: CONTROL_FORCE }, rpmFormat);
var dOutput = createOutputVariable({}, dFormat);

// circular output
var iOutput = createOutputVariable({ prefix: "I", control: CONTROL_FORCE }, spatialFormat);
var jOutput = createOutputVariable({ prefix: "J", control: CONTROL_FORCE }, spatialFormat);
var kOutput = createOutputVariable({ prefix: "K", control: CONTROL_FORCE }, spatialFormat);

var gMotionModal = createOutputVariable({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createOutputVariable({ onchange: function () { gMotionModal.reset(); } }, gFormat); // modal group 2 // G17-19
var gFeedModeModal = createOutputVariable({}, gFormat); // modal group 5 // G98-99
var gSpindleModeModal = createOutputVariable({}, gFormat); // modal group 5 // G96-97
var gAbsIncModal = createOutputVariable({}, gFormat); // modal group 3 // G90-91
var gUnitModal = createOutputVariable({}, gFormat); // modal group 6 // G20-21
var cAxisBrakeModal = createOutputVariable({}, mFormat);
var cAxisEngageModal = createOutputVariable({}, mFormat);

// fixed settings
var firstFeedParameter = 100;
var maximumLineLength = 80; // the maximum number of charaters allowed in a line

var yAxisMinimum = toPreciseUnit(-100, MM); // specifies the minimum range for the Y-axis
var yAxisMaximum = toPreciseUnit(100, MM); // specifies the maximum range for the Y-axis
var gotMultiTurret = false; // specifies if the machine has several turrets

var gotPolarInterpolation = true; // specifies if the machine has XY polar interpolation (TRANSMIT) capabilities
var gotSecondarySpindle = false;
var gotDoorControl = false;
var gotBarFeeder = false;
var turret1GotYAxis = true;
var turret2GotYAxis = false;
var turret1GotBAxis = false;
var bAxisIsManual = false;

// defined in activateMachine
var gotYAxis;
var xAxisMinimum;
var gotBAxis;

var WARNING_TURRET_UNSPECIFIED = 0;

var SPINDLE_MAIN = 0;
var SPINDLE_SUB = 1;
var SPINDLE_LIVE = 2;

// getSpindle parameters
var TOOL = false;
var PART = true;

// collected state
var sequenceNumber;
var currentWorkOffset;
var optionalSection = false;
var forceSpindleSpeed = false;
var activeMovements; // do not use by default
var currentFeedId;
var previousSpindle = SPINDLE_MAIN;
var forcePolarCoordinates = false; // forces Polar coordinate output, activated by Action:usePolarCoordinates
var forcePolarInterpolation = false; // force Polar interpolation output, activated by Action:usePolarInterpolation
var tapping = false;
var bestABC = undefined;
var activeTurret = 1;
var reverseAxes;
var operationSupportsTCP; // multi-axis operation supports TCP
var retracted = false; // specifies that the tool has been retracted to the safe plane
var subprograms = [];
var currentPattern = -1;
var firstPattern = false;
var currentSubprogram = 0;
var lastSubprogram = 0;
var saveShowSequenceNumbers;
var subprogramExtension = "spf";
var toolLengthOffset = 0;
var stockForMeasure = 0;
var _DSSV = false
var gFeedReduction = 1.0; // Global variable to store feed scaling

var machineState = {
    isTurningOperation: undefined,
    liveToolIsActive: undefined,
    cAxisIsEngaged: undefined,
    machiningDirection: undefined,
    mainSpindleIsActive: undefined,
    subSpindleIsActive: undefined,
    mainSpindleBrakeIsActive: undefined,
    subSpindleBrakeIsActive: undefined,
    tailstockIsActive: false,
    usePolarInterpolation: false,
    usePolarCoordinates: false,
    axialCenterDrilling: false,
    currentBAxisOrientationTurning: new Vector(0, 0, 0),
    mainChuckIsClamped: undefined,
    subChuckIsClamped: undefined,
    spindlesAreAttached: false,
    spindlesAreSynchronized: false,
    stockTransferIsActive: false,
    cAxesAreSynchronized: false,
    feedPerRevolution: undefined,
    isBroachingOperation: false,
    isVariThreadOperation: false,
    isDSSVon: false,
};



function formatOutputVariables() {
    xyzFormat.setNumberOfDecimals(unit == MM ? 5 : 6);
    abcFormat.setNumberOfDecimals(6);
    //abcDirectFormat.setNumberOfDecimals(3);
    //abc3Format.setNumberOfDecimals(8);
    xOutput.setFormat(xyzFormat);
    yOutput.setFormat(xyzFormat);
    zOutput.setFormat(xyzFormat);
    //aOutput.setFormat(abcFormat);
    //bOutput.setFormat(abcFormat);
    //cOutput.setFormat(abcFormat);
    //toolVectorOutputI.setFormat(abc3Format);
    //toolVectorOutputJ.setFormat(abc3Format);
    //toolVectorOutputK.setFormat(abc3Format);
    iOutput.setFormat(xyzFormat);
    jOutput.setFormat(xyzFormat);
    kOutput.setFormat(xyzFormat);
}

/** G/M codes setup */
function getCode(code, spindle) {
    switch (code) {

        case "PART_CATCHER_ON":
            return mFormat.format(681);
        case "PART_CATCHER_OFF":
            return mFormat.format(680);
        case "TAILSTOCK_ON":
            machineState.tailstockIsActive = true;
            return mFormat.format(55);
        case "TAILSTOCK_OFF":
            machineState.tailstockIsActive = false;
            return mFormat.format(54);
        case "ENABLE_C_AXIS":
            machineState.cAxisIsEngaged = true;
            cOutput.reset();
            return "";
        // return "SPOS[" + (currentSection.spindle == SPINDLE_PRIMARY ? mainSpindleAxisName[1] : subSpindleAxisName[1])+ "]=" + abcFormat.format(0);
        case "DISABLE_C_AXIS":
            machineState.cAxisIsEngaged = false;
            cOutput.reset();
            return "";
        // return "SPOS[" + (currentSection.spindle == SPINDLE_PRIMARY ? mainSpindleAxisName[1] : subSpindleAxisName[1]) + "]=" + abcFormat.format(0);
        case "POLAR_INTERPOLATION_ON":
            //return "TRANSMIT(" + (((currentSection.spindle == SPINDLE_PRIMARY) ? mainSpindleAxisName[1] : subSpindleAxisName[1]) + ")");
            return "TRANSMIT()";
        case "POLAR_INTERPOLATION_OFF":
            return "TRAFOOF";
        case "STOP_SPINDLE":
            switch (spindle) {
                case SPINDLE_MAIN:
                    machineState.mainSpindleIsActive = false;
                    return mFormat.format(mainSpindleAxisName[1]) + "=" + spatialFormat.format(5);
                case SPINDLE_LIVE:
                    machineState.liveToolIsActive = false;
                    return mFormat.format(liveToolSpindleAxisName[1]) + "=" + spatialFormat.format(5);
                case SPINDLE_SUB:
                    machineState.subSpindleIsActive = false;
                    return mFormat.format(subSpindleAxisName[1]) + "=" + spatialFormat.format(5);
            }
            break;
        case "START_SPINDLE_CW":
            switch (spindle) {
                case SPINDLE_MAIN:
                    machineState.mainSpindleIsActive = true;
                    return mFormat.format(mainSpindleAxisName[1]) + "=" + spatialFormat.format(3);
                case SPINDLE_LIVE:
                    machineState.liveToolIsActive = true;
                    return mFormat.format(liveToolSpindleAxisName[1]) + "=" + spatialFormat.format(3);
                case SPINDLE_SUB:
                    machineState.subSpindleIsActive = true;
                    return mFormat.format(subSpindleAxisName[1]) + "=" + spatialFormat.format(3);
            }
            break;
        case "START_SPINDLE_CCW":
            switch (spindle) {
                case SPINDLE_MAIN:
                    machineState.mainSpindleIsActive = true;
                    return mFormat.format(mainSpindleAxisName[1]) + "=" + spatialFormat.format(4);
                case SPINDLE_LIVE:
                    machineState.liveToolIsActive = true;
                    return mFormat.format(liveToolSpindleAxisName[1]) + "=" + spatialFormat.format(4);
                case SPINDLE_SUB:
                    machineState.subSpindleIsActive = true;
                    return mFormat.format(subSpindleAxisName[1]) + "=" + spatialFormat.format(4);
            }
            break;
        case "FEED_MODE_UNIT_REV":
            machineState.feedPerRevolution = true;
            return gFormat.format(95);
        case "FEED_MODE_UNIT_MIN":
            machineState.feedPerRevolution = false;
            return gFormat.format(94);
        case "CONSTANT_SURFACE_SPEED_ON":
            return gFormat.format(96);
        case "CONSTANT_SURFACE_SPEED_OFF":
            return gFormat.format(97);
        case "LOCK_MULTI_AXIS":
            machineState.mainSpindleBrakeIsActive = true;
            return cAxisBrakeModal.format(412);
        case "UNLOCK_MULTI_AXIS":
            machineState.mainSpindleBrakeIsActive = false;
            return cAxisBrakeModal.format(413);
        case "MAINSPINDLE_AIR_BLAST_ON":
            return mFormat.format();
        case "MAINSPINDLE_AIR_BLAST_OFF":
            return mFormat.format();
        case "SUBSPINDLE_AIR_BLAST_ON":
            return mFormat.format();
        case "SUBSPINDLE_AIR_BLAST_OFF":
            return mFormat.format();
        case "CLAMP_PRIMARY_CHUCK":
            return mFormat.format(412);
        case "UNCLAMP_PRIMARY_CHUCK":
            return mFormat.format(413);
        case "CLAMP_SECONDARY_CHUCK":
            return mFormat.format();
        case "UNCLAMP_SECONDARY_CHUCK":
            return mFormat.format();
        case "SPINDLE_SYNCHRONIZATION_ON":
            machineState.spindleSynchronizationIsActive = true;
            return "L726";
        case "SPINDLE_SYNCHRONIZATION_OFF":
            machineState.spindleSynchronizationIsActive = false;
            return "L727";
        case "START_CHIP_TRANSPORT":
            return mFormat.format();
        case "STOP_CHIP_TRANSPORT":
            return mFormat.format();
        case "OPEN_DOOR":
            return mFormat.format(67);
        case "CLOSE_DOOR":
            return mFormat.format();
        case "COUNT_WORKPIECE":
            return mFormat.format(18);
        case "CENTER_PARK":
        //machineState.tailstockIsActive =false
        //return mFormat.format(54);
        case "CENTER_WORK":
        //machineState.tailstockIsActive =true
        //return mFormat.format(55);
        default:
            error(localize("Command " + code + " is not defined."));
            return 0;
    }
    return 0;
}

/** Write WCS. */
function writeWCS(section) {
    if (section.workOffset != currentWorkOffset) {
        writeBlock(section.wcs);
        currentWorkOffset = section.workOffset;
    }
}

/**  Returns the desired tolerance for the given section in MM.*/
function getTolerance() {
    var t1 = toPreciseUnit(tolerance, MM);
    var t2 = getParameter("operation:tolerance", t1);
    t1 = t1 > 0 ? Math.min(t1, t2) : t2;
    return unit == IN ? t1 * 25.4 : t1;
}

function formatSequenceNumber() {
    if (sequenceNumber > 99999) {
        sequenceNumber = getProperty("sequenceNumberStart");
    }
    var seqno = "N" + sequenceNumber;
    sequenceNumber += getProperty("sequenceNumberIncrement");
    return seqno;
}

function writeBlock() {
    var text = formatWords(arguments);
    if (!text) {
        return;
    }
    var seqno = "";
    var opskip = "";
    if (getProperty("showSequenceNumbers") == "true") {
        seqno = formatSequenceNumber();
    }
    if (optionalSection) {
        opskip = "/";
    }
    if (text) {
        writeWords(opskip, seqno, text);
    }
}

function formatComment(text) {
    return "; " + String(text);
}

function writeToolBlock() {
    var show = getProperty("showSequenceNumbers");
    setProperty("showSequenceNumbers", (show == "true" || show == "toolChange") ? "true" : "false");
    writeBlock(arguments);
    setProperty("showSequenceNumbers", show);
}

function writeComment(text) {
    writeln(formatComment(text));
}

function getB(abc, section) {
    if (section.spindle == SPINDLE_PRIMARY) {
        return abc.y;
    } else {
        return Math.PI - abc.y;
    }
}

function activateMachine(section) {
    // TCP setting
    operationSupportsTCP = false;

    // handle multiple turrets
    var turret = 1;
    if (gotMultiTurret) {
        turret = section.getTool().turret;
        if (turret == 0) {
            warningOnce(localize("Turret has not been specified. Using Turret 1 as default."), WARNING_TURRET_UNSPECIFIED);
            turret = 1; // upper turret as default
        }
        turret = turret == undefined ? 1 : turret;
        switch (turret) {
            case 1:
                gotYAxis = turret1GotYAxis;
                gotBAxis = turret1GotBAxis;
                break;
            case 2:
                gotYAxis = turret2GotYAxis;
                gotBAxis = false;
                break;
            default:
                error(subst(localize("Turret %1 is not supported"), turret));
                return turret;
        }
    } else {
        gotYAxis = turret1GotYAxis;
    }

    // disable unsupported rotary axes output
    if (!gotYAxis) {
        yOutput.disable();
    }
    aOutput.disable();

    // define machine configuration
    var bAxis;
    var cAxis;
    if (section != null) {
        if (section.getSpindle() == SPINDLE_PRIMARY) {
            bAxis = createAxis({ coordinate: 1, table: false, axis: [0, -1, 0], range: [-0.001, 90.001], preference: 0, tcp: true });
            cAxis = createAxis({ coordinate: 2, table: true, axis: [0, 0, 1], cyclic: true, range: [0, 359.999], tcp: operationSupportsTCP });
        } else {
            bAxis = createAxis({ coordinate: 1, table: false, axis: [0, 1, 0], range: [-0.001, 90.001], preference: 0, tcp: false });
            cAxis = createAxis({ coordinate: 2, table: true, axis: [0, 0, 1], cyclic: true, range: [0, 359.999], tcp: operationSupportsTCP });
        }
        if (gotBAxis) {
            machineConfiguration = new MachineConfiguration(bAxis, cAxis);
            bOutput.enable();
        } else {
            machineConfiguration = new MachineConfiguration(cAxis);
            bOutput.disable();
        }


        // define spindle axis
        if (!gotBAxis || bAxisIsManual || (turret == 2)) {
            if ((getMachiningDirection(section) == MACHINING_DIRECTION_AXIAL) && !section.isMultiAxis()) {
                machineConfiguration.setSpindleAxis(new Vector(0, 0, 1));
            } else {
                machineConfiguration.setSpindleAxis(new Vector(1, 0, 0));
            }
        } else {
            machineConfiguration.setSpindleAxis(new Vector(1, 0, 0)); // set the spindle axis depending on B0 orientation
        }

        // define linear axes limits
        var xAxisMaximum = 10000; // don't check X-axis maximum limit
        yAxisMinimum = gotYAxis ? yAxisMinimum : 0;
        yAxisMaximum = gotYAxis ? yAxisMaximum : 0;
        var xAxis = createAxis({ actuator: "linear", coordinate: 0, table: true, axis: [1, 0, 0], range: [xAxisMinimum, xAxisMaximum] });
        var yAxis = createAxis({ actuator: "linear", coordinate: 1, table: true, axis: [0, 1, 0], range: [yAxisMinimum, yAxisMaximum] });
        var zAxis = createAxis({ actuator: "linear", coordinate: 2, table: true, axis: [0, 0, 1], range: [-100000, 100000] });
        machineConfiguration.setAxisX(xAxis);
        machineConfiguration.setAxisY(yAxis);
        machineConfiguration.setAxisZ(zAxis);

        // enable retract/reconfigure
        safeRetractDistance = (unit == IN) ? 1 : 25; // additional distance to retract out of stock, can be overridden with a property
        safeRetractFeed = (unit == IN) ? 20 : 500; // retract feed rate
        safePlungeFeed = (unit == IN) ? 10 : 250; // plunge feed rate
        var stockExpansion = new Vector(toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN)); // expand stock XYZ values
        machineConfiguration.enableMachineRewinds();
        machineConfiguration.setSafeRetractDistance(safeRetractDistance);
        machineConfiguration.setSafeRetractFeedrate(safeRetractFeed);
        machineConfiguration.setSafePlungeFeedrate(safePlungeFeed);
        machineConfiguration.setRewindStockExpansion(stockExpansion);

        // multi-axis feedrates
        machineConfiguration.setMultiAxisFeedrate(
            operationSupportsTCP ? FEED_FPM : FEED_DPM, // FEED_INVERSE_TIME,
            99999, // maximum output value for dpm feed rates
            DPM_COMBINATION, // INVERSE_MINUTES/INVERSE_SECONDS or DPM_COMBINATION/DPM_STANDARD
            0.5, // tolerance to determine when the DPM feed has changed
            unit == MM ? 1.0 : 1.0 // ratio of rotary accuracy to linear accuracy for DPM calculations
        );

        machineConfiguration.setVendor("DMG Mori");
        machineConfiguration.setModel("NLX");
        setMachineConfiguration(machineConfiguration);
        if (section.isMultiAxis()) {
            section.optimizeMachineAnglesByMachine(machineConfiguration, OPTIMIZE_AXIS);
        }

        return turret;
    }
}

function formatTurretPos(number) {
    if (number > 100) {
        var s = String(number)
        var plaats = s[0]
        var pos = s.substring(1)
        return plaats + "/" + pos
    } else { return "#" }
}


function setSmoothing(mode) {
    //writeBlock(mode +" gtgfdgfdgdfsgfdgd")
    smoothingSettings = settings.smoothing;
    if ((mode == smoothing.isActive && (!mode || !smoothing.isDifferent) && !smoothing.force) || !machineState.liveToolIsActive) {
        return; // return if smoothing is already active or is not different
    }
    if (mode) { // enable smoothing

        //writeComment("")
        //writeComment("----SmoothSettings----")
        var stockToLeave = xyzFormat.getResultingValue(getParameter("operation:stockToLeave", 0));
        var tolerance = xyzFormat.getResultingValue(getParameter("operation:tolerance", 0));
        //writeComment("Operation stock     : " + stockToLeave)
        //writeComment("Operation tolerance : " + tolerance)
        //writeComment("Thresholds          : Rough=" + thresholdRoughing + " Semi=" + thresholdSemiFinishing + " Finish=" + thresholdFinishing)
        //writeComment("Set threshold       : " + smoothing.tolerance)



        if (stockToLeave >= 0.05) {
            writeBlock("CYCLE832(0.1,3,1)")
        }
        if (stockToLeave < 0.05 && stockToLeave > 0.02) {
            writeBlock("CYCLE832(0.05,2,1)")
        }
        if (stockToLeave <= 0.025) {
            writeBlock("CYCLE832(0.025,1,1)")
        }

        //writeComment("----SmoothSettings----")
        //writeComment("")
    } else { // disable smoothing
        writeBlock("CYCLE832()");
    }
    smoothing.isActive = mode;
    smoothing.force = false;
    smoothing.isDifferent = false;
}

function onOpen() {
    formatOutputVariables();


    if (getProperty("useRadius")) {
        maximumCircularSweep = toRad(90); // avoid potential center calculation errors for CNC
    }

    // Copy certain properties into global variables
    showSequenceNumbers = getProperty("showSequenceNumbers");
    xAxisMinimum = getProperty("xAxisMinimum");

    // define machine
    turret1GotBAxis = gotBAxis;
    activeTurret = activateMachine(getSection(0));

    if (highFeedrate <= 0) {
        error(localize("You must set 'highFeedrate' because axes are not synchronized for rapid traversal."));
        return;
    }

    reverseAxes = getProperty("reverseAxes", true);

    if (!getProperty("separateWordsWithSpace")) {
        setWordSeparator("");
    }

    sequenceNumber = getProperty("sequenceNumberStart");

    if (programName) {
        writeln("; %_N_" + translateText(String(programName).toUpperCase(), " ", "_") + "_MPF");

        if (programComment) {
            writeComment(programComment);
        }
    } else {
        error(localize("Program name has not been specified."));
        return;
    }

    // ---------------------------------------------------------------------------
    // Collect data into bufferParameters.
    // The actual header (JOB INFO + TOOLS table + NOTES) is written by
    // myBufferdOpen(), which is called from the first onSection().
    // ---------------------------------------------------------------------------
    var now = new Date();
    bufferParameters.part = "PART: " + getGlobalParameter("document-path");
    bufferParameters.prog = "PROG: " + getGlobalParameter("job-description");
    if (!bufferParameters.time) {
        bufferParameters.time = now.toLocaleString();
    }
    bufferParameters.tools = collectToolsFromSections();

    if (hasGlobalParameter("job-notes")) {
        bufferParameters.jobNotes = getGlobalParameter("job-notes");
    }

    // Keep the legacy global flag in sync (used elsewhere in this post)
    if (bufferParameters.isBarPullProg) {
        isBarPullProg = true;
    }


    if (true) {
        // check for duplicate tool number
        for (var i = 0; i < getNumberOfSections(); ++i) {
            var sectioni = getSection(i);
            var tooli = sectioni.getTool();
            for (var j = i + 1; j < getNumberOfSections(); ++j) {
                var sectionj = getSection(j);
                var toolj = sectionj.getTool();
                if (tooli.number == toolj.number) {
                    if (spatialFormat.areDifferent(tooli.diameter, toolj.diameter) ||
                        spatialFormat.areDifferent(tooli.cornerRadius, toolj.cornerRadius) ||
                        abcFormat.areDifferent(tooli.taperAngle, toolj.taperAngle) ||
                        (tooli.numberOfFlutes != toolj.numberOfFlutes)) {
                        error(
                            subst(
                                localize("Using the same tool number for different cutter geometry for operation '%1' and '%2'."),
                                sectioni.hasParameter("operation-comment") ? sectioni.getParameter("operation-comment") : ("#" + (i + 1)),
                                sectionj.hasParameter("operation-comment") ? sectionj.getParameter("operation-comment") : ("#" + (j + 1))
                            )
                        );
                        return;
                    }
                }
            }
        }
    }

    if ((getNumberOfSections() > 0) && (getSection(0).workOffset == 0)) {
        for (var i = 0; i < getNumberOfSections(); ++i) {
            if (getSection(i).workOffset > 0) {
                error(localize("Using multiple work offsets is not possible if the initial work offset is 0."));
                return;
            }
        }
    }

    // determine starting spindle (state setup only - no G-code emitted here)
    if (getNumberOfSections() > 0) {
        switch (getSection(0).spindle) {
            case SPINDLE_PRIMARY: // main spindle
                activeSpindle = SPINDLE_MAIN;
                machineState.mainChuckIsClamped = true;
                break;
            case SPINDLE_SECONDARY: // sub spindle
                activeSpindle = SPINDLE_SUB;
                machineState.subChuckIsClamped = true;
                break;

        }
    }

    if (gotSecondarySpindle) {
        // retract Sub Spindle if applicable
    }

    // NOTE: the startup G-code (WORKPIECE, G94 G18, G70/G71, UNCLAMP_PRIMARY_CHUCK,
    // LIMS=, chip conveyor) is emitted from myBufferdOpen() inside a "PROG START"
    // GROUP, so it appears AFTER the JOB INFO header on the first onSection.
}

function getOHL(tool) {
    var loop = true
    var numberOfSections = getNumberOfSections();
    for (var j = 0; j < numberOfSections; ++j) {
        section = getSection(j);
        if (tool.description.toUpperCase() == section.getTool().description.toUpperCase()) {
            var maxDepth = 0
            switch (tool.type) {
                case 1: // boor
                    maxDepth = section.getParameter('operation:tool_shoulderLength')
                    break
                case 22: // TOOL_TURNING_GENERAL, general turning
                    maxDepth = section.getParameter("operation:tool_holderOverallLength")
                    break
                case 24: // inwendig steek
                    maxDepth = section.getParameter("operation:tool_holderOverallLength")
                    break
                case 25: // boring bar
                    maxDepth = section.getParameter("operation:tool_holderOverallLength")
                    break
            }
            loop = false
            return maxDepth

        }
        if (!loop) { break }
    }
    return
}


function padRight(text, width) {
    var s = String(text || "");
    if (s.length > width) {
        return s.substring(0, width);
    }
    while (s.length < width) {
        s += " ";
    }
    return s;
}

function repeatChar(ch, count) {
    var out = "";
    for (var i = 0; i < count; ++i) {
        out += ch;
    }
    return out;
}

function truncate(text, width) {
    var s = String(text || "");
    return s.length > width ? s.substring(0, width) : s;
}

function centerInWidth(text, width) {
    var s = String(text || "");
    var totalPad = width - s.length;
    if (totalPad <= 0) {
        return s.substring(0, width);
    }
    var left = Math.floor(totalPad / 2);
    var right = totalPad - left;
    return repeatChar(" ", left) + s + repeatChar(" ", right);
}

function isChamferTool(tool) {
    if (!tool) {
        return false;
    }
    if (typeof TOOL_CHAMFER !== "undefined" && tool.type == TOOL_CHAMFER) {
        return true;
    }
    var typeText = String(tool.type || "").toLowerCase();
    if (typeText.indexOf("chamfer") >= 0) {
        return true;
    }
    return tool.taperAngle !== undefined && tool.taperAngle !== null && tool.taperAngle > 0;
}

function getDutchOpName(opName, tool) {
    var name = String(opName || "");
    var lower = name.toLowerCase();

    if (lower.indexOf("face") >= 0) return "VLAKKEN";
    if (lower.indexOf("profile roughing") >= 0) return "VOORDRAAIEN";
    if (lower.indexOf("profile finishing") >= 0) return "NADRAAIEN";
    if (lower.indexOf("groove") >= 0) return "GROEF";
    if (lower.indexOf("thread") >= 0) return "DRAAD";
    if (lower.indexOf("drill") >= 0) return "BOREN";
    if (lower.indexOf("bore") >= 0) return "KOTTEREN";
    if (lower.indexOf("part") >= 0) return "AFSTEKEN";
    if (lower.indexOf("trace") >= 0) return "AFSCHUINEN";
    if (lower.indexOf("2d contour") >= 0) {
        return isChamferTool(tool) ? "FREZEN AFSCHUINEN" : "FREZEN";
    }
    if (lower.indexOf("slot") >= 0) return "SLEUF";
    if (lower.indexOf("pocket") >= 0) return "POCKET";
    if (lower.indexOf("adaptive") >= 0) return "RUW FREZEN";
    if (lower.indexOf("engrave") >= 0) return "GRAVEREN";

    return name;
}

function appendInwUitw(base, tool) {
    var suffix = (tool && tool.isInternal) ? "INW" : "UITW";
    var desc = tool && (tool.description || tool.number) ? String(tool.description || tool.number) : "";
    var parts = [String(base || "").trim(), suffix];
    if (desc) {
        parts.push(desc.trim());
    }
    return parts.join(" ").trim();
}

function collectToolsFromSections() {
    var tools = [];
    var seen = {};
    var numberOfSections = getNumberOfSections();
    for (var j = 0; j < numberOfSections; ++j) {
        var section = getSection(j);
        var tool = section.getTool();
        if (!tool) {
            continue;
        }
        var key = String(tool.number) + "|" + String(tool.description) + "|" + String(tool.diameter);
        var entry = seen[key];
        if (!entry) {
            entry = {
                tool: tool,
                sp: "",
                zmin: undefined,
                ohl: undefined
            };
            seen[key] = entry;
            tools.push(entry);
        }

        if (section.spindle == SPINDLE_PRIMARY) {
            entry.sp = entry.sp == "SUB" ? "MAIN/SUB" : "MAIN";
        } else if (section.spindle == SPINDLE_SECONDARY) {
            entry.sp = entry.sp == "MAIN" ? "MAIN/SUB" : "SUB";
        }

        if (section.hasParameter("operation:bottomHeight_value")) {
            var z = section.getParameter("operation:bottomHeight_value");
            if (z !== undefined && z !== null) {
                entry.zmin = (entry.zmin === undefined) ? z : Math.min(entry.zmin, z);
            }
        }

        var ohl = undefined;
        switch (tool.type) {
            case 1: // boor
                if (section.hasParameter("operation:tool_shoulderLength")) {
                    ohl = section.getParameter("operation:tool_shoulderLength");
                }
                break;
            case 22: // TOOL_TURNING_GENERAL, general turning
            case 24: // inwendig steek
            case 25: // boring bar
                if (section.hasParameter("operation:tool_holderOverallLength")) {
                    ohl = section.getParameter("operation:tool_holderOverallLength");
                }
                break;
        }
        if (ohl !== undefined && ohl !== null) {
            entry.ohl = (entry.ohl === undefined) ? ohl : Math.max(entry.ohl, ohl);
        }

        if (section.hasParameter('operation-strategy') &&
            section.getParameter('operation-strategy') == 'turningSecondarySpindlePull') {
            bufferParameters.isBarPullProg = true;
        }
    }
    return tools;
}

function myBufferdOpen() {
    var partStr = bufferParameters.part || "";
    var progStr = bufferParameters.prog || "";
    var timeStr = bufferParameters.time || "";
    var notesStr = bufferParameters.jobNotes || "";
    var stickout = (String(chuckFrontMode).toLowerCase() == "model front") ? Math.abs(chuckOffset || 0) : 0;
    var wcsRef = 160 + stickout; // 160mm = DMG chuck reference length (Doosan uses 130mm)
    bufferParameters.workpieceLength =
        Math.abs(bufferParameters.workpieceUpperZ || 0) + Math.abs(bufferParameters.workpieceLowerZ || 0);
    bufferParameters.stockDiameter = hasParameter('stock-diameter') ? getParameter('stock-diameter') : 0;

    var labelWidth = 20;
    var valueWidth = 42;
    var jobSep = "+" + repeatChar("-", labelWidth + 2) + "+" + repeatChar("-", valueWidth + 2) + "+";
    var tableInnerWidth = labelWidth + valueWidth + 5;

    writeComment("|" + centerInWidth("JOB INFO", tableInnerWidth) + "|");
    writeComment(jobSep);
    writeComment("| " + padRight("PART", labelWidth) + " | " + padRight(partStr, valueWidth) + " |");
    writeComment("| " + padRight("PROGRAM", labelWidth) + " | " + padRight(progStr, valueWidth) + " |");
    writeComment("| " + padRight("TIJD", labelWidth) + " | " + padRight(timeStr, valueWidth) + " |");
    writeComment("| " + padRight("UITSTEEKLENGTE", labelWidth) + " | " + padRight(spatialFormat.format(stickout) + " mm", valueWidth) + " |");
    writeComment("| " + padRight("NULPUNT", labelWidth) + " | " + padRight(spatialFormat.format(wcsRef) + " mm", valueWidth) + " |");
    writeComment("| " + padRight("WERKSTUK LEN. +3MM", labelWidth) + " | " + padRight(spatialFormat.format(bufferParameters.workpieceLength + 3) + " mm", valueWidth) + " |");
    writeComment("| " + padRight("STOCK DIAMETER", labelWidth) + " | " + padRight(spatialFormat.format(bufferParameters.stockDiameter) + " mm", valueWidth) + " |");
    writeComment("| " + padRight("AANSLAG LENGTE", labelWidth) + " | " + padRight(spatialFormat.format(1285 + stickout) + " mm", valueWidth) + " |");
    writeComment(jobSep);

    writeComment("|" + centerInWidth("TOOLS", tableInnerWidth) + "|");
    var spWidth = 4;
    var nameWidth = 29;
    var liveWidth = 4;
    var dnrWidth = 4;
    var ohlWidth = 4;
    var zminWidth = 5;
    var separator = "+" +
        repeatChar("-", spWidth + 2) + "+" +
        repeatChar("-", nameWidth + 2) + "+" +
        repeatChar("-", liveWidth + 2) + "+" +
        repeatChar("-", dnrWidth + 2) + "+" +
        repeatChar("-", ohlWidth + 2) + "+" +
        repeatChar("-", zminWidth + 2) + "+";
    writeComment(separator);
    writeComment("| " + padRight("SP", spWidth) + " | " + padRight("NAME", nameWidth) + " | " + padRight("LIVE", liveWidth) + " | " + padRight("D/NR", dnrWidth) + " | " + padRight("OHL", ohlWidth) + " | " + padRight("ZMIN", zminWidth) + " |");
    writeComment(separator);

    var tools = bufferParameters.tools || [];
    tools.sort(function (a, b) {
        var spA = (a && a.sp) ? a.sp : "";
        var spB = (b && b.sp) ? b.sp : "";
        var order = { "MAIN": 0, "MAIN/SUB": 1, "SUB": 2 };
        var rankA = (order[spA] !== undefined) ? order[spA] : 3;
        var rankB = (order[spB] !== undefined) ? order[spB] : 3;
        if (rankA != rankB) {
            return rankA - rankB;
        }
        var numA = (a && a.tool && a.tool.number !== undefined) ? Number(a.tool.number) : 0;
        var numB = (b && b.tool && b.tool.number !== undefined) ? Number(b.tool.number) : 0;
        return numA - numB;
    });
    for (var t = 0; t < tools.length; ++t) {
        var entry = tools[t];
        var tool = entry.tool || {};
        var sp = entry.sp || "";
        var name = truncate((tool.description ? tool.description.toUpperCase() : "")  || tool.number || "", nameWidth);
        var dnr = (tool.diameter && tool.diameter > 0 && !isNaN(tool.diameter)) ? spatialFormat.format(Number(tool.diameter)) : String(tool.number || "");
        var ohl = entry.ohl;
        var ohlOut = (ohl === undefined || ohl === null || isNaN(ohl)) ? "" : spatialFormat.format(Number(ohl));
        var zmin = entry.zmin;
        var zminOut = (zmin === undefined || zmin === null || isNaN(zmin)) ? "" : spatialFormat.format(Number(zmin));
        if (zmin !== undefined && ohl !== undefined && ohl !== null) {
            if (Math.abs(zmin) > ohl) {
                zminOut = "CRASH!!";
            }
        }

        var liveOut = (tool.liveTool === true) ? "YES" : "NO";

        var rowString = "| ";
        rowString += padRight(sp, spWidth) + " | ";
        rowString += padRight(name, nameWidth) + " | ";
        rowString += padRight(liveOut, liveWidth) + " | ";
        rowString += padRight(dnr, dnrWidth) + " | ";
        rowString += padRight(ohlOut, ohlWidth) + " | ";
        rowString += padRight(zminOut, zminWidth) + " |";
        writeComment(rowString);
    }

    writeComment(separator);

    if (getProperty("showNotes") && notesStr) {
        writeComment("|" + centerInWidth("JOB NOTES", tableInnerWidth) + "|");
        writeComment("+" + repeatChar("-", tableInnerWidth) + "+");
        var noteLines = String(notesStr).split(/\r?\n/);
        for (var i = 0; i < noteLines.length; ++i) {
            var line = String(noteLines[i] || "").trim();
            if (line) {
                writeComment("NOTE: " + line);
            }
        }
    }

    if (centerWorkBuffer) {
        for (line in centerWorkBuffer) { // remove empty elements
            if (centerWorkBuffer[line] == "") {
                centerWorkBuffer.splice(line);
            }
            writeBlock(centerWorkBuffer[line]);
        }
    }

    // -----------------------------------------------------------------------
    // PROG START group: the machine startup G-code that used to be at the
    // bottom of onOpen() is now emitted here, AFTER the JOB INFO/TOOLS header.
    // No spindle-axis or motion logic is changed - only the location and
    // grouping of these blocks.
    // -----------------------------------------------------------------------
    writeln("GROUP_BEGIN(0,\"PROG START\",0,0)");

    // stock - workpiece
    var _wp = getWorkpiece();
    var _delta = Vector.diff(_wp.upper, _wp.lower);
    if (_delta.isNonZero()) {
        var _spindle = getSection(0).getSpindle() == SPINDLE_PRIMARY ? 192 : 4288;
        var _XA = _wp.upper.x; // diameter
        var _ZA = _wp.upper.z; // stock offset Z
        var _ZI = _wp.lower.z; // stock Z
        var _ZB = _ZI + toPreciseUnit(1, MM); // stock in chuck
        writeBlock(
            "WORKPIECE" + "(" + ",,," + "\"" + "CYLINDER" + "\"" + "," + _spindle + "," + zFormat.format(_ZA) + "," + zFormat.format(_ZI) +
            "," + spatialFormat.format(_ZB) + "," + xFormat.format(_XA) + ")"
        );
    }

    // absolute coordinates and feed per min
    writeBlock(getCode("FEED_MODE_UNIT_MIN"), gPlaneModal.format(18));
    writeBlock(gUnitModal.format((unit == IN) ? 70 : 71));

    writeBlock(getCode("UNCLAMP_PRIMARY_CHUCK"));
    writeBlock("LIMS=" + rpmFormat.format(getProperty("maximumSpindleSpeed")));
    sOutput.reset();

    if (getProperty("gotChipConveyor")) {
        onCommand(COMMAND_START_CHIP_TRANSPORT);
    }

    writeln("GROUP_END(0,0)");
}


function onComment(message) {
    writeComment(message);
}

/** Force output of X, Y, and Z. */
function forceXYZ() {
    xOutput.reset();
    yOutput.reset();
    zOutput.reset();
}

/** Force output of A, B, and C. */
function forceABC() {
    aOutput.reset();
    bOutput.reset();
    cOutput.reset();
    if (debug) { writeComment("End of forceABC function") }
}

function forceFeed() {
    currentFeedId = undefined;
    feedOutput.reset();
}

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny() {
    forceXYZ();
    forceABC();
    forceFeed();
    if (debug) { writeComment("End of force any function") }
}

function forceModals() {
    if (arguments.length == 0) { // reset all modal variables listed below
        if (typeof gMotionModal != "undefined") {
            gMotionModal.reset();
        }
        if (typeof gPlaneModal != "undefined") {
            gPlaneModal.reset();
        }
        if (typeof gAbsIncModal != "undefined") {
            gAbsIncModal.reset();
        }
        if (typeof gFeedModeModal != "undefined") {
            gFeedModeModal.reset();
        }
    } else {
        for (var i in arguments) {
            arguments[i].reset(); // only reset the modal variable passed to this function
        }
    }
}

function FeedContext(id, description, feed) {
    this.id = id;
    this.description = description;
    this.feed = feed;
}

function formatFeedMode(mode) {
    var fMode = (mode == FEED_PER_REVOLUTION || tapping) ? getCode("FEED_MODE_UNIT_REV") : getCode("FEED_MODE_UNIT_MIN");
    if (fMode) {
        feedFormat = mode == FEED_PER_REVOLUTION ? fprFormat : fpmFormat;
        feedOutput.setFormat(feedFormat);
    }
    return fMode;
}

function getFeed(f) {
    // Apply the reduction ratio calculated in onSection
    f = f * gFeedReduction;

    if (currentSection.feedMode != FEED_PER_REVOLUTION && machineState.feedPerRevolution) {
        f /= spindleSpeed;
    }
    if (activeMovements) {
        var feedContext = activeMovements[movement];
        if (feedContext != undefined) {
            if (!feedFormat.areDifferent(feedContext.feed, f)) {
                if (feedContext.id == currentFeedId) {
                    return ""; // nothing has changed
                }
                forceFeed();
                currentFeedId = feedContext.id;
                return "F=R" + (firstFeedParameter + feedContext.id);
            }
        }
        currentFeedId = undefined; // force Q feed next time
    }
    return feedOutput.format(f); // use feed value
}

function initializeActiveFeeds() {
    activeMovements = new Array();
    var movements = currentSection.getMovements();
    var feedPerRev = currentSection.feedMode == FEED_PER_REVOLUTION;

    var id = 0;
    var activeFeeds = new Array();
    if (hasParameter("operation:tool_feedCutting")) {
        if (movements & ((1 << MOVEMENT_CUTTING) | (1 << MOVEMENT_LINK_TRANSITION) | (1 << MOVEMENT_EXTENDED))) {
            var feedContext = new FeedContext(id, localize("Cutting"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
            activeFeeds.push(feedContext);
            activeMovements[MOVEMENT_CUTTING] = feedContext;
            if (!hasParameter("operation:tool_feedTransition")) {
                activeMovements[MOVEMENT_LINK_TRANSITION] = feedContext;
            }
            activeMovements[MOVEMENT_EXTENDED] = feedContext;
        }
        ++id;
        if (movements & (1 << MOVEMENT_PREDRILL)) {
            feedContext = new FeedContext(id, localize("Predrilling"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
            activeMovements[MOVEMENT_PREDRILL] = feedContext;
            activeFeeds.push(feedContext);
        }
        ++id;
    }

    if (hasParameter("operation:finishFeedrate")) {
        if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
            var finishFeedrateRel;
            if (hasParameter("operation:finishFeedrateRel")) {
                finishFeedrateRel = getParameter("operation:finishFeedrateRel");
            } else if (hasParameter("operation:finishFeedratePerRevolution")) {
                finishFeedrateRel = getParameter("operation:finishFeedratePerRevolution");
            }
            var feedContext = new FeedContext(id, localize("Finish"), feedPerRev ? finishFeedrateRel : getParameter("operation:finishFeedrate"));
            activeFeeds.push(feedContext);
            activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
        }
        ++id;
    } else if (hasParameter("operation:tool_feedCutting")) {
        if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
            var feedContext = new FeedContext(id, localize("Finish"), feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"));
            activeFeeds.push(feedContext);
            activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
        }
        ++id;
    }

    if (hasParameter("operation:tool_feedEntry")) {
        if (movements & (1 << MOVEMENT_LEAD_IN)) {
            var feedContext = new FeedContext(id, localize("Entry"), feedPerRev ? getParameter("operation:tool_feedEntryRel") : getParameter("operation:tool_feedEntry"));
            activeFeeds.push(feedContext);
            activeMovements[MOVEMENT_LEAD_IN] = feedContext;
        }
        ++id;
    }

    if (hasParameter("operation:tool_feedExit")) {
        if (movements & (1 << MOVEMENT_LEAD_OUT)) {
            var feedContext = new FeedContext(id, localize("Exit"), feedPerRev ? getParameter("operation:tool_feedExitRel") : getParameter("operation:tool_feedExit"));
            activeFeeds.push(feedContext);
            activeMovements[MOVEMENT_LEAD_OUT] = feedContext;
        }
        ++id;
    }

    if (hasParameter("operation:noEngagementFeedrate")) {
        if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
            var feedContext = new FeedContext(id, localize("Direct"), feedPerRev ? getParameter("operation:noEngagementFeedrateRel") : getParameter("operation:noEngagementFeedrate"));
            activeFeeds.push(feedContext);
            activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
        }
        ++id;
    } else if (hasParameter("operation:tool_feedCutting") &&
        hasParameter("operation:tool_feedEntry") &&
        hasParameter("operation:tool_feedExit")) {
        if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
            var feedContext = new FeedContext(
                id,
                localize("Direct"),
                Math.max(
                    feedPerRev ? getParameter("operation:tool_feedCuttingRel") : getParameter("operation:tool_feedCutting"),
                    feedPerRev ? getParameter("operation:tool_feedEntryRel") : getParameter("operation:tool_feedEntry"),
                    feedPerRev ? getParameter("operation:tool_feedExitRel") : getParameter("operation:tool_feedExit")
                )
            );
            activeFeeds.push(feedContext);
            activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
        }
        ++id;
    }

    if (hasParameter("operation:reducedFeedrate")) {
        if (movements & (1 << MOVEMENT_REDUCED)) {
            var feedContext = new FeedContext(id, localize("Reduced"), feedPerRev ? getParameter("operation:reducedFeedrateRel") : getParameter("operation:reducedFeedrate"));
            activeFeeds.push(feedContext);
            activeMovements[MOVEMENT_REDUCED] = feedContext;
        }
        ++id;
    }

    if (hasParameter("operation:tool_feedRamp")) {
        if (movements & ((1 << MOVEMENT_RAMP) | (1 << MOVEMENT_RAMP_HELIX) | (1 << MOVEMENT_RAMP_PROFILE) | (1 << MOVEMENT_RAMP_ZIG_ZAG))) {
            var feedContext = new FeedContext(id, localize("Ramping"), feedPerRev ? getParameter("operation:tool_feedRampRel") : getParameter("operation:tool_feedRamp"));
            activeFeeds.push(feedContext);
            activeMovements[MOVEMENT_RAMP] = feedContext;
            activeMovements[MOVEMENT_RAMP_HELIX] = feedContext;
            activeMovements[MOVEMENT_RAMP_PROFILE] = feedContext;
            activeMovements[MOVEMENT_RAMP_ZIG_ZAG] = feedContext;
        }
        ++id;
    }
    if (hasParameter("operation:tool_feedPlunge")) {
        if (movements & (1 << MOVEMENT_PLUNGE)) {
            var feedContext = new FeedContext(id, localize("Plunge"), feedPerRev ? getParameter("operation:tool_feedPlungeRel") : getParameter("operation:tool_feedPlunge"));
            activeFeeds.push(feedContext);
            activeMovements[MOVEMENT_PLUNGE] = feedContext;
        }
        ++id;
    }
    if (true) { // high feed
        if ((movements & (1 << MOVEMENT_HIGH_FEED)) || (highFeedMapping != HIGH_FEED_NO_MAPPING)) {
            var feed;
            if (hasParameter("operation:highFeedrateMode") && getParameter("operation:highFeedrateMode") != "disabled") {
                feed = getParameter("operation:highFeedrate");
            } else {
                feed = this.highFeedrate;
            }
            var feedContext = new FeedContext(id, localize("High Feed"), feed);
            activeFeeds.push(feedContext);
            activeMovements[MOVEMENT_HIGH_FEED] = feedContext;
            activeMovements[MOVEMENT_RAPID] = feedContext;
        }
        ++id;
    }
    if (hasParameter("operation:tool_feedTransition")) {
        if (movements & (1 << MOVEMENT_LINK_TRANSITION)) {
            var feedContext = new FeedContext(id, localize("Transition"), getParameter("operation:tool_feedTransition"));
            activeFeeds.push(feedContext);
            activeMovements[MOVEMENT_LINK_TRANSITION] = feedContext;
        }
        ++id;
    }

    for (var i = 0; i < activeFeeds.length; ++i) {
        var feedContext = activeFeeds[i];
        writeBlock("R" + (firstFeedParameter + feedContext.id) + "=" + feedFormat.format(feedContext.feed), formatComment(feedContext.description));
    }
}

var currentWorkPlaneABC = undefined;

function forceWorkPlane() {
    currentWorkPlaneABC = undefined;
}

function defineWorkPlane(_section, _setWorkPlane) {
    var abc = new Vector(0, 0, 0);
    if (machineConfiguration.isMultiAxisConfiguration()) {
        if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
            if (gotBAxis) {
                // TAG: handle B-axis support for turning operations here
                if (_setWorkPlane) {
                    writeBlock(gMotionModal.format(0), conditional(machineConfiguration.isMachineCoordinate(1), bOutput.format(getB(bAxisOrientationTurning, _section))));
                }
                machineState.currentBAxisOrientationTurning = bAxisOrientationTurning;
                //setSpindleOrientationTurning();
            } else {
                setRotation(_section.workPlane);
            }
        } else {
            if (_section.isMultiAxis() || isPolarModeActive()) {
                if (_setWorkPlane) {
                    forceWorkPlane();
                    onCommand(COMMAND_UNLOCK_MULTI_AXIS);
                }
                cancelTransformation();
                abc = currentSection.isMultiAxis() ? currentSection.getInitialToolAxisABC() : getCurrentDirection();
            } else {
                abc = getWorkPlaneMachineABC(_section, _section.workPlane);
            }
            if (_setWorkPlane && !machineState.usePolarCoordinates && !machineState.usePolarInterpolation) {
                setWorkPlane(abc);
            }
        }
    } else { // pure 3D
        var remaining = _section.workPlane;
        if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
            error(localize("Tool orientation is not supported by the CNC machine."));
            return abc;
        }
        setRotation(remaining);
    }
    if (abc !== undefined) {
        if (_setWorkPlane) {
            if (!_section.isMultiAxis()) {
                cOutput.format(abc.z); // make C current - we do not want to output here
            }
        }
    }
    return abc;
}

function setWorkPlane(abc) {
    if (!machineConfiguration.isMultiAxisConfiguration()) {
        return; // ignore
    }

    if (!((currentWorkPlaneABC == undefined) ||
        abcFormat.areDifferent(abc.x, currentWorkPlaneABC.x) ||
        abcFormat.areDifferent(abc.y, currentWorkPlaneABC.y) ||
        abcFormat.areDifferent(abc.z, currentWorkPlaneABC.z))) {
        return; // no change
    }

    onCommand(COMMAND_UNLOCK_MULTI_AXIS);
    gMotionModal.reset();

    writeBlock(
        gMotionModal.format(0),
        conditional(machineConfiguration.isMachineCoordinate(0), aOutput.format(abc.x)),
        conditional(machineConfiguration.isMachineCoordinate(1), bOutput.format(getB(abc, currentSection))),
        conditional(machineConfiguration.isMachineCoordinate(2) && machineState.cAxisIsEngaged, cOutput.format(abc.z))
    );

    if (gotBAxis) {
        writeBlock("ROT");
        writeBlock("AROT Y" + abcFormat.format(abc.y));
    }

    if (!currentSection.isMultiAxis() && !machineState.usePolarInterpolation && !machineState.usePolarCoordinates) {
        if (machineState.cAxisIsEngaged) {
            onCommand(COMMAND_LOCK_MULTI_AXIS);
        }
    }

    currentWorkPlaneABC = new Vector(abc);
    setCurrentDirection(abc);
}

function getBestABC(section) {
    // try workplane orientation
    var abc = section.getABCByPreference(machineConfiguration, section.workPlane, getCurrentDirection(), C, PREFER_CLOSEST, ENABLE_ALL);
    if (section.doesToolpathFitWithinLimits(machineConfiguration, abc)) {
        return abc;
    }
    var currentABC = new Vector(abc);

    // quadrant boundaries are the preferred solution
    var quadrants = [0, 90, 180, 270];
    for (var i = 0; i < quadrants.length; ++i) {
        abc.setZ(toRad(quadrants[i]));
        if (section.doesToolpathFitWithinLimits(machineConfiguration, abc)) {
            abc = machineConfiguration.remapToABC(abc, currentABC);
            abc = machineConfiguration.remapABC(abc);
            return abc;
        }
        //writeComment("STEP="+toDeg(abc.z))
    }

    // attempt to find soultion at fixed angle rotations
    var maxTries = 60; // every 6 degrees
    var delta = (Math.PI * 2) / maxTries;
    var angle = delta;
    for (var i = 0; i < (maxTries - 1); i++) {
        abc.setZ(angle);
        if (section.doesToolpathFitWithinLimits(machineConfiguration, abc)) {
            abc = machineConfiguration.remapToABC(abc, currentABC);
            abc = machineConfiguration.remapABC(abc);
            return abc;
        }
        //writeComment("ABCZ INCR="+ toDeg(abc.z))
        angle += delta;
    }

    //writeComment("BEST ABCZ="+ toDeg(abc.z))
    return abc;
}

function getWorkPlaneMachineABC(section, workPlane) {
    var W = workPlane; // map to global frame

    var abc;
    if (machineState.isTurningOperation && gotBAxis) {
        var both = machineConfiguration.getABCByDirectionBoth(workPlane.forward);
        abc = both[0];
        if (both[0].z != 0) {
            abc = both[1];
        }
    } else {
        abc = bestABC ? bestABC :
            section.getABCByPreference(machineConfiguration, W, getCurrentDirection(), C, PREFER_CLOSEST, ENABLE_RESET);
    }

    var direction = machineConfiguration.getDirection(abc);
    if (!isSameDirection(direction, W.forward)) {
        error(localize("Orientation not supported."));
    }

    if (machineState.isTurningOperation && gotBAxis && !bAxisIsManual) { // remapABC can change the B-axis orientation
        if (abc.z != 0) {
            error(localize("Could not calculate a B-axis turning angle within the range of the machine."));
        }
    }

    var tcp = false;
    if (tcp) {
        setRotation(W); // TCP mode
    } else {
        var O = machineConfiguration.getOrientation(abc);
        var R = machineConfiguration.getRemainingOrientation(abc, W);
        setRotation(R);
    }

    if (machineState.usePolarCoordinates) { // set C-axis to initial polar coordinate position
        var initialPosition = getFramePosition(section.getInitialPosition());
        var polarPosition = getPolarCoordinates(initialPosition, abc);
        abc.setZ(polarPosition.second.z);
    }
    return abc;
}

var bAxisOrientationTurning = new Vector(0, 0, 0);

function setSpindleOrientationTurning() {
    var J; // cutter orientation
    var R; // cutting quadrant
    var leftHandTool = (hasParameter("operation:tool_hand") && (getParameter("operation:tool_hand") == "L" || getParameter("operation:tool_holderType") == 0));
    if (hasParameter("operation:machineInside")) {
        if (getParameter("operation:machineInside") == 0) {
            R = currentSection.spindle == SPINDLE_PRIMARY ? 3 : 4;
        } else {
            R = currentSection.spindle == SPINDLE_PRIMARY ? 2 : 1;
        }
    } else {
        if ((hasParameter("operation-strategy") && getParameter("operation-strategy") == "turningFace") ||
            (hasParameter("operation-strategy") && getParameter("operation-strategy") == "turningPart")) {
            R = currentSection.spindle == SPINDLE_PRIMARY ? 3 : 4;
        } else {
            error(subst(localize("Failed to identify spindle orientation for operation \"%1\"."), getOperationComment()));
            return;
        }
    }
    if (leftHandTool) {
        J = currentSection.spindle == SPINDLE_PRIMARY ? 2 : 1;
    } else {
        J = currentSection.spindle == SPINDLE_PRIMARY ? 1 : 2;
    }
    writeComment("Post processor is not customized, add code for cutter orientation and cutting quadrant here if needed.");
}

function getBAxisOrientationTurning() {
    var toolAngle = hasParameter("operation:tool_angle") ? getParameter("operation:tool_angle") : 0;
    var toolOrientation = section.toolOrientation;
    if (toolAngle && toolOrientation != 0) {
        // error(localize("You cannot use tool angle and tool orientation together in operation " + "\"" + (getParameter("operation-comment")) + "\""));
    }

    var angle = toRad(toolAngle) + toolOrientation;

    var axis = new Vector(0, 1, 0);
    var mappedAngle;
    if (bAxisIsManual) {
        mappedAngle = 0; // manual b-axis used for milling only
    } else {
        mappedAngle = (currentSection.spindle == SPINDLE_PRIMARY ? (Math.PI / 2 - angle) : (Math.PI / 2 - angle));
    }
    var mappedWorkplane = new Matrix(axis, mappedAngle);
    var abc = getWorkPlaneMachineABC(section, mappedWorkplane);
    return abc;
}

function getSpindle(whichSpindle) {
    // safety conditions
    if (getNumberOfSections() == 0) {
        return SPINDLE_MAIN;
    }
    if (getCurrentSectionId() < 0) {
        if (machineState.liveToolIsActive && (whichSpindle == TOOL)) {
            return SPINDLE_LIVE;
        } else {
            return getSection(getNumberOfSections() - 1).spindle;
        }
    }

    // Turning is active or calling routine requested which spindle part is loaded into
    if (machineState.isTurningOperation || machineState.axialCenterDrilling || (whichSpindle == PART)) {
        return currentSection.spindle;
        //Milling is active
    } else {
        return SPINDLE_LIVE;
    }
}

function invertAxes(activate, polarMode) {
    var scaleValue = reverseAxes ? -1 : 1;
    var yIsEnabled = yOutput.isEnabled();
    yFormat.setScale(activate ? scaleValue : 1);
    yOutput.setFormat(yFormat);

    if (polarMode) {
        cOutput.disable();
    } else {
        if (activate) {
            cOutput.setPrefix(subSpindleAxisName[0]);
        } else {
            cOutput.setPrefix(mainSpindleAxisName[0]);
        }
        if (!yIsEnabled) {
            yOutput.disable();
        }
    }
    jOutput.setFormat(yFormat);
}

/** determines if the axes in the given plane are mirrored */
function isMirrored(plane) {
    plane = plane == -1 ? getCompensationPlane(getCurrentDirection(), false, false) : plane;
    switch (plane) {
        case PLANE_XY:
            if ((xFormat.getScale() * yFormat.getScale()) < 0) {
                return true;
            }
            break;
        case PLANE_YZ:
            if ((yFormat.getScale() * zFormat.getScale()) < 0) {
                return true;
            }
            break;
        case PLANE_ZX:
            if ((zFormat.getScale() * xFormat.getScale()) < 0) {
                return true;
            }
            break;
    }
    return false;
}

function subprogramDefine(_initialPosition, _abc, _retracted, _zIsOutput) {
    // convert patterns into subprograms
    var usePattern = false;
    patternIsActive = false;
    if (currentSection.isPatterned && currentSection.isPatterned() && false /*(getProperty("useSubroutines") == "patterns")*/) {
        currentPattern = currentSection.getPatternId();
        firstPattern = true;
        for (var i = 0; i < definedPatterns.length; ++i) {
            if ((definedPatterns[i].patternType == SUB_PATTERN) && (currentPattern == definedPatterns[i].patternId)) {
                currentSubprogram = definedPatterns[i].subProgram;
                usePattern = definedPatterns[i].validPattern;
                firstPattern = false;
                break;
            }
        }

        if (firstPattern) {
            // determine if this is a valid pattern for creating a subprogram
            usePattern = subprogramIsValid(currentSection, currentPattern, SUB_PATTERN);
            if (usePattern) {
                currentSubprogram = ++lastSubprogram;
            }
            definedPatterns.push({
                patternType: SUB_PATTERN,
                patternId: currentPattern,
                subProgram: currentSubprogram,
                validPattern: usePattern,
                initialPosition: _initialPosition,
                finalPosition: _initialPosition
            });
        }

        if (usePattern) {
            // make sure Z-position is output prior to subprogram call
            if (!_retracted && !_zIsOutput) {
                writeBlock(gMotionModal.format(0), zOutput.format(_initialPosition.z));
            }

            // call subprogram
            subprogramCall();
            patternIsActive = true;

            if (firstPattern) {
                subprogramStart(_initialPosition, _abc, true);
            } else {
                skipRemainingSection();
                setCurrentPosition(getFramePosition(currentSection.getFinalPosition()));
            }
        }
    }

    // Output cycle operation as subprogram


    // Output each operation as a subprogram
    if (!usePattern && (getProperty("useSubroutines") == "allOperations")) {
        currentSubprogram = ++lastSubprogram;
        // writeBlock("REPEAT LABEL" + currentSubprogram + " LABEL0");
        subprogramCall();
        firstPattern = true;
        subprogramStart(_initialPosition, _abc, false);
    }
}

function subprogramStart(_initialPosition, _abc, _incremental) {
    var comment = "";
    if (hasParameter("operation-comment")) {
        comment = getParameter("operation-comment");
    }

    if (getProperty("useFilesForSubprograms")) {
        // used if external files are used for subprograms
        var subprogram = "sub" + String(programName).substr(0, Math.min(programName.length, 20)) + currentSubprogram; // set the subprogram name



        var path = FileSystem.getCombinedPath(FileSystem.getFolderPath(getOutputPath()), subprogram + "." + subprogramExtension); // set the output path for the subprogram(s)
        redirectToFile(path); // redirect output to the new file (defined above)
        writeln("; %_N_" + translateText(String(subprogram).toUpperCase(), " ", "_") + "_SPF"); // add the program name to the first line of the newly created file
    } else {
        // used if subroutines are contained within the same file
        redirectToBuffer();
        writeln(
            "LABEL" + currentSubprogram + ":" +
            conditional(comment, formatComment(comment.substr(0, maximumLineLength - 2 - 6 - 1)))
        ); // output the subroutine name as the first line of the new file
    }

    saveShowSequenceNumbers = getProperty("showSequenceNumbers");
    setProperty("showSequenceNumbers", "false"); // disable sequence numbers for subprograms
    if (_incremental) {
        setIncrementalMode(_initialPosition, _abc);
    }
    gPlaneModal.reset();
    gMotionModal.reset();
}

function subprogramCall() {
    if (hasParameter("operation-comment")) {
        var comment = getParameter("operation-comment");
        if (comment) {
            writeln("");
            writeBlock("MSG (" + "\"" + formatComment(comment) + "\"" + ")");
        }
    }
    if (getProperty("useFilesForSubprograms")) {
        var subprogram = "sub" + String(programName).substr(0, Math.min(programName.length, 20)) + currentSubprogram; // set the subprogram name
        var callType = "SPF CALL";
        writeBlock(subprogram + " ;", callType); // call subprogram
    } else {
        writeBlock("CALL BLOCK LABEL" + currentSubprogram + " TO LABEL0");
    }
}

function subprogramEnd() {
    if (firstPattern) {
        if (!getProperty("useFilesForSubprograms")) {
            writeBlock("LABEL0:"); // sets the end block of the subroutine
            writeln("");
            subprograms += getRedirectionBuffer();
        } else {
            writeBlock(mFormat.format(17)); // close the external subprogram with M17
        }
    }
    forceModals();
    forceAny();
    firstPattern = false;
    setProperty("showSequenceNumbers", saveShowSequenceNumbers);
    closeRedirection();
}

function onSectionSpecialCycle() {
    if (!isFirstSection()) {
        activateMachine(currentSection);
    }
}

function onSection() {
    //check if tool fits in machine axis
    //var range = section.getOptimizedBoundingBox(machineConfiguration, machineConfiguration.getABC(section.workPlane));
    //var xMax = range.upper.x
    //var xMin =range.lower.x

    //var machRangeX = machineConfiguration.getAxisU().getRange()
    //var machRangeXUpper = machRangeX.upper.x
    //writeComment("SectionRangeX:" , xMax, xMin)
    //writeComment("MachineXRange:", machRangeX )


    //var yAxisWithinLimits = machineConfiguration.getAxisY().getRange().isWithin(yFormat.getResultingValue(range.lower.y)) &&
    //    machineConfiguration.getAxisY().getRange().isWithin(yFormat.getResultingValue(range.upper.y));

    // ---------------------------------------------------------------------------
    // First-section header: write the JOB INFO + TOOLS table block once.
    // ---------------------------------------------------------------------------
    if (isFirstSection()) {
        myBufferdOpen();
    }

    // ---------------------------------------------------------------------------
    // Open a Sinumerik program-structure GROUP for this operation.
    // The matching GROUP_END is written in onSectionEnd().
    // ---------------------------------------------------------------------------
    var _opNameForGroup = getOperationComment();
    if (!_opNameForGroup) {
        _opNameForGroup = hasParameter("operation-comment") ? getParameter("operation-comment") : "";
    }
    if (!_opNameForGroup) {
        _opNameForGroup = "SECTION";
    }
    var _toolForGroup = currentSection.getTool();
    var _groupName = appendInwUitw(getDutchOpName(_opNameForGroup, _toolForGroup), _toolForGroup);
    _groupName = String(_groupName).replace(/"/g, "'");
    writeln("GROUP_BEGIN(0,\"" + _groupName + "\",0,0)");

    //writeln("")
    //writeln("")
    writeln("")
    writeln("R18=ATAN2(((R16-R15)/2),R17)");
    if (getProperty(properties._01_isBroaching)) { machineState.isBroachingOperation = true; } else { machineState.isBroachingOperation = false; }

    machineState.isVariThreadOperation = getProperty(properties._10_variThread) &&
        hasParameter("operation-strategy") && (getParameter("operation-strategy") == "turningThread");
    if (machineState.isVariThreadOperation) { variThread.start(); } else { variThread.stop(); }


    // Detect machine configuration
    var currentTurret = isFirstSection() ? activeTurret : activateMachine(currentSection);

    // Define Machining modes
    tapping = isTappingCycle();

    var forceSectionRestart = optionalSection && !currentSection.isOptional();
    optionalSection = currentSection.isOptional();
    bestABC = undefined;
    setCurrentDirection(isFirstSection() ? new Vector(0, 0, 0) : getCurrentDirection());

    machineState.isTurningOperation = (currentSection.getType() == TYPE_TURNING);
    if (machineState.isTurningOperation && gotBAxis) {
        bAxisOrientationTurning = getBAxisOrientationTurning(currentSection);
    }

    var insertToolCall = isToolChangeNeeded(toolAsName ? "description" : "number",
        "compensationOffset", "diameterOffset", "lengthOffset") || forceSectionRestart;
    var newWorkOffset = isNewWorkOffset() || forceSectionRestart;
    var newWorkPlane = isNewWorkPlane() || forceSectionRestart ||
        (machineState.isTurningOperation &&
            abcFormat.areDifferent(bAxisOrientationTurning.x, machineState.currentBAxisOrientationTurning.x) ||
            abcFormat.areDifferent(bAxisOrientationTurning.y, machineState.currentBAxisOrientationTurning.y) ||
            abcFormat.areDifferent(bAxisOrientationTurning.z, machineState.currentBAxisOrientationTurning.z));
    retracted = false; // specifies that the tool has been retracted to the safe plane
    var zIsOutput = true; // true if the Z-position has been output, used for patterns

    partCutoff = getParameter("operation-strategy", "") == "turningPart";

    updateMachiningMode(currentSection); // sets the needed machining mode to machineState (usePolarInterpolation, usePolarCoordinates, axialCenterDrilling)

    // --- START: FEED & SPEED LIMIT CALCULATION ---
    gFeedReduction = 1.0; // Reset to 100%

    // 1. Determine the Limit (4000 for Live Tools, Property for Turning)
    // Now that updateMachiningMode is called, getSpindle(TOOL) works correctly
    var activeSpindleId = getSpindle(TOOL);
    var machineLimit;

    if (activeSpindleId == SPINDLE_LIVE) {
        machineLimit = 4000; // Hard limit for live tools
    } else {
        machineLimit = getProperty("maximumSpindleSpeed");
    }

    // 2. Determine Tool Limit (Lower of Tool data or Machine Limit)
    var limit = (tool.maximumSpindleSpeed > 0) ? Math.min(tool.maximumSpindleSpeed, machineLimit) : machineLimit;

    // 3. Clamp Spindle and Calculate Feed Ratio
    // Only apply if NOT in G96 (Surface Speed) mode
    if (currentSection.getTool().getSpindleMode() != SPINDLE_CONSTANT_SURFACE_SPEED) {
        if (spindleSpeed > limit) {
            // If we are in Feed Per Minute (G94), we must reduce feed
            if (currentSection.feedMode != FEED_PER_REVOLUTION) {
                gFeedReduction = limit / spindleSpeed;
            }
            // Overwrite the system spindleSpeed variable so subsequent functions use the clamped value
            spindleSpeed = limit;
        }
    }
    // --- END: FEED & SPEED LIMIT CALCULATION ---



    if (toolAsName && !tool.description) {
        if (hasParameter("operation-comment")) {
            error(localize("Tool description is empty in operation " + "\"" + (getParameter("operation-comment").toUpperCase()) + "\""));
        } else {
            error(localize("Tool description is empty."));
        }
        return;
    }

    // Get the active spindle
    var newSpindle = true;
    var tempSpindle = getSpindle(TOOL);
    if (isFirstSection()) {
        previousSpindle = tempSpindle;
    }
    newSpindle = tempSpindle != previousSpindle;

    // define subprogram
    subprogramDefine(initialPosition, abc, retracted, zIsOutput);

    // End the previous section if a new tool is selected
    if (insertToolCall || newSpindle || newWorkOffset || newWorkPlane && !currentSection.isPatterned()) {
        if (insertToolCall) {
            onCommand(COMMAND_COOLANT_OFF);
        }
        writeRetract(currentSection, true)
    }

    if (!isFirstSection() && (newSpindle || (insertToolCall && previousSpindle == SPINDLE_LIVE))) {
        writeBlock(getCode("STOP_SPINDLE", previousSpindle));
        previousSpindle == SPINDLE_LIVE ? onCommand(COMMAND_UNLOCK_MULTI_AXIS) : null;
    }

    // Consider part cutoff as stockTransfer operation
    if (!(machineState.stockTransferIsActive && partCutoff)) {
        machineState.stockTransferIsActive = false;
    }

    writeln("");

    if (!(getProperty("useSubroutines") == "allOperations")) {
        if (hasParameter("operation-comment")) {
            var comment = getParameter("operation-comment");
            if (comment) {
                writeBlock("MSG (" + "\"" + formatComment(comment) + "\"" + ")");
            }
        }
    }
    if (tool.description) {
        writeComment(tool.description);
    }

    // invert axes for secondary spindle
    invertAxes(getSpindle(PART) == SPINDLE_SUB, false); // polar mode has not been enabled yet

    if (getProperty("showNotes") && hasParameter("notes")) {
        var notes = getParameter("notes");
        if (notes) {
            var lines = String(notes).split("\n");
            var r1 = new RegExp("^[\\s]+", "g");
            var r2 = new RegExp("[\\s]+$", "g");
            for (line in lines) {
                var comment = lines[line].replace(r1, "").replace(r2, "");
                if (comment) {
                    writeComment(comment);
                }
            }
        }
    }

    if (machineState.stockTransferIsActive) {
        return; // skip onSection(), continue in onCycle()
    }

    if (insertToolCall || forceMyToolChange) {
        forceWorkPlane();
        cAxisEngageModal.reset();
        onCommand(COMMAND_COOLANT_OFF);
        if (!isFirstSection() && getProperty("optionalStop")) {
            onCommand(COMMAND_OPTIONAL_STOP);
        }

        writeToolBlock("T" + (toolAsName ? "=" + "\"" + (tool.description.toUpperCase()) + "\"" : toolFormat.format(tool.number)));
        writeBlock("TC(1)");
        writeBlock(dFormat.format(1))

        activeTurret = currentTurret;
    }

    if (machineState.isTurningOperation) {
        writeBlock("DIAMON");
        if (gotBAxis) {
            writeBlock("ROT");
        }
        xFormat.setScale(2); // diameter mode
        xOutput.setFormat(xFormat);
        writeln("R18=ATAN2(((R16-R15)/2),R17)");
        writeBlock("$P_PFRAME=CROT(Y,R18)")
    } else {
        writeBlock("DIAMOF");
        xFormat.setScale(1); // radius mode
        xOutput.setFormat(xFormat);
    }

    // command stop for manual tool change, useful for quick change live tools
    if (insertToolCall && tool.manualToolChange) {
        onCommand(COMMAND_STOP);
        writeComment("MANUAL TOOL CHANGE TO T" + (toolAsName ? "=" + "\"" + (tool.description.toUpperCase()) + "\"" : toolFormat.format(tool.number * 100 + compensationOffset)) + ")");
    }

    if (newSpindle) {
        // select spindle if required
    }

    sOutput.reset(); // force spindle speeds

    // Engage tailstock
    if (getProperty("useTailStock")) {
        if (machineState.axialCenterDrilling || (currentSection.spindle == SPINDLE_SECONDARY) ||
            (machineState.liveToolIsActive && (machineState.machiningDirection == MACHINING_DIRECTION_AXIAL))) {
            if (currentSection.tailstock) {
                warning(localize("Tail stock is not supported for secondary spindle or Z-axis milling."));
            }
            if (machineState.tailstockIsActive) {
                writeBlock(getCode("TAILSTOCK_OFF"));
            }
        } else {
            writeBlock(currentSection.tailstock ? getCode("TAILSTOCK_ON") : getCode("TAILSTOCK_OFF"));
        }
    }

    var forceRPMMode = false;
    var spindleChanged = tool.type != TOOL_PROBE && ((insertToolCall || forceSpindleSpeed || isSpindleSpeedDifferent() || newSpindle) && !machineState.isBroachingOperation);
    if (spindleChanged) {
        forceSpindleSpeed = false;
        if (machineState.isTurningOperation) {
            if (spindleSpeed > 99999) {
                warning(subst(localize("Spindle speed exceeds maximum value for operation \"%1\"."), getOperationComment()));
            }
        } else {
            if (spindleSpeed > 6000) {
                warning(subst(localize("Spindle speed exceeds maximum value for operation \"%1\"."), getOperationComment()));
            }
        }
        forceRPMMode = tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED;
        startSpindle(true, getFramePosition(currentSection.getInitialPosition()));
    }

    // wcs
    if (insertToolCall) { // force work offset when changing tool
        currentWorkOffset = undefined;
        forceModals();
    }

    // Get active feedrate mode
    var feedMode = formatFeedMode(currentSection.feedMode);

    // Output modal commands here
    writeBlock(gPlaneModal.format(getPlane()), gAbsIncModal.format(90), feedMode);

    writeWCS(currentSection);

    if (debug) { writeComment("Write WCS") }

    if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
        writeBlock(conditional(machineState.cAxisIsEngaged || machineState.cAxisIsEngaged == undefined), getCode("DISABLE_C_AXIS", getSpindle(PART)));
    } else { // milling
        writeBlock(conditional(!machineState.cAxisIsEngaged || machineState.cAxisIsEngaged == undefined), getCode("ENABLE_C_AXIS", getSpindle(PART)));
    }

    var maximumSpindleSpeed = (tool.maximumSpindleSpeed > 0) ? Math.min(tool.maximumSpindleSpeed, getProperty("maximumSpindleSpeed")) : getProperty("maximumSpindleSpeed");
    if ((maximumSpindleSpeed > 0) && (currentSection.getTool().getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED)) {
        writeBlock("LIMS[" + getSpindleCode(currentSection) + "]=" + rpmFormat.format(maximumSpindleSpeed));
    }


    gMotionModal.reset();

    var abc = defineWorkPlane(currentSection, true);

    forceAny();

    gMotionModal.reset();

    if (machineState.cAxisIsEngaged) { // make sure C-axis in engaged
        if (!machineState.usePolarInterpolation && !machineState.usePolarCoordinates && !currentSection.isMultiAxis()) {
            onCommand(COMMAND_LOCK_MULTI_AXIS);
        } else {
            onCommand(COMMAND_UNLOCK_MULTI_AXIS);
        }
        if (debug) { writeComment("Engage C-axis") }
    }

    if (machineState.usePolarInterpolation) {
        if (debug) { writeComment("Enable polar interpolation") }
        setPolarInterpolation(true); // enable polar interpolation mode

    }

    // set coolant after we have positioned at Z
    setCoolant(tool.coolant);

    // enable Polar coordinates mode
    if (machineState.usePolarCoordinates && (tool.type != TOOL_PROBE)) {
        if (polarCoordinatesDirection == undefined) {
            error(localize("Polar coordinates axis direction to maintain must be defined as a vector - x,y,z."));
            return;
        }
        setPolarCoordinates(true);
    }


    var initialPosition = getFramePosition(currentSection.getInitialPosition());
    if (currentSection.isMultiAxis()) {
        forceABC();
        forceWorkPlane();
        cancelTransformation();
        // turn machine
        // writeBlock("TRANS_5A(" + (currentSection.spindle == SPINDLE_PRIMARY ? mainSpindleAxisName[1] :  subSpindleAxisName[1]) + "," + "\"" + "BC" + "\"" + ")");
        if (debug) { writeComment("Multiaxis prepos") }
        writeBlock(gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), zOutput.format(initialPosition.z), aOutput.format(abc.x), bOutput.format(getB(abc, currentSection)), cOutput.format(abc.z));
    } else {

        if ((insertToolCall || retracted || forceMyToolChange || machineState.tailstockIsActive) && !(machineState.isBroachingOperation)) {
            gMotionModal.reset();
            if (machineState.usePolarCoordinates) {
                var polarPosition = getPolarCoordinates(initialPosition, abc);
                if (debug) { writeComment("polar prepos") }
                writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
                writeBlock(
                    gMotionModal.format(0),
                    xOutput.format(polarPosition.first.x),
                    conditional(gotYAxis, yOutput.format(polarPosition.first.y)),
                    cOutput.format(polarPosition.second.z)
                );
            } else {
                if (debug) { writeComment("Normal prepos") }
                if (machineState.isTurningOperation) {
                    writeBlock(gMotionModal.format(0), yOutput.format(initialPosition.y), zOutput.format(initialPosition.z));
                    writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z), xOutput.format(initialPosition.x));
                } else {
                    writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
                    writeBlock(gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y));
                }
            }
        } else if (machineState.usePolarCoordinates && !getProperty(properties._01_isBroaching)) {
            var polarPosition = getPolarCoordinates(initialPosition, abc);
            if (debug) { writeComment("polar broaching prepos") }
            writeBlock(gMotionModal.format(0), cOutput.format(polarPosition.second.z));
        }
    }




    // enable SFM spindle speed
    if (forceRPMMode) {
        startSpindle(false);
    }

    if (getProperty("useParametricFeed") &&
        hasParameter("operation-strategy") &&
        (getParameter("operation-strategy") != "drill") && // legacy
        !(currentSection.hasAnyCycle && currentSection.hasAnyCycle())) {
        if (!insertToolCall &&
            activeMovements &&
            (getCurrentSectionId() > 0) &&
            ((getPreviousSection().getPatternId() == currentSection.getPatternId()) && (currentSection.getPatternId() != 0))) {
            // use the current feeds
        } else {
            initializeActiveFeeds();
        }
    } else {
        activeMovements = undefined;
    }

    previousSpindle = tempSpindle;
    activeSpindle = tempSpindle;

    if (false) { // DEBUG
        for (var key in machineState) {
            writeComment(key + " : " + machineState[key]);
        }
        writeComment((getMachineConfigurationAsText(machineConfiguration)));
    }

    if (!getProperty(properties._01_isBroaching)) {
        initializeSmoothing(); // initialize smoothing mode
        smoothing.force = insertToolCall && (getProperty("useSmoothing") != "-1");
        setSmoothing(smoothing.isAllowed); // writes the required smoothing codes
    }


    if (debug) {
        writeComment("Debugging information:");
        writeComment("End of OnSection()")
    }
}

// <<<<< INCLUDED FROM include_files/coolant.cpi
// >>>>> INCLUDED FROM include_files/smoothing.cpi
// collected state below, do not edit
validate(settings.smoothing, "Setting 'smoothing' is required but not defined.");
var smoothing = {
    cancel: false, // cancel tool length prior to update smoothing for this operation
    isActive: false, // the current state of smoothing
    isAllowed: false, // smoothing is allowed for this operation
    isDifferent: false, // tells if smoothing levels/tolerances/both are different between operations
    level: -1, // the active level of smoothing
    tolerance: -1, // the current operation tolerance
    force: false // smoothing needs to be forced out in this operation
};

function initializeSmoothing() {
    var smoothingSettings = settings.smoothing;
    var previousLevel = smoothing.level;
    var previousTolerance = xyzFormat.getResultingValue(smoothing.tolerance);

    // format threshold parameters
    var thresholdRoughing = xyzFormat.getResultingValue(smoothingSettings.thresholdRoughing);
    var thresholdSemiFinishing = xyzFormat.getResultingValue(smoothingSettings.thresholdSemiFinishing);
    var thresholdFinishing = xyzFormat.getResultingValue(smoothingSettings.thresholdFinishing);

    // determine new smoothing levels and tolerances
    smoothing.level = parseInt(getProperty("useSmoothing"), 10);
    smoothing.level = isNaN(smoothing.level) ? -1 : smoothing.level;
    smoothing.tolerance = xyzFormat.getResultingValue(Math.max(getParameter("operation:tolerance", thresholdFinishing), 0));

    if (smoothing.level == 9999) {
        if (smoothingSettings.autoLevelCriteria == "stock") { // determine auto smoothing level based on stockToLeave
            var stockToLeave = xyzFormat.getResultingValue(getParameter("operation:stockToLeave", 0));
            var verticalStockToLeave = xyzFormat.getResultingValue(getParameter("operation:verticalStockToLeave", 0));
            if (((stockToLeave >= thresholdRoughing) && (verticalStockToLeave >= thresholdRoughing)) || getParameter("operation:strategy", "") == "face") {
                smoothing.level = smoothingSettings.roughing; // set roughing level
            } else {
                if (((stockToLeave >= thresholdSemiFinishing) && (stockToLeave < thresholdRoughing)) &&
                    ((verticalStockToLeave >= thresholdSemiFinishing) && (verticalStockToLeave < thresholdRoughing))) {
                    smoothing.level = smoothingSettings.semi; // set semi level
                } else if (((stockToLeave >= thresholdFinishing) && (stockToLeave < thresholdSemiFinishing)) &&
                    ((verticalStockToLeave >= thresholdFinishing) && (verticalStockToLeave < thresholdSemiFinishing))) {
                    smoothing.level = smoothingSettings.semifinishing; // set semi-finishing level
                } else {
                    smoothing.level = smoothingSettings.finishing; // set finishing level
                }
            }
        } else { // detemine auto smoothing level based on operation tolerance instead of stockToLeave
            if (smoothing.tolerance >= thresholdRoughing || getParameter("operation:strategy", "") == "face") {
                smoothing.level = smoothingSettings.roughing; // set roughing level
            } else {
                if (((smoothing.tolerance >= thresholdSemiFinishing) && (smoothing.tolerance < thresholdRoughing))) {
                    smoothing.level = smoothingSettings.semi; // set semi level
                } else if (((smoothing.tolerance >= thresholdFinishing) && (smoothing.tolerance < thresholdSemiFinishing))) {
                    smoothing.level = smoothingSettings.semifinishing; // set semi-finishing level
                } else {
                    smoothing.level = smoothingSettings.finishing; // set finishing level
                }
            }
        }
    }

    if (smoothing.level == -1) { // useSmoothing is disabled
        smoothing.isAllowed = false;
    } else { // do not output smoothing for the following operations
        smoothing.isAllowed = !(currentSection.getTool().type == TOOL_PROBE || isDrillingCycle());
    }
    if (!smoothing.isAllowed) {
        smoothing.level = -1;
        smoothing.tolerance = -1;
    }

    switch (smoothingSettings.differenceCriteria) {
        case "level":
            smoothing.isDifferent = smoothing.level != previousLevel;
            break;
        case "tolerance":
            smoothing.isDifferent = smoothing.tolerance != previousTolerance;
            break;
        case "both":
            smoothing.isDifferent = smoothing.level != previousLevel || smoothing.tolerance != previousTolerance;
            break;
        default:
            error(localize("Unsupported smoothing criteria."));
            return;
    }

    // tool length compensation needs to be canceled when smoothing state/level changes
    if (smoothingSettings.cancelCompensation) {
        smoothing.cancel = !isFirstSection() && smoothing.isDifferent;
    }
}



var MACHINING_DIRECTION_AXIAL = 0;
var MACHINING_DIRECTION_RADIAL = 1;
var MACHINING_DIRECTION_INDEXING = 2;

function getMachiningDirection(section) {
    var forward = section.workPlane.forward;
    if (section.isMultiAxis()) {
        forward = section.getGlobalInitialToolAxis();
        forward = Math.abs(forward.z) < 1e-7 ? new Vector(1, 0, 0) : forward; // radial multi-axis operation
    }
    if (isSameDirection(forward, new Vector(0, 0, 1))) {
        return MACHINING_DIRECTION_AXIAL;
    } else if (Vector.dot(forward, new Vector(0, 0, 1)) < 1e-7) {
        return MACHINING_DIRECTION_RADIAL;
    } else {
        return MACHINING_DIRECTION_INDEXING;
    }
}

function updateMachiningMode(section) {
    machineState.axialCenterDrilling = false; // reset
    machineState.usePolarInterpolation = false; // reset
    machineState.usePolarCoordinates = false; // reset

    machineState.machiningDirection = getMachiningDirection(section);

    if ((section.getType() == TYPE_MILLING) && !section.isMultiAxis()) {
        if (machineState.machiningDirection == MACHINING_DIRECTION_AXIAL) {
            if (isDrillingCycle(section, false)) {
                // drilling axial
                machineState.axialCenterDrilling = isAxialCenterDrilling(section, true);
                if (!machineState.axialCenterDrilling && !isAxialCenterDrilling(section, false)) { // several holes not on XY center
                    // bestABC = section.getABCByPreference(machineConfiguration, section.workPlane, getCurrentDirection(), C, PREFER_CLOSEST, ENABLE_RESET | ENABLE_LIMITS);
                    bestABC = getBestABC(section);
                    bestABC = section.doesToolpathFitWithinLimits(machineConfiguration, bestABC) ? bestABC : undefined;
                    if (!getProperty("useYAxisForDrilling") || bestABC == undefined) {
                        machineState.usePolarCoordinates = true;
                    }
                }
            } else { // milling
                // Use new operation property for polar milling
                if (currentSection.machiningType && (currentSection.machiningType == MACHINING_TYPE_POLAR)) {
                    // Choose correct polar mode depending on machine capabilities
                    if (gotPolarInterpolation && !forcePolarCoordinates) {
                        forcePolarInterpolation = true;
                    } else {
                        forcePolarCoordinates = true;
                    }

                    // Update polar coordinates direction according to operation property
                    polarCoordinatesDirection = currentSection.polarDirection;
                }
                if (gotPolarInterpolation && forcePolarInterpolation) { // polar mode is requested by user
                    machineState.usePolarInterpolation = true;
                    bestABC = undefined;
                } else if (forcePolarCoordinates) { // Polar coordinate mode is requested by user
                    machineState.usePolarCoordinates = true;
                    bestABC = undefined;
                } else {
                    //bestABC = section.getABCByPreference(machineConfiguration, section.workPlane, getCurrentDirection(), C, PREFER_CLOSEST, ENABLE_RESET | ENABLE_LIMITS);
                    bestABC = getBestABC(section);
                    bestABC = section.doesToolpathFitWithinLimits(machineConfiguration, bestABC) ? bestABC : undefined;
                    if (bestABC == undefined) { // toolpath does not match XY ranges, enable interpolation mode
                        if (gotPolarInterpolation) {
                            machineState.usePolarInterpolation = true;
                        } else {
                            machineState.usePolarCoordinates = true;
                        }
                    }
                }
            }
        } else if (machineState.machiningDirection == MACHINING_DIRECTION_RADIAL) { // G19 plane
            var range = section.getOptimizedBoundingBox(machineConfiguration, machineConfiguration.getABC(section.workPlane));
            var yAxisWithinLimits = machineConfiguration.getAxisY().getRange().isWithin(yFormat.getResultingValue(range.lower.y)) &&
                machineConfiguration.getAxisY().getRange().isWithin(yFormat.getResultingValue(range.upper.y));
            if (!gotYAxis) {
                if (!section.isMultiAxis() && !yAxisWithinLimits) {
                    error(subst(localize("Y-axis motion is not possible without a Y-axis for operation \"%1\"."), getOperationComment()));
                    return;
                }
            } else {
                if (!yAxisWithinLimits) {
                    error(subst(localize("Toolpath exceeds the maximum ranges for operation \"%1\"."), getOperationComment()));
                    return;
                }
            }
            // C-coordinates come from setWorkPlane or is within a multi axis operation, we cannot use the C-axis for non wrapped toolpathes (only multiaxis works, all others have to be into XY range)
        } else {
            // usePolarCoordinates & usePolarInterpolation is only supported for axial machining, keep false
        }
    } else {
        // turning or multi axis, keep false
    }

    if (machineState.axialCenterDrilling) {
        cOutput.disable();
    } else {
        cOutput.enable();
    }

    var checksum = 0;
    checksum += machineState.usePolarInterpolation ? 1 : 0;
    checksum += machineState.usePolarCoordinates ? 1 : 0;
    checksum += machineState.axialCenterDrilling ? 1 : 0;
    validate(checksum <= 1, localize("Internal post processor error."));
}

function getPlane() {
    if (machineState.machiningDirection == MACHINING_DIRECTION_AXIAL) { // axial
        if (machineState.isTurningOperation) {
            return 18; // turning
        } else {
            return 17; // milling
        }
    } else if (machineState.machiningDirection == MACHINING_DIRECTION_RADIAL) { // radial
        return 19; // YZ plane
    } else if (machineState.machiningDirection == MACHINING_DIRECTION_INDEXING) { // radial
        return 17;
    } else {
        error(subst(localize("Unsupported machining direction for operation " + "\"" + "%1" + "\"" + "."), getOperationComment()));
        return undefined;
    }
}

function getOperationComment() {
    var operationComment = hasParameter("operation-comment") && getParameter("operation-comment");
    return operationComment;
}

function setPolarInterpolation(activate) {
    if (activate) {
        if (debug) { writeComment("Start of activate setPolarInterpolation()") }
        if (!machineState.cAxisIsEngaged) {
            writeBlock(getCode("ENABLE_C_AXIS", getSpindle(TOOL)));
        }
        if (gotYAxis) {
            writeBlock(gMotionModal.format(0), yOutput.format(0));
        }
        yOutput.reset();
        cOutput.enable();
        writeBlock(gMotionModal.format(0), cOutput.format(0)); // set C-axis to 0 to avoid polar interpolation issues

        writeBlock(getCode("POLAR_INTERPOLATION_ON", getSpindle(PART))); // command for polar interpolation
        writeBlock(gPlaneModal.format(getPlane()));
        if (getSpindle(PART) == SPINDLE_SUB) {
            invertAxes(true, true);
        } else {
            xFormat.setScale(1); // radius mode
            xOutput.setFormat(xFormat);
            yOutput.enable();
        }
        if (debug) { writeComment("End of activate setPolarInterpolation()") }
    } else {
        writeBlock(getCode("POLAR_INTERPOLATION_OFF", getSpindle(PART)));
        writeBlock("DIAMON");
        xFormat.setScale(2); // diameter mode
        xOutput.setFormat(xFormat);
        if (!gotYAxis) {
            yOutput.disable();
        }
        cOutput.reset();
        if (currentWorkPlaneABC != undefined) {
            currentWorkPlaneABC.z = Number.POSITIVE_INFINITY;
        }
    }
    if (debug) { writeComment("End of setPolarInterpolation()") }
}

/** Output block to do safe retract and/or move to home position. */


function writeRetract(section, retractZ) {
    if (gotYAxis) {
        writeBlock(gFormat.format(53), gMotionModal.format(0), "Y" + yFormat.format(getProperty("homePositionY")), "D0"); // retract
        yOutput.reset();
    }
    writeBlock(gFormat.format(53), gMotionModal.format(0), "X" + xFormat.format(getProperty("homePositionX")), "D0"); // retract
    xOutput.reset();
    if (retractZ) {
        writeBlock(gFormat.format(53), gMotionModal.format(0), "Z" + zFormat.format(getProperty("homePositionZ")), "D0"); // retract with regard to spindle
        zOutput.reset();
    }
    writeBlock(dFormat.format(1))
}


function onDwell(seconds) {
    if (seconds > 99999.999) {
        warning(localize("Dwelling time is out of range."));
    }
    milliseconds = clamp(1, seconds * 1000, 99999999);
    writeBlock(gFormat.format(4), "F" + seconds);
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
    pendingRadiusCompensation = radiusCompensation;
}

function getCompensationPlane(abc, returnCode, outputPlane) {
    var plane;
    if (machineState.isTurningOperation) {
        plane = PLANE_ZX;
    } else if (machineState.usePolarInterpolation) {
        plane = PLANE_XY;
    } else {
        var found = false;
        if (!found) {
            if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1))) {
                plane = PLANE_XY;
            } else if (Vector.dot(currentSection.workPlane.forward, new Vector(0, 0, 1)) < 1e-7) {
                plane = PLANE_YZ;
            } else {
                if (returnCode) {
                    if (machineState.machiningDirection == MACHINING_DIRECTION_AXIAL) {
                        plane = PLANE_XY;
                    } else {
                        plane = PLANE_ZX;
                    }
                } else {
                    plane = -1;
                    if (outputPlane) {
                        error(localize("Tool orientation is not supported for radius compensation."));
                        return -1;
                    }
                }
            }
        }
    }
    var code = plane == -1 ? -1 : (plane == PLANE_XY ? getG17Code() : (plane == PLANE_ZX ? 18 : 19));
    if (outputPlane) {
        writeBlock(gPlaneModal.format(code));
    }
    return returnCode ? code : plane;
}

var resetFeed = false;

function getHighfeedrate(radius) {
    if (currentSection.feedMode == FEED_PER_REVOLUTION) {
        if (toDeg(radius) <= 0) {
            radius = toPreciseUnit(0.1, MM);
        }
        var rpm = spindleSpeed; // rev/min
        if (currentSection.getTool().getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
            var O = 2 * Math.PI * radius; // in/rev
            rpm = tool.surfaceSpeed / O; // in/min div in/rev => rev/min
        }
        return highFeedrate / rpm; // in/min div rev/min => in/rev
    }
    return highFeedrate;
}

// >>> VARITHREAD CORE BEGIN - do not edit between the markers by hand.
// Pure rekenkern, zonder afhankelijkheid van de post-API, zodat test/varithread.test.js
// dit blok eruit kan snijden en tegen de echte Sandvik-programma's kan valideren.
// Afgeleid uit gemeten programma's; zie docs/analyse-sandvik-output.md.
var VariThread = (function () {
    "use strict";

    // Zijdelingse aanzethoek van de "flank with oscillation" strategie.
    // Bevestigd op 18/18 passes in M64x6 en 15/15 in M48x5.
    var INFEED_ANGLE_DEG = 29;
    var TAN_INFEED = Math.tan(INFEED_ANGLE_DEG * Math.PI / 180);

    // Radiale overmaat op de startdiameter: de oscillatie van de eerste pass
    // trekt terug naar D_nominaal + 0.1 (diameter).
    var START_OVERSIZE_DIA = 0.1;

    // Kleinste diepte-stap van de calculator: 0.01 op diameter.
    var MIN_STEP_RADIAL = 0.005;

    // Tussenliggende diepe knopen van een even pass liggen 0.02 (diameter)
    // ondieper dan de knopen aan de uiteinden.
    var MID_DEEP_RELIEF_DIA = 0.02;

    // Genormaliseerde diepteverdeling. x = n/(N-1), y = AP_n/AP_(N-1).
    // Bemonsterd uit de M64x6-programma's; de M48x5 valt op dezelfde curve
    // (afwijking < 0.002 genormaliseerd), dus hij is dimensieloos.
    var DEPTH_CURVE = [
        [0.000000, 0.000000],
        [0.058824, 0.083740], [0.117647, 0.164770], [0.176471, 0.243631],
        [0.235294, 0.319783], [0.294118, 0.392954], [0.352941, 0.463415],
        [0.411765, 0.531165], [0.470588, 0.596206], [0.529412, 0.658537],
        [0.588235, 0.715447], [0.647059, 0.772358], [0.705882, 0.821138],
        [0.764706, 0.867209], [0.823529, 0.910569], [0.882353, 0.948509],
        [0.941176, 0.978320], [1.000000, 1.000000]
    ];

    // Knoopafstand als veelvoud van de spoed. Even passes altijd de helft
    // van oneven. Bevestigd op fine (M64), normal (M48) en coarse (M64).
    var FREQUENCY_FACTOR = { fine: 1, normal: 2, coarse: 3 };

    function depthFraction(x) {
        if (x <= 0) { return 0; }
        if (x >= 1) { return 1; }
        for (var i = 1; i < DEPTH_CURVE.length; ++i) {
            if (x <= DEPTH_CURVE[i][0]) {
                var x0 = DEPTH_CURVE[i - 1][0], y0 = DEPTH_CURVE[i - 1][1];
                var x1 = DEPTH_CURVE[i][0], y1 = DEPTH_CURVE[i][1];
                return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
            }
        }
        return 1;
    }

    // Radiale snededieptes AP_1 .. AP_n, gemeten vanaf de startdiameter.
    // De laatste twee stappen zijn vaste minimumstappen: de curve loopt over
    // n = 1..N-1 tot totalDepth - 0.01, pass N voegt 0.005 toe en de
    // eventuele zero pass nog eens 0.005.
    function passDepths(totalDepth, numPasses, extraStraightPass) {
        var depths = [];
        var shaped = numPasses - 1;
        var shapedDepth = totalDepth - 2 * MIN_STEP_RADIAL;
        if (shaped < 1 || shapedDepth <= 0) {
            // Te weinig passes voor de staartregel: gelijkmatig verdelen.
            for (var k = 1; k <= numPasses; ++k) {
                depths.push(totalDepth * k / numPasses);
            }
        } else {
            for (var n = 1; n <= shaped; ++n) {
                depths.push(shapedDepth * depthFraction(n / shaped));
            }
            depths[shaped - 1] = shapedDepth;
            depths.push(totalDepth - MIN_STEP_RADIAL);
        }
        if (extraStraightPass) { depths.push(totalDepth); }
        return depths;
    }

    // Terugtrekking in Z zodat de beitel op één flank blijft snijden.
    function zDisplacement(ap, firstAp) {
        return (ap - firstAp) * TAN_INFEED;
    }

    function nodeSpacing(pitch, frequency, passNumber) {
        var factor = FREQUENCY_FACTOR[frequency];
        if (!factor) { return 0; }
        return pitch * factor * ((passNumber % 2 === 1) ? 1 : 0.5);
    }

    // Knoopposities langs Z, oplopend in afstand vanaf het draadbegin.
    // Knoop j is diep bij even j en ondiep bij oneven j; het eindpunt moet
    // diep zijn, dus een even laatste tussenknoop vervalt en het laatste
    // segment wordt navenant langer.
    function nodeOffsets(threadLength, spacing) {
        var offsets = [0];
        if (spacing > 0) {
            var jMax = Math.ceil(threadLength / spacing) - 1;
            if (jMax % 2 === 0) { jMax -= 1; }
            for (var j = 1; j <= jMax; ++j) { offsets.push(j * spacing); }
        }
        offsets.push(threadLength);
        return offsets;
    }

    function fitsWholeNumberOfSpacings(threadLength, spacing) {
        if (spacing <= 0) { return false; }
        var q = threadLength / spacing;
        return Math.abs(q - Math.round(q)) < 1e-9;
    }

    // Toerenreeks -5%, 0%, +5%, roterend over de passes. Voorkomt dat twee
    // opeenvolgende snedes op hetzelfde toerental lopen (trillingen).
    function spindleSpeeds(baseRpm, variationPercent, count) {
        var pattern = [-1, 0, 1];
        var speeds = [];
        for (var i = 0; i < count; ++i) {
            var f = 1 + pattern[i % pattern.length] * variationPercent / 100;
            speeds.push(Math.round(baseRpm * f));
        }
        return speeds;
    }

    // Bouwt de volledige passenlijst. Alle X-waarden zijn diameters.
    //
    //   startDiameter   diameter waar de beitel vrij loopt (nominaal + 0.1)
    //   totalDepth      radiale profieldiepte gemeten vanaf startDiameter
    //   pitch           spoed
    //   threadLength    lengte van het draadlichaam (positief)
    //   zThreadStart    Z waar het draadlichaam begint (knoop 0)
    //   numPasses       aantal snedes exclusief de zero pass
    //   frequency       "none" | "fine" | "normal" | "coarse"
    function buildPasses(opts) {
        var pitch = opts.pitch;
        var length = Math.abs(opts.threadLength);
        var z0 = opts.zThreadStart;
        var dStart = opts.startDiameter;
        var extra = !!opts.extraStraightPass;
        var frequency = opts.frequency || "none";

        var ap = passDepths(opts.totalDepth, opts.numPasses, extra);
        var total = ap.length;
        var leadIn = (opts.leadIn !== undefined) ? opts.leadIn : 2 * pitch;
        var speeds = spindleSpeeds(opts.baseRpm, opts.rpmVariationPercent || 0, total);

        // AP van een pass, met AP_0 = 0 (de startdiameter zelf).
        function apAt(i) {
            if (i <= 0) { return 0; }
            if (i > total) { return ap[total - 1]; }
            return ap[i - 1];
        }
        function diaAt(i) { return dStart - 2 * apAt(i); }

        var passes = [];
        for (var n = 1; n <= total; ++n) {
            var isLastTwo = (n > total - (extra ? 2 : 1));
            var oscillates = !isLastTwo && frequency !== "none";
            var xDeep = diaAt(n);
            var zStart = z0 + leadIn - zDisplacement(apAt(n), apAt(1));

            var nodes = [];
            if (!oscillates) {
                nodes.push({ z: z0 - length, x: xDeep });
            } else {
                var spacing = nodeSpacing(pitch, frequency, n);
                var offsets = nodeOffsets(length, spacing);
                var even = (n % 2 === 0);

                // Ondiepe stand. Oneven passes pendelen terug naar precies de
                // diepte van de vorige pass; even passes gaan daar nog een
                // halve volgende stap bovenuit.
                var xShallow = even
                    ? dStart - 2 * (apAt(n - 1) - 0.5 * (apAt(n + 1) - apAt(n)))
                    : diaAt(n - 1);

                // De laatste ondiepe toppen van een even pass wijken af.
                var shallowIdx = [];
                for (var s = 1; s < offsets.length - 1; s += 2) { shallowIdx.push(s); }
                var taper = {};
                if (even && shallowIdx.length > 0) {
                    var d = 0.5 * (apAt(n - 1) - apAt(n - 2));
                    if (fitsWholeNumberOfSpacings(length, spacing)) {
                        if (shallowIdx.length >= 2) {
                            taper[shallowIdx[shallowIdx.length - 2]] = d;
                        }
                        taper[shallowIdx[shallowIdx.length - 1]] = -2 * d;
                    } else {
                        taper[shallowIdx[shallowIdx.length - 1]] = -0.5 * d;
                    }
                }

                for (var j = 0; j < offsets.length; ++j) {
                    var last = (j === offsets.length - 1);
                    var x;
                    if (j % 2 === 0 || last) {
                        x = (j === 0 || last) ? xDeep
                            : xDeep + (even ? MID_DEEP_RELIEF_DIA : 0);
                    } else {
                        x = xShallow + (taper[j] || 0);
                    }
                    nodes.push({ z: z0 - offsets[j], x: x });
                }
            }

            passes.push({
                number: n,
                isZeroPass: extra && n === total,
                ap: apAt(n),
                xDeep: xDeep,
                zStart: zStart,
                rpm: speeds[n - 1],
                nodes: nodes
            });
        }
        return passes;
    }

    return {
        INFEED_ANGLE_DEG: INFEED_ANGLE_DEG,
        START_OVERSIZE_DIA: START_OVERSIZE_DIA,
        MIN_STEP_RADIAL: MIN_STEP_RADIAL,
        FREQUENCY_FACTOR: FREQUENCY_FACTOR,
        depthFraction: depthFraction,
        passDepths: passDepths,
        zDisplacement: zDisplacement,
        nodeSpacing: nodeSpacing,
        nodeOffsets: nodeOffsets,
        spindleSpeeds: spindleSpeeds,
        buildPasses: buildPasses
    };
})();
// <<< VARITHREAD CORE END

// >>> VARITHREAD EMITTER BEGIN
// ---------------------------------------------------------------------------
// VariThread - draadsnijden met oscillerende, variërende X-diepte.
//
// De post vervangt de snedes die Fusion aanlevert door een eigen reeks,
// gebouwd met VariThread.buildPasses(). Fusion kent de oscillatie en de
// diepteverdeling niet, dus zijn bewegingen worden opgevangen, gebruikt om de
// geometrie af te leiden, en daarna weggegooid.
//
// LET OP: de simulatie en de tijdschatting in Fusion tonen Fusion's eigen
// snedes, niet deze. Dat verschil is inherent aan deze aanpak.
// ---------------------------------------------------------------------------
var variThread = {
    active: false,
    moves: [],

    start: function () {
        this.active = true;
        this.moves = [];
    },

    stop: function () {
        this.active = false;
        this.moves = [];
    },

    record: function (x, y, z, isCut) {
        this.moves.push({ x: x, y: y, z: z, cut: isCut });
    },

    // xFormat heeft scale 2: het verwacht een radius en schrijft een diameter.
    // De rekenkern werkt in diameters, dus hier delen.
    dia: function (diameter) {
        return "X" + xFormat.format(diameter / 2);
    },

    // Leidt de draadgeometrie af uit de opgevangen bewegingen plus de
    // operatieparameters. Geeft null terug als er iets ontbreekt; de aanroeper
    // meldt dat dan als fout in plaats van te gokken.
    geometry: function () {
        var cuts = [], rapids = [];
        for (var i = 0; i < this.moves.length; ++i) {
            (this.moves[i].cut ? cuts : rapids).push(this.moves[i]);
        }
        if (cuts.length < 1) { return null; }

        var pitch = getParameter("operation:threadPitch", 0);
        var depth = getParameter("operation:threadDepth", 0);
        if (pitch <= 0 || depth <= 0) { return null; }

        // Fusion geeft de X-waarden als radius; alles hieronder is diameter.
        var xDeepest = Infinity, xRetract = -Infinity;
        for (i = 0; i < cuts.length; ++i) { xDeepest = Math.min(xDeepest, cuts[i].x * 2); }
        for (i = 0; i < rapids.length; ++i) { xRetract = Math.max(xRetract, rapids[i].x * 2); }
        if (!isFinite(xDeepest) || !isFinite(xRetract)) { return null; }

        // Het draadlichaam zelf, zonder de aanloop die Fusion ervoor zet.
        if (!hasParameter("operation:frontHeight_value") || !hasParameter("operation:backHeight_value")) {
            return null;
        }
        var zBodyStart = getParameter("operation:frontHeight_value") - getParameter("operation:frontHeight_offset", 0);
        var zBodyEnd = getParameter("operation:backHeight_value") + getParameter("operation:backHeight_offset", 0);
        var length = Math.abs(zBodyStart - zBodyEnd);
        if (length <= 0) { return null; }

        var nominalDiameter = xDeepest + 2 * depth;

        return {
            pitch: pitch,
            nominalDiameter: nominalDiameter,
            startDiameter: nominalDiameter + VariThread.START_OVERSIZE_DIA,
            totalDepth: depth + VariThread.START_OVERSIZE_DIA / 2,
            threadLength: length,
            zThreadStart: zBodyStart,
            retractDiameter: xRetract,
            fusionPasses: cuts.length
        };
    },

    // Speelt de aanlooppositionering van Fusion af tot en met de beweging naar
    // de vrijloopdiameter, zodat de beitel via dezelfde weg aankomt.
    replayApproach: function (retractDiameter) {
        var target = xFormat.getResultingValue(retractDiameter / 2);
        var stop = -1;
        for (var i = 0; i < this.moves.length; ++i) {
            if (this.moves[i].cut) { break; }
            if (xFormat.getResultingValue(this.moves[i].x) == target) { stop = i; }
        }
        for (i = 0; i <= stop; ++i) {
            var xw = xOutput.format(this.moves[i].x);
            var yw = yOutput.format(this.moves[i].y);
            var zw = zOutput.format(this.moves[i].z);
            if (xw || yw || zw) { writeBlock(gMotionModal.format(0), xw, yw, zw); }
        }
        return stop >= 0;
    },

    emit: function () {
        var geo = this.geometry();
        if (!geo) {
            error(localize("VariThread: kan de draadgeometrie niet afleiden uit deze operatie. Controleer spoed, draaddiepte en de voor-/achterzijde van de draad."));
            return;
        }

        var frequency = getProperty(properties._11_oscillatie);
        var numPasses = parseInt(getProperty(properties._12_aantalPassen), 10);
        if (!(numPasses > 0)) { numPasses = geo.fusionPasses; }
        var extraStraightPass = getProperty(properties._13_extraGladdeSnede) ? true : false;

        var cuttingSpeed = parseFloat(getProperty(properties._14_snijsnelheid));
        var baseRpm = spindleSpeed;
        if (cuttingSpeed > 0) {
            baseRpm = cuttingSpeed * 1000.0 / (Math.PI * geo.nominalDiameter);
        }
        var variation = parseFloat(getProperty(properties._15_toerentalVariatie));
        if (!(variation > 0)) { variation = 0; }

        var passes = VariThread.buildPasses({
            startDiameter: geo.startDiameter,
            totalDepth: geo.totalDepth,
            pitch: geo.pitch,
            threadLength: geo.threadLength,
            zThreadStart: geo.zThreadStart,
            numPasses: numPasses,
            frequency: frequency,
            extraStraightPass: extraStraightPass,
            baseRpm: baseRpm,
            rpmVariationPercent: variation
        });

        writeComment("VARITHREAD");
        writeComment("SPOED: " + spatialFormat.format(geo.pitch));
        writeComment("DIAMETER: " + spatialFormat.format(geo.nominalDiameter));
        writeComment("PROFIELDIEPTE: " + spatialFormat.format(geo.totalDepth - VariThread.START_OVERSIZE_DIA / 2));
        writeComment("LENGTE: " + spatialFormat.format(geo.threadLength));
        writeComment("SNEDES: " + integerFormat.format(passes.length) + (extraStraightPass ? " (incl. rechte snede)" : ""));
        writeComment("OSCILLATIE: " + String(frequency).toUpperCase());
        if (variation > 0) {
            writeComment("TOERENVARIATIE: +/- " + spatialFormat.format(variation) + "% (-,0,+ roterend)");
        }

        var atClearance = this.replayApproach(geo.retractDiameter);

        var kWord = "K" + spatialFormat.format(geo.pitch);
        var lastRpm = -1;
        if (!atClearance) {
            writeBlock(gMotionModal.format(0), this.dia(geo.retractDiameter));
        }

        for (var p = 0; p < passes.length; ++p) {
            var pass = passes[p];
            writeComment(pass.isZeroPass ? "RECHTE SNEDE" : ("SNEDE " + integerFormat.format(pass.number)));
            if (pass.rpm != lastRpm) {
                writeBlock("S" + getSpindleCode(currentSection) + "=" + rpmFormat.format(pass.rpm));
                lastRpm = pass.rpm;
            }
            writeBlock("Z" + zFormat.format(pass.zStart));
            writeBlock(this.dia(pass.xDeep));
            for (var n = 0; n < pass.nodes.length; ++n) {
                writeBlock("G33", this.dia(pass.nodes[n].x), "Z" + zFormat.format(pass.nodes[n].z), kWord);
            }
            writeBlock(gMotionModal.format(0), this.dia(geo.retractDiameter));
        }

        // De modale stand is met de hand geschreven; forceer hem terug zodat de
        // volgende operatie zijn eigen X/Z weer uitschrijft.
        xOutput.reset();
        zOutput.reset();
        gMotionModal.reset();
        sOutput.reset();
        forceFeed();
    }
};
// <<< VARITHREAD EMITTER END

function onRapid(_x, _y, _z) {
    if (variThread.active) { variThread.record(_x, _y, _z, false); return; }
    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var z = zOutput.format(_z);
    if (x || y || z) {
        var useG1 = (((x ? 1 : 0) + (y ? 1 : 0) + (z ? 1 : 0)) > 1) && !isCannedCycle;
        var gCode = useG1 ? 1 : 0;
        var f = useG1 ? (getFeed(machineState.usePolarInterpolation ? toPreciseUnit(10000, MM) : getHighfeedrate(_x))) : "";
        if (pendingRadiusCompensation >= 0) {
            pendingRadiusCompensation = -1;
            var plane = getCompensationPlane(getCurrentDirection(), false, true);
            var ccLeft = isMirrored(plane) ? 42 : 41;
            var ccRight = isMirrored(plane) ? 41 : 42;
            switch (radiusCompensation) {
                case RADIUS_COMPENSATION_LEFT:
                    writeBlock(gMotionModal.format(gCode), gFormat.format(ccLeft), x, y, z, f);
                    break;
                case RADIUS_COMPENSATION_RIGHT:
                    writeBlock(gMotionModal.format(gCode), gFormat.format(ccRight), x, y, z, f);
                    break;
                default:
                    writeBlock(gMotionModal.format(gCode), gFormat.format(40), x, y, z, f);
            }
        } else {
            writeBlock(gMotionModal.format(gCode), x, y, z, f);
            resetFeed = false;
        }
    }

    if (debug) { writeComment("End of onRapid()"); }
}

function onLinear(_x, _y, _z, feed) {
    if (variThread.active) { variThread.record(_x, _y, _z, isSpeedFeedSynchronizationActive()); return; }
    if (isSpeedFeedSynchronizationActive()) {
        resetFeed = true;
        var threadPitch = getParameter("operation:threadPitch");
        var threadsPerInch = 1.0 / threadPitch; // per mm for metric
        var pitchLetter;
        var xLength = Math.abs(xFormat.format(_x) - xFormat.format(xOutput.getCurrent()));
        var zLength = Math.abs(zFormat.format(_z) - zFormat.format(zOutput.getCurrent()));
        if (xLength > zLength) {
            pitchLetter = "I";
        } else {
            pitchLetter = "K";
        }
        gMotionModal.reset();
        writeBlock(gMotionModal.format(33), xOutput.format(_x), zOutput.format(_z), pitchLetter + spatialFormat.format(1 / threadsPerInch));
        return;
    }
    if (resetFeed) {
        resetFeed = false;
        forceFeed();
    }
    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var z = zOutput.format(_z);
    if (x || y || z) {
        if (pendingRadiusCompensation >= 0) {
            pendingRadiusCompensation = -1;
            var plane = getCompensationPlane(getCurrentDirection(), false, true);
            var ccLeft = isMirrored(plane) ? 42 : 41;
            var ccRight = isMirrored(plane) ? 41 : 42;
            writeBlock(gPlaneModal.format(getPlane()));
            switch (radiusCompensation) {
                case RADIUS_COMPENSATION_LEFT:
                    writeBlock(
                        gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1),
                        gFormat.format(ccLeft),
                        x, y, z, getFeed(feed)
                    );
                    break;
                case RADIUS_COMPENSATION_RIGHT:
                    writeBlock(
                        gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1),
                        gFormat.format(ccRight),
                        x, y, z, getFeed(feed)
                    );
                    break;
                default:
                    writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), gFormat.format(40), x, y, z, getFeed(feed));
            }
        } else {
            writeBlock(gMotionModal.format(isSpeedFeedSynchronizationActive() ? 32 : 1), x, y, z, getFeed(feed));
        }


        if (hasParameter("operation:reducedPartingFeedRadius")) {
            var xend = getParameter("operation:reducedPartingFeedRadius");
            //writeComment("xend = " + spatialFormat.format(xend) + " currentx " + _x)
            if (spatialFormat.format(xend) == spatialFormat.format(_x)) {
                //setCoolant(COOLANT_OFF);
                if (currentSection.partCatcher) {
                    engagePartCatcher(true);
                }
            }

            var x_disengage = (getParameter("operation:bottomHeight_value") - getParameter("operation:tool_cornerRadius") - getParameter("operation:belowInnerRadiusDistance"))
            //writeComment("x_disengage = " + spatialFormat.format(x_disengage) + " currentx " + spatialFormat.format(_x))
            if (Math.abs(spatialFormat.format(x_disengage) - spatialFormat.format(_x)) < 0.1) {
                //setCoolant(COOLANT_OFF);
                if (currentSection.partCatcher) {
                    engagePartCatcher(false);
                }
            }
        }
    }

    if (debug) { writeComment("End of onLinear()"); }
}

function onRapid5D(_x, _y, _z, _a, _b, _c) {
    if (machineState.isBroachingOperation) { writeComment("End of onRapid5D()"); return; } // broaching operation does not support 5-axis rapid moves

    if (pendingRadiusCompensation >= 0) {
        error(localize("Radius compensation mode cannot be changed at rapid traversal."));
        return;
    }
    //if (oldc < cOutput.format(_c)) {// pos
    //    c = "C4=ACP(" + cFormat.format(_c) + ")"
    //} else {
    //    c = "C4=ACN(" + cFormat.format(_c) + ")"
    //}

    //oldc = cOutput.format(_c)

    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var z = zOutput.format(_z);
    var a = aOutput.format(_a);
    var b = bOutput.format(getB(new Vector(_a, _b, _c), currentSection));
    var c = cOutput.format(_c);
    if (x || y || z || a || b || c) {
        var useG1 = (((x ? 1 : 0) + (y ? 1 : 0) + (z ? 1 : 0)) > 1) && !isCannedCycle;
        var gCode = true ? 1 : 0;
        var f = useG1 ? (getFeed(machineState.usePolarInterpolation ? toPreciseUnit(1500, MM) : getHighfeedrate(_x))) : "F5000";
        writeBlock(gMotionModal.format(gCode), x, y, z, a, b, c, f);
        if (!useG1) {
            forceFeed();
        }
    }

    if (debug) { writeComment("End of onRapid5D()"); }
}

function onLinear5D(_x, _y, _z, _a, _b, _c, feed) {
    if (pendingRadiusCompensation >= 0) {
        error(localize("Radius compensation cannot be activated/deactivated for 5-axis move."));
        return;
    }

    //oldc = cOutput.format(_c)

    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var z = zOutput.format(_z);
    var a = aOutput.format(_a);
    var b = bOutput.format(getB(new Vector(_a, _b, _c), currentSection));
    var c = cOutput.format(_c);



    if (x || y || z || a || b || c) {
        writeBlock(gMotionModal.format(1), x, y, z, a, b, c, getFeed(feed));
    }

    if (debug) { writeComment("End of onLinear5D()"); }
}

// Start of Polar coordinates
var defaultPolarCoordinatesDirection = new Vector(1, 0, 0); // default direction for polar interpolation
var polarCoordinatesDirection = defaultPolarCoordinatesDirection; // vector to maintain tool at while in polar interpolation
var polarSpindleAxisSave;

function setPolarCoordinates(mode) {
    if (!mode) { // turn off polar mode if required
        if (isPolarModeActive()) {
            deactivatePolarMode();
            if (gotBAxis) {
                machineConfiguration.setSpindleAxis(polarSpindleAxisSave);
                bOutput.enable();
            }
            // setPolarFeedMode(false);
            if (currentWorkPlaneABC != undefined) {
                currentWorkPlaneABC.z = Number.POSITIVE_INFINITY;
            }
        }
        polarCoordinatesDirection = defaultPolarCoordinatesDirection; // reset when deactivated
        return;
    }

    var direction = polarCoordinatesDirection;

    // determine the rotary axis to use for Polar coordinates
    var axis = undefined;
    if (machineConfiguration.getAxisV().isEnabled()) {
        if (Vector.dot(machineConfiguration.getAxisV().getAxis(), currentSection.workPlane.getForward()) != 0) {
            axis = machineConfiguration.getAxisV();
        }
    }
    if (axis == undefined && machineConfiguration.getAxisU().isEnabled()) {
        if (Vector.dot(machineConfiguration.getAxisU().getAxis(), currentSection.workPlane.getForward()) != 0) {
            axis = machineConfiguration.getAxisU();
        }
    }
    if (axis == undefined) {
        error(localize("Polar coordinates require an active rotary axis be defined in direction of workplane normal."));
    }

    // calculate directional vector from initial position
    if (direction == undefined) {
        error(localize("Polar coordinates initiated without a directional vector."));
        return;
    }

    // activate polar coordinates
    // setPolarFeedMode(true); // enable multi-axis feeds for polar mode

    if (gotBAxis) {
        polarSpindleAxisSave = machineConfiguration.getSpindleAxis();
        machineConfiguration.setSpindleAxis(new Vector(0, 0, 1));
        bOutput.disable();
    }
    activatePolarMode(getTolerance() / 2, 0, direction);
    var polarPosition = getPolarPosition(currentSection.getInitialPosition().x, currentSection.getInitialPosition().y, currentSection.getInitialPosition().z);
    setCurrentPositionAndDirection(polarPosition);
}

function getPolarCoordinates(position, abc) {
    var reset = false;
    var current = getCurrentDirection();
    if (!isPolarModeActive()) {
        setCurrentDirection(abc);
        var tempPolarCoordinatesDirection = (currentSection.machiningType && (currentSection.machiningType == MACHINING_TYPE_POLAR)) ? currentSection.polarDirection : polarCoordinatesDirection;
        activatePolarMode(getTolerance() / 2, 0, tempPolarCoordinatesDirection);
        reset = true;
    }
    var polarPosition = getPolarPosition(position.x, position.y, position.z);
    if (reset) {
        deactivatePolarMode();
        setCurrentDirection(current);
    }
    return polarPosition;
}
// End of polar coordinates

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
    var directionCode;
    if (isMirrored(getCircularPlane())) {
        directionCode = clockwise ? 3 : 2;
    } else {
        directionCode = clockwise ? 2 : 3;
    }
    var toler = getTolerance();

    if (isSpeedFeedSynchronizationActive()) {
        error(localize("Speed-feed synchronization is not supported for circular moves."));
        return;
    }

    var start = getCurrentPosition();
    var revolutions = Math.abs(getCircularSweep()) / (2 * Math.PI);
    var turns = useArcTurn ? (revolutions % 1) == 0 ? revolutions - 1 : Math.floor(revolutions) : 0; // full turns

    if (isFullCircle()) {
        if (isHelical()) {
            linearize(toler);
            return;
        }
        if (turns > 1) {
            error(localize("Multiple turns are not supported."));
            return;
        }
        // G90/G91 are dont care when we do not used XYZ
        switch (getCircularPlane()) {
            case PLANE_XY:
                if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
                    if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 17)) {
                        error(localize("Plane cannot be changed when radius compensation is active."));
                        return;
                    }
                }
                writeBlock(gMotionModal.format(directionCode), iOutput.format(cx - start.x), jOutput.format(cy - start.y), getFeed(feed));
                break;
            case PLANE_ZX:
                if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
                    if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 18)) {
                        error(localize("Plane cannot be changed when radius compensation is active."));
                        return;
                    }
                }
                writeBlock(gMotionModal.format(directionCode), iOutput.format(cx - start.x), kOutput.format(cz - start.z), getFeed(feed));
                break;
            case PLANE_YZ:
                if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
                    if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 19)) {
                        error(localize("Plane cannot be changed when radius compensation is active."));
                        return;
                    }
                }
                writeBlock(gMotionModal.format(directionCode), jOutput.format(cy - start.y), kOutput.format(cz - start.z), getFeed(feed));
                break;
            default:
                linearize(toler);
        }
    } else if (!getProperty("useRadius")) { // IJK mode
        switch (getCircularPlane()) {
            case PLANE_XY:
                if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
                    if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 17)) {
                        error(localize("Plane cannot be changed when radius compensation is active."));
                        return;
                    }
                }
                if (turns > 0) {
                    writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x), jOutput.format(cy - start.y), getFeed(feed), "TURN=" + turns);
                } else {
                    writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x), jOutput.format(cy - start.y), getFeed(feed));
                }
                break;
            case PLANE_ZX:
                if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
                    if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 18)) {
                        error(localize("Plane cannot be changed when radius compensation is active."));
                        return;
                    }
                }
                if (turns > 0) {
                    writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x), kOutput.format(cz - start.z), getFeed(feed), "TURN=" + turns);
                } else {
                    writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x), kOutput.format(cz - start.z), getFeed(feed));
                }
                break;
            case PLANE_YZ:
                if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
                    if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 19)) {
                        error(localize("Plane cannot be changed when radius compensation is active."));
                        return;
                    }
                }
                if (turns > 0) {
                    writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y), kOutput.format(cz - start.z), getFeed(feed), "TURN=" + turns);
                } else {
                    writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y), kOutput.format(cz - start.z), getFeed(feed));
                }
                break;
            default:
                linearize(toler);
        }
    } else { // use radius mode
        var r = getCircularRadius();
        if (toDeg(getCircularSweep()) > (180 + 1e-9)) {
            r = -r; // allow up to <360 deg arcs
        }
        switch (getCircularPlane()) {
            case PLANE_XY:
                forceXYZ();
                writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "CR=" + spatialFormat.format(r), getFeed(feed));
                break;
            case PLANE_ZX:
                //linearize(toler);
                forceXYZ();
                writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "CR=" + spatialFormat.format(r), getFeed(feed));
                break;
            case PLANE_YZ:
                forceXYZ();
                writeBlock(gMotionModal.format(directionCode), xOutput.format(x), yOutput.format(y), zOutput.format(z), "CR=" + spatialFormat.format(r), getFeed(feed));
                break;
            default:
                linearize(toler);
        }
    }
}

var chuckMachineFrame;
var chuckSubPosition;
function getSecondaryPullMethod(type) {
    var pullMethod = {};

    // determine if pull operation, spindle return, or both
    pullMethod.pull = false;
    pullMethod.home = false;

    switch (type) {
        case "secondary-spindle-pull":
            pullMethod.pullPosition = chuckSubPosition + cycle.pullingDistance;
            pullMethod.machineFrame = chuckMachineFrame;
            pullMethod.unclampMode = "keep-clamped";
            pullMethod.pull = true;
            break;
        case "secondary-spindle-return":
            pullMethod.pullPosition = cycle.feedPosition;
            pullMethod.machineFrame = cycle.useMachineFrame;
            pullMethod.unclampMode = cycle.unclampMode;

            // pull part only (when offset!=0), Return secondary spindle to home (when offset=0)
            var feedDis = 0;
            if (pullMethod.machineFrame) {
                if (hasParameter("operation:feedPlaneHeight_direct")) { // Inventor
                    feedDis = getParameter("operation:feedPlaneHeight_direct");
                } else if (hasParameter("operation:feedPlaneHeightDirect")) { // HSMWorks
                    feedDis = getParameter("operation:feedPlaneHeightDirect");
                }
                feedPosition = feedDis;
            } else if (hasParameter("operation:feedPlaneHeight_offset")) { // Inventor
                feedDis = getParameter("operation:feedPlaneHeight_offset");
            } else if (hasParameter("operation:feedPlaneHeightOffset")) { // HSMWorks
                feedDis = getParameter("operation:feedPlaneHeightOffset");
            }

            // Transfer part to secondary spindle
            if (pullMethod.unclampMode != "keep-clamped") {
                pullMethod.pull = feedDis != 0;
                pullMethod.home = true;
            } else {
                // pull part only (when offset!=0), Return secondary spindle to home (when offset=0)
                pullMethod.pull = feedDis != 0;
                pullMethod.home = !pullMethod.pull;
            }
            break;
    }
    return pullMethod;
}

function onCycle() {

    writeBlock(gPlaneModal.format(getPlane()));

    expandCurrentCycle = false;

    if (!isTappingCycle() && (cycleType != "tapping-with-chip-breaking") && (cycleType != "turning-canned-rough") && !(machineState.isBroachingOperation)) {
        writeBlock(getFeed(cycle.feedrate));
    }

    var RTP = cycle.clearance; // return plane (absolute)
    var RFP = cycle.stock; // reference plane (absolute)
    var SDIS = cycle.retract - cycle.stock; // safety distance
    var DP = cycle.bottom; // depth (absolute)
    // var DPR = RFP - cycle.bottom; // depth (relative to reference plane)
    var DTB = cycle.dwell;
    var SDIR = tool.clockwise ? 3 : 4; // direction of rotation: M3:3 and M4:4

    switch (cycleType) {
        case "drilling":

            if (machineState.isBroachingOperation) { return; } // broaching operation does not support drilling cycles, we handle broaching separately in OnCyclePoint()


            writeCycleClearance();
            writeBlock(
                "MCALL CYCLE81(" + spatialFormat.format(RTP) +
                "," + spatialFormat.format(RFP) +
                "," + spatialFormat.format(SDIS) +
                "," + spatialFormat.format(DP) +
                "," /*+ spatialFormat.format(DPR)*/ + ")"
            );
            break;
        case "counter-boring":
            writeCycleClearance();
            writeBlock(
                "MCALL CYCLE82(" + spatialFormat.format(RTP) +
                "," + spatialFormat.format(RFP) +
                "," + spatialFormat.format(SDIS) +
                "," + spatialFormat.format(DP) +
                "," /*+ spatialFormat.format(DPR)*/ +
                "," + conditional(DTB > 0, secFormat.format(DTB)) + ")"
            );
            break;
        case "chip-breaking":
            expandCurrentCycle = true;

            /*         if (cycle.accumulatedDepth < cycle.depth) {
                         expandCurrentCycle = true;
                     } else {
                         writeCycleClearance();
                         var FDEP = cycle.stock - cycle.incrementalDepth;
                         var FDPR = cycle.incrementalDepth; // relative to reference plane (unsigned)
                         var DAM = cycle.incrementalDepthReduction; // degression (unsigned)
                         var DTS = 0; // dwell time at start
                         var FRF = 1; // feedrate factor (unsigned)
                         var VARI = 0; // chip breaking
                         var _AXN = 3; // tool axis
                         var _MDEP = (cycle.incrementalDepthReduction > 0) ? cycle.minimumIncrementalDepth : cycle.incrementalDepth; // minimum drilling depth
                         var _VRT = (cycle.chipBreakDistance > 0) ? cycle.chipBreakDistance : 0; // retraction distance
                         var _DTD = (cycle.dwell != undefined) ? cycle.dwell : 0;
                         var _DIS1 = 0; // limit distance
         
                         writeBlock(
                             "MCALL CYCLE83(" + spatialFormat.format(RTP) +
                             ", " + spatialFormat.format(RFP) +
                             ", " + spatialFormat.format(SDIS) +
                             ", " + spatialFormat.format(DP) +
                             ", " //+ spatialFormat.format(DPR)// +
                             ", " + spatialFormat.format(FDEP) +
                             ", " //+ spatialFormat.format(FDPR)// +
                             ", " + spatialFormat.format(DAM) +
                             ", " + //conditional(DTB > 0, secFormat.format(DTB))// // only dwell at bottom
                             ", " + conditional(DTS > 0, secFormat.format(DTS)) +
                             ", " + spatialFormat.format(FRF) +
                             ", " + spatialFormat.format(VARI) +
                             ", " + //_AXN +//
                             ", " + spatialFormat.format(_MDEP) +
                             ", " + spatialFormat.format(_VRT) +
                             ", " + secFormat.format(_DTD) +
                             ", 0" + //spatialFormat.format(_DIS1) +
                             ")"
                         );
                     }
                         */

            break;
        case "deep-drilling":
            writeCycleClearance();
            var FDEP = cycle.stock - cycle.incrementalDepth;
            var FDPR = cycle.incrementalDepth; // relative to reference plane (unsigned)
            var DAM = cycle.incrementalDepthReduction; // degression (unsigned)
            var DTS = 0; // dwell time at start
            var FRF = 1; // feedrate factor (unsigned)
            var VARI = 1; // full retract
            var _MDEP = (cycle.incrementalDepthReduction > 0) ? cycle.minimumIncrementalDepth : cycle.incrementalDepth; // minimum drilling depth
            var _VRT = 0; // retraction distance
            var _DTD = (cycle.dwell != undefined) ? cycle.dwell : 0;
            var _DIS1 = 0; // limit distance

            writeBlock(
                "MCALL CYCLE83(" + spatialFormat.format(RTP) +
                ", " + spatialFormat.format(RFP) +
                ", " + spatialFormat.format(SDIS) +
                ", " + spatialFormat.format(DP) +
                ", " /*+ spatialFormat.format(DPR)*/ +
                ", " + spatialFormat.format(FDEP) +
                ", " /*+ spatialFormat.format(FDPR)*/ +
                ", " + spatialFormat.format(DAM) +
                ", " + /*conditional(DTB > 0, secFormat.format(DTB)) +*/ // only dwell at bottom
                ", " + conditional(DTS > 0, secFormat.format(DTS)) +
                ", " + spatialFormat.format(FRF) +
                ", " + spatialFormat.format(VARI) +
                ", " + /*_AXN +*/
                ", " + spatialFormat.format(_MDEP) +
                ", " + spatialFormat.format(_VRT) +
                ", " + secFormat.format(_DTD) +
                ", 0" + /*spatialFormat.format(_DIS1) +*/
                ")"
            );
            break;
        case "tapping":
        case "left-tapping":
        case "right-tapping":
            writeCycleClearance();
            var SDAC = SDIR; // direction of rotation after end of cycle
            var MPIT = 0; // thread pitch as thread size
            var PIT = ((tool.type == TOOL_TAP_LEFT_HAND) ? -1 : 1) * tool.threadPitch; // thread pitch
            var POSS = 0; // spindle position for oriented spindle stop in cycle (in degrees)
            var SST = spindleSpeed; // speed for tapping
            var SST1 = spindleSpeed; // speed for return
            writeBlock(
                "MCALL CYCLE84(" + spatialFormat.format(RTP) +
                ", " + spatialFormat.format(RFP) +
                ", " + spatialFormat.format(SDIS) +
                ", " + spatialFormat.format(DP) +
                ", " /*+ spatialFormat.format(DPR)*/ +
                ", " + conditional(DTB > 0, secFormat.format(DTB)) +
                ", " + spatialFormat.format(SDAC) +
                ", " /*+ spatialFormat.format(MPIT)*/ +
                ", " + spatialFormat.format(PIT) +
                ", " + spatialFormat.format(POSS) +
                ", " + spatialFormat.format(SST) +
                ", " + spatialFormat.format(SST1) + ")"
            );
            break;
        case "tapping-with-chip-breaking":
            writeCycleClearance();
            var SDAC = SDIR; // direction of rotation after end of cycle
            var MPIT = 0; // thread pitch as thread size
            var PIT = ((tool.type == TOOL_TAP_LEFT_HAND) ? -1 : 1) * tool.threadPitch; // thread pitch
            var POSS = 0; // spindle position for oriented spindle stop in cycle (in degrees)
            var SST = spindleSpeed; // speed for tapping
            var SST1 = spindleSpeed; // speed for return
            var _AXN = 0; // tool axis
            var _PTAB = 0; // must be 0
            var _TECHNO = 0; // technology settings
            var _VARI = 1; // machining type: 0 = tapping full depth, 1 = tapping partial retract, 2 = tapping full retract
            var _DAM = cycle.incrementalDepth; // incremental depth
            var _VRT = cycle.chipBreakDistance; // retract distance for chip breaking

            writeBlock(
                "MCALL CYCLE84(" + spatialFormat.format(RTP) +
                ", " + spatialFormat.format(RFP) +
                ", " + spatialFormat.format(SDIS) +
                ", " + spatialFormat.format(DP) +
                ", " /*+ spatialFormat.format(DPR)*/ +
                ", " + conditional(DTB > 0, secFormat.format(DTB)) +
                ", " + spatialFormat.format(SDAC) +
                ", " + spatialFormat.format(MPIT) +
                ", " + spatialFormat.format(PIT) +
                ", " + spatialFormat.format(POSS) +
                ", " + spatialFormat.format(SST) +
                ", " + spatialFormat.format(SST1) +
                ", " + spatialFormat.format(_AXN) +
                ", " + spatialFormat.format(_PTAB) +
                ", " + spatialFormat.format(_TECHNO) +
                ", " + spatialFormat.format(_VARI) +
                ", " + spatialFormat.format(_DAM) +
                ", " + spatialFormat.format(_VRT) + ")"
            );
            break;
        case "reaming":
            writeCycleClearance();
            forceFeed();
            var FFR = cycle.feedrate;
            forceFeed();
            var RFF = cycle.retractFeedrate;
            writeBlock(
                "MCALL CYCLE85(" + spatialFormat.format(RTP) +
                ", " + spatialFormat.format(RFP) +
                ", " + spatialFormat.format(SDIS) +
                ", " + spatialFormat.format(DP) +
                ", " /*+ spatialFormat.format(DPR)*/ +
                ", " + conditional(DTB > 0, secFormat.format(DTB)) +
                ", " + feedFormat.format(FFR) +
                ", " + feedFormat.format(RFF) + ")"
            );
            break;
        case "stop-boring":
            if (cycle.dwell > 0) {
                expandCurrentCycle = true;
            } else {
                writeCycleClearance();
                writeBlock(
                    "MCALL CYCLE87(" + spatialFormat.format(RTP) +
                    ", " + spatialFormat.format(RFP) +
                    ", " + spatialFormat.format(SDIS) +
                    ", " + spatialFormat.format(DP) +
                    ", " /*+ spatialFormat.format(DPR)*/ +
                    ", " + SDIR + ")"
                );
            }
            break;
        case "fine-boring":
            writeCycleClearance();
            var RPA = 0; // return path in abscissa of the active plane (enter incrementally with)
            var RPO = 0; // return path in the ordinate of the active plane (enter incrementally sign)
            var RPAP = 0; // return plane in the applicate (enter incrementally with sign)
            var POSS = 0; // spindle position for oriented spindle stop in cycle (in degrees)
            writeBlock(
                "MCALL CYCLE86(" + spatialFormat.format(RTP) +
                ", " + spatialFormat.format(RFP) +
                ", " + spatialFormat.format(SDIS) +
                ", " + spatialFormat.format(DP) +
                ", " /*+ spatialFormat.format(DPR)*/ +
                ", " + conditional(DTB > 0, secFormat.format(DTB)) +
                ", " + SDIR +
                ", " + spatialFormat.format(RPA) +
                ", " + spatialFormat.format(RPO) +
                ", " + spatialFormat.format(RPAP) +
                ", " + spatialFormat.format(POSS) + ")"
            );
            break;
        case "back-boring":
            expandCurrentCycle = true;
            break;
        case "manual-boring":
            writeCycleClearance();
            writeBlock(
                "MCALL CYCLE88(" + spatialFormat.format(RTP) +
                ", " + spatialFormat.format(RFP) +
                ", " + spatialFormat.format(SDIS) +
                ", " + spatialFormat.format(DP) +
                ", " /*+ spatialFormat.format(DPR)*/ +
                ", " + conditional(DTB > 0, secFormat.format(DTB)) +
                ", " + SDIR + ")"
            );
            break;
        case "boring":
            writeCycleClearance();
            // retract feed is ignored
            writeBlock(
                "MCALL CYCLE89(" + spatialFormat.format(RTP) +
                ", " + spatialFormat.format(RFP) +
                ", " + spatialFormat.format(SDIS) +
                ", " + spatialFormat.format(DP) +
                ", " /*+ spatialFormat.format(DPR)*/ +
                ", " + conditional(DTB > 0, secFormat.format(DTB)) + ")"
            );
            break;
        default:
            expandCurrentCycle = true;
    }

    if (cycleType == "stock-transfer") {
        error(localize("Stock transfer is not supported. Requires machine specific customization."));
        return;
    }

    if (debug) { writeComment("End of onCycle()"); }
}

function onCyclePath() {
    saveShowSequenceNumbers = getProperty("showSequenceNumbers");

    // buffer all paths and stop feeds being output
    feedOutput.disable();
    setProperty("showSequenceNumbers", "false");
    redirectToBuffer();
    //Adding indice in cases of multiple canned cycles calls
    writeBlock("START" + integerFormat.format(currentSection.getId()) + ":");
    gMotionModal.reset();
    isCannedCycle = true;
    xOutput.reset();
    zOutput.reset();
}

function onCyclePathEnd() {
    writeBlock("END" + integerFormat.format(currentSection.getId()) + ":");
    setProperty("showSequenceNumbers", saveShowSequenceNumbers); // reset property to initial state
    feedOutput.enable();
    var cyclePath = String(getRedirectionBuffer()).split(EOL); // get cycle path from buffer
    closeRedirection();
    for (line in cyclePath) { // remove empty elements
        if (cyclePath[line] == "") {
            cyclePath.splice(line);
        }
    }

    var outsideProfiling = cycle.turningMode == 0;
    var verticalPasses;
    if (cycle.profileRoughingCycle == 0) {
        verticalPasses = false;
    } else if (cycle.profileRoughingCycle == 1) {
        verticalPasses = true;
    } else {
        error(localize("Unsupported passes type."));
        return;
    }

    // output cycle data
    switch (cycleType) {
        case "turning-canned-rough":
            var NPP = "\"" + "START" + integerFormat.format(currentSection.getId()) + ":END" + integerFormat.format(currentSection.getId()) + "\""; // Name of contour subroutine
            var MID = spatialFormat.format(cycle.depthOfCut); // Infeed depth (enter without sign)
            //Siemens doesn't use sign for allowance
            var FALZ = Math.abs(spatialFormat.format(cycle.zStockToLeave)); // Finishing allowance in the longitudinal axis (enter without sign)
            var FALX = Math.abs(xFormat.format(cycle.xStockToLeave)); // Finishing allowance in the transverse axis (enter without sign)
            var FAL = 0; // Finishing allowance suitable for contour (enter without sign)
            var FF1 = feedFormat.format(cycle.cutfeedrate); // Feedrate for roughing without relief cut
            var FF2 = feedFormat.format(cycle.cutfeedrate); //Feedrate for plunging into relief cut element
            var FF3 = feedFormat.format(cycle.cutfeedrate); // Feedrate for finishing cut
            var VARI = outsideProfiling ? (verticalPasses ? 2 : 1) : (verticalPasses ? 4 : 3); // Machining typeRange of values: 1 ... 12
            var DT = 0; // Dwell time fore chip breaking when roughing
            var DAM = 0; // Path length after which each roughing step is interrupted for chip breaking
            var _VRT = spatialFormat.format(cycle.retractLength); // Lift-off distance from contour when roughing, incremental (to be entered without sign)

            writeBlock(
                "CYCLE95(" + NPP + ", " + MID + ", " + FALZ + ", " + FALX + ", " + FAL + ", " + FF1 + ", " + FF2 +
                ", " + FF3 + ", " + VARI + ", " + DT + ", " + DAM + ", " + _VRT + ")"
            );
            break;
        default:
            error(localize("Unsupported turning canned cycle."));
    }

    for (var i = 0; i < cyclePath.length; ++i) {
        writeBlock(cyclePath[i]); // output cycle path
        setProperty("showSequenceNumbers", saveShowSequenceNumbers); // reset property to initial state
    }
    isCannedCycle = false;
}

function writeCycleClearance() {
    if (gotBAxis) {
        return;
    } else {
        switch (gPlaneModal.getCurrent()) {
            case 17:
                writeBlock(gMotionModal.format(0), zOutput.format(cycle.clearance));
                break;
            case 18:
                writeBlock(gMotionModal.format(0), yOutput.format(cycle.clearance));
                break;
            case 19:
                writeBlock(gMotionModal.format(0), xOutput.format(cycle.clearance));
                break;
            default:
                error(localize("Unsupported drilling orientation."));
                return;
        }
    }
}

var expandCurrentCycle = false;
function onCyclePoint(x, y, z) {

    if (machineState.isBroachingOperation) {// Handle broaching operation separately

        updateMachiningMode(currentSection)
        var abc = defineWorkPlane(currentSection, true);
        var initialPosition = getFramePosition(currentSection.getInitialPosition());
        var polarPosition = getPolarCoordinates(initialPosition, abc);

        // Retrieve custom property values
        var broachRadius = parseFloat(getProperty(properties._02_broodsDiepte)); // The radius from center for broaching
        var broachStep = parseFloat(getProperty(properties._03_stapGrootte));   // Incremental step in X
        var broachFeedrate = parseFloat(getProperty(properties._04_snijSnelheid)); // Feedrate for broaching moves
        var calculatedBroachSteps = Math.ceil(broachRadius / broachStep); // Calculate the number of steps needed for the broaching operation
        var calculatedBroachDepth = broachRadius / calculatedBroachSteps; // Calculate the depth for each step
        var initialX
        writeComment("Broaching operation with broach depth: " + broachRadius + ", max step size: " + broachStep + ", feedrate: " + broachFeedrate + "M/Min, steps: " + calculatedBroachSteps + ", calculated depth per step: " + calculatedBroachDepth);

        // Basic validation for broaching parameters
        if (broachRadius <= 0 || broachStep <= 0) {
            error(localize("Broaching depth and step size must be positive values."));
            return true; // Indicate that we tried to handle it, but failed
        }
        if (broachFeedrate <= 0) {
            error(localize("Broaching feedrate must be a positive value."));
            return true;
        }

        cOutput.reset();
        if (machineState.usePolarCoordinates) {
            if (debug) {
                writeComment("Broaching operation in polar coordinates detected in onCyclePoint()");
                writeComment("Initial polar position: " + polarPosition.first.x + ", " + polarPosition.first.y + ", " + polarPosition.second.z);
            }
            var polarPosition = getPolarPosition(x, y, z);
            setCurrentPositionAndDirection(polarPosition);
            forceXYZ();
            onCommand(COMMAND_UNLOCK_MULTI_AXIS);
            cOutput.reset();

            writeBlock(gMotionModal.format(0), yOutput.format(polarPosition.first.y), zOutput.format(initialPosition.z), cOutput.format(polarPosition.second.z));
            writeBlock(gMotionModal.format(0), xOutput.format((polarPosition.first.x - broachRadius)));
            initialX = polarPosition.first.x - broachRadius;

        } else {
            if (debug) {
                writeComment("Broaching operation in Cartesian coordinates detected in onCyclePoint()");
                writeComment("Initial position: " + initialPosition.x + ", " + initialPosition.y + ", " + initialPosition.z);
            }
            forceXYZ();
            var _x = xOutput.format(x);
            var _y = yOutput.format(y);
            var _z = zOutput.format(z);
            writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
            writeBlock(gMotionModal.format(0), xOutput.format((initialPosition.x - broachRadius)), yOutput.format(initialPosition.y));
            initialX = initialPosition.x - broachRadius;
        }
        // Loop through the calculated steps for broaching
        for (var i = 1; i < calculatedBroachSteps + 1; i++) {
            // Calculate the new position for each step
            currentX = initialX + (i * calculatedBroachDepth);
            writeBlock(gMotionModal.format(0), xOutput.format(currentX), zOutput.format(initialPosition.z), cOutput.format(polarPosition.second.z));
            writeBlock(gMotionModal.format(1), zOutput.format(cycle.bottom), feedOutput.format(broachFeedrate));
            writeBlock(gMotionModal.format(0), xOutput.format(initialX - .1))
            writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z))
        }
        if (debug) { writeComment("End of broaching operation in onCyclePoint()"); }
        return
    }

    if (expandCurrentCycle) {
        expandCyclePoint(x, y, z);
    } else if (machineState.usePolarCoordinates) {
        var polarPosition = getPolarPosition(x, y, z);
        setCurrentPositionAndDirection(polarPosition);
        forceXYZ();
        onCommand(COMMAND_UNLOCK_MULTI_AXIS);
        cOutput.reset();
        var _x = xOutput.format(polarPosition.first.x);
        var _c = cOutput.format(polarPosition.second.z);
        writeBlock(_x, _c, getCode("LOCK_MULTI_AXIS", getSpindle(PART)));
        //writeBlock(_x, _c);
    } else {
        forceXYZ();
        var _x = xOutput.format(x);
        var _y = yOutput.format(y);
        var _z = zOutput.format(z);
        switch (gPlaneModal.getCurrent()) {
            case 17: // XY
                writeBlock(_x, _y);
                break;
            case 18: // ZX
                writeBlock(_z, _x);
                break;
            case 19: // YZ
                writeBlock(_y, _z);
                break;
        }
    }
    if (debug) { writeComment("End of onCyclePoint()"); }
}

function onCycleEnd() {

    if (machineState.isBroachingOperation) { if (debug) { writeComment("End of onCycleEnd()"); } return; }
    if (!expandCurrentCycle) {
        writeBlock("MCALL"); // end modal cycle
    }
    zOutput.reset();
    onCommand(COMMAND_UNLOCK_MULTI_AXIS);
}

var saveShowSequenceNumbers;
var isCannedCycle = false;

function onPassThrough(text) {
    var commands = String(text).split(",");
    for (text in commands) {
        writeBlock(commands[text]);
    }
}

var forceMyToolChange = false
function onParameter(name, value) {
    var invalid = false;
    switch (name) {
        case "generated-at":
            generatedAtRaw = String(value);
            var dt = new Date(generatedAtRaw);
            bufferParameters.time = isNaN(dt.getTime()) ? generatedAtRaw : dt.toLocaleString();
            break;
        case 'chuck-front-mode':
            chuckFrontMode = value;
            break;
        case 'chuck-front-offset':
            chuckOffset = value;
            break;
        case 'part-lower-z':
            bufferParameters.workpieceLowerZ = parseFloat(value);
            break;
        case 'part-upper-z':
            bufferParameters.workpieceUpperZ = parseFloat(value);
            break;
        case 'job-notes':
           break
        case "action":
            if (String(value).toUpperCase() == "USEPOLARMODE" ||
                String(value).toUpperCase() == "USEPOLARINTERPOLATION") {
                forcePolarInterpolation = true;
                forcePolarCoordinates = false;
            } else if (String(value).toUpperCase() == "USEXZCMODE" ||
                String(value).toUpperCase() == "USEPOLARCOORDINATES") {
                forcePolarCoordinates = true;
                forcePolarInterpolation = false;
            } else if (String(value).toUpperCase() == "METEN") {
                writeln("GROUP_BEGIN(0,\"MAAT CONTROLE\",0,0)");
                writeComment("")
                writeComment("MAAT CONTROLE")
                writeBlock("M" + getSpindleCode(currentSection) + "=5")
                onCommand(COMMAND_COOLANT_OFF);
                writeRetract(currentSection, true)
                writeBlock(getCode("OPEN_DOOR"));
                writeBlock("MSG(" + "\"" + "TOEGIFT OP GEDRAAIDE DIAMETERS = " + stockForMeasure + "\"" + ")")
                onCommand(COMMAND_STOP)
                forceMyToolChange = true
                writeComment("")
                writeln("GROUP_END(0,0)");
            } else if (String(value).toUpperCase() == "INSPECTIE") {
                writeln("GROUP_BEGIN(0,\"INSPECTEREN\",0,0)");
                writeComment("")
                writeComment("INSPECTEREN")
                writeBlock("M" + getSpindleCode(currentSection) + "=5")
                onCommand(COMMAND_COOLANT_OFF);
                writeRetract(currentSection, true)
                writeBlock(getCode("OPEN_DOOR"));
                onCommand(COMMAND_STOP)
                forceMyToolChange = true
                writeComment("")
                writeln("GROUP_END(0,0)");
            } else if (String(value).toUpperCase() == "STANGENLADER_MET_AANSLAG") {
                writeBlock("M1")
                writeBlock(getCode("STOP_SPINDLE", activeSpindle))
                onCommand(COMMAND_COOLANT_OFF);
                writeBlock("METAANSLAG_FUSION")
                //writeBlock("METAANSLAG_FUSION(" + spatialFormat.format(parseFloat(getParameter("stock-upper-z"))) + ")")
                xFormat.setScale(2); // diameter mode
                xOutput.setFormat(xFormat);
                writeBlock("DIAMON");
                gotBarFeeder = true
            } else if (String(value).toUpperCase() == "CENTER_WORK") {
                onCommand(COMMAND_COOLANT_OFF)
                writeBlock(getCode("STOP_SPINDLE", activeSpindle))
                writeRetract(currentSection, true)
                writeBlock("M4=5")
                writeBlock(getCode('TAILSTOCK_ON'))
            } else if (String(value).toUpperCase() == "CENTER_PARK") {
                onCommand(COMMAND_COOLANT_OFF)
                writeBlock(getCode("STOP_SPINDLE", activeSpindle))
                writeRetract(currentSection, true)
                writeBlock(getCode('TAILSTOCK_OFF'))
            } else if (String(value).toUpperCase().includes("_DSSV_ON")) {
                const ampReg = /A\s*(\d+)/
                const timeReg = /T\s*(\d+)/

                const ampMatch = String(value).match(ampReg)
                const timeMatch = String(value).match(timeReg)

                if (ampMatch && ampMatch[1]) {
                    amp = parseInt(ampMatch[1])
                }
                if (timeMatch && timeMatch[1]) {
                    time = parseInt(timeMatch[1])
                }
                machineState.isDSSVon = true
            } else if (String(value).toUpperCase().includes("_DSSV_OFF")) {
                machineState.isDSSVon = false
                writeBlock("_DSSV_OFF")
            }
            else if (String(value).toUpperCase().includes("STOP_MET_DEUR_OPEN")) {
                //'STOP_MET_DEUR_OPEN(AS OMDRAAIEN)'
                // Extract the string inside the brackets ()
                const match = String(value).match(/\((.*?)\)/);
                const extractedString = match ? match[1] : "";
                var _grpName = String(extractedString || "STOP MET DEUR OPEN").replace(/"/g, "'");
                writeln("GROUP_BEGIN(0,\"" + _grpName + "\",0,0)");
                writeComment(extractedString)
                writeBlock("MSG(" + "\"" + extractedString + "\"" + ")")
                writeBlock("M" + getSpindleCode(currentSection) + "=5")
                onCommand(COMMAND_COOLANT_OFF);
                writeRetract(currentSection, true)
                writeBlock(getCode("OPEN_DOOR"));
                onCommand(COMMAND_STOP)
                forceMyToolChange = true
                writeComment("")
                writeln("GROUP_END(0,0)");
            }
            else {
                invalid = true;
            }
    }
    if (invalid) {
        error(localize("Invalid action parameter: ") + value);
        return;
    }
}

var currentCoolantMode = COOLANT_OFF;
var currentCoolantTurret = 1;
var coolantOff = undefined;
var isOptionalCoolant = false;
var forceCoolant = false;

function setCoolant(coolant, turret) {
    var coolantCodes = getCoolantCodes(coolant, turret);
    if (Array.isArray(coolantCodes)) {
        if (singleLineCoolant) {
            skipBlock = isOptionalCoolant;
            writeBlock(coolantCodes.join(getWordSeparator()));
        } else {
            for (var c in coolantCodes) {
                skipBlock = isOptionalCoolant;
                writeBlock(coolantCodes[c]);
            }
        }
        return undefined;
    }
    return coolantCodes;
}

function getCoolantCodes(coolant, turret) {
    turret = gotMultiTurret ? (turret == undefined ? 1 : turret) : 1;
    isOptionalCoolant = false;
    var multipleCoolantBlocks = new Array(); // create a formatted array to be passed into the outputted line
    if (!coolants) {
        error(localize("Coolants have not been defined."));
    }
    if (tool.type == TOOL_PROBE) { // avoid coolant output for probing
        coolant = COOLANT_OFF;
    }
    if (coolant == currentCoolantMode && turret == currentCoolantTurret) {
        if ((typeof operationNeedsSafeStart != "undefined" && operationNeedsSafeStart) && coolant != COOLANT_OFF) {
            isOptionalCoolant = true;
        } else if (!forceCoolant || coolant == COOLANT_OFF) {
            return undefined; // coolant is already active
        }
    }
    if ((coolant != COOLANT_OFF) && (currentCoolantMode != COOLANT_OFF) && (coolantOff != undefined) && !forceCoolant && !isOptionalCoolant) {
        if (Array.isArray(coolantOff)) {
            for (var i in coolantOff) {
                multipleCoolantBlocks.push(coolantOff[i]);
            }
        } else {
            multipleCoolantBlocks.push(coolantOff);
        }
    }
    forceCoolant = false;

    var m;
    var coolantCodes = {};
    for (var c in coolants) { // find required coolant codes into the coolants array
        if (coolants[c].id == coolant) {
            var localCoolant = parseCoolant(coolants[c], turret);
            localCoolant = typeof localCoolant == "undefined" ? coolants[c] : localCoolant;
            coolantCodes.on = localCoolant.on;
            if (localCoolant.off != undefined) {
                coolantCodes.off = localCoolant.off;
                break;
            } else {
                for (var i in coolants) {
                    if (coolants[i].id == COOLANT_OFF) {
                        coolantCodes.off = localCoolant.off;
                        break;
                    }
                }
            }
        }
    }
    if (coolant == COOLANT_OFF) {
        m = !coolantOff ? coolantCodes.off : coolantOff; // use the default coolant off command when an 'off' value is not specified
    } else {
        coolantOff = coolantCodes.off;
        m = coolantCodes.on;
    }

    if (!m) {
        onUnsupportedCoolant(coolant);
        m = 9;
    } else {
        if (Array.isArray(m)) {
            for (var i in m) {
                multipleCoolantBlocks.push(m[i]);
            }
        } else {
            multipleCoolantBlocks.push(m);
        }
        currentCoolantMode = coolant;
        currentCoolantTurret = turret;
        for (var i in multipleCoolantBlocks) {
            if (typeof multipleCoolantBlocks[i] == "number") {
                multipleCoolantBlocks[i] = mFormat.format(multipleCoolantBlocks[i]);
            }
        }
        return multipleCoolantBlocks; // return the single formatted coolant value
    }
    return undefined;
}

function parseCoolant(coolant, turret) {
    var localCoolant;
    if (getSpindle(TOOL) == SPINDLE_MAIN) {
        localCoolant = turret == 1 ? coolant.spindle1t1 : coolant.spindle1t2;
        localCoolant = typeof localCoolant == "undefined" ? coolant.spindle1 : localCoolant;
    } else if (getSpindle(TOOL) == SPINDLE_LIVE) {
        localCoolant = turret == 1 ? coolant.spindleLivet1 : coolant.spindleLivet2;
        localCoolant = typeof localCoolant == "undefined" ? coolant.spindleLive : localCoolant;
    } else {
        localCoolant = turret == 1 ? coolant.spindle2t1 : coolant.spindle2t2;
        localCoolant = typeof localCoolant == "undefined" ? coolant.spindle2 : localCoolant;
    }
    localCoolant = typeof localCoolant == "undefined" ? (turret == 1 ? coolant.turret1 : coolant.turret2) : localCoolant;
    localCoolant = typeof localCoolant == "undefined" ? coolant : localCoolant;
    return localCoolant;
}

function isSpindleSpeedDifferent() {
    var areDifferent = false;
    if (isFirstSection()) {
        areDifferent = true;
    }
    if (lastSpindleDirection != tool.clockwise) {
        areDifferent = true;
    }
    if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
        var _spindleSpeed = tool.surfaceSpeed * ((unit == MM) ? 1 / 1000.0 : 1 / 12.0);
        if ((lastSpindleMode != SPINDLE_CONSTANT_SURFACE_SPEED) ||
            rpmFormat.areDifferent(lastSpindleSpeed, _spindleSpeed)) {
            areDifferent = true;
        }
    } else {
        if ((lastSpindleMode != SPINDLE_CONSTANT_SPINDLE_SPEED) ||
            rpmFormat.areDifferent(lastSpindleSpeed, spindleSpeed)) {
            areDifferent = true;
        }
    }
    return areDifferent;
}

function onSpindleSpeed(spindleSpeed) {
    // Determine the machine limit based on active spindle
    var activeSpindleId = getSpindle(TOOL);
    var machineLimit = (activeSpindleId == SPINDLE_LIVE) ? 4000 : getProperty("maximumSpindleSpeed");
    var toolLimit = (tool.maximumSpindleSpeed > 0) ? Math.min(tool.maximumSpindleSpeed, machineLimit) : machineLimit;
    var clampedSpindleSpeed = Math.min(spindleSpeed, toolLimit);

    // Calculate feed adjustment factor to maintain chip load
    gFeedReduction = (spindleSpeed > 0) ? clampedSpindleSpeed / spindleSpeed : 1.0;

    if (rpmFormat.areDifferent(clampedSpindleSpeed, sOutput.getCurrent())) { // avoid redundant output of spindle speed
        writeBlock("S" + getSpindleCode(currentSection) + "=" + sOutput.format(clampedSpindleSpeed));
    }
}
function startSpindle(forceRPMMode, initialPosition) {
    var _spindleSpeed = spindleSpeed;



    var useConstantSurfaceSpeed = currentSection.getTool().getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED;
    var maximumSpindleSpeed = (tool.maximumSpindleSpeed > 0) ? Math.min(tool.maximumSpindleSpeed, getProperty("maximumSpindleSpeed")) : getProperty("maximumSpindleSpeed");
    ;
    if (getSpindle(TOOL) != 2 && _spindleSpeed > maximumSpindleSpeed) {
        _spindleSpeed = maximumSpindleSpeed;
        spindleSpeedAdjustmentFactor = maximumSpindleSpeed / spindleSpeed;
    }
    //writeComment("_spindleSpeed before calculation: " + _spindleSpeed);
    //writeComment("maximumSpindleSpeed: " + maximumSpindleSpeed);





    writeBlock("SETMS(" + getSpindleCode(currentSection) + ")");

    gSpindleModeModal.reset();
    var spindleMode;
    if (useConstantSurfaceSpeed && !forceRPMMode) {
        spindleMode = getCode("CONSTANT_SURFACE_SPEED_ON", getSpindle(TOOL));
    } else {
        spindleMode = getCode("CONSTANT_SURFACE_SPEED_OFF", getSpindle(TOOL));
    }

    if (useConstantSurfaceSpeed) {
        _spindleSpeed = tool.surfaceSpeed * ((unit == MM) ? 1 / 1000.0 : 1 / 12.0);
    }
    if(useConstantSurfaceSpeed && forceRPMMode) { // RPM mode is forced until move to initial position
        if (xFormat.getResultingValue(initialPosition.x) == 0) {
            _spindleSpeed = maximumSpindleSpeed;
        } else {
            _spindleSpeed = Math.min((_spindleSpeed * ((unit == MM) ? 1000.0 : 12.0) / (Math.PI * Math.abs(initialPosition.x * 2))), maximumSpindleSpeed);
        }
    }
    //if(currentSection.getTool().getSpindleMode() == SPINDLE_CONSTANT_SPINDLE_SPEED && currentSection.getParameter('operation-strategy') == 'turningThread'){
    //    spindleMode = getCode("CONSTANT_SURFACE_SPEED_OFF", getSpindle(TOOL));
     //   _spindleSpeed = (tool.spindleRPM*1000)/(Math.PI* getParameter("operation:threadInfoMajorDiameter"))
    //}
    writeBlock(
        spindleMode,
        "S" + getSpindleCode(currentSection) + "=" + sOutput.format(_spindleSpeed),
        getCode((tool.clockwise ? "START_SPINDLE_CW" : "START_SPINDLE_CCW"), getSpindle(TOOL))
    );

    lastSpindleMode = tool.getSpindleMode();
    lastSpindleSpeed = _spindleSpeed;
    lastSpindleDirection = tool.clockwise;
    if (machineState.isDSSVon) {
        writeBlock("_DSSV_ON(" + time + "," + amp + ")")
        machineState.isDSSVon = false
    }
}
let amp = null
let time = null

function onCommand(command) {
    switch (command) {
        case COMMAND_COOLANT_OFF:
            setCoolant(COOLANT_OFF);
            break;
        case COMMAND_COOLANT_ON:
            setCoolant(tool.coolant);
            break;
        case COMMAND_START_SPINDLE:
            break;
        case COMMAND_LOCK_MULTI_AXIS:
            writeBlock(getCode("LOCK_MULTI_AXIS", getSpindle(PART)));
            break;
        case COMMAND_UNLOCK_MULTI_AXIS:
            writeBlock(getCode("UNLOCK_MULTI_AXIS", getSpindle(PART)));
            break;
        case COMMAND_START_CHIP_TRANSPORT:
            writeBlock(mFormat.format(31));
            break;
        case COMMAND_STOP_CHIP_TRANSPORT:
            writeBlock(mFormat.format(33));
            break;
        case COMMAND_OPEN_DOOR:
            break;
        case COMMAND_CLOSE_DOOR:
            break;
        case COMMAND_BREAK_CONTROL:
            break;
        case COMMAND_TOOL_MEASURE:
            break;
        case COMMAND_ACTIVATE_SPEED_FEED_SYNCHRONIZATION:
            break;
        case COMMAND_DEACTIVATE_SPEED_FEED_SYNCHRONIZATION:
            break;
        case COMMAND_STOP:
            writeBlock(mFormat.format(0));
            forceSpindleSpeed = true;
            forceCoolant = true;
            break;
        case COMMAND_OPTIONAL_STOP:
            writeBlock(mFormat.format(1));
            forceSpindleSpeed = true;
            forceCoolant = true;
            break;
        case COMMAND_END:
            writeBlock(mFormat.format(2));
            break;
        case COMMAND_STOP_SPINDLE:
            lastSpindleSpeed = 0;
            lastSpindleDirection = undefined;
            writeBlock(getSpindle(TOOL));
            break;
        case COMMAND_ORIENTATE_SPINDLE:
            /*
            if (currentSection.getType() == TYPE_TURNING) {
              if (currentSection.spindle == SPINDLE_PRIMARY) {
                writeBlock(mFormat.format(19)); // use P or R to set angle (optional)
              } else {
                writeBlock(mFormat.format(119));
              }
            } else {
              if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1))) {
                writeBlock(mFormat.format(19)); // use P or R to set angle (optional)
              } else if (isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, -1))) {
                writeBlock(mFormat.format(119));
              } else {
                error(localize("Spindle orientation is not supported for live tooling."));
                return;
              }
            }
        */
            break;
        case COMMAND_SPINDLE_CLOCKWISE:
            writeBlock(getCode("START_SPINDLE_CW", getSpindle(TOOL)));
            break;
        case COMMAND_SPINDLE_COUNTERCLOCKWISE:
            writeBlock(getCode("START_SPINDLE_CCW", getSpindle(TOOL)));
            break;
        default:
            onUnsupportedCommand(command);
    }
}

function getG17Code() {
    return machineState.usePolarInterpolation ? 17 : 17;
}

function engagePartCatcher(engage) {
    if (engage) {
        writeBlock(getCode("PART_CATCHER_ON"), formatComment(localize("PART CATCHER ON")));
    } else {
        writeBlock(getCode("PART_CATCHER_OFF"), formatComment(localize("PART CATCHER OFF")));
        forceXYZ();
    }
}

function onSectionEnd() {

    if (machineState.isVariThreadOperation) {
        variThread.emit();
        variThread.stop();
        machineState.isVariThreadOperation = false;
    }

    machineState.isBroachingOperation = false

    if (machineState.usePolarInterpolation) {
        setPolarInterpolation(false); // disable polar interpolation mode
    }

    if (isPolarModeActive()) {
        setPolarCoordinates(false); // disable Polar coordinates mode
    }

    // cancel SFM mode to preserve spindle speed
    if (tool.getSpindleMode() == SPINDLE_CONSTANT_SURFACE_SPEED) {
        startSpindle(true, getFramePosition(currentSection.getFinalPosition()));
    }

    if (((getCurrentSectionId() + 1) >= getNumberOfSections()) ||
        (tool.number != getNextSection().getTool().number)) {
        onCommand(COMMAND_BREAK_CONTROL);
    }

    if (hasNextSection()) {
        if (getNextSection().getTool().coolant != currentSection.getTool().coolant) {
            setCoolant(COOLANT_OFF);
        }
    }

    if (true) {
        if (isRedirecting()) {
            if (firstPattern) {
                var finalPosition = getFramePosition(currentSection.getFinalPosition());
                var abc;
                if (currentSection.isMultiAxis() && machineConfiguration.isMultiAxisConfiguration()) {
                    abc = currentSection.getFinalToolAxisABC();
                } else {
                    abc = currentWorkPlaneABC;
                }
                if (abc == undefined) {
                    abc = new Vector(0, 0, 0);
                }
                // setAbsoluteMode(finalPosition, abc);
                subprogramEnd();
            }
        }
    }

    forcePolarCoordinates = false;
    forcePolarInterpolation = false;
    forceAny();

    stockForMeasure = hasParameter("operation:xStockToLeave") ? xFormat.format(getParameter("operation:xStockToLeave")) : 0
    forceMyToolChange = false
    if (machineState.isTurningOperation) {
        writeBlock("$P_PFRAME=CROT(Y,0)")
    }

    writeBlock("M1")

    // Close the Sinumerik program-structure GROUP that was opened in onSection().
    writeln("GROUP_END(0,0)");
}

function onClose() {
    // Open the EINDE PROGRAMMA group. This wraps the entire end-of-program
    // sequence so it sits at the same structural level as the per-operation
    // groups in the program.
    writeln("GROUP_BEGIN(0,\"EINDE PROGRAMMA\",0,0)");

    writeln("");
    optionalSection = false;
    setCoolant(COOLANT_OFF);

    if (getProperty("gotChipConveyor")) {
        onCommand(COMMAND_STOP_CHIP_TRANSPORT);
    }

    writeRetract(currentSection, true)

    writeBlock(getCode("STOP_SPINDLE", activeSpindle));

    if (machineState.tailstockIsActive) {
        writeBlock(getCode("TAILSTOCK_OFF"));
    }
    forceWorkPlane();

    writeBlock(getCode("DISABLE_C_AXIS", getSpindle(PART)));

    if (gotBarFeeder) {
        writeBlock(getCode("COUNT_WORKPIECE"))
        writeBlock("GOTOS");
    }

    if (gotBAxis) {
        writeBlock("TRANS_OFF");
        writeBlock("ROT");
    }

    writeln("");
    writeBlock("UNCLAMP_S4")
    writeBlock(getCode("COUNT_WORKPIECE"))
    writeBlock(getCode("OPEN_DOOR"));

    writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off

    // Close the EINDE PROGRAMMA group BEFORE subprograms and BEFORE the final '%'.
    writeln("GROUP_END(0,0)");

    if (subprograms.length > 0) {
        writeln("");
        write(subprograms);
    }
    writeln("%");
}

function getSpindleCode(section) {
    if (section.spindle == SPINDLE_PRIMARY) { // mainspindle
        if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
            return mainSpindleAxisName[1];
        } else {
            return liveToolSpindleAxisName[1]; // milling live tool
        }
    } else { // subspindle
        if (machineState.isTurningOperation || machineState.axialCenterDrilling) {
            return subSpindleAxisName[1];
        } else {
            return liveToolSpindleAxisName[1]; // milling live tool
        }
    }
}

function getNextToolDescription(description) {
    var currentSectionId = getCurrentSectionId();
    if (currentSectionId < 0) {
        return null;
    }
    for (var i = currentSectionId + 1; i < getNumberOfSections(); ++i) {
        var section = getSection(i);
        var sectionTool = section.getTool();
        if (description != sectionTool.description) {
            return sectionTool; // found next tool
        }
    }
    return null; // not found
}


function getNextToolDescription(description) {
    var currentSectionId = getCurrentSectionId();
    if (currentSectionId < 0) {
        return null;
    }
    for (var i = currentSectionId + 1; i < getNumberOfSections(); ++i) {
        var section = getSection(i);
        var sectionTool = section.getTool();
        if (description != sectionTool.description) {
            return sectionTool; // found next tool
        }
    }
    return null; // not found
}

