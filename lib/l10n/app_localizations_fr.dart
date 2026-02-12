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
  String get noData => 'Pas de données.';

  @override
  String get imsak => 'Fajr';

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
  String get exactAlarm => 'Alerte à l\'heure exacte';

  @override
  String get exactAlarmSub => 'Envoie une notification.';

  @override
  String get silentNotif => 'Notification texte seulement';

  @override
  String get silentNotifSub => 'Pas de son/Adhan, juste une alerte.';

  @override
  String warningAlarm(String minute) {
    return 'Alerter $minute min avant';
  }

  @override
  String get warningAlarmSub => 'Son de notification court.';

  @override
  String get settings => 'Paramètres';

  @override
  String get changeLanguage => 'Changer la langue';

  @override
  String get waitingLocation => 'En attente de localisation...';

  @override
  String get noInternet =>
      'Pas de connexion internet et aucune donnée enregistrée.';

  @override
  String get gpsOff =>
      'Le GPS est désactivé. Veuillez activer la localisation.';

  @override
  String get permissionDenied => 'Permission de localisation refusée.';

  @override
  String get locationError => 'Impossible d\'obtenir la localisation.';

  @override
  String get internetNeeded => 'Connexion internet requise.';

  @override
  String get soundEzan => 'Adhan';

  @override
  String get soundBeep => 'Bip court';

  @override
  String get notifTitleTime => 'Heure de Prière';

  @override
  String notifBodyTime(String vakit) {
    return 'C\'est l\'heure de $vakit.';
  }

  @override
  String get notifTitleUpcoming => 'L\'heure approche';

  @override
  String notifBodyUpcoming(String vakit, int minute) {
    return 'Il reste $minute minutes pour $vakit.';
  }

  @override
  String get navPrayer => 'Horaires';

  @override
  String get navQibla => 'Qibla';

  @override
  String get navMenu => 'Menu';

  @override
  String get menuTitle => 'Paramètres';

  @override
  String get sectionLocation => 'LOCALISATION & HORAIRES';

  @override
  String get changeLocation => 'Changer de ville';

  @override
  String get citySelect => 'Sélectionner la ville';

  @override
  String get districtSelect => 'Sélectionner le district';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get locationWarning =>
      'La sélection du district est importante pour des horaires précis.';

  @override
  String get menuNotifications => 'Permissions de notification';

  @override
  String get menuNotificationsSub =>
      'Vérifiez ici si vous n\'entendez pas de son.';

  @override
  String get menuTroubleshoot => 'Pas de notifications ?';

  @override
  String get menuTroubleshootSub => 'Réglages batterie pour Samsung/Xiaomi.';

  @override
  String get sectionSupport => 'SUPPORT';

  @override
  String get shareApp => 'Partager avec des amis';

  @override
  String get rateApp => 'Notez-nous';

  @override
  String get contactUs => 'Contact & Signaler un bug';

  @override
  String shareText(String link) {
    return 'J\'ai trouvé une super appli d\'Horaires de Prière ! Télécharge : $link';
  }

  @override
  String get batteryDialogTitle => 'Résoudre les problèmes de notification';

  @override
  String get batteryDialogBody =>
      'Votre téléphone peut fermer l\'application pour économiser la batterie. Pour éviter cela :\n\n1. Ouvrez les applications récentes (bouton carré).\n2. Appuyez longuement sur l\'appli \'Vaktinde\' ou cliquez sur le logo.\n3. Appuyez sur l\'icône de cadenas 🔒 pour la verrouiller.\n\nAllez aussi dans Paramètres > Applications > Vaktinde > Batterie > Non restreint.';

  @override
  String get okUnderstood => 'Compris';

  @override
  String get religiousDaysTitle => 'Jours Religieux';

  @override
  String errorOccurred(String error) {
    return 'Erreur survenue : $error';
  }

  @override
  String get noDataFound => 'Aucune donnée trouvée.';

  @override
  String noDataForYear(int year) {
    return 'Aucune donnée trouvée pour l\'année $year.';
  }

  @override
  String religiousDaysListTitle(int year) {
    return 'Liste des Jours Religieux $year';
  }

  @override
  String get missedPrayersTitle => 'Prières Manquées';

  @override
  String get missedPrayersInfo =>
      'Suivez vos prières manquées ici et diminuez-les au fur et à mesure.\n(Appuyez sur le nombre pour saisir manuellement)';

  @override
  String editMissedTitle(String title) {
    return 'Modifier $title';
  }

  @override
  String get missedCountLabel => 'Nombre';

  @override
  String get missedCountHint => 'Ex: 150';

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
  String get esmaulHusnaTitle => '99 Noms d\'Allah';

  @override
  String get closeCaps => 'FERMER';

  @override
  String get zakatTitle => 'Calculatrice Zakat';

  @override
  String get zakatCalculatorTitle => 'Calculatrice Zakat Intelligente';

  @override
  String get liveRatesLoading => 'Récupération des taux...';

  @override
  String get liveRatesInfo =>
      'Vous pouvez ajuster manuellement les taux si nécessaire.';

  @override
  String get sectionGold => 'Actifs en Or';

  @override
  String get goldType => 'Type d\'Or';

  @override
  String get goldAmount => 'Quantité / Gramme';

  @override
  String get goldUnitPrice => 'Prix Unitaire (TL)';

  @override
  String get sectionCurrency => 'Actifs en Devises';

  @override
  String get currencyType => 'Type de Devise';

  @override
  String get currencyAmount => 'Montant';

  @override
  String get currencyRate => 'Taux Actuel (TL)';

  @override
  String get sectionCashDebt => 'Espèces & Dettes';

  @override
  String get cashAmount => 'Espèces en main & Banque (TL)';

  @override
  String get debtAmount => 'Dettes Totales (À déduire)';

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
      'Le service de localisation est désactivé. Veuillez l\'activer.';

  @override
  String get locationPermissionDenied => 'Permission de localisation refusée.';

  @override
  String get locationPermissionForever =>
      'Permission refusée définitivement. Activez dans les paramètres.';

  @override
  String compassError(String error) {
    return 'Erreur capteur : $error';
  }

  @override
  String get noCompass => 'Pas de boussole sur l\'appareil.';

  @override
  String get qiblaFound => 'VOUS AVEZ TROUVÉ LA QIBLA !';

  @override
  String qiblaAngle(String angle) {
    return 'Angle Qibla : $angle°';
  }

  @override
  String get keepAwayMetal => 'Tenir à l\'écart des objets métalliques.';

  @override
  String get goldGram => 'Or Gramme (24K)';

  @override
  String get goldQuarter => 'Quart d\'Or';

  @override
  String get goldFull => 'Or Plein';

  @override
  String get typeOther => 'Autre (Manuel)';

  @override
  String get usd => 'Dollar Américain (USD)';

  @override
  String get eur => 'Euro (EUR)';

  @override
  String get gbp => 'Livre Sterling (GBP)';

  @override
  String get sectionAppearance => 'APPARENCE & LANGUE';

  @override
  String get appearanceSettings => 'Paramètres d\'apparence';

  @override
  String get appearanceSub => 'Thème et Arrière-plan';

  @override
  String get themeMode => 'Mode du thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get bgImage => 'Image d\'arrière-plan';

  @override
  String get bgDefault => 'Défaut';

  @override
  String get bgMosque => 'Mosquée';

  @override
  String get bgKaaba => 'Kaaba';

  @override
  String get bgQuran => 'Coran';

  @override
  String get none => 'Aucun';

  @override
  String get zakatEligible => 'La Zakat est requise';

  @override
  String get zakatNotEligible => 'Zakat non requise';

  @override
  String get nisabLimit => 'Seuil Nisab (80,18g d\'Or)';

  @override
  String get belowNisabMessage =>
      'La Zakat n\'est pas obligatoire car votre actif net est inférieur au seuil Nisab.';

  @override
  String get searchLocationTitle => 'Rechercher un lieu (Monde entier)';

  @override
  String get searchLocationHint => 'Ville ou Pays (Ex: Paris)';

  @override
  String get searchInitial => 'Tapez pour rechercher...';

  @override
  String get searchNotFound => 'Lieu non trouvé.';

  @override
  String get searchError => 'Aucun résultat. Veuillez réessayer.';

  @override
  String locationSelected(String city) {
    return '$city sélectionné';
  }
}
