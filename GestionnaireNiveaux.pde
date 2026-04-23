// Rôle : Gérer la progression des niveaux et la difficulté du jeu.
// - Stocke le numéro de niveau courant
// - Définit la grille de briques (colonnes / lignes) et les marges d'affichage
// - Ajuste la difficulté : vitesse des balles, taille de la raquette, etc.
// - Construit un niveau en générant les briques (position, PV, points, bonus)
class GestionnaireNiveaux {

  // Niveau actuel (commence à 1)
  int niveau = 1;

  // Paramètres de la grille de briques (nombre de colonnes et de lignes possibles)
  int colonnes = 10;
  int lignes = 6;

  // Marges d'affichage pour placer la grille de briques à l'écran
  float margeHaute = 80;   // distance du haut de l'écran
  float margeCote = 60;    // marge à gauche et à droite

  // Espace entre les briques (horizontal et vertical)
  float espaceBrique = 6;

  // Difficulté : vitesse des balles
  // - vitesseBase : vitesse au niveau 1
  // - vitesseParNiveau : augmentation par niveau
  float vitesseParNiveau = 0.6;
  float vitesseBase = 7.5;

  // Difficulté : taille de la raquette
  // - la raquette rétrécit progressivement
  // - largeurMinRaquette : limite pour éviter qu'elle devienne injouable
  float largeurMinRaquette = 70;
  float retrecissementParNiveau = 6;

  // Remet le niveau à 1 (nouvelle partie / reset)
  void reset() { 
    niveau = 1; 
  }

  // Passe au niveau suivant
  void niveauSuivant() { 
    niveau++; 
  }

  // Applique la difficulté du niveau courant au jeu :
  // - définit la vitesse de départ des balles
  // - ajuste la largeur de la raquette (rétrécissement)
  void appliquerDifficulte(Jeu jeu) {

    // Vitesse de la balle selon le niveau (croissance linéaire)
    float vitesse = vitesseBase + (niveau - 1) * vitesseParNiveau;

    // Largeur de référence au niveau 1 (choix de design)
    float largeurN1 = 100;

    // Nouvelle largeur : diminue à chaque niveau mais ne descend pas sous un minimum
    float newL = max(largeurN1 - (niveau - 1) * retrecissementParNiveau, largeurMinRaquette);

    // Application sur la raquette
    jeu.raquette.setLargeur(newL);

    // Balles : vitesse de départ
    // On applique la vitesse de départ à toutes les balles existantes
    for (Balle b : jeu.gb.balles) b.vitesseDepart = vitesse;
  }

  // Construit (génère) le niveau courant :
  // - Vide la liste de briques
  // - Calcule la taille des briques pour tenir dans la zone utile
  // - Choisit aléatoirement un nombre de briques selon une densité croissante
  // - Donne à chaque brique :
  //    - une position dans la grille
  //    - des points de vie aléatoires (plus élevés avec les niveaux)
  //    - un score proportionnel aux PV
  //    - un bonus caché (tiré via GestionnaireBonus)
  void construireNiveau(Jeu jeu) {
    // Supprime toutes les briques de l'ancien niveau
    jeu.briques.clear();

    // Largeur disponible pour placer les briques (sans dépasser les marges)
    float largeurUtile = width - 2 * margeCote;

    // Calcul de la largeur d'une brique pour rentrer exactement sur "colonnes" en tenant compte des espaces entre briques
    float largeurBrique = (largeurUtile - (colonnes - 1) * espaceBrique) / colonnes;

    // Hauteur fixe d'une brique (choix de design)
    float hauteurBrique = 26;

    // Nombre total de cases dans la grille
    int total = colonnes * lignes;

    // DENSITÉ : part de cases de la grille réellement remplies par des briques
    // - augmente progressivement avec le niveau
    // - bornée entre 60% et 95% pour garder un niveau jouable
    float densite = 0.60 + 0.04 * (niveau - 1);
    densite = constrain(densite, 0.60, 0.95);

    // Nombre réel de briques à générer
    int nbBriques = ceil(total * densite);

    // PV MAX : la résistance des briques augmente avec le niveau
    // Exemple : +1 PV max tous les 2 niveaux, avec un maximum à 8.
    int pvMax = 2 + (niveau - 1) / 2;
    pvMax = min(pvMax, 8);

    // Pour répartir les briques de manière aléatoire :
    // - on crée la liste de toutes les cases possibles
    // - on mélange (shuffle)
    // - on prend les nbBriques premières cases
    IntList cases = new IntList();
    for (int i = 0; i < total; i++) cases.append(i);
    cases.shuffle();

    // Création des briques sélectionnées
    for (int k = 0; k < nbBriques; k++) {
      int idx = cases.get(k);

      // Conversion index -> ligne/colonne
      int l = idx / colonnes;
      int c = idx % colonnes;

      // Calcul de la position réelle à l'écran
      float x = margeCote + c * (largeurBrique + espaceBrique);
      float y = margeHaute + l * (hauteurBrique + espaceBrique);

      // PV aléatoires entre 1 et pvMax (inclus)
      int pv = int(random(1, pvMax + 1));

      // Score : proportionnel aux points de vie (brique plus dure = plus de points)
      int points = pv * 20;

      // Tirage d'un bonus caché (ou null) via le gestionnaire de bonus
      TypeBonus cache = jeu.gBonus.tirerBonusCache();

      // Ajout de la brique dans la liste du jeu
      jeu.briques.add(new Brique(x, y, largeurBrique, hauteurBrique, pv, points, cache));
    }
  }
}
