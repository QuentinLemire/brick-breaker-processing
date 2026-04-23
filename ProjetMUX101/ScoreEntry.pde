// Rôle : Représenter une entrée du classement (pseudo + score).
// Cette classe sert de structure de données simple pour stocker les scores.
class ScoreEntry {
  String nom;  // pseudo du joueur
  int score;   // score obtenu

  // Constructeur : crée une entrée (nom, score)
  ScoreEntry(String nom, int score) {
    this.nom = nom;
    this.score = score;
  }
}
