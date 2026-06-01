// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Vaktinde';

  @override
  String get nextPrayer => 'Prochaine Prière';

  @override
  String get hadithTitle => 'Hadith du Jour';

  @override
  String get readMore => 'Lire la suite...';

  @override
  String get share => 'Partager';

  @override
  String get close => 'Fermer';

  @override
  String get loading => 'Calcul des horaires...';

  @override
  String get error => 'Erreur';

  @override
  String get retry => 'Réessayer';

  @override
  String get noData => 'Aucune donnée.';

  @override
  String get imsak => 'Imsak';

  @override
  String get gunes => 'Lever du soleil';

  @override
  String get ogle => 'Dhuhr';

  @override
  String get ikindi => 'Asr';

  @override
  String get aksam => 'Maghrib';

  @override
  String get yatsi => 'Isha';

  @override
  String get exactAlarm => 'Lire à l\'heure exacte';

  @override
  String get exactAlarmSub => 'Envoie une notification.';

  @override
  String get silentNotif => 'Notification texte uniquement';

  @override
  String get silentNotifSub => 'Pas de son, juste une alerte.';

  @override
  String warningAlarm(String minute) {
    return 'Alerter $minute min avant';
  }

  @override
  String get warningAlarmSub => 'Son de notification court.';

  @override
  String get settings => 'Paramètres';

  @override
  String get changeLanguage => 'Changer de langue';

  @override
  String get waitingLocation => 'En attente de localisation...';

  @override
  String get noInternet =>
      'Pas d\'Internet et aucune donnée enregistrée trouvée.';

  @override
  String get gpsOff => 'GPS désactivé. Veuillez activer la localisation.';

  @override
  String get permissionDenied => 'Permission de localisation refusée.';

  @override
  String get locationError => 'Échec de l\'obtention de la localisation.';

  @override
  String get internetNeeded => 'Connexion Internet requise.';

  @override
  String get soundEzan => 'Adhan';

  @override
  String get soundBeep => 'Bip court';

  @override
  String get notifTitleTime => 'Heure de la Prière';

  @override
  String notifBodyTime(String vakit) {
    return 'C\'est l\'heure de la prière de $vakit.';
  }

  @override
  String get notifTitleUpcoming => 'La prière approche';

  @override
  String notifBodyUpcoming(String vakit, int minute) {
    return 'Il reste $minute minutes avant la prière de $vakit.';
  }

  @override
  String get navPrayer => 'Prières';

  @override
  String get navQibla => 'Qibla';

  @override
  String get navMenu => 'Menu';

  @override
  String get menuTitle => 'Paramètres';

  @override
  String get sectionLocation => 'LOCALISATION ET HORAIRES';

  @override
  String get changeLocation => 'Changer de Lieu';

  @override
  String get citySelect => 'Sélectionnez la ville';

  @override
  String get districtSelect => 'Sélectionnez le quartier';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get locationWarning =>
      'La sélection du district est importante pour des horaires précis.';

  @override
  String get menuNotifications => 'Autorisations de Notification';

  @override
  String get menuNotificationsSub => 'Vérifiez ici si aucun son n\'est émis.';

  @override
  String get menuTroubleshoot => 'Pas de notifications ?';

  @override
  String get menuTroubleshootSub =>
      'Ajustez les paramètres de batterie pour Samsung/Xiaomi.';

  @override
  String get sectionSupport => 'SUPPORT';

  @override
  String get shareApp => 'Partager avec des amis';

  @override
  String get rateApp => 'Évaluez-nous';

  @override
  String get contactUs => 'Contact & Signaler un bug';

  @override
  String shareText(String link) {
    return 'J\'ai trouvé une excellente application pour les heures de prière ! Téléchargez : $link';
  }

  @override
  String get batteryDialogTitle => 'Solution au problème de notification';

  @override
  String get batteryDialogBody =>
      'Votre téléphone ferme peut-être l\'application pour économiser la batterie. Pour éviter cela :\n\n1. Ouvrez l\'écran des applications récentes.\n2. Appuyez et maintenez l\'application \'Vaktinde\' ou cliquez sur son logo.\n3. Verrouillez-la avec l\'icône de cadenas 🔒.\n\nAllez également dans Paramètres > Applications > Vaktinde > Batterie > Sans restriction.';

  @override
  String get okUnderstood => 'D\'accord, compris';

  @override
  String get religiousDaysTitle => 'Jours Religieux';

  @override
  String errorOccurred(String error) {
    return 'Une erreur est survenue : $error';
  }

  @override
  String get noDataFound => 'Aucune donnée trouvée.';

  @override
  String noDataForYear(int year) {
    return 'Aucune donnée trouvée pour l\'année $year.';
  }

  @override
  String religiousDaysListTitle(int year) {
    return 'Liste des jours religieux $year';
  }

  @override
  String get missedPrayersTitle => 'Prières Manquées';

  @override
  String get missedPrayersInfo =>
      'Vous pouvez noter vos prières manquées ici et les déduire au fur et à mesure que vous les accomplissez.\n(Cliquez sur le numéro pour entrer manuellement)';

  @override
  String editMissedTitle(String title) {
    return 'Modifier la prière $title';
  }

  @override
  String get missedCountLabel => 'Nombre manqué';

  @override
  String get missedCountHint => 'Ex : 150';

  @override
  String get sabah => 'Fajr';

  @override
  String get vitir => 'Witr';

  @override
  String get oruc => 'Jeûne';

  @override
  String timeLeftFor(String vakit) {
    return 'Temps restant pour $vakit';
  }

  @override
  String get tomorrow => '(Demain)';

  @override
  String get fridayMessagesTitle => 'Messages du Vendredi';

  @override
  String get esmaulHusnaTitle => 'Les Noms d\'Allah';

  @override
  String get closeCaps => 'FERMER';

  @override
  String get zakatTitle => 'Calculer la Zakat';

  @override
  String get zakatCalculatorTitle => 'Calculateur Intelligent Zakat';

  @override
  String get liveRatesLoading => 'Récupération des taux actuels...';

  @override
  String get liveRatesInfo =>
      'Vous pouvez modifier manuellement les taux récupérés automatiquement.';

  @override
  String get sectionGold => 'Actifs en Or';

  @override
  String get goldType => 'Type d\'Or';

  @override
  String get goldAmount => 'Quantité / Gramme';

  @override
  String get goldUnitPrice => 'Prix Unitaire';

  @override
  String get sectionCurrency => 'Actifs en Devises';

  @override
  String get currencyType => 'Type de Devise';

  @override
  String get currencyAmount => 'Montant';

  @override
  String get currencyRate => 'Taux Actuel';

  @override
  String get sectionCashDebt => 'Espèces et Dettes';

  @override
  String get cashAmount => 'Espèces en Main et Banque';

  @override
  String get debtAmount => 'Total des Dettes (À déduire)';

  @override
  String get calculateButton => 'CALCULER';

  @override
  String get zakatResultTitle => 'Zakat à Payer';

  @override
  String get netAssets => 'Actif Net :';

  @override
  String get qiblaTitle => 'Boussole Qibla';

  @override
  String get locationServiceOff =>
      'Service de localisation désactivé. Veuillez l\'activer.';

  @override
  String get locationPermissionDenied => 'Permission de localisation refusée.';

  @override
  String get locationPermissionForever =>
      'La permission de localisation est bloquée en permanence. Vous devez l\'activer dans les paramètres.';

  @override
  String compassError(String error) {
    return 'Erreur de capteur : $error';
  }

  @override
  String get noCompass => 'Pas de boussole sur l\'appareil.';

  @override
  String get qiblaFound => 'VOUS AVEZ TROUVÉ LA QIBLA !';

  @override
  String qiblaAngle(String angle) {
    return 'Angle de la Qibla : $angle°';
  }

  @override
  String get keepAwayMetal => 'Tenir éloigné des objets métalliques.';

  @override
  String get goldGram => 'Gramme d\'Or (24k)';

  @override
  String get goldQuarter => 'Quart d\'Or';

  @override
  String get goldFull => 'Or Entier';

  @override
  String get typeOther => 'Autre (Manuel)';

  @override
  String get usd => 'Dollar Américain (USD)';

  @override
  String get eur => 'Euro (EUR)';

  @override
  String get gbp => 'Livre Sterling (GBP)';

  @override
  String get sectionAppearance => 'APPARENCE ET LANGUE';

  @override
  String get appearanceSettings => 'Paramètres d\'Apparence';

  @override
  String get appearanceSub => 'Thème et Arrière-plan';

  @override
  String get themeMode => 'Mode Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get bgImage => 'Image de Fond';

  @override
  String get bgDefault => 'Par Défaut';

  @override
  String get bgMosque => 'Mosquée';

  @override
  String get bgKaaba => 'Kaaba';

  @override
  String get bgQuran => 'Coran';

  @override
  String get none => 'Aucun';

  @override
  String get zakatEligible => 'Zakat Obligatoire';

  @override
  String get zakatNotEligible => 'Zakat Non Requise';

  @override
  String get nisabLimit => 'Limite de Nisab (80,18 g d\'or)';

  @override
  String get belowNisabMessage =>
      'La Zakat n\'est pas obligatoire car vos actifs nets sont en dessous de la quantité de Nisab (seuil de richesse).';

  @override
  String get searchLocationTitle => 'Rechercher un Lieu (Monde Entier)';

  @override
  String get searchLocationHint => 'Ville ou Pays (Ex: Paris)';

  @override
  String get searchInitial => 'Tapez le lieu que vous souhaitez rechercher...';

  @override
  String get searchNotFound => 'Lieu introuvable.';

  @override
  String get searchError => 'Aucun résultat trouvé. Veuillez réessayer.';

  @override
  String locationSelected(String city) {
    return '$city sélectionné';
  }

  @override
  String channelSoundPrefix(String soundName) {
    return 'Son : $soundName';
  }

  @override
  String get channelSilentPrayers => 'Notifications de Prière Silencieuses';

  @override
  String get tickerEzan => 'Heure de la Prière';

  @override
  String get stickyChannelName => 'Compteur Permanent';

  @override
  String get stickyChannelDesc => 'Affiche le temps restant jusqu\'à la prière';

  @override
  String get timeLeftTo => 'Temps restant : ';

  @override
  String get locationFallbackMessage =>
      'Impossible d\'obtenir la position, utilisation de la valeur par défaut.';

  @override
  String get fetchingLocation => 'Obtention de la localisation...';

  @override
  String get directionNorth => 'N';

  @override
  String get directionSouth => 'S';

  @override
  String get directionEast => 'E';

  @override
  String get directionWest => 'O';

  @override
  String get calibrationInstruction => '(Dessinez un \'8\' pour calibrer)';

  @override
  String get zakatDescription =>
      'Calculez votre zakat détaillée selon les fatwas de la Diyanet et les taux de marché actuels.';

  @override
  String get cashAndCurrencyTitle => 'Espèces et Devises';

  @override
  String get cashTurkishLira => 'Livre Turque en espèces (TL)';

  @override
  String get goldAndSilverTitle => 'Or et Argent';

  @override
  String get silverGram => 'Argent (Gramme)';

  @override
  String get unitPrice => 'Prix Unitaire';

  @override
  String get commercialGoodsTitle => 'Marchandises Commerciales';

  @override
  String get commercialEvalCurrency => 'Devise d\'Évaluation';

  @override
  String get commercialGoodsValue => 'Valeur des Marchandises';

  @override
  String get exchangeRateValue => 'Valeur du Taux de Change';

  @override
  String get receivablesTitle => 'Créances (Récupérables)';

  @override
  String get receivableType => 'Type de Créance (Devise, Or)';

  @override
  String get amountOrCount => 'Montant / Quantité';

  @override
  String get otherAssetsTitle => 'Autres Actifs';

  @override
  String get assetType => 'Type d\'Actif';

  @override
  String get currencyLabel => 'Devise';

  @override
  String get valueOrAmount => 'Valeur / Montant';

  @override
  String get agriProductsTitle => 'Produits Agricoles (Oshr)';

  @override
  String get agriDiyanetNote =>
      'Comme le montant du nisab n\'est pas requis pour les produits agricoles, le montant déclaré est directement ajouté à la zakat.';

  @override
  String get harvestedProductValue => 'Valeur du Produit Récolté';

  @override
  String get irrigationMethod => 'Méthode d\'Irrigation';

  @override
  String get debtsTitle => 'Dettes (À Déduire)';

  @override
  String get debtType => 'Type de Dette';

  @override
  String get zakatAgriIncluded => 'Zakat Agricole (Oshr) Inclus';

  @override
  String get assetCheck => 'Chèque';

  @override
  String get assetBond => 'Billet à Ordre';

  @override
  String get assetSukuk => 'Sukuk';

  @override
  String get assetLeaseCert => 'Certificat de Location';

  @override
  String get assetStock => 'Action';

  @override
  String get agriSoil => 'Produit Agricole (Avec Terre)';

  @override
  String get agriSoilless => 'Produit Agricole (Sans Terre)';

  @override
  String get agriRateNoCost => 'Sans Frais (Pluie/Rivière) - 10%';

  @override
  String get agriRateCostly => 'Avec Frais (Moteur/Transport) - 5%';

  @override
  String get toImsak => 'Avant Fajr';

  @override
  String get toGunes => 'Avant Lever du soleil';

  @override
  String get toOgle => 'Avant Dhuhr';

  @override
  String get toIkindi => 'Avant Asr';

  @override
  String get toAksam => 'Avant Maghrib';

  @override
  String get toYatsi => 'Avant Isha';

  @override
  String get lowAccuracyWarning =>
      'Étalonnage faible. Veuillez dessiner un \'8\' en l\'air avec votre téléphone.';

  @override
  String get qiblaDirection => 'Direction Qibla';

  @override
  String get zikirmatikTitle => 'Dhikr Counter';

  @override
  String get dhikrSubhanallah => 'Subhanallah';

  @override
  String get dhikrElhamdulillah => 'Alhamdulillah';

  @override
  String get dhikrAllahuEkber => 'Allahu Akbar';

  @override
  String get dhikrKalima => 'Kalimat at-Tawhid';

  @override
  String get dhikrSalavat => 'Salawat';

  @override
  String get targetReached => 'Objectif Atteint !';

  @override
  String get resetCounter => 'Réinitialiser';

  @override
  String targetCount(int target) {
    return 'Objectif : $target';
  }

  @override
  String get setTarget => 'Fixer un Objectif';

  @override
  String get dhikrOther => 'Autre (Dhikr Personnalisé)';

  @override
  String get customDhikrTitle => 'Ajouter un Dhikr Personnalisé';

  @override
  String get customDhikrHint => 'Tapez votre dhikr';

  @override
  String get zikirSettings => 'Paramètres';

  @override
  String get vibration => 'Vibration';

  @override
  String get sound => 'Effet Sonore';

  @override
  String get keepAwake => 'Garder l\'écran allumé';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeModern => 'Bouton Moderne';

  @override
  String get themeClassic => 'Chapelet Classique';

  @override
  String get introTitle1 => 'Bienvenue sur Vaktinde';

  @override
  String get introDesc1 =>
      'Suivez facilement les heures de prière, vos dhikrs et les jours religieux avec une interface moderne et élégante.';

  @override
  String get introTitle2 => 'Notifications Intelligentes';

  @override
  String get introDesc2 =>
      'Soyez alerté avec le son de notification de votre choix aux heures de prière. Ne manquez jamais vos prières.';

  @override
  String get introTitle3 => 'Outils Avancés';

  @override
  String get introDesc3 =>
      'Renforcez votre spiritualité avec des outils tels que le compteur de Dhikr animé, les prières manquées et le calculateur de Zakat.';

  @override
  String get introSkip => 'Passer';

  @override
  String get introNext => 'Suivant';

  @override
  String get introStart => 'Commencer';

  @override
  String get dhikrListTitle => 'Liste de Dhikr';

  @override
  String get addCustomDhikr => 'Ajouter un Dhikr personnalisé';

  @override
  String get customDhikrAdded => 'Dhikr ajouté avec succès.';

  @override
  String get customDhikrLimit =>
      'Vous pouvez ajouter jusqu\'à 20 dhikrs personnalisés !';

  @override
  String get deleteDhikr => 'Supprimer';

  @override
  String get statisticsTitle => 'Statistiques';

  @override
  String get monthly => 'Mensuel';

  @override
  String get yearly => 'Annuel';

  @override
  String get totalDhikr => 'Total des Dhikrs';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get statsEmpty => 'Aucune donnée de dhikr pour le moment.';

  @override
  String get dhikrEstagfirullah => 'Astaghfirullah';

  @override
  String get dhikrLaHavle => 'La Hawla wa la Quwwata';

  @override
  String get dhikrHasbunallah => 'Hasbunallah';

  @override
  String get dhikrSubhanallahi => 'Subhanallahi wa bihamdihi';

  @override
  String get dhikrYunus => 'Prière de Prophète Yunus';

  @override
  String get dhikrYaAllah => 'Ya Allah';

  @override
  String get dhikrYaRahman => 'Ya Rahman';

  @override
  String get dhikrYaRahim => 'Ya Rahim';

  @override
  String get dhikrYaSafi => 'Ya Shafi';

  @override
  String get dhikrYaRezzak => 'Ya Razzaq';

  @override
  String get dhikrYaFettah => 'Ya Fattah';

  @override
  String get mainDhikrs => 'Dhikrs Principaux';

  @override
  String get esmaulHusnaTab => 'Les Noms d\'Allah';

  @override
  String get qiblaCalibration =>
      'Dessinez un \'8\' dans les airs avec votre téléphone pour calibrer la boussole.';
}
