// Rôle : Centraliser tous les sons du jeu.
// - Charge les fichiers audio depuis le dossier data/Sons
// - Règle les volumes (amp)
// - Propose des méthodes simples pour jouer chaque son du jeu
// - Utilise une fonction utilitaire "relancer" pour rejouer un son proprement
import processing.sound.*;

class GestionnaireSons {

  // Sons principaux du gameplay
  SoundFile hitRaquette;   // impact balle / raquette
  SoundFile hitBrique;     // impact balle / brique
  SoundFile breakBrique;   // destruction d'une brique
  SoundFile loseLife;      // perte de vie
  SoundFile win;           // victoire
  SoundFile gameOver;      // fin de partie

  // Sons spécifiques aux bonus (un son par type de bonus)
  SoundFile bonusBalle;
  SoundFile bonusRaquette;
  SoundFile bonusVitesse;
  SoundFile bonusEclair;
  SoundFile bonusVie;

  // Constructeur : charge tous les sons et configure leurs volumes
  GestionnaireSons(PApplet app) {

    // Chargements (chemins relatifs au dossier /data)
    hitRaquette  = new SoundFile(app, "Sons/hit_raquette.mp3");
    hitBrique    = new SoundFile(app, "Sons/hit_brique.mp3");
    breakBrique  = new SoundFile(app, "Sons/break_brique.mp3");

    loseLife = new SoundFile(app, "Sons/lose_life.mp3");
    win      = new SoundFile(app, "Sons/win.mp3");
    gameOver = new SoundFile(app, "Sons/game_over.mp3");

    bonusBalle    = new SoundFile(app, "Sons/bonus_balle.mp3");
    bonusRaquette = new SoundFile(app, "Sons/bonus_raquette.mp3");
    bonusVitesse  = new SoundFile(app, "Sons/bonus_vitesse.mp3");
    bonusEclair   = new SoundFile(app, "Sons/bonus_eclair.mp3");
    bonusVie      = new SoundFile(app, "Sons/bonus_vie.mp3");

    // Réglage des volumes (amp = amplitude entre 0.0 et 1.0)
    // Ajustables selon le rendu souhaité dans le jeu
    hitRaquette.amp(0.35);
    hitBrique.amp(0.25);
    breakBrique.amp(0.35);

    loseLife.amp(0.45);
    win.amp(0.6);
    gameOver.amp(0.6);

    bonusBalle.amp(0.45);
    bonusRaquette.amp(0.45);
    bonusVitesse.amp(0.45);
    bonusEclair.amp(0.45);
    bonusVie.amp(0.45);
  }

  // SONS DE JEU (méthodes simples à appeler depuis le reste du programme)
  // Joue le son d’impact sur la raquette
  void jouerHitRaquette() {
    relancer(hitRaquette);
  }

  // Joue le son d’impact sur une brique (sans destruction)
  void jouerHitBrique() {
    relancer(hitBrique);
  }

  // Joue le son de destruction d’une brique
  void jouerBreakBrique() {
    relancer(breakBrique);
  }

  // Joue le son quand une vie est perdue
  void jouerPerteVie() {
    relancer(loseLife);
  }

  // Joue le son de victoire
  void jouerVictoire() {
    relancer(win);
  }

  // Joue le son de game over
  void jouerGameOver() {
    relancer(gameOver);
  }

  // Joue le son correspondant au type de bonus ramassé
  // Le type VITESSE_X2 correspond à un effet x1.5 dans le jeu.
  void jouerBonus(TypeBonus type) {
    switch(type) {
      case BALLE:         relancer(bonusBalle); break;
      case RAQUETTE_PLUS: relancer(bonusRaquette); break;
      case VITESSE_X2:    relancer(bonusVitesse); break;
      case ECLAIR:        relancer(bonusEclair); break;
      case VIE:           relancer(bonusVie); break;
    }
  }

  // Rôle : rejouer un son même s’il est déjà en cours.
  // Problème évité : si un son est déclenché plusieurs fois rapidement,
  // il peut ne pas se relancer tout seul -> on stoppe puis on play().
  void relancer(SoundFile s) {
    if (s == null) return;

    // Si le son joue déjà, on l'arrête pour pouvoir le relancer immédiatement
    if (s.isPlaying()) s.stop();

    // Lecture du son
    s.play();
  }
}
