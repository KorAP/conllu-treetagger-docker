#!/usr/bin/perl
$\ = "\n";    # set output record separator

$FS    = "\t";
$,     = "\t";
$_     = &Getline0();
$word  = $Fld1;
$tag   = $Fld2;
$lemma = $Fld3;
$rest  = $FldRest;

while (<>) {
  chomp;    # strip record separator
  my @f = split( $FS, $_, -1 );
  $Fld1 = $f[0];
  $Fld2 = $f[1];
  $Fld3 = $f[2];
  $FldRest = (@f > 3) ? join("\t", @f[3..$#f]) : undef;
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
    print $word, $tag, $lemma, (defined $rest ? $rest : ());
  } elsif ($tag) {
    print $word, $tag, (defined $rest ? $rest : ());
  } else {
    print $word, (defined $rest ? $rest : ());
  }

  $word  = $Fld1;
  $tag   = $Fld2;
  $lemma = $Fld3;
  $rest  = $FldRest;
}

if ($lemma) {
  print $word, $tag, $lemma, (defined $rest ? $rest : ());
} elsif ($tag) {
  print $word, $tag, (defined $rest ? $rest : ());
} else {
  print $word, (defined $rest ? $rest : ());
}

sub Getline0 {
  if ( $getline_ok = ( ( $_ = <> ) ne '' ) ) {
    chomp;    # strip record separator
    my @f = split( $FS, $_, -1 );
    $Fld1 = $f[0];
    $Fld2 = $f[1];
    $Fld3 = $f[2];
    $FldRest = (@f > 3) ? join("\t", @f[3..$#f]) : undef;
  }
  $_;
}
