" Test for commands that operate on the spellfile.

source shared.vim
source check.vim

CheckFeature spell
CheckFeature syntax

func Test_spell_normal()
  new
  call append(0, ['1 good', '2 goood', '3 goood'])
  set spell spellfile=./Xspellfile.add spelllang=en
  let oldlang=v:lang
  lang C

  " Test for zg
  1
  norm! ]s
  call assert_equal('2 goood', getline('.'))
  norm! zg
  1
  let a=execute('unsilent :norm! ]s')
  call assert_equal('1 good', getline('.'))
  call assert_equal('search hit BOTTOM, continuing at TOP', a[1:])
  let cnt=readfile('./Xspellfile.add')
  call assert_equal('goood', cnt[0])

  " Test for zw
  2
  norm! $zw
  1
  norm! ]s
  call assert_equal('2 goood', getline('.'))
  let cnt=readfile('./Xspellfile.add')
  call assert_equal('#oood', cnt[0])
  call assert_equal('goood/!', cnt[1])

  " Test for :spellrare
  spellrare rare
  let cnt=readfile('./Xspellfile.add')
  call assert_equal(['#oood', 'goood/!', 'rare/?'], cnt)

  " Make sure :spellundo works for rare words.
  spellundo rare
  let cnt=readfile('./Xspellfile.add')
  call assert_equal(['#oood', 'goood/!', '#are/?'], cnt)

  " Test for zg in visual mode
  let a=execute('unsilent :norm! V$zg')
  call assert_equal("Word '2 goood' added to ./Xspellfile.add", a[1:])
  1
  norm! ]s
  call assert_equal('3 goood', getline('.'))
  let cnt=readfile('./Xspellfile.add')
  call assert_equal('2 goood', cnt[3])
  " Remove "2 good" from spellfile
  2
  let a=execute('unsilent norm! V$zw')
  call assert_equal("Word '2 goood' added to ./Xspellfile.add", a[1:])
  let cnt=readfile('./Xspellfile.add')
  call assert_equal('2 goood/!', cnt[4])

  " Test for zG
  let a=execute('unsilent norm! V$zG')
  call assert_match("Word '2 goood' added to .*", a)
  let fname=matchstr(a, 'to\s\+\zs\f\+$')
  let cnt=readfile(fname)
  call assert_equal('2 goood', cnt[0])

  " Test for zW
  let a=execute('unsilent norm! V$zW')
  call assert_match("Word '2 goood' added to .*", a)
  let cnt=readfile(fname)
  call assert_equal('# goood', cnt[0])
  call assert_equal('2 goood/!', cnt[1])

  " Test for zuW
  let a=execute('unsilent norm! V$zuW')
  call assert_match("Word '2 goood' removed from .*", a)
  let cnt=readfile(fname)
  call assert_equal('# goood', cnt[0])
  call assert_equal('# goood/!', cnt[1])

  " Test for zuG
  let a=execute('unsilent norm! $zG')
  call assert_match("Word 'goood' added to .*", a)
  let cnt=readfile(fname)
  call assert_equal('# goood', cnt[0])
  call assert_equal('# goood/!', cnt[1])
  call assert_equal('goood', cnt[2])
  let a=execute('unsilent norm! $zuG')
  let cnt=readfile(fname)
  call assert_match("Word 'goood' removed from .*", a)
  call assert_equal('# goood', cnt[0])
  call assert_equal('# goood/!', cnt[1])
  call assert_equal('#oood', cnt[2])
  " word not found in wordlist
  let a=execute('unsilent norm! V$zuG')
  let cnt=readfile(fname)
  call assert_match("", a)
  call assert_equal('# goood', cnt[0])
  call assert_equal('# goood/!', cnt[1])
  call assert_equal('#oood', cnt[2])

  " Test for zug
  call delete('./Xspellfile.add')
  2
  let a=execute('unsilent norm! $zg')
  let cnt=readfile('./Xspellfile.add')
  call assert_equal('goood', cnt[0])
  let a=execute('unsilent norm! $zug')
  call assert_match("Word 'goood' removed from \./Xspellfile.add", a)
  let cnt=readfile('./Xspellfile.add')
  call assert_equal('#oood', cnt[0])
  " word not in wordlist
  let a=execute('unsilent norm! V$zug')
  call assert_match('', a)
  let cnt=readfile('./Xspellfile.add')
  call assert_equal('#oood', cnt[0])

  " Test for zuw
  call delete('./Xspellfile.add')
  2
  let a=execute('unsilent norm! Vzw')
  let cnt=readfile('./Xspellfile.add')
  call assert_equal('2 goood/!', cnt[0])
  let a=execute('unsilent norm! Vzuw')
  call assert_match("Word '2 goood' removed from \./Xspellfile.add", a)
  let cnt=readfile('./Xspellfile.add')
  call assert_equal('# goood/!', cnt[0])
  " word not in wordlist
  let a=execute('unsilent norm! $zug')
  call assert_match('', a)
  let cnt=readfile('./Xspellfile.add')
  call assert_equal('# goood/!', cnt[0])

  " add second entry to spellfile setting
  set spellfile=./Xspellfile.add,./Xspellfile2.add
  call delete('./Xspellfile.add')
  2
  let a=execute('unsilent norm! $2zg')
  let cnt=readfile('./Xspellfile2.add')
  call assert_match("Word 'goood' added to ./Xspellfile2.add", a)
  call assert_equal('goood', cnt[0])

  " Test for :spellgood!
  let temp = execute(':spe!0/0')
  call assert_match('Invalid region', temp)
  let spellfile = matchstr(temp, 'Invalid region nr in \zs.*\ze line \d: 0')
  call assert_equal(['# goood', '# goood/!', '#oood', '0/0'], readfile(spellfile))

  " Test for :spellrare!
  :spellrare! raare
  call assert_equal(['# goood', '# goood/!', '#oood', '0/0', 'raare/?'], readfile(spellfile))
  call delete(spellfile)

  " clean up
  exe "lang" oldlang
  call delete("./Xspellfile.add")
  call delete("./Xspellfile2.add")
  call delete("./Xspellfile.add.spl")
  call delete("./Xspellfile2.add.spl")

  " zux -> no-op
  2
  norm! $zux
  call assert_equal([], glob('Xspellfile.add',0,1))
  call assert_equal([], glob('Xspellfile2.add',0,1))

  set spellfile= spell& spelllang&
  bw!
endfunc

" Spell file content test. Write 'content' to the spell file prefixed by the
" spell file header and then enable spell checking. If 'emsg' is not empty,
" then check for error.
func Spellfile_Test(content, emsg)
  let splfile = './Xtest/spell/Xtest.utf-8.spl'
  " Add the spell file header and version (VIMspell2)
  let v = 0z56494D7370656C6C32 + a:content
  call writefile(v, splfile, 'b')
  set runtimepath=./Xtest
  set spelllang=Xtest
  if a:emsg != ''
    call assert_fails('set spell', a:emsg)
  else
    " FIXME: With some invalid spellfile contents, there are no error
    " messages. So don't know how to check for the test result.
    set spell
  endif
  set nospell spelllang& rtp&
endfunc

" Test for spell file format errors.
" The spell file format is described in spellfile.c
func Test_spellfile_format_error()
  let save_rtp = &rtp
  call mkdir('Xtest/spell', 'p')
  let splfile = './Xtest/spell/Xtest.utf-8.spl'

  " empty spell file
  call writefile([], splfile)
  set runtimepath=./Xtest
  set spelllang=Xtest
  call assert_fails('set spell', 'E757:')
  set nospell spelllang&

  " invalid file ID
  call writefile(0z56494D, splfile, 'b')
  set runtimepath=./Xtest
  set spelllang=Xtest
  call assert_fails('set spell', 'E757:')
  set nospell spelllang&

  " missing version number
  call writefile(0z56494D7370656C6C, splfile, 'b')
  set runtimepath=./Xtest
  set spelllang=Xtest
  call assert_fails('set spell', 'E771:')
  set nospell spelllang&

  " invalid version number
  call writefile(0z56494D7370656C6C7A, splfile, 'b')
  set runtimepath=./Xtest
  set spelllang=Xtest
  call assert_fails('set spell', 'E772:')
  set nospell spelllang&

  " no sections
  call Spellfile_Test(0z, 'E758:')

  " missing section length
  call Spellfile_Test(0z00, 'E758:')

  " unsupported required section
  call Spellfile_Test(0z7A0100000004, 'E770:')

  " unsupported not-required section
  call Spellfile_Test(0z7A0000000004, 'E758:')

  " SN_REGION: invalid number of region names
  call Spellfile_Test(0z0000000000FF, 'E759:')

  " SN_CHARFLAGS: missing <charflagslen> length
  call Spellfile_Test(0z010000000004, 'E758:')

  " SN_CHARFLAGS: invalid <charflagslen> length
  call Spellfile_Test(0z0100000000010201, '')

  " SN_CHARFLAGS: charflagslen == 0 and folcharslen != 0
  call Spellfile_Test(0z01000000000400000101, 'E759:')

  " SN_CHARFLAGS: missing <folcharslen> length
  call Spellfile_Test(0z01000000000100, 'E758:')

  " SN_PREFCOND: invalid prefcondcnt
  call Spellfile_Test(0z03000000000100, 'E759:')

  " SN_PREFCOND: invalid condlen
  call Spellfile_Test(0z0300000000020001, 'E759:')

  " SN_REP: invalid repcount
  call Spellfile_Test(0z04000000000100, 'E758:')

  " SN_REP: missing rep
  call Spellfile_Test(0z0400000000020004, 'E758:')

  " SN_REP: zero repfromlen
  call Spellfile_Test(0z040000000003000100, 'E759:')

  " SN_REP: invalid reptolen
  call Spellfile_Test(0z0400000000050001014101, '')

  " SN_REP: zero reptolen
  call Spellfile_Test(0z0400000000050001014100, 'E759:')

  " SN_SAL: missing salcount
  call Spellfile_Test(0z05000000000102, 'E758:')

  " SN_SAL: missing salfromlen
  call Spellfile_Test(0z050000000003080001, 'E758:')

  " SN_SAL: missing saltolen
  call Spellfile_Test(0z0500000000050400010161, 'E758:')

  " SN_WORDS: non-NUL terminated word
  call Spellfile_Test(0z0D000000000376696D, 'E758:')

  " SN_WORDS: very long word
  let v = eval('0z0D000000012C' .. repeat('41', 300))
  call Spellfile_Test(v, 'E759:')

  " SN_SOFO: missing sofofromlen
  call Spellfile_Test(0z06000000000100, 'E758:')

  " SN_SOFO: missing sofotolen
  call Spellfile_Test(0z06000000000400016100, 'E758:')

  " SN_SOFO: missing sofoto
  call Spellfile_Test(0z0600000000050001610000, 'E759:')

  " SN_COMPOUND: compmax is less than 2
  call Spellfile_Test(0z08000000000101, 'E759:')

  " SN_COMPOUND: missing compsylmax and other options
  call Spellfile_Test(0z0800000000020401, 'E759:')

  " SN_COMPOUND: missing compoptions
  call Spellfile_Test(0z080000000005040101, 'E758:')

  " SN_INFO: missing info
  call Spellfile_Test(0z0F0000000005040101, '')

  " SN_MIDWORD: missing midword
  call Spellfile_Test(0z0200000000040102, '')

  " SN_MAP: missing midword
  call Spellfile_Test(0z0700000000040102, '')

  " SN_SYLLABLE: missing SYLLABLE item
  call Spellfile_Test(0z0900000000040102, '')

  " SN_SYLLABLE: More than SY_MAXLEN size
  let v = eval('0z090000000022612F' .. repeat('62', 32))
  call Spellfile_Test(v, '')

  " LWORDTREE: missing
  call Spellfile_Test(0zFF, 'E758:')

  " LWORDTREE: missing tree node
  call Spellfile_Test(0zFF00000004, 'E758:')

  " LWORDTREE: missing tree node value
  call Spellfile_Test(0zFF0000000402, 'E758:')

  " KWORDTREE: missing tree node
  call Spellfile_Test(0zFF0000000000000004, 'E758:')

  " PREFIXTREE: missing tree node
  call Spellfile_Test(0zFF000000000000000000000004, 'E758:')

  let &rtp = save_rtp
  call delete('Xtest', 'rf')
endfunc

" Test for format errors in suggest file
func Test_sugfile_format_error()
  let save_rtp = &rtp
  call mkdir('Xtest/spell', 'p')
  let splfile = './Xtest/spell/Xtest.utf-8.spl'
  let sugfile = './Xtest/spell/Xtest.utf-8.sug'

  " create an empty spell file with a suggest timestamp
  call writefile(0z56494D7370656C6C320B00000000080000000000000044FF000000000000000000000000, splfile, 'b')

  " 'encoding' is set before each test to clear the previously loaded suggest
  " file from memory.

  " empty suggest file
  set encoding=utf-8
  call writefile([], sugfile)
  set runtimepath=./Xtest
  set spelllang=Xtest
  set spell
  call assert_fails("let s = spellsuggest('abc')", 'E778:')
  set nospell spelllang&

  " zero suggest version
  set encoding=utf-8
  call writefile(0z56494D73756700, sugfile)
  set runtimepath=./Xtest
  set spelllang=Xtest
  set spell
  call assert_fails("let s = spellsuggest('abc')", 'E779:')
  set nospell spelllang&

  " unsupported suggest version
  set encoding=utf-8
  call writefile(0z56494D7375671F, sugfile)
  set runtimepath=./Xtest
  set spelllang=Xtest
  set spell
  call assert_fails("let s = spellsuggest('abc')", 'E780:')
  set nospell spelllang&

  " missing suggest timestamp
  set encoding=utf-8
  call writefile(0z56494D73756701, sugfile)
  set runtimepath=./Xtest
  set spelllang=Xtest
  set spell
  call assert_fails("let s = spellsuggest('abc')", 'E781:')
  set nospell spelllang&

  " incorrect suggest timestamp
  set encoding=utf-8
  call writefile(0z56494D7375670100000000000000FF, sugfile)
  set runtimepath=./Xtest
  set spelllang=Xtest
  set spell
  call assert_fails("let s = spellsuggest('abc')", 'E781:')
  set nospell spelllang&

  " missing suggest wordtree
  set encoding=utf-8
  call writefile(0z56494D737567010000000000000044, sugfile)
  set runtimepath=./Xtest
  set spelllang=Xtest
  set spell
  call assert_fails("let s = spellsuggest('abc')", 'E782:')
  set nospell spelllang&

  let &rtp = save_rtp
  call delete('Xtest', 'rf')
endfunc

" Test for using :mkspell to create a spell file from a list of words
func Test_wordlist_dic()
  " duplicate encoding
  let lines =<< trim [END]
    # This is an example word list

    /encoding=latin1
    /encoding=latin1
    example
  [END]
  call writefile(lines, 'Xwordlist.dic')
  let output = execute('mkspell Xwordlist.spl Xwordlist.dic')
  call assert_match('Duplicate /encoding= line ignored in Xwordlist.dic line 4: /encoding=latin1', output)

  " multiple encoding for a word
  let lines =<< trim [END]
    example
    /encoding=latin1
    example
  [END]
  call writefile(lines, 'Xwordlist.dic')
  let output = execute('mkspell! Xwordlist.spl Xwordlist.dic')
  call assert_match('/encoding= line after word ignored in Xwordlist.dic line 2: /encoding=latin1', output)

  " unsupported encoding for a word
  let lines =<< trim [END]
    /encoding=Xtest
    example
  [END]
  call writefile(lines, 'Xwordlist.dic')
  let output = execute('mkspell! Xwordlist.spl Xwordlist.dic')
  call assert_match('Conversion in Xwordlist.dic not supported: from Xtest to utf-8', output)

  " duplicate region
  let lines =<< trim [END]
    /regions=usca
    /regions=usca
    example
  [END]
  call writefile(lines, 'Xwordlist.dic')
  let output = execute('mkspell! Xwordlist.spl Xwordlist.dic')
  call assert_match('Duplicate /regions= line ignored in Xwordlist.dic line 2: regions=usca', output)

  " maximum regions
  let lines =<< trim [END]
    /regions=uscauscauscauscausca
    example
  [END]
  call writefile(lines, 'Xwordlist.dic')
  let output = execute('mkspell! Xwordlist.spl Xwordlist.dic')
  call assert_match('Too many regions in Xwordlist.dic line 1: uscauscauscauscausca', output)

  " unsupported '/' value
  let lines =<< trim [END]
    /test=abc
    example
  [END]
  call writefile(lines, 'Xwordlist.dic')
  let output = execute('mkspell! Xwordlist.spl Xwordlist.dic')
  call assert_match('/ line ignored in Xwordlist.dic line 1: /test=abc', output)

  " unsupported flag
  let lines =<< trim [END]
    example/+
  [END]
  call writefile(lines, 'Xwordlist.dic')
  let output = execute('mkspell! Xwordlist.spl Xwordlist.dic')
  call assert_match('Unrecognized flags in Xwordlist.dic line 1: +', output)

  " non-ascii word
  call writefile(["ʀʀ"], 'Xwordlist.dic')
  let output = execute('mkspell! -ascii Xwordlist.spl Xwordlist.dic')
  call assert_match('Ignored 1 words with non-ASCII characters', output)

  call delete('Xwordlist.spl')
  call delete('Xwordlist.dic')
endfunc

" Test for the :mkspell command
func Test_mkspell()
  call assert_fails('mkspell Xtest_us.spl', 'E751:')
  call assert_fails('mkspell a b c d e f g h i j k', 'E754:')

  call writefile([], 'Xtest.spl')
  call writefile([], 'Xtest.dic')
  call assert_fails('mkspell Xtest.spl Xtest.dic', 'E13:')
  call delete('Xtest.spl')
  call delete('Xtest.dic')

  call mkdir('Xtest.spl')
  call assert_fails('mkspell! Xtest.spl Xtest.dic', 'E17:')
  call delete('Xtest.spl', 'rf')

  call assert_fails('mkspell en en_US abc_xyz', 'E755:')
endfunc

func Test_spell_add_word()
  set spellfile=
  call assert_fails('spellgood abc', 'E764:')

  set spellfile=Xtest.utf-8.add
  call assert_fails('2spellgood abc', 'E765:')

  edit Xtest.utf-8.add
  call setline(1, 'sample')
  call assert_fails('spellgood abc', 'E139:')
  set spellfile&
  %bw!
endfunc

" vim: shiftwidth=2 sts=2 expandtab
