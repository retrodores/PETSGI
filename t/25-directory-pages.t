use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use PETSGI::App::Files;
use PETSGI::Test::PETdiskMax;

my $dir=tempdir(CLEANUP=>1);
for my $n (1..70) {
    my $name=sprintf('P%03d.PRG',$n);
    open my $fh,'>:raw',"$dir/$name" or die $!;
    print {$fh} "X";
    close $fh;
}
my $pet=PETSGI::Test::PETdiskMax->new(app=>PETSGI::App::Files->new(root=>$dir));
my @got=$pet->directory;
is scalar(@got),70,'mock follows all 512-byte directory pages';
is $got[0],'P001.PRG','first entry';
is $got[-1],'P070.PRG','last entry';

done_testing;
