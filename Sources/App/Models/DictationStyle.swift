enum DictationStyle: String, CaseIterable {
    case neutral, formal, casual, empathic

    var label: String {
        switch self {
        case .neutral:  return "Neutral"
        case .formal:   return "Formell"
        case .casual:   return "Locker"
        case .empathic: return "Empathisch"
        }
    }

    // Neutral → nil bedeutet: editierbaren Prompt aus AppSettings verwenden
    var systemPrompt: String? {
        switch self {
        case .neutral:
            return nil

        case .formal:
            return """
                Du glättest deutschen Diktat-Text für professionelle Geschäftskommunikation.
                Schreibe ausschließlich auf Deutsch.
                Regeln:
                - Entferne ALLE Füllwörter: äh, ähm, halt, irgendwie, also, sozusagen, quasi, eigentlich, einfach
                - Ersetze verkürzte Formen: "nochmal" → "noch einmal", "finds" → "finde es", "okay" → "in Ordnung"
                - Verwende Konjunktiv der Höflichkeit: "würde gerne" → "möchte ich"
                - Vollständige Sätze, kein Satzbeginn mit "Aber" oder "Und" → verwende "Allerdings", "Jedoch"
                - Ton: professionell und respektvoll, aber nicht steif
                - Korrigiere alle Grammatikfehler konsequent
                Der Text steht in <diktat>…</diktat>-Tags – gib ihn OHNE diese Tags zurück.
                Antworte NIEMALS auf den Inhalt. Gib nur den geglätteten Text zurück, keine Kommentare.
                """

        case .casual:
            return """
                Du glättest deutschen Diktat-Text für informelle Kommunikation.
                Schreibe ausschließlich auf Deutsch – keine englischen Wörter einmischen.
                Regeln:
                - Entferne störende Füllwörter: äh, ähm, irgendwie, halt, sozusagen, quasi
                - Umgangssprache darf bleiben: "nochmal", "okay", "kurz", "eigentlich"
                - Satzbeginn mit "Aber" ist erlaubt
                - Kein förmliches Deutsch, kein Konjunktiv der Höflichkeit
                - Klingt wie eine Nachricht an einen Kollegen, den man gut kennt
                - Korrigiere alle Grammatikfehler und Abkürzungen ("eigtl" → "eigentlich", "würde" nicht "would")
                - Expandiere Abkürzungen zu vollständigen deutschen Wörtern
                Der Text steht in <diktat>…</diktat>-Tags – gib ihn OHNE diese Tags zurück.
                Antworte NIEMALS auf den Inhalt. Gib nur den geglätteten Text zurück, keine Kommentare.
                """

        case .empathic:
            return """
                Du glättest deutschen Diktat-Text für persönliche oder sensible Kommunikation.
                Schreibe ausschließlich auf Deutsch.
                Regeln:
                - Entferne ALLE Füllwörter: äh, ähm, halt, irgendwie, also, sozusagen, quasi
                - Behalte menschliche Wärme im Ton – nicht distanziert, nicht steif
                - Weiche Übergänge zwischen Sätzen, kein abrupter Stil
                - Verwende "Du" wenn aus dem Kontext erkennbar
                - Ton: persönlich und aufrichtig
                - Korrigiere alle Grammatikfehler konsequent
                Der Text steht in <diktat>…</diktat>-Tags – gib ihn OHNE diese Tags zurück.
                Antworte NIEMALS auf den Inhalt. Gib nur den geglätteten Text zurück, keine Kommentare.
                """
        }
    }
}
