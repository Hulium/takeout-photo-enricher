Add-Type -AssemblyName System.Windows.Forms

# GUI : Sélection du dossier
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "Selectionnez le dossier Google Takeout (Photos)"
$null = $folderBrowser.ShowDialog()
$sourceFolder = $folderBrowser.SelectedPath
if (-not $sourceFolder) {
    [System.Windows.Forms.MessageBox]::Show("Aucun dossier selectionne. Le script est interrompu.","Fusionneur EXIF",0,[System.Windows.Forms.MessageBoxIcon]::Warning)
    exit 1
}

# Exiftool localisé dans le même dossier que le script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$exiftool = Join-Path $scriptDir "exiftool.exe"
if (-not (Test-Path $exiftool)) {
    [System.Windows.Forms.MessageBox]::Show("ExifTool n'est pas trouve dans le dossier du script.","Erreur",0,[System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}

# Création du dossier de sortie
$desktopPath = [Environment]::GetFolderPath("Desktop")
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFolder = Join-Path $desktopPath "Photos_Enrichies_$timestamp"
New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null

# Rapport
$reportPath = Join-Path $outputFolder "rapport_traitement.txt"
New-Item -ItemType File -Path $reportPath -Force | Out-Null

# Comptage
$jsonFiles = Get-ChildItem -Path $sourceFolder -Recurse -Filter *.json
$total = $jsonFiles.Count
$index = 0
$traites = 0
$ignores = 0
$erreurs = 0

foreach ($json in $jsonFiles) {
    $index++
    $jsonFile = $json.FullName
    $photoFile = $jsonFile -replace '\.json$', ''

    Write-Progress -Activity "Traitement des photos" `
                   -Status "Fichier $index sur $total : $($json.Name)" `
                   -PercentComplete (($index / $total) * 100)

    if (-not (Test-Path $photoFile)) {
        Add-Content $reportPath "Image manquante : $jsonFile"
        $erreurs++
        continue
    }

    if ((Get-Item $photoFile).Extension.ToLower() -ne ".jpg") {
        Add-Content $reportPath "Fichier ignore (non-JPG) : $photoFile"
        $ignores++
        continue
    }

    try {
        $data = Get-Content $jsonFile | ConvertFrom-Json

        # Date de prise de vue
        $tsTaken = [int64]$data.photoTakenTime.timestamp
        $datetime = (Get-Date -Date ([DateTimeOffset]::FromUnixTimeSeconds($tsTaken).DateTime) -Format "yyyy:MM:dd HH:mm:ss")

        # Création et modification (optionnelles)
        $args = @(
            "-DateTimeOriginal=$datetime",
            "-CreateDate=$datetime"
        )

        if ($data.creationTime.timestamp) {
            $tsCreation = [int64]$data.creationTime.timestamp
            $args += "-XMP:MetadataDate=" + (Get-Date -Date ([DateTimeOffset]::FromUnixTimeSeconds($tsCreation).DateTime) -Format "yyyy:MM:dd HH:mm:ss")
        }
        if ($data.photoLastModifiedTime.timestamp) {
            $tsModified = [int64]$data.photoLastModifiedTime.timestamp
            $args += "-XMP:ModifyDate=" + (Get-Date -Date ([DateTimeOffset]::FromUnixTimeSeconds($tsModified).DateTime) -Format "yyyy:MM:dd HH:mm:ss")
        }

        # GPS
        $lat = $data.geoData.latitude
        $lon = $data.geoData.longitude
        if ($lat -ne 0 -or $lon -ne 0) {
            $latRef = if ($lat -lt 0) { "S" } else { "N" }
            $lonRef = if ($lon -lt 0) { "W" } else { "E" }
            $args += "-GPSLatitude=$lat"
            $args += "-GPSLatitudeRef=$latRef"
            $args += "-GPSLongitude=$lon"
            $args += "-GPSLongitudeRef=$lonRef"
        }

        # Description
        if ($data.description -ne "") {
            $args += "-ImageDescription=$($data.description)"
            $args += "-XPComment=$($data.description)"
        }

        # Type d'appareil
        $deviceType = $data.googlePhotosOrigin.mobileUpload.deviceType
        if ($deviceType) {
            $args += "-XPKeywords=$deviceType"
        }

        # Préparation du fichier de destination
        $relativePath = $json.DirectoryName.Substring($sourceFolder.Length).TrimStart('\')
        $destSubFolder = Join-Path $outputFolder $relativePath
        New-Item -ItemType Directory -Path $destSubFolder -Force | Out-Null

        $destFile = Join-Path $destSubFolder ([System.IO.Path]::GetFileName($photoFile))
        Copy-Item -Path $photoFile -Destination $destFile -Force

        # Appel à exiftool avec les arguments construits dynamiquement
        $args += "-overwrite_original"
        $args += $destFile
        & $exiftool @args | Out-Null

        Add-Content $reportPath "Fichier traite : $destFile"
        $traites++

    } catch {
        Add-Content $reportPath "Erreur sur $jsonFile : $($_.Exception.Message)"
        $erreurs++
    }
}

Write-Progress -Activity "Traitement termine" -Completed

# Résumé dans MessageBox
$resume = "Traitement termine.`n`n" +
          "Total de fichiers JSON traites : $total`n" +
          "Photos enrichies avec succes   : $traites`n" +
          "Fichiers ignores               : $ignores`n" +
          "Erreurs detectees              : $erreurs`n`n" +
          "Dossier de sortie : $outputFolder`n" +
          "Rapport : $reportPath"

[System.Windows.Forms.MessageBox]::Show($resume, "Resultat du traitement", 0, [System.Windows.Forms.MessageBoxIcon]::Information)
