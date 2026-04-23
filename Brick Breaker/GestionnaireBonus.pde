// - Détermine si une brique contient un bonus (tirage / rareté)
// - Fait apparaître les bonus lors de la destruction des briques
// - Met à jour la chute des bonus et détecte la récupération par la raquette
// - Applique les effets (multi-balle, raquette plus, vitesse, éclair, vie)
// - Gère les effets temporaires avec des timers (millis())
class GestionnaireBonus {

  // Liste des bonus actuellement visibles à l'écran
  ArrayList<Bonus> bonus = new ArrayList<Bonus>();

  // Timers (en millisecondes) pour les effets temporaires
  // Valeur 0 = aucun effet actif
  int finVitesseX15 = 0;     // moment où l'effet vitesse (x1.5) se termine
  int finRaquettePlus = 0;   // moment où l'effet raquette +20% se termine

  // Multiplicateurs courants (pour suivre les effets actifs)
  float multiplicateurRaquette = 1.0;
  float multiplicateurVitesse = 1.0;

  // Largeur de référence de la raquette selon le niveau (sans bonus).
  // Sert à restaurer correctement la largeur quand RAQUETTE_PLUS se termine.
  float largeurRaquetteNiveau = 100;

  // Probabilité fixe qu'une brique contienne un bonus (7%)
  float probaBonus = 0.07;

  // Tire aléatoirement un type de bonus (répartition uniforme entre 5 bonus).
  // Ici : random(5) -> entier 0..4.
  TypeBonus tirerTypeBonus() {
    int r = int(random(5)); // 0..4
    if (r == 0) return TypeBonus.BALLE;
    if (r == 1) return TypeBonus.RAQUETTE_PLUS;
    if (r == 2) return TypeBonus.VITESSE_X2;  // dans le jeu : effet x1.5
    if (r == 3) return TypeBonus.ECLAIR;
    return TypeBonus.VIE;
  }

  // Donne un bonus caché pour une brique (ou null s'il n'y en a pas).
  // - Si random < probaBonus : la brique recevra un bonus
  // - Sinon : aucun bonus
  TypeBonus tirerBonusCache() {
    if (random(1) < probaBonus) {
      return tirerTypeBonus();
    }
    return null;
  }

  // Réinitialisation du gestionnaire :
  // - Supprime tous les bonus présents
  // - Réinitialise les timers et multiplicateurs
  // - Enregistre la largeur actuelle de raquette (après application du niveau)
  void reset(Jeu jeu) {
    bonus.clear();

    finVitesseX15 = 0;
    finRaquettePlus = 0;

    multiplicateurRaquette = 1.0;
    multiplicateurVitesse = 1.0;

    // Largeur de référence (celle définie par la difficulté/niveau)
    largeurRaquetteNiveau = jeu.raquette.largeur;
  }

  // Fait apparaître un bonus lorsqu'une brique est détruite, si elle en possède un.
  // Le bonus apparaît au centre de la brique.
  void spawnDepuisBrique(Jeu jeu, Brique br) {
    if (br.bonusCache == null) return;
    bonus.add(new Bonus(br.x + br.largeur/2, br.y + br.hauteur/2, br.bonusCache));
  }

  // Met à jour les effets temporaires :
  // - Si le timer est dépassé, on remet les multiplicateurs à 1 et on restaure.
  void updateTimers(Jeu jeu) {

    // Effet vitesse x1.5 terminé ?
    if (finVitesseX15 > 0 && millis() > finVitesseX15) {
      multiplicateurVitesse = 1.0;
      finVitesseX15 = 0;
    }

    // Effet raquette +20% terminé ?
    if (finRaquettePlus > 0 && millis() > finRaquettePlus) {
      multiplicateurRaquette = 1.0;
      finRaquettePlus = 0;

      // On revient à la largeur de référence du niveau
      jeu.raquette.setLargeur(largeurRaquetteNiveau);
    }
  }

  // Mise à jour principale :
  // - Déplace les bonus (chute)
  // - Détecte collision avec la raquette
  // - Joue le son de ramassage
  // - Applique l'effet correspondant
  // - Supprime les bonus inactifs
  void update(Jeu jeu) {
    for (int i = bonus.size() - 1; i >= 0; i--) {
      Bonus b = bonus.get(i);
      b.mettreAJour();

      // Si le bonus touche la raquette : on le ramasse
      if (b.collisionRaquette(jeu.raquette)) {

        // Son de bonus au moment du ramassage
        if (jeu.sons != null) {
          jeu.sons.jouerBonus(b.type);
        }

        // Application de l'effet selon le type
        appliquerBonus(jeu, b.type);

        // Marqué comme inactif (sera supprimé)
        b.actif = false;
      }

      // Nettoyage : suppression des bonus inactifs
      if (!b.actif) bonus.remove(i);
    }
  }

  // Affiche tous les bonus visibles
  void render() {
    for (Bonus b : bonus) b.afficher();
  }

  // Applique l'effet d'un bonus, selon son type
  // - Certains effets sont instantanés (VIE, ECLAIR)
  // - D'autres sont temporaires (RAQUETTE_PLUS, VITESSE)
  // - Le bonus BALLE crée une nouvelle balle déjà lancée
  void appliquerBonus(Jeu jeu, TypeBonus type) {
    switch(type) {

      case BALLE:
        // Ajoute une balle "bonus" déjà lancée au-dessus de la raquette
        // La vitesse dépend du niveau (vitesseBase + incrément par niveau)
        jeu.gb.ajouterBalleLancee(
          jeu.raquette.x,
          jeu.raquette.y - jeu.raquette.hauteur/2 - 10,
          jeu.gNiveaux.vitesseBase + (jeu.gNiveaux.niveau - 1) * jeu.gNiveaux.vitesseParNiveau
        );
        break;

      case RAQUETTE_PLUS:
        // IMPORTANT : on prend comme référence la largeur du niveau (non boostée)
        // afin d’éviter l’empilement ou un retour à une mauvaise valeur.
        largeurRaquetteNiveau = jeu.raquette.largeur;

        // Bonus : +20% de largeur pendant 10 secondes
        multiplicateurRaquette = 1.2;
        jeu.raquette.setLargeur(largeurRaquetteNiveau * multiplicateurRaquette);

        // Fin de l'effet dans 10 secondes
        finRaquettePlus = millis() + 10000;
        break;

      case VITESSE_X2:
        // Bonus vitesse : multiplie la vitesse des balles lancées (x1.5)
        // On agit directement sur les vecteurs vitesse actuels.
        for (Balle ba : jeu.gb.balles) {
          if (ba.lancee) ba.vitesseVecteur.mult(1.5);
        }

        // On garde l'information que l'effet est actif
        multiplicateurVitesse = 1.5;

        // Fin de l'effet dans 8 secondes
        finVitesseX15 = millis() + 8000;
        break;

      case ECLAIR:
        // Effet spécial : toutes les briques perdent 1 point de vie
        // Si une brique tombe à 0 PV, elle est détruite :
        // - on ajoute les points
        // - on peut faire apparaître son bonus caché
        for (Brique br : jeu.briques) {
          if (!br.vivante) continue;

          br.pointsDeVie--;
          if (br.pointsDeVie <= 0) {
            br.vivante = false;
            jeu.score += br.points;

            // Si la brique détruite contenait un bonus, on le spawn
            spawnDepuisBrique(jeu, br);
          }
        }
        // Si l'éclair termine le niveau -> victoire
        if (jeu.toutesBriquesDetruites()) {
          if (jeu.sons != null) jeu.sons.jouerVictoire();
          jeu.etat = EtatJeu.VICTOIRE;
        }
        break;

      case VIE:
        // Bonus simple : gagne une vie
        jeu.vies++;
        break;
    }
  }
}
