import 'package:anymex/utils/it_translations_data.dart';

/// Traduzione in italiano dell'interfaccia.
///
/// I testi dell'app sono scritti in inglese nel codice: al momento di
/// disegnarli vengono confrontati con il dizionario in
/// `it_translations_data.dart`. Se non c'è una corrispondenza esatta si provano
/// i modelli qui sotto (testi con numeri o nomi dentro); se non corrisponde
/// niente il testo resta com'è (titoli di anime, descrizioni, nomi propri).
final Map<String, String> _lowerIndex = {
  for (final e in itTranslations.entries) e.key.toLowerCase(): e.value,
};

typedef _Builder = String Function(Match m);

String _plural(String n, String one, String many) => n == '1' ? one : many;

final List<(RegExp, _Builder)> _patterns = [
  // numeri e quantità
  (RegExp(r'^Episodes? (\S+)$'), (m) => 'Episodio ${m[1]}'),
  (RegExp(r'^EP (\S+)$'), (m) => 'EP ${m[1]}'),
  (RegExp(r'^Chapter (\S+)$'), (m) => 'Capitolo ${m[1]}'),
  (RegExp(r'^Chapter (\S+) of (\d+)$'), (m) => 'Capitolo ${m[1]} di ${m[2]}'),
  (RegExp(r'^Ch\. ?(\S+)$'), (m) => 'Cap. ${m[1]}'),
  (RegExp(r'^Ch\. (.+) · (\d+) total$'),
      (m) => 'Cap. ${m[1]} · ${m[2]} in totale'),
  (RegExp(r'^Ep\. ?(\S+)$'), (m) => 'Ep. ${m[1]}'),
  (RegExp(r'^Season (\d+)$'), (m) => 'Stagione ${m[1]}'),
  (RegExp(r'^Page (\d+)$'), (m) => 'Pagina ${m[1]}'),
  (RegExp(r'^PAGE (\d+) / (\d+)$'), (m) => 'PAGINA ${m[1]} / ${m[2]}'),
  (RegExp(r'^Page (\d+) of (\d+)$'), (m) => 'Pagina ${m[1]} di ${m[2]}'),
  (RegExp(r'^(\d+) PAGES$'), (m) => '${m[1]} PAGINE'),
  (RegExp(r'^(\d+) pages$'), (m) => '${m[1]} pagine'),
  (RegExp(r'^(\d+) episodes?$'),
      (m) => '${m[1]} ${_plural(m[1]!, 'episodio', 'episodi')}'),
  (RegExp(r'^(\d+) eps$'), (m) => '${m[1]} ep.'),
  (RegExp(r'^(\d+) chapters?$'),
      (m) => '${m[1]} ${_plural(m[1]!, 'capitolo', 'capitoli')}'),
  (RegExp(r'^(\d+) Episodes?$'),
      (m) => '${m[1]} ${_plural(m[1]!, 'episodio', 'episodi')}'),
  (RegExp(r'^(\d+) Chapters?$'),
      (m) => '${m[1]} ${_plural(m[1]!, 'capitolo', 'capitoli')}'),
  (RegExp(r'^(\d+) titles$'), (m) => '${m[1]} titoli'),
  (RegExp(r'^(\d+) lists$'), (m) => '${m[1]} liste'),
  (RegExp(r'^(\d+) items?$'),
      (m) => '${m[1]} ${_plural(m[1]!, 'elemento', 'elementi')}'),
  (RegExp(r'^(\d+) items total$'), (m) => '${m[1]} elementi in totale'),
  (RegExp(r'^(\d+) selected$'),
      (m) => '${m[1]} ${_plural(m[1]!, 'selezionato', 'selezionati')}'),
  (RegExp(r'^(\d+) installed$'),
      (m) => '${m[1]} ${_plural(m[1]!, 'installato', 'installati')}'),
  (RegExp(r'^(\d+) available$'),
      (m) => '${m[1]} ${_plural(m[1]!, 'disponibile', 'disponibili')}'),
  (RegExp(r'^(\d+) chapters available$'),
      (m) => '${m[1]} capitoli disponibili'),
  (RegExp(r'^(\d+) episodes available$'),
      (m) => '${m[1]} episodi disponibili'),
  (RegExp(r'^(\d+) unread$'), (m) => '${m[1]} non letti'),
  (RegExp(r'^(\d+) comments?$'),
      (m) => '${m[1]} ${_plural(m[1]!, 'commento', 'commenti')}'),
  (RegExp(r'^(\d+) Comments?$'),
      (m) => '${m[1]} ${_plural(m[1]!, 'commento', 'commenti')}'),
  (RegExp(r'^(\d+) comments loaded$'), (m) => '${m[1]} commenti caricati'),
  (RegExp(r'^(\d+) pending reports?$'),
      (m) => '${m[1]} segnalazioni in sospeso'),
  (RegExp(r'^(\d+) recommendations?$'),
      (m) => '${m[1]} ${_plural(m[1]!, 'consiglio', 'consigli')}'),
  (RegExp(r'^(\d+) imported theme\(s\)$'), (m) => '${m[1]} temi importati'),
  (RegExp(r'^(\d+) commits?$'),
      (m) => '${m[1]} ${_plural(m[1]!, 'commit', 'commit')}'),
  (RegExp(r'^(\d+) repos?$'),
      (m) => '${m[1]} ${_plural(m[1]!, 'repository', 'repository')}'),
  (RegExp(r'^(\d+) behind$'), (m) => '${m[1]} indietro'),
  (RegExp(r'^(\d+) missing chapters?$'),
      (m) => '${m[1]} ${_plural(m[1]!, 'capitolo mancante', 'capitoli mancanti')}'),
  (RegExp(r'^(\d+) pts$'), (m) => '${m[1]} pt'),
  (RegExp(r'^(\d+) min read \((\d+) chs\)$'),
      (m) => '${m[1]} min di lettura (${m[2]} cap.)'),
  (RegExp(r'^(\d+) min watch \((\d+) eps\)$'),
      (m) => '${m[1]} min di visione (${m[2]} ep.)'),
  (RegExp(r'^(\d+) mins total$'), (m) => '${m[1]} min in totale'),
  (RegExp(r'^(\d+)/(\d+) members$'), (m) => '${m[1]}/${m[2]} membri'),
  (RegExp(r'^(\d+) / (\d+) members$'), (m) => '${m[1]} / ${m[2]} membri'),
  (RegExp(r'^Watched (\d+) of (\d+)$'),
      (m) => 'Guardati ${m[1]} di ${m[2]}'),
  (RegExp(r'^Total entries: (\d+)$'), (m) => 'Voci totali: ${m[1]}'),
  (RegExp(r'^Total Lists: (\d+)$'), (m) => 'Liste totali: ${m[1]}'),
  (RegExp(r'^Items: (\d+)$'), (m) => 'Elementi: ${m[1]}'),
  (RegExp(r'^Threshold: (.+)$'), (m) => 'Soglia: ${m[1]}'),
  (RegExp(r'^Reason: (.+)$'), (m) => 'Motivo: ${m[1]}'),
  (RegExp(r'^Joined (\d{4})$'), (m) => 'Iscritto nel ${m[1]}'),
  (RegExp(r'^Joined room (.+)!$'), (m) => 'Sei entrato nella stanza ${m[1]}!'),
  (RegExp(r'^Joining room (.+)\.\.\.$'),
      (m) => 'Ingresso nella stanza ${m[1]}...'),
  (RegExp(r'^Room (\S+) is private$'),
      (m) => 'La stanza ${m[1]} è privata'),
  (RegExp(r'^(.+) joined the party$'), (m) => '${m[1]} è entrato nella party'),
  (RegExp(r'^(.+) left the party$'), (m) => '${m[1]} è uscito dalla party'),
  (RegExp(r'^Kicked (.+)$'), (m) => '${m[1]} è stato espulso'),
  (RegExp(r'^Episode (\S+) Airing In$'),
      (m) => 'Episodio ${m[1]} in onda tra'),
  (RegExp(r'^EPISODE (\S+) RELEASES IN$'),
      (m) => 'EPISODIO ${m[1]} ESCE TRA'),
  // tempo
  (RegExp(r'^(\d+) minutes?$'), (m) => '${m[1]} ${_plural(m[1]!, 'minuto', 'minuti')}'),
  (RegExp(r'^(\d+) days? ago$'), (m) => '${m[1]} ${_plural(m[1]!, 'giorno', 'giorni')} fa'),
  (RegExp(r'^(\d+) hours? ago$'), (m) => '${m[1]} ${_plural(m[1]!, 'ora', 'ore')} fa'),
  (RegExp(r'^(\d+) mins? ago$'), (m) => '${m[1]} min fa'),
  (RegExp(r'^(\d+)m ago$'), (m) => '${m[1]} min fa'),
  (RegExp(r'^(\d+)h ago$'), (m) => '${m[1]} h fa'),
  (RegExp(r'^(\d+)d ago$'), (m) => '${m[1]} g fa'),
  (RegExp(r'^Welcome back, (.+)$'), (m) => 'Bentornato, ${m[1]}'),
  // elenchi con conteggio
  (RegExp(r'^All \((\d+)\)$'), (m) => 'Tutti (${m[1]})'),
  (RegExp(r'^Movies \((\d+)\)$'), (m) => 'Film (${m[1]})'),
  (RegExp(r'^Shows \((\d+)\)$'), (m) => 'Serie (${m[1]})'),
  (RegExp(r'^Chapters \((\d+)\)$'), (m) => 'Capitoli (${m[1]})'),
  (RegExp(r'^Subtitles \((\d+)\)$'), (m) => 'Sottotitoli (${m[1]})'),
  (RegExp(r'^Audio Tracks \((\d+)\)$'), (m) => 'Tracce audio (${m[1]})'),
  (RegExp(r'^Tracks \((\d+)\)$'), (m) => 'Tracce (${m[1]})'),
  (RegExp(r'^Replies \((\d+)\)$'), (m) => 'Risposte (${m[1]})'),
  (RegExp(r'^Followers \((\d+)\)$'), (m) => 'Follower (${m[1]})'),
  (RegExp(r'^Following \((\d+)\)$'), (m) => 'Seguiti (${m[1]})'),
  (RegExp(r'^Mutual Followers \((\d+)\)$'),
      (m) => 'Follower in comune (${m[1]})'),
  (RegExp(r'^Shared Following \((\d+)\)$'),
      (m) => 'Seguiti in comune (${m[1]})'),
  (RegExp(r'^Delete Selected \((\d+)\)$'),
      (m) => 'Elimina selezionati (${m[1]})'),
  (RegExp(r'^DONE \((\d+) selected\)$'), (m) => 'FATTO (${m[1]} selezionati)'),
  (RegExp(r'^Show more replies \((\d+)\)$'),
      (m) => 'Mostra altre risposte (${m[1]})'),
  (RegExp(r'^\[\+\] (\d+) replies collapsed$'),
      (m) => '[+] ${m[1]} risposte nascoste'),
  (RegExp(r'^Download (\d+) Chapters?$'),
      (m) => 'Scarica ${m[1]} ${_plural(m[1]!, 'capitolo', 'capitoli')}'),
  (RegExp(r'^Download (\d+) Episodes?$'),
      (m) => 'Scarica ${m[1]} ${_plural(m[1]!, 'episodio', 'episodi')}'),
  (RegExp(r'^Drag to reorder · (\d+) items$'),
      (m) => 'Trascina per riordinare · ${m[1]} elementi'),
  (RegExp(r'^Skipped (\d+) filler episodes?$'),
      (m) => 'Saltati ${m[1]} episodi filler'),
  // azioni con un nome dentro
  (RegExp(r'^(.+) Settings$'), (m) => 'Impostazioni di ${m[1]}'),
  (RegExp(r'^(.+) Section Order$'),
      (m) => 'Ordine delle sezioni ${itr(m[1]!)}'),
  (RegExp(r'^(.+) installed successfully$'),
      (m) => '${m[1]} installato con successo'),
  (RegExp(r'^(.+) uninstalled$'), (m) => '${m[1]} disinstallato'),
  (RegExp(r'^(.+) updated successfully$'),
      (m) => '${m[1]} aggiornato con successo'),
  (RegExp(r'^Install (.+)$'), (m) => 'Installa ${m[1]}'),
  (RegExp(r'^Uninstall (.+)$'), (m) => 'Disinstalla ${m[1]}'),
  (RegExp(r'^(.+) copied$'), (m) => '${m[1]} copiato'),
  (RegExp(r'^Reply to (.+)$'), (m) => 'Rispondi a ${m[1]}'),
  (RegExp(r'^Replying to (.+)$'), (m) => 'In risposta a ${m[1]}'),
  (RegExp(r"^(.+)'s Comments$"), (m) => 'Commenti di ${m[1]}'),
  (RegExp(r'^Manage User: (.+)$'), (m) => 'Gestisci utente: ${m[1]}'),
  (RegExp(r'^Search (.+)\.\.\.$'), (m) => 'Cerca ${m[1]}...'),
  (RegExp(r'^No results found for "(.+)"$'),
      (m) => 'Nessun risultato per "${m[1]}"'),
  (RegExp(r'^Recommend "(.+)"$'), (m) => 'Consiglia "${m[1]}"'),
  (RegExp(r'^Connect to (.+)$'), (m) => 'Collegati a ${m[1]}'),
  (RegExp(r'^Connected to (.+)$'), (m) => 'Collegato a ${m[1]}'),
  (RegExp(r'^Fetching (.+)\.\.\.$'), (m) => 'Recupero di ${m[1]}...'),
  (RegExp(r'^Loading page (.+)\.\.\.$'),
      (m) => 'Caricamento della pagina ${m[1]}...'),
  (RegExp(r'^Subtitle loaded: (.+)$'),
      (m) => 'Sottotitoli caricati: ${m[1]}'),
  (RegExp(r'^Saved to (.+)$'), (m) => 'Salvato in ${m[1]}'),
  (RegExp(r'^Page saved to (.+)$'), (m) => 'Pagina salvata in ${m[1]}'),
  (RegExp(r'^Removed "(.+)"$'), (m) => 'Rimosso "${m[1]}"'),
  (RegExp(r'^Deleted "(.+)"$'), (m) => 'Eliminato "${m[1]}"'),
  (RegExp(r'^Created · (.+)$'), (m) => 'Creata · ${m[1]}'),
  (RegExp(r'^Message (.+)$'), (m) => 'Scrivi a ${m[1]}'),
  (RegExp(r'^Error: (.+)$'), (m) => 'Errore: ${m[1]}'),
  (RegExp(r'^Download failed: (.+)$'),
      (m) => 'Download non riuscito: ${m[1]}'),
  (RegExp(r'^Sync failed: (.+)$'),
      (m) => 'Sincronizzazione non riuscita: ${m[1]}'),
  (RegExp(r'^Backup failed: (.+)$'),
      (m) => 'Backup non riuscito: ${m[1]}'),
  (RegExp(r'^Restore failed: (.+)$'),
      (m) => 'Ripristino non riuscito: ${m[1]}'),
  (RegExp(r'^Search failed: (.+)$'),
      (m) => 'Ricerca non riuscita: ${m[1]}'),
  (RegExp(r'^Export failed: (.+)$'),
      (m) => 'Esportazione non riuscita: ${m[1]}'),
  (RegExp(r'^Factory reset failed: (.+)$'),
      (m) => 'Ripristino di fabbrica non riuscito: ${m[1]}'),
  (RegExp(r'^Failed to check for updates: (.+)$'),
      (m) => 'Impossibile cercare aggiornamenti: ${m[1]}'),
  (RegExp(r'^Failed to clear cache: (.+)$'),
      (m) => 'Impossibile svuotare la cache: ${m[1]}'),
  (RegExp(r'^Failed to copy: (.+)$'),
      (m) => 'Impossibile copiare: ${m[1]}'),
  (RegExp(r'^Failed to join room: (.+)$'),
      (m) => 'Impossibile entrare nella stanza: ${m[1]}'),
  (RegExp(r'^Failed to post message: (.+)$'),
      (m) => 'Impossibile inviare il messaggio: ${m[1]}'),
  (RegExp(r'^Failed to save page: (.+)$'),
      (m) => 'Impossibile salvare la pagina: ${m[1]}'),
  (RegExp(r'^Failed to share page: (.+)$'),
      (m) => 'Impossibile condividere la pagina: ${m[1]}'),
  (RegExp(r'^Failed to add repo: (.+)$'),
      (m) => 'Impossibile aggiungere il repository: ${m[1]}'),
  (RegExp(r'^Are you sure you want to delete (.+)\? This action cannot be undone\.$'),
      (m) => 'Vuoi davvero eliminare ${itr(m[1]!)}? Questa azione non può essere annullata.'),
  (RegExp(r'^Are you sure you want to delete (.+)\?$'),
      (m) => 'Vuoi davvero eliminare ${itr(m[1]!)}?'),
  (RegExp(r'^Are you sure you want to remove "(.+)" from your history\?$'),
      (m) => 'Vuoi davvero rimuovere "${m[1]}" dalla cronologia?'),
  (RegExp(r'^(.+) will be permanently removed from your downloads\.$'),
      (m) => '${itr(m[1]!)} verrà rimosso definitivamente dai download.'),
  (RegExp(r'^Chapter (\S+) is downloaded$'),
      (m) => 'Capitolo ${m[1]} scaricato'),
  (RegExp(r'^Episode (\S+) is downloaded$'),
      (m) => 'Episodio ${m[1]} scaricato'),
];

bool _isUpper(String s) =>
    s == s.toUpperCase() && s != s.toLowerCase() && s.length > 1;

/// Restituisce la versione italiana di [text], se esiste.
String itr(String text) {
  if (text.isEmpty) return text;
  final direct = itTranslations[text];
  if (direct != null) return direct;

  final trimmed = text.trim();
  if (trimmed.isEmpty) return text;
  if (trimmed != text) {
    final t = itr(trimmed);
    if (t != trimmed) {
      final lead = text.substring(0, text.indexOf(trimmed));
      final trail = text.substring(lead.length + trimmed.length);
      return '$lead$t$trail';
    }
    return text;
  }

  final lower = _lowerIndex[trimmed.toLowerCase()];
  if (lower != null) {
    return _isUpper(trimmed) ? lower.toUpperCase() : lower;
  }

  for (final (pattern, build) in _patterns) {
    final m = pattern.firstMatch(trimmed);
    if (m != null) return build(m);
  }
  return text;
}
