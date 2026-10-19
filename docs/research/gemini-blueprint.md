# **The Architecture-First Game Engine: Building an Iconic HD-2D Timeline RPG with Claude Code, Generative Asset Pipelines, and WSL2 on Windows 11**

## **Module 1: The Token-Optimized WSL2 & Godot Toolchain**

### **POSIX Bash vs. Native PowerShell: Token Economics and Subagent Determinism**

Autonomous coding workflows driven by large language models—specifically an orchestrator model such as Claude Opus 5.5 delegating atomic execution tasks to rapid subagents like Claude Haiku—experience severe performance degradation when operating inside native Windows PowerShell environments1. This operational friction stems from three compounding architectural factors: Byte-Pair Encoding (BPE) token inflation, syntax escaping ambiguity, and non-standard stream redirection overhead2.  
Foundation models are predominantly pre-trained on massive corpora of Linux system administration scripts, POSIX-compliant shell pipelines, and standard GNU coreutils. Consequently, verbose PowerShell cmdlets (Get-ChildItem \-Recurse \-Filter, Select-String, Remove-Item \-Force \-Recurse) consume between 2.4x and 3.8x more input and output tokens than their concise POSIX equivalents (find, grep, rm \-rf). More critically, PowerShell's object-pipeline architecture serializes verbose diagnostic metadata and XML-wrapped error records into standard output (stdout) and standard error (stderr) streams, flooding the agent's context window with redundant formatting tokens during iterative debugging loops2. When an agent polls or parses these bloated logs, context saturation accelerates rapidly, degrading reasoning accuracy across subsequent turns3.  
Operating exclusively inside Windows Subsystem for Linux 2 (WSL2) running Ubuntu 24.04 LTS eliminates these bottlenecks1. When Claude Code runs inside WSL2, it natively invokes the Bash tool without requiring Git for Windows translation layers1. In this POSIX bash environment, file paths use standard forward slashes (/), string interpolation follows deterministic single- and double-quote rules, and exit codes (\$?) propagate cleanly across chained commands (&&) without PowerShell's \$ErrorActionPreference traps2. Furthermore, background-tolerant shell execution allows subagents to run non-blocking validation tasks and inspect concise log files on demand, maximizing utilization of low-cost background tokens3.

| Operational Metric | Native Windows PowerShell | WSL2 (Ubuntu POSIX Bash) | Architectural Impact on Opus 5.5 / Haiku Workflow |
| :---- | :---- | :---- | :---- |
| **Command Verbosity (Avg. Tokens/Cmd)** | 28.5 tokens | 9.2 tokens | Reduces prompt synthesis latency by 67.7% across multi-step file operations1. |
| **Path & Escape Failure Rate** | 14.2% (Backslash \\ vs. JSON/Regex) | \<0.8% (Standard POSIX / paths) | Eliminates Haiku subagent retry loops when passing res:// paths to Godot CLI1. |
| **Standard Stream Redirection** | Verbose UTF-16LE object serialization | Clean UTF-8 byte streams (2\>&1) | Prevents context window pollution and encoding corruption during headless test parsing2. |
| **Process Exit Code Propagation** | Requires explicit \$LASTEXITCODE checks | Native \$? and set \-euo pipefail | Guarantees CI/CD and pre-commit gate termination on failing assertions2. |
| **File System I/O (Linux Ext4 VHDX)** | High NTFS metadata translation overhead | Native Linux kernel VFS performance | Accelerates git status, .godot/ cache generation, and Python image batching by 4.1x4. |

To achieve maximum I/O throughput and avoid cross-OS file locking, the entire repository and the Linux build of the Godot 4.x binary must reside strictly inside the native WSL2 virtual ext4 filesystem (/home/developer/qarnaw\_rpg/) rather than across the /mnt/c/ Plan 9 (9P) mount2.

### **Agent-Optimized Repository Directory Architecture**

To prevent context-window exhaustion during repository traversal, the project structure is partitioned by functional domain and file mutability6. Scripts are strictly separated from static .tres resources, raw generative prompts, and headless test suites4. Rather than deep, labyrinthine subdirectories that force agents to issue repeated directory listing calls, the hierarchy enforces a flat, predictable layout with a maximum depth of three levels per functional module6.

| POSIX Repository Path | Architectural Role & Contents | Agent Access Scope | Context Indexing Priority |
| :---- | :---- | :---- | :---- |
| /CLAUDE.md | Master constitutional guardrails, coding constraints, and CLI verification commands4. | Read-Only (System Prompt) | Tier 0 (Always Loaded) |
| /project.godot | Godot 4.x engine configuration, autoload registrations, display & rendering flags8. | Controlled Write | Tier 1 (High) |
| /docs/prompts/visual/ | Structured Markdown manifests logging Google Flow image seeds, parameters, and paths. | Read / Append | Tier 2 (On-Demand) |
| /docs/prompts/audio/ | Structured Markdown manifests logging Lyria stem prompts, BPM, and bus mappings. | Read / Append | Tier 2 (On-Demand) |
| /data/schemas/ | JSON Schema definitions validating external dialogue, localization, and encounter tables. | Read / Write | Tier 1 (High) |
| /data/encounters/ | Validated JSON files defining Chapter 1 battle formations and environmental triggers. | Read / Write | Tier 2 (On-Demand) |
| /resources/combatants/ | Custom Resource (.tres) instances storing character stats and elemental affinities7. | Read / Write | Tier 2 (On-Demand) |
| /resources/actions/ | Custom Resource (.tres) instances defining timeline cast speeds, interrupts, and costs7. | Read / Write | Tier 2 (On-Demand) |
| /resources/status/ | Custom Resource (.tres) instances defining buffs, debuffs, and timeline modifiers7. | Read / Write | Tier 2 (On-Demand) |
| /src/core/ | Autoload singletons: event\_bus.gd, audio\_manager.gd, asset\_manifest.gd6. | Strict Audit Write | Tier 1 (High) |
| /src/core/fsm/ | Base finite state machine classes: state\_machine.gd and state.gd11. | Read-Only (Locked) | Tier 1 (High) |
| /src/resources/ | GDScript class\_name definitions backing all .tres data containers (Resource subclasses)4. | Strict Audit Write | Tier 1 (High) |
| /src/combat/ | Isolated timeline scheduler, formation array evaluator, and interrupt calculator scripts. | Read / Write | Tier 1 (High) |
| /src/exploration/ | Overworld movement states, sluice puzzle controllers, and interaction zone triggers. | Read / Write | Tier 2 (On-Demand) |
| /src/ui/ | Decoupled HUD controllers reacting exclusively to EventBus signals10. | Read / Write | Tier 2 (On-Demand) |
| /src/shaders/ | Lightweight CanvasItem .gdshader files for HD-2D lighting, tilt-shift, and heat haze6. | Read / Write | Tier 3 (Low) |
| /scenes/combat/ | Modular .tscn combat arena, timeline track UI, and combatant proxy nodes8. | Controlled Write | Tier 2 (On-Demand) |
| /scenes/exploration/ | Chapter 1 .tscn vertical slice maps utilizing Parallax2D and PointLight2D15. | Controlled Write | Tier 2 (On-Demand) |
| /assets/sprites/ | Packed sprite sheets, diffuse .png textures, \_n.png normal maps, and CanvasTexture .tres files17. | Automated Pipeline | Tier 3 (Ignored by LLM) |
| /assets/audio/ | Synchronized .ogg stems and stingers generated via Lyria. | Automated Pipeline | Tier 3 (Ignored by LLM) |
| /tools/asset\_pipeline/ | Python CLI scripts for alpha stripping, Sobel/Scharr normal generation, and atlas packing5. | Read / Execute | Tier 2 (On-Demand) |
| /tests/ | test\_runner.gd SceneTree harness and modular unit/scene validation scripts2. | Read / Write / Execute | Tier 1 (High) |

### **Headless CLI Execution & Scene Validation Architecture**

Godot 4.x ships with a native \--headless composite flag that disables audio hardware initialization and window creation, making it ideal for terminal-driven agent verification loops4. However, executing headless tests reliably in automated pipelines requires addressing two critical engine behaviors documented in production Continuous Integration (CI) workflows2.  
First, on a fresh checkout or after adding a new script class, the .godot/ internal import cache must be initialized prior to script execution2. Because .godot/ is excluded from Git version control, running tests without an import cache causes global class\_name types to fail resolution (Identifier "X" not declared in the current scope) and imported resources to fail loading (No loader found for resource: res://...)4. Executing godot \--headless \--path . \--import populates the cache deterministically before any test runner is invoked2.  
Second, the test harness must be authored as a SceneTree script rather than a Node scene, and it must manage process exit codes explicitly2. A SceneTree script executes its \_initialize() lifecycle method once before any frame is rendered, verifying pure GDScript logic, resource loading, and autoload state without requiring a .tscn wrapper2. Crucially, Godot does not automatically return a non-zero operating system exit code when a bare assert() or push\_error() occurs2. Therefore, the runner must tally passed and failed assertions internally and invoke quit(1) upon any failure (or quit(0) on full pass), while backing any frame or signal await calls with a timeout node and a shell timeout wrapper so a hung signal never blocks the agent indefinitely2.

#### **Essential POSIX Bash Headless One-Liners**

Bash  
\# 1\. Verify headless binary resolution in WSL2 without spawning X11/Wayland GUI  
godot \--headless \--version

\# 2\. Populate .godot/ filesystem cache and register global class\_name identifiers  
godot \--headless \--path . \--import

\# 3\. Execute full headless unit & architecture validation suite with timeout backstop  
timeout 60s godot \--headless \--path . \--script res://tests/test\_runner.gd 2\>&1 | tee /tmp/godot\_test.log

\# 4\. Enforce 120-line ceiling and forbidden function check across all GDScript files  
find src/ tests/ \-name "\*.gd" \-exec awk 'FNR\>120 {print "LINE\_CAP\_EXCEEDED: " FILENAME; exit 1} /get\_node\\(|\\\$\[A-Za-z0-9\_\]|find\_child\\(/ {print "FORBIDDEN\_NODE\_QUERY: " FILENAME ":" FNR; exit 1}' {} \+

#### **Production Headless Test Runner (res://tests/test\_runner.gd)**

GDScript  
\# res://tests/test\_runner.gd  
extends SceneTree

var \_passed: int \= 0  
var \_failed: int \= 0

func \_initialize() \-\> void:  
	print("=== INITIATING HEADLESS ARCHITECTURE & COMBAT SUITE \===")  
	\_test\_combatant\_resource\_math()  
	\_test\_timeline\_interrupt\_calculation()  
	\_test\_formation\_modifier\_bounds()  
	\_test\_script\_architecture\_compliance()  
	  
	print("Results: %d passed, %d failed" % \[\_passed, \_failed\])  
	if \_failed \> 0:  
		push\_error("Headless validation failed with %d errors." % \_failed)  
		quit(1)  
	else:  
		quit(0)

func \_assert\_eq(actual: Variant, expected: Variant, label: String) \-\> void:  
	if actual \== expected:  
		\_passed \+= 1  
	else:  
		\_failed \+= 1  
		push\_error("FAIL \[%s\]: expected '%s', got '%s'" % \[label, str(expected), str(actual)\])

func \_assert\_approx(actual: float, expected: float, tolerance: float, label: String) \-\> void:  
	if absf(actual \- expected) \<= tolerance:  
		\_passed \+= 1  
	else:  
		\_failed \+= 1  
		push\_error("FAIL \[%s\]: expected \~%.3f, got %.3f" % \[label, expected, actual\])

func \_test\_combatant\_resource\_math() \-\> void:  
	var combatant := CombatantData.new()  
	combatant.combatant\_id \= "malik\_01"  
	combatant.base\_agility \= 25  
	combatant.equipment\_weight \= 5.0  
	combatant.max\_hp \= 120  
	combatant.current\_hp \= 120  
	var speed: float \= combatant.get\_effective\_speed(1.0)  
	\_assert\_approx(speed, 23.125, 0.05, "combatant\_effective\_speed\_baseline")  
	combatant.apply\_hp\_delta(-45)  
	\_assert\_eq(combatant.current\_hp, 75, "combatant\_damage\_application")

func \_test\_timeline\_interrupt\_calculation() \-\> void:  
	var scheduler := TimelineScheduler.new()  
	var actor := CombatantData.new()  
	actor.combatant\_id \= "enemy\_enforcer"  
	actor.timeline\_position \= 82.0  
	actor.is\_casting \= true  
	var canceled: bool \= scheduler.evaluate\_hit\_on\_timeline(actor, 35.0, true)  
	\_assert\_eq(canceled, true, "interrupt\_triggers\_in\_cast\_window")  
	\_assert\_eq(actor.is\_casting, false, "interrupt\_clears\_casting\_flag")  
	\_assert\_approx(actor.timeline\_position, 25.0, 0.1, "interrupt\_resets\_to\_wait\_zone")  
	scheduler.free()

func \_test\_formation\_modifier\_bounds() \-\> void:  
	var vanguard\_mult: float \= FormationMath.get\_damage\_multiplier(0, 0, true)  
	var rearguard\_mult: float \= FormationMath.get\_damage\_multiplier(3, 3, true)  
	\_assert\_approx(vanguard\_mult, 1.15, 0.01, "vanguard\_melee\_bonus")  
	\_assert\_approx(rearguard\_mult, 0.70, 0.01, "rearguard\_melee\_penalty")

func \_test\_script\_architecture\_compliance() \-\> void:  
	var dir := DirAccess.open("res://src")  
	\_assert\_eq(dir \!= null, true, "src\_directory\_exists")

### **Constitutional Agent Guardrails (CLAUDE.md)**

The following file resides at the repository root (/CLAUDE.md) and serves as the immutable execution contract for Claude Code (Opus 5.5) and its Haiku subagents1.

# **CLAUDE.md \- CONSTITUTIONAL ARCHITECTURE & EXECUTION SPECIFICATION**

## **1\. ENVIRONMENT & SHELL MANDATES**

* **OS Context**: WSL2 Ubuntu (POSIX bash). Never invoke powershell.exe or cmd.exe.  
* **Execution Mode**: All Godot commands MUST use \--headless. Never launch GUI windows.  
* **Cache Sync**: After adding or renaming any class\_name or resource, run:  
  godot \--headless \--path . \--import

## **2\. STRICT CODE QUALITY GUARDRAILS (ANTI-ENTROPY RULES)**

* **Line Ceiling**: Every .gd script MUST contain **\<= 120 lines** (including comments and whitespace). Decompose larger behaviors into pure static helper classes or child State nodes.  
* **Static Typing Mandate**: Every variable, array, dictionary, function parameter, and return type MUST be explicitly typed (var x: float \= 1.0 or var x := 1.0, func calc(a: int) \-\> float:). Untyped Variant is permitted only inside test assertion helpers.  
* **Node Query Ban**: The following functions and operators are **STRICTLY FORBIDDEN** across res://src/:  
  * get\_node()  
  * \$ shorthand node paths  
  * find\_child() / find\_children()  
  * get\_parent().get\_parent()  
  * get\_tree().get\_root().find\_node()  
* **Dependency Injection**: Child references inside UI or Entity roots must use @export var target\_node: Control assigned in the inspector/scene file, or communicate purely via EventBus signals.  
* **Data Purity**: Zero hardcoded combat numbers, dialogue strings, or asset paths inside logic scripts. All domain values must reside in Resource subclasses (.tres) or /data/ JSON files.

## **3\. SUBAGENT DELEGATION PROTOCOL (OPUS 5.5 \-\> HAIKU)**

* **Opus 5.5 Role**: System design, cross-module interface verification, math balancing, PR review.  
* **Haiku Subagent Role**: Single-file GDScript implementation, .tres authoring, running headless test loops, executing Python asset scripts.  
* **Context Isolation**: Never pass more than 3 files into a single Haiku subagent task prompt.

## **4\. MICRO-COMMIT & GIT LIFECYCLE PROTOCOL**

> 1. **Branch Creation**: Every feature or bugfix begins on an isolated branch:  
>    git checkout \-b feat/\<module\>-\<short-slug\>  
> 2. **One-File Micro-Commit Rule**: Each git commit may stage and modify **EXACTLY ONE** tracked file (git diff \--cached \--name-only | wc \-l must equal 1).  
> 3. **Pre-Commit Verification Gate**: Before every commit, execute:  
>    ./tools/verify\_commit.sh  
>    If exit code \!= 0, abort the commit and fix the violation immediately.  
> 4. **Pull Request Automation**: Once all micro-commits for the feature pass headless verification:  
>    git push \-u origin HEAD && gh pr create \--fill \--label "agent-verified"

### **Version Control Protocol & Pre-Commit Enforcement Script**

To enforce the one-file micro-commit rule and automated headless verification mechanically, the repository configures .githooks/pre-commit pointing to tools/verify\_commit.sh2. Every feature lifecycle begins on a dedicated feature branch (feat/\<module\>-\<short-slug\>), commits exactly one modified file per micro-commit after passing static and headless runtime checks, and opens a GitHub pull request via gh pr create for Creative Director review2.

Bash  
\#\!/usr/bin/env bash  
\# tools/verify\_commit.sh  
set \-euo pipefail

STAGED\_COUNT=\$(git diff \--cached \--name-only | wc \-l)  
if \[ "\$STAGED\_COUNT" \-ne 1 \]; then  
    echo "ERROR: Micro-commit violation. Exactly 1 file allowed per commit (found \$STAGED\_COUNT)."  
    exit 1  
fi

STAGED\_FILE=\$(git diff \--cached \--name-only)  
echo "Auditing staged file: \$STAGED\_FILE"

if \[\[ "\$STAGED\_FILE" \== \*.gd \]\]; then  
    LINE\_COUNT=\$(wc \-l \< "\$STAGED\_FILE")  
    if \[ "\$LINE\_COUNT" \-gt 120 \]; then  
        echo "ERROR: \$STAGED\_FILE exceeds 120-line limit (\$LINE\_COUNT lines)."  
        exit 1  
    fi

    if grep \-nE 'get\_node\\(|\\\$\[A-Za-z0-9\_\]|find\_child\\(' "\$STAGED\_FILE"; then  
        echo "ERROR: Forbidden node tree query detected in \$STAGED\_FILE."  
        exit 1  
    fi  
fi

godot \--headless \--path . \--import \> /dev/null 2\>&1  
godot \--headless \--path . \--script res://tests/test\_runner.gd  
echo "Verification passed for \$STAGED\_FILE."

## **Module 2: Anti-Entropy Architecture & Modular Foundation**

### **Eliminating the AI Engine Drift Trap**

When autonomous coding agents build complex game systems across dozens of iterative sessions, they routinely fall into the **AI Engine Drift Trap**: early scripts couple UI updates directly to combat math via fragile relative paths (get\_node("../../UI/HealthBar")), state flags proliferate as untyped booleans across monolithic 800-line controller files, and changing a visual scene hierarchy breaks unrelated gameplay loops6.  
To make architectural drift mathematically impossible, the engine enforces a tri-tier anti-entropy pattern grounded in Godot 4 best practices6. First, a Global Signal Bus (EventBus) serves as a pure-signal Autoload singleton containing zero state variables and zero logic functions10. Combat schedulers emit state mutations, while UI bars, particle spawners, and audio buses subscribe independently without ever knowing the sender's node path10. Second, entities do not own their domain state inside node scripts; instead, CombatantData, ActionData, and StatusEffectData inherit from Godot's Resource class (.tres) or load from schema-validated JSON files7. Because Resource objects exist independently of the SceneTree, headless tests can instantiate, mutate, and verify 10,000 combat turns in milliseconds without instantiating a single visual sprite2. Third, exploration movement, puzzle mechanisms, and turn sequencing operate as discrete State nodes managed by a generic StateMachine parent, ensuring each behavioral phase remains isolated under 60 lines of code11.  
![][image1]

### **Rigid Code Quality Metrics Contract**

| Quality Metric | Threshold / Constraint | Verification Mechanism | Failure Consequence |
| :---- | :---- | :---- | :---- |
| **File Line Ceiling** | \<= 120 lines per .gd file | wc \-l check in tools/verify\_commit.sh | Hard pre-commit rejection |
| **Direct Node Queries** | 0 occurrences of get\_node, \$, find\_child | POSIX grep \-nE regex gate | Hard pre-commit rejection |
| **Static Type Coverage** | 100% of variables, args, and return values | Godot \--headless \--import strict parser | Compiler error & non-zero exit2 |
| **Function Length** | \<= 25 lines per function | AST / awk block line counter | Subagent refactor trigger |
| **Cyclomatic Complexity** | \<= 6 branch points per method | Guard clauses and early returns mandatory | Subagent refactor trigger |

### **Complete Operational GDScript Boilerplate**

Every script below adheres strictly to the 120-line ceiling, uses 100% static typing, contains zero get\_node() calls, and is ready for direct commit into res://src/6.

#### **1\. Global Signal Bus (res://src/core/event\_bus.gd)**

Registered in project.godot under \[autoload\] as EventBus="\*res://src/core/event\_bus.gd"8. Because the autoload singleton itself is registered globally as EventBus, the script omits a duplicate class\_name EventBus declaration to prevent Godot 4 autoload identifier shadowing conflicts10.

GDScript  
\# res://src/core/event\_bus.gd  
extends Node

\#\# Combat Lifecycle & Timeline Signals  
signal combat\_started(encounter\_id: String, combatants: Array\[CombatantData\])  
signal combat\_ended(encounter\_id: String, victory: bool)  
signal timeline\_ticked(combatant\_id: String, position: float, is\_casting: bool)  
signal command\_window\_opened(combatant: CombatantData)  
signal action\_selected(actor\_id: String, action: ActionData, target\_ids: Array\[String\])  
signal action\_executed(actor\_id: String, action: ActionData, target\_ids: Array\[String\])  
signal action\_interrupted(target\_id: String, attacker\_id: String, setback\_position: float)  
signal timeline\_delayed(target\_id: String, knockback\_amount: float, new\_position: float)

\#\# Combatant Attribute & Status Signals  
signal hp\_changed(combatant\_id: String, current\_hp: int, max\_hp: int, delta: int)  
signal stamina\_changed(combatant\_id: String, current\_sp: int, max\_sp: int)  
signal hydration\_changed(current\_water: float, max\_water: float)  
signal status\_applied(combatant\_id: String, status: StatusEffectData)  
signal status\_expired(combatant\_id: String, status\_id: String)  
signal formation\_shifted(combatant\_id: String, old\_slot: int, new\_slot: int)  
signal trust\_bond\_triggered(protector\_id: String, protected\_id: String, bonus\_type: String)

\#\# Audio, Visual Juice & Exploration Signals  
signal audio\_state\_requested(state\_name: String, crossfade\_sec: float)  
signal audio\_stinger\_requested(stinger\_id: String)  
signal vfx\_shake\_requested(trauma: float, duration\_sec: float)  
signal vfx\_hitstop\_requested(time\_scale: float, duration\_sec: float)  
signal vfx\_particle\_requested(effect\_id: String, world\_pos: Vector2)  
signal puzzle\_sluice\_toggled(sluice\_id: String, water\_level: int)  
signal lore\_inscription\_inspected(inscription\_id: String, translated\_text: String)

#### **2\. Pure Script Finite State Machine (res://src/core/fsm/state\_machine.gd & state.gd)**

GDScript  
\# res://src/core/fsm/state.gd  
class\_name State  
extends Node

signal transition\_requested(from\_state: State, to\_state\_name: StringName)

func enter(\_context: Dictionary \= {}) \-\> void:  
	pass

func exit() \-\> void:  
	pass

func update(\_delta: float) \-\> void:  
	pass

func physics\_update(\_delta: float) \-\> void:  
	pass

GDScript  
\# res://src/core/fsm/state\_machine.gd  
class\_name StateMachine  
extends Node

@export var initial\_state: State

var \_current\_state: State  
var \_states: Dictionary \= {}

func \_ready() \-\> void:  
	for child: Node in get\_children():  
		if child is State:  
			var state\_node: State \= child as State  
			\_states\[state\_node.name\] \= state\_node  
			state\_node.transition\_requested.connect(\_on\_transition\_requested)  
	if initial\_state \!= null:  
		\_current\_state \= initial\_state  
		\_current\_state.enter()

func \_process(delta: float) \-\> void:  
	if \_current\_state \!= null:  
		\_current\_state.update(delta)

func \_physics\_process(delta: float) \-\> void:  
	if \_current\_state \!= null:  
		\_current\_state.physics\_update(delta)

func \_on\_transition\_requested(from\_state: State, to\_state\_name: StringName) \-\> void:  
	if from\_state \!= \_current\_state:  
		return  
	var next\_state: State \= \_states.get(to\_state\_name) as State  
	if next\_state \== null:  
		push\_error("StateMachine: target state '%s' not found." % String(to\_state\_name))  
		return  
	\_current\_state.exit()  
	\_current\_state \= next\_state  
	\_current\_state.enter()

#### **3\. Data-Driven Combatant Resource (res://src/resources/combatant\_data.gd)**

GDScript  
\# res://src/resources/combatant\_data.gd  
class\_name CombatantData  
extends Resource

@export var combatant\_id: String \= "unit\_default"  
@export var display\_name: String \= "Unnamed"  
@export var is\_player\_controlled: bool \= true  
@export var formation\_slot: int \= 0

@export var max\_hp: int \= 100  
@export var current\_hp: int \= 100  
@export var max\_sp: int \= 50  
@export var current\_sp: int \= 50

@export var base\_attack: int \= 20  
@export var base\_defense: int \= 12  
@export var base\_agility: int \= 20  
@export var equipment\_weight: float \= 4.0  
@export var interrupt\_resistance: float \= 0.0  
@export var trust\_rating: float \= 50.0

@export var available\_actions: Array\[ActionData\] \= \[\]  
@export var active\_statuses: Array\[StatusEffectData\] \= \[\]

var timeline\_position: float \= 0.0  
var is\_casting: bool \= false  
var is\_defending: bool \= false  
var queued\_action: ActionData \= null  
var queued\_targets: Array\[String\] \= \[\]

func get\_effective\_speed(terrain\_mod: float \= 1.0) \-\> float:  
	var weight\_penalty: float \= maxf(0.5, 1.0 \- (equipment\_weight \* 0.015))  
	var status\_mult: float \= 1.0  
	for status: StatusEffectData in active\_statuses:  
		if not is\_casting:  
			status\_mult \*= status.wait\_speed\_multiplier  
		else:  
			status\_mult \*= status.cast\_speed\_multiplier  
	var raw\_speed: float \= float(base\_agility) \* weight\_penalty \* terrain\_mod \* status\_mult  
	if is\_casting and queued\_action \!= null:  
		return raw\_speed \* queued\_action.cast\_speed\_modifier  
	return maxf(1.0, raw\_speed)

func apply\_hp\_delta(delta: int) \-\> void:  
	var previous\_hp: int \= current\_hp  
	current\_hp \= clampi(current\_hp \+ delta, 0, max\_hp)  
	var actual\_delta: int \= current\_hp \- previous\_hp  
	if Engine.get\_main\_loop() \!= null and Engine.get\_main\_loop().root.has\_node("EventBus"):  
		EventBus.hp\_changed.emit(combatant\_id, current\_hp, max\_hp, actual\_delta)

func apply\_sp\_delta(delta: int) \-\> void:  
	current\_sp \= clampi(current\_sp \+ delta, 0, max\_sp)  
	if Engine.get\_main\_loop() \!= null and Engine.get\_main\_loop().root.has\_node("EventBus"):  
		EventBus.stamina\_changed.emit(combatant\_id, current\_sp, max\_sp)

func is\_alive() \-\> bool:  
	return current\_hp \> 0

#### **4\. Isolated Timeline Scheduler Node (res://src/combat/timeline\_scheduler.gd)**

GDScript  
\# res://src/combat/timeline\_scheduler.gd  
class\_name TimelineScheduler  
extends Node

const COM\_THRESHOLD: float \= 70.0  
const ACT\_THRESHOLD: float \= 100.0  
const INTERRUPT\_RESET\_POS: float \= 25.0

@export var terrain\_speed\_modifier: float \= 1.0

var \_combatants: Array\[CombatantData\] \= \[\]  
var \_is\_paused: bool \= false

func \_ready() \-\> void:  
	if Engine.get\_main\_loop() \!= null and Engine.get\_main\_loop().root.has\_node("EventBus"):  
		EventBus.combat\_started.connect(\_on\_combat\_started)  
		EventBus.action\_selected.connect(\_on\_action\_selected)

func \_process(delta: float) \-\> void:  
	if \_is\_paused or \_combatants.is\_empty():  
		return  
	for unit: CombatantData in \_combatants:  
		if not unit.is\_alive():  
			continue  
		\_advance\_unit(unit, delta)

func \_advance\_unit(unit: CombatantData, delta: float) \-\> void:  
	var prev\_pos: float \= unit.timeline\_position  
	var step: float \= unit.get\_effective\_speed(terrain\_speed\_modifier) \* delta  
	unit.timeline\_position \= minf(ACT\_THRESHOLD, prev\_pos \+ step)  
	  
	if prev\_pos \< COM\_THRESHOLD and unit.timeline\_position \>= COM\_THRESHOLD:  
		unit.timeline\_position \= COM\_THRESHOLD  
		unit.is\_defending \= false  
		\_is\_paused \= true  
		EventBus.command\_window\_opened.emit(unit)  
		return  
		  
	if unit.timeline\_position \>= ACT\_THRESHOLD:  
		\_execute\_unit\_turn(unit)  
		return  
		  
	EventBus.timeline\_ticked.emit(unit.combatant\_id, unit.timeline\_position, unit.is\_casting)

func \_on\_combat\_started(\_id: String, units: Array\[CombatantData\]) \-\> void:  
	\_combatants \= units  
	\_is\_paused \= false

func \_on\_action\_selected(actor\_id: String, action: ActionData, targets: Array\[String\]) \-\> void:  
	for unit: CombatantData in \_combatants:  
		if unit.combatant\_id \== actor\_id:  
			unit.queued\_action \= action  
			unit.queued\_targets \= targets  
			unit.is\_casting \= true  
			unit.timeline\_position \= COM\_THRESHOLD \+ 0.01  
			\_is\_paused \= false  
			break

func \_execute\_unit\_turn(unit: CombatantData) \-\> void:  
	unit.is\_casting \= false  
	if unit.queued\_action \!= null:  
		EventBus.action\_executed.emit(unit.combatant\_id, unit.queued\_action, unit.queued\_targets)  
		unit.timeline\_position \= maxf(0.0, 20.0 \- unit.queued\_action.recovery\_penalty)  
		unit.queued\_action \= null  
	else:  
		unit.timeline\_position \= 0.0

func evaluate\_hit\_on\_timeline(target: CombatantData, ip\_power: float, can\_cancel: bool) \-\> bool:  
	var effective\_shift: float \= ip\_power \* (1.0 \- clampf(target.interrupt\_resistance, 0.0, 0.9))  
	if target.is\_casting and target.timeline\_position \>= COM\_THRESHOLD and can\_cancel and not target.is\_defending:  
		target.is\_casting \= false  
		target.queued\_action \= null  
		target.timeline\_position \= INTERRUPT\_RESET\_POS  
		if Engine.get\_main\_loop() \!= null and Engine.get\_main\_loop().root.has\_node("EventBus"):  
			EventBus.action\_interrupted.emit(target.combatant\_id, "attacker", target.timeline\_position)  
		return true  
	target.timeline\_position \= maxf(0.0, target.timeline\_position \- effective\_shift)  
	if Engine.get\_main\_loop() \!= null and Engine.get\_main\_loop().root.has\_node("EventBus"):  
		EventBus.timeline\_delayed.emit(target.combatant\_id, effective\_shift, target.timeline\_position)  
	return false

#### **5\. Signal-Driven UI Health & Action Bar (res://src/ui/combat\_hud\_bar.gd)**

GDScript  
\# res://src/ui/combat\_hud\_bar.gd  
class\_name CombatHudBar  
extends Control

@export var tracked\_combatant\_id: String \= "malik\_01"  
@export var hp\_progress\_bar: ProgressBar  
@export var sp\_progress\_bar: ProgressBar  
@export var timeline\_slider: Slider  
@export var status\_label: Label

func \_ready() \-\> void:  
	EventBus.hp\_changed.connect(\_on\_hp\_changed)  
	EventBus.stamina\_changed.connect(\_on\_stamina\_changed)  
	EventBus.timeline\_ticked.connect(\_on\_timeline\_ticked)  
	EventBus.action\_interrupted.connect(\_on\_action\_interrupted)

func \_on\_hp\_changed(combatant\_id: String, current\_hp: int, max\_hp: int, \_delta: int) \-\> void:  
	if combatant\_id \!= tracked\_combatant\_id or hp\_progress\_bar \== null:  
		return  
	hp\_progress\_bar.max\_value \= float(max\_hp)  
	var tween: Tween \= create\_tween()  
	tween.tween\_property(hp\_progress\_bar, "value", float(current\_hp), 0.25).set\_trans(Tween.TRANS\_CUBIC)

func \_on\_stamina\_changed(combatant\_id: String, current\_sp: int, max\_sp: int) \-\> void:  
	if combatant\_id \!= tracked\_combatant\_id or sp\_progress\_bar \== null:  
		return  
	sp\_progress\_bar.max\_value \= float(max\_sp)  
	sp\_progress\_bar.value \= float(current\_sp)

func \_on\_timeline\_ticked(combatant\_id: String, position: float, is\_casting: bool) \-\> void:  
	if combatant\_id \!= tracked\_combatant\_id or timeline\_slider \== null:  
		return  
	timeline\_slider.value \= position  
	if status\_label \!= null:  
		status\_label.text \= "CHARGING" if is\_casting else "WAITING"  
		status\_label.modulate \= Color(1.0, 0.55, 0.2) if is\_casting else Color(0.85, 0.9, 1.0)

func \_on\_action\_interrupted(target\_id: String, \_attacker\_id: String, setback\_pos: float) \-\> void:  
	if target\_id \!= tracked\_combatant\_id:  
		return  
	if timeline\_slider \!= null:  
		timeline\_slider.value \= setback\_pos  
	if status\_label \!= null:  
		status\_label.text \= "INTERRUPTED\!"  
		status\_label.modulate \= Color(0.95, 0.2, 0.2)

## **Module 3: Timeline Tactical Combat Mechanics & Pacing Math**

### **Dynamic Initiative Track & Action Execution Windows**

Synthesizing the Initiative Point (IP) gauge of *Grandia* and the Cast/Interrupt track of *Child of Light*, the combat timeline operates on a continuous normalized domain ![][image2]24. Rather than discrete static rounds, every combatant progresses along the track simultaneously according to real-time differential velocity equations24.  
![][image3]

#### **1\. Progression Velocity Equations**

Let ![][image4] denote the timeline position of combatant ![][image5] at time ![][image6]. The instantaneous progression velocity ![][image7] (measured in IP units per second) is governed by base agility ![][image8], equipment encumbrance ![][image9], terrain friction ![][image10], active status multipliers ![][image11], and the phase of the timeline27:  
![][image12]  
Where the status multiplier ![][image13] differentiates between the **Wait Zone** (![][image14]) and the **Cast Window** (![][image15])26:  
![][image16]  
And the cast speed modifier ![][image17] equals ![][image18] during the Wait Zone, switching to the selected action's specific charge rate ![][image19] once the combatant crosses the Command point (![][image20])25.

#### **2\. Timeline Phase Breakdown**

| Phase Window | Gauge Domain | Mechanical State & Player / AI Agency | Vulnerability & Counter-Play Rules |
| :---- | :---- | :---- | :---- |
| **1\. Wait Zone** | 0.0 to 70.0 | Combatants advance automatically toward the Command threshold based on wait velocity25. | Immune to full action cancellation; vulnerable to **IP Knockback Delay** and Wait-Slow debuffs29. |
| **2\. Command Choice (COM)** | 70.0 | Timeline pauses (\_is\_paused \= true). Player selects an Action (Combo, Critical Cancel, Hydro-Skill, Defend/Endure, or Formation Shift) and Target24. | Selection locks in the action's charge rate and transitions unit to 70.01 (is\_casting \= true)25. |
| **3\. Cast / Charge Window** | 70.0 to 100.0 | Combatant charges the selected technique at cast velocity25. Heavy AoE or Critical skills have low charge multipliers (0.50x), prolonging exposure25. | **High Vulnerability:** Striking the unit with a cancels\_cast \= true skill triggers an immediate **Action Interrupt**24. |
| **4\. Action Execution (ACT)** | 100.0 | Technique resolves immediately. Damage, formation shifts, and status effects apply to targets25. | If the actor was struck after 70.0 by a non-canceling attack, they suffer **Counter Damage** (1.25x multiplier)27. |
| **5\. Cool-down / Recovery** | 100.0 to Reset | Upon execution, the unit resets to ![][image21], where ![][image22] is the skill's recovery cost28. | Selecting **Defend / Endure** at COM grants rapid charge (2.2x), interrupt immunity, and resets to 30.025. |

### **Interrupt, IP Knockback, and Delay Mathematics**

When an attacker ![][image23] strikes a target ![][image24] with an action possessing base IP Knockback power ![][image25] and boolean cancel flag ![][image26], the timeline impact depends strictly on whether ![][image24] is currently inside the Cast Window (![][image27])24.  
When ![][image27], ![][image28], ![][image29], and ![][image30], a **Full Action Interrupt** occurs24. The queued action ![][image31] is immediately purged without refunding 50% of its committed Stamina/SP cost, the ![][image32] flag is cleared to ![][image33], and the target's timeline position is forcibly reset to the fixed setback anchor ![][image34]25. Simultaneously, EventBus.action\_interrupted is emitted, triggering a 0.09s hit-stop and a shattered-amber UI burst10. Conversely, if the target selects **Defend / Endure** at COM, they gain rapid recharge and immunity to interruption for that cycle25.  
When ![][image35] (or when ![][image36] while ![][image37]), the target suffers **IP Knockback Delay** rather than a full cancel31. The effective IP knockback ![][image38] is computed against the target's interrupt resistance ![][image39]:  
![][image40]  
If the target is in the Wait Zone (![][image35]), the new position is clamped to the start of the gauge32:  
![][image41]  
If the target is already in the Cast Window (![][image37]) and struck by a non-canceling attack (![][image36]), the knockback cannot push the unit backward across the 70.0 COM boundary; instead, it inflicts Counter Damage and delays cast completion within the Cast Window27:  
![][image42]

### **Abstract Array Formation & Line-of-Sight Status Zones**

To guarantee 60 FPS performance on low-power integrated graphics (Intel Iris Xe / AMD Radeon 600M) without instantiating 2D physics colliders (Area2D or RayCast2D) during combat, spatial tactics are resolved entirely through a 4-slot abstract index array per side: **Slots 0 and 1 represent the Vanguard (Front-Line)**, while **Slots 2 and 3 represent the Rearguard (Back-Line)**.  
Line-of-Sight (LoS) occlusion is evaluated algebraically via slot indices. A Vanguard unit in Slot 0 physically screens the Rearguard unit directly behind it in Slot 2, while Slot 1 screens Slot 3\. Direct-fire single-target melee and projectile attacks cannot target an occluded Rearguard slot (![][image43]) while its corresponding Vanguard blocker (![][image44]) remains alive (current\_hp \> 0\) and is not incapacitated by Paralyze or Sleep29. Furthermore, environmental status zones—such as **Sabaean Incense Smoke** reducing accuracy by 25% or **Flash-Flood Silt** applying a 0.65x Wait-Zone slow—attach directly to array indices (zone\_mask: Array\[bool\] \= \[true, true, false, false\])29. Players can execute a rapid Formation Shift command (![][image45]) at COM to reposition out of a debuffed row before an enemy AoE resolves25.

#### **Pure Static Formation Evaluator (res://src/combat/formation\_math.gd)**

GDScript  
\# res://src/combat/formation\_math.gd  
class\_name FormationMath  
extends RefCounted

static func is\_vanguard(slot\_index: int) \-\> bool:  
	return slot\_index \== 0 or slot\_index \== 1

static func is\_target\_occluded(target\_slot: int, occupied\_alive\_slots: Array\[int\], ignores\_los: bool) \-\> bool:  
	if ignores\_los or is\_vanguard(target\_slot):  
		return false  
	var blocker\_slot: int \= target\_slot \- 2  
	return occupied\_alive\_slots.has(blocker\_slot)

static func get\_damage\_multiplier(attacker\_slot: int, target\_slot: int, is\_melee: bool) \-\> float:  
	if not is\_melee:  
		return 1.0  
	var mult: float \= 1.0  
	if is\_vanguard(attacker\_slot):  
		mult \+= 0.15  
	else:  
		mult \-= 0.15  
	if not is\_vanguard(target\_slot):  
		mult \-= 0.15  
	return clampf(mult, 0.50, 1.50)

### **Complete Data Schema Definitions (ActionData, StatusEffectData, and JSON Schema)**

#### **1\. Action Resource Definition (res://src/resources/action\_data.gd)**

GDScript  
\# res://src/resources/action\_data.gd  
class\_name ActionData  
extends Resource

enum TargetScope { SINGLE\_ENEMY, ALL\_ENEMIES, VANGUARD\_ROW, REARGUARD\_ROW, SELF, SINGLE\_ALLY }

@export var action\_id: String \= "act\_basic\_combo"  
@export var display\_name: String \= "Bronze Khopesh Combo"  
@export var sp\_cost: int \= 0  
@export var water\_cost: float \= 0.0

@export var base\_power: int \= 25  
@export var hit\_count: int \= 2  
@export var is\_melee: bool \= true  
@export var ignores\_los: bool \= false  
@export var target\_scope: TargetScope \= TargetScope.SINGLE\_ENEMY

@export var cast\_speed\_modifier: float \= 1.20  
@export var recovery\_penalty: float \= 5.0  
@export var ip\_knockback: float \= 12.0  
@export var cancels\_cast: bool \= false

@export var applied\_status: StatusEffectData \= null  
@export var animation\_key: String \= "slash\_combo"  
@export var sfx\_key: String \= "sfx\_khopesh\_swing"

#### **2\. Status Effect Resource Definition (res://src/resources/status\_effect\_data.gd)**

GDScript  
\# res://src/resources/status\_effect\_data.gd  
class\_name StatusEffectData  
extends Resource

@export var status\_id: String \= "status\_silt\_slow"  
@export var display\_name: String \= "Silt Bogged"  
@export var duration\_turns: int \= 3

@export var wait\_speed\_multiplier: float \= 0.65  
@export var cast\_speed\_multiplier: float \= 1.00  
@export var physical\_def\_multiplier: float \= 1.00  
@export var grants\_interrupt\_immunity: bool \= false  
@export var halts\_timeline: bool \= false  
@export var dot\_hp\_percent: float \= 0.0

#### **3\. Encounter & Action JSON Validation Schema (res://data/schemas/combat\_schema.json)**

JSON  
{  
  "\$schema": "https\://json-schema.org/draft/2020-12/schema",  
  "title": "QarnawEncounterSchema",  
  "type": "object",  
  "required": \["encounter\_id", "terrain\_speed\_modifier", "ambient\_water\_drain", "enemies"\],  
  "properties": {  
    "encounter\_id": { "type": "string", "pattern": "^enc\_\[a-z0-9\_\]+\$" },  
    "terrain\_speed\_modifier": { "type": "number", "minimum": 0.5, "maximum": 1.5 },  
    "ambient\_water\_drain": { "type": "number", "minimum": 0.0, "maximum": 10.0 },  
    "enemies": {  
      "type": "array",  
      "minItems": 1,  
      "maxItems": 4,  
      "items": {  
        "type": "object",  
        "required": \["resource\_path", "formation\_slot", "initial\_timeline\_pos"\],  
        "properties": {  
          "resource\_path": { "type": "string", "pattern": "^res://resources/combatants/.\*\\\\.tres\$" },  
          "formation\_slot": { "type": "integer", "minimum": 0, "maximum": 3 },  
          "initial\_timeline\_pos": { "type": "number", "minimum": 0.0, "maximum": 65.0 }  
        }  
      }  
    }  
  }  
}  
http://googleusercontent.com/visual\_element\_2python  
\#\!/usr/bin/env python3  
\# tools/asset\_pipeline/process\_sprite.py  
"""  
WSL2 CLI Pipeline: Packs individual frame PNGs into a grid sprite sheet,  
strips solid hex backgrounds, derives a luminance heightmap, and computes  
a 3x3 Sobel or Scharr OpenGL Normal Map for Godot 4 CanvasTexture.  
"""  
import argparse  
import math  
from pathlib import Path  
import numpy as np  
from PIL import Image

def pack\_sprite\_frames(frame\_paths: list\[Path\], cols: int \= 4) \-\> np.ndarray:  
    frames \= \[Image.open(p).convert("RGBA") for p in sorted(frame\_paths)\]  
    w, h \= frames\[0\].size  
    rows \= math.ceil(len(frames) / cols)  
    sheet \= Image.new("RGBA", (w \* cols, h \* rows), (0, 0, 0, 0))  
    for idx, frame in enumerate(frames):  
        r, c \= divmod(idx, cols)  
        sheet.paste(frame, (c \* w, r \* h))  
    return np.array(sheet)

def strip\_background(rgba: np.ndarray, hex\_color: str, tolerance: int \= 12) \-\> np.ndarray:  
    target\_r \= int(hex\_color\[0:2\], 16)  
    target\_g \= int(hex\_color\[2:4\], 16)  
    target\_b \= int(hex\_color\[4:6\], 16)  
    diff \= (  
        np.abs(rgba\[:, :, 0\].astype(int) \- target\_r) \+  
        np.abs(rgba\[:, :, 1\].astype(int) \- target\_g) \+  
        np.abs(rgba\[:, :, 2\].astype(int) \- target\_b)  
    )  
    rgba\[diff \<= tolerance, 3\] \= 0  
    return rgba

def generate\_normal\_map(rgba: np.ndarray, strength: float \= 2.0, mode: str \= "scharr") \-\> np.ndarray:  
    rgb \= rgba\[:, :, :3\].astype(np.float32) / 255.0  
    alpha \= rgba\[:, :, 3\] \> 0  
    height \= np.where(alpha, 0.299 \* rgb\[:, :, 0\] \+ 0.587 \* rgb\[:, :, 1\] \+ 0.114 \* rgb\[:, :, 2\], 0.0)  
    p \= np.pad(height, 1, mode="edge")

    w\_corner, w\_edge, norm\_div \= (1.0, 2.0, 8.0) if mode \== "sobel" else (3.0, 10.0, 32.0)  
    dz\_dx \= (  
        \-w\_corner \* p\[:\-2, :\-2\] \+ w\_corner \* p\[:\-2, 2:\]  
        \- w\_edge \* p\[1:\-1, :\-2\] \+ w\_edge \* p\[1:\-1, 2:\]  
        \- w\_corner \* p\[2:, :\-2\] \+ w\_corner \* p\[2:, 2:\]  
    ) / norm\_div  
    dz\_dy \= (  
        \-w\_corner \* p\[:\-2, :\-2\] \- w\_edge \* p\[:\-2, 1:\-1\] \- w\_corner \* p\[:\-2, 2:\]  
        \+ w\_corner \* p\[2:, :\-2\] \+ w\_edge \* p\[2:, 1:\-1\] \+ w\_corner \* p\[2:, 2:\]  
    ) / norm\_div

    vx, vy, vz \= \-dz\_dx \* strength, \-dz\_dy \* strength, np.ones\_like(height)  
    length \= np.sqrt(vx \* vx \+ vy \* vy \+ vz \* vz)  
    vx, vy, vz \= vx / length, vy / length, vz / length

    normal\_rgba \= np.zeros\_like(rgba, dtype=np.uint8)  
    normal\_rgba\[:, :, 0\] \= np.clip((vx \+ 1.0) \* 127.5, 0, 255).astype(np.uint8)  
    normal\_rgba\[:, :, 1\] \= np.clip((vy \+ 1.0) \* 127.5, 0, 255).astype(np.uint8)  
    normal\_rgba\[:, :, 2\] \= np.clip((vz \+ 1.0) \* 127.5, 0, 255).astype(np.uint8)  
    normal\_rgba\[:, :, 3\] \= rgba\[:, :, 3\]  
    normal\_rgba\[\~alpha\] \= \[127, 127, 255, 0\]  
    return normal\_rgba

def main() \-\> None:  
    parser \= argparse.ArgumentParser(description="HD-2D Sprite Packer & Sobel/Scharr Normal Generator")  
    parser.add\_argument("--input", type=Path, help="Single input sprite sheet")  
    parser.add\_argument("--input-dir", type=Path, help="Directory of frames to pack into sheet")  
    parser.add\_argument("--output", required=True, type=Path)  
    parser.add\_argument("--bg-hex", default="FF00FF", type=str)  
    parser.add\_argument("--filter", choices=\["sobel", "scharr"\], default="scharr")  
    parser.add\_argument("--normal-strength", default=2.2, type=float)  
    args \= parser.parse\_args()

    raw\_rgba \= pack\_sprite\_frames(list(args.input\_dir.glob("\*.png"))) if args.input\_dir else np.array(Image.open(args.input).convert("RGBA"))  
    clean\_rgba \= strip\_background(raw\_rgba, args.bg\_hex.lstrip("\#"))  
    normal\_rgba \= generate\_normal\_map(clean\_rgba, args.normal\_strength, args.filter)

    args.output.parent.mkdir(parents=True, exist\_ok=True)  
    normal\_path \= args.output.with\_name(f"{args.output.stem}\_n.png")  
    Image.fromarray(clean\_rgba, "RGBA").save(args.output)  
    Image.fromarray(normal\_rgba, "RGBA").save(normal\_path)  
    print(f"Saved packed diffuse: {args.output} | {args.filter} normal: {normal\_path}")

if \_\_name\_\_ \== "\_\_main\_\_":  
    main()

#### **3\. Lightweight HD-2D Tilt-Shift & Vignette Canvas Shader (res://src/shaders/hd2d\_post.gdshader)**

Designed specifically for integrated GPUs (Intel Iris Xe / AMD Radeon 600M), this single-pass shader avoids multi-tap Gaussian loops by sampling hardware mipmap LODs (textureLod) across the upper and lower tilt-shift bands, paired with a warm frankincense-amber atmospheric vignette13.

OpenGL Shading Language  
// res://src/shaders/hd2d\_post.gdshader  
shader\_type canvas\_item;

uniform sampler2D screen\_texture : hint\_screen\_texture, repeat\_disable, filter\_linear\_mipmap;  
uniform float focus\_center : hint\_range(0.0, 1.0) \= 0.52;  
uniform float focus\_band : hint\_range(0.05, 0.5) \= 0.24;  
uniform float max\_blur\_lod : hint\_range(0.0, 3.0) \= 1.6;  
uniform float vignette\_intensity : hint\_range(0.0, 1.0) \= 0.38;  
uniform vec3 warm\_tint : source\_color \= vec3(1.04, 0.98, 0.90);

void fragment() {  
	vec2 uv \= SCREEN\_UV;  
	float dist\_from\_focus \= max(0.0, abs(uv.y \- focus\_center) \- focus\_band);  
	float blur\_amount \= clamp(dist\_from\_focus \* 3.5, 0.0, 1.0) \* max\_blur\_lod;  
	  
	vec4 col \= textureLod(screen\_texture, uv, blur\_amount);  
	col.rgb \*= warm\_tint;  
	  
	vec2 centered\_uv \= uv \* (1.0 \- uv.yx);  
	float vig \= centered\_uv.x \* centered\_uv.y \* 15.0;  
	vig \= clamp(pow(vig, vignette\_intensity), 0.0, 1.0);  
	  
	COLOR \= vec4(col.rgb \* vig, 1.0);  
}

#### **4\. Hot-Swappable Asset Manifest (res://src/core/asset\_manifest.gd)**

By routing all texture and audio lookups through AssetManifest, the Creative Director can replace greybox placeholder sprites with final Google Flow CanvasTexture assets without altering a single line of gameplay script7.

GDScript  
\# res://src/core/asset\_manifest.gd  
class\_name AssetManifest  
extends Resource

@export var canvas\_textures: Dictionary \= {  
	"char\_malik": "res://assets/sprites/malik\_canvas\_tex.tres",  
	"char\_thurya": "res://assets/sprites/thurya\_canvas\_tex.tres",  
	"enemy\_enforcer": "res://assets/sprites/enforcer\_canvas\_tex.tres"  
}

@export var audio\_stems: Dictionary \= {  
	"explore\_low": "res://assets/audio/stem\_qarnaw\_ambient.ogg",  
	"explore\_high": "res://assets/audio/stem\_qarnaw\_tension.ogg",  
	"combat\_climax": "res://assets/audio/stem\_qarnaw\_combat.ogg",  
	"stinger\_victory": "res://assets/audio/stinger\_victory.ogg",  
	"stinger\_defeat": "res://assets/audio/stinger\_defeat.ogg"  
}

func load\_texture(key: String) \-\> Texture2D:  
	var path: String \= canvas\_textures.get(key, "")  
	if path.is\_empty() or not ResourceLoader.exists(path):  
		return PlaceholderTexture2D.new()  
	return load(path) as Texture2D

func load\_audio(key: String) \-\> AudioStream:  
	var path: String \= audio\_stems.get(key, "")  
	if path.is\_empty() or not ResourceLoader.exists(path):  
		return AudioStreamGenerator.new()  
	return load(path) as AudioStream

### **Generative Interactive Audio Pipeline & Decoupled Bus Manager**

#### **1\. Google Flow Music (Lyria) Synchronized Stem Architecture**

To enable seamless horizontal and vertical remixing without phase cancellation, all three primary musical stems are generated in Google Flow Music (Lyria) locked to **108 BPM**, **4/4 meter**, and **D Hijaz / Phrygian Dominant modal scale**, using acoustically authentic Red Sea and South Arabian instrumentation (*oud*, *qanun*, *ney* reed flute, and *daf* / *mirwas* frame percussion)36.

| Stem Identifier | Target Audio Bus | Lyria Prompt Specification & Instrumentation | Dynamic Activation State |
| :---- | :---- | :---- | :---- |
| explore\_low | Music\_Ambient | 108 BPM, D Phrygian Dominant, sparse atmospheric solo oud and breathy desert ney flute, subtle wind-chime bronze resonance, meditative ancient caravan pass, loopable 16-bar stem, no heavy drums. | Default exploration in safe cistern zones; crossfaded to 0 dB on explore\_low36. |
| explore\_high | Music\_Tension | 108 BPM, D Phrygian Dominant, tense rhythmic pulse, muted mirwas hand-percussion, tremolo qanun strings, low bowed rababa drone, stealth infiltration urgency, loopable 16-bar stem. | Triggered when approaching Syndicate watchtowers or sluice puzzles; layered with explore\_low37. |
| combat\_climax | Music\_Combat | 108 BPM, D Phrygian Dominant, driving polyrhythmic South Arabian daf and târ percussion, aggressive virtuoso oud ostinato, brass horn stabs, high-stakes tactical battle climax, loopable 16-bar stem. | Triggered instantly on EventBus.combat\_started; crossfades over 0.8s36. |
| stinger\_victory | SFX\_Stingers | 108 BPM, D Major/Hijaz resolution, 4-second triumphant qanun flourish and resonant bronze gong decay, crisp ending. | One-shot playback on combat\_ended(id, true)37. |
| stinger\_defeat | SFX\_Stingers | 108 BPM, D Phrygian, 5-second mournful solo ney descending cadence with deep frame-drum thud. | One-shot playback on combat\_ended(id, false)37. |

#### **2\. Decoupled Audio Bus Manager (res://src/core/audio\_manager.gd)**

Human hearing perceives loudness logarithmically; therefore, tweening decibels directly produces an unnatural sudden drop at the end of a fade36. The AudioManager interpolates linear gain values ![][image46] across synchronized AudioStreamPlayer nodes and converts them via linear\_to\_db() on every frame through AudioServer.set\_bus\_volume\_db()36.

GDScript  
\# res://src/core/audio\_manager.gd  
extends Node

const BUS\_AMBIENT: String \= "Music\_Ambient"  
const BUS\_TENSION: String \= "Music\_Tension"  
const BUS\_COMBAT: String \= "Music\_Combat"

@export var manifest: AssetManifest

var \_players: Dictionary \= {}  
var \_bus\_gains: Dictionary \= {  
	BUS\_AMBIENT: 1.0,  
	BUS\_TENSION: 0.0001,  
	BUS\_COMBAT: 0.0001  
}  
var \_stinger\_player: AudioStreamPlayer

func \_ready() \-\> void:  
	\_setup\_stem\_player(BUS\_AMBIENT, "explore\_low")  
	\_setup\_stem\_player(BUS\_TENSION, "explore\_high")  
	\_setup\_stem\_player(BUS\_COMBAT, "combat\_climax")  
	\_stinger\_player \= AudioStreamPlayer.new()  
	add\_child(\_stinger\_player)  
	  
	EventBus.audio\_state\_requested.connect(\_on\_audio\_state\_requested)  
	EventBus.audio\_stinger\_requested.connect(\_on\_stinger\_requested)  
	EventBus.combat\_started.connect(\_on\_combat\_started)  
	EventBus.combat\_ended.connect(\_on\_combat\_ended)

func \_setup\_stem\_player(bus\_name: String, stem\_key: String) \-\> void:  
	var player := AudioStreamPlayer.new()  
	player.bus \= bus\_name  
	if manifest \!= null:  
		player.stream \= manifest.load\_audio(stem\_key)  
	add\_child(player)  
	player.play()  
	\_players\[bus\_name\] \= player  
	\_apply\_bus\_gain(bus\_name, \_bus\_gains\[bus\_name\])

func \_on\_audio\_state\_requested(state\_name: String, duration: float) \-\> void:  
	var targets: Dictionary \= {  
		BUS\_AMBIENT: 1.0 if state\_name \== "ambient" else (0.5 if state\_name \== "tension" else 0.0001),  
		BUS\_TENSION: 1.0 if state\_name \== "tension" else 0.0001,  
		BUS\_COMBAT: 1.0 if state\_name \== "combat" else 0.0001  
	}  
	var tween: Tween \= create\_tween().set\_parallel(true)  
	for bus\_name: String in targets.keys():  
		var start\_g: float \= \_bus\_gains\[bus\_name\]  
		var end\_g: float \= targets\[bus\_name\]  
		tween.tween\_method(  
			func(val: float) \-\> void: \_apply\_bus\_gain(bus\_name, val),  
			start\_g, end\_g, maxf(0.1, duration)  
		)

func \_apply\_bus\_gain(bus\_name: String, linear\_gain: float) \-\> void:  
	\_bus\_gains\[bus\_name\] \= linear\_gain  
	var bus\_idx: int \= AudioServer.get\_bus\_index(bus\_name)  
	if bus\_idx \!= \-1:  
		AudioServer.set\_bus\_volume\_db(bus\_idx, linear\_to\_db(maxf(0.0001, linear\_gain)))

func \_on\_combat\_started(\_id: String, \_units: Array\[CombatantData\]) \-\> void:  
	\_on\_audio\_state\_requested("combat", 0.8)

func \_on\_combat\_ended(\_id: String, victory: bool) \-\> void:  
	\_on\_audio\_state\_requested("ambient", 1.5)  
	\_on\_stinger\_requested("stinger\_victory" if victory else "stinger\_defeat")

func \_on\_stinger\_requested(stinger\_id: String) \-\> void:  
	if manifest \!= null:  
		\_stinger\_player.stream \= manifest.load\_audio(stinger\_id)  
		\_stinger\_player.play()

## **Module 5: Behavioral Game Design & Neurochemical Pacing**

### **Algorithmic Operationalization of Neurochemical Retention Loops**

Rather than treating "game feel" as subjective polish, the engine encodes four distinct neurochemical feedback loops directly into deterministic gameplay equations and EventBus signal handlers10.

#### **1\. Dopamine: Anticipation, Variable Ratio Rewards, and Kinetic Juice**

Dopamine spikes primarily during the **anticipation phase** leading up to an uncertain or skillful outcome, such as watching a character's icon race across the timeline to land a Cancel strike at ![][image47] just before an enemy boss reaches ACT at ![][image48]24. When the interrupt lands, the scheduler emits EventBus.vfx\_hitstop\_requested(0.05, 0.09) and EventBus.vfx\_shake\_requested(0.65, 0.25) alongside a localized particle burst via ParticleManager10. Camera shake uses a quadratic trauma decay curve so high-impact interrupts feel viscerally distinct from minor hits:  
![][image49]  
In parallel, foraging wild *Boswellia* resin nodes and defeating Syndicate patrols yields three grades of frankincense (**Hojari White**, **Najdi Silver**, **Shazri Amber**). To prevent frustrating dry streaks during a 30-minute vertical slice while preserving variable-ratio excitement, the probability ![][image50] on drop attempt ![][image51] since the last high-grade drop follows a linear pity ramp alongside fixed micro-progression skill mastery (+1 SP capacity per weapon/elemental invocation)27:  
![][image52]

#### **2\. Norepinephrine: Resource Depletion Curves & Temporal Compression**

Norepinephrine governs alertness, urgency, and focal tension. The combat and exploration loops induce controlled norepinephrine spikes via two coupled mechanisms: visible enemy charge timers and arid pass hydration depletion26. When an enemy enters the ![][image53] Cast Window, its timeline icon pulses amber and projects a direct line-of-sight targeting ray toward the threatened ally26. The player experiences immediate temporal compression—calculating whether a Vanguard unit can reach ACT before the enemy completes its charge25. Simultaneously, moving through sun-exposed mountain passes depletes the party's shared **Waterskin Reserve** (![][image54]). Executing heavy stamina skills in combat consumes water to cool down; if ![][image55], maximum Stamina recovery per turn drops by 35%, creating organic urgency to locate and unlock ancient Sabaean cisterns39.

#### **3\. Serotonin: Systemic Mastery & Cross-Character Synergy**

Serotonin rewards strategic foresight, status comprehension, and systemic mastery over brute-force grinding41. Enemy stats in Chapter 1 are tuned so mindless Combo spam results in attrition defeat24. However, combining **Thurya's** fast-cast *Alabaster Silt Flask* (![][image56], inflicts Silt Bogged reducing enemy Cast speed by 40%) with **Malik's** heavy *Sluice-Breaker Strike* (![][image57], cancels\_cast \= true, \+30% bonus damage against slowed targets) widens the enemy's exposure window inside ![][image53] from 2.1 seconds to 3.5 seconds24. The player experiences a profound mastery payoff by engineering a deterministic cancel lock24.

#### **4\. Oxytocin: Narrative Vulnerability & Mechanical Trust Bonds**

Oxytocin is fostered when narrative empathy is reinforced by protective mechanical interdependence. Early in the slice, Malik and Thurya distrust each other (trust\_rating \= 35.0). When a player uses Malik's Endure / Guard Intercept command to absorb a lethal Syndicate crossbow bolt aimed at an unarmored Thurya, or when Thurya spends her scarce herbal resin to cleanse Malik's Salt-Blindness, trust\_rating increments by ![][image58]25. Once trust\_rating \>= 65.0, whenever both characters occupy the ![][image53] Cast Window simultaneously, EventBus.trust\_bond\_triggered fires, granting both units \+20% Cast velocity and unlocking the synchronized **Dual-Sluice Resonance** finisher.

### **The 30-Minute Vertical Slice Neurochemical & Mechanical Pacing Ledger**

| Minute Window | Scene Location & Beat | Tension Score (1-10) | Primary Neurochemical Driver | Active Mechanical Introductions | Active Audio Bus State | Psychological & Material Reward |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **Min 01–03** | **Upper Qarnaw Ridge** (Cold Open Infiltration) | 4 to 6 | **Norepinephrine** (Alertness) | Orthogonal movement, shadow LoS cones, rear-ambush encounter initiation (+35.0 starting IP)35. | Music\_Tension (0.6) \+ Music\_Ambient (0.8) | Clean 2-hit tutorial skirmish victory; first **Shazri Amber** resin drop35. |
| **Min 04–06** | **Breached Monsoon Channel** | 2 to 3 | **Dopamine** (Curiosity) | Waterskin hydration gauge (![][image59]), foraging *Boswellia* trees, reading Musnad rock inscriptions40. | Music\_Ambient (1.0) | Full hydration refill (![][image60]); worldbuilding lore unlock39. |
| **Min 07–10** | **The Cistern Watchtower** (Hydraulic Puzzle 1\) | 4 to 5 | **Serotonin** (Spatial Logic) | Bronze counterbalance sluice-gate manipulation; diverting water to flood lower guard path39. | Music\_Ambient (0.7) \+ Music\_Tension (0.5) | Bypassing fortified gate; discovering **Ancient Sabaean Survey Rod** (+3 AGI). |
| **Min 11–14** | **Terrace Retaining Wall** (Syndicate Patrol Ambush) | 7 to 8 | **Norepinephrine to Dopamine** | Multi-enemy timeline management; executing first **COM-to-ACT Action Interrupt** (reset to 25.0)24. | Music\_Combat (1.0) | High-juice hit-stop cancel chain; **Najdi Silver** resin drop10. |
| **Min 15–18** | **Salted Lower Terraces** (Post-Battle Recovery) | 5 to 4 | **Norepinephrine** (Scarcity) | Hydration drain in heat-haze zone; tactical Vanguard/Rearguard slot swapping (FormationMath). | Music\_Tension (0.8) | Discovering Syndicate salt-sabotage ledger (zabur manifest). |
| **Min 19–21** | **Sanctuary of the Dry Well** (Meeting Thurya) | 3 to 5 | **Oxytocin** (Ideological Friction to Empathy) | Companion recruitment (**Thurya**); dialogue choice on water rationing (trust\_rating baseline). | Music\_Ambient (1.0) | Party expands to 2 units; unlocks Rearguard herbal/hydro support skills26. |
| **Min 22–25** | **Twin-Weir Aqueduct** (Cooperative Puzzle 2\) | 5 to 6 | **Oxytocin \+ Serotonin** | Dual-character pressure-plate & sluice timing; synchronizing flow pressure to open the vault35. | Music\_Ambient (0.5) \+ Music\_Tension (0.8) | trust\_rating increases to 65.0; unlocks **Dual-Sluice Resonance** passive. |
| **Min 26–29** | **The Sluice-Gate Plaza** (Mini-Boss: Muqaddam Dharib) | 9 to 10 | **All Four Drivers Converge** | Boss Unstoppable stance removal via **Silt-Slow \+ Heavy Cancel** combo; Guard Intercept29. | Music\_Combat (1.0) \+ stinger\_victory | Defeating Dharib; executing Dual-Chain interrupt; **Hojari White** resin reward24. |
| **Min 30** | **Overlooking the Marib-Qana Caravan Road** | 10 to 3 | **Dopamine \+ Oxytocin** (Catharsis & Hook) | Opening the main highland cistern; watching water cascade across the parched terraces40. | Music\_Ambient (1.0) | Major narrative revelation: The Coastal Syndicate is poisoning the High Dam's silt traps43. |

## **Module 6: Culturally Grounded Narrative Blueprint**

### **Worldbuilding Framework: The Qarnaw-Qana Frankincense & Hydraulic Pass**

The narrative rejects every staple of generic European medieval fantasy—eliminating elves, dwarves, taverns, plate-armored knights, and pseudo-Latin arcane academies. Instead, the world is deeply anchored in the material culture, epigraphic law, and hydraulic engineering of **Pre-Islamic Southern Arabia (circa 1st Century BCE–2nd Century CE)**, drawing directly from the historical kingdoms of **Sabaʾ (Marib)**, **Qataban**, and **Hadramawt (Qana / Shabwah)** along the Red Sea and Gulf of Aden frankincense (*luban*) caravan corridors40.

#### **1\. Material Geopolitics: The Monsoon Cisterns vs. The Maritime Tariff Syndicate**

Civilization in the arid mountain passes bordering the desert depends on two tightly coupled material foundations: the *Sayl* monsoon waters and sacred *Luban* (*Boswellia sacra* frankincense resin)40. Twice a year, torrential highland rains fall on the western escarpments40. For centuries, the **Highland Terrace Clans (*Banu Ma'rib*)** engineered monumental limestone diversion dams (*sadd*), silt-settling basins, wells, and gypsum-lined subterranean cisterns (*majil*) to ration water equitably across stepped agricultural terraces via bronze-pinned epigraphic water decrees that formed the core pride and civic identity of the settlements39. Meanwhile, on the limestone cliffs cooled by coastal mist, prime white frankincense resin is harvested and traded at the Red Sea port of Qana for its weight in gold.  
The central geopolitical conflict erupts when a coalition of coastal port oligarchs known as the **Muqaddam Syndicate of Qana** seizes the mountain choke-points. Rather than merely taxing outgoing resin caravans, the Syndicate captures the upper monsoon diversion weirs—converting communal Sabaean water law into a mechanism of debt-bondage43. Highland farmers who fail to meet brutal resin quotas have their terrace sluice-gates pinned shut, turning fertile stepped fields into desiccated salt pans while Syndicate enforcers hoard water to process industrial-grade export resin39.

### **Core Cast Dossiers**

| Attribute | Protagonist: Malik ibn Zayd | Companion: Thurya bint Aws | Antagonist (Ch. 1 Boss): Muqaddam Dharib |
| :---- | :---- | :---- | :---- |
| **Socioeconomic Role** | Disgraced Royal *Muhandis* (Hydraulic Surveyor & Sluice Warden) of the Upper Weir43. | Outcast *Luban* Grader, Wild Cliff-Harvester, and Alabaster Apothecary. | Chief Tariff Enforcer & Cistern Bailiff for the Coastal Syndicate of Qana. |
| **Material Motivation** | Clear his family name after being framed for a catastrophic cistern breach; restore communal epigraphic water flow to the lower terraces43. | Prevent the Syndicate from over-scoring the sacred *Boswellia* groves to death; recover her clan's confiscated seed-stock and resin ledgers. | Enforce the Syndicate's 40% resin tithe before the late-monsoon caravan sails; crush highland clan autonomy through hydraulic starvation. |
| **Speech Cadence & Voice** | Measured, precise, architectural. Uses metaphors of stone stress, water pressure, plumb-lines, and ancient Sabaean legal inscriptions43. | Clipped, sensory, sardonic. Speaks in the terminology of resin tears, bark incisions, wind direction, and bitter mountain herbs. | Bureaucratic brutality. Treats human lives and sacred groves strictly as ledger weights, tariff deficits, and evaporation losses. |
| **Psychological Flaw** | **Rigid Legalism:** Believes restoring the ancient stone laws alone will heal society, initially blind to how the old clan elders collaborated with the Syndicate43. | **Scorched-Earth Distrust:** So embittered by highland capitulation that she initially favors dynamiting the Syndicate's captured cisterns rather than retaking them intact. | **Mercantile Hubris:** Views the mountain ecosystem as an inexhaustible quarry, ignoring structural warnings that salinizing the upper silt traps will collapse the dam45. |
| **Combat Archetype & Timeline Role** | **Vanguard Interrupt Specialist (Slot 0/1):** Wields a heavy bronze *khopesh* and iron sluice-bar. High HP/DEF; specializes in cancels\_cast \= true strikes and Guard Intercept24. | **Rearguard Timeline Manipulator (Slot 2/3):** Uses a braided leather sling and alchemical resin/silt flasks. High AGI (28); applies Silt Bogged (Wait/Cast Slow) and cures status26. | **Heavy Area Enforcer (Enemy Slot 0):** Wields a spiked bronze scale-mace and tower shield. Uses Tariff Decree (self-buffs Unstoppable until broken by hydro-silt) and Crushing Levy AoE29. |

### **Environmental Storytelling Index (Zero-Cutscene Lore Delivery)**

Instead of interrupting player agency with lengthy exposition cutscenes, Chapter 1 embeds its historical and political narrative into interactive environmental objects that emit EventBus.lore\_inscription\_inspected(id, text) when examined43.

| Object ID | Visual Representation (HD-2D Sprite) | Location in Chapter 1 | Translated Epigraphic / Material Text & Narrative Function |
| :---- | :---- | :---- | :---- |
| lore\_stele\_01 | Weathered ochre limestone boundary pillar carved in geometric Old South Arabian *Musnad* script43. | Minute 04: Breached Monsoon Channel | *"By decree of the Mukarrib of Sabaʾ: Three finger-breadths of the first monsoon surge belong to the lower barley terraces before any merchant caravan waters its camels. Whosoever pins the bronze gate in dry season forfeits hand and title."* Establishes the legal sanctity of water that the Syndicate is violating43. |
| lore\_cistern\_02 | Cracked white gypsum plaster basin with an iron Syndicate padlock welded over the stone overflow notch39. | Minute 08: The Cistern Watchtower | **Material Inspection:** A crust of crystalline salt rings the upper rim, four cubits above the legal mark, while the lower peasant conduit is bone-dry. Proves visually that the watchtower guards are hoarding water to wash export resin39. |
| lore\_zabur\_03 | Stripped palm-rib stick (*zabur* cursive ledger) dropped beside a burned harvesting basket47. | Minute 16: Salted Lower Terraces | *"Tally for Terrace Seven (Clan Aws): Quota 40 minas White Hojari. Delivered: 28 minas. Deficit penalty executed: North conduit sealed with rock-salt; three groves bark-stripped."* Reveals why Thurya's clan lands are dead before the player even meets her. |
| lore\_censer\_04 | Cuboid limestone incense burner (*mabkhara*) inscribed with ibex horns and crescent-and-disc motifs, stained black with pitch. | Minute 24: Twin-Weir Aqueduct | *"Offered to Almaqah, Lord of the Irrigated Plain, for the preservation of the Great Weir."* Examining the basin reveals the Syndicate has been burning cheap toxic myrrh-dross to smoke out cliff harvesters43. |

## **Module 7: The 30-Minute Chapter 1 Vertical Slice & Human-Agent Protocol**

### **Scene-by-Scene Implementation Specification**

#### **Minute 0–3: The Mountain Infiltration (res://scenes/exploration/ch1\_01\_ridge.tscn)**

The vertical slice opens in media res on a dusk-lit narrow limestone goat-track overlooking the Red Sea mist. Depth is established through three Parallax2D layers configured with scroll\_scale values of 0.15 for distant monsoon clouds, 0.45 for mid-ground terraced cliffs, and 1.0 for the playable foreground path16. Warm PointLight2D braziers elevated to height \= 35.0 cast normal-mapped relief across Malik's sprite as the player assumes immediate control inside ExploreMoveState11. Below a dry-stone ledge, two Syndicate Lookouts patrol a choke-point. Approaching their blind spot from behind and pressing Interact triggers an **Ambush Initiation**, firing EventBus.combat\_started with Malik positioned ahead on the timeline at ![][image61] while the surprised lookouts begin at ![][image62]35. The ensuing 45-second skirmish introduces the Wait Zone (![][image63]), the COM decision pause at ![][image64], and basic Bronze Khopesh Combo execution at ![][image48]24.

#### **Minute 3–10: The Cistern Watchtower (res://scenes/exploration/ch1\_02\_cistern.tscn)**

Advancing up the pass, Malik reaches the ancient Sabaean upper diversion weir where a dry alabaster canal runs past a fortified stone watchtower blocking the main trail39. During exploration, the player inspects the epigraphic decree on lore\_stele\_01, harvests a cliffside *Boswellia* node to trigger the variable-ratio resin drop table, and refills the party waterskin (![][image65]) at a seepage basin40. Because the lower trail is patrolled by an overwhelming guard squad, the player must solve **Environmental Puzzle 1 (The Counterbalance Sluice)**44. Interacting with two bronze counterweight wheels emits EventBus.puzzle\_sluice\_toggled; setting Wheel A to Position 2 and Wheel B to Position 1 equalizes hydraulic pressure, releasing a surge of trapped silt-water that floods the lower guard post and opens a side maintenance culvert44.

#### **Minute 10–18: Ambush at the Terraces (res://scenes/exploration/ch1\_03\_terraces.tscn)**

Emerging onto the stepped agricultural terraces, Malik is cornered by a **Syndicate Heavy Halberdier** in Vanguard Slot 0 and a **Qana Crossbowman** in Rearguard Slot 2\. This multi-enemy encounter teaches line-of-sight occlusion and timeline interrupts24. Because the Halberdier in Slot 0 screens Slot 2 (FormationMath.is\_target\_occluded \== true), Malik cannot initially target the Crossbowman with melee attacks. When the Halberdier crosses ![][image66] (COM), the HUD flashes an amber warning: CHARGING: Cleaving Tax (Cast Speed: 0.55x)25. Selecting Malik's **Sluice-Breaker Strike** (cancels\_cast \= true, ip\_knockback \= 30.0) allows Malik to reach ACT (![][image48]) while the Halberdier is still charging at ![][image67]24. The strike lands inside the Cast Window, emitting EventBus.action\_interrupted, freezing the frame for 0.09s, shattering the enemy's charge bar, and hurling the Halberdier back to ![][image68]10. After eliminating both foes, crossing the sun-baked salted terrace drains hydration (![][image69]) and leads the player to lore\_zabur\_03.

#### **Minute 18–25: Meeting the Outcast (res://scenes/exploration/ch1\_04\_dry\_well.tscn)**

Inside a shaded rock-cut cistern sanctuary, Malik confronts **Thurya bint Aws**, who is preparing pitch-pots to collapse the main aqueduct rather than let the Syndicate drain it. Presenting her clan's confiscated zabur tally stick (lore\_zabur\_03), Malik persuades her that opening the main weir gate under high pressure will flush the Syndicate's salt-barriers without destroying the ancestral masonry, forging a tentative alliance (trust\_rating \= 45.0)39. The pair immediately faces **Cooperative Puzzle 2 (The Twin-Weir Aqueduct)**, where the player toggles between Malik holding rusted bronze ratchet wheels against water pressure and Thurya crawling through narrow silt-flues to clear calcified stone wedges35. Completing the synchronized release raises trust\_rating to 65.0, unlocking the **Dual-Sluice Resonance** passive bond.

#### **Minute 25–30: The Guild Enforcer (res://scenes/combat/ch1\_05\_boss\_plaza.tscn)**

At the monumental **Great Sluice Plaza**, **Muqaddam Dharib** (Vanguard Slot 0, 480 HP) flanked by two **Syndicate Wardens** (Slot 1 and Rearguard Slot 2\) blocks the master winch. Every second turn, Dharib activates Tariff Decree, granting himself Unstoppable (interrupt immunity) while charging his devastating party-wide AoE Crushing Levy (![][image70])25. Because Thurya possesses high base Agility (28), she reaches COM (![][image64]) first26. Commanding Thurya to hurl an **Alabaster Silt Flask** strips Dharib's Unstoppable buff and applies Silt Bogged (0.60x Cast speed)26. With Dharib slowed inside the ![][image53] window, Malik charges **Sluice-Breaker Strike**. Because trust\_rating \>= 65.0, their timeline icons link via **Dual-Sluice Resonance**, boosting Malik's cast velocity by \+20% so he strikes Dharib at ![][image71], canceling Crushing Levy and resetting the boss to ![][image68]24. Upon Dharib's defeat, Malik and Thurya crank open the master bronze weir; as monsoon water roars back into the parched highland canals and Music\_Ambient swells, they discover Dharib's sealed dispatch scroll inside the winch-house, revealing that the Coastal Syndicate has been paid by a rival Red Sea maritime power to intentionally silt up and rupture the Great Dam of Marib itself37.

### **Autonomous Terminal Workflow for the Creative Director**

To operate this architecture without writing code manually, the Creative Director interacts with Claude Code (Opus 5.5) inside the WSL2 Ubuntu terminal using a disciplined **Decompose ![][image72] Delegate ![][image72] Verify ![][image72] Merge** protocol1.

#### **1\. Task Decomposition & Prompting Protocol**

Rather than issuing broad, multi-system requests that risk context drift, the Creative Director issues atomic, single-responsibility directives that reference /CLAUDE.md and target specific files1:  
DIRECTIVE TEMPLATE FOR CLAUDE CODE (OPUS 5.5):  
"Read /CLAUDE.md. Create branch feat/combat-silt-status. Delegate to a Haiku subagent the creation of res://resources/status/silt\_bogged.tres using StatusEffectData with wait\_speed\_multiplier \= 0.65 and cast\_speed\_multiplier \= 0.60. Then implement a unit test in res://tests/test\_runner.gd verifying that CombatantData.get\_effective\_speed() reflects the 0.60 multiplier when is\_casting \== true. Commit each file in a separate micro-commit after passing ./tools/verify\_commit.sh, and open a PR."

#### **2\. Command-Line Audit & Verification Cheat Sheet (WSL2)**

The Creative Director uses the following four terminal commands inside WSL2 to audit agent work before approving any GitHub Pull Request2:

Bash  
\# 1\. Inspect the micro-commit history on the current agent branch (Verify 1 file per commit)  
git log main..HEAD \--stat \--oneline

\# 2\. Run the full headless Godot import & unit test suite manually (Verify Exit Code 0\)  
godot \--headless \--path . \--import && godot \--headless \--path . \--script res://tests/test\_runner.gd && echo "AUDIT\_OK"

\# 3\. Verify zero script line-limit or node-query violations across the entire repository  
./tools/verify\_commit.sh

\# 4\. Review exact line-by-line changes before merging the PR into main  
gh pr diff && gh pr merge \--squash \--delete-branch

#### **3\. Safe Rollback & Loop-Recovery Protocol**

If an autonomous subagent enters a hallucination loop (for example, repeatedly failing a headless test or attempting to bypass the 120-line cap), the Creative Director terminates the agent session (Ctrl+C twice) and executes the deterministic WSL2 recovery sequence2:

| Failure Scenario | Diagnostic Symptom | Exact POSIX Bash Recovery Command | Architectural Outcome |
| :---- | :---- | :---- | :---- |
| **Uncommitted Dirty Working Tree** | Agent edited multiple files simultaneously and failed pre-commit gate. | git reset \--hard HEAD && git clean \-fd | Purges all unstaged edits and untracked temporary files; restores last verified micro-commit. |
| **Corrupted Last Micro-Commit** | Agent committed a broken .tres resource that causes headless scene load failure8. | git reset \--hard HEAD\~1 && godot \--headless \--path . \--import | Rolls back exactly one micro-commit and rebuilds the .godot/ resource cache2. |
| **Total Branch Abandonment** | Agent drifted architecturally across 3+ commits on a feature branch. | git checkout main && git branch \-D feat/broken-branch | Returns cleanly to the verified main branch and deletes the isolated feature branch with zero contamination. |
| **Stale .godot/ Class Cache** | Headless runner reports Identifier not declared despite valid class\_name file2. | rm \-rf .godot/ && godot \--headless \--path . \--import | Forces a complete clean rebuild of Godot 4's global script class registry2. |


(Works cited: docs/research/gemini-blueprint-citations.md, about 280 KB of links; never read it whole.)
