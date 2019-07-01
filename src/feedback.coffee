scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      "Nutzen Sie mehrere Wöreter, vermeiden Sie typische Phrasen"
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
    extra_feedback = 'Fügen Sie ein Paar Wörter dazu, untypische Wörter sind besser'
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
          'Nacheinander folgende Tasten kann man leicht erraten'
        else
          'Kurze Tastatur Kombinationen kann man leicht erraten'
        warning: warning
        suggestions: [
          'Nutzen Sie eine längere Kombination, wenden Sie häufiger'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          'Wiederholende Buchstaben sind sehr leicht zu erraten'
        else
          'Wiederholungen wie "abcabcabc" sind unwessentlich besser als nur "abc"'
        warning: warning
        suggestions: [
          'Vermeiden Sie wiederholende Wörter und Buchstaben'
        ]

      when 'sequence'
        warning: "Sequenzen wie 6543 sind leicht zu erraten"
        suggestions: [
          'Vermeiden Sie Sequencen'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "Letze Jahre sind leicht zu erraten"
          suggestions: [
            'Vermeiden Sie letzte Jahre'
            'Vermeiden Sie Jahre die mit Ihnen verbunden sind'
          ]

      when 'date'
        warning: "Dates are often easy to guess"
        suggestions: [
          'Vermeiden Sie Daten die mit Ihnen verbunden sind'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'Das ist ein von sehr häufigste und einfachste Passwörter'
        else if match.rank <= 100
          'Das ist ein von häufigste Passwörter'
        else
          'Das ist ein von häufige Passwörter'
      else if match.guesses_log10 <= 4
        'Das ist sehr ähnlich zu einem sehr häufigen Password'
    else if match.dictionary_name in ['english_wikipedia', 'populaere']
      if is_sole_match
        'Das ist ein einfaches Wort'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names', 'vornamen', 'nachnamen']
      if is_sole_match
        'Namen und Vornamen selbst sind sehr leicht zu erraten'
      else
        'Häufige Namen sind leicht zu erraten'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "Große Buchstaben helfen nicht unbedingt"
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "Ein Passwort aus allen großen Buchstaben ist genau so leicht wie aus kleinen."

    if match.reversed and match.token.length >= 4
      suggestions.push "Rückwärts schreiben hilft nicht"
    if match.l33t
      suggestions.push "Wenn man a auf @ ersetzt u.ä. bleibt das Passwort leicht zu erraten"

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
