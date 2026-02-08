# SOTASERV - CI SARL · Gestion HSE

Application mobile de **gestion HSE** (Hygiène, Sécurité, Environnement) pour SOTASERV - CI SARL. Elle permet de gérer les équipements de protection individuelle (EPI), le stock, les incidents et d’exporter les données en Excel, le tout en **mode hors ligne**.

---

## Fonctionnalités de l’application

### Connexion

- Accès par **code PIN à 4 chiffres** (par défaut : ).
- Saisie d’un **nom d’utilisateur** (enregistré et affiché dans l’application).
- Après connexion, accès à l’écran de bienvenue puis au tableau de bord.

### Tableau de bord

- **Indicateurs** : nombre d’EPI en stock critique et nombre total d’incidents.
- **Graphique** : évolution des incidents sur les 6 derniers mois (courbe).
- **Répartition par gravité** : répartition des incidents selon la gravité (1 à 5) sous forme de graphique.
- **Accès rapides** : liens directs vers la gestion du stock EPI et la déclaration d’incidents.

### Gestion du stock EPI

- **Liste des EPI** : code, désignation, seuil minimum d’alerte.
- **Stock calculé** : quantité actuelle déduite des mouvements d’entrée et de sortie.
- **Alertes** : mise en évidence des EPI dont le stock est en dessous du seuil minimum (affichage et notification locale).
- **Mouvements** : pour chaque EPI, enregistrement d’entrées ou de sorties de stock avec quantité et commentaire optionnel.
- **Création et modification** : ajout de nouveaux équipements et mise à jour des existants.

### Incidents / accidents

- **Déclaration** : enregistrement de la date, de la zone, du type (accident, incident, quasi-accident, etc.), de la gravité (1 à 5), de la cause, des actions correctives et du responsable.
- **Historique** : liste de tous les incidents avec possibilité de les modifier.
- **Affichage** : gravité et date visibles sur chaque fiche.

### Paramètres

- **À propos** : présentation de l’application (SOTASERV - CI SARL, version).
- **Modification du code** : changement du code PIN à 4 chiffres (via une fenêtre type « glass »).
- **Exporter en Excel** : génération d’un fichier .xlsx (EPI, mouvements, incidents) partageable (par messagerie, etc.).
- **Données locales** : indication du mode hors ligne (SQLite).
- **Notifications** : réglages des alertes liées au stock critique.

### Navigation

- **Barre de navigation en bas** : accès direct au Tableau de bord, au Stock, aux Incidents et aux Paramètres.
- Chaque section reste en mémoire lors du changement d’onglet (état conservé).

---

*SOTASERV - CI SARL — Gestion EPI et incidents*
