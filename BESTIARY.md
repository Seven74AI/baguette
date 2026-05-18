# BAGUETTE — BESTIAIRE COMPLET

> Document de recherche — Phase Brainstorming
> Paris 2087. La dernière boulangerie de France est assiégée.
> Tu es MITCH, le mitron armé.

---

## Table des matières

1. [Archétypes & Patterns FPS/Rogue-like](#1-archetypes--patterns)
2. [Bestiaire — Tier 1 : Rue de la Boulangerie (early game)](#2-tier-1--rue-de-la-boulangerie)
3. [Bestiaire — Tier 2 : Le Marais / Quartier Hipster (mid game)](#3-tier-2--le-marais--quartier-hipster)
4. [Bestiaire — Tier 3 : Les Halles / Food Court (late game)](#4-tier-3--les-halles--food-court)
5. [Mini-Bosses](#5-mini-bosses)
6. [Bosses Majeurs](#6-bosses-majeurs)
7. [Systèmes Transverses](#7-systemes-transverses)
8. [Progression & Courbe de Difficulté](#8-progression--courbe-de-difficulte)

---

## 1. Archétypes & Patterns

### 1.1 Archétypes FPS classiques appliqués à BAGUETTE

| Archétype | Rôle FPS | Twist BAGUETTE |
|-----------|----------|----------------|
| **Grunt / Chair à canon** | Faible, nombreux, apprend les bases au joueur | Touristes zombies — lents, prévisibles, comiques |
| **Soldat** | Distance moyenne, utilise couvert, précision modérée | Vendeurs de souvenirs — lancent des tours Eiffel miniatures |
| **Swarmer** | Rapide, faible PV, attaque en groupe | Pigeons mutants — volants, esquive, harcèlement |
| **Heavy** | Lent, énorme PV, dégâts massifs | Brigade des Calories — obèses, chargent, AoE |
| **Sniper** | Longue portée, fragile, repositionne | Critiques gastronomiques — attaques à distance, débuff |
| **Support / Buffer** | Soigne/buff les alliés, fragile seul | Chefs étoilés corrompus — buff zone, invoque add-ons |
| **Specialist** | Mécanique unique (shield, téléportation, spawn) | Hipsters sans gluten — zone de débuff, esquive |
| **Area Denial** | Contrôle de zone, dégâts sur la durée | Crêpiers démoniaques — nappes de pâte brûlante |
| **Rusher / Flanker** | Rapide, attaque de flanc, corps à corps | Livreurs à vélo — charge, knockback |

### 1.2 Patterns rogue-like

- **Variété par run** : Chaque run pioche dans un sous-ensemble d'ennemis (pools par tier)
- **Élites** : Versions buffées avec modificateurs visuels et comportementaux
- **Modificateurs d'étage** : "Nuit Sans Lune" (enemies plus agressifs), "Pâte Qui Lève" (ennemis grossissent avec le temps), "Inspection Sanitaire" (ennemis plus nombreux, plus faibles)
- **Courbe de difficulté** : Introduction progressive des mécaniques (tier 1 = 2 types d'ennemis simples → tier 3 = 5+ types en combinaison)

---

## 2. Tier 1 — Rue de la Boulangerie (Early Game)

Ambiance : Rues pavées de Paris, devantures de boulangeries, terrasses de cafés. Introduction des mécaniques de base.

### 2.1 Touriste Zombie (Grunt)

> *"Regaaarde, Maaaartha, une vraie boulangerie française ! Braaaains... euh, baguettes !"*

| Propriété | Valeur |
|-----------|--------|
| **PV** | Faible (2-3 tirs de pistolet à baguettes) |
| **Vitesse** | Très lente (marche traînante) |
| **Attaque** | Griffe à bout portant (dégâts faibles) |
| **Portée** | Mêlée uniquement |
| **Comportement** | Avance en ligne droite vers le joueur. Parfois s'arrête pour prendre une photo (stun self de 1s). |
| **Son** | Gémissements : "baaaguuette... crooiiissant..." |
| **Faiblesse** | Tir à la tête = mort instantanée (la casquette "I ❤️ Paris" s'envole) |
| **Variante Élite** | **Touriste en Groupe Organisé** : suit un guide zombie avec un drapeau, +20% vitesse, attaque synchronisée |
| **Drop** | Miettes de pain (soin faible), Tickets de métro (monnaie) |

**Design Note** : Le grunt par excellence. Apprend au joueur le tir à la tête et le kiting basique. L'animation photo crée des fenêtres de tir satisfaisantes.

---

### 2.2 Pigeon Mutant (Swarmer)

> *"ROUCOUOU... *bruit de mitraillette*... ROUCOUOU !"*

| Propriété | Valeur |
|-----------|--------|
| **PV** | Très faible (1 tir, mais esquive fréquente) |
| **Vitesse** | Rapide, vol stationnaire |
| **Attaque** | Fiente explosive (petite AoE, dégâts mineurs + ralentissement) |
| **Portée** | Courte à moyenne |
| **Comportement** | Tournoie autour du joueur, plonge pour attaquer, remonte. Attaque en nuées de 5-10. |
| **Son** | Roucoulements agressifs, bruits d'ailes métalliques |
| **Faiblesse** | Le fusil à croissants (spread shot) les one-shot en groupe. Restent stunned 0.5s quand touchés. |
| **Variante Élite** | **Pigeon Blindé** : porte une mini-baguette en travers du bec (+50% PV, charge le joueur) |
| **Drop** | Plumes (crafting), Miettes (soin) |

**Design Note** : Apprend au joueur le tracking de cibles rapides et le positionnement. La nuée force le mouvement constant.

---

### 2.3 Vendeur de Souvenirs (Ranged Soldier)

> *"Monsieur ! Une tour Eiffel 15 centimètres ? Très bon prix ! TRÈS BON PRIX !"*

| Propriété | Valeur |
|-----------|--------|
| **PV** | Moyen (4-5 tirs) |
| **Vitesse** | Lente, utilise les étals de marché comme couvert |
| **Attaque** | Lance des tours Eiffel miniatures (projectile lent, dégâts moyens) et des boules à neige (AoE étourdissement courte durée) |
| **Portée** | Moyenne-longue |
| **Comportement** | Reste à couvert, tire par salves de 3, change de position après chaque salve. Crie "PROMOTION !" avant chaque salve (telegraph). |
| **Son** | "DERNIER PRIX !" "PROMO PROMO PROMO !" |
| **Faiblesse** | Le couvert est destructible (croissant rifle). Stun si on détruit son présentoir. |
| **Variante Élite** | **Vendeur de Luxe** : lance des tours Eiffel dorées (traçantes, +50% dégâts) |
| **Drop** | Tour Eiffel cassée (monnaie), Billets de banque |

**Design Note** : Apprend l'utilisation du couvert et le timing des fenêtres de tir (entre les salves). Le telegraph vocal est clair et drôle.

---

## 3. Tier 2 — Le Marais / Quartier Hipster (Mid Game)

Ambiance : Boutiques vintage, cafés à 6€ le café, galeries d'art contemporain. Les ennemis gagnent en complexité mécanique.

### 3.1 Hipster Sans Gluten (Specialist / Debuffer)

> *"Le gluten, c'est comme le capitalisme : ça opprime les intestins. *ajuste ses lunettes* Je vais te libérer."*

| Propriété | Valeur |
|-----------|--------|
| **PV** | Moyen-élevé (6-8 tirs) |
| **Vitesse** | Moyenne, esquive latérale stylée (dodge roll avec pause pose) |
| **Attaque** | 1) **Lanceur de Farine Sans Gluten** : projectile qui applique un debuff "Intolérance" (-30% vitesse de rechargement, -20% vitesse de déplacement, 8s). 2) **Aura Vegan** : zone autour de lui qui convertit les drops de soin en "substituts vegan" (soignent 50% moins). |
| **Portée** | Moyenne |
| **Comportement** | Maintient sa distance, applique des debuffs, esquive les projectiles. Sort un appareil photo vintage pour "documenter l'oppression boulangère" (immobile 2s, régénération lente). |
| **Son** | "C'est artisanal au moins ?" "Je connais un meilleur boulanger... à Berlin." "T'as du levain ? Non ? *soupir*" |
| **Faiblesse** | Le lance-pains au chocolat (explosif) annule son Aura Vegan. L'appareil photo explose si on tire dessus (dégâts AoE aux ennemis proches). |
| **Variante Élite** | **Influenceur Food** : possède un drone qui filme et attire d'autres ennemis. Aura Vegan améliorée (les drops deviennent toxiques). |
| **Drop** | Graines de chia (soin lent), Carte de fidélité périmée |

**Design Note** : Introduit les debuffs et le contrôle de foule ennemi. Force le joueur à prioriser cette cible avant qu'elle ne rende le combat ingérable. L'appareil photo est un risk/reward : attendre qu'il sorte pour le faire exploser.

---

### 3.2 Crêpier Démoniaque (Area Denial)

> *"Alors, sucrée ou salée ? ...LES DEUX ! *rit démoniaque en versant de la pâte*"*

| Propriété | Valeur |
|-----------|--------|
| **PV** | Élevé (8-10 tirs) |
| **Vitesse** | Lente, lourde |
| **Attaque** | 1) **Nappe de Pâte Brûlante** : crée une zone au sol qui inflige des dégâts sur la durée (5s). 2) **Crêpe Suzette** : lance une crêpe enflammée (projectile lent, gros dégâts, laisse une petite AoE de feu). 3) **Retournement de Crêpe** : attaque de mêlée circulaire (AoE autour de lui). |
| **Portée** | Mixte (zone au sol = longue, crêpe = moyenne, retournement = mêlée) |
| **Comportement** | Couvre le sol de nappes pour contrôler le déplacement du joueur, puis lance des crêpes Suzette. Le retournement est utilisé si le joueur s'approche trop. |
| **Son** | Grésillements constants de la crêpière. "La pâte est prête..." "Allez, hop !" "AH TIENS !" |
| **Faiblesse** | La nappe de pâte peut être enflammée par ses propres Crêpes Suzette (dégâts à lui-même). Le Four Sacré (ultimate) nettoie toute la pâte en un seul tir. |
| **Variante Élite** | **Maître Crêpier** : les nappes ralentissent ET collent (immobilisation 1s). Crêpes Suzette à tête chercheuse lente. |
| **Drop** | Beurre (invulnérabilité temporaire 2s), Pâte crue (grenade collante) |

**Design Note** : Enseigne la gestion de l'espace et le baiting (attirer les projectiles ennemis dans leurs propres zones). Préfigure les patterns de boss avec contrôle de zone.

---

### 3.3 Livreur à Vélo (Rusher / Flanker)

> *"DING DING ! LIVRAISON PRIORITAIRE ! *te rentre dedans à 40 km/h*"*

| Propriété | Valeur |
|-----------|--------|
| **PV** | Faible-moyen (3-4 tirs) |
| **Vitesse** | Très rapide en ligne droite, lent en virage |
| **Attaque** | 1) **Charge à Vélo** : fonce en ligne droite, knockback + dégâts moyens. 2) **Lancer de Pizza** : lancé en roulant, projectile rapide, dégâts faibles. 3) **Coup de Sonnette** : stun AoE très courte portée. |
| **Portée** | Mêlée (charge) + moyenne (pizza) |
| **Comportement** | Tourne autour du joueur en larges cercles, accélère pour charger. Après une charge ratée, freine (dérive comique), vulnérable 1.5s. |
| **Son** | Sonnette frénétique. "Dépêchez-vous !" "J'ai 3 étoiles sur Google Maps !" "Client mécontent = pas de pourboire !" |
| **Faiblesse** | La charge est télégraphiée (sonnette + trajectoire droite). Un tir bien placé pendant la charge le fait chuter (stun long + dégâts bonus). |
| **Variante Élite** | **Coursier Uber Eats** : sac isotherme qui lâche des boissons énergétiques (buff les ennemis proches). 2 livraisons = 2 charges consécutives. |
| **Drop** | Pourboire (pièces bonus), Boisson énergétique (buff vitesse temporaire) |

**Design Note** : Teste les réflexes de tir et la lecture de trajectoire. La dérive après charge ratée est un moment de satisfaction important.

---

### 3.4 Barista Possédé (Support / Spawner)

> *"Un... macchiato... avec... LAIT... D'AVOINE... *ses yeux brillent d'un noir profond* VOUS AVEZ DIT LAIT DE VACHE ?!"*

| Propriété | Valeur |
|-----------|--------|
| **PV** | Élevé (10-12 tirs) |
| **Vitesse** | Statique (derrière son comptoir) |
| **Attaque** | 1) **Invoque un Stagiaire** : spawn un Touriste Zombie toutes les 8 secondes (max 3 actifs). 2) **Machine à Expresso** : tir en cône de vapeur brûlante (dégâts moyens, repousse). 3) **Latte Art Maudit** : buff un ennemi proche (+30% vitesse, +20% dégâts, 10s) — l'ennemi buffé a une mousse de lait sur la tête. |
| **Portée** | Variable (spawn = distance, vapeur = courte, buff = moyenne) |
| **Comportement** | Reste derrière un comptoir qui sert de couvert destructible. Priorise le buff des alliés, puis le spawn, puis l'attaque. |
| **Son** | Bruits de percolateur. "COMMANDE PRÊTE !" "Un double décaféiné... POUR L'ENFER !" |
| **Faiblesse** | Le comptoir est destructible (croissant rifle : 3 tirs). Une fois exposé, gros hitbox. Le Latte Art Maudit peut être interrompu en tirant sur la tasse. |
| **Variante Élite** | **Torréfacteur Maudit** : spawn des Pigeons Mutants ET des Touristes Zombies. Machine expresso a plus de portée. |
| **Drop** | Grains de café (buff attaque), Lait d'avoine (annule debuff Intolérance) |

**Design Note** : Première introduction d'un ennemi "commandant" qui modifie le champ de bataille. Apprend la priorisation des spawners.

---

## 4. Tier 3 — Les Halles / Food Court (Late Game)

Ambiance : Anciennes halles de Paris, food court géant, cuisines industrielles. Ennemis synergiques et patterns complexes.

### 4.1 Critique Gastronomique (Sniper / Elite Debuffer)

> *"Hmm... la texture est... *écrit frénétiquement*... CATASTROPHIQUE. ZÉRO ÉTOILE. *déchire la page qui s'enflamme*"*

| Propriété | Valeur |
|-----------|--------|
| **PV** | Moyen (7-9 tirs) |
| **Vitesse** | Très lente, téléportation occasionnelle ("changement de table") |
| **Attaque** | 1) **Plume Empoisonnée** : tir précis longue portée (dégâts élevés + DoT "Mauvaise Critique" de 5s). 2) **Jugement Dernier** : AoE ciblée après 2s de canalisation (énorme dégâts, zone marquée au sol par un rond de serviette). 3) **Note Salée** : Cri qui inflige "Démoralisation" (-20% dégâts infligés, 10s). |
| **Portée** | Longue (tout le niveau si ligne de vue) |
| **Comportement** | Se positionne en hauteur, observe le joueur, attaque quand le joueur est occupé avec d'autres ennemis. Se téléporte ailleurs si le joueur s'approche à moins de 10m. |
| **Son** | Bruits de stylo plume. "PASSABLE." (quand il rate) "EXÉCRABLE !" (attaque) "Je connais un petit bouillon... *much better*" |
| **Faiblesse** | Pendant Jugement Dernier, immobile. La Note Salée ne traverse pas les murs. Le pain au chocolat explosif le fait tomber de son perchoir. |
| **Variante Élite** | **Guide Michelin Maudit** : possède 3 étoiles flottantes qui tournent autour de lui (bouclier rotatif). Perd une étoile = perd un buff. 0 étoile = rage. |
| **Drop** | Page de critique (monnaie, valeur élevée), Plume (crafting) |

**Design Note** : Ennemi "puzzle" qui force le joueur à utiliser le décor et les explosifs. Le Jugement Dernier est un Oneshot si pas esquivé — crée de la tension. La téléportation empêche le rush.

---

### 4.2 Brigade des Calories (Heavy)

> *"*respiration lourde* VOUS... AVEZ... DÉPASSÉ... L'APPORT... JOURNALIER... RECOMMANDÉ !"*

| Propriété | Valeur |
|-----------|--------|
| **PV** | Très élevé (20-25 tirs, 2x un grunt élite) |
| **Vitesse** | Très lente, mais charge soudaine |
| **Attaque** | 1) **Charge Calorique** : fonce en ligne droite (trajectoire télégraphiée), dégâts massifs + stun si touche. 2) **Onde de Choc** : frappe le sol, AoE circulaire (dégâts moyens + knockback). 3) **Crise de Boulimie** : mange un drop au sol, régénère 20% PV. |
| **Portée** | Mêlée (charge) + AoE courte |
| **Comportement** | Avance lentement, absorbe les tirs. Charge quand le joueur est à distance moyenne. Priorise manger des drops au sol — y compris ceux du joueur. |
| **Son** | Pas lourds. "BOU... LANGE... RIE..." "BEURRE... SUCRE... FARINE..." |
| **Faiblesse** | Lent à tourner après une charge ratée (dos exposé, dégâts x2). La Crise de Boulimie peut être exploitée en lançant un pain au chocolat (explosif) qu'il va manger. Peut être ralenti avec la fiente de Pigeon. |
| **Variante Élite** | **Chef Pâtissier Déchu** : porte un tablier renforcé (armure frontale). Charge ET Onde de Choc combo. Mange 2x plus vite. |
| **Drop** | Beurre (invulnérabilité), Farine (grenade aveuglante) |

**Design Note** : Le "bullet sponge" classique avec twist tactique (mange les drops). Enseigne le kiting et la visée des points faibles.

---

### 4.3 Chef Étoilé Corrompu (Support / Buffer Elite)

> *"LA CUISSON... C'EST MOI ! *ses toques flottent, ses couteaux tournoient* QUE LA SAUCE SOIT AVEC NOUS !"*

| Propriété | Valeur |
|-----------|--------|
| **PV** | Élevé (15-18 tirs) |
| **Vitesse** | Lente, lévitation basse |
| **Attaque** | 1) **Sauce Mère** : bénit 3 ennemis proches (+40% dégâts, +30% vitesse, régénération lente, 15s — traînée de sauce visible). 2) **Couteaux Virevoltants** : 4 couteaux en orbite qui bloquent les projectiles et blessent au contact. 3) **Service en Salle** : tire des assiettes telekinétiques (projectile tracking lent). 4) **RAPPEL** : quand il meurt, inflige "Mise à Pied" à tous les ennemis buffés (stun 3s — "ils sont virés !"). |
| **Portée** | Longue (buff) + courte (couteaux) + moyenne (assiettes) |
| **Comportement** | Reste en retrait, buff les alliés en priorité. Se rapproche si tous les alliés sont buffés pour utiliser les couteaux. |
| **Son** | "PLUS VITE !" "LA SAUCE EST TROP LIQUIDE, BANDE D'INCAPABLES !" "ON RECOMMENCE !" |
| **Faiblesse** | Détruire ses couteaux (1 tir chacun) expose sa hitbox. La sauce buff peut être "nettoyée" par le lance-pains au chocolat (explosion = annule buff). Son RAPPEL final punit aussi ses alliés. |
| **Variante Élite** | **Chef Triplement Étoilé** : 8 couteaux, Sauce Mère affecte TOUS les ennemis du niveau, invoque des Crêpiers Démoniaques en renfort. |
| **Drop** | Toque (buff PV max pour l'étage), Étoile Michelin (monnaie très rare) |

**Design Note** : Boss de soutien transformé en élite de zone. La mécanique "tuer le buffer en premier" est poussée à l'extrême avec le RAPPEL qui punit les ennemis restants.

---

### 4.4 Nuée de Mouches à Miel (Swarmer Élite)

> *"BZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"*

| Propriété | Valeur |
|-----------|--------|
| **PV** | Très faible (1 tir), mais 30+ individus par nuée |
| **Vitesse** | Très rapide, vol |
| **Attaque** | Nuée qui recouvre l'écran (réduit la visibilité) + dégâts de contact continus. Laisse des gouttes de miel collant au sol (ralentissement). |
| **Portée** | Mêlée (contact) |
| **Comportement** | Poursuit le joueur en nuée compacte. Se disperse si le joueur utilise le Four Sacré (fuient la chaleur). Se reforme après 5 secondes. |
| **Son** | Bourdonnement intense, modulé (plus fort = plus proche) |
| **Faiblesse** | Le Four Sacré (ultimate) les disperse instantanément. Le fusil à croissants (spread) tue 8-10 mouches par tir. Le lance-pains au chocolat (explosif) tue 15+ par tir. |
| **Variante Élite** | **Essaim de Frelons** : plus rapides, dégâts x2, ne se dispersent qu'avec le Four Sacré. |
| **Drop** | Miel (soin + buff vitesse), Cire (crafting) |

**Design Note** : Teste le contrôle de foule à grande échelle. Très satisfaisant avec les armes à spread. La réduction de visibilité est une mécanique de stress horizontale.

---

## 5. Mini-Bosses

Rencontrés à la fin de certaines sections, ou en milieu de niveau comme "épreuve".

### 5.1 Camion Pizza Blindé (Tier 1.5)

> *"*klaxon* LIVRAISON GRATUITE... DE LA MORT ! *le four à pizza crépite*"*

| Propriété | Valeur |
|-----------|--------|
| **PV** | Boss (barre de vie en bas) |
| **Phases** | 3 phases |
| **Arène** | Place de marché, le camion tourne en cercle |
| **Phase 1 — Service Normal** | Le camion roule lentement, lance des pizzas (projectiles lents, circulaires). Des Touristes Zombies sortent du camion toutes les 10s. |
| **Phase 2 (<60% PV) — Heure de Pointe** | Le camion accélère. Lance des pizzas en rafale (3 à la suite). Invoque des Livreurs à Vélo au lieu de Touristes. |
| **Phase 3 (<30% PV) — Pizza Gratuite Pour Tous** | Le camion s'arrête au centre et déploie un canon à pizza rotatif (360°, tir continu). L'arène se remplit de pizzas. Faut détruire le canon. |
| **Faiblesse** | Le four à pizza à l'arrière est le point faible (dégâts x2). Pendant la Phase 3, le canon peut être détruit en 8 tirs de croissant rifle — le camion explose. |
| **Récompense** | Recette secrète (débloque upgrade d'arme), Pizza gratuite (soin complet) |

---

### 5.2 Garde Républicain Pâtissier (Tier 2.5)

> *"HALTE ! Au nom de la Pâtisserie Française Traditionnelle, vous êtes en état d'arrestation... *sort un éclair au chocolat* ...pour crime de boulange illicite !"*

| Propriété | Valeur |
|-----------|--------|
| **PV** | Boss |
| **Phases** | 2 phases |
| **Arène** | Salon de thé de luxe, tables et chaises comme couverts destructibles |
| **Phase 1 — Contrôle d'Identité** | Le Garde est monté sur un cheval en pain d'épices. Charge de cavalerie (dégâts massifs), coup de matraque-miche de pain. Invoque des Vendeurs de Souvenirs. |
| **Phase 2 (<50%) — État de Siège** | Le cheval est détruit. Le Garde dégaine deux éclairs au chocolat (akimbo). Tir rapide, dash latéral, grenades de crème pâtissière (AoE collante). |
| **Faiblesse** | Le cheval peut être effrayé par le Four Sacré (stun 3s). Les éclairs en Phase 2 peuvent être détruits en plein vol. |
| **Récompense** | Uniforme de Garde (armure cosmétique), Médaille (monnaie) |

---

### 5.3 Sommelier Fou (Tier 3.5)

> *"Un millésime 2087... *débouche une bouteille*... ah, un nez de poudre à canon, des notes de désespoir... *renifle le joueur*... et une finale... de FIN DU MONDE !"*

| Propriété | Valeur |
|-----------|--------|
| **PV** | Boss |
| **Phases** | 4 phases (une par bouteille) |
| **Arène** | Cave à vin circulaire, tonneaux partout |
| **Phase 1 — Rouge** | Vin rouge : nappe au sol (dégâts + ralentissement). Le Sommelier esquive élégamment. |
| **Phase 2 — Blanc** | Vin blanc : bulles qui remontent du sol façon geyser (timing à apprendre). Le Sommelier flotte au-dessus. |
| **Phase 3 — Rosé** | Rosé : mélange des deux patterns, plus rapide. Le Sommelier est enragé. |
| **Phase 4 — Champagne !** | Sabre une bouteille de champagne. Le bouchon traverse l'arène (oneshot). Le champagne explose en fontaine AoE. Le Sommelier est vulnérable après chaque sabrage (fatigue, 2s). |
| **Faiblesse** | Les tonneaux de vin dans l'arène explosent si on tire dedans, endommageant le Sommelier. Le bouchon de champagne peut être tiré en plein vol (timing serré). |
| **Récompense** | Bouteille millésimée (régénération lente pour l'étage suivant), Tire-bouchon (arme de mêlée cosmétique) |

---

## 6. Bosses Majeurs

Un boss à la fin de chaque zone principale. Chaque boss a 3+ phases, une arène unique, et des mécaniques qui testent ce que le joueur a appris.

### 6.1 BOSS ZONE 1 — Le Food Truck Titan

> *Ancien food truck anodin, transformé par les radiations de levure en forteresse roulante de la malbouffe.*

| Aspect | Détail |
|--------|--------|
| **Concept** | Un énorme food truck transformable (mode camion → mode forteresse → mode désespéré). |
| **Arène** | Boulevard Haussmann bloqué. Kiosques à journaux, terrasses renversées, voitures en feu. Le Titan roule de gauche à droite, le joueur doit naviguer le décor. |

**Phase 1 — "Service Au Volant"** : Le Titan roule en cercle, balance des frites brûlantes (zone DoT), des burgers explosifs, et active des essuie-glaces géants (knockback). Des Touristes Zombies et Pigeons Mutants sortent en continu. Point faible : les pneus. Une fois tous explosés → le Titan s'immobilise.

**Phase 2 — " Formule Terrasse"** : Le Titan déploie des pieds hydrauliques et devient une forteresse. Tourelle à soda (tir rapide), lanceur de nuggets (homing), et four à pizza qui lance des pizzas circulaires géantes. Les Vendeurs de Souvenirs apparaissent. Point faible : la tourelle à soda (détruire = stun 5s).

**Phase 3 (<30%) — "Fermeture Définitive"** : Le Titan active l'autodestruction (compte à rebours 60s). Tous les systèmes d'arme tirent en même temps. Des Livreurs à Vélo arrivent en renfort frénétique. Le cœur du réacteur est exposé. Le joueur doit détruire le réacteur avant la fin du compte à rebours — explosion massive qui détruit tout.

**Récompense** : Clé du Food Truck (débloque la Zone 2), Jambon-beurre sacré (soin complet + buff permanent sur le run).

---

### 6.2 BOSS ZONE 2 — Le Grand Critique

> *Un critique gastronomique si puissant que ses mots tuent littéralement. Ancien rédacteur du guide le plus redouté de France, transformé par sa propre amertume.*

| Aspect | Détail |
|--------|--------|
| **Concept** | Boss stationnaire qui attaque avec des mots géants et un stylo-plume démoniaque. |
| **Arène** | Salle de restaurant étoilé abandonnée. Tables blanches, chandeliers instables. Des miroirs reflètent les attaques. |

**Phase 1 — "L'Apéritif"** : Le Critique est assis à une table, invoque des mots flottants qui chargent le joueur ("FADE", "TROP CUIT", "SANS SAVEUR"). Chaque mot est un projectile avec l'effet écrit. Des serveurs zombies apportent des plats (obstacles). Point faible : tirer sur les plats pour les renvoyer — le Critique déteste qu'on lui renvoie ses plats.

**Phase 2 (<70%) — "Le Plat Principal"** : Le Critique se lève. Son stylo-plume devient une épée. Attaques de mêlée rapides avec dash. Invoque "CRITIQUE" en lettres géantes qui écrasent une zone (ombre au sol). Des Hipsters Sans Gluten et Crêpiers Démoniaques apparaissent.

**Phase 3 (<30%) — "L'Addition"** : Le Critique écrit frénétiquement dans l'air. L'écran se couvre de texte critique ("0/10", "HONTEUX", "FERMEZ !"). Le joueur a une visibilité réduite. Le Critique régénère sa vie si le joueur ne tape pas assez vite. Phase de DPS check. Tous les ennemis survivants sont buffés.

**Récompense** : Stylo du Critique (arme cosmétique), Colonne de critique (débloque le dash latéral pour MITCH), nouvelle arme : Pistolet à Encre (t inflige DoT "mauvaise critique").

---

### 6.3 BOSS ZONE 3 — Le Boulanger Déchu

> *L'ancien propriétaire de la boulangerie. Le premier à avoir résisté. Il a tenu 10 ans seul contre les forces anti-gluten. Puis quelque chose s'est brisé. Maintenant, il garde le Four Sacré — la source de tout — et il ne laissera personne l'approcher. Même pas toi, son ancien apprenti.*

| Aspect | Détail |
|--------|--------|
| **Concept** | Boss humanoïde rapide qui utilise toutes les armes du jeu (versions corrompues). |
| **Arène** | La boulangerie originelle, immense et déformée. Le Four Sacré brille au fond. Des sacs de farine explosent. Des pains lévitent. |

**Phase 1 — "Le Mitron"** : Combat en miroir. Le Boulanger Déchu utilise un pistolet à baguettes noires, pose des pièges de pâte, et dash. Patterns identiques au joueur mais plus rapides. Apprend au joueur à maîtriser ce qu'il sait déjà.

**Phase 2 (<70%) — "Le Chef"** : Dégaine un fusil à croissants corrompu ET un lance-pains au chocolat maudit. Attaques combinées. Invoque desTouristes Zombies comme "apprentis". Utilise une capacité "Pétrissage" (le joueur est ralenti, doit spam-tirer pour se libérer).

**Phase 3 (<30%) — "Le Gardien du Four"** : Le Boulanger active le Four Sacré maudit. L'arène entière devient une zone de chaleur (dégâts passifs croissants). Des flammes jaillissent du sol (pattern). Le Boulanger a des attaques de mêlée au tisonnier. Le joueur doit détruire les 4 chaînes qui retiennent le Four pour le libérer — le Four libéré absorbe le Boulanger, combat terminé.

**Récompense** : Le Four Sacré Purifié (ultimate amélioré), Tablier du Boulanger (armure), FARINE ANCESTRALE (ressource pour le crafting de fin de jeu).

**Narratif** : Boss émotionnel. Combat contre son mentor corrompu. Le fantôme du vrai boulanger apparaît après pour remercier MITCH.

---

### 6.4 BOSS FINAL — La M.A.L. (Mère Artificielle du Levain)

> *Une intelligence artificielle créée pour "optimiser" la boulangerie. Elle a décidé que l'humanité était une variable sous-optimale. Elle opère depuis une usine à pain industrielle aux portes de Paris.*

| Aspect | Détail |
|--------|--------|
| **Concept** | Boss techno-organique. Mélange de machines industrielles et de levain mutant. |
| **Arène** | Usine à pain futuriste. Tapis roulants, pétrins géants, fours industriels, cuves de levain. |

**Phase 1 — "Production de Masse"** : La M.A.L. est protégée par un champ de force alimenté par 4 générateurs. Sur des tapis roulants, des pains industriels deviennent des ennemis (tous les types des zones 1-3). Le joueur doit détruire les générateurs tout en gérant le flux d'ennemis. Les tapis roulants changent de direction.

**Phase 2 — "Contrôle Qualité"** : La M.A.L. émerge — un amalgame géant de levain, de circuits imprimés, et de bras robotiques. Bras pétrins (mêlée AoE), jets de levain brûlant (lave au sol), et laser "scan de qualité" (rayon continu qui suit le joueur, oneshot si touché). Des drones livreurs (pigeons robotiques) harcèlent.

**Phase 3 (<50%) — "Rappel Produit"** : La M.A.L. active un champ gravitationnel — attire le joueur vers elle. Le joueur doit tirer en arrière pour résister. Des débris de l'usine volent (obstacles à éviter). Attaque "Pétrissage Final" : toutes les 30s, un pétrin géant s'abat (zone, stun, énormes dégâts).

**Phase 4 (<15%) — "Levain Éternel"** : La M.A.L. surcharge. L'arène tremble. Elle spawn TOUS les types d'ennemis simultanément. Le noyau de levain est exposé. Le joueur doit utiliser tout : armes, environnement, Four Sacré purifié pour infliger assez de dégâts avant d'être submergé.

**Fin** : La M.A.L. explose en une pluie de farine. Paris est libérée. La boulangerie renaît.

**Récompense** : Fin du jeu. New Game+ débloqué avec le mode "Boulangerie Infinie" (rogue-like pur, étages sans fin).

---

## 7. Systèmes Transverses

### 7.1 Modificateurs d'Élite

Tout ennemi standard a 15% de chance d'apparaître en version Élite. Un Élite a :
- Nom affiché en orange avec préfixe (ex: "Pigeon Blindé")
- +50% PV
- +30% dégâts
- 1 capacité additionnelle (définie par type, cf. ci-dessus)
- Aura visuelle (brillance, particules)
- Drop garanti : 1 ressource rare + 2x monnaie

### 7.2 Modificateurs d'Étage (Mutators)

À chaque nouvel étage, 1 modificateur est tiré au sort (affiché au début du niveau) :

| Modificateur | Effet |
|--------------|-------|
| **Nuit Sans Lune** | Les ennemis sont 20% plus agressifs, +15% vitesse |
| **Pâte Qui Lève** | Les ennemis grossissent de 10% toutes les 30s (+taille hitbox, +PV) |
| **Inspection Sanitaire** | +50% d'ennemis, -25% PV par ennemi |
| **Pénurie de Farine** | Drops de soin -50%, drops de munitions +50% |
| **Jour de Marché** | Drops de monnaie x2, ennemis +20% PV |
| **Grève des Livreurs** | Pas de Livreurs à Vélo ni Vendeurs. +30% autres ennemis |
| **Four Surchauffé** | Four Sacré charge 2x plus vite, mais dégâts de feu partout |
| **Vent de Farine** | Visibilité réduite (-30%), ennemis ont -20% de précision |
| **Saint-Honoré** | Bonus rare : les ennemis lâchent un soin en mourant |
| **Apocalypse Gluten** | Tous les ennemis ont +40% PV et +30% dégâts. Drops monnaie x3. Pour les runs challenge. |

### 7.3 Système de Butin

| Type d'ennemi | Drop commun | Drop rare | Drop légendaire |
|---------------|-------------|-----------|-----------------|
| Grunt | Miettes (soin 15%) | Ticket de métro (monnaie) | — |
| Swarmer | Plumes (crafting) | Miettes | Œuf de pigeon (respawn) |
| Soldier | Tour Eiffel cassée (monnaie) | Billet (monnaie x2) | Tour Eiffel dorée (grosse monnaie) |
| Specialist | Graines de chia (soin lent) | Carte périmée | Certificat Bio (immunité debuff 60s) |
| Area Denial | Beurre (2s invulnérabilité) | Pâte crue (grenade collante) | Crêpe Suprême (arme secondaire temporaire) |
| Rusher | Pourboire (monnaie) | Boisson énergétique (buff vitesse) | Sonnette (talisman passif) |
| Spawner | Grains de café (buff attaque) | Lait d'avoine (cure debuff) | Toque (buff PV max) |
| Sniper | Plume (crafting) | Page de critique (monnaie) | Stylo du Critique (une utilisation d'attaque Critique) |
| Heavy | Beurre | Farine (grenade aveuglante) | Tablier (armure temporaire) |
| Buffer Elite | Toque | Étoile Michelin (monnaie rare) | 3 Étoiles (super buff toutes stats 30s) |
| Mini-Boss | Ressource spécifique | Arme cosmétique | Recette (upgrade d'arme permanent) |
| Boss | Clé de zone | Arme cosmétique | Upgrade ultime / Nouvelle arme |

### 7.4 Comportements Absurdes (Gimmicks)

Chaque ennemi a 5% de chance par apparition d'avoir un comportement absurde :

- **Touriste** : Sort un selfie stick et prend un selfie avec le joueur (immobile 3s, flash aveuglant si on regarde)
- **Pigeon** : S'arrête pour picorer... une miette de pain PAR TERRE (priorité absurde)
- **Vendeur** : Essaie de vendre quelque chose à un autre ennemi (les deux sont immobiles 4s)
- **Hipster** : Conteste le prix d'un café (débat avec lui-même, 5s immobile)
- **Crêpier** : Rate son retournement de crêpe (la crêpe lui tombe sur la tête, stun 2s + dégâts)
- **Livreur** : Regarde son GPS, tourne en rond 3s, puis repart
- **Barista** : Fait un latte art... d'une tête de mort (l'ennemi buffé a une tête de mort dans sa mousse)
- **Critique** : Prend une bouchée d'un cadavre ennemi, puis écrit une critique (immobile 4s, si pas tué : grosse attaque)
- **Brigade des Calories** : S'arrête pour souffler (essoufflé, 3s immobile)
- **Chef Étoilé** : Pique une colère et vire un ennemi allié (l'ennemi "viré" s'enfuit du niveau en pleurant)

---

## 8. Progression & Courbe de Difficulté

### 8.1 Structure d'un run

```
Zone 1 (Rue de la Boulangerie)
├── Niveau 1.1 : Introduction — Touristes Zombies uniquement
├── Niveau 1.2 : + Pigeons Mutants
├── Niveau 1.3 : + Vendeurs de Souvenirs
├── Mini-Boss : Camion Pizza Blindé (optionnel)
└── Boss : Food Truck Titan
        ↓
Zone 2 (Le Marais)
├── Niveau 2.1 : Touristes + Pigeons + Hipsters Sans Gluten
├── Niveau 2.2 : + Crêpiers Démoniaques
├── Niveau 2.3 : + Livreurs à Vélo + Baristas Possédés
├── Mini-Boss : Garde Républicain Pâtissier (optionnel)
└── Boss : Le Grand Critique
        ↓
Zone 3 (Les Halles)
├── Niveau 3.1 : Mélange Zone 2 + Critiques Gastronomiques
├── Niveau 3.2 : + Brigade des Calories + Chefs Étoilés
├── Niveau 3.3 : + Nuées de Mouches à Miel
├── Mini-Boss : Sommelier Fou (optionnel)
└── Boss : Le Boulanger Déchu
        ↓
Zone Finale (L'Usine)
├── Niveau 4.1 : Mélange de tout + ennemis corrompus
├── Niveau 4.2 : Élites uniquement
└── Boss Final : La M.A.L.
```

### 8.2 Introduction des mécaniques

| Niveau | Nouveaux ennemis | Mécanique introduite | Arme débloquée |
|--------|------------------|---------------------|----------------|
| 1.1 | Touriste Zombie | Mouvement + tir de base | Pistolet à baguettes |
| 1.2 | Pigeon Mutant | Tracking cibles rapides | — |
| 1.3 | Vendeur de Souvenirs | Couvert + timing de salve | Fusil à croissants |
| Boss 1 | Food Truck Titan | Phases de boss + arène dynamique | — |
| 2.1 | Hipster Sans Gluten | Debuffs + priorisation | Lance-pains au chocolat |
| 2.2 | Crêpier Démoniaque | Contrôle de zone | — |
| 2.3 | Livreur + Barista | Lecture de charge + spawners | — |
| Boss 2 | Le Grand Critique | Boss multi-phases complexe | Pistolet à Encre |
| 3.1 | Critique Gastronomique | Téléportation + oneshot telegraph | — |
| 3.2 | Brigade + Chef Étoilé | Kiting + gestion de buff | — |
| 3.3 | Nuée de Mouches | Gestion de foule massive | — |
| Boss 3 | Le Boulanger Déchu | Combat miroir + mécanique narrative | Four Sacré Purifié |
| Zone 4 | Mélange | Synthèse de tout | — |
| Boss Final | La M.A.L. | Ultimate test | — |

### 8.3 Conseils d'équilibrage

- **Zone 1** : Un joueur débutant doit pouvoir la finir en 2-3 tentatives. Focus sur l'apprentissage.
- **Zone 2** : Taux de réussite visé de 40% pour un joueur qui maîtrise la zone 1. Les debuffs et le contrôle spatial augmentent la difficulté.
- **Zone 3** : 15-20% de réussite. Les combos ennemis deviennent mortels sans bonne priorisation.
- **Zone Finale** : 5% de réussite. Seuls les runs optimisés arrivent ici. Le boss final doit être une célébration, pas une punition.

---

## A. Résumé pour le Plan de Développement

**Pour la phase PROTO (core loop)** :
- Implémenter 3 ennemis : Touriste Zombie, Pigeon Mutant, Vendeur de Souvenirs
- 1 modificateur d'étage simple : "Pâte Qui Lève"
- 1 boss simplifié : Food Truck Titan (2 phases au lieu de 3)

**Pour la phase V1 (contenu complet)** :
- Tous les ennemis Tier 1-3
- Mini-boss + Boss Zone 1-3
- Système d'élites
- Modificateurs d'étage

**Pour la phase V2 (post-launch)** :
- Boss final + Zone 4
- Comportements absurdes (gimmicks)
- Mode New Game+
- Mode "Boulangerie Infinie"

---

*Document de recherche — Version 1.0*
*Phase Brainstorming BAGUETTE*
*À raffiner avec l'équipe*
