// Rôle : Définir les différents "écrans" / états possibles du jeu.
// - MENU : écran d'accueil
// - JEU : partie en cours (update + render)
// - PAUSE : partie affichée mais logique stoppée
// - VICTOIRE : fin de niveau (toutes briques détruites)
// - GAMEOVER : fin de partie (plus de vies)
// - SAISIE_SCORE : saisie pseudo si le score entre dans le TOP 5
enum EtatJeu { MENU, JEU, PAUSE, VICTOIRE, GAMEOVER, SAISIE_SCORE }

// Rôle : Cœur du programme (architecture principale).
// - Gère l'état du jeu (menu, pause, victoire, game over, saisie score)
// - Coordonne les entités : raquette, balles, briques, bonus
// - Coordonne les gestionnaires : niveaux, scores, sons
// - Contient la boucle logique : update() + render()
// - Gère les entrées utilisateur : souris et clavier
// - Gère l'interface (HUD, menu, fin, top 5, saisie pseudo)
class Jeu {

  // État actuel (commence sur le menu)
  EtatJeu etat = EtatJeu.MENU;

  // Entités / gestionnaires du jeu
  Raquette raquette;
  GestionnaireBalles gb;
  GestionnaireBonus gBonus;
  GestionnaireNiveaux gNiveaux;
  GestionnaireScores gScores;

  // Gestion des sons (impacts, bonus, victoire, game over...)
  GestionnaireSons sons;

  // Liste des briques du niveau courant
  ArrayList<Brique> briques = new ArrayList<Brique>();

  // Variables de gameplay
  int score = 0;
  int vies = 3;

  // Gestion TOP 5 (pseudo + saisie)
  String pseudo = "";
  int maxPseudo = 12;

  // Permet d'éviter de déclencher plusieurs fois la vérification TOP5 lorsqu'on reste plusieurs frames sur l'écran GAMEOVER.
  boolean finGameOverTraitee = false;

  // Polices utilisées dans l'UI
  PFont policeTitre;
  PFont policeUI;

  // Constructeur : initialise tout le jeu.
  // On reçoit un PApplet (le sketch) pour pouvoir charger les sons.
  Jeu(PApplet app) {

    // Chargement des sons via le gestionnaire dédié
    sons = new GestionnaireSons(app);

    // Chargement des polices depuis data/Polices
    policeTitre = createFont("Polices/Poppins-SemiBold.ttf", 52);
    policeUI    = createFont("Polices/Inter_24pt-Regular.ttf", 18);

    // Police UI par défaut
    textFont(policeUI);

    // Création de la raquette (centrée en bas de l’écran)
    raquette = new Raquette(width/2, height - 50, 100, 16);

    // Instanciation des gestionnaires
    gNiveaux = new GestionnaireNiveaux();
    gb = new GestionnaireBalles();
    gBonus = new GestionnaireBonus();
    gScores = new GestionnaireScores();

    // Chargement du TOP 5 au démarrage (si fichier présent)
    gScores.charger();

    // Démarre une nouvelle partie : niveau 1 + balle en attente + niveau construit
    recommencer();
  }

  // Fonction principale appelée chaque frame (via draw()).
  // Elle dessine le fond et affiche le bon écran selon l'état (switch).
  void dessiner() {
    background(18);

    // Si on vient d’entrer en GAME OVER : déclenche UNE seule fois la vérif TOP5 (sinon, comme draw() tourne en boucle, la vérification se relancerait)
    if (etat == EtatJeu.GAMEOVER && !finGameOverTraitee) {
      finGameOverTraitee = true;
      verifierFinPartieGameOver(); // peut basculer en SAISIE_SCORE
    }

    // Affichage selon l’état du jeu
    switch(etat) {

      case MENU:
        afficherMenu();
        break;

      case JEU:
        update();
        render();
        break;

      case PAUSE:
        // On affiche le jeu mais on ne met pas à jour la logique
        render();
        afficherPause();
        break;

      case VICTOIRE:
        // On affiche le jeu en fond + un overlay de victoire
        render();
        afficherFin(true);
        break;

      case GAMEOVER:
        // On affiche le jeu en fond + overlay game over
        render();
        afficherFin(false);
        break;

      case SAISIE_SCORE:
        // On affiche le jeu en fond + overlay de saisie pseudo
        render();
        afficherSaisieScore();
        break;
    }
  }

  // UPDATE : logique du jeu (déplacements, collisions, bonus...)
  // Appelé uniquement quand etat == JEU.
  void update() {

    // La raquette suit la souris (mouseX), avec contraintes écran dans Raquette
    raquette.mettreAJour(mouseX);

    // Mise à jour des timers d'effets temporaires (raquette+ / vitesse...)
    gBonus.updateTimers(this);

    // Mise à jour des balles (déplacements, rebonds, perte de vie...)
    // ⚠️ Peut mettre etat = GAMEOVER (si vies <= 0)
    gb.update(this);

    // Gestion des collisions balles / briques (multi-balles)
    gererBriques();

    // Mise à jour des bonus (chute + ramassage)
    gBonus.update(this);

    // La victoire n’est pas forcée ici : elle est détectée dans gererBriques()
  }

  // Affichage du jeu
  // - briques, raquette, balles, bonus, HUD
  void render() {

    // Affichage des briques
    for (Brique b : briques) b.afficher();

    // Affichage de la raquette
    raquette.afficher();

    // Affichage des balles + bonus
    gb.render();
    gBonus.render();

    // Affichage de l’interface (score/vies/niveau + raccourcis)
    afficherHUD();
  }

   //  FIN DE PARTIE (GAME OVER uniquement) -> TOP 5 ?
  // Vérifie si le score final entre dans le TOP 5.
  // - Si oui : passage en SAISIE_SCORE
  // - Sinon : reste en GAMEOVER
  void verifierFinPartieGameOver() {
    boolean nouveauRecord = (gScores != null && gScores.estNouveauRecord(score));

    if (nouveauRecord) {
      pseudo = "";
      etat = EtatJeu.SAISIE_SCORE;
    } else {
      etat = EtatJeu.GAMEOVER;
    }
  }

  // Gestion clic souris selon l’état :
  // - MENU : démarrer la partie
  // - VICTOIRE : passer au niveau suivant
  // - GAMEOVER : recommencer une partie
  // - JEU : lancer la balle si elle est en attente
  // - SAISIE_SCORE : pas d'action au clic (validation au clavier)
  void sourisCliquee() {

    if (etat == EtatJeu.MENU) {
      etat = EtatJeu.JEU;
      finGameOverTraitee = false; // reset sécurité
      gb.mettreBallePrincipaleEnAttente(this);
      return;
    }

    if (etat == EtatJeu.VICTOIRE) {
      gNiveaux.niveauSuivant();
      demarrerNouveauNiveau();
      etat = EtatJeu.JEU;
      finGameOverTraitee = false; // reset sécurité
      return;
    }

    if (etat == EtatJeu.GAMEOVER) {
      // Si le score est TOP5, on sera déjà passé en SAISIE_SCORE
      recommencer();
      etat = EtatJeu.JEU;
      finGameOverTraitee = false; // reset sécurité
      return;
    }

    if (etat == EtatJeu.JEU) {
      // Clic pendant le jeu : lance la balle principale si elle est collée
      gb.lancerBallePrincipaleSiBesoin(this);
      return;
    }

    // En SAISIE_SCORE : aucun effet au clic (validation au clavier)
  }

  // Gestion du clavier :
  // - En SAISIE_SCORE : capture des caractères + validation ENTER + BACKSPACE + ESC
  // - Sinon :
  //   P : pause/reprise
  //   M : retour menu + reset partie
  void toucheAppuyee(char k) {

    // SAISIE PSEUDO (prioritaire sur toutes les autres touches)
    if (etat == EtatJeu.SAISIE_SCORE) {

      // ENTER / RETURN : valider et enregistrer le score
      if (k == ENTER || k == RETURN) {
        String nom = trim(pseudo);
        if (nom == null || nom.length() == 0) nom = "Anonyme";

        if (gScores != null) {
          gScores.ajouterScore(nom, score);

          // Recharge pour afficher immédiatement dans le menu (TOP5 à jour)
          gScores.charger();
        }

        // Retour à l'écran GAMEOVER après saisie
        etat = EtatJeu.GAMEOVER;
        return;
      }

      // BACKSPACE : effacer le dernier caractère
      if (k == BACKSPACE) {
        if (pseudo.length() > 0) pseudo = pseudo.substring(0, pseudo.length()-1);
        return;
      }

      // ESC : annuler la saisie (et surtout empêcher Processing de fermer la fenêtre)
      if (k == ESC) {
        key = 0; // empêche la fermeture du sketch
        etat = EtatJeu.GAMEOVER;
        return;
      }

      // Ajout d’un caractère si autorisé et si longueur max non dépassée
      // Autorisés : lettres, chiffres, espace, underscore, tiret
      if (pseudo.length() < maxPseudo) {
        if ( (k >= 'a' && k <= 'z') ||
             (k >= 'A' && k <= 'Z') ||
             (k >= '0' && k <= '9') ||
             k == ' ' || k == '_' || k == '-' ) {
          pseudo += k;
        }
      }
      return;
    }

    // TOUCHES "NORMALES" (hors saisie pseudo)
    // P : bascule pause ↔ jeu
    if (k == 'p' || k == 'P') {
      if (etat == EtatJeu.JEU) etat = EtatJeu.PAUSE;
      else if (etat == EtatJeu.PAUSE) etat = EtatJeu.JEU;
    }

    // M : recommencer + retour menu
    if (k == 'm' || k == 'M') {
      recommencer();
      etat = EtatJeu.MENU;
    }
  }

  // Recommence une partie complète :
  // - score/vies reset
  // - niveau reset
  // - lancement du niveau 1
  void recommencer() {
    score = 0;
    vies = 3;
    finGameOverTraitee = false; // reset sécurité
    gNiveaux.reset();
    demarrerNouveauNiveau();
  }

  // Démarre / reconstruit un niveau :
  // - reset balles (balle principale en attente)
  // - applique la difficulté selon le niveau (vitesse + raquette)
  // - reset bonus (timers + multiplicateurs)
  // - construit les briques du niveau
  void demarrerNouveauNiveau() {
    gb.reset(this);
    gNiveaux.appliquerDifficulte(this);
    gBonus.reset(this);
    gNiveaux.construireNiveau(this);
  }

  // Gère les collisions balles / briques :
  // - Pour chaque brique vivante, on teste toutes les balles
  // - Si collision :
  //    - son impact
  //    - rebond de la balle sur le rectangle
  //    - diminution des PV de la brique
  //    - si PV <= 0 : destruction, ajout score, spawn bonus
  //    - si plus de briques vivantes : victoire + son victoire
  //
  // "return" en fin de collision évite plusieurs collisions dans la même frame (évite bugs et doubles destructions).
  
  void gererBriques() {
    for (int ib = briques.size()-1; ib >= 0; ib--) {
      Brique br = briques.get(ib);
      if (!br.vivante) continue;

      for (Balle ba : gb.balles) {
        if (ba.collisionBrique(br)) {

          // Son d'impact sur brique (à chaque contact)
          if (sons != null) sons.jouerHitBrique();

          // Rebonds sur le rectangle brique
          ba.rebondirRectangle(br.x, br.y, br.largeur, br.hauteur);

          // La brique perd 1 point de vie
          br.pointsDeVie--;

          // Si PV = 0 -> brique détruite
          if (br.pointsDeVie <= 0) {
            br.vivante = false;
            score += br.points;

            // Spawn du bonus si la brique en cachait un
            gBonus.spawnDepuisBrique(this, br);

            // Si c'était la dernière brique -> victoire
            if (toutesBriquesDetruites()) {
              if (etat != EtatJeu.VICTOIRE && sons != null) sons.jouerVictoire();
              etat = EtatJeu.VICTOIRE;
            } else {
              // Sinon son "break" de brique
              if (sons != null) sons.jouerBreakBrique();
            }
          }

          // Empêche d'autres collisions ce frame (stabilité)
          return;
        }
      }
    }
  }

  // Vérifie si toutes les briques sont détruites (aucune vivante)
  boolean toutesBriquesDetruites() {
    for (Brique b : briques) if (b.vivante) return false;
    return true;
  }

     // UI / AFFICHAGE INTERFACE
     
  // HUD : infos en haut (score, vies, niveau) + rappels touches
  void afficherHUD() {
    pushStyle();
    textFont(policeUI);
    fill(255);
    textSize(15);

    textAlign(LEFT, TOP);
    text("Score : " + score, 20, 20);
    text("Vies : " + vies, 20, 40);
    text("Niveau : " + gNiveaux.niveau, 20, 60);

    textAlign(RIGHT, TOP);
    text("P : Pause", width - 20, 20);
    text("M : Menu", width - 20, 40);

    popStyle();
  }

  // MENU : écran d'accueil avec une carte UI + instructions + preview + fenêtre TOP 5 (affichée à droite)
  void afficherMenu() {
    background(32, 26, 52);

    // Paramètres de la "carte" de menu
    float carteL = 560;
    float carteH = 320;
    float cx = width/2;
    float cy = height/2;

    // Carte + ombre
    pushStyle();
    rectMode(CENTER);
    noStroke();
    fill(0, 120);
    rect(cx + 10, cy + 10, carteL, carteH, 20);

    fill(25, 180);
    rect(cx, cy, carteL, carteH, 20);
    popStyle();

    // Titre
    pushStyle();
    textFont(policeTitre);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(52);
    text("CASSE-BRIQUES", cx, cy - 110);
    popStyle();

    // Instructions
    pushStyle();
    textFont(policeUI);
    textAlign(CENTER, CENTER);

    fill(220);
    textSize(16);
    text("Séance 7 — Animation interactive 2D", cx, cy - 75);

    fill(255);
    textSize(20);
    text("Cliquez pour jouer", cx, cy - 20);

    fill(200);
    textSize(15);
    text("Souris : déplacer la raquette", cx, cy + 20);
    text("P : Pause   •   M : Menu", cx, cy + 45);
    text("Objectif : détruire toutes les briques (PV visibles)", cx, cy + 70);
    popStyle();

    // Petit aperçu visuel (briques + raquette + balle)
    float apercuY = height - 170;

    pushStyle();
    rectMode(CENTER);
    noStroke();
    for (int i = -3; i <= 3; i++) {
      float bx = cx + i*55;
      float by = apercuY - 30;
      fill(180 + i*5, 120, 180);
      rect(bx, by, 46, 18, 6);
    }

    fill(230);
    rect(cx, apercuY + 20, 140, 14, 6);

    fill(255);
    ellipse(cx - 90, apercuY, 14, 14);
    popStyle();

    // Fenêtre TOP5 à droite
    afficherFenetreTop5();

    // Crédit bas droite
    pushStyle();
    textFont(policeUI);
    textAlign(RIGHT, BOTTOM);
    textSize(12);
    fill(220, 180);
    text("Created & designed by LEMIRE Quentin", width - 16, height - 12);
    popStyle();
  }

  // Fenêtre TOP 5 (affichée sur le menu)
  // - affiche pseudo + score
  // - tronque les pseudos trop longs (max 9 + "…")
  void afficherFenetreTop5() {
    float w = 150;
    float h = 220;
    float x = width - w - 10;
    float y = 150;

    pushStyle();
    rectMode(CORNER);
    noStroke();

    // Ombre
    fill(0, 120);
    rect(x + 6, y + 6, w, h, 16);

    // Fenêtre
    fill(25, 190);
    rect(x, y, w, h, 16);

    textFont(policeUI);
    fill(255);
    textAlign(LEFT, TOP);
    textSize(16);
    text("TOP 5", x + 18, y + 14);

    // En-têtes
    fill(220);
    textSize(12);
    text("Pseudo", x + 18, y + 42);
    textAlign(RIGHT, TOP);
    text("Score", x + w - 18, y + 42);

    // Séparateur
    stroke(255, 35);
    line(x + 18, y + 62, x + w - 18, y + 62);
    noStroke();

    // Contenu
    float yy = y + 74;
    textSize(14);

    // Aucun score enregistré
    if (gScores == null || gScores.scores == null || gScores.scores.size() == 0) {
      fill(200);
      textAlign(LEFT, TOP);
      text("Aucun score", x + 18, yy);
    } else {

      // Affiche max 5 entrées
      for (int i = 0; i < min(5, gScores.scores.size()); i++) {
        ScoreEntry s = gScores.scores.get(i);

        // Rang
        fill(180);
        textAlign(LEFT, TOP);
        text((i+1) + ".", x + 10, yy);

        // Pseudo (tronqué si trop long)
        String nom = s.nom;
        if (nom.length() > 9) nom = nom.substring(0, 9) + "…";

        fill(255);
        text(nom, x + 28, yy);

        // Score
        textAlign(RIGHT, TOP);
        text(str(s.score), x + w - 10, yy);

        yy += 24;
      }
    }

    popStyle();
  }

  // Overlay pause : filtre sombre + texte PAUSE
  void afficherPause() {
    pushStyle();
    rectMode(CORNER);
    noStroke();
    fill(0, 160);
    rect(0, 0, width, height);
    popStyle();

    pushStyle();
    textFont(policeTitre);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(40);
    text("PAUSE", width/2, height/2);
    popStyle();
  }

  // Overlay de fin (victoire ou game over)
  // - victoire = true : "VICTOIRE !" et message niveau suivant
  // - victoire = false : "GAME OVER" et message rejouer
  void afficherFin(boolean victoire) {
    pushStyle();
    rectMode(CORNER);
    noStroke();
    fill(0, 200);
    rect(0, 0, width, height);
    popStyle();

    pushStyle();
    textFont(policeTitre);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(48);
    text(victoire ? "VICTOIRE !" : "GAME OVER", width/2, height/2 - 80);
    popStyle();

    pushStyle();
    textFont(policeUI);
    fill(255);
    textAlign(CENTER, CENTER);

    textSize(22);
    text("Score final : " + score, width/2, height/2 - 20);

    textSize(16);
    text(victoire ? "Cliquez pour passer au niveau suivant" : "Cliquez pour rejouer", width/2, height/2 + 30);
    text("ou appuyez sur M pour revenir au menu", width/2, height/2 + 55);
    popStyle();
  }

  // Overlay de saisie pseudo (nouveau TOP 5)
  // - Affiche un champ de saisie centré
  // - Affiche un curseur clignotant (underscore)
  void afficherSaisieScore() {
    pushStyle();
    rectMode(CORNER);
    noStroke();
    fill(0, 200);
    rect(0, 0, width, height);

    textAlign(CENTER, CENTER);

    textFont(policeTitre);
    fill(255);
    textSize(40);
    text("NOUVEAU TOP 5 !", width/2, height/2 - 120);

    textFont(policeUI);
    textSize(18);
    fill(230);
    text("Entrez votre pseudo puis appuyez sur Entrée", width/2, height/2 - 70);

    // Champ de saisie (visuel)
    float w = 420;
    float h = 58;
    float x = width/2 - w/2;
    float y = height/2 - h/2;

    fill(255, 25);
    rect(x, y, w, h, 12);

    // Texte saisi + curseur clignotant
    fill(255);
    textSize(22);

    String curseur = (millis()/350 % 2 == 0) ? "_" : " ";
    text(pseudo + curseur, width/2, height/2);

    // Aide saisie
    fill(180);
    textSize(14);
    text("(Backspace = effacer, ESC = annuler)", width/2, height/2 + 55);

    popStyle();
  }
}
