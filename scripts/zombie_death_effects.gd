extends RefCounted
class_name ZombieDeathEffects

const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")

const STATUS_ACTIVE_NOW := "active_now"
const STATUS_SIMPLIFIED_NOW := "simplified_now"
const STATUS_PLANNED_LATER := "planned_later"

const STATUS_LABELS: Dictionary = {
	STATUS_ACTIVE_NOW: "Jetzt aktiv",
	STATUS_SIMPLIFIED_NOW: "Jetzt reduziert aktiv",
	STATUS_PLANNED_LATER: "Fuer spaeter vorbereitet"
}

const DEFAULT_PROFILE: Dictionary = {
	"runtime_effect": "Kein zusaetzlicher Spezialeffekt.",
	"gameplay_followup": "Verhaelt sich wie der Basis-Zombie dieser Art.",
	"implementation_status": STATUS_SIMPLIFIED_NOW,
	"revenge_bonus": false,
	"danger_hint": "Standardbedrohung.",
	"counter_hint": "Standardwaffen reichen aus.",
	"active_hooks": [],
	"planned_hooks": [],
	"image_path": "",
	"ai_prompt": "",
	"speed_mult": 1.0,
	"health_mult": 1.0,
	"damage_mult": 1.0,
	"attack_cooldown_mult": 1.0,
	"turn_agility_mult": 1.0,
	"movement_jitter_add": 0.0,
	"limp_strength_add": 0.0,
	"limp_frequency_mult": 1.0,
	"pain_resistance_add": 0.0,
	"attack_cooldown_variance": 0.0,
	"heading_wobble_strength": 0.0,
	"heading_wobble_frequency": 0.0,
	"head_wobble_strength": 0.0,
	"head_wobble_frequency": 0.0,
	"aura_radius": 0.0,
	"aura_dps": 0.0,
	"aura_tick_interval": 0.45,
	"touch_bonus_damage": 0.0,
	"touch_dot_duration": 0.0,
	"touch_dot_dps": 0.0,
	"touch_dot_tick_interval": 0.4,
	"death_burst_radius": 0.0,
	"death_burst_damage": 0.0,
	"death_burst_dot_duration": 0.0,
	"death_burst_dot_dps": 0.0,
	"death_burst_dot_tick_interval": 0.45,
	"ally_pull_radius": 0.0,
	"ally_pull_strength": 0.0,
	"ally_pull_interval": 0.65,
	"discipline_rating": 0.0,
	"stumble_interval": 0.0,
	"stumble_duration": 0.0,
	"stumble_speed_mult": 1.0,
	"pulse_interval": 0.0,
	"pulse_radius": 0.0,
	"pulse_damage": 0.0,
	"part_fragility_mult": 1.0,
	"start_missing_part_count": 0,
	"crawl_transition_threshold": 0.0,
	"ground_pose_probability": 0.0,
	"rage_close_distance": 0.0,
	"rage_speed_mult": 1.0,
	"rage_attack_cooldown_mult": 1.0,
	"heal_on_attack": 0.0,
	"ally_buff_radius": 0.0,
	"ally_buff_interval": 0.0,
	"ally_buff_speed_mult": 1.0,
	"ally_buff_attack_cooldown_mult": 1.0,
	"ally_buff_require_death_class_id": "",
	"contact_slow_duration": 0.0,
	"contact_slow_strength": 1.0,
	"revenge_radius": 8.0,
	"revenge_duration": 5.0,
	"revenge_speed_mult": 1.15,
	"revenge_damage_mult": 1.2,
	"revenge_attack_cooldown_mult": 0.85,
	"mutation_pool": []
}

const EFFECT_DATA: Dictionary = {
	ZombieDefinitions.DeathSubtype.ALKOHOLISIERT: {
		"runtime_effect": "Torkelbewegung mit starkem Richtungswobble und unregelmaessigem Angriffstiming.",
		"gameplay_followup": "Jetzt reduziert aktiv: erratische Bewegung statt direkter Praezisions-Manipulation auf einzelne Hitboxen.",
		"implementation_status": STATUS_SIMPLIFIED_NOW,
		"danger_hint": "Unberechenbare Laufspur macht Distanzhalten schwerer.",
		"counter_hint": "Seitliche Bewegung und mittlere Distanz halten.",
		"active_hooks": ["movement_wobble", "head_wobble", "attack_cooldown_variance"],
		"planned_hooks": ["Kopf-/Gliedmassen-Praezisionsregel bei spaeterem Aim-System."],
		"movement_jitter_add": 0.18,
		"heading_wobble_strength": 0.33,
		"heading_wobble_frequency": 2.2,
		"head_wobble_strength": 0.14,
		"head_wobble_frequency": 3.0,
		"attack_cooldown_variance": 0.2
	},
	ZombieDefinitions.DeathSubtype.GEISTLICH: {
		"runtime_effect": "Lokale Sammellogik: nahe Zombies werden periodisch zum geistlichen Typ hingezogen.",
		"gameplay_followup": "Jetzt reduziert aktiv: Ally-Buendelung ohne mapabhaengige Heilig-Ort-Logik.",
		"implementation_status": STATUS_SIMPLIFIED_NOW,
		"danger_hint": "Kann kleine Gruppen dichter zusammenziehen.",
		"counter_hint": "Geistliche zuerst entfernen, um Cluster zu vermeiden.",
		"active_hooks": ["ally_pull_field"],
		"planned_hooks": ["Reaktion auf spaetere Sacred-Areas/Level-Tags."],
		"ally_pull_radius": 6.0,
		"ally_pull_strength": 0.35,
		"ally_pull_interval": 0.7
	},
	ZombieDefinitions.DeathSubtype.VERFLUCHT: {
		"runtime_effect": "Dunkle Nah-Aura plus anhaltender Fluchschaden bei Kontakt.",
		"gameplay_followup": "Jetzt aktiv: Aura-Debuff als konstante Nahbereichsgefahr.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Langer Nahkontakt baut stetigen Schaden auf.",
		"counter_hint": "Burst-Schaden aus Distanz bevorzugen.",
		"active_hooks": ["aura_dot", "touch_dot", "revenge_bonus"],
		"aura_radius": 2.4,
		"aura_dps": 3.1,
		"touch_dot_duration": 2.6,
		"touch_dot_dps": 2.1,
		"revenge_bonus": true
	},
	ZombieDefinitions.DeathSubtype.MILITAERISCH: {
		"runtime_effect": "Disziplinierter Chase mit direkterer Verfolgung und weniger Drift.",
		"gameplay_followup": "Jetzt aktiv: stabilere Zielverfolgung ohne grosses Squad-System.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Verliert den direkten Anlauf deutlich seltener.",
		"counter_hint": "Deckung und enge Winkel nutzen, um Turns zu erzwingen.",
		"active_hooks": ["discipline_chase"],
		"speed_mult": 1.06,
		"turn_agility_mult": 1.34,
		"movement_jitter_add": -0.09,
		"discipline_rating": 1.0
	},
	ZombieDefinitions.DeathSubtype.VERGIFTET: {
		"runtime_effect": "Vergifteter Kontakt: Attacken verursachen einen DOT-Effekt.",
		"gameplay_followup": "Jetzt aktiv: Gift wird als direkter Kontakt-DOT abgebildet.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Auch nach dem Hit bleibt Schaden noch kurz aktiv.",
		"counter_hint": "Kontakt vermeiden und gezielt kiten.",
		"active_hooks": ["touch_dot", "revenge_bonus"],
		"touch_dot_duration": 3.8,
		"touch_dot_dps": 2.0,
		"revenge_bonus": true
	},
	ZombieDefinitions.DeathSubtype.INFIZIERT: {
		"runtime_effect": "Infektionsaura plus leichte Infektionswirkung bei Nahkontakt.",
		"gameplay_followup": "Jetzt aktiv: lokaler Debuff als generischer DOT ohne separates Statussystem.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Nahe Distanz erzeugt doppelten Schaden durch Hit + Aura.",
		"counter_hint": "Engen Nahkampf kurz halten.",
		"active_hooks": ["aura_dot", "touch_dot"],
		"aura_radius": 2.1,
		"aura_dps": 2.0,
		"touch_dot_duration": 2.2,
		"touch_dot_dps": 1.4
	},
	ZombieDefinitions.DeathSubtype.KREBSINFIZIERT: {
		"runtime_effect": "Zaehes, schwer stoppbares Ziel mit niedrigerem Tempo.",
		"gameplay_followup": "Jetzt aktiv: mehr HP/Resistenz ueber Stats statt visueller Deformation.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Frisst mehr Treffer als vergleichbare Typen.",
		"counter_hint": "Priorisiert Head-/Torso-DPS.",
		"active_hooks": ["health_boost", "pain_resistance"],
		"speed_mult": 0.88,
		"health_mult": 1.24,
		"pain_resistance_add": 0.22
	},
	ZombieDefinitions.DeathSubtype.STARK_VERLETZT: {
		"runtime_effect": "Startet mit Vorschaden: fehlende Teile und asymmetrische Bewegung.",
		"gameplay_followup": "Jetzt reduziert aktiv: verlagertes Trefferprofil ueber Start-Partverlust statt exakter Weakspot-Neudefinition.",
		"implementation_status": STATUS_SIMPLIFIED_NOW,
		"danger_hint": "Unregelmaessige Bewegung erschwert Timing.",
		"counter_hint": "Bewegungsmuster abwarten, dann fokussiert schiessen.",
		"active_hooks": ["start_missing_parts", "part_fragility", "revenge_bonus"],
		"planned_hooks": ["Praezise Weakspot-Neuverteilung nach spaeterem Hitzone-Ausbau."],
		"start_missing_part_count": 1,
		"part_fragility_mult": 1.25,
		"movement_jitter_add": 0.16,
		"revenge_bonus": true
	},
	ZombieDefinitions.DeathSubtype.ZERSTUECKELT: {
		"runtime_effect": "Instabiler Restkoerper mit fruehem Uebergang in niedrigen Kriechmodus.",
		"gameplay_followup": "Jetzt aktiv: bleibt auch bei starkem Schaden als niedrige Bedrohung kampffaehig.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Kann nach Teilverlusten weiter Druck machen.",
		"counter_hint": "Ziel komplett finishen, nicht nur anschlagen.",
		"active_hooks": ["start_missing_parts", "crawl_transition", "revenge_bonus"],
		"start_missing_part_count": 1,
		"crawl_transition_threshold": 0.42,
		"part_fragility_mult": 1.35,
		"revenge_bonus": true
	},
	ZombieDefinitions.DeathSubtype.ATOMVERSEUCHT: {
		"runtime_effect": "Strahlungsaura plus radioaktiver Burst beim Tod.",
		"gameplay_followup": "Jetzt aktiv: sauber als DeathClass Strahlung mit DOT- und OnDeath-Gefahr.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Nahbereich und Todeszone gleichzeitig gefaehrlich.",
		"counter_hint": "Nach Kill sofort Radius verlassen.",
		"active_hooks": ["aura_dot", "on_death_burst", "revenge_bonus"],
		"aura_radius": 3.0,
		"aura_dps": 4.4,
		"death_burst_radius": 2.8,
		"death_burst_damage": 14.0,
		"death_burst_dot_duration": 2.2,
		"death_burst_dot_dps": 2.5,
		"revenge_bonus": true
	},
	ZombieDefinitions.DeathSubtype.VERBRANNT: {
		"runtime_effect": "Hitzeschaden bei Kontakt und kurze Nachbrennphase.",
		"gameplay_followup": "Jetzt aktiv: Ignite als einfacher DOT statt komplexem Feuerstack-System.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Jeder Nahhit setzt Burn-Nachschaden.",
		"counter_hint": "Feuertraeger aus Distanz kontrollieren.",
		"active_hooks": ["touch_damage_bonus", "touch_dot", "revenge_bonus"],
		"touch_bonus_damage": 2.0,
		"touch_dot_duration": 2.0,
		"touch_dot_dps": 3.0,
		"revenge_bonus": true
	},
	ZombieDefinitions.DeathSubtype.ERFROREN: {
		"runtime_effect": "Starre Bewegung mit langsameren Turns, aber stabilem Frontdruck.",
		"gameplay_followup": "Jetzt aktiv: Bewegungsstarre und kurzer Kontakt-Slow statt grosser Frost-Subsysteme.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Kontakt bremst kurz aus und macht repositioning schwerer.",
		"counter_hint": "Grossen Abstand halten und flankieren.",
		"active_hooks": ["speed_penalty", "turn_penalty", "contact_slow"],
		"speed_mult": 0.74,
		"turn_agility_mult": 0.7,
		"attack_cooldown_mult": 1.08,
		"contact_slow_duration": 1.2,
		"contact_slow_strength": 0.82
	},
	ZombieDefinitions.DeathSubtype.ERTRUNKEN: {
		"runtime_effect": "Nasser, rutschiger Gang mit Rhythmusstoerungen bei Angriff und Bewegung.",
		"gameplay_followup": "Jetzt reduziert aktiv: Stumble-/Timing-Interrupt statt Screen-Sichtstoerung.",
		"implementation_status": STATUS_SIMPLIFIED_NOW,
		"danger_hint": "Unklare Angriffsrhythmen erschweren Countertiming.",
		"counter_hint": "Nicht in engem Raum traden.",
		"active_hooks": ["attack_cooldown_variance", "stumble_cycle"],
		"planned_hooks": ["Optionale Sichtstoerung nur bei spaeterem Player-Feedback-Hook."],
		"attack_cooldown_variance": 0.22,
		"stumble_interval": 3.6,
		"stumble_duration": 0.45,
		"stumble_speed_mult": 0.5
	},
	ZombieDefinitions.DeathSubtype.ELEKTRISIERT: {
		"runtime_effect": "Zuckende Bewegung plus periodische Schockimpulse im Nahbereich.",
		"gameplay_followup": "Jetzt aktiv: Kontakt- und Puls-Schaden ohne komplexes Chain-Lightning-Netz.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Regelmaessige Impulse bestrafen dauerhaftes Kleben am Ziel.",
		"counter_hint": "Impuls-Timing ausspielen und kurz rausgehen.",
		"active_hooks": ["movement_wobble", "pulse_damage"],
		"heading_wobble_strength": 0.2,
		"heading_wobble_frequency": 8.4,
		"pulse_interval": 2.4,
		"pulse_radius": 1.8,
		"pulse_damage": 5.0
	},
	ZombieDefinitions.DeathSubtype.ERHAENGT: {
		"runtime_effect": "Verdrehte Kopfbewegung und instabiles Aim-Profil ueber Head-Wobble.",
		"gameplay_followup": "Jetzt reduziert aktiv: Hitbox-/Praezisionsstoerung ueber Bewegung statt exakter Trefferquotenregel.",
		"implementation_status": STATUS_SIMPLIFIED_NOW,
		"danger_hint": "Unsaubere Kopfbewegung reduziert vorhersehbare Trefferfenster.",
		"counter_hint": "Torso fokussieren statt auf schnelle Headshots zu gehen.",
		"active_hooks": ["head_wobble", "revenge_bonus"],
		"planned_hooks": ["Direkter Headshot-Difficulty-Multiplikator bei spaeterem Targeting-System."],
		"head_wobble_strength": 0.26,
		"head_wobble_frequency": 2.7,
		"movement_jitter_add": 0.08,
		"revenge_bonus": true
	},
	ZombieDefinitions.DeathSubtype.VERBLUTET: {
		"runtime_effect": "Auffallend aggressiver Vorwaertsdruck im Nahbereich.",
		"gameplay_followup": "Jetzt aktiv: hoehere Nahkampfintensitaet ueber Rage-Boost statt Blut-VFX-System.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Wird in Nahdistanz deutlich schneller und druckvoller.",
		"counter_hint": "Abstand erzwingen und bursten.",
		"active_hooks": ["rage_near_target"],
		"speed_mult": 1.08,
		"rage_close_distance": 4.0,
		"rage_speed_mult": 1.2,
		"rage_attack_cooldown_mult": 0.82
	},
	ZombieDefinitions.DeathSubtype.PARASSITIERT: {
		"runtime_effect": "Parasitenausbruch beim Tod als lokale Burst-/DOT-Gefahr.",
		"gameplay_followup": "Jetzt reduziert aktiv: parasitaerer Burst statt vollwertiger Minion-Spawns.",
		"implementation_status": STATUS_SIMPLIFIED_NOW,
		"danger_hint": "Kill im Nahbereich kann direkten Nachschaden ausloesen.",
		"counter_hint": "Beim finalen Treffer leicht Abstand halten.",
		"active_hooks": ["touch_dot", "on_death_burst"],
		"planned_hooks": ["Echte Parasiten-Minions spaeter ueber separates Spawn-Subsystem."],
		"touch_dot_duration": 2.6,
		"touch_dot_dps": 1.8,
		"death_burst_radius": 2.1,
		"death_burst_damage": 8.0,
		"death_burst_dot_duration": 2.0,
		"death_burst_dot_dps": 2.0
	},
	ZombieDefinitions.DeathSubtype.PILZINFIZIERT: {
		"runtime_effect": "Sporen-Aura mit konstantem Druck in mittlerer Distanz.",
		"gameplay_followup": "Jetzt aktiv: Debuff-Area und leichte Kontaktwirkung ohne schwere VFX-Kette.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Sporenraum zwingt Bewegung und verhindert langes Halten.",
		"counter_hint": "Aura-Radius nur kurz betreten.",
		"active_hooks": ["aura_dot", "touch_dot"],
		"aura_radius": 2.6,
		"aura_dps": 3.0,
		"touch_dot_duration": 1.6,
		"touch_dot_dps": 1.1
	},
	ZombieDefinitions.DeathSubtype.CHEMISCH_VERSEUCHT: {
		"runtime_effect": "Toxische Kontaktwirkung und chemischer Todesburst.",
		"gameplay_followup": "Jetzt aktiv: modulare Flaechen-/DOT-Gefahr ohne fremde VFX-Systeme.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Kann bei Kill einen zweiten Schadensmoment ausloesen.",
		"counter_hint": "Burst aus Distanz und Radius nach Tod verlassen.",
		"active_hooks": ["touch_dot", "on_death_burst", "revenge_bonus"],
		"touch_dot_duration": 3.0,
		"touch_dot_dps": 2.4,
		"death_burst_radius": 2.5,
		"death_burst_damage": 10.0,
		"death_burst_dot_duration": 2.3,
		"death_burst_dot_dps": 2.1,
		"revenge_bonus": true
	},
	ZombieDefinitions.DeathSubtype.SAEUREVERAETZT: {
		"runtime_effect": "Saeurekontakt mit starkem Nachschaden statt direkter Ruestungszerlegung.",
		"gameplay_followup": "Jetzt aktiv (reduzierte Vollversion): DOT ersetzt fehlendes Schutzsystem.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Mehrfachtreffer stapeln schnell hohen Folgeschaden.",
		"counter_hint": "Kurze Peek-Fenster statt Dauerkontakt.",
		"active_hooks": ["touch_bonus_damage", "touch_dot", "revenge_bonus"],
		"touch_bonus_damage": 3.0,
		"touch_dot_duration": 3.2,
		"touch_dot_dps": 3.3,
		"revenge_bonus": true
	},
	ZombieDefinitions.DeathSubtype.SEUCHENVERSEUCHT: {
		"runtime_effect": "Starke Seuchen-Aura mit kleinem Ally-Buff fuer Krankheits-Typen.",
		"gameplay_followup": "Jetzt aktiv: lokaler Krankheitssynergie-Buff statt grosser Gruppensimulation.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "In Gruppen steigen Druck und Angriffstempo sichtbar.",
		"counter_hint": "Seuchenquellen zuerst fokusieren.",
		"active_hooks": ["aura_dot", "ally_buff_disease"],
		"aura_radius": 2.9,
		"aura_dps": 3.5,
		"ally_buff_radius": 5.5,
		"ally_buff_interval": 0.9,
		"ally_buff_speed_mult": 1.08,
		"ally_buff_attack_cooldown_mult": 0.93,
		"ally_buff_require_death_class_id": "krankheit"
	},
	ZombieDefinitions.DeathSubtype.MUMIFIZIERT: {
		"runtime_effect": "Steif, aber schwer zu unterbrechen; hohe Resistenz gegen Kontrollverlust.",
		"gameplay_followup": "Jetzt aktiv: Stagger-Resistenz und traege Bewegung; Feuer-Anfaelligkeit als Hook.",
		"implementation_status": STATUS_SIMPLIFIED_NOW,
		"danger_hint": "Bleibt trotz Treffern auf Kurs.",
		"counter_hint": "Kontrollfeuer mit hohem DPS statt Single-Shots.",
		"active_hooks": ["pain_resistance", "speed_penalty"],
		"planned_hooks": ["Erhoehter Feuerschaden sobald Damage-Typen verfuegbar sind."],
		"speed_mult": 0.86,
		"pain_resistance_add": 0.34
	},
	ZombieDefinitions.DeathSubtype.VERWEST: {
		"runtime_effect": "Instabile Koerperstruktur mit schnellerem Teilverlust.",
		"gameplay_followup": "Jetzt aktiv: Part-Bruchwahrscheinlichkeit und Bewegungsinstabilitaet erhoeht.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Kann als chaotischer Restkoerper unberechenbar bleiben.",
		"counter_hint": "Nach Teilverlust konsequent finishen.",
		"active_hooks": ["part_fragility", "movement_instability"],
		"part_fragility_mult": 1.32,
		"movement_jitter_add": 0.12
	},
	ZombieDefinitions.DeathSubtype.FRISCH_VERSTORBEN: {
		"runtime_effect": "Frischer Zustand mit direkter Reaktion und fluessiger Bewegung.",
		"gameplay_followup": "Jetzt aktiv: schnellere, koordiniertere Nahkampffolge.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Erreicht den Spieler schneller als andere Verwesungsstufen.",
		"counter_hint": "Frueh focusen bevor Nahdistanz entsteht.",
		"active_hooks": ["speed_boost", "attack_speed_boost"],
		"speed_mult": 1.12,
		"attack_cooldown_mult": 0.88,
		"turn_agility_mult": 1.1
	},
	ZombieDefinitions.DeathSubtype.DAEMONISCH_BESESSEN: {
		"runtime_effect": "Daemonische Aura und sehr hohe Resistenz gegen Unterbrechung.",
		"gameplay_followup": "Jetzt reduziert aktiv: Kerngefahr umgesetzt, komplexe Daemonenstufen nur als Hook.",
		"implementation_status": STATUS_SIMPLIFIED_NOW,
		"danger_hint": "Lange Stopp-Ketten funktionieren deutlich schlechter.",
		"counter_hint": "Konstanter DPS statt Stagger-Plan.",
		"active_hooks": ["aura_dot", "pain_resistance"],
		"planned_hooks": ["Erweiterte Daemonen-Faehigkeiten als separates Modul."],
		"aura_radius": 2.2,
		"aura_dps": 2.8,
		"pain_resistance_add": 0.46,
		"attack_cooldown_mult": 0.92
	},
	ZombieDefinitions.DeathSubtype.HINGERICHTET: {
		"runtime_effect": "Starres Bewegungsprofil mit Startverletzung und hoher Entschlossenheit.",
		"gameplay_followup": "Jetzt reduziert aktiv: markanter Bewegungsstil plus Part-Startschaden statt exotischer Spezial-Weakspots.",
		"implementation_status": STATUS_SIMPLIFIED_NOW,
		"danger_hint": "Bleibt trotz sichtbarer Schaeden gefaehrlich.",
		"counter_hint": "Nicht auf kosmetische Treffer verlassen, Kernteile focusen.",
		"active_hooks": ["start_missing_parts", "discipline_chase", "revenge_bonus"],
		"planned_hooks": ["Spezial-Schwachstellen erst bei robustem Weakspot-System."],
		"start_missing_part_count": 1,
		"turn_agility_mult": 0.82,
		"discipline_rating": 0.65,
		"revenge_bonus": true
	},
	ZombieDefinitions.DeathSubtype.GEFOLTERT: {
		"runtime_effect": "Extrem schmerzresistent und nur schwer zu stoppen.",
		"gameplay_followup": "Jetzt aktiv: hohe Pain-Resistenz als direkter Kampfmodifikator.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Unterbrechungen greifen deutlich seltener.",
		"counter_hint": "Burst-Phasen koordinieren statt Stagger-Fokus.",
		"active_hooks": ["pain_resistance", "revenge_bonus"],
		"pain_resistance_add": 0.52,
		"damage_mult": 1.08,
		"revenge_bonus": true
	},
	ZombieDefinitions.DeathSubtype.BLITZSCHLAG_OPFER: {
		"runtime_effect": "Periodische Blitz-Impulse und elektrische Zuckungen.",
		"gameplay_followup": "Jetzt aktiv: Puls-Nahschaden in festen Intervallen.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Impulsfenster machen Nahkampf-Rush riskant.",
		"counter_hint": "Pulsintervall lesen und dazwischen angreifen.",
		"active_hooks": ["pulse_damage", "movement_wobble"],
		"pulse_interval": 2.0,
		"pulse_radius": 2.3,
		"pulse_damage": 6.0,
		"heading_wobble_strength": 0.16,
		"heading_wobble_frequency": 8.0
	},
	ZombieDefinitions.DeathSubtype.TIERANGRIFF_OPFER: {
		"runtime_effect": "Wilder, hektischer Angriffsstil mit hoher Instabilitaet.",
		"gameplay_followup": "Jetzt aktiv: schnelleres, riskanteres Nahkampfmuster mit hoher Streuung.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Chaotische Rushes erzeugen schwer lesbare Engagements.",
		"counter_hint": "Raumkontrolle und Hindernisse nutzen.",
		"active_hooks": ["speed_boost", "jitter_boost", "revenge_bonus"],
		"speed_mult": 1.18,
		"damage_mult": 1.1,
		"attack_cooldown_mult": 0.9,
		"movement_jitter_add": 0.2,
		"revenge_bonus": true
	},
	ZombieDefinitions.DeathSubtype.RADIOAKTIV_MUTIERT: {
		"runtime_effect": "Kontrollierte Mutationsvariante aus kleinem Effekt-Pool pro Spawn.",
		"gameplay_followup": "Jetzt aktiv: testbare Zufallsselektion mit begrenzten, klaren Modifikatoren.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Mutation pro Spawn variiert das Bedrohungsprofil.",
		"counter_hint": "Nach erstem Kontakt Bewegungsmuster schnell lesen.",
		"active_hooks": ["controlled_mutation_pool"],
		"aura_radius": 2.0,
		"aura_dps": 1.9,
		"mutation_pool": [
			{
				"id": "mut_speed",
				"name": "Mutationsschub: Geschwindigkeit",
				"modifiers": {
					"speed_mult": 1.18
				}
			},
			{
				"id": "mut_armor",
				"name": "Mutationsschub: Panzerhaut",
				"modifiers": {
					"health_mult": 1.15,
					"pain_resistance_add": 0.2
				}
			},
			{
				"id": "mut_toxic",
				"name": "Mutationsschub: Toxische Aura",
				"modifiers": {
					"aura_radius_add": 0.7,
					"aura_dps_add": 1.8
				}
			},
			{
				"id": "mut_burst",
				"name": "Mutationsschub: Instabiler Tod",
				"modifiers": {
					"death_burst_radius_add": 1.2,
					"death_burst_damage_add": 10.0
				}
			},
			{
				"id": "mut_regen",
				"name": "Mutationsschub: Regenerativer Schlag",
				"modifiers": {
					"heal_on_attack": 2.0
				}
			}
		]
	},
	ZombieDefinitions.DeathSubtype.ERSTOCHEN: {
		"runtime_effect": "Extremer Vorwaertsdrang mit kurzen, direkten Attack-Zyklen.",
		"gameplay_followup": "Jetzt aktiv: aggressives Push-Verhalten ueber Cooldown- und Chase-Modifikatoren.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Schliesst schnell auf und greift in kurzen Intervallen an.",
		"counter_hint": "Seitliches Ausweichen statt Rueckwaertsrennen.",
		"active_hooks": ["rush_profile", "revenge_bonus"],
		"speed_mult": 1.1,
		"attack_cooldown_mult": 0.78,
		"turn_agility_mult": 1.2,
		"revenge_bonus": true
	},
	ZombieDefinitions.DeathSubtype.ERSCHOSSEN: {
		"runtime_effect": "Ruckartige Mikrobewegungen mit unruhigem Attack-Timing.",
		"gameplay_followup": "Jetzt aktiv: kalkulierbar-chaotisches Muster ohne unfaires Teleport-Verhalten.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Timingfenster schwanken leicht und brechen Erwartung.",
		"counter_hint": "Kurze Burstfenster nach Zuckungsphase nutzen.",
		"active_hooks": ["movement_wobble", "attack_cooldown_variance", "revenge_bonus"],
		"heading_wobble_strength": 0.15,
		"heading_wobble_frequency": 7.2,
		"attack_cooldown_variance": 0.18,
		"stumble_interval": 4.6,
		"stumble_duration": 0.2,
		"stumble_speed_mult": 0.7,
		"revenge_bonus": true
	},
	ZombieDefinitions.DeathSubtype.ERSCHLAGEN: {
		"runtime_effect": "Schwerer, traeger Nahkaempfer mit hohen Einzelhieben.",
		"gameplay_followup": "Jetzt aktiv: langsameres Angriffstempo bei hoeherem Impact pro Hit.",
		"implementation_status": STATUS_ACTIVE_NOW,
		"danger_hint": "Treffer tun deutlich mehr weh, obwohl weniger haeufig.",
		"counter_hint": "Wind-up ausspielen und danach bestrafen.",
		"active_hooks": ["heavy_hit_profile", "revenge_bonus"],
		"speed_mult": 0.82,
		"damage_mult": 1.24,
		"attack_cooldown_mult": 1.26,
		"pain_resistance_add": 0.24,
		"revenge_bonus": true
	}
}

static func get_status_label(status_id: String) -> String:
	if STATUS_LABELS.has(status_id):
		return String(STATUS_LABELS[status_id])
	return String(STATUS_LABELS[STATUS_SIMPLIFIED_NOW])

static func get_effect_profile(death_subtype: int) -> Dictionary:
	var profile: Dictionary = DEFAULT_PROFILE.duplicate(true)
	if EFFECT_DATA.has(death_subtype):
		_merge_profile(profile, EFFECT_DATA[death_subtype])

	var subtype_cfg: Dictionary = ZombieDefinitions.get_death_subtype_data(death_subtype)
	var subtype_id: String = String(subtype_cfg.get("id", "unknown"))
	var subtype_name: String = String(subtype_cfg.get("display_name", subtype_id))
	var class_cfg: Dictionary = ZombieDefinitions.get_death_class_data(int(subtype_cfg.get("death_class", ZombieDefinitions.DEFAULT_DEATH_CLASS)))
	var death_class_name_text: String = String(class_cfg.get("display_name", "Unbekannt"))

	profile["id"] = subtype_id
	profile["name"] = subtype_name
	profile["death_class_id"] = String(class_cfg.get("id", ""))
	profile["death_class_name"] = death_class_name_text
	profile["implementation_status_name"] = get_status_label(String(profile.get("implementation_status", STATUS_SIMPLIFIED_NOW)))

	if String(profile.get("image_path", "")) == "":
		profile["image_path"] = "res://assets/handbook/death_subtypes/%s.svg" % subtype_id
	if String(profile.get("ai_prompt", "")) == "":
		profile["ai_prompt"] = "Portraitkarte fuer Todesart '%s' (Klasse %s), grim dark Zombie-Handbuchstil, detailreiche Silhouette, entsaettigte Farben, kein Text." % [subtype_name, death_class_name_text]

	return profile

static func resolve_runtime_profile(death_subtype: int, rng: RandomNumberGenerator) -> Dictionary:
	var runtime_profile: Dictionary = get_effect_profile(death_subtype)
	var pool: Array = runtime_profile.get("mutation_pool", [])
	if pool.is_empty():
		return runtime_profile

	var index := 0
	if rng != null and pool.size() > 1:
		index = rng.randi_range(0, pool.size() - 1)
	var mutation: Dictionary = pool[index]
	var mutation_modifiers: Dictionary = mutation.get("modifiers", {})
	_apply_modifier_set(runtime_profile, mutation_modifiers)
	runtime_profile["runtime_mutation_id"] = String(mutation.get("id", ""))
	runtime_profile["runtime_mutation_name"] = String(mutation.get("name", ""))

	var effect_suffix: String = String(mutation.get("name", "Mutation aktiv"))
	runtime_profile["runtime_effect"] = "%s (%s)." % [String(runtime_profile.get("runtime_effect", "")), effect_suffix]
	return runtime_profile

static func _merge_profile(target: Dictionary, source: Dictionary):
	for key in source.keys():
		target[key] = _duplicate_value(source[key])

static func _duplicate_value(value):
	if value is Array or value is Dictionary:
		return value.duplicate(true)
	return value

static func _apply_modifier_set(target: Dictionary, modifiers: Dictionary):
	for key in modifiers.keys():
		var key_name: String = String(key)
		var value = modifiers[key]

		if key_name.ends_with("_mult"):
			var base_value: float = float(target.get(key_name, 1.0))
			target[key_name] = base_value * float(value)
			continue

		if key_name.ends_with("_add"):
			var base_key: String = key_name.substr(0, key_name.length() - 4)
			var base_add_value: float = float(target.get(base_key, 0.0))
			target[base_key] = base_add_value + float(value)
			continue

		target[key_name] = _duplicate_value(value)
