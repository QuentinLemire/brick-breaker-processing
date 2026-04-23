// Importation de la librairie Processing Sound.
// Elle permet de jouer des sons dans le jeu.
import processing.sound.*; 

// Déclaration de l’objet principal du jeu.
// La classe Jeu contiendra toute la logique du jeu (menus, partie, sons, etc.).
Jeu jeu;

void setup() {
  // Définition de la taille de la fenêtre du jeu (largeur 900px, hauteur 600px)
  size(900, 600);
  
  // Active l’anti-crénelage pour lisser les formes affichées à l’écran
  smooth();

  // Création de l’objet Jeu.
  // On passe "this" (le PApplet courant) afin que la classe Jeu puisse accéder aux fonctions Processing, notamment pour gérer les sons.
  jeu = new Jeu(this);
}

void draw() {
  jeu.dessiner();
}

void mousePressed() {
  jeu.sourisCliquee();
}

void keyPressed() {
  jeu.toucheAppuyee(key);
}
