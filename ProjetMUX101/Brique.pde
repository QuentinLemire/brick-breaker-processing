// Rôle : Représente une brique du jeu de type casse-briques.
// - Possède des points de vie (résistance)
// - Donne un certain nombre de points au joueur
// - Peut contenir un bonus caché
// - S’affiche à l’écran et disparaît lorsqu’elle est détruite
class Brique {

  // Position de la brique (coin haut-gauche)
  float x, y;

  // Dimensions de la brique
  float largeur, hauteur;

  // Nombre de coups nécessaires pour détruire la brique
  int pointsDeVie;

  // Nombre de points accordés au joueur lorsque la brique est détruite
  int points;

  // Indique si la brique est encore présente dans le jeu
  boolean vivante = true;

  // Bonus éventuellement caché dans la brique
  // (peut être null s’il n’y a pas de bonus)
  TypeBonus bonusCache = null;

  // Constructeur : initialise une brique avec :
  // - sa position (x, y)
  // - sa taille (l, h)
  // - ses points de vie (pv)
  // - les points qu’elle rapporte (pts)
  // - un éventuel bonus caché
  Brique(float x, float y, float l, float h, int pv, int pts, TypeBonus bonusCache) {
    this.x = x;
    this.y = y;
    largeur = l;
    hauteur = h;
    pointsDeVie = pv;
    points = pts;
    this.bonusCache = bonusCache;
  }

  // Affiche la brique à l’écran
  // - La couleur varie selon les points de vie restants
  // - Le nombre de points de vie est affiché au centre
  void afficher() {
    // Si la brique est détruite, on ne l’affiche plus
    if (!vivante) return;

    pushStyle();

    // Dessin du rectangle représentant la brique
    rectMode(CORNER);

    // La couleur devient plus claire quand la brique est plus résistante
    float intensite = map(pointsDeVie, 1, 3, 180, 255);
    fill(intensite, 120, 180);
    noStroke();
    rect(x, y, largeur, hauteur, 6); // bords arrondis

    // Affichage du nombre de points de vie au centre de la brique
    fill(0, 180);
    textAlign(CENTER, CENTER);
    textSize(14);
    text(pointsDeVie, x + largeur/2, y + hauteur/2);

    popStyle();
  }
}
