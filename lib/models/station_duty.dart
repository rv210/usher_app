import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Individual duty or operational checklist item belonging to an usher station.
class StationDutyItem {
  final String id;
  final String stationId;
  final String title;
  final String summary;
  final List<String> detailedSteps;
  final List<String> supplies;
  final String timing; // e.g. "30 Min Pre-Service", "Pre-Service & Offering", "Post-Service"
  final IconData icon;
  final String category; // 'setup', 'hospitality', 'sanitation', 'ministry', 'facility'

  const StationDutyItem({
    required this.id,
    required this.stationId,
    required this.title,
    required this.summary,
    required this.detailedSteps,
    required this.supplies,
    required this.timing,
    required this.icon,
    this.category = 'setup',
  });
}

/// Represents an usher station post with its identity and associated duties.
class UsherStation {
  final String id;
  final String name;
  final String shortName;
  final String tagline;
  final IconData icon;
  final Color accentColor;
  final List<StationDutyItem> duties;

  const UsherStation({
    required this.id,
    required this.name,
    required this.shortName,
    required this.tagline,
    required this.icon,
    required this.accentColor,
    required this.duties,
  });
}

/// Master Registry containing detailed duties for all usher stations.
class UsherStationRegistry {
  // Station Identifiers
  static const String mainSanctuaryId = 'main_sanctuary';
  static const String vestibuleId = 'vestibule';
  static const String signsBathroomId = 'signs_bathroom';
  static const String petitionsId = 'petitions';
  static const String wtBreakdownId = 'wt_breakdown';

  // 1. MAIN SANCTUARY STATION
  static const UsherStation mainSanctuary = UsherStation(
    id: mainSanctuaryId,
    name: 'Main Sanctuary',
    shortName: 'Sanctuary',
    tagline: 'Altar, Seating, Tithes & Pastoral Support',
    icon: LucideIcons.church,
    accentColor: Color(0xFFD97706), // Warm Amber / Sanctuary Gold
    duties: [
      StationDutyItem(
        id: 'sanctuary_tissue',
        stationId: mainSanctuaryId,
        title: 'Tissue Setup',
        summary: 'Position fresh tissue boxes across all pews, pastoral seating, and altar perimeter.',
        timing: '30 Min Pre-Service',
        icon: LucideIcons.box,
        category: 'setup',
        supplies: [
          'Kleenex / Facial Tissue Boxes',
          'Spare Tissue Reserve (Storage Cabinet)',
          'Trash Bin Liners',
        ],
        detailedSteps: [
          'Inspect all sanctuary pew and chair rows from front to back.',
          'Place unopened or full tissue boxes neatly in designated rack holders or under-seat holders.',
          'Ensure pastoral front row and podium corners have fresh, premium tissue boxes within arm\'s reach.',
          'Position two tissue boxes at the left and right foot of the altar for prayer and ministry times.',
          'Discard any crushed, empty, or soiled boxes into pre-service waste bins.',
        ],
      ),
      StationDutyItem(
        id: 'sanctuary_tithe_table',
        stationId: mainSanctuaryId,
        title: 'Tithe Table',
        summary: 'Stage the tithe and offering station with collection buckets, envelopes, and secure placement.',
        timing: 'Pre-Service & Offering',
        icon: LucideIcons.badgeDollarSign,
        category: 'ministry',
        supplies: [
          'Offering Buckets / Baskets',
          'Tithe & Offering Envelopes',
          'Black Ballpoint Pens',
          'Offering Log Sheets / Secure Pouches',
        ],
        detailedSteps: [
          'Position the Tithe & Offering table at its designated sanctuary station before doors open.',
          'Stock envelope racks with fresh tithe and offering envelopes and working black pens.',
          'Inspect collection buckets/baskets to ensure velvet linings and handles are clean and intact.',
          'Coordinate with the Lead Usher regarding the offertory collection sequence and headcount count.',
          'Immediately after collection, accompany designated paired ushers to deposit offering in the church safe.',
        ],
      ),
      StationDutyItem(
        id: 'sanctuary_pastor_water',
        stationId: mainSanctuaryId,
        title: 'Pastor Water',
        summary: 'Prepare fresh chilled bottled water and crystal glass with saucer for pulpit and pastoral seats.',
        timing: '45 Min Pre-Service',
        icon: LucideIcons.droplets,
        category: 'hospitality',
        supplies: [
          'Chilled Bottled Water (Sealed)',
          'Room-Temperature Bottled Water',
          'Clean Crystal Glass / Coaster',
          'White Linen Napkin / Coaster Pad',
        ],
        detailedSteps: [
          'Check pastor preferences (chilled vs. room temperature water).',
          'Place two sealed bottles of water on the pulpit/podium shelf along with a pristine glass and saucer.',
          'Set one sealed water bottle and napkin at Senior Pastor and guest speaker front-row seats.',
          'Ensure bottle caps are unbroken to maintain sanitation and peace of mind.',
          'Discreetly check water levels during praise & worship; refresh or replace bottles during ministry transitions if needed.',
        ],
      ),
      StationDutyItem(
        id: 'sanctuary_spray_chair',
        stationId: mainSanctuaryId,
        title: 'Spray Chair',
        summary: 'Sanitize, wipe down, and align sanctuary seating rows before congregation doors open.',
        timing: '45 Min Pre-Service',
        icon: LucideIcons.sparkles,
        category: 'sanitation',
        supplies: [
          'Fabric / Vinyl Disinfectant Spray',
          'Microfiber Cleaning Cloths',
          'Glove Pair (Optional)',
        ],
        detailedSteps: [
          'Lightly mist and wipe down sanctuary chairs/pews starting from row 1 to the rear.',
          'Check upholstery and armrests for dust, smudges, debris, or sticky spots.',
          'Straighten chair rows to ensure neat, uniform aisle sightlines and required egress clearance.',
          'Verify that row connector clips or pew spacing are securely locked in place.',
          'Allow adequate drying time before doors open for the congregation.',
        ],
      ),
      StationDutyItem(
        id: 'sanctuary_mop',
        stationId: mainSanctuaryId,
        title: 'Mop Down Aisle/Altar',
        summary: 'Spot-clean, sweep, and mop main center aisles, side aisles, and the sacred altar stage area.',
        timing: '45 Min Pre-Service',
        icon: LucideIcons.brush,
        category: 'facility',
        supplies: [
          'Flat Microfiber Mop / Floor Cleaner',
          'Broom & Dustpan',
          'Yellow "Wet Floor" Warning Cone',
        ],
        detailedSteps: [
          'Sweep central main aisle, side aisles, and front altar stage to remove grit and stray dust.',
          'Damp mop the flooring with gentle wood/tile disinfectant cleaner.',
          'Focus on high-traffic threshold areas and the altar kneeling zone.',
          'Ensure the altar platform and aisles are completely dry and slip-free before worship team sound check and congregation arrival.',
          'Place wet floor warning cone if any dampness remains, removing it before doors officially open.',
        ],
      ),
    ],
  );

  // 2. VESTIBULE STATION
  static const UsherStation vestibule = UsherStation(
    id: vestibuleId,
    name: 'Vestibule',
    shortName: 'Vestibule',
    tagline: 'Foyer Hospitality, Guest Welcome & Sanitization',
    icon: LucideIcons.doorOpen,
    accentColor: Color(0xFF059669), // Emerald Welcome Green
    duties: [
      StationDutyItem(
        id: 'vestibule_welcome_table',
        stationId: vestibuleId,
        title: 'Welcome Table Setup',
        summary: 'Set up greeting table with bulletins, visitor connection cards, registration tablets, and gifts.',
        timing: '40 Min Pre-Service',
        icon: LucideIcons.table,
        category: 'hospitality',
        supplies: [
          'Sunday Service Bulletins / Programs',
          'First-Time Visitor Connection Cards',
          'Welcome Gift Bags / Packets',
          'Guest Check-In Tablet & Stylus',
          'Branded Pens',
        ],
        detailedSteps: [
          'Position Welcome Center table in prime vestibule foot-traffic line.',
          'Neatly arrange weekly bulletins, order of service pamphlets, and visitor packets.',
          'Verify that the Guest Check-In tablet is charged, connected to church Wi-Fi, and launched on the check-in screen.',
          'Keep pens tested and organized in display holder.',
          'Stand ready with warm smiles, eye contact, and sincere greetings for arriving congregants.',
        ],
      ),
      StationDutyItem(
        id: 'vestibule_hand_sanitizer',
        stationId: vestibuleId,
        title: 'Hand Sanitizer',
        summary: 'Verify and refill all automatic & manual hand sanitizer dispensers at every entrance foyer door.',
        timing: '30 Min Pre-Service',
        icon: LucideIcons.sprayCan,
        category: 'sanitation',
        supplies: [
          'Hand Sanitizer Refill Gel / Liquid',
          'Replacement C/D Batteries (for Auto Dispensers)',
          'Surface Disinfectant Wipes',
        ],
        detailedSteps: [
          'Test every hand sanitizer dispenser at the outer foyer doors and inner sanctuary doors.',
          'Refill empty or low reservoirs to at least 80% capacity.',
          'Wipe down dispenser nozzles and drip trays to eliminate residue buildup.',
          'Check battery indicators on touchless automatic units and replace batteries if sluggish.',
          'Ensure stand bases are stable and not wobbling.',
        ],
      ),
      StationDutyItem(
        id: 'vestibule_trash_can',
        stationId: vestibuleId,
        title: 'Trash Can',
        summary: 'Line all entryway bins with fresh heavy-duty bags and empty any pre-service waste.',
        timing: '30 Min Pre-Service & Post-Service',
        icon: LucideIcons.trash2,
        category: 'facility',
        supplies: [
          'Heavy-Duty Black Trash Liners',
          'Disinfectant Deodorizer Spray',
        ],
        detailedSteps: [
          'Empty all vestibule, foyer, and entrance waste receptacles prior to service start.',
          'Fit fresh trash liners neatly over bin rims without bulging or slipping.',
          'Spray bin lids with deodorizing disinfectant.',
          'Inspect trash levels midway through service and perform a final empty/re-line immediately post-service.',
        ],
      ),
      StationDutyItem(
        id: 'vestibule_sweep_mop',
        stationId: vestibuleId,
        title: 'Sweep/Mop',
        summary: 'Sweep and mop vestibule foyer floors, door thresholds, and vacuum/shake out entrance mats.',
        timing: '40 Min Pre-Service',
        icon: LucideIcons.sparkles,
        category: 'facility',
        supplies: [
          'Commercial Broom & Dustpan',
          'Fast-Drying Floor Mop & Bucket',
          'Entrance Mat Brush / Shaker',
        ],
        detailedSteps: [
          'Sweep entire foyer floor, corner to corner, gathering tracked-in outdoor dirt and leaves.',
          'Shake out or sweep entrance dirt-trap floor mats.',
          'Damp-mop tile/hardwood flooring with fast-drying neutral floor cleaner.',
          'Ensure thresholds and transitions between carpet and tile are free of tripping hazards.',
          'Confirm floors are 100% dry and safe before the doors are opened for congregants.',
        ],
      ),
    ],
  );

  // 3. SIGNS / BATHROOM STATION
  static const UsherStation signsBathroom = UsherStation(
    id: signsBathroomId,
    name: 'Signs/Bathroom',
    shortName: 'Signs & Bath',
    tagline: 'Directional Signage, Restrooms & Exterior Walkways',
    icon: LucideIcons.signpost,
    accentColor: Color(0xFF2563EB), // Royal Blue
    duties: [
      StationDutyItem(
        id: 'signs_inside_outside',
        stationId: signsBathroomId,
        title: 'Signs Inside/Outside',
        summary: 'Deploy exterior parking/entrance signs and stage interior directional pointers.',
        timing: '45 Min Pre-Service',
        icon: LucideIcons.signpost,
        category: 'facility',
        supplies: [
          'A-Frame Sidewalk Directional Signs',
          'Reserved / Guest Parking Cones & Signs',
          'Interior Easels / Restroom Pointers',
          'Handicap / Ramp Accessibility Signs',
        ],
        detailedSteps: [
          'Place exterior A-frame signs along church driveway, main walkway, and handicap parking zone.',
          'Verify that directional signage pointing toward Sanctuary, Children\'s Wing, and Restrooms is visible.',
          'Inspect signs for weather damage, tilt, or fallen placards; adjust firmly against wind.',
          'Confirm door entry signs (e.g. "Main Entrance", "Service at 10:00 AM") are mounted squarely.',
          'Pack up exterior signage safely at the conclusion of service wrap-up.',
        ],
      ),
      StationDutyItem(
        id: 'signs_bathroom_cleaner_caddy',
        stationId: signsBathroomId,
        title: 'Cleaner Caddy/Wipe Down Toilets/Hand Soap',
        summary: 'Stock caddy, sanitize toilets, wipe counters & mirrors, and replenish foaming hand soap.',
        timing: '40 Min Pre-Service & Mid-Service',
        icon: LucideIcons.sparkle,
        category: 'sanitation',
        supplies: [
          'Facility Cleaning Caddy',
          'Hospital-Grade Disinfectant Spray',
          'Foaming Hand Soap Refills',
          'Paper Towel Rolls & Commercial Toilet Paper',
          'Microfiber Restroom Towels & Gloves',
        ],
        detailedSteps: [
          'Take fully-stocked cleaner caddy through Men\'s, Women\'s, and Family restrooms.',
          'Spray and wipe down toilet seats, flush handles, stalls, sink faucets, and countertops.',
          'Check foaming hand soap dispensers; refill any bottles that are below 50% capacity.',
          'Restock paper towel dispensers and ensure two full backup toilet paper rolls in each stall.',
          'Empty restroom waste cans and replace with fresh liners.',
          'Conduct a quick mid-service check (approx. 25 minutes after service start) to ensure cleanliness.',
        ],
      ),
      StationDutyItem(
        id: 'signs_blower_walkway',
        stationId: signsBathroomId,
        title: 'Blower Outside Walkway',
        summary: 'Clear leaves, grass clippings, dirt, and debris from walkways, ramps, and exterior steps.',
        timing: '45 Min Pre-Service',
        icon: LucideIcons.wind,
        category: 'facility',
        supplies: [
          'Cordless / Gas Leaf Blower',
          'Ear Protection & Safety Goggles',
          'Outdoor Push Broom (for edges)',
        ],
        detailedSteps: [
          'Inspect blower battery charge or fuel level before heading outside.',
          'Blow off main entrance walkways, outdoor stairs, accessible ramps, and covered patio areas.',
          'Direct all leaves, mulch, twigs, and gravel away from church doors into landscape beds or collection bags.',
          'Ensure walkway is clean and clear of any slip or trip hazards (puddles, wet leaves, ice melt).',
          'Return blower to facility storage room, wipe off dust, and plug battery into charger.',
        ],
      ),
    ],
  );

  // 4. PETITIONS STATION
  static const UsherStation petitions = UsherStation(
    id: petitionsId,
    name: 'Petitions',
    shortName: 'Petitions',
    tagline: 'Prayer Petitions & God\'s Girls/Boys Youth Ministry Coordination',
    icon: LucideIcons.heartHandshake,
    accentColor: Color(0xFF9333EA), // Purple / Sacred Ministry
    duties: [
      StationDutyItem(
        id: 'petitions_gods_girls_boys',
        stationId: petitionsId,
        title: 'Set God\'s Girls/Boys Group',
        summary: 'Set up Petitions table, prepare prayer slips, and coordinate God\'s Girls & Boys youth ushering group.',
        timing: '35 Min Pre-Service & Altar Call',
        icon: LucideIcons.users,
        category: 'ministry',
        supplies: [
          'Prayer Petition Slips & Clipboards',
          'God\'s Girls / God\'s Boys Ministry Badges / Ribbons',
          'Petition Collection Baskets / Box',
          'Pens & Highlighters',
          'Youth Ushering Attendance Sheet',
        ],
        detailedSteps: [
          'Set up the Petitions table near the sanctuary entrance or designated prayer corridor.',
          'Stage neat stacks of printed Prayer Petition cards, pens, and clipboards.',
          'Meet with God\'s Girls and God\'s Boys youth group leaders and youth ushers for pre-service prayer and briefing.',
          'Assign youth group partners to their petition stations and explain their duties during altar call.',
          'During the prayer and altar call moment, support youth ushers as they collect filled petition slips.',
          'Ensure all collected petitions are organized respectfully and handed to the pastoral prayer team.',
        ],
      ),
    ],
  );

  /// All canonical stations list
  static const List<UsherStation> allStations = [
    mainSanctuary,
    vestibule,
    signsBathroom,
    petitions,
  ];

  /// Standard station names for dropdown menus across the app
  static const List<String> standardStationNames = [
    'Main Sanctuary',
    'Vestibule',
    'Signs/Bathroom',
    'Petitions',
    'WT Breakdown',
    'Custom...',
  ];

  /// Look up station by raw string name with fuzzy matching fallback
  static UsherStation getStationByName(String? name) {
    if (name == null || name.isEmpty) return mainSanctuary;
    final lower = name.toLowerCase().trim();

    if (lower.contains('sanctuary')) {
      return mainSanctuary;
    }
    if (lower.contains('vestibule') || lower.contains('greeter') || lower.contains('door')) {
      return vestibule;
    }
    if (lower.contains('sign') || lower.contains('bath') || lower.contains('restroom')) {
      return signsBathroom;
    }
    if (lower.contains('petition') || lower.contains('girl') || lower.contains('boy')) {
      return petitions;
    }

    return mainSanctuary;
  }

  /// Look up station by unique ID
  static UsherStation? getStationById(String id) {
    for (final s in allStations) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Get all duties for a given station name
  static List<StationDutyItem> getDutiesForStation(String stationName) {
    return getStationByName(stationName).duties;
  }

  /// Build a standardized SharedPreferences key for tracking duty checklist completion
  static String getChecklistPrefKey({
    required String stationId,
    required String dutyId,
    String? serviceDate,
  }) {
    final dateKey = serviceDate ?? 'today';
    return 'usher_duty_${stationId}_${dutyId}_$dateKey';
  }
}
