class TutorMessage {
  TutorMessage(this.me, this.text, {DateTime? at}) : at = at ?? DateTime.now();
  final bool me;
  final String text;
  final DateTime at;
}
