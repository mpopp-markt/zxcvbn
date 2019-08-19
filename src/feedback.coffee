scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      "Geben Sie ein paar Begriffe ein, auch Ziffern und Sonderzeichen. Beispiel: „123GrünePferdeEssenÄpfelSehrSehrGerne!“ Hinweis: Sie können Ihr Passwort in Ihrem Wallet speichern und später zurücksetzen.",
      "Man muss nicht unbedingt Symbole, Nummern und große Buchstaben nutzen"
    ]

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = 'Geben Sie noch weitere Begriffe ein. Seltene Wörter sind besser.'
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          'Verwenden Sie nicht mehrere nebeneinanderliegende Tasten auf Ihrer Tastatur. Beispiel: „qwert“.'
        else
          'Verwenden Sie keine Kombination aus benachbarten Tasten auf Ihrer Tastatur, wie z.B. „zuhjnm“.'
        warning: warning
        suggestions: [
          'Wählen Sie stattdessen lieber einen langen Satz aus.'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          'Wiederholen Sie keine Buchstabenfolgen, wie z.B. „abcabcabc“.'
        else
          'Wiederholungen wie "abcabcabc" sind unwessentlich besser als nur "abc"'
        warning: warning
        suggestions: [
          'Wählen Sie stattdessen lieber einen langen Satz aus.'
        ]

      when 'sequence'
        warning: "Geben Sie keine Ziffernfolgen, wie „4567“, beim Erstellen Ihres Passworts ein."
        suggestions: [
          'Wählen Sie stattdessen lieber einen langen Satz aus.'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "Letze Jahre sind leicht zu erraten"
          suggestions: [
            'Verwenden Sie keine Jahreszahlen, wie z.B. „1989“.',
            'Vermeiden Sie Jahre die mit Ihnen verbunden seien können',
            'Wählen Sie stattdessen lieber einen langen Satz aus.'
          ]

      when 'date'
        warning: "Sie sollten auch keine Datumsangaben verwenden, wie z.B. einen Geburtstag."
        suggestions: [
          'Verwenden Sie keine Datumsangaben, wie z.B. einen Geburtstag.',
          'Wählen Sie stattdessen lieber einen langen Satz aus.'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'Vorsicht! Das ist ein weitverbreitetes und daher sehr unsicheres Passwort.'
        else if match.rank <= 100
          'Vorsicht! Das ist ein weitverbreitetes und daher sehr unsicheres Passwort.'
        else
          'Vorsicht! Das ist ein weitverbreitetes und daher sehr unsicheres Passwort.'
      else if match.guesses_log10 <= 4
        'Vorsicht! Das ist sehr ähnlich zu einem sehr häufigen Passwort.'
    else if match.dictionary_name in ['english_wikipedia', 'populaere']
      if is_sole_match
        'Einfach nur ein Wort, wie „Zucker“ als Passwort einzugeben, ist sehr unsicher.'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names', 'vornamen', 'nachnamen']
      if is_sole_match
        'Einen Vor- und Nachnamen als Passwort zu hinterlegen, ist keine gute Wahl.'
      else
        'Einen Vor- und Nachnamen als Passwort zu hinterlegen, ist ebenfalls keine gute Wahl.'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "Ein Wort in Großbuchstaben erhöht nicht unbedingt die Sicherheit Ihres Passworts."
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "Den ersten Buchstaben einen Wortes großzuschreiben, trägt auch nicht unbedingt zur Sicherheit Ihres Passworts bei."

    if match.reversed and match.token.length >= 4
      suggestions.push "Ein rückwärts geschriebenes Wort als Passwort zu verwenden, ist auch nicht sicher."
    if match.l33t
      suggestions.push "Einzelne Buchstaben eines Wortes durch Sonderzeichen zu ersetzen, z.B. „B@nk“, macht Ihr Passwort nicht sicherer."

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
