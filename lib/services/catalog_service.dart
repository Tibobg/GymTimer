import '../models/exercise.dart';

class CatalogService {
  static final List<Exercise> _exercises = [
    // Jambes
    Exercise(
      id: 'leg_press',
      name: 'Leg press',
      category: 'Jambes',
      imageAsset: 'assets/exos/LegPress.png',
      defaultWeight: 100,
    ),
    Exercise(
      id: 'leg_extension',
      name: 'Leg extension',
      category: 'Jambes',
      imageAsset: 'assets/exos/LegExtension.png',
      defaultWeight: 30,
    ),
    Exercise(
      id: 'leg_curl',
      name: 'Leg curl',
      category: 'Jambes',
      imageAsset: 'assets/exos/LegCurl.png',
      defaultWeight: 35,
    ),
    Exercise(
      id: 'hip_thrust',
      name: 'Hip thrust smith machine',
      category: 'Jambes',
      imageAsset: 'assets/exos/HipThrustSmithMachine.png',
      defaultWeight: 55,
    ),
    Exercise(
      id: 'adductor',
      name: 'Adductor',
      category: 'Jambes',
      imageAsset: 'assets/exos/Adductor.png',
      defaultWeight: 55,
    ),
    Exercise(
      id: 'abductor',
      name: 'Abductor',
      category: 'Jambes',
      imageAsset: 'assets/exos/Abductor.png',
      defaultWeight: 55,
    ),
    Exercise(
      id: 'mollet_press',
      name: 'Mollet press',
      category: 'Jambes',
      imageAsset: 'assets/exos/MolletPress.png',
      defaultWeight: 90,
    ),
    // Pectoraux
    Exercise(
      id: 'dev_incline_hal',
      name: 'Développé incliné haltères',
      category: 'Pectoraux',
      imageAsset: 'assets/exos/DeveloppeInclineHalteres.png',
      defaultWeight: 14,
    ),
    Exercise(
      id: 'chest_press',
      name: 'Chest press',
      category: 'Pectoraux',
      imageAsset: 'assets/exos/ChestPress.png',
      defaultWeight: 35,
    ),
    Exercise(
      id: 'dev_decline_hal',
      name: 'Développé décliné haltères',
      category: 'Pectoraux',
      imageAsset: 'assets/exos/DeveloppeDeclineHalteres.png',
      defaultWeight: 14,
    ),
    Exercise(
      id: 'ecarte_poulie',
      name: 'Ecarté poulie',
      category: 'Pectoraux',
      imageAsset: 'assets/exos/EcartePoulie.png',
      defaultWeight: 7.5,
    ),
    // Dos
    Exercise(
      id: 'tirage_vert',
      name: 'Tirage vertical serré',
      category: 'Dos',
      imageAsset: 'assets/exos/TirageVertical.png',
      defaultWeight: 45,
    ),
    Exercise(
      id: 'rowing_uni',
      name: 'Rowing unilatéral haltère',
      category: 'Dos',
      imageAsset: 'assets/exos/RowingUnilateralHaltere.png',
      defaultWeight: 12,
    ),
    Exercise(
      id: 'low_row',
      name: 'Low row',
      category: 'Dos',
      imageAsset: 'assets/exos/LowRow.png',
      defaultWeight: 40,
    ),
    Exercise(
      id: 'tirage_horiz',
      name: 'Tirage horizontal',
      category: 'Dos',
      imageAsset: 'assets/exos/TirageHorizontal.png',
      defaultWeight: 35,
    ),
    // Épaules
    Exercise(
      id: 'shoulder_press',
      name: 'Shoulder press',
      category: 'Épaules',
      imageAsset: 'assets/exos/ShoulderPress.png',
      defaultWeight: 25,
    ),
    Exercise(
      id: 'ele_lat_hal',
      name: 'Élévations latérales haltères',
      category: 'Épaules',
      imageAsset: 'assets/exos/ElevationsLateralesHalteres.png',
      defaultWeight: 8,
    ),
    Exercise(
      id: 'ele_front_hal',
      name: 'Élévations frontales haltères',
      category: 'Épaules',
      defaultWeight: 8,
    ),
    Exercise(
      id: 'oiseau_incline',
      name: 'Oiseau incliné',
      category: 'Épaules',
      imageAsset: 'assets/exos/OiseauIncline.png',
      defaultWeight: 8,
    ),
    Exercise(
      id: 'shrugs',
      name: 'Shrugs haltères',
      category: 'Épaules',
      imageAsset: 'assets/exos/ShrugsHalteres.png',
      defaultWeight: 18,
    ),
    // Biceps
    Exercise(
      id: 'curl_incline',
      name: 'Curl incliné banc 45°',
      category: 'Biceps',
      imageAsset: 'assets/exos/CurlInclineBanc.png',
      defaultWeight: 10,
    ),
    Exercise(
      id: 'curl_marteau',
      name: 'Curl marteau',
      category: 'Biceps',
      imageAsset: 'assets/exos/CurlMarteau.png',
      defaultWeight: 6,
    ),
    Exercise(
      id: 'curl_poulie_basse',
      name: 'Curl à la poulie basse',
      category: 'Biceps',
      imageAsset: 'assets/exos/CurlALaPoulieBasse.png',
      defaultWeight: 15,
    ),
    Exercise(
      id: 'curl_inverse',
      name: 'Curl inversé poulie',
      category: 'Biceps',
      imageAsset: 'assets/exos/CurlInversePoulie.png',
      defaultWeight: 4,
    ),
    // Triceps
    Exercise(
      id: 'overhead_poulie',
      name: 'Overhead poulie',
      category: 'Triceps',
      imageAsset: 'assets/exos/OverheadPoulie.png',
      defaultWeight: 2,
    ),
    Exercise(
      id: 'poulie_barre',
      name: 'Poulie barre',
      category: 'Triceps',
      imageAsset: 'assets/exos/PoulieBarre.png',
      defaultWeight: 7,
    ),
    Exercise(
      id: 'poulie_corde',
      name: 'Poulie corde',
      category: 'Triceps',
      imageAsset: 'assets/exos/PoulieCorde.png',
      defaultWeight: 4,
    ),
    Exercise(
      id: 'poulie_mousqueton',
      name: 'Poulie mousqueton côté',
      category: 'Triceps',
      imageAsset: 'assets/exos/ExtensionUneMain.png',
      defaultWeight: 2,
    ),
    // Avant-bras
    Exercise(
      id: 'curl_conc_prone',
      name: 'Curl concentration pronation',
      category: 'Avant-bras',
      imageAsset: 'assets/exos/CurlInclineBanc.png',
      defaultWeight: 10,
    ),
    Exercise(
      id: 'flex_poignet_dos',
      name: 'Flexions du poignet derrière le dos',
      category: 'Avant-bras',
      imageAsset: 'assets/exos/CurlMarteau.png',
      defaultWeight: 6,
    ),
    Exercise(
      id: 'ext_poignet',
      name: 'Extension du poignet',
      category: 'Avant-bras',
      imageAsset: 'assets/exos/CurlALaPoulieBasse.png',
      defaultWeight: 15,
    ),
    Exercise(
      id: 'rot_poignet',
      name: 'Rotations du poignet',
      category: 'Avant-bras',
      imageAsset: 'assets/exos/CurlInversePoulie.png',
      defaultWeight: 4,
    ),
    // Abdos
    Exercise(
      id: 'circuit_abdos',
      name: 'Circuit Abdos',
      category: 'Abdos',
      mediaUrl: 'https://youtu.be/dQw4w9WgXcQ',
    ),
  ];

  static List<Exercise> get all => List.unmodifiable(_exercises);
  static List<String> get categories =>
      _exercises.map((e) => e.category).toSet().toList()..sort();
  static List<Exercise> byCategory(String cat) =>
      _exercises.where((e) => e.category == cat).toList();
  static Exercise? byId(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
