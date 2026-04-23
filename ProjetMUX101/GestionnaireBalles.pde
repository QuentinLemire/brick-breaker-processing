// Rôle : Gérer toutes les balles présentes dans le jeu.
// - Stocke la balle principale + les balles bonus (multi-balles)
// - Met à jour les déplacements et rebonds
// - Gère les collisions avec la raquette
// - Supprime les balles tombées en bas de l'écran
// - Déclenche la perte de vie et le passage en GAME OVER
// - Permet d'ajouter une balle bonus déjà lancée
class GestionnaireBalles {

  // Liste dynamique de balles : index 0 = balle principale (la plus importante)
  ArrayList<Balle> balles = new ArrayList<Balle>();

  // Réinitialise la liste de balles en début de partie / nouveau niveau
  // - Supprime toutes les balles
  // - Crée une balle principale en bas de l'écran (en attente)
  void reset(Jeu jeu) {
    balles.clear();
    balles.add(new Balle(width/2, height - 80, 10));
    balles.get(0).mettreEnAttente();
  }

  // Force la balle principale à revenir en attente et à se coller à la raquette.
  // Utilisé typiquement :
  // - au lancement d'une nouvelle vie
  // - après un reset
  void mettreBallePrincipaleEnAttente(Jeu jeu) {
    // Sécurité : si aucune balle n'existe, on recrée une balle principale
    if (balles.size() == 0) {
      balles.add(new Balle(width/2, height - 80, 10));
    }

    // On stoppe la balle puis on la colle à la raquette
    balles.get(0).mettreEnAttente();
    balles.get(0).collerARaquette(jeu.raquette);
  }

  // Lance la balle principale uniquement si elle est en attente (pas déjà lancée)
  // La vitesse de départ (vitesseDepart) doit déjà avoir été réglée par le niveau.
  void lancerBallePrincipaleSiBesoin(Jeu jeu) {
    if (balles.size() == 0) return;

    Balle b = balles.get(0);
    if (!b.lancee) {
      b.lancer(); // b.vitesseDepart est supposée correctement configurée
    }
  }

  // Mise à jour principale : appelée à chaque frame
  // - Déplacement de toutes les balles
  // - Rebonds sur murs
  // - Collision avec la raquette (et son associé)
  // - Suppression des balles tombées en bas
  // - Gestion perte de vie et GAME OVER si plus aucune balle
  void update(Jeu jeu) {

    // Mise à jour des balles (boucle à l'envers pour pouvoir supprimer)
    for (int i = balles.size() - 1; i >= 0; i--) {
      Balle b = balles.get(i);

      // La balle principale (index 0) reste collée à la raquette tant qu'elle n'est pas lancée
      if (i == 0 && !b.lancee) {
        b.collerARaquette(jeu.raquette);
      }

      // Déplacement de la balle + rebonds sur murs
      b.mettreAJour();
      b.rebondirMurs();

      // Détection collision raquette AVANT correction :
      // On calcule la collision ici pour décider de jouer le son de l'impact (car la raquette peut modifier la vitesse juste après).
      boolean vaVersLeBas = (b.vitesseVecteur.y > 0);
      boolean toucheRaquette = collisionBalleRaquette(b, jeu.raquette);

      // La raquette applique la vraie logique de renvoi (angle, correction, etc.)
      jeu.raquette.gererCollision(b);

      // Son seulement si :
      // - la balle descendait (évite les doubles triggers)
      // - il y a collision détectée
      if (toucheRaquette && vaVersLeBas && jeu.sons != null) {
        jeu.sons.jouerHitRaquette();
      }

      // Si la balle passe sous l'écran : elle est considérée comme perdue On la retire de la liste
      if (b.position.y - b.rayon > height) {
        balles.remove(i);
      }
    }

    // Si aucune balle ne reste : le joueur perd une vie
    if (balles.size() == 0) {
      jeu.vies--;

      // Plus de vies -> GAME OVER
      // On joue uniquement le son de game over et on laisse Jeu gérer la suite (top 5, pseudo, écran de fin, etc.)
      if (jeu.vies <= 0) {

        if (jeu.sons != null) jeu.sons.jouerGameOver();
        jeu.etat = EtatJeu.GAMEOVER;

        return; // On stoppe ici : pas de respawn
      }

      // Sinon : perte de vie classique + respawn d'une balle principale
      if (jeu.sons != null) jeu.sons.jouerPerteVie();

      balles.add(new Balle(width/2, height - 80, 10));
      balles.get(0).mettreEnAttente();

      // On réapplique la difficulté du niveau sur la nouvelle balle (ex : vitesse de départ selon niveau)
      jeu.gNiveaux.appliquerDifficulte(jeu);
    }
  }

  // Affiche toutes les balles à l’écran
  void render() {
    for (Balle b : balles) b.afficher();
  }

  // Ajoute une balle bonus déjà lancée (multi-balles)
  // - Sert lors d’un bonus "BALLE"
  // - On lui donne une position et une vitesse de départ
  // - Elle part vers le haut avec un angle aléatoire
  void ajouterBalleLancee(float x, float y, float vitesseDepart) {
    Balle n = new Balle(x, y, 10);

    // On force l'état "lancée" car c'est une balle bonus
    n.lancee = true;

    // On définit la vitesse de départ donnée en paramètre
    n.vitesseDepart = vitesseDepart;

    // Angle aléatoire orienté vers le haut
    float angle = random(radians(240), radians(300));
    n.vitesseVecteur.set(cos(angle) * vitesseDepart, sin(angle) * vitesseDepart);

    // On ajoute la nouvelle balle dans la liste
    balles.add(n);
  }

  /* Collision balle / raquette (cercle vs rectangle)
     Rôle : Fonction utilitaire pour tester rapidement l'impact.
     Principe :
     - On calcule le point du rectangle le plus proche du centre de la balle
     - Si la distance <= rayon : collision */
  boolean collisionBalleRaquette(Balle b, Raquette r) {

    // Limites de la raquette (rectangle centré sur r.x / r.y)
    float left   = r.x - r.largeur/2;
    float right  = r.x + r.largeur/2;
    float top    = r.y - r.hauteur/2;
    float bottom = r.y + r.hauteur/2;

    // Position de la balle
    float bx = b.position.x;
    float by = b.position.y;

    // Point du rectangle le plus proche de la balle
    float closestX = constrain(bx, left, right);
    float closestY = constrain(by, top, bottom);

    // Distance (vecteur) entre le centre de la balle et ce point
    float dx = bx - closestX;
    float dy = by - closestY;

    // Collision si la distance au carré est inférieure au rayon au carré
    return (dx*dx + dy*dy) <= (b.rayon * b.rayon);
  }
}
