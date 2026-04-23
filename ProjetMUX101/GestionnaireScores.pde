// Rôle : Gérer le classement des meilleurs scores (TOP 5).
// - Charge les scores depuis un fichier texte (data/scores.txt)
// - Sauvegarde les scores dans le même format
// - Détecte si un score est un nouveau record
// - Ajoute un score, trie et conserve uniquement les 5 meilleurs
//
// Format du fichier : une ligne par entrée
//   pseudo|score
// Exemple :
//   Manon|1200
//   Quentin|950
class GestionnaireScores {

  // Chemin du fichier de stockage (dans le dossier data/ du sketch)
  final String FICHIER = "data/scores.txt";

  // Nombre maximum d'entrées conservées (TOP 5)
  final int MAX = 5;

  // Taille maximum autorisée pour un pseudo (cohérent avec la saisie côté Jeu)
  final int MAX_PSEUDO = 12;

  // Liste en mémoire des scores chargés (ou créés pendant la partie)
  ArrayList<ScoreEntry> scores = new ArrayList<ScoreEntry>();

  // Charge les scores depuis le fichier.
  // - Si le fichier n'existe pas : pas d'erreur bloquante (liste vide)
  // - Ignore les lignes invalides
  // - Nettoie les pseudos (séparateurs, retours ligne, longueur max)
  // - Trie et garde uniquement les 5 meilleurs
  void charger() {
    scores.clear();

    String[] lignes = null;

    // Tentative de lecture du fichier (try/catch pour éviter crash si absent)
    try {
      lignes = loadStrings(FICHIER);
    } catch(Exception e) {
      lignes = null; // fichier absent -> pas grave
    }

    // Rien à charger
    if (lignes == null) return;

    // Analyse de chaque ligne du fichier
    for (String l : lignes) {
      if (l == null) continue;

      l = trim(l);
      if (l.length() == 0) continue;

      // Format attendu : nom|score
      String[] p = split(l, '|');
      if (p == null || p.length < 2) continue;

      // Nettoyage du pseudo (évite de casser le format)
      String nom = nettoyerPseudo(p[0]);

      // Lecture du score : si invalide, on met 0
      int sc = 0;
      try { 
        sc = int(trim(p[1])); 
      } catch(Exception e) { 
        sc = 0; 
      }
      
      // Ajout en mémoire
      scores.add(new ScoreEntry(nom, sc));
    }

    // Tri et conservation du TOP 5
    trierEtCouper();
  }

  // Sauvegarde la liste des scores dans le fichier.
  // - Trie et coupe avant sauvegarde (garantie TOP 5)
  // - Réécrit le fichier entièrement (écrase l'ancien)
  void sauvegarder() {
    trierEtCouper();

    // Conversion de la liste en tableau de lignes "nom|score"
    String[] lignes = new String[scores.size()];
    for (int i = 0; i < scores.size(); i++) {
      ScoreEntry s = scores.get(i);
      lignes[i] = s.nom + "|" + s.score;
    }

    // Écriture/écrasement propre du fichier
    saveStrings(FICHIER, lignes);
  }

  // Indique si un score donné mérite d'entrer dans le TOP 5.
  // - Si moins de 5 scores enregistrés -> oui
  // - Sinon -> doit être strictement supérieur au dernier du classement
  boolean estNouveauRecord(int score) {
    if (score < 0) score = 0;

    // S'il manque des entrées, c'est forcément un record (place libre)
    if (scores.size() < MAX) return true;

    // Comparaison avec le plus petit du TOP 5 (dernier après tri décroissant)
    return score > scores.get(scores.size()-1).score;
  }

  // Ajoute un score dans la liste + sauvegarde immédiate.
  // - Nettoie le pseudo
  // - Remplace par "Anonyme" si vide
  // - Trie + coupe + sauvegarde
  void ajouterScore(String nom, int score) {
    if (score < 0) score = 0;

    nom = nettoyerPseudo(nom);
    if (nom == null || nom.length() == 0) nom = "Anonyme";

    scores.add(new ScoreEntry(nom, score));
    trierEtCouper();
    sauvegarder();
  }

  // Trie la liste des scores par ordre décroissant (plus grand score d'abord)
  // puis supprime tout ce qui dépasse MAX (TOP 5).
  void trierEtCouper() {

    // Tri décroissant par score (Comparator personnalisé)
    scores.sort(new java.util.Comparator<ScoreEntry>() {
      public int compare(ScoreEntry a, ScoreEntry b) {
        return b.score - a.score;
      }
    });

    // Suppression des entrées en trop (on garde uniquement MAX)
    while (scores.size() > MAX) scores.remove(scores.size()-1);
  }

  // Nettoie un pseudo pour éviter de casser le fichier.
  // Objectifs :
  // - enlever le séparateur '|'
  // - enlever les retours à la ligne
  // - réduire les espaces multiples
  // - limiter la longueur du pseudo
  String nettoyerPseudo(String nom) {
    if (nom == null) return "";

    nom = trim(nom);

    // Supprime séparateur + retours ligne (sécurité format fichier)
    nom = nom.replace("|", "");
    nom = nom.replace("\n", "");
    nom = nom.replace("\r", "");

    // Réduit les espaces multiples ("   " -> " ")
    while (nom.indexOf("  ") != -1) nom = nom.replace("  ", " ");

    // Limite longueur du pseudo
    if (nom.length() > MAX_PSEUDO) {
      nom = nom.substring(0, MAX_PSEUDO);
    }
    return nom;
  }

  // (Optionnel) Affiche le classement dans la console Processing (debug)
  void printScores() {
    println("=== TOP " + MAX + " ===");
    for (int i = 0; i < scores.size(); i++) {
      println((i+1) + ") " + scores.get(i).nom + " : " + scores.get(i).score);
    }
  }
}
