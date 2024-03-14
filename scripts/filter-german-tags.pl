#!/usr/bin/perl
$\ = "\n";    # set output record separator

$FS    = "\t";
$,     = "\t";
$_     = &Getline0();
$word  = $Fld1;
$tag   = $Fld2;
$lemma = $Fld3;

while (<>) {
  chomp;    # strip record separator
  ( $Fld1, $Fld2, $Fld3 ) = split( $FS, $_, -1 );
  if (
    (
         ( $tag =~ 'V.FIN' || $tag =~ 'V.INF' )
      && $Fld2 =~ "^[\$][.,]"
      && ( $word =~ "[erlu]n\$"
        && $word !~ "[^aeiou]e*ten\$" )
      && $word !~ '.zu.....'
    )
  ) {
    if ( $flag || $zu ) {
      if ( $tag eq 'VVFIN' ) {
        $tag = 'VVINF';
      } elsif ( $tag eq 'VAFIN' ) {
        $tag = 'VAINF';
      } elsif ( $tag eq 'VMFIN' ) {
        $tag = 'VMINF';
      }
    } else {
      if ( $tag eq 'VVINF' ) {
        $tag = 'VVFIN';
      } elsif ( $tag eq 'VAINF' ) {
        $tag = 'VAFIN';
      } elsif ( $tag eq 'VMINF' ) {
        $tag = 'VMFIN';
      }
    }
  }
  if ( $tag =~ "^V[VAM]FIN\$" ) {
    $flag = 1;
  }
  if ( $tag =~ "^[\$][.,]" ) {
    $flag = 0;
  }
  if ( $tag eq 'PTKZU' ) {
    $zu = 1;
  } else {
    $zu = 0;
  }

  if ($lemma) {
    print $word, $tag, $lemma;
  } elsif ($tag) {
    print $word, $tag;
  } else {
    print $word;
  }

  $word  = $Fld1;
  $tag   = $Fld2;
  $lemma = $Fld3;
}

if ($lemma) {
  print $word, $tag, $lemma;
} elsif ($tag) {
  print $word, $tag;
} else {
  print $word;
}

sub Getline0 {
  if ( $getline_ok = ( ( $_ = <> ) ne '' ) ) {
    chomp;    # strip record separator
    ( $Fld1, $Fld2, $Fld3 ) = split( $FS, $_, -1 );
  }
  $_;
}
