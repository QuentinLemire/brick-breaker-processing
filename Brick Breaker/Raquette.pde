// Rôle : Représente la raquette contrôlée par le joueur.
// - Se déplace horizontalement en suivant la souris (ou une cible X)
// - Est contrainte à rester dans les limites de l'écran
// - S'affiche à l'écran
// - Gère la collision avec la balle et calcule un renvoi "réaliste" : plus on touche sur les côtés, plus la balle part en diagonale.
class Raquette {

  // Position du centre de la raquette
  float x, y;

  // Dimensions de la raquette
  float largeur, hauteur;

  // Constructeur : initialise la raquette
  // - x, y : position du centre
  // - largeur, hauteur : dimensions
  Raquette(float x, float y, float largeur, float hauteur) {
    this.x = x;
    this.y = y;

    // Largeur initiale (taille "de base" avant bonus / niveau)
    this.largeur = largeur;

    this.hauteur = hauteur;
  }

  // Modifie la largeur de la raquette (utilisé par niveaux/bonus)
  void setLargeur(float nouvelleLargeur) {
    largeur = nouvelleLargeur;
  }

  // Retourne la largeur actuelle (utile si une autre classe doit la connaître)
  float getLargeur() {
    return largeur;
  }

  // Met à jour la position horizontale de la raquette
  // cibleX = position souhaitée (souvent mouseX)
  // constrain(...) empêche la raquette de sortir de l'écran :
  // - minimum : largeur/2 (bord gauche)
  // - maximum : width - largeur/2 (bord droit)
  void mettreAJour(float cibleX) {
    x = constrain(cibleX, largeur / 2, width - largeur / 2);
  }

  // Affiche la raquette à l'écran (rectangle centré, coins arrondis)
  // pushStyle/popStyle : protège le style (couleurs, modes) du reste du jeu
  void afficher() {
    pushStyle();
    rectMode(CENTER);
    noStroke();
    fill(230);
    rect(x, y, largeur, hauteur, 6);
    popStyle();
  }

  // Gère la collision avec la balle :
  // - si la balle touche la raquette (détection côté Balle)
  // - alors on calcule un renvoi (direction + angle)
  void gererCollision(Balle balle) {
    if (balle.collisionRaquette(this)) {
      renvoyerBalle(balle);
    }
  }

  // Calcule le renvoi de la balle selon l’endroit où elle touche la raquette.
  // Principe :
  // - On calcule un "décalage" entre -1 et +1 :
  //    -1 = bord gauche de la raquette
  //     0 = centre
  //    +1 = bord droit
  // - On convertit ce décalage en angle, autour d’une direction vers le haut.
  // - On conserve la vitesse actuelle de la balle (on change seulement direction).
  void renvoyerBalle(Balle balle) {

    // Décalage normalisé : (position balle - centre raquette) / demi-largeur
    float decalage = (balle.position.x - x) / (largeur / 2);

    // Sécurise le décalage pour éviter des valeurs hors plage
    decalage = constrain(decalage, -1, 1);

    // Angle max (plus grand = renvoi plus "diagonal" sur les bords)
    float angleMax = radians(65);

    // Angle de base vers le haut = 3*PI/2 (270°)
    // Puis on ajoute/subtracte selon le décalage
    float angle = (3*PI/2) + decalage * angleMax;

    // On garde la vitesse actuelle de la balle
    float vitesse = balle.vitesse();

    // Nouvelle direction : trigonométrie (cos = x, sin = y)
    balle.vitesseVecteur.x = cos(angle) * vitesse;
    balle.vitesseVecteur.y = sin(angle) * vitesse;

    // Sécurité : on s'assure que la balle repart bien vers le haut
    // (si jamais un calcul la renvoie vers le bas)
    if (balle.vitesseVecteur.y > 0)
      balle.vitesseVecteur.y *= -1;
  }
}
