import 'package:flutter/material.dart';

class BiblicalAvatar {
  final String id;
  final String title;
  final String subtitle;
  final String verse;
  final String verseText;
  final String assetPath;
  final Color accentColor;

  const BiblicalAvatar({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.verse,
    required this.verseText,
    required this.assetPath,
    required this.accentColor,
  });
}

const List<BiblicalAvatar> kBiblicalAvatars = [
  BiblicalAvatar(
    id: 'lion_of_judah',
    title: 'Lion of Judah',
    subtitle: 'Strength & Sovereignty',
    verse: 'Revelation 5:5',
    verseText: 'The Lion of the tribe of Judah, the Root of David, has triumphed.',
    assetPath: 'assets/images/biblical/lion_of_judah.jpg',
    accentColor: Color(0xFFD97706),
  ),
  BiblicalAvatar(
    id: 'sanctuary_doorkeeper',
    title: 'Sanctuary Doorkeeper',
    subtitle: 'Temple Usher Stewardship',
    verse: 'Psalm 84:10',
    verseText: 'I would rather be a doorkeeper in the house of my God than dwell in the tents of the wicked.',
    assetPath: 'assets/images/biblical/sanctuary_doorkeeper.jpg',
    accentColor: Color(0xFFC79540),
  ),
  BiblicalAvatar(
    id: 'dove_holy_spirit',
    title: 'Dove of Peace',
    subtitle: 'Holy Spirit & Grace',
    verse: 'Matthew 3:16',
    verseText: 'He saw the Spirit of God descending like a dove and lighting on him.',
    assetPath: 'assets/images/biblical/dove_holy_spirit.jpg',
    accentColor: Color(0xFF0EA5E9),
  ),
  BiblicalAvatar(
    id: 'good_shepherd',
    title: 'The Good Shepherd',
    subtitle: 'Pastoral Care & Love',
    verse: 'Psalm 23:1',
    verseText: 'The LORD is my shepherd; I shall not want.',
    assetPath: 'assets/images/biblical/good_shepherd.jpg',
    accentColor: Color(0xFF10B981),
  ),
  BiblicalAvatar(
    id: 'shield_of_faith',
    title: 'Shield of Faith',
    subtitle: 'Armor of God & Protection',
    verse: 'Ephesians 6:16',
    verseText: 'Take up the shield of faith, with which you can extinguish all flaming arrows.',
    assetPath: 'assets/images/biblical/shield_of_faith.jpg',
    accentColor: Color(0xFFF59E0B),
  ),
  BiblicalAvatar(
    id: 'cross_sunrise',
    title: 'Cross of Dawn',
    subtitle: 'Resurrection & Hope',
    verse: 'John 8:12',
    verseText: 'I am the light of the world. Whoever follows me will never walk in darkness.',
    assetPath: 'assets/images/biblical/cross_sunrise.jpg',
    accentColor: Color(0xFFE11D48),
  ),
  BiblicalAvatar(
    id: 'open_scripture',
    title: 'Word of Life',
    subtitle: 'Illuminated Holy Scripture',
    verse: 'Psalm 119:105',
    verseText: 'Your word is a lamp for my feet, a light on my path.',
    assetPath: 'assets/images/biblical/open_scripture.jpg',
    accentColor: Color(0xFF8B5CF6),
  ),
  BiblicalAvatar(
    id: 'crown_of_life',
    title: 'Crown of Righteousness',
    subtitle: 'Perseverance & Eternal Glory',
    verse: '2 Timothy 4:8',
    verseText: 'There is in store for me the crown of righteousness, awarded by the Lord.',
    assetPath: 'assets/images/biblical/crown_of_life.jpg',
    accentColor: Color(0xFFEAB308),
  ),
];
