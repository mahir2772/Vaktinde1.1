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
  String get navZikir => 'Dhikr';

  @override
  String get adPrivacySettings => 'Confidentialité des annonces';

  @override
  String get adPrivacySettingsSub =>
      'Modifier votre consentement aux annonces personnalisées';

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
  String get showcaseZikir => 'Comptez vos dhikrs ici.';

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
    return 'Orientation du téléphone : $deg°';
  }

  @override
  String get usingSavedLocation => 'Utilisation de la position enregistrée.';

  @override
  String exampleHint(int n) {
    return 'Ex. : $n';
  }

  @override
  String get noCustomDhikr =>
      'Vous n\'avez pas encore ajouté de dhikr personnalisé.';

  @override
  String get messagesShuffled => 'Messages mélangés';

  @override
  String get shareAsImage => 'Partager en image';

  @override
  String get shareAsText => 'Partager le texte';

  @override
  String get shareCardFooter => 'Vaktinde sur Google Play';

  @override
  String get fridayGreeting => 'Vendredi béni';

  @override
  String get sendGreeting => 'Envoyer des vœux';

  @override
  String get greetingsTitle => 'Messages de vœux';

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
  String get nextPrayer => 'Prochaine prière';

  @override
  String get hadithTitle => 'Hadith du jour';

  @override
  String get share => 'Partager';

  @override
  String get close => 'Fermer';

  @override
  String get loading => 'Calcul des horaires...';

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
  String get exactAlarm => 'Notifier à l\'heure exacte';

  @override
  String get reminderTitleAt => 'Rappel de prière';

  @override
  String notifBodyUpcomingAt(String vakit, String time) {
    return '$vakit : début à $time';
  }

  @override
  String get endReminderTitleAt => 'Fin du temps de prière';

  @override
  String endReminderNotifBodyAt(String vakit, String time) {
    return '$vakit : fin du temps de prière à $time';
  }

  @override
  String ramadanImsakBodyAt(String time) {
    return 'Le temps du suhoor s\'est terminé à $time. Bon jeûne !';
  }

  @override
  String get alarmHealthExactOff =>
      'Autorisation d\'alarme désactivée : l\'adhan et les rappels peuvent avoir jusqu\'à environ une heure de retard (imsak et suhoor compris).';

  @override
  String get healthTitle => 'Vérifier les notifications';

  @override
  String get healthSub =>
      'L\'adhan ne retentit pas ? Vérifiez vos paramètres étape par étape';

  @override
  String get healthSectionStatus => 'État';

  @override
  String get healthEzansTitle => 'Alarmes d\'adhan';

  @override
  String healthEzansOn(String names) {
    return 'Activées : $names';
  }

  @override
  String get healthEzansNone => 'L\'adhan n\'est activé pour aucune prière.';

  @override
  String get healthNextTitle => 'Prochain adhan';

  @override
  String get healthNextNone => 'Aucun adhan programmé.';

  @override
  String get healthReschedule => 'Reprogrammer';

  @override
  String get healthNotificationsTitle => 'Notifications';

  @override
  String get healthNotificationsOk => 'Activées.';

  @override
  String get healthOpenSettings => 'Ouvrir les paramètres';

  @override
  String get healthExactTitle => 'Alarmes et rappels';

  @override
  String get healthExactOk => 'Autorisé : l\'adhan retentit à l\'heure exacte.';

  @override
  String get healthVolumeTitle => 'Son';

  @override
  String get healthVolumeOk => 'Le son des notifications est activé.';

  @override
  String get healthVolumeAlarmOk => 'Le son des alarmes est activé.';

  @override
  String get healthVolumeSilent =>
      'Votre téléphone est en mode silencieux ou vibreur : vous n\'entendrez pas l\'adhan.';

  @override
  String get healthVolumeNotificationMuted =>
      'Le son des notifications est coupé : vous n\'entendrez pas l\'adhan.';

  @override
  String get healthVolumeAlarmMuted =>
      'Le son des alarmes est coupé : vous n\'entendrez pas l\'adhan.';

  @override
  String healthAlarmStreamTip(String setting) {
    return 'Si « $setting » est activé, l\'adhan retentit au volume de l\'alarme.';
  }

  @override
  String get healthDndTitle => 'Ne pas déranger';

  @override
  String get healthDndOff => 'Désactivé.';

  @override
  String get healthDndOn =>
      'Activé : vous risquez de ne pas entendre l\'adhan.';

  @override
  String healthDndAlarm(String setting) {
    return 'Activé, mais grâce à « $setting », l\'adhan retentit au volume de l\'alarme.';
  }

  @override
  String get healthBatteryTitle => 'Utilisation de la batterie';

  @override
  String get healthBatteryOk =>
      'L\'optimisation de la batterie est désactivée pour Vaktinde.';

  @override
  String get healthBatteryOptimized =>
      'L\'optimisation de la batterie est activée : votre téléphone peut arrêter Vaktinde en arrière-plan. Dans les paramètres de l\'application, ouvrez Batterie et choisissez « Sans restriction » (l\'intitulé peut varier selon le téléphone).';

  @override
  String get healthBackgroundTitle => 'Activité en arrière-plan';

  @override
  String healthBackgroundToday(String time) {
    return 'Dernière exécution : aujourd\'hui à $time';
  }

  @override
  String healthBackgroundYesterday(String time) {
    return 'Dernière exécution : hier à $time';
  }

  @override
  String get healthBackgroundStale =>
      'Vaktinde ne s\'est pas exécuté en arrière-plan depuis 48 heures : votre téléphone l\'arrête peut-être.';

  @override
  String get healthShowSteps => 'Voir les étapes';

  @override
  String healthGuideTitle(String brand) {
    return 'Paramètres pour $brand';
  }

  @override
  String get healthGuideTitleGeneric => 'Paramètres pour votre téléphone';

  @override
  String get healthGuideStale =>
      'L\'activité en arrière-plan semble arrêtée. Pour que l\'adhan ne soit pas retardé, modifiez les paramètres suivants :';

  @override
  String get healthGuideMore =>
      'Guides détaillés selon votre modèle (en anglais)';

  @override
  String get healthTestTitle => 'Adhan de test';

  @override
  String get healthTestInfo =>
      'Vous recevrez une notification de test dans 1 minute, avec le même son et les mêmes paramètres que le véritable adhan.';

  @override
  String get healthTestButton => 'Adhan de test dans 1 min';

  @override
  String get healthTestScheduled =>
      'L\'adhan de test retentira dans 1 minute. Vous pouvez fermer l\'application.';

  @override
  String get healthTestNotifBody =>
      'Si vous voyez cette notification, les notifications d\'adhan fonctionnent.';

  @override
  String get healthStepXiaomiAutostart =>
      'Dans les paramètres de l\'application, activez le démarrage automatique.';

  @override
  String get healthStepXiaomiBattery =>
      'Sur le même écran, dans l\'économiseur de batterie (ou Batterie), supprimez toutes les restrictions.';

  @override
  String get healthStepHuaweiLaunch =>
      'Dans les paramètres, ouvrez la gestion du lancement des applications (sous Batterie ou Applications). Désactivez la gestion automatique pour Vaktinde et laissez toutes les options activées dans la fenêtre qui s\'affiche.';

  @override
  String get healthStepOppoBackground =>
      'Dans les paramètres de l\'application, sous Utilisation de la batterie, autorisez l\'activité en arrière-plan et le lancement automatique.';

  @override
  String get healthStepVivoBackground =>
      'Dans Paramètres > Batterie, autorisez une consommation d\'énergie élevée en arrière-plan pour Vaktinde.';

  @override
  String healthStepAutostartIn(String app) {
    return 'Activez le démarrage automatique de Vaktinde dans les paramètres ou dans l\'application $app.';
  }

  @override
  String get healthStepAppBattery =>
      'Dans les paramètres de l\'application, sous Batterie, choisissez « Sans restriction ».';

  @override
  String get healthStepSamsungSleeping =>
      'Dans Paramètres > Batterie > Limites d\'utilisation en arrière-plan, ajoutez Vaktinde aux applications jamais mises en veille.';

  @override
  String get healthStepLockRecents =>
      'Verrouillez Vaktinde sur l\'écran des applications récentes (si votre téléphone le permet).';

  @override
  String get healthDetails => 'Détails';

  @override
  String get alarmHealthExactAction => 'Autoriser';

  @override
  String get alarmHealthNotificationsOff =>
      'Les notifications sont désactivées, l\'adhan ne retentira pas.';

  @override
  String get alarmHealthNotificationsAction => 'Activer';

  @override
  String get ezanAlarmStreamTitle => 'Jouer aussi en mode silencieux';

  @override
  String get ezanAlarmStreamSub =>
      'L\'adhan retentit au volume de l\'alarme, même si le téléphone est en mode silencieux.';

  @override
  String channelAlarmSound(String soundName) {
    return 'Son : $soundName (même en silencieux)';
  }

  @override
  String get exactAlarmSub => 'Envoie une notification.';

  @override
  String get silentNotif => 'Notification textuelle uniquement';

  @override
  String get silentNotifSub =>
      'Ni adhan ni son, uniquement une alerte visuelle.';

  @override
  String warningAlarm(String minute) {
    return 'Avertir $minute min avant';
  }

  @override
  String get warningAlarmSub => 'Son de notification court.';

  @override
  String get settings => 'Paramètres';

  @override
  String get changeLanguage => 'Changer de langue';

  @override
  String get waitingLocation => 'En attente de la position...';

  @override
  String get noInternet =>
      'Pas de connexion internet et aucune donnée enregistrée trouvée.';

  @override
  String get gpsOff =>
      'Le GPS est désactivé. Veuillez activer la localisation.';

  @override
  String get permissionDenied => 'Autorisation de localisation refusée.';

  @override
  String get locationError => 'Impossible d\'obtenir la position.';

  @override
  String get internetNeeded => 'Une connexion internet est requise.';

  @override
  String get soundEzan => 'Adhan';

  @override
  String get soundBeep => 'Bip court';

  @override
  String get notifTitleTime => 'Heure de prière';

  @override
  String notifBodyTime(String vakit) {
    return '$vakit : c\'est l\'heure.';
  }

  @override
  String get notifTitleUpcoming => 'L\'heure approche';

  @override
  String notifBodyUpcoming(String vakit, int minute) {
    return '$vakit dans $minute minutes.';
  }

  @override
  String get navPrayer => 'Accueil';

  @override
  String get navQibla => 'Qibla';

  @override
  String get menuTitle => 'Paramètres';

  @override
  String get sectionLocation => 'POSITION & HORAIRES';

  @override
  String get changeLocation => 'Changer la position';

  @override
  String get citySelect => 'Sélectionner la ville';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get timeAdjustTitle => 'Ajustement des horaires';

  @override
  String get tapToCount => 'Appuyez pour compter';

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
      'Les prières non cochées des 30 derniers jours (depuis le début du suivi) sont ajoutées aux compteurs de qada. Chaque prière n\'est ajoutée qu\'une fois. Si vous avez accompli une prière ajoutée au qada, appuyez dessus : elle sera marquée comme accomplie et déduite du compteur de qada.';

  @override
  String trackerKazaConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count prières non cochées seront ajoutées aux compteurs de qada. Continuer ?',
      one:
          '1 prière non cochée sera ajoutée aux compteurs de qada. Continuer ?',
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
  String get trackerKazaRemoveTitle => 'Retirer du qada ?';

  @override
  String trackerKazaRemoveConfirm(String name, int from, int to) {
    return 'Cette prière sera marquée comme accomplie. $name : le nombre à rattraper passera de $from à $to.';
  }

  @override
  String get addWidgetTitle => 'Ajouter un widget à l\'écran d\'accueil';

  @override
  String get addWidgetSub => 'Voir les horaires sans ouvrir l\'application';

  @override
  String get addWidgetHint =>
      'Choisissez-en un ; votre écran d\'accueil vous demandera de confirmer.';

  @override
  String get widgetLargeName => 'Horaires du jour';

  @override
  String get widgetLargeDesc =>
      'Grand format : lieu, date hégirienne, horaires du jour et temps restant';

  @override
  String get widgetWideName => 'Prochaine prière';

  @override
  String get widgetWideDesc =>
      'Bandeau horizontal : lieu, date hégirienne et temps restant avant la prochaine prière';

  @override
  String get widgetSmallName => 'Compte à rebours';

  @override
  String get widgetSmallDesc =>
      'Petit carré : temps restant avant la prochaine prière';

  @override
  String get trackerLegendPrayed => 'Accomplie';

  @override
  String get trackerLegendKaza => 'Ajoutée au qada';

  @override
  String kerahatActive(String range) {
    return 'Temps makruh en cours : $range';
  }

  @override
  String kerahatUpcoming(String range) {
    return 'Le temps makruh approche : $range';
  }

  @override
  String get endReminderTitle => 'Rappel avant la fin du temps de prière';

  @override
  String get dailyContentNotifTitle =>
      'Notifications du verset et du hadith du jour';

  @override
  String get dailyContentNotifSub =>
      'Envoie un verset chaque matin et un hadith chaque soir.';

  @override
  String get religiousDaysNotifTitle =>
      'Notifications des jours religieux et des nuits bénies';

  @override
  String get religiousDaysNotifSub =>
      'Vous rappelle le matin même les nuits bénies, les fêtes et les autres jours religieux.';

  @override
  String get religiousDaysChannel => 'Jours religieux et nuits bénies';

  @override
  String get ucAylarBaslangici => 'Début des trois mois bénis';

  @override
  String get ramazanArefesi => 'Dernier jour du Ramadan';

  @override
  String get kurbanArefesi => 'Jour d\'Arafat';

  @override
  String get ucAylarNotifBody =>
      'Les trois mois bénis de Rajab, Chaabane et Ramadan commencent aujourd\'hui. Qu\'ils vous apportent de nombreuses bénédictions.';

  @override
  String get ucAylarRegaipTitle => 'Trois mois bénis et Nuit du Raghaïb';

  @override
  String get ucAylarRegaipNotifBody =>
      'Les trois mois bénis commencent aujourd\'hui, et ce soir, c\'est la Nuit du Raghaïb. Que cette nuit et ces mois soient bénis pour vous.';

  @override
  String get regaipKandiliNotifBody =>
      'Ce soir commence la Nuit du Raghaïb. Qu\'elle soit bénie pour vous.';

  @override
  String get miracKandiliNotifBody =>
      'Ce soir commence la nuit d\'Isra et Mi\'raj. Qu\'elle soit bénie pour vous.';

  @override
  String get beratKandiliNotifBody =>
      'Ce soir commence la nuit de la mi-Chaabane (Bara\'at). Qu\'elle soit bénie pour vous.';

  @override
  String get mevlidKandiliNotifBody =>
      'Ce soir commence la nuit du Mawlid. Qu\'elle soit bénie pour vous.';

  @override
  String get kadirGecesiNotifBody =>
      'Ce soir commence la Nuit du Destin (Qadr). Qu\'elle soit bénie pour vous.';

  @override
  String get ramazanBaslangiciNotifBody =>
      'Le Ramadan commence demain : la première prière de tarawih et le premier suhoor ont lieu cette nuit. Bon Ramadan !';

  @override
  String get ramazanArefesiNotifBody =>
      'Demain, c\'est l\'Aïd al-Fitr. Aïd Moubarak par avance !';

  @override
  String get ramazanBayramiNotifBody =>
      'Aïd Moubarak ! Qu\'Allah accepte notre jeûne et nos prières.';

  @override
  String get kurbanArefesiNotifBody =>
      'Demain, c\'est l\'Aïd al-Adha. Aïd Moubarak par avance !';

  @override
  String get kurbanBayramiNotifBody =>
      'Aïd Moubarak ! Qu\'Allah accepte vos sacrifices et vos bonnes actions.';

  @override
  String get hicriYilbasiNotifBody =>
      'Aujourd\'hui, c\'est le Nouvel An islamique. Que cette nouvelle année soit source de bien et de bénédictions.';

  @override
  String get asureGunuNotifBody =>
      'Aujourd\'hui, c\'est le jour d\'Achoura. Qu\'il soit source de bien et de bénédictions.';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get endReminderSub =>
      'Vous avertit avant la fin du temps d\'une prière non cochée.';

  @override
  String get endReminderNotifTitle => 'Fin du temps de prière';

  @override
  String endReminderNotifBody(String vakit, int minute) {
    return '$vakit : le temps de prière se termine dans $minute minutes.';
  }

  @override
  String get endReminderChannel => 'Rappels de fin du temps de prière';

  @override
  String get ramadanIftarTitle => 'Heure de l\'iftar';

  @override
  String ramadanIftarBody(String vakit) {
    return 'L\'heure de $vakit est arrivée. Bon iftar !';
  }

  @override
  String get ramadanImsakTitle => 'Heure de l\'imsak';

  @override
  String get ramadanImsakBody => 'Le temps du suhoor est terminé. Bon jeûne !';

  @override
  String get sectionSupport => 'SUPPORT';

  @override
  String get shareApp => 'Partager avec un ami';

  @override
  String get rateApp => 'Évaluez-nous';

  @override
  String get contactUs => 'Contact et signalement de bug';

  @override
  String shareText(String link) {
    return 'J\'ai trouvé une super application d\'horaires de prière ! Téléchargez-la ici : $link';
  }

  @override
  String get okUnderstood => 'OK, j\'ai compris';

  @override
  String get religiousDaysTitle => 'Jours religieux';

  @override
  String get noDataFound => 'Aucune donnée trouvée.';

  @override
  String noDataForYear(int year) {
    return 'Aucune donnée trouvée pour l\'année $year.';
  }

  @override
  String religiousDaysListTitle(int year) {
    return 'Liste des jours religieux de $year';
  }

  @override
  String get missedPrayersTitle => 'Suivi des prières manquées';

  @override
  String get missedPrayersInfo =>
      'Notez ici vos prières manquées et déduisez-les au fur et à mesure.\n(Appuyez sur le nombre pour une saisie manuelle)';

  @override
  String editMissedTitle(String title) {
    return 'Modifier le compteur : $title';
  }

  @override
  String get missedCountLabel => 'Nombre à rattraper';

  @override
  String get missedCountHint => 'Ex. : 150';

  @override
  String get sabah => 'Fajr';

  @override
  String get vitir => 'Witr';

  @override
  String get oruc => 'Jeûne';

  @override
  String timeLeftFor(String vakit) {
    return '$vakit dans';
  }

  @override
  String get tomorrow => '(Demain)';

  @override
  String get fridayMessagesTitle => 'Messages du vendredi';

  @override
  String get esmaulHusnaTitle => 'Noms d\'Allah';

  @override
  String get zakatTitle => 'Calculatrice de Zakat';

  @override
  String get fitreTitle => 'Fitra et fidya';

  @override
  String get toolFitreDesc => 'Calcul de la fitra et de la fidya';

  @override
  String get fitreInfo =>
      'Le montant par personne est la fitra (sadaqat al-fitr) minimale fixée par la Diyanet, l\'autorité religieuse turque ; la fitra peut être donnée en argent ou en nourriture. La fidya est due par les personnes qui ne peuvent pas jeûner en raison de leur grand âge ou d\'une maladie sans espoir de guérison : une fitra pour chaque jour. Si vous vivez hors de Turquie, vous pouvez saisir le montant fixé là où vous vivez.';

  @override
  String get fitreAmountLabel => 'Montant par personne';

  @override
  String fitreSource(String source, String year) {
    return 'Source : $source, $year';
  }

  @override
  String get fitreResetAmount => 'Rétablir le montant par défaut';

  @override
  String get fitreSectionTitle => 'Fitra';

  @override
  String get fitrePeopleLabel => 'Nombre de personnes';

  @override
  String get fidyeSectionTitle => 'Fidya';

  @override
  String get fidyeDaysLabel => 'Nombre de jours';

  @override
  String get fitreTotal => 'Total';

  @override
  String get fastTitle => 'Jeûne du Ramadan';

  @override
  String fastCount(int done, int total) {
    return '$done/$total jours';
  }

  @override
  String get fastInfo =>
      'Appuyez sur les jours où vous avez jeûné. Les jours manqués sont ajoutés une seule fois au compteur de jeûnes à rattraper ; si vous avez finalement jeûné un jour ajouté au qada, appuyez dessus pour le déduire du compteur.';

  @override
  String get fastLegendFasted => 'Jeûné';

  @override
  String get fastLegendKaza => 'Ajouté au qada';

  @override
  String get fastKazaButton => 'Ajouter les jeûnes manqués au qada';

  @override
  String fastKazaConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count jours non cochés seront ajoutés au compteur de jeûnes à rattraper. Continuer ?',
      one:
          '1 jour non coché sera ajouté au compteur de jeûnes à rattraper. Continuer ?',
    );
    return '$_temp0';
  }

  @override
  String fastKazaDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours ajoutés au qada.',
      one: '1 jour ajouté au qada.',
    );
    return '$_temp0';
  }

  @override
  String get fastKazaNone => 'Aucun jour à ajouter au qada.';

  @override
  String get fastKazaRemoveTitle => 'Retirer du qada ?';

  @override
  String fastKazaRemoveConfirm(int from, int to) {
    return 'Ce jour sera marqué comme jeûné et le nombre de jeûnes à rattraper passera de $from à $to.';
  }

  @override
  String get fastFastedAction => 'J\'ai jeûné';

  @override
  String get zakatCalculatorTitle => 'Calculatrice intelligente de Zakat';

  @override
  String get liveRatesLoading => 'Récupération des taux de change...';

  @override
  String get liveRatesInfo =>
      'Vous pouvez modifier manuellement les taux récupérés automatiquement.';

  @override
  String get goldType => 'Type d\'or';

  @override
  String get goldAmount => 'Quantité / Grammes';

  @override
  String get goldUnitPrice => 'Prix unitaire';

  @override
  String get currencyType => 'Type de devise';

  @override
  String get currencyAmount => 'Montant';

  @override
  String get currencyRate => 'Taux actuel';

  @override
  String get calculateButton => 'CALCULER';

  @override
  String get zakatResultTitle => 'Votre Zakat à payer';

  @override
  String get netAssets => 'Actifs nets :';

  @override
  String get qiblaTitle => 'Boussole Qibla';

  @override
  String get locationServiceOff =>
      'Service de localisation désactivé. Veuillez l\'activer.';

  @override
  String get locationPermissionDenied =>
      'Autorisation de localisation refusée.';

  @override
  String get noCompass => 'Pas de boussole sur cet appareil.';

  @override
  String get qiblaFound => 'VOUS AVEZ TROUVÉ LA QIBLA !';

  @override
  String qiblaAngle(String angle) {
    return 'Angle de la Qibla : $angle°';
  }

  @override
  String get keepAwayMetal =>
      'Tenez le téléphone éloigné des objets métalliques.';

  @override
  String get goldGram => 'Gramme d\'or (24 carats)';

  @override
  String get goldQuarter => 'Quart d\'or';

  @override
  String get goldFull => 'Pièce d\'or entière';

  @override
  String get typeOther => 'Autre (saisie manuelle)';

  @override
  String get usd => 'Dollar US (USD)';

  @override
  String get eur => 'Euro (EUR)';

  @override
  String get gbp => 'Livre sterling (GBP)';

  @override
  String get sectionAppearance => 'APPARENCE & LANGUE';

  @override
  String get appearanceSettings => 'Paramètres d\'apparence';

  @override
  String get appearanceSub => 'Thème et arrière-plan';

  @override
  String get themeMode => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get bgImage => 'Image de fond';

  @override
  String get bgDefault => 'Par défaut';

  @override
  String get bgMosque => 'Mosquée';

  @override
  String get bgKaaba => 'Kaaba';

  @override
  String get zakatEligible => 'La Zakat est due';

  @override
  String get zakatNotEligible => 'La Zakat n\'est pas due';

  @override
  String get nisabLimit => 'Seuil du nisab (80,18 g d\'or)';

  @override
  String get belowNisabMessage =>
      'Vos actifs nets étant inférieurs au seuil du nisab, la Zakat n\'est pas obligatoire.';

  @override
  String get searchLocationTitle => 'Rechercher un lieu (monde entier)';

  @override
  String get searchLocationHint => 'Ville ou pays (ex. : Paris)';

  @override
  String get searchInitial => 'Tapez le lieu que vous souhaitez rechercher...';

  @override
  String get searchNotFound => 'Position introuvable.';

  @override
  String get searchError => 'Aucun résultat trouvé. Veuillez réessayer.';

  @override
  String locationSelected(String city) {
    return 'Lieu sélectionné : $city';
  }

  @override
  String channelSoundPrefix(String soundName) {
    return 'Son : $soundName';
  }

  @override
  String get channelSilentPrayers => 'Notifications d\'adhan silencieuses';

  @override
  String get tickerEzan => 'Heure de prière';

  @override
  String get fetchingLocation => 'Localisation en cours...';

  @override
  String get directionNorth => 'N';

  @override
  String get directionSouth => 'S';

  @override
  String get directionEast => 'E';

  @override
  String get directionWest => 'O';

  @override
  String get zakatDescription =>
      'Calculez votre Zakat en détail selon les directives religieuses et les taux actuels du marché.';

  @override
  String get cashAndCurrencyTitle => 'Espèces et devises';

  @override
  String get goldAndSilverTitle => 'Or et argent';

  @override
  String get silverGram => 'Argent (grammes)';

  @override
  String get unitPrice => 'Prix unitaire';

  @override
  String get commercialGoodsTitle => 'Biens commerciaux';

  @override
  String get commercialEvalCurrency => 'Devise d\'évaluation';

  @override
  String get commercialGoodsValue => 'Valeur des biens';

  @override
  String get exchangeRateValue => 'Taux de change';

  @override
  String get receivablesTitle => 'Créances (recouvrables)';

  @override
  String get receivableType => 'Type (espèces, devise, or)';

  @override
  String get amountOrCount => 'Montant / Quantité';

  @override
  String get otherAssetsTitle => 'Autres actifs';

  @override
  String get assetType => 'Type d\'actif';

  @override
  String get currencyLabel => 'Devise';

  @override
  String get valueOrAmount => 'Valeur / Montant';

  @override
  String get agriProductsTitle => 'Produits agricoles (ouchr)';

  @override
  String get agriDiyanetNote =>
      'Comme le nisab ne s\'applique pas aux produits agricoles, le montant déclaré est directement ajouté à votre total de Zakat.';

  @override
  String get harvestedProductValue => 'Valeur du produit récolté';

  @override
  String get irrigationMethod => 'Méthode d\'irrigation';

  @override
  String get debtsTitle => 'Dettes (à déduire)';

  @override
  String get debtType => 'Type de dette (espèces, devise, or)';

  @override
  String get zakatAgriIncluded =>
      'Incluant la Zakat des produits agricoles (ouchr)';

  @override
  String get assetCheck => 'Chèque';

  @override
  String get assetBond => 'Billet à ordre';

  @override
  String get assetSukuk => 'Sukuk';

  @override
  String get assetLeaseCert => 'Certificat de location';

  @override
  String get assetStock => 'Actions';

  @override
  String get agriSoil => 'Agriculture (en terre)';

  @override
  String get agriSoilless => 'Agriculture (hors-sol)';

  @override
  String get agriRateNoCost => 'Sans frais (pluie/rivière) - 10 %';

  @override
  String get agriRateCostly => 'Avec frais (moteur/transport) - 5 %';

  @override
  String get toImsak => 'Imsak dans';

  @override
  String get toGunes => 'Lever du soleil dans';

  @override
  String get toOgle => 'Dhuhr dans';

  @override
  String get toIkindi => 'Asr dans';

  @override
  String get toAksam => 'Maghrib dans';

  @override
  String get toYatsi => 'Isha dans';

  @override
  String get lowAccuracyWarning =>
      'La boussole est mal étalonnée. Veuillez dessiner un « 8 » en l\'air avec votre téléphone.';

  @override
  String get qiblaDirection => 'Direction de la Qibla';

  @override
  String get zikirmatikTitle => 'Compteur de dhikr';

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
  String get targetReached => 'Objectif atteint !';

  @override
  String get resetCounter => 'Réinitialiser';

  @override
  String targetCount(int target) {
    return 'Objectif : $target';
  }

  @override
  String get setTarget => 'Définir l\'objectif';

  @override
  String get dhikrOther => 'Autre (dhikr personnalisé)';

  @override
  String get customDhikrHint => 'Tapez votre dhikr';

  @override
  String get zikirSettings => 'Paramètres';

  @override
  String get vibration => 'Vibration';

  @override
  String get sound => 'Effet sonore';

  @override
  String get keepAwake => 'Garder l\'écran allumé';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeModern => 'Bouton moderne';

  @override
  String get themeClassic => 'Tasbih classique';

  @override
  String get dhikrListTitle => 'Liste des dhikrs';

  @override
  String get addCustomDhikr => 'Ajouter un nouveau dhikr';

  @override
  String get customDhikrAdded => 'Dhikr ajouté avec succès.';

  @override
  String get customDhikrLimit =>
      'Vous pouvez ajouter jusqu\'à 20 dhikrs personnalisés !';

  @override
  String get deleteDhikr => 'Supprimer';

  @override
  String get statisticsTitle => 'Statistiques';

  @override
  String get monthly => 'Mensuel';

  @override
  String get yearly => 'Annuel';

  @override
  String get totalDhikr => 'Total des dhikrs';

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
  String get dhikrYunus => 'Invocation du prophète Younous';

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
  String get mainDhikrs => 'Dhikrs de base';

  @override
  String get esmaulHusnaTab => 'Noms d\'Allah';

  @override
  String get qiblaCalibration =>
      'Pour que la boussole soit précise, dessinez un « 8 » en l\'air avec votre téléphone.';

  @override
  String get hicriYilbasi => 'Nouvel An islamique';

  @override
  String get asureGunu => 'Jour d\'Achoura';

  @override
  String get mevlidKandili => 'Mawlid';

  @override
  String get miracKandili => 'Isra et Mi\'raj';

  @override
  String get beratKandili => 'Nuit de la mi-Chaabane (Bara\'at)';

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
  String get locationFoundNoName =>
      'Position trouvée, mais le nom du lieu est introuvable.';

  @override
  String get dailyAyahTitle => 'Verset du jour';

  @override
  String get onboardingWelcome => 'Hoş Geldiniz / Bienvenue';

  @override
  String get onboardingSelectLanguage =>
      'Lütfen kullanmak istediğiniz dili seçin.\nVeuillez sélectionner votre langue.';

  @override
  String get calibrationRequired => 'Étalonnage requis';

  @override
  String get qiblaAccuracyNote =>
      'La boussole indique une direction approximative ; le métal, les aimants et les appareils électroniques peuvent la fausser.';

  @override
  String get qiblaTipsTitle => 'Pour un résultat précis';

  @override
  String get qiblaTipFlat => 'Tenez le téléphone à plat, parallèle au sol.';

  @override
  String get qiblaTipCalibrate =>
      'Étalonnez la boussole en dessinant un « 8 » en l\'air avec votre téléphone.';

  @override
  String get qiblaTipMagneticCase =>
      'Retirez la coque aimantée, le cas échéant.';

  @override
  String get qiblaTipMetal =>
      'Éloignez-vous des objets métalliques et des appareils électroniques.';

  @override
  String get qiblaTipMosque =>
      'Si possible, comparez avec la direction de la Qibla d\'une mosquée.';

  @override
  String qiblaAngleTrueNorth(String angle) {
    return 'Angle de la Qibla : $angle° (par rapport au nord géographique)';
  }

  @override
  String qiblaDeclination(String deg) {
    return 'Déclinaison magnétique : $deg° (corrigée automatiquement)';
  }

  @override
  String get qiblaInterferenceWarning =>
      'Interférence magnétique détectée : éloignez le téléphone des objets métalliques, des coques aimantées et des appareils électroniques.';

  @override
  String get gold22kGram => 'Gramme d\'or 22 carats';

  @override
  String get goldAtaToptan => 'Ata (prix de gros)';

  @override
  String get goldAtaCumhuriyet => 'Ata Cumhuriyet';

  @override
  String get gold22kBracelet => 'Bracelet 22 carats';

  @override
  String get gold18k => 'Or 18 carats';

  @override
  String get gold14k => 'Or 14 carats';

  @override
  String get goldHalf => 'Demi-or';

  @override
  String get goldGremse => 'Or Gremse';

  @override
  String get goldAtaBesli => 'Ata Besli';

  @override
  String get goldResat => 'Or Resat';

  @override
  String get goldHamit => 'Or Hamit';

  @override
  String get currencyChf => 'Franc suisse';

  @override
  String get currencyJpy => 'Yen japonais';

  @override
  String get currencySar => 'Riyal saoudien';

  @override
  String get currencyAud => 'Dollar australien';

  @override
  String get currencyCad => 'Dollar canadien';

  @override
  String get currencyRub => 'Rouble russe';

  @override
  String get currencyAzn => 'Manat azerbaïdjanais';

  @override
  String get currencyCny => 'Yuan chinois';

  @override
  String get currencyRon => 'Leu roumain';

  @override
  String get currencyAed => 'Dirham des EAU';

  @override
  String get currencyBgn => 'Lev bulgare';

  @override
  String get currencyKwd => 'Dinar koweïtien';

  @override
  String get currencyTry => 'Livre turque';

  @override
  String get editCounterTitle => 'Modifier le compteur';

  @override
  String get resetCounterConfirm =>
      'Voulez-vous vraiment réinitialiser le compteur ?';

  @override
  String get imsakiyeTitle => 'Calendrier des prières';

  @override
  String get widgetRamadanName => 'Compte à rebours du Ramadan';

  @override
  String get widgetRamadanDesc =>
      'Carré : temps restant avant l\'iftar et la fin du suhoor ; hors Ramadan, jours restants avant son début';

  @override
  String widgetRamadanDay(String day) {
    return 'Ramadan · jour $day';
  }

  @override
  String get widgetRamadanUntil => 'Jours avant le Ramadan';

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
  String get nearbyMosquesTitle => 'Mosquées à proximité';

  @override
  String get toolNearbyMosquesDesc =>
      'Trouvez les mosquées les plus proches sur la carte';

  @override
  String get nearbyMosquesQuery => 'mosquée';

  @override
  String get nearbyMosquesError => 'Impossible d\'ouvrir la carte.';

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
    return '$name : le nombre à rattraper passera de $from à $to. Enregistrer ?';
  }

  @override
  String get shareFailed => 'L\'opération a échoué. Veuillez réessayer.';

  @override
  String get zakatCurrencyNote =>
      'Tous les montants sont en livres turques (₺).';

  @override
  String get zakatCashTry => 'Espèces (₺)';

  @override
  String get zakatRatesUnavailable =>
      'Les prix de l\'or et les taux de change actuels sont indisponibles. Veuillez saisir les prix vous-même.';

  @override
  String get zakatGoldGramPrice => 'Prix du gramme d\'or 24 carats (₺)';

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
  String get ramadanSahurLeft => 'Temps avant le suhoor';

  @override
  String get ramadanIftarLeft => 'Temps avant l\'iftar';

  @override
  String ramadanDayLabel(int day) {
    return 'Ramadan, jour $day';
  }
}
