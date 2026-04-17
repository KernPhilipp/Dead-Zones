# Character and Enemy Direction

## Zielbild
Dead Zones soll wie ein improvisierter, harter Lost-Places-Survival-Shooter wirken. Die Figuren duerfen deshalb nicht sauber oder heroisch aussehen, sondern muessen funktional, abgenutzt und unruhig wirken.

## Spieler
- First-Person-Silhouette mit schweren Jackenaermeln, dunklen Handschuhen und einer improvisiert wirkenden Waffe.
- Farbwelt: entsaettigte Gruen-, Braun- und Metalltoene statt bunter Militaer-Optik.
- Die Spielerfigur soll sich wie ein scavengerfokussierter Ueberlebender anfuehlen, nicht wie ein High-Tech-Soldat.

## Gegner
- Hagerer, leicht gekruemmter Zombie mit ungleichmaessiger Pose.
- Zerrissene Kleidung, freiliegendes Fleisch, Knochen-/Klauendetails und leicht leuchtende Augen fuer schnelle Lesbarkeit im Dunkeln.
- Die aktuelle Szene ist modular aufgebaut, damit spaetere Blender-Modelle einzelne Primitive direkt ersetzen koennen.

## Naechster sauberer Ausbau
1. Echte Meshes in Blender auf Basis derselben Silhouette bauen.
2. Die Primitive in `scenes/player.tscn` und `scenes/zombie.tscn` schrittweise durch importierte Szenen ersetzen.
3. Spaeter Animationen fuer Idle, Treffer, Sprint und Angriff an dieselben Ankerpunkte anschliessen.
