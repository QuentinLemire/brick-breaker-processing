// Rôle : Représente la balle du jeu (type casse-briques).
// - Gère sa position, sa vitesse, son état (lancée ou en attente)
// - Met à jour son déplacement
// - Affiche la balle
// - Détecte les collisions (raquette / brique)
// - Applique les rebonds (murs / rectangles)
class Balle {

  // Position actuelle de la balle (x, y)
  PVector position = new PVector();

  // Position à l’image précédente : utile pour déterminer "d'où vient" la balle afin de calculer un rebond cohérent (haut/bas/gauche/droite)
  PVector positionPrecedente = new PVector();

  // Vecteur vitesse (vx, vy) : direction + intensité du mouvement
  PVector vitesseVecteur = new PVector();

  // Rayon de la balle (taille = rayon * 2)
  float rayon;

  // État : false = balle collée / en attente, true = balle en mouvement
  boolean lancee = false;

  // Vitesse initiale au moment du lancement
  float vitesseDepart = 7.5;

  // Constructeur : initialise la balle à une position (x, y) et un rayon r
  Balle(float x, float y, float r) {
    position.set(x, y);
    rayon = r;

    // Tant que la balle n'est pas lancée : elle ne bouge pas
    vitesseVecteur.set(0, 0);
  }

  // Colle la balle sur la raquette (avant lancement)
  // On place la balle au-dessus de la raquette en tenant compte du rayon.
  void collerARaquette(Raquette raquette) {
    position.x = raquette.x;
    position.y = raquette.y - raquette.hauteur/2 - rayon;
  }

  // Lance la balle : elle part vers le haut avec un angle aléatoire.
  // Angles choisis entre 240° et 300° (en radians) = direction globalement vers le haut.
  void lancer() {
    lancee = true;

    // Choix d’un angle aléatoire orienté vers le haut
    float angle = random(radians(240), radians(300));

    // Conversion angle -> vecteur vitesse (cos, sin)
    vitesseVecteur.set(cos(angle) * vitesseDepart, sin(angle) * vitesseDepart);
  }

  // Remet la balle en attente : elle s'arrête et n'avance plus
  void mettreEnAttente() {
    lancee = false;
    vitesseVecteur.set(0, 0);
  }

  // Met à jour la position de la balle à chaque frame
  // - Sauvegarde la position précédente (pour les collisions)
  // - Ajoute la vitesse à la position
  void mettreAJour() {
    // Si la balle n'est pas lancée : aucun mouvement
    if (!lancee) return;

    positionPrecedente.set(position);
    position.add(vitesseVecteur);
  }

  // Affichage de la balle (cercle blanc sans contour)
  void afficher() {
    noStroke();
    fill(255);
    ellipse(position.x, position.y, rayon*2, rayon*2);
  }

  // Rebonds sur les murs de l'écran (gauche / droite / haut)
  // - On repositionne la balle pour éviter qu'elle reste "dans le mur"
  // - On inverse la composante de vitesse correspondante
  void rebondirMurs() {
    if (!lancee) return;

    // Mur gauche
    if (position.x - rayon < 0) {
      position.x = rayon;
      vitesseVecteur.x *= -1;
    }
    // Mur droit
    else if (position.x + rayon > width) {
      position.x = width - rayon;
      vitesseVecteur.x *= -1;
    }

    // Mur du haut
    if (position.y - rayon < 0) {
      position.y = rayon;
      vitesseVecteur.y *= -1;
    }
  }

  // Retourne la vitesse (norme du vecteur vitesse)
  // Utile si on veut afficher une info debug ou ajuster la difficulté.
  float vitesse() {
    return vitesseVecteur.mag();
  }

  // Collision balle / raquette (rectangle centré)
  // Principe :
  // - On cherche le point du rectangle le plus proche du centre de la balle
  // - On mesure la distance entre ce point et la balle
  // - Collision si distance <= rayon
  // - Condition vitesseVecteur.y > 0 : la balle doit descendre pour toucher la raquette
  boolean collisionRaquette(Raquette r) {
    float cx = constrain(position.x, r.x - r.largeur/2, r.x + r.largeur/2);
    float cy = constrain(position.y, r.y - r.hauteur/2, r.y + r.hauteur/2);

    float dx = position.x - cx;
    float dy = position.y - cy;

    return dx*dx + dy*dy <= rayon*rayon && vitesseVecteur.y > 0;
  }

  // Collision balle / brique (rectangle "classique" : coin haut-gauche + largeur/hauteur)
  // Même principe de collision cercle-rectangle avec point le plus proche.
  boolean collisionBrique(Brique b) {
    float cx = constrain(position.x, b.x, b.x + b.largeur);
    float cy = constrain(position.y, b.y, b.y + b.hauteur);

    float dx = position.x - cx;
    float dy = position.y - cy;

    return dx*dx + dy*dy <= rayon*rayon;
  }

  // Rebonds sur un rectangle quelconque (brique, raquette, etc.)
  // Objectif : savoir de quel côté la balle est entrée (haut/bas/gauche/droite) en comparant la position actuelle avec la position précédente.
  // xRect, yRect : position du rectangle (coin haut-gauche)
  // lRect, hRect : largeur et hauteur du rectangle
  void rebondirRectangle(float xRect, float yRect, float lRect, float hRect) {

    // Limites du rectangle
    float gauche  = xRect;
    float droite  = xRect + lRect;
    float haut    = yRect;
    float bas     = yRect + hRect;

    // Position précédente (avant déplacement)
    float xAvant = positionPrecedente.x;
    float yAvant = positionPrecedente.y;

    // Cas 1 : la balle arrivait d’au-dessus -> rebond sur le haut du rectangle
    if (yAvant + rayon <= haut && position.y + rayon > haut) {
      position.y = haut - rayon;   // on replace la balle juste au-dessus
      vitesseVecteur.y *= -1;      // on inverse la vitesse verticale
      return;
    }

    // Cas 2 : la balle arrivait d’en dessous -> rebond sur le bas du rectangle
    if (yAvant - rayon >= bas && position.y - rayon < bas) {
      position.y = bas + rayon;
      vitesseVecteur.y *= -1;
      return;
    }

    // Cas 3 : la balle arrivait de la gauche -> rebond sur le côté gauche
    if (xAvant + rayon <= gauche && position.x + rayon > gauche) {
      position.x = gauche - rayon;
      vitesseVecteur.x *= -1;
      return;
    }

    // Cas 4 : la balle arrivait de la droite -> rebond sur le côté droit
    if (xAvant - rayon >= droite && position.x - rayon < droite) {
      position.x = droite + rayon;
      vitesseVecteur.x *= -1;
      return;
    }

    // Cas ambigu :
    // Si on ne peut pas déterminer clairement le côté (collision d'angle),on choisit l'axe où la pénétration dans le rectangle est la plus faible.
    float chevaucheX = min(abs(position.x - gauche), abs(position.x - droite));
    float chevaucheY = min(abs(position.y - haut), abs(position.y - bas));

    if (chevaucheX < chevaucheY) vitesseVecteur.x *= -1;
    else vitesseVecteur.y *= -1;
  }
}
