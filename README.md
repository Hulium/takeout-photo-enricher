
# Takeout Photo Enricher

**Takeout Photo Enricher** est un script PowerShell autonome permettant d'enrichir automatiquement les fichiers `.jpg` extraits depuis **Google Photos Takeout**, en injectant les métadonnées disponibles (date, GPS, description, type d'appareil...) directement dans les champs EXIF/XMP des images.

Il facilite ainsi l'archivage local, l'importation dans des galeries auto-hébergées comme [Immich](https://immich.app), ou l'organisation par métadonnées.

---

## ✅ Fonctionnalités

- Interface graphique pour choisir le dossier source
- Traitement récursif de tous les sous-dossiers Takeout
- Association automatique `.json` ⇄ `.jpg`
- Injection des champs :
  - `DateTimeOriginal`, `CreateDate` (prise de vue)
  - `GPSLatitude`, `GPSLongitude` (si disponibles)
  - `ImageDescription`, `XPComment` (si présent)
  - `XPKeywords` (type d'appareil)
  - `MetadataDate`, `ModifyDate` (timestamps secondaires)
- Création d’un nouveau dossier sur le bureau contenant les fichiers enrichis
- Rapport texte `rapport_traitement.txt`
- Fenêtre de résumé final (traités / ignorés / erreurs)

---

## 📁 Exemple de structure Takeout attendue

```
Google Photos/
├── Album1/
│   ├── IMG_001.jpg
│   ├── IMG_001.json
```

---

## 🔧 Prérequis

- Windows 10/11
- PowerShell 5.1+
- [ExifTool](https://exiftool.org/)

### Installation ExifTool

1. Télécharger "Windows Executable" sur [exiftool.org](https://exiftool.org/)
2. Extraire le fichier `exiftool(-k).exe`
3. Renommer-le `exiftool.exe`
4. Placer `exiftool.exe` dans le **même dossier** que `enricher.ps1`

---

## ▶️ Utilisation

### Méthode recommandée

1. Clic droit sur `enricher.ps1` → *Exécuter avec PowerShell*
2. Sélectionner le dossier racine de votre archive Google Photos Takeout
3. Le script :
   - Analyse les fichiers
   - Injecte les métadonnées
   - Crée un dossier `Photos_Enrichies_YYYYMMDD_HHMMSS` sur le bureau
   - Génère un rapport et un résumé visuel

### Si vous rencontrez une erreur liée à l’exécution de scripts PowerShell :

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\enricher.ps1
```

---

## 📤 Résultat

- Dossier de sortie avec structure préservée
- Fichiers `.jpg` enrichis avec métadonnées EXIF
- Rapport d’exécution clair
- Parfaitement compatible avec Immich ou d'autres outils d'organisation photo

---

## 🚫 Limitations

- Seuls les fichiers `.jpg` sont traités
- Les fichiers `.png` sont ignorés (pas de support standard EXIF)
- Les coordonnées GPS ne sont injectées que si elles sont valides (`≠ 0.0`)

---

## 📄 Licence

Ce projet est distribué sous licence **MIT**. Vous êtes libres de l’utiliser, le modifier et le redistribuer.
