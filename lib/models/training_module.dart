class TrainingModule {
  final String title;
  final String summary;
  final String content;

  const TrainingModule({
    required this.title,
    required this.summary,
    required this.content,
  });
}

const String usheringTrainingAuthor = "Buddy Bell";

const String usheringTrainingPlaceholder =
    "Content coming soon. Replace this placeholder with the real Ushering 101 material.";

const List<TrainingModule> usheringTrainingModules = [
  TrainingModule(
    title: "Module 1: Welcoming Guests",
    summary: "First impressions and a warm greeting",
    content: usheringTrainingPlaceholder,
  ),
  TrainingModule(
    title: "Module 2: Seating & Sanctuary Flow",
    summary: "Guiding guests to their seats smoothly",
    content: usheringTrainingPlaceholder,
  ),
  TrainingModule(
    title: "Module 3: Offering & Communion Procedures",
    summary: "Handling giving and communion with order",
    content: usheringTrainingPlaceholder,
  ),
  TrainingModule(
    title: "Module 4: Crowd & Traffic Management",
    summary: "Keeping entrances, aisles, and exits clear",
    content: usheringTrainingPlaceholder,
  ),
  TrainingModule(
    title: "Module 5: Emergency & Safety Procedures",
    summary: "What to do when something goes wrong",
    content: usheringTrainingPlaceholder,
  ),
  TrainingModule(
    title: "Module 6: Serving with the Right Heart",
    summary: "The spirit behind the service",
    content: usheringTrainingPlaceholder,
  ),
];
