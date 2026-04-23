// Rôle : Définit tous les types de bonus possibles dans le jeu.
// Chaque valeur correspond à un effet différent lorsqu’il est récupéré par la raquette.
enum TypeBonus { 
  BALLE,          // Ajoute une balle supplémentaire
  RAQUETTE_PLUS,  // Agrandit la raquette
  VITESSE_X2,     // Augmente la vitesse de la balle
  ECLAIR,         // Effet spécial (ex : destruction rapide / power-up)
  VIE             // Ajoute une vie au joueur
}

// Rôle : Représente un bonus qui tombe depuis une brique détruite.
// - Gère sa position et sa chute
// - Affiche une icône selon son type
// - Détecte la collision avec la raquette
class Bonus {

  // Position du bonus dans la fenêtre
  float x, y;

  // Taille d’affichage de l’icône
  float taille = 36;

  // Vitesse de descente du bonus
  float vitesseChute = 3.5;

  // Type du bonus (défini par l’énumération ci-dessus)
  TypeBonus type;

  // Indique si le bonus est encore actif à l’écran
  boolean actif = true;

  // Images associées à chaque type de bonus
  // (chargées depuis le dossier data/Images)
  PImage icBalle, icRaquette, icVitesse, icEclair, icVie;

  // Constructeur : crée un bonus à la position (x, y) avec un type donné
  // Charge également les images correspondant aux icônes des bonus
  Bonus(float x, float y, TypeBonus type) {
    this.x = x;
    this.y = y;
    this.type = type;

    // Chargement des images des bonus
    icBalle    = loadImage("Images/bonus_balle.png");
    icRaquette = loadImage("Images/bonus_raquette.png");
    icVitesse  = loadImage("Images/bonus_vitesse.png");
    icEclair   = loadImage("Images/bonus_eclair.png");
    icVie      = loadImage("Images/bonus_vie.png");
  }

  // Met à jour la position du bonus à chaque frame
  // Il descend verticalement jusqu’à sortir de l’écran
  void mettreAJour() {
    y += vitesseChute;

    // Si le bonus sort de l’écran par le bas, on le désactive
    if (y - taille > height) actif = false;
  }

  // Affiche le bonus à l’écran
  // - Sélectionne l’icône correspondant à son type
  // - Affiche une forme de secours si l’image est manquante
  void afficher() {
    if (!actif) return;

    PImage icone = getIcone();

    pushStyle();
    imageMode(CENTER);

    if (icone != null) {
      image(icone, x, y, taille, taille);
    } else {
      // Affichage de secours si l’image n’a pas été trouvée
      noStroke();
      fill(255, 80);
      ellipse(x, y, taille, taille);
    }

    popStyle();
  }

  // Retourne l’image correspondant au type du bonus
  // Utilise un switch sur l’énumération TypeBonus
  PImage getIcone() {
    switch(type) {
      case BALLE:         return icBalle;
      case RAQUETTE_PLUS: return icRaquette;
      case VITESSE_X2:    return icVitesse;
      case ECLAIR:        return icEclair;
      case VIE:           return icVie;
    }
    return null;
  }

  // Détection de collision entre le bonus (cercle) et la raquette (rectangle centré)
  // Même principe que pour la balle : collision cercle / rectangle
  boolean collisionRaquette(Raquette r) {
    // Limites de la raquette
    float gauche = r.x - r.largeur/2;
    float droite = r.x + r.largeur/2;
    float haut   = r.y - r.hauteur/2;
    float bas    = r.y + r.hauteur/2;

    // Point du rectangle le plus proche du centre du bonus
    float cx = constrain(x, gauche, droite);
    float cy = constrain(y, haut, bas);

    // Distance entre ce point et le centre du bonus
    float dx = x - cx;
    float dy = y - cy;

    // Collision si la distance est inférieure au rayon du bonus
    return dx*dx + dy*dy <= (taille/2)*(taille/2);
  }
}
