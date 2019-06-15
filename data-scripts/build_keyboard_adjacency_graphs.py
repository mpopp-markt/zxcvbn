#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import simplejson

def usage():
    return '''
constructs adjacency_graphs.coffee from QWERTY and DVORAK keyboard layouts

usage:
%s adjacency_graphs.coffee
''' % sys.argv[0]

qwerty = r'''
`~ 1! 2@ 3# 4$ 5% 6^ 7& 8* 9( 0) -_ =+
    qQ wW eE rR tT yY uU iI oO pP [{ ]} \|
     aA sS dD fF gG hH jJ kK lL ;: '"
      zZ xX cC vV bB nN mM ,< .> /?
'''

qwertz = r'''
^° 1! 2" 3§ 4$ 5% 6& 7/ 8( 9) 0= ß? ´`
    qQ wW eE rR tT zZ uU iI oO pP üÜ +*
     aA sS dD fF gG hH jJ kK lL öÖ äÄ #'
      yY xX cC vV bB nN mM ,; .: -_
'''.decode('utf-8')


qwertz_altgr = r'''
^′ 1¹ 2² 3³ 4¼ 5½ 6¬ 7{ 8[ 9] 0} ß\ ´¸
    q@ wł e€ r¶ tŧ z← u↓ i→ oø pþ ü¨ +~
     aæ sſ dð fđ gŋ hħ j̣ kĸ lł ö˝ ä^ #’
      y» x« c¢ v„ b“ n” mµ ,· .… -–
'''.decode('utf-8')

qwertz_altgr_shift = r'''
°′ !¹ "² §³ $¼ %½ &¬ /{ ([ )] =} ?\ `¸
    Q@ Wł E€ R¶ Tŧ Z← U↓ I→ Oø Pþ Ü¨ *~
     Aæ Sſ Dð Fđ Gŋ Hħ J̣ Kĸ Lł Ö˝ Ä^ '’
      Y» X« C¢ V„ B“ N” Mµ ;· :… _–
'''.decode('utf-8')

dvorak = r'''
`~ 1! 2@ 3# 4$ 5% 6^ 7& 8* 9( 0) [{ ]}
    '" ,< .> pP yY fF gG cC rR lL /? =+ \|
     aA oO eE uU iI dD hH tT nN sS -_
      ;: qQ jJ kK xX bB mM wW vV zZ
'''

keypad = r'''
  / * -
7 8 9 +
4 5 6
1 2 3
  0 .
'''

mac_keypad = r'''
  = / *
7 8 9 -
4 5 6 +
1 2 3
  0 .
'''

def get_slanted_adjacent_coords(x, y):
    '''
    returns the six adjacent coordinates on a standard keyboard, where each row is slanted to the
    right from the last. adjacencies are clockwise, starting with key to the left, then two keys
    above, then right key, then two keys below. (that is, only near-diagonal keys are adjacent,
    so g's coordinate is adjacent to those of t,y,b,v, but not those of r,u,n,c.)
    '''
    return [(x-1, y), (x, y-1), (x+1, y-1), (x+1, y), (x, y+1), (x-1, y+1)]

def get_aligned_adjacent_coords(x, y):
    '''
    returns the nine clockwise adjacent coordinates on a keypad, where each row is vert aligned.
    '''
    return [(x-1, y), (x-1, y-1), (x, y-1), (x+1, y-1), (x+1, y), (x+1, y+1), (x, y+1), (x-1, y+1)]

def build_graph(layout_str, slanted):
    '''
    builds an adjacency graph as a dictionary: {character: [adjacent_characters]}.
    adjacent characters occur in a clockwise order.
    for example:
    * on qwerty layout, 'g' maps to ['fF', 'tT', 'yY', 'hH', 'bB', 'vV']
    * on keypad layout, '7' maps to [None, None, None, '=', '8', '5', '4', None]
    '''
    position_table = {} # maps from tuple (x,y) -> characters at that position.
    tokens = layout_str.split()
    token_size = len(tokens[0])
    x_unit = token_size + 1 # x position unit len is token len plus 1 for the following whitespace.
    adjacency_func = get_slanted_adjacent_coords if slanted else get_aligned_adjacent_coords
    for token in tokens:
        if len(token) != token_size:
            print 'token len mismatch:\n ' + layout_str
    for y, line in enumerate(layout_str.split('\n')):
        # the way I illustrated keys above, each qwerty row is indented one space in from the last
        slant = y - 1 if slanted else 0
        for token in line.split():
            x, remainder = divmod(line.index(token) - slant, x_unit)
            if remainder != 0:
                print 'unexpected x offset for %s in:\n%s' % (token, layout_str)
            position_table[(x,y)] = token

    adjacency_graph = {}
    for (x,y), chars in position_table.iteritems():
        for char in chars:
            adjacency_graph[char] = []
            for coord in adjacency_func(x, y):
                # position in the list indicates direction
                # (for qwerty, 0 is left, 1 is top, 2 is top right, ...)
                # for edge chars like 1 or m, insert None as a placeholder when needed
                # so that each character in the graph has a same-length adjacency list.
                adjacency_graph[char].append(position_table.get(coord, None))
    return adjacency_graph

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print usage()
        sys.exit(0)
    with open(sys.argv[1], 'w') as f:
        f.write('# generated by scripts/build_keyboard_adjacency_graphs.py\n')
        f.write('adjacency_graphs = \n  ')
        lines = []
        for graph_name, args in [('qwerty', (qwerty, True)), 
                                 ('qwertz', (qwertz, True)), 
                                 ('qwertz_altgr', (qwertz_altgr, True)),
                                 ('qwertz_altgr_shift', (qwertz_altgr_shift, True)),
                                 ('dvorak', (dvorak, True)),
                                 ('keypad', (keypad, False)),
                                 ('mac_keypad', (mac_keypad, False))]:
            graph = build_graph(*args)
            lines.append('%s: %s' % (graph_name, simplejson.dumps(graph, sort_keys=True)))
        f.write('\n  '.join(lines))
        f.write('\n\n')
        f.write('module.exports = adjacency_graphs\n')
    sys.exit(0)

