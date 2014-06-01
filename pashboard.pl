#!/usr/bin/perl
# v24 Dashboard by Felipe Crespo felipe.crespo@ventura24.es

package Dashboard;

# Create a config
my $Config = Config::Tiny->new;
$Config = Config::Tiny->read( 'pashboard.ini', 'utf8' );

# Reading properties
$globalHeader = $Config->{_}->{globalheader};
# ------- Section 1 conf -------
$section1Name = $Config->{section1}->{name};
$section1DBUser = $Config->{section1}->{user};
$section1ConectionName = $Config->{section1}->{connection};
$section1DBPass = $Config->{section1}->{password};
$section1Header = $Config->{section1}->{header};
$section1Footer = $Config->{section1}->{footer};
# ------- Section 2 Conf -------
$section2Name = $Config->{section2}->{name};
$section2DBUser = $Config->{section2}->{user};
$section2ConectionName = $Config->{section2}->{connection};
$section2DBPass = $Config->{section2}->{password};
$section2Header = $Config->{section2}->{header};
$section2Footer = $Config->{section2}->{footer};

use strict; # Obliga a declarar variables
use warnings;
use diagnostics; # helpfull information
use IO::Prompt;
use Term::ANSIColor;
use Term::ANSIColor qw(:constants);
use Config::Tiny;


# Sub get password from user
sub getPasswordFromUser
{
  my $systemName = $_[0];
  system('stty','-echo');
  print("\nEnter the $systemName password:");
  chop(my $password=<STDIN>);
  system('stty','echo');
  return $password;
}

# Sub executeSection1SqlFile
sub executeSection1SqlFile
{
  my $fileUri = $_[0];
  return executeSqlFile($Dashboard::section1DBUser,
                        $Dashboard::section1DBPass,
                        $Dashboard::section1ConectionName,
                        $fileUri)
}

# Sub executeSection2SqlFile
sub executeSection2SqlFile
{
  my $fileUri = $_[0];
  return executeSqlFile($Dashboard::section2DBUser,
                        $Dashboard::section2DBPass,
                        $Dashboard::section2ConectionName,
                        $fileUri)
}


# Sub executeSqlFile
sub executeSqlFile
{
  my ($user, $pswd, $db, $fileUri) = @_;
  my $section2ResultText=`sqlplus64 -s $user/$pswd\@$db \@$fileUri`;
  chomp($section2ResultText);
  return split (/\\t/, $section2ResultText);
}

# Print data line
sub printDataLine
{
  my ($title, @data) = @_;

  print $title;

  foreach (@data)
  {
    my $item = $_;
    print "\t";
    if ($item eq "0")
    {
      print BOLD ON_RED  "$item", RESET;
    }
    else
    {
      print "$item";
    }
  }
  print "\n";
}


my $refreshTimeInSeconds = 1;

#$Dashboard::section1DBPass = getPasswordFromUser("section 1");
#$Dashboard::section2DBPass = getPasswordFromUser("section 2");



print "\nLoading...\n";



my $section1filesraw = $Config->{section1}->{filelist};
my @section1FileList = split (/,/, $section1filesraw);

my $section2filesraw = $Config->{section2}->{filelist};
my @section2FileList = split (/,/, $section2filesraw);





my @section1ResultText = ();
my @section2ResultText = ();

while(1)
{
  @section1ResultText = ();
  @section2ResultText = ();

  foreach (@section1FileList)
  {
    push (@section1ResultText, executeSection1SqlFile($_));
  }

  foreach (@section2FileList)
  {
    push (@section2ResultText, executeSection2SqlFile($_));
  }

  print BOLD BLUE  "[Description]\t[1 Min]\t[5 Min]\t[10 Mi]\t[60 Mi]\t[Last Insert]", RESET, "";
  my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
  printf ("[%02d/%02d/%02d %02d:%02d:%02d]\n", $mday, $mon, $year, $hour, $min, $sec);

  foreach (@section1ResultText)
  {
    printDataLine ($_);
  }
  print BOLD BLUE  $Dashboard::section1Footer, RESET, "\n";
  foreach (@section2ResultText)
  {
    printDataLine ($_);
  }
  print BOLD BLUE  $Dashboard::section2Footer, RESET, "\n";

  sleep($refreshTimeInSeconds);
};



