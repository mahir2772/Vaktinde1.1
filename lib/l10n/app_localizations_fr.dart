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
  String get showcaseLanguage =>
      'Vous pouvez changer la langue de l\'application ici.';

  @override
  String get showcaseStory => 'Lisez ici le verset et le hadith du jour.';

  @override
  String get showcaseAlarms =>
      'Réglez ici les alarmes d\'adhan et de rappel pour chaque prière.';

  @override
  String get showcaseQibla =>
      'Trouvez la direction de la Qibla avec la boussole.';

  @override
  String get showcaseZikir => 'Comptez vos dhikr ici.';

  @override
  String get refreshLocation => 'Actualiser la position';

  @override
  String get navTools => 'Outils';

  @override
  String get hadithNotFound => 'Texte du hadith introuvable.';

  @override
  String get timesLoadError =>
      'Les horaires de prière n\'ont pas pu être chargés. Veuillez réessayer.';

  @override
  String get sunriseNotPrayer => 'Lever du soleil, pas une prière';

  @override
  String get currentPrayer => 'Prière en cours';

  @override
  String get textCopied => 'Texte copié';

  @override
  String get updateDownloaded => 'Une nouvelle version a été téléchargée.';

  @override
  String get restartAction => 'Redémarrer';

  @override
  String get qiblaTurnRight => 'Tournez à droite';

  @override
  String get qiblaTurnSlightRight => 'Tournez légèrement à droite';

  @override
  String get qiblaTurnLeft => 'Tournez à gauche';

  @override
  String get qiblaTurnSlightLeft => 'Tournez légèrement à gauche';

  @override
  String phoneHeading(String deg) {
    return 'Orientation du téléphone : $deg°';
  }

  @override
  String get usingSavedLocation => 'Position enregistrée utilisée.';

  @override
  String exampleHint(int n) {
    return 'Ex. : $n';
  }

  @override
  String get noCustomDhikr =>
      'Vous n\'avez pas encore ajouté de dhikr personnalisé.';

  @override
  String get messagesShuffled => 'Messages mélangés';

  @override
  String get shuffle => 'Mélanger';

  @override
  String get copy => 'Copier';

  @override
  String get messageCopied => 'Message copié';

  @override
  String versionLabel(String v) {
    return 'Version $v';
  }

  @override
  String get supportMailSubject => 'Vaktinde - Assistance';

  @override
  String get madeBy => 'Fait avec ❤️ par mmdigital';

  @override
  String get permissionPrimingTitle => 'Ne manquez aucune prière';

  @override
  String get permissionPrimingBody =>
      'Nous avons besoin de l\'autorisation des notifications pour les alertes d\'adhan et de la localisation pour calculer les horaires là où vous êtes.';

  @override
  String get continueAction => 'Continuer';

  @override
  String get ok => 'OK';

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
  String get loading => 'Calcul des Horaires...';

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
  String get exactAlarm => 'Notifier à l\'Heure Exacte';

  @override
  String get exactAlarmSub => 'Envoie une notification.';

  @override
  String get silentNotif => 'Notification Textuelle Uniquement';

  @override
  String get silentNotifSub =>
      'Pas d\'Adhan/Son, uniquement une alerte visuelle.';

  @override
  String warningAlarm(String minute) {
    return 'Avertir $minute min Avant';
  }

  @override
  String get warningAlarmSub => 'Son de notification court.';

  @override
  String get settings => 'Paramètres';

  @override
  String get changeLanguage => 'Changer de Langue';

  @override
  String get waitingLocation => 'En attente de la position...';

  @override
  String get noInternet =>
      'Pas de connexion internet et aucune donnée enregistrée trouvée.';

  @override
  String get gpsOff =>
      'Le GPS est désactivé. Veuillez activer la localisation.';

  @override
  String get permissionDenied => 'Permission de localisation refusée.';

  @override
  String get locationError => 'Impossible d\'obtenir la localisation.';

  @override
  String get internetNeeded => 'Une connexion internet est requise.';

  @override
  String get soundEzan => 'Adhan';

  @override
  String get soundBeep => 'Bip Court';

  @override
  String get notifTitleTime => 'Heure de Prière';

  @override
  String notifBodyTime(String vakit) {
    return 'C\'est l\'heure de $vakit.';
  }

  @override
  String get notifTitleUpcoming => 'L\'Heure Approche';

  @override
  String notifBodyUpcoming(String vakit, int minute) {
    return 'Il reste $minute minutes avant $vakit.';
  }

  @override
  String get navPrayer => 'Accueil';

  @override
  String get navQibla => 'Qibla';

  @override
  String get navMenu => 'Menu';

  @override
  String get menuTitle => 'Paramètres';

  @override
  String get sectionLocation => 'POSITION & HORAIRES';

  @override
  String get changeLocation => 'Changer la Position';

  @override
  String get citySelect => 'Sélectionner la Ville';

  @override
  String get districtSelect => 'Sélectionner le Quartier';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get locationWarning =>
      'Le choix du quartier est important pour des horaires précis.';

  @override
  String get menuNotifications => 'Permissions de Notifications';

  @override
  String get menuNotificationsSub =>
      'Vérifiez ici si vous n\'entendez pas les sons.';

  @override
  String get menuTroubleshoot => 'Vous ne recevez pas de notifications ?';

  @override
  String get menuTroubleshootSub => 'Réglez la batterie pour Samsung/Xiaomi.';

  @override
  String get timeAdjustTitle => 'Ajustement des horaires';

  @override
  String get timeAdjustSub => 'Corriger les horaires à la minute près';

  @override
  String get timeAdjustInfo =>
      'Les horaires sont calculés pour votre position selon la méthode Diyanet. S\'ils diffèrent légèrement de ceux de votre mosquée, vous pouvez avancer ou retarder chaque horaire de quelques minutes. Le réglage s\'applique à l\'écran d\'accueil, aux widgets et aux notifications de prière.';

  @override
  String get timeAdjustReset => 'Réinitialiser';

  @override
  String timeAdjustMinutes(String value) {
    return '$value min';
  }

  @override
  String get timeAdjustSaved => 'Horaires mis à jour';

  @override
  String get trackerTitle => 'Suivi des prières';

  @override
  String get trackerToday => 'Aujourd\'hui';

  @override
  String get trackerYesterday => 'Hier';

  @override
  String get trackerPrayedAction => 'J\'ai prié';

  @override
  String get trackerLast7Days => '7 derniers jours';

  @override
  String get trackerCompletion => 'Taux sur 30 jours';

  @override
  String get trackerStreak => 'Série';

  @override
  String trackerStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
      zero: '0 jour',
    );
    return '$_temp0';
  }

  @override
  String get trackerNotYet =>
      'L\'heure de cette prière n\'est pas encore arrivée.';

  @override
  String get trackerKazaButton => 'Ajouter les prières non faites au qada';

  @override
  String get trackerKazaInfo =>
      'Les prières non cochées des 30 derniers jours (depuis le début du suivi) sont ajoutées aux compteurs de qada. Chaque prière n\'est ajoutée qu\'une fois.';

  @override
  String trackerKazaConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count prières non cochées seront ajoutées aux compteurs de qada. Continuer ?',
      one:
          '1 prière non cochée sera ajoutée aux compteurs de qada. Continuer ?',
    );
    return '$_temp0';
  }

  @override
  String get trackerKazaAdd => 'Ajouter';

  @override
  String trackerKazaDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prières ajoutées au qada.',
      one: '1 prière ajoutée au qada.',
    );
    return '$_temp0';
  }

  @override
  String get trackerKazaNone => 'Aucune prière à ajouter au qada.';

  @override
  String get trackerKazaLocked =>
      'Cette prière a été ajoutée au qada. Une fois rattrapée, diminuez-la dans le suivi des prières manquées.';

  @override
  String get trackerLegendPrayed => 'Accomplie';

  @override
  String get trackerLegendKaza => 'Ajoutée au qada';

  @override
  String kerahatActive(String range) {
    return 'Temps makruh en cours : $range';
  }

  @override
  String kerahatUpcoming(String range) {
    return 'Temps makruh bientôt : $range';
  }

  @override
  String get endReminderTitle => 'Rappel avant la fin de la prière';

  @override
  String get endReminderSub =>
      'Vous avertit avant la fin du temps d\'une prière non cochée.';

  @override
  String get endReminderNotifTitle => 'Fin du temps de prière';

  @override
  String endReminderNotifBody(String vakit, int minute) {
    return 'Il reste $minute minutes avant la fin du temps de $vakit.';
  }

  @override
  String get endReminderChannel => 'Rappels de fin de prière';

  @override
  String get ramadanIftarTitle => 'Heure de l\'iftar';

  @override
  String ramadanIftarBody(String vakit) {
    return 'L\'heure de $vakit est arrivée. Bon iftar !';
  }

  @override
  String get ramadanImsakTitle => 'Heure de l\'imsak';

  @override
  String get ramadanImsakBody => 'Le temps du suhoor est terminé. Bon jeûne !';

  @override
  String get sectionSupport => 'SUPPORT';

  @override
  String get shareApp => 'Partager avec un Ami';

  @override
  String get rateApp => 'Évaluez-nous';

  @override
  String get contactUs => 'Contact & Signaler un Bug';

  @override
  String shareText(String link) {
    return 'J\'ai trouvé une super application d\'heures de prière ! Téléchargez-la ici : $link';
  }

  @override
  String get batteryDialogTitle => 'Solution au Problème de Notification';

  @override
  String get batteryDialogBody =>
      'Votre téléphone peut fermer l\'application pour économiser la batterie. Pour éviter cela :\n\n1. Ouvrez l\'écran des applications récentes.\n2. Appuyez longuement sur l\'application \'Vaktinde\' ou sur son logo.\n3. Appuyez sur l\'icône Cadenas 🔒 pour la verrouiller.\n\nAllez également dans Paramètres > Applications > Vaktinde > Batterie > Sélectionnez \'Non restreint\'.';

  @override
  String get okUnderstood => 'OK, J\'ai Compris';

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
    return 'Liste des Jours Religieux pour $year';
  }

  @override
  String get missedPrayersTitle => 'Suivi des Prières Manquées';

  @override
  String get missedPrayersInfo =>
      'Notez ici vos prières manquées et déduisez-les au fur et à mesure.\n(Appuyez sur le nombre pour une saisie manuelle)';

  @override
  String editMissedTitle(String title) {
    return 'Modifier la Prière de $title Manquée';
  }

  @override
  String get missedCountLabel => 'Nombre Manqué';

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
    return 'Temps Restant pour $vakit';
  }

  @override
  String get tomorrow => '(Demain)';

  @override
  String get fridayMessagesTitle => 'Messages du Vendredi';

  @override
  String get esmaulHusnaTitle => 'Noms d\'Allah';

  @override
  String get closeCaps => 'FERMER';

  @override
  String get zakatTitle => 'Calculatrice de Zakat';

  @override
  String get zakatCalculatorTitle => 'Calculatrice Intelligente de Zakat';

  @override
  String get liveRatesLoading => 'Récupération des taux de change...';

  @override
  String get liveRatesInfo =>
      'Vous pouvez modifier manuellement les taux récupérés automatiquement.';

  @override
  String get sectionGold => 'Avoirs en Or';

  @override
  String get goldType => 'Type d\'Or';

  @override
  String get goldAmount => 'Quantité / Grammes';

  @override
  String get goldUnitPrice => 'Prix Unitaire';

  @override
  String get sectionCurrency => 'Avoirs en Devises';

  @override
  String get currencyType => 'Type de Devise';

  @override
  String get currencyAmount => 'Montant';

  @override
  String get currencyRate => 'Taux Actuel';

  @override
  String get sectionCashDebt => 'Espèces & Dettes';

  @override
  String get cashAmount => 'Espèces en Main & en Banque';

  @override
  String get debtAmount => 'Total des Dettes (À déduire)';

  @override
  String get calculateButton => 'CALCULER';

  @override
  String get zakatResultTitle => 'Votre Zakat à Payer';

  @override
  String get netAssets => 'Actifs Nets :';

  @override
  String get qiblaTitle => 'Boussole Qibla';

  @override
  String get locationServiceOff =>
      'Service de localisation désactivé. Veuillez l\'activer.';

  @override
  String get locationPermissionDenied => 'Permission de localisation refusée.';

  @override
  String get locationPermissionForever =>
      'La permission de localisation est bloquée définitivement. Veuillez l\'activer dans les paramètres.';

  @override
  String compassError(String error) {
    return 'Erreur du capteur : $error';
  }

  @override
  String get noCompass => 'Pas de boussole sur cet appareil.';

  @override
  String get qiblaFound => 'VOUS AVEZ TROUVÉ LA QIBLA !';

  @override
  String qiblaAngle(String angle) {
    return 'Angle de la Qibla : $angle°';
  }

  @override
  String get keepAwayMetal => 'Éloignez des objets métalliques.';

  @override
  String get goldGram => 'Gramme d\'Or (24 Carats)';

  @override
  String get goldQuarter => 'Quart d\'Or';

  @override
  String get goldFull => 'Or Complet';

  @override
  String get typeOther => 'Autre (Manuel)';

  @override
  String get usd => 'Dollar US (USD)';

  @override
  String get eur => 'Euro (EUR)';

  @override
  String get gbp => 'Livre Sterling (GBP)';

  @override
  String get sectionAppearance => 'APPARENCE & LANGUE';

  @override
  String get appearanceSettings => 'Paramètres d\'Apparence';

  @override
  String get appearanceSub => 'Thème et Arrière-plan';

  @override
  String get themeMode => 'Mode de Thème';

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
  String get zakatEligible => 'La Zakat est Requise';

  @override
  String get zakatNotEligible => 'La Zakat N\'est Pas Requise';

  @override
  String get nisabLimit => 'Limite du Nissab (80,18 g d\'Or)';

  @override
  String get belowNisabMessage =>
      'Vos actifs nets étant inférieurs au montant du Nissab, la Zakat n\'est pas obligatoire.';

  @override
  String get searchLocationTitle => 'Rechercher une Position (Mondial)';

  @override
  String get searchLocationHint => 'Ville ou Pays (Ex : Paris)';

  @override
  String get searchInitial => 'Tapez le lieu que vous souhaitez rechercher...';

  @override
  String get searchNotFound => 'Position introuvable.';

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
  String get channelSilentPrayers => 'Notifications Silencieuses de l\'Adhan';

  @override
  String get tickerEzan => 'Heure de Prière';

  @override
  String get stickyChannelName => 'Compteur Persistant';

  @override
  String get stickyChannelDesc => 'Affiche le temps restant';

  @override
  String get timeLeftTo => 'Temps Restant Jusqu\'à la Fin : ';

  @override
  String get locationFallbackMessage =>
      'Impossible d\'obtenir la position, valeurs par défaut utilisées.';

  @override
  String get fetchingLocation => 'Obtention de la position...';

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
      'Calculez votre Zakat en détail selon les directives religieuses et les taux actuels du marché.';

  @override
  String get cashAndCurrencyTitle => 'Espèces et Devises';

  @override
  String get cashTurkishLira => 'Espèces (Monnaie Locale)';

  @override
  String get goldAndSilverTitle => 'Or et Argent';

  @override
  String get silverGram => 'Argent (Grammes)';

  @override
  String get unitPrice => 'Prix Unitaire';

  @override
  String get commercialGoodsTitle => 'Biens Commerciaux';

  @override
  String get commercialEvalCurrency => 'Devise d\'Évaluation';

  @override
  String get commercialGoodsValue => 'Valeur des Biens';

  @override
  String get exchangeRateValue => 'Taux de Change';

  @override
  String get receivablesTitle => 'Créances (Recouvrables)';

  @override
  String get receivableType => 'Type (Espèces, Devise, Or)';

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
  String get agriProductsTitle => 'Produits Agricoles (Ouchr)';

  @override
  String get agriDiyanetNote =>
      'Comme le Nissab n\'est pas requis pour les produits agricoles, le montant déclaré est directement ajouté à votre total de Zakat.';

  @override
  String get harvestedProductValue => 'Valeur du Produit Récolté';

  @override
  String get irrigationMethod => 'Méthode d\'Irrigation';

  @override
  String get debtsTitle => 'Dettes (À déduire)';

  @override
  String get debtType => 'Type de Dette (Espèces, Devise, Or)';

  @override
  String get zakatAgriIncluded =>
      'Incluant la Zakat des Produits Agricoles (Ouchr)';

  @override
  String get assetCheck => 'Chèque';

  @override
  String get assetBond => 'Billet à Ordre';

  @override
  String get assetSukuk => 'Sukuk';

  @override
  String get assetLeaseCert => 'Certificat de Location';

  @override
  String get assetStock => 'Actions';

  @override
  String get agriSoil => 'Agriculture (En Terre)';

  @override
  String get agriSoilless => 'Agriculture (Hors-Sol)';

  @override
  String get agriRateNoCost => 'Sans Frais (Pluie/Rivière) - 10%';

  @override
  String get agriRateCostly => 'Avec Frais (Moteur/Transport) - 5%';

  @override
  String get toImsak => 'Vers Imsak';

  @override
  String get toGunes => 'Vers le Lever du Soleil';

  @override
  String get toOgle => 'Vers Dhuhr';

  @override
  String get toIkindi => 'Vers Asr';

  @override
  String get toAksam => 'Vers Maghrib';

  @override
  String get toYatsi => 'Vers Isha';

  @override
  String get lowAccuracyWarning =>
      'L\'étalonnage de la boussole est faible. Veuillez dessiner un \'8\' en l\'air avec le téléphone.';

  @override
  String get qiblaDirection => 'Direction de la Qibla';

  @override
  String get zikirmatikTitle => 'Compteur de Dhikr';

  @override
  String get dhikrSubhanallah => 'Soubhanallah';

  @override
  String get dhikrElhamdulillah => 'Alhamdulillah';

  @override
  String get dhikrAllahuEkber => 'Allahu Akbar';

  @override
  String get dhikrKalima => 'Kalimat At-Tawhid';

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
  String get setTarget => 'Définir l\'Objectif';

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
  String get keepAwake => 'Garder l\'Écran Allumé';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeModern => 'Bouton Moderne';

  @override
  String get themeClassic => 'Tasbih Classique';

  @override
  String get introTitle1 => 'Bienvenue sur Vaktinde';

  @override
  String get introDesc1 =>
      'Suivez facilement les heures de prière, les dhikrs et les jours religieux avec notre interface moderne.';

  @override
  String get introTitle2 => 'Notifications Intelligentes';

  @override
  String get introDesc2 =>
      'Recevez des alertes avec le son de votre choix. Ne manquez jamais vos actes d\'adoration.';

  @override
  String get introTitle3 => 'Outils Avancés';

  @override
  String get introDesc3 =>
      'Renforcez votre spiritualité avec le Compteur Animé, le Suivi des Prières Manquées, les Noms d\'Allah et la Calculatrice de Zakat.';

  @override
  String get introSkip => 'Passer';

  @override
  String get introNext => 'Suivant';

  @override
  String get introStart => 'Commencer';

  @override
  String get dhikrListTitle => 'Liste de Dhikrs';

  @override
  String get addCustomDhikr => 'Ajouter un Nouveau Dhikr';

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
  String get statsEmpty => 'Pas encore de données de dhikr.';

  @override
  String get dhikrEstagfirullah => 'Astaghfiroullah';

  @override
  String get dhikrLaHavle => 'La Hawla wa la Quwwata';

  @override
  String get dhikrHasbunallah => 'Hasbounallah';

  @override
  String get dhikrSubhanallahi => 'Soubhanallahi wa bihamdihi';

  @override
  String get dhikrYunus => 'Prière du Prophète Younous';

  @override
  String get dhikrYaAllah => 'Ya Allah (J.J.)';

  @override
  String get dhikrYaRahman => 'Ya Rahman (J.J.)';

  @override
  String get dhikrYaRahim => 'Ya Rahim (J.J.)';

  @override
  String get dhikrYaSafi => 'Ya Shafi (J.J.)';

  @override
  String get dhikrYaRezzak => 'Ya Razzaq (J.J.)';

  @override
  String get dhikrYaFettah => 'Ya Fattah (J.J.)';

  @override
  String get mainDhikrs => 'Dhikrs de Base';

  @override
  String get esmaulHusnaTab => 'Noms d\'Allah';

  @override
  String get qiblaCalibration =>
      'Pour que la boussole soit précise, dessinez un \'8\' en l\'air avec le téléphone.';

  @override
  String get hicriYilbasi => 'Nouvel An Islamique';

  @override
  String get asureGunu => 'Jour d\'Achoura';

  @override
  String get mevlidKandili => 'Mawlid';

  @override
  String get miracKandili => 'Isra et Mi\'raj';

  @override
  String get beratKandili => 'Nuit du Destin (Bara\'at)';

  @override
  String get ramazanBaslangici => 'Début du Ramadan';

  @override
  String get kadirGecesi => 'Nuit du Destin (Qadr)';

  @override
  String get ramazanBayrami => 'Aïd al-Fitr';

  @override
  String get kurbanBayrami => 'Aïd al-Adha';

  @override
  String get regaipKandili => 'Nuit du Raghaïb';

  @override
  String get tabTimes => 'Horaires';

  @override
  String get tabAlarms => 'Alarmes';

  @override
  String get locationFoundNoName => 'Position trouvée mais pas de nom.';

  @override
  String get dailyAyahTitle => 'Verset du Jour';

  @override
  String get remainingTime => 'Restant';

  @override
  String get onboardingWelcome => 'Hoş Geldiniz / Bienvenue';

  @override
  String get onboardingSelectLanguage =>
      'Lütfen kullanmak istediğiniz dili seçin.\nVeuillez sélectionner votre langue.';

  @override
  String get turnRight => 'Tournez à droite ➔';

  @override
  String get turnSlightRight => 'Tournez légèrement à droite ➔';

  @override
  String get turnLeft => '⬅ Tournez à gauche';

  @override
  String get turnSlightLeft => '⬅ Tournez légèrement à gauche';

  @override
  String get calibrationRequired => 'Étalonnage Requis';

  @override
  String get gold22kGram => 'Gramme d\'Or 22 Carats';

  @override
  String get goldAtaToptan => 'Ata Gros';

  @override
  String get goldAtaCumhuriyet => 'Ata Cumhuriyet';

  @override
  String get gold22kBracelet => 'Bracelet 22 Carats';

  @override
  String get gold18k => 'Or 18 Carats';

  @override
  String get gold14k => 'Or 14 Carats';

  @override
  String get goldHalf => 'Demi-Or';

  @override
  String get goldGremse => 'Or Gremse';

  @override
  String get goldAtaBesli => 'Ata Besli';

  @override
  String get goldResat => 'Or Resat';

  @override
  String get goldHamit => 'Or Hamit';

  @override
  String get currencyChf => 'Franc Suisse';

  @override
  String get currencyJpy => 'Yen Japonais';

  @override
  String get currencySar => 'Riyal Saoudien';

  @override
  String get currencyAud => 'Dollar Australien';

  @override
  String get currencyCad => 'Dollar Canadien';

  @override
  String get currencyRub => 'Rouble Russe';

  @override
  String get currencyAzn => 'Manat Azerbaïdjanais';

  @override
  String get currencyCny => 'Yuan Chinois';

  @override
  String get currencyRon => 'Leu Roumain';

  @override
  String get currencyAed => 'Dirham des EAU';

  @override
  String get currencyBgn => 'Lev Bulgare';

  @override
  String get currencyKwd => 'Dinar Koweïtien';

  @override
  String get currencyTry => 'Livre Turque';

  @override
  String get holdToEdit => 'Maintenir pour modifier';

  @override
  String get editCounterTitle => 'Modifier le Compteur';

  @override
  String get editCounterHint => 'Ex : 2000';

  @override
  String get editTargetHint => 'Ex : 99';

  @override
  String get resetCounterConfirm =>
      'Êtes-vous sûr de vouloir réinitialiser le compteur ?';

  @override
  String get dhikrTarget => 'Objectif :';

  @override
  String get imsakiyeTitle => 'Calendrier des prières';

  @override
  String get toolsGroupPrayer => 'Prière';

  @override
  String get toolsGroupInfo => 'Connaissances';

  @override
  String get toolsGroupCalc => 'Calculs';

  @override
  String get toolImsakiyeDesc => 'Horaires du mois et du Ramadan';

  @override
  String get toolTrackerDesc => 'Cochez les prières accomplies';

  @override
  String get toolKazaDesc => 'Compteur des prières et jeûnes manqués';

  @override
  String get toolReligiousDaysDesc => 'Nuits bénies et fêtes';

  @override
  String get toolEsmaDesc => 'Les 99 noms et leur sens';

  @override
  String get toolFridayDesc => 'Messages prêts à partager';

  @override
  String get toolZakatDesc => 'Calcul de la zakat et de l\'ouchr';

  @override
  String get toolSettingsDesc => 'Position, notifications, apparence';

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dans $count jours',
      one: 'Demain',
      zero: 'Aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get previousYear => 'Année précédente';

  @override
  String get nextYear => 'Année suivante';

  @override
  String get previousItem => 'Précédent';

  @override
  String get nextItem => 'Suivant';

  @override
  String missedChangeConfirm(String name, int from, int to) {
    return 'Le nombre pour $name passera de $from à $to. Enregistrer ?';
  }

  @override
  String get zakatCurrencyNote =>
      'Tous les montants sont en livres turques (₺).';

  @override
  String get zakatCashTry => 'Espèces (₺)';

  @override
  String get zakatRatesUnavailable =>
      'Les prix de l\'or et les taux de change actuels sont indisponibles. Veuillez saisir les prix vous-même.';

  @override
  String get zakatGoldGramPrice => 'Prix d\'1 g d\'or 24 carats (₺)';

  @override
  String get zakatGoldGramPriceHelp => 'Sert à calculer le seuil du nisab.';

  @override
  String get zakatNisabUnknown =>
      'Sans prix de l\'or, le seuil du nisab ne peut pas être calculé. Saisissez le prix de l\'or pour un résultat correct.';

  @override
  String get imsakiyeRamadan => 'Ramadan';

  @override
  String imsakiyeRamadanTitle(int year) {
    return 'Calendrier du Ramadan $year';
  }

  @override
  String get imsakiyeDay => 'Jour';

  @override
  String get imsakiyeSunriseShort => 'Lever';

  @override
  String get imsakiyePrevMonth => 'Mois précédent';

  @override
  String get imsakiyeNextMonth => 'Mois suivant';

  @override
  String get imsakiyeNoLocation =>
      'Veuillez d\'abord choisir votre position pour afficher le calendrier. Vous pouvez la définir sur l\'écran d\'accueil ou dans les Paramètres.';

  @override
  String get imsakiyeShareError =>
      'Impossible de partager le calendrier. Veuillez réessayer.';

  @override
  String get ramadanSahurLeft => 'Temps avant le Suhoor';

  @override
  String get ramadanIftarLeft => 'Temps avant l\'Iftar';

  @override
  String ramadanDayLabel(int day) {
    return 'Ramadan, jour $day';
  }
}
