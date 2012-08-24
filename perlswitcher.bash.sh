#!/bin/bash

# First created: 2012-05-08
# Last modified: 2012-08-24T06:57:25 UTC-04:00
# This following doesn't work:
# $ bind -x '"\C-o"':'"_toggle_perlinstance"\C-M'
#  ...but I created an inputrc file with this line
# and all works fine using that approach:
# .inputrc line: "\C-o":"\C-M _toggle_perlinstance\C-M"

declare PEIR=/usr/bin/perl
declare +x _Save_IFS=$IFS
  IFS=$'\t'
  declare +x _Saved_PS1=$(printf '%s' $PS1)
  declare -r _Saved_PS1  # readonly
IFS="$_Save_IFS"

# Boilerplate
# Track source-ing of this script in global array var BASH_STARTUP_SCRIPT
shopt -s extdebug extglob
declare -x -a BASH_STARTUP_SCRIPT
declare +x -i _instance_cnt=0x0
declare +x -i subs=0x0
declare +x -i __script_stack_bounded=${#BASH_STARTUP_SCRIPT[*]}
declare +x -i j=$__script_stack_bounded
((j -= 1))
declare +x __this_shell_script=$(/usr/bin/realpath.exe --physical "${BASH_SOURCE[0]}")
declare +x DeeBuggins='printf >/dev/null'  # change to '>&2' when debugging this script.

for jonquil in "${BASH_SOURCE[@]}"
 do
    case $(/usr/bin/realpath.exe -P "$jonquil") in
        ( $__this_shell_script )
           test $_instance_cnt -ge 1 &&
           printf >&2 '\nWe have a dupl hit at count %u on item %s\n' \
              "$_instance_cnt" "$__this_shell_script"
           ((_instance_cnt += 1))
        ;&
        ( * )
           ((subs += 1))
        ;;
    esac
 done
if [[ $subs -ne $__script_stack_bounded ]]
  then
   printf >/dev/null '\nWARNING: script debugging needed in "%s" at %u: %u ne %u\n' \
                      $__this_shell_script  $LINENO  $subs  $__script_stack_bounded
fi
if [[ $_instance_cnt -lt 0x2 ]]
  then BASH_STARTUP_SCRIPT[((j + 1))]=$__this_shell_script
  else return 0  # AFTER DEBUGGINS do: return 0
fi
# unset __this_shell_script
unset _instance_cnt
unset jonquil
unset j
unset subs
unset __script_stack_bounded
shopt -u extdebug
# /end/ BASH_STARTUP_SCRIPT stuff

# Shifted over from file ~/.bash_common on 08 May 2012
# NOTA BENE: when we are using the StrawberryPerl installation, we are employing
# the "sitecustomize" mechanism that makes perl "do" the file
#   C:/Strawberry/perl/site/lib/sitecustomize.pl
# each time we run (unless running perl with '-f' flag); and compiler errors are
# *SILENCED*. That's dangerous! Much wasted time if that happens!

declare -r _DEFAULT_CYGWIN_PATH="$PATH"
declare -r _DEFAULT_PERL5LIB_PATH="$PERL5LIB"
declare -r _MIXEDMODE_CYGSHELL=$(/bin/cygpath -m -C UTF8 /bin/dash)
declare -x PLV_STRING

function _Uq
{
    set -o verbose
    declare +x FRES=''
    declare -i lico=0; declare -i ocil
    declare -a _l_
    if [[ $# -eq 2 ]]
      then declare +x pa="$1:$2"
      else declare +x pa="$1"
    fi

    shopt -s nocasematch
    declare +x gotDeeBug=0  # set to 1 when done debugging

    for YITELE in ${pa//:/' '}
      do
          if [[ ! "${_l_[*]}" =~ $YITELE ]]
            then _l_[$lico]=$YITELE
                 (( lico += 1 ))
          fi
      done

    ocil=$(( $lico * -1 ))

    while [[ $ocil -lt 0 ]]
       do
          if [[ $gotDeeBug -eq 1 ]]; then
              printf >&2 'Adding element [%i] : %s to new PATH\n' \
                     $(( $ocil + $lico )) "${_l_[(( $ocil + $lico ))]}"
          fi
          FRES=${FRES:+$FRES:}${_l_[(( $ocil + $lico ))]}
          ((ocil += 1))
       done
    printf "$FRES"  # set what will be new PATH here
    set +o verbose
    shopt -u nocasematch
    unset gotDeeBug lico FRES YITELE _l_ ocil a1 a2 pa
    return 0
}

function perl_v_in_use
{
  # contrast with use of version pragma as in:
  #   $ perl -Mversion -le 'print version->parse($])->normal'
  /usr/bin/env perl \
    -e 'my $pow = 2; @qiu = split(q/[.]/=>$]);' \
    -e '@qiu[1 .. @qiu] = map{sprintf(q[%u],$_/10**$pow++)} ' \
    -e 'map {unpack "A4 A4",$_ * 10**3 } @qiu[1 .. $#qiu];' \
    -e 'print join q[.], grep{length($_)} @qiu;'
}

function pviu_insurance
{
    by_longhand="$(perl_v_in_use)"
 #  by_pragma=$(perl -e 2>/dev/null'use version "0.77"; print version->parse($])->normal')
 #  if [[ $? != 0x0 ]]; then
 #      by_pragma=$(perl -e 'use version "0.74"; print version->new($])->normal')
 #  fi

    if [[ "v$by_longhand" == $(/usr/bin/env perl -e 'print $^V') ]]
        then return 0
    else     return 1
    fi
}

# get a global string to hold Perl's version "number."
function set_perl_v_in_use
{
    if pviu_insurance
        then PLV_STRING=$(perl_v_in_use)
        else printf >&2 "WARNING: NON-SUCCESS rv \"%u\" from pviu_insurance\n" $?
             PLV_STRING='0_INVALID'
    fi
}
set_perl_v_in_use

function _toggle_perlinstance
{
  declare +x RESULT
  declare +x NEWPATH
  declare +x _have_CheckPath
  if [[ $(declare -F checkpath) != "" ]]
    then _have_CheckPath=1
    else _have_CheckPath=''
  fi
  local PS3a="\e[0;33m"
  local PS3b="\e[0m "
  local PS3=$(printf '%b\n%b' \
   "${PS3a}Change precedence for a Perl in PATH?" \
   "(hint: choose a *number*):${PS3b}")

  function _toggle_Path
  {
      shopt -s nocasematch
      shopt -s extdebug
      PERLCHOICE=$1
      declare +x PURECYGPATH=$(_Uq "$PATH")

      if     [[ $PERLCHOICE =~ strawb ]]

        then
          declare +x SBY_PERL=$(/bin/cygpath -u 'C:/Strawberry')
          declare +x -a SBY_SDRS=('/C/' '/Perl/' '/Perl/site/')

          for SD in ${SBY_SDRS[@]}
            do
              PURECYGPATH=$(_Uq "$SBY_PERL${SD}bin" "$PURECYGPATH")
            done
          export NEWPATH=$PURECYGPATH
          unset SD

        elif [[ $PERLCHOICE =~ camelb ]]
        then
          PURECYGPATH=$(_Uq /cygdrive/C/Camelbox/bin "$PURECYGPATH")
          export NEWPATH=$PURECYGPATH

        else :  # want to restore to /usr/bin in front, here.
      fi
      shopt -u nocasematch
      return 0
  }


  select SELT in "StrawberryPerl" "CamelboxPerl" "revert to default" "cancel"
    do
      case $SELT in
        StrawberryPerl )
             _toggle_Path "strawb"
             PATH=$NEWPATH
             export MAKE=dmake
#  Remember that PERL5SHELL is set in sitecustomize.pl; depending how it is done,
#  that overrides the setting we are doing here! It may be meaningless to set
#  PERL5SHELL in this routine.
             export PERL5SHELL=$_MIXEDMODE_CYGSHELL' -ul -c'
             export SHELL=$_MIXEDMODE_CYGSHELL' -l'
             export PERL5_CPANPLUS_VERBOSE=1
             export PERL5OPT='-MWin32::UTCFileTime=:globally'
             # My plugins for CPANPLUS live under:  $PUP/.cpanplus/lib
             #   and my User.pm config lives under  $PUP/.config {/CPANPLUS/Config/User.pm}
             export PERL5LIB='C:/Users/somian/.config;C:/Users/somian/.cpanplus/lib'
             INFOPATH=${INFOPATH:-$(_Uq $INFOPATH)}
             MANPATH=${MANPATH:-$(_Uq $MANPATH)}
             declare +x nowperl=$(command -v perl|/bin/cygpath -ml -f -)
             set_perl_v_in_use
             alias cpanp='cygstart cpanp'
             printf >&2 " PATH is changed to\n%b  %s%b\n\n" \
                     "\e[36m" "$(printf '%s\n' "${PATH//:/$'\n'  }")" "\e[0m"

             PS1=$(env|grep -e '^PS1'|
                         sed\
                   -e 's#PS1=##'\
                   -e 's#\\a# ÷NonCygwin Perl being used÷ perl is '"$nowperl $PLV_STRING"'\\a#')
             break ;;

           CamelboxPerl )
             _toggle_Path "camelb"
             PATH=$NEWPATH
             export MAKE=dmake
#  Remember that PERL5SHELL is set in sitecustomize.pl; depending how it is done,
#  that overrides the setting we are doing here! It may be meaningless to set
#  PERL5SHELL in this routine.
             export PERL5SHELL=$_MIXEDMODE_CYGSHELL' -ul -c'
             export SHELL=$_MIXEDMODE_CYGSHELL' -l'
             export PERL5_CPANPLUS_VERBOSE=1
             export PERL5OPT=''  # '-MWin32::UTCFileTime=:globally'
             #          When we use Camelbox Perl we need to add Strawberry's /site/lib
             # My plugins for CPANPLUS live under:  $PUP/.cpanplus/lib
             #   and my User.pm config lives under  $PUP/.config {/CPANPLUS/Config/User.pm}
             export PERL5LIB='C:/Users/somian/.config;C:/Users/somian/.cpanplus/lib;C:/strawberry/perl/site/lib'
             INFOPATH=${INFOPATH:-$(_Uq "$INFOPATH")}
             MANPATH=${MANPATH:-$(_Uq $(/bin/cygpath -u C:/camelbox/man) "$MANPATH")}
             set_perl_v_in_use
             declare +x nowperl=$(command -v perl|cygpath -ml -f -)
             printf >&2 " PATH is changed to\n%b  %s%b\n\n" \
                     "\e[36m" "$(printf '%s\n' "${PATH//:/$'\n'  }")" "\e[0m"

             PS1=$(env|grep -e '^PS1'|
                         sed\
                  -e 's#PS1=##'\
                  -e 's#\\a# ÷NonCygwin Perl being used÷ perl is '"$nowperl $PLV_STRING"'\\a#')
             break ;;

    "revert to default" )  # we do not call _togglePath here
             PATH=$_DEFAULT_CYGWIN_PATH
             PERL5LIB=$_DEFAULT_PERL5LIB_PATH
             hash -p $PEIR perl
             declare +x nowperl=$(command -v perl|cygpath -ml -f -)
             PS1=$_Saved_PS1
             MAKE=make
             INFOPATH=${INFOPATH:-$(_Uq $INFOPATH)}
             MANPATH=${MANPATH:-$(_Uq $MANPATH)}
             unset PERL5SHELL PERL5OPT
             set_perl_v_in_use
             printf >&2 " PATH change reverted to Cygwin default.\n"
             printf >&2 " The PATH will now be:\n%s\n" "${PATH//:/$'\n'}"
             printf >&2 " Perl will now be: %s version:%s\n" $nowperl $PLV_STRING
             break ;; # break!
         cancel )
             declare +x nowperl=$(command -v perl|cygpath -ml -f -)
             printf >&2 " PATH and all other changes cancelled.\n"
             printf >&2 " The PATH will remain:\n%s\n" "${PATH//:/$'\n'}"
             printf >&2 " Perl will still be: %s version:%s\n" $nowperl $PLV_STRING
             break ;;
      esac
    done
    IFS=$_Save_IFS
    unset SELT NEWPATH
}

# Make functions exportable
declare -x -f _toggle_perlinstance perl_v_in_use pviu_insurance set_perl_v_in_use _Uq

unset DeeBuggins
unset __this_shell_script
unset _Save_IFS
